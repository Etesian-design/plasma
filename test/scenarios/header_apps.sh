# Richer apps' toolbars in the header (look/decoration, toolbar mode): Dolphin, Okular and Gwenview get their main toolbar's
# buttons in the header and their own toolbar hidden; a header click runs the action in that window, and the action's state
# (enabled, checked) shows in the header. Checked through the apps' own D-Bus actions.
source /src/test/check.sh
# Header layout from the right: edge 4, controls 90, spacer 10, app menu 30, then the actions (34 each) and a 4 px gap.
# action <i> <count>: the screen x,y of the i-th of count header actions of the active window
action() { g=$(active_geometry); x=${g%%,*}; rest=${g#*,}; y=${rest%% *}; size=${g#* }; w=${size%x*}
  echo "$((x + w - 134 - 4 - $2 * 34 + $1 * 34 + 17)) $((y + 7 + 15))"; }
# the app's bus connection: its well-known name, or (Gwenview takes none) the connection that belongs to its process
svc_of() { local n=$(qdbus6 | grep -i "org.kde.$1" | head -n 1 | tr -d ' '); [ -n "$n" ] && { echo "$n"; return; }
  local pid=$(pgrep -x "$1" | head -n 1) c; [ -n "$pid" ] || return
  for c in $(qdbus6 | grep '^ *:' | tr -d ' '); do
    [ "$(qdbus6 org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus.GetConnectionUnixProcessID "$c" 2>/dev/null)" = "$pid" ] && { echo "$c"; return; }
  done; }
win_of() { qdbus6 "$1" | grep -E '^/[^/]+/[^/]+_[0-9]+$' | head -n 1; }
# at <svc> <win> <name> <toolbar names...>: where the header shows <name>, among the toolbar actions the app has visible now
at() { local s=$1 w=$2 want=$3; shift 3; local shown=() n; for n in "$@"; do [ "$(prop "$s" "$w" "$n" visible 2>/dev/null)" = true ] && shown+=("$n"); done
  local i; for i in "${!shown[@]}"; do [ "${shown[$i]}" = "$want" ] && { action "$i" "${#shown[@]}"; return; }; done; echo "0 0"; }
DOLPHIN="go_back go_forward split_view split_stash toggle_search"
OKULAR="show_leftpanel view_zoom_in view_zoom_out mouse_drag mouse_selecttools"
GWENVIEW="go_start_page browse view go_previous go_next toggle_operations_sidebar share fullscreen"
# menu <svc> <icon> <property>: a property of the app's menu item with that icon (Okular's actions are its part's: not on D-Bus
# as actions, only in its menu, where the header finds them too)
menu() { python3 - "$@" <<'PY'
import dbus, sys
svc, icon, key = sys.argv[1:4]
b = dbus.SessionBus()
for path in ('/MenuBar/2', '/MenuBar/1'):
    try: _, lay = b.get_object(svc, path).GetLayout(0, -1, [], dbus_interface='com.canonical.dbusmenu'); break
    except Exception: lay = None
def walk(n):
    i, p, kids = n
    if str(p.get('icon-name', '')) == icon: return p
    for k in kids:
        f = walk(k)
        if f is not None: return f
found = walk(lay) if lay else None
print('' if found is None else str(found.get(key, '')))
PY
}
prop() { qdbus6 "$1" "$2/actions/$3" org.freedesktop.DBus.Properties.Get org.qtproject.Qt.QAction "$4"; }
hidden() { s=$(svc_of "$1"); [ -n "$s" ] || return; w=$(win_of "$s"); [ -n "$w" ] || return
  i=$(qdbus6 "$s" "$w" | grep -o '[a-zA-Z.]*\.KXmlGuiWindow\.isToolBarVisible' | head -n 1)
  [ -n "$i" ] && [ "$(qdbus6 "$s" "$w" "$i" mainToolBar)" = false ] && echo true; }

# Dolphin: Back, Forward, Split, Search (Stash is hidden unless turned on in Dolphin)
mkdir -p ~/h/inner && touch ~/h/inner/a.txt
dolphin --new-window ~/h/inner >/out/dolphin.log 2>&1 &
wait_for 30 hidden dolphin || true
expect "Dolphin's own toolbar is hidden (its buttons are in the header)" "$(hidden dolphin)" true
s=$(svc_of dolphin); w=$(win_of "$s")
keys "sleep 1" "shot header-dolphin"
expect "Back starts disabled (no history)" "$(prop "$s" "$w" go_back enabled)" false
split=$(prop "$s" "$w" split_view text)
read sx sy < <(at "$s" "$w" split_view $DOLPHIN); keys "move $sx $sy" "click" "sleep 1" "shot header-dolphin-split"
expect_has "the header's Split button split the view (it now closes it)" "$(prop "$s" "$w" split_view text) (was $split)" "Close"
read sx sy < <(at "$s" "$w" split_view $DOLPHIN); keys "move $sx $sy" "click" "sleep 1"
expect "and closed it again" "$(prop "$s" "$w" split_view text)" "$split"
read fx fy < <(at "$s" "$w" toggle_search $DOLPHIN); keys "move $fx $fy" "click" "sleep 1"
expect "the header's Search button opened search" "$(prop "$s" "$w" toggle_search checked)" true
keys "tap ESC" "sleep 0.5"
qdbus6 "$s" "$w" org.kde.KMainWindow.activateAction go_up >/dev/null; sleep 1
expect "going up enables Back" "$(prop "$s" "$w" go_back enabled)" true
expect_has "(Dolphin is in the parent folder)" "$(active_caption)" "h"
read bx by < <(at "$s" "$w" go_back $DOLPHIN); keys "move $bx $by" "click" "sleep 1"
expect_has "the header's Back button went back" "$(active_caption)" "inner"
keys "shot header-dolphin-after"
# the location bar stays in Dolphin (a widget, not a button): with it out of the toolbar (install.sh) Dolphin puts it above the
# view. The row under the header is the bar: the folder names "h" and "inner" as breadcrumbs (text pixels on a light row).
expect "Dolphin's toolbar file (install.sh) leaves the location bar out" "$(grep -c url_navigators ~/.local/share/kxmlgui5/dolphin/dolphinui.rc)" 0
qdbus6 "$s" "$w" org.qtproject.Qt.QWidget.close >/dev/null 2>&1 || true

# Okular: Sidebar, Zoom In, Zoom Out, Browse, Select
python3 -c "from PIL import Image; Image.new('RGB', (600, 800), 'white').save('$HOME/doc.pdf')"
okular ~/doc.pdf >/out/okular.log 2>&1 &
wait_for 30 hidden okular || true
qdbus6 "$(svc_of okular)" >/out/okular-objects.txt 2>&1; qdbus6 | grep -i okular >>/out/okular-objects.txt
expect "Okular's own toolbar is hidden" "$(hidden okular)" true
s=$(svc_of okular); w=$(win_of "$s")
expect "Okular's Page Bar is on (it takes the toolbar's page number)" "$(kreadconfig6 --file okularpartrc --group 'Main View' --key ShowBottomBar)" true
before=$(menu "$s" sidebar-expand-left toggle-state)
read ox oy < <(action 0 5); keys "move $ox $oy" "click" "sleep 1" "shot header-okular"
expect "the header's Sidebar button toggled Okular's sidebar" "$(menu "$s" sidebar-expand-left toggle-state)" "$([ "$before" = 1 ] && echo 0 || echo 1)"
read ox oy < <(action 4 5); keys "move $ox $oy" "click" "sleep 1"
expect "the header's Select button picked Okular's area selection" "$(menu "$s" select-rectangular toggle-state)" 1
qdbus6 "$s" "$w" org.qtproject.Qt.QWidget.close >/dev/null 2>&1 || true

# Gwenview: Start page, Browse, View, Previous, Next, Sidebar, Share, Full screen
mkdir -p ~/g && python3 -c "from PIL import Image; Image.new('RGB', (64, 64), (40, 120, 200)).save('$HOME/g/one.png'); Image.new('RGB', (64, 64), (200, 80, 40)).save('$HOME/g/two.png')"
gwenview ~/g >/out/gwenview.log 2>&1 &
wait_for 30 hidden gwenview || true
expect "Gwenview's own toolbar is hidden" "$(hidden gwenview)" true
s=$(svc_of gwenview); w=$(win_of "$s")
read vx vy < <(at "$s" "$w" view $GWENVIEW); keys "move $vx $vy" "click" "sleep 1.5" "shot header-gwenview"
expect "the header's View button switched Gwenview to viewing" "$(prop "$s" "$w" view checked)" true
expect "and Browse is off" "$(prop "$s" "$w" browse checked)" false
grep -iE "etesian" /out/kwin.log | grep -iE "error|warning" | head -n 10 >/out/deco-errors.txt || true
expect "no decoration errors" "$(grep -c . /out/deco-errors.txt)" 0

#!/bin/bash
# Removes the Etesian files that install.sh copied and puts your own settings and panels back, as they were before the first
# install (current user only).
#   ./uninstall.sh                  your settings back (Breeze when Etesian was installed before install.sh kept them)
#   ./uninstall.sh --breeze         the Breeze look instead of your settings
#   ./uninstall.sh --breeze --layout  Breeze and Plasma's default panels
set -e
here="$(cd "$(dirname "$0")" && pwd)"
data="${XDG_DATA_HOME:-$HOME/.local/share}"
. "$here/settings.sh"
backup="$data/etesian/backup"
remove_files() {
  rm -rf "$data/plasma/plasmoids/org.etesian."* "$data/kwin/scripts/etesian-snap" "$data/kwin/effects/etesian_windows" "$data/kwin/effects/etesian_snaplayouts" "$data/kwin/tabbox/etesian_carousel" "$data/aurorae/themes/Etesian" "$data/plasma/desktoptheme/etesian" "$data/plasma/look-and-feel/org.etesian.desktop" "$data/icons/Etesian" "$HOME/.local/lib/qt6/plugins/org.kde.kdecoration3/org.etesian.decoration.so" "$HOME/.config/plasma-workspace/env/etesian-plugins.sh" "$HOME/.local/lib/qt6/qml/org/etesian/mail" "$HOME/.config/plasma-workspace/env/etesian-qml.sh" "$data/sounds/Etesian" "$data/icons/Etesian-cursors" "$data/wallpapers/Etesian"
  # the Thunderbird theme (Thunderbird goes back to its default theme if it was in use)
  rm -f "$HOME"/.thunderbird/*/extensions/theme@etesian-design.com.xpi "$HOME"/.var/app/org.mozilla.Thunderbird/.thunderbird/*/extensions/theme@etesian-design.com.xpi "$HOME"/snap/thunderbird/common/.thunderbird/*/extensions/theme@etesian-design.com.xpi
  rm -f "$data/color-schemes/Etesian.colors" "$data/color-schemes/EtesianDark.colors"
}

if [ -d "$backup" ] && [ "$1" != --breeze ]; then
  # Plasma keeps its panels in memory and writes them back when it quits: stop it, put the files back, start it again.
  shell=
  if systemctl --user -q is-active plasma-plasmashell 2>/dev/null; then shell=systemd; systemctl --user stop plasma-plasmashell
  elif pgrep -x plasmashell >/dev/null; then
    shell=plain; qdbus6 org.kde.plasmashell /MainApplication quit >/dev/null 2>&1 || pkill -x plasmashell || true
    for i in $(seq 50); do pgrep -x plasmashell >/dev/null || break; sleep 0.2; done
  fi
  for f in "${etesian_settings[@]}"; do
    if [ -f "$backup/$f" ]; then cp "$backup/$f" "$config/$f"; elif [ -e "$backup/$f.absent" ]; then rm -f "$config/$f"; fi
  done
  remove_files
  case "$shell" in systemd) systemctl --user start plasma-plasmashell ;; plain) setsid plasmashell >/dev/null 2>&1 & ;; esac
  # The restored files are read at the next start; these tell running apps now.
  plasma-apply-colorscheme "$(kreadconfig6 --file kdeglobals --group General --key ColorScheme --default BreezeLight)" >/dev/null 2>&1 || true
  plasma-apply-cursortheme "$(kreadconfig6 --file kcminputrc --group Mouse --key cursorTheme --default breeze_cursors)" >/dev/null 2>&1 || true
  qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
  # The shortcut service keeps Etesian's shortcuts in memory and would write them back into the restored file.
  for k in "Etesian Snap Left" "Etesian Snap Right" "Etesian Maximise" "Etesian Float" "Etesian Snap Layouts" "Etesian Windows" "Etesian Windows (Reverse)"; do
    qdbus6 org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel.unregister kwin "$k" >/dev/null 2>&1 || true
    kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "$k" --delete
  done
  rm -rf "$data/etesian"
  echo "Your own settings and panels are back. Log out and back in once for the shortcuts."
  exit 0
fi

if [ "$2" = --layout ] || [ "$1" = --layout ]; then plasma-apply-lookandfeel --apply org.kde.breeze.desktop --resetLayout
else plasma-apply-lookandfeel --apply org.kde.breeze.desktop; fi
plasma-apply-colorscheme BreezeLight >/dev/null
plasma-apply-desktoptheme default >/dev/null
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.breeze
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme Breeze
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft --delete
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight --delete
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key BorderSize --delete
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key BorderSizeAuto --delete
for k in AccentColor accentColorFromWallpaper font menuFont toolBarFont smallestReadableFont; do kwriteconfig6 --file kdeglobals --group General --key $k --delete; done
kwriteconfig6 --file kdeglobals --group WM --key activeFont --delete
kwriteconfig6 --file kdeglobals --group Icons --key Theme --delete
kwriteconfig6 --file kwinrc --group TabBox --key LayoutName --delete
kwriteconfig6 --file kwinrc --group TabBox --key HighlightWindows --delete
for k in "Walk Through Windows" "Walk Through Windows (Reverse)"; do kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "$k" --delete; done
for k in "next activity" "previous activity"; do kwriteconfig6 --file kglobalshortcutsrc --group plasmashell --key "$k" --delete; done
for k in etesian-snapEnabled etesian_windowsEnabled etesian_snaplayoutsEnabled; do kwriteconfig6 --file kwinrc --group Plugins --key $k --delete; done
for d in Left Right Top Bottom; do kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window Quick Tile $d" --delete; done
for k in "Etesian Snap Left" "Etesian Snap Right" "Etesian Maximise" "Etesian Float" "Etesian Snap Layouts" "Etesian Windows" "Etesian Windows (Reverse)"; do kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "$k" --delete; done
remove_files; rm -rf "$data/etesian"
kwriteconfig6 --file kdeglobals --group Sounds --key Theme ocean
kwriteconfig6 --file kcminputrc --group Mouse --key cursorTheme breeze_cursors
plasma-apply-cursortheme breeze_cursors >/dev/null 2>&1 || true
kwriteconfig6 --file ksplashrc --group KSplash --key Theme org.kde.breeze.desktop
kwriteconfig6 --file kwinrc --group Etesian --key HeaderActions --delete
kwriteconfig6 --file kwinrc --group Etesian --key HeaderActionApps --delete
qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
echo "Breeze restored. Log out and back in once for the shortcuts."

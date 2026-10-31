# Assertions shared by the scenarios: `expect <name> <actual> <expected>` prints PASS/FAIL lines to /out/result.txt;
# run.sh fails when any line says FAIL.
expect() { if [ "$2" = "$3" ]; then echo "PASS $1" >>/out/result.txt; else echo "FAIL $1: got '$2', want '$3'" >>/out/result.txt; fi; }
expect_has() { case "$2" in *"$3"*) echo "PASS $1" >>/out/result.txt ;; *) echo "FAIL $1: '$3' not in '$2'" >>/out/result.txt ;; esac; }
cfg() { kreadconfig6 --file "$1" --group "$2" --key "$3"; }
# Evaluate a Plasma desktop script in the running shell and return what it prints.
plasma_eval() { qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$1"; }
# Runs a one-off KWin script and returns what its expression evaluates to (the script prints into kwin.log).
kwin_eval() {
  local js=/tmp/eval-$RANDOM.js mark="EVAL-$RANDOM"
  echo "print('$mark=' + ($1))" >"$js"
  local id; id=$(qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.loadScript "$js")
  qdbus6 org.kde.KWin "/Scripting/Script$id" org.kde.kwin.Script.run >/dev/null; sleep 0.5
  qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript "$js" >/dev/null
  grep -o "$mark=.*" /out/kwin.log | tail -n 1 | cut -d= -f2-
}
active_caption() { kwin_eval "workspace.activeWindow ? workspace.activeWindow.caption : ''"; }
# The active window's frame as "x,y w×h".
active_geometry() { kwin_eval "(g => g.x + ',' + g.y + ' ' + g.width + 'x' + g.height)(workspace.activeWindow.frameGeometry)"; }
work_area() { kwin_eval "(a => a.x + ',' + a.y + ' ' + a.width + 'x' + a.height)(workspace.clientArea(KWin.MaximizeArea, workspace.activeWindow))"; }

#!/bin/bash
# Inside the container: start D-Bus, KWin with a virtual 1600x1000 screen and Plasma, then run the scenario given as $1.
# Screenshots of the session go to /out (shot.py). KWIN_GDB=1 runs KWin under gdb (a crash leaves its backtrace in kwin.log). The repo is mounted read-only at /src.
set -e
mkdir -p "$XDG_RUNTIME_DIR" && chmod 700 "$XDG_RUNTIME_DIR"
eval "$(dbus-launch --sh-syntax)"
/src/install.sh >/out/install-pre.log 2>&1 || true # config KWin reads at start (shortcuts)
kbuildsycoca6 >/dev/null 2>&1
for f in ~/.config/plasma-workspace/env/*.sh; do [ -f "$f" ] && . "$f"; done # what startplasma does at login (the decoration plugin path)
(pipewire & sleep 0.5; wireplumber & pipewire-pulse &) >/out/pipewire.log 2>&1 # sound (volume, Silent) and window streams (dock previews); before KWin, which connects at start
sleep 1
QT_FORCE_STDERR_LOGGING=1 KWIN_WAYLAND_NO_PERMISSION_CHECKS=1 KWIN_SCREENSHOT_NO_PERMISSION_CHECKS=1 ${KWIN_GDB:+gdb -batch -ex run -ex bt --args} kwin_wayland --virtual --width 1600 --height 1000 --no-lockscreen >/out/kwin.log 2>&1 &
for i in $(seq 50); do [ -S "$XDG_RUNTIME_DIR/wayland-0" ] && break; sleep 0.2; done
kded6 >/out/kded.log 2>&1 &
$(ls /usr/lib/x86_64-linux-gnu/libexec/kactivitymanagerd /usr/lib/kactivitymanagerd 2>/dev/null | head -n 1) >/out/kamd.log 2>&1 & # Ubuntu / Arch path
QT_FORCE_STDERR_LOGGING=1 plasmashell >/out/plasma.log 2>&1 &
sleep 8
/src/install.sh --layout >/out/install.log 2>&1
sleep 4
shot() { python3 /src/test/shot.py "/out/$1.png"; }
keys() { python3 /src/test/input.py "$@"; }
source "/src/test/scenarios/$1.sh"

# After a Plasma update the decoration plugin may no longer match KDecoration: the login script (env.sh) falls back to the
# Aurorae header bar and switches back when they match again; install.sh never installs a stale plugin it cannot rebuild.
source /src/test/check.sh
deco() { cfg kwinrc org.kde.kdecoration2 "$1"; }
state=~/.local/share/etesian
now=$(ls /usr/lib/x86_64-linux-gnu/libkdecorations3.so.*.*.* /usr/lib/libkdecorations3.so.*.*.* 2>/dev/null | head -n 1 | sed 's/.*\.so\.//')
expect "installed build matches KDecoration" "$(cut -d. -f1,2 $state/decoration-version)" "${now%.*}"
expect "native decoration in use" "$(deco library)" org.etesian.decoration
login() { sh -c '. ~/.config/plasma-workspace/env/etesian-plugins.sh'; }

real=$(cat $state/decoration-version); echo 6.0.0 >$state/decoration-version # as if Plasma moved on since the build
login
expect "stale build: Aurorae at login" "$(deco library)" org.kde.kwin.aurorae
expect "stale build: Etesian Aurorae theme" "$(deco theme)" __aurorae__svg__Etesian
expect "fallback marker" "$(ls $state/decoration-fallback 2>/dev/null | wc -l)" 1
qdbus6 org.kde.KWin /KWin reconfigure; sleep 2
expect_has "KWin draws the Aurorae header" "$(qdbus6 org.kde.KWin /KWin org.kde.KWin.supportInformation)" "__aurorae__svg__Etesian"
kate /src/README.md >/out/kate.log 2>&1 & sleep 4
shot plasma-update-aurorae; pkill -x kate

echo "$real" >$state/decoration-version; login # rebuilt (or the versions match again)
expect "matching again: native decoration" "$(deco library)" org.etesian.decoration
expect "marker cleared" "$(ls $state/decoration-fallback 2>/dev/null | wc -l)" 0
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.breeze; login
expect "a user's own choice is never changed" "$(deco library)" org.kde.breeze

# install.sh with a stale build it cannot rebuild (the repo is read-only here): Aurorae, not the stale plugin
mkdir -p /tmp/stale && cp /deco/org.etesian.decoration.so /tmp/stale/ && echo 6.0.0 >/tmp/stale/kdecoration-version
ETESIAN_DECORATION_SO=/tmp/stale/org.etesian.decoration.so /src/install.sh >/out/install-stale.log 2>&1
expect "install skips a stale plugin" "$(deco library)" org.kde.kwin.aurorae
expect_has "and says so" "$(cat /out/install-stale.log)" "native decoration could not be built"

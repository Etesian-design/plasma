# Etesian: sourced by startplasma at login, before KWin starts (installed as ~/.config/plasma-workspace/env/etesian-plugins.sh).
# The window decoration plugin lives in ~/.local/lib/qt6/plugins.
export QT_PLUGIN_PATH="$HOME/.local/lib/qt6/plugins${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}"
# A Plasma update can change the decoration interface the plugin was built for (KDecoration, major.minor). Until install.sh
# rebuilds it, use the Aurorae header bar (same look, no app toolbar actions); the marker lets a later login switch back
# when the versions match again, and only ever undoes this script's own switch.
etesian_state="${XDG_DATA_HOME:-$HOME/.local/share}/etesian"
etesian_built=$(cat "$etesian_state/decoration-version" 2>/dev/null)
etesian_now=$(ls /usr/lib/x86_64-linux-gnu/libkdecorations3.so.*.*.* /usr/lib64/libkdecorations3.so.*.*.* /usr/lib/libkdecorations3.so.*.*.* 2>/dev/null | head -n 1 | sed 's/.*\.so\.//')
if [ -n "$etesian_built" ] && [ -n "$etesian_now" ]; then
  if [ "${etesian_built%.*}" != "${etesian_now%.*}" ]; then
    if [ "$(kreadconfig6 --file kwinrc --group org.kde.kdecoration2 --key library)" = org.etesian.decoration ]; then
      kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.kwin.aurorae
      kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme __aurorae__svg__Etesian
      echo "$etesian_built -> $etesian_now" >"$etesian_state/decoration-fallback"
    fi
  elif [ -f "$etesian_state/decoration-fallback" ]; then
    kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.etesian.decoration
    kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme --delete
    rm -f "$etesian_state/decoration-fallback"
  fi
fi
unset etesian_state etesian_built etesian_now

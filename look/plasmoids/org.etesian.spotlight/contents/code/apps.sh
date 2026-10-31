#!/bin/sh
# Lists the installed apps for the launcher, one per line: desktop-file id <TAB> name <TAB> icon.
# Follows the XDG data dirs in order (the user's own first, so their overrides win) and skips NoDisplay / Hidden entries.
# Plasma's own app model (org.kde.plasma.private.kicker) is not used: on Plasma 6.8 it crashes plasmashell in a third-party widget.
dirs="${XDG_DATA_HOME:-$HOME/.local/share}:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
echo "$dirs" | tr ':' '\n' | while read -r dir; do
  for f in "$dir"/applications/*.desktop; do
    [ -f "$f" ] && printf '%s\0' "$f"
  done
done | xargs -0 awk '
  function emit() { if (file != "" && type == "Application" && !hide && name != "" && !(id in seen)) { seen[id] = 1; print id "\t" name "\t" icon } }
  FNR == 1 { emit(); file = FILENAME; n = split(FILENAME, p, "/"); id = p[n]; name = ""; icon = ""; type = ""; hide = 0; entry = 0 }
  /^\[/ { entry = ($0 == "[Desktop Entry]"); next }
  entry && /^Name=/ { name = substr($0, 6) }
  entry && /^Icon=/ { icon = substr($0, 6) }
  entry && /^Type=/ { type = substr($0, 6) }
  entry && /^(NoDisplay|Hidden)=true/ { hide = 1 }
  END { emit() }
'

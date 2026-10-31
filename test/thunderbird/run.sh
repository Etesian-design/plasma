#!/bin/bash
# Checks the Etesian Thunderbird theme (look/thunderbird, packed as install.sh packs it): Thunderbird in a throwaway container
# picks it up from a profile's extensions folder, the user's one switch turns it on (enable.cfg), and a screenshot lands in test/out-thunderbird/thunderbird.png.
set -e
cd "$(dirname "$0")/../.."
docker build -q -t etesian-thunderbird-test test/thunderbird >/dev/null
mkdir -p test/out-thunderbird && chmod 777 test/out-thunderbird
docker run --rm -v "$PWD:/src:ro" -v "$PWD/test/out-thunderbird:/out" etesian-thunderbird-test timeout 120 bash -c '
  set -e
  p=~/tb; mkdir -p $p/extensions
  python /src/look/thunderbird/pack.py "$p/extensions/theme@etesian-design.com.xpi"
  printf "user_pref(\"extensions.autoDisableScopes\", 0);\nuser_pref(\"extensions.activeThemeID\", \"theme@etesian-design.com\");\nuser_pref(\"mail.provider.suppress_dialog_on_startup\", true);\nuser_pref(\"mailnews.start_page.enabled\", false);\n" >$p/user.js
  Xvfb :9 -screen 0 1280x800x24 >/dev/null 2>&1 & export DISPLAY=:9; sleep 1
  thunderbird --profile $p >/out/thunderbird.log 2>&1 &
  sleep 25
  xwd -root -silent | magick xwd:- /out/thunderbird.png
  # the header bar left of the search field: the Etesian bar colour (stock Thunderbird is light grey there)
  px=$(magick /out/thunderbird.png -format "%[pixel:p{200,10}]" info:)
  case "$px" in *"21,21,21"*) echo "PASS Thunderbird shows the Etesian header bar ($px)" ;; *) echo "FAIL Thunderbird header is $px, not the Etesian bar" ;; esac
  # the folder pane: Etesian Dark surface, like the message list beside it (not a white pane next to black ones)
  px=$(magick /out/thunderbird.png -format "%[pixel:p{150,400}]" info:)
  case "$px" in *"22,22,22"*) echo "PASS the folder pane is the Etesian dark surface ($px)" ;; *) echo "FAIL the folder pane is $px" ;; esac
'

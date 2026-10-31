# The look on real apps: a file manager over a text editor, with the Etesian menu bar and dock.
source /src/test/check.sh
kate /src/README.md >/out/kate.log 2>&1 &
sleep 3
dolphin /src >/out/dolphin.log 2>&1 &
sleep 5
shot look-apps

expect "colour scheme" "$(cfg kdeglobals General ColorScheme)" Etesian
expect "accent is Etesian blue" "$(cfg kdeglobals General AccentColor)" 69,145,255
expect "accent not from wallpaper" "$(cfg kdeglobals General accentColorFromWallpaper)" false
expect "plasma style" "$(cfg plasmarc Theme name)" etesian
expect "font has no Nokia face" "$(cfg kdeglobals General font | cut -d, -f1)" "Open Sans"
info="$(qdbus6 org.kde.KWin /KWin org.kde.KWin.supportInformation)"
# the native Etesian decoration (built for each distro by run.sh); without it install.sh falls back to the Aurorae theme
expect_has "decoration plugin" "$info" "org.etesian.decoration"
expect "no side borders" "$(cfg kwinrc org.kde.kdecoration2 BorderSize)" None
expect "icon theme" "$(cfg kdeglobals Icons Theme)" Etesian
expect "Etesian icons installed" "$(ls ~/.local/share/icons/Etesian/apps/scalable/org.kde.dolphin.svg 2>/dev/null | wc -l)" 1
panels="$(plasma_eval 'print(panels().map(p => p.location + (p.floating ? "/floating" : "") + ":" + p.widgets().map(w => w.type).join(",")).join(" | "))')"
expect_has "menu bar on top" "$panels" "top:org.etesian.appname,org.kde.plasma.appmenu,org.kde.plasma.panelspacer,org.etesian.events,org.etesian.spotlight,org.kde.plasma.systemtray,org.etesian.status,org.kde.plasma.digitalclock"
expect_has "floating Etesian dock on the left" "$panels" "left/floating:org.etesian.launcher,org.etesian.dock"
expect "two panels only" "$(plasma_eval 'print(panels().length)')" 2
# Sounds, cursors, wallpaper and splash: Etesian's own (no Nokia files)
expect "sound theme" "$(cfg kdeglobals Sounds Theme)" Etesian
expect "sound theme installed" "$(ls ~/.local/share/sounds/Etesian/stereo/message-new-instant.wav >/dev/null 2>&1 && echo yes)" yes
expect "cursor theme" "$(cfg kcminputrc Mouse cursorTheme)" Etesian-cursors
expect "busy cursor is animated (12 frames)" "$(grep -c filename ~/.local/share/icons/Etesian-cursors/cursors_scalable/wait/metadata.json)" 12
expect "splash" "$(cfg ksplashrc KSplash Theme)" org.etesian.desktop
expect_has "wallpaper" "$(grep -h '^Image=' ~/.config/plasma-org.kde.plasma.desktop-appletsrc | head -n 1)" wallpapers/Etesian
! grep -rqi nokia ~/.local/share/sounds/Etesian ~/.local/share/icons/Etesian-cursors ~/.local/share/wallpapers/Etesian && echo "PASS no Nokia material in the assets" >>/out/result.txt

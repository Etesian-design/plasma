#!/bin/bash
# Puts the Breeze look back and removes the Etesian files that install.sh copied (current user only).
#   ./uninstall.sh --layout  also resets the panels to Plasma's default layout
set -e
data="${XDG_DATA_HOME:-$HOME/.local/share}"
if [ "$1" = --layout ]; then plasma-apply-lookandfeel --apply org.kde.breeze.desktop --resetLayout
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
rm -rf "$data/plasma/plasmoids/org.etesian.dock" "$data/plasma/plasmoids/org.etesian.appname" "$data/plasma/plasmoids/org.etesian.events" "$data/plasma/plasmoids/org.etesian.launcher" "$data/plasma/plasmoids/org.etesian.status" "$data/plasma/plasmoids/org.etesian.spotlight" "$data/kwin/scripts/etesian-snap" "$data/kwin/effects/etesian_windows" "$data/kwin/effects/etesian_snaplayouts" "$data/kwin/tabbox/etesian_carousel" "$data/aurorae/themes/Etesian" "$data/plasma/desktoptheme/etesian" "$data/plasma/look-and-feel/org.etesian.desktop" "$data/icons/Etesian" "$HOME/.local/lib/qt6/plugins/org.kde.kdecoration3/org.etesian.decoration.so" "$HOME/.config/plasma-workspace/env/etesian-plugins.sh" "$data/sounds/Etesian" "$data/icons/Etesian-cursors" "$data/wallpapers/Etesian"
kwriteconfig6 --file kdeglobals --group Sounds --key Theme ocean
kwriteconfig6 --file kcminputrc --group Mouse --key cursorTheme breeze_cursors
plasma-apply-cursortheme breeze_cursors >/dev/null 2>&1 || true
kwriteconfig6 --file ksplashrc --group KSplash --key Theme org.kde.breeze.desktop
kwriteconfig6 --file kwinrc --group Etesian --key HeaderActions --delete
kwriteconfig6 --file kwinrc --group Etesian --key HeaderActionApps --delete
rm -f "$data/color-schemes/Etesian.colors" "$data/color-schemes/EtesianDark.colors"
qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
echo "Breeze restored. Log out and back in once for the shortcuts."

# The user's own settings before Etesian: a dark Breeze, the grid task switcher and a shortcut of their own.
kwriteconfig6 --file kdeglobals --group General --key ColorScheme BreezeDark
kwriteconfig6 --file kwinrc --group TabBox --key LayoutName thumbnail_grid
kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Show Desktop" "Meta+D,Meta+D,Peek at Desktop"

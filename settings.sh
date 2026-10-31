# The settings files install.sh changes (in ~/.config): install.sh keeps the user's own copies before its first change and
# uninstall.sh puts them back. Sourced by both.
config="${XDG_CONFIG_HOME:-$HOME/.config}"
etesian_settings=(kdeglobals kwinrc kglobalshortcutsrc kcminputrc ksplashrc plasmarc
  plasma-org.kde.plasma.desktop-appletsrc plasmashellrc)

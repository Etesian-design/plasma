#!/bin/sh
# Optional: the Etesian login screen for SDDM. The login screen is system-wide, so this one step needs sudo; everything
# else (install.sh) stays per-user. Undo with: sudo ./install-sddm.sh --remove
# Preview first, without touching the system: sddm-greeter-qt6 --test-mode --theme look/sddm/etesian
set -eu
here=$(cd "$(dirname "$0")" && pwd)
themes=/usr/share/sddm/themes; conf=/etc/sddm.conf.d/etesian.conf
[ "$(id -u)" = 0 ] || { echo "Run with sudo: sudo $0 $*" >&2; exit 1; }
if [ "${1:-}" = --remove ]; then rm -rf "$themes/etesian" "$conf"; echo "Etesian login screen removed (SDDM uses its default again)."; exit 0; fi
mkdir -p "$themes" /etc/sddm.conf.d
rm -rf "$themes/etesian.new" && cp -r "$here/look/sddm/etesian" "$themes/etesian.new" && rm -rf "$themes/etesian" && mv "$themes/etesian.new" "$themes/etesian"
printf '[Theme]\nCurrent=etesian\n' >"$conf"
echo "Etesian login screen installed; it shows at the next login screen."

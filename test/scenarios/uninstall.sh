# uninstall.sh puts back the user's own settings and panels (kept by the first install.sh), not just Breeze.
source /src/test/check.sh
expect "installed: colour scheme" "$(cfg kdeglobals General ColorScheme)" Etesian
expect "installed: Etesian switcher" "$(cfg kwinrc TabBox LayoutName)" etesian_carousel
expect "backup kept the user's scheme" "$(kreadconfig6 --file ~/.local/share/etesian/backup/kdeglobals --group General --key ColorScheme)" BreezeDark
mkdir -p ~/.thunderbird/abc.default && printf '[Profile0]\nName=default\nIsRelative=1\nPath=abc.default\n' >~/.thunderbird/profiles.ini
/src/install.sh >/out/install-again.log 2>&1 # updating must not replace the kept settings with Etesian's
expect "a second install keeps the user's scheme" "$(kreadconfig6 --file ~/.local/share/etesian/backup/kdeglobals --group General --key ColorScheme)" BreezeDark
xpi=~/.thunderbird/abc.default/extensions/theme@etesian-design.com.xpi
expect "the Thunderbird theme is in the Thunderbird profile" "$(python3 -c "import zipfile, json, sys; print(json.load(zipfile.ZipFile(sys.argv[1]).open('manifest.json'))['browser_specific_settings']['gecko']['id'])" $xpi 2>&1)" theme@etesian-design.com
expect "the mail plugin is installed" "$(ls ~/.local/lib/qt6/qml/org/etesian/mail/qmldir ~/.config/plasma-workspace/env/etesian-qml.sh 2>/dev/null | wc -l)" 2

/src/uninstall.sh >/out/uninstall.log 2>&1
for i in $(seq 40); do qdbus6 org.kde.plasmashell /PlasmaShell >/dev/null 2>&1 && break; sleep 0.5; done; sleep 6
shot uninstalled
expect "user's colour scheme back" "$(cfg kdeglobals General ColorScheme)" BreezeDark
expect "user's task switcher back" "$(cfg kwinrc TabBox LayoutName)" thumbnail_grid
expect "user's own shortcut kept" "$(cfg kglobalshortcutsrc kwin 'Show Desktop' | cut -d, -f1)" Meta+D
expect "Etesian shortcut gone" "$(cfg kglobalshortcutsrc kwin 'Etesian Windows')" ""
expect "Etesian font gone" "$(cfg kdeglobals General font)" ""
panels="$(plasma_eval 'print(panels().map(p => p.widgets().map(w => w.type).join(",")).join(" | "))')"
expect "Plasma is running again" "$(qdbus6 org.kde.plasmashell >/dev/null 2>&1 && echo yes)" yes
case "$panels" in *org.etesian*) expect "no Etesian panels" "$panels" "(no org.etesian)" ;; *) expect "no Etesian panels" ok ok ;; esac
expect_has "Plasma's own panel back" "$panels" "org.kde.plasma.icontasks"
expect "Etesian files gone" "$(ls -d ~/.local/share/plasma/plasmoids/org.etesian.* ~/.local/share/kwin/effects/etesian_* ~/.local/share/color-schemes/Etesian* 2>/dev/null | wc -l)" 0
expect "Thunderbird theme and mail plugin gone" "$(ls $xpi ~/.local/lib/qt6/qml/org/etesian/mail ~/.config/plasma-workspace/env/etesian-qml.sh 2>/dev/null | wc -l)" 0
expect "kept settings removed" "$(ls -d ~/.local/share/etesian 2>/dev/null | wc -l)" 0

# Folders, file types, devices and app icons in a real file manager: all from the Etesian theme (scripts/icons.ts), none from
# Breeze. A folder of sample files in Dolphin's icon view, and the places panel.
source /src/test/check.sh
d=/tmp/files; mkdir -p $d/Documents $d/Music
for f in notes.txt page.html script.py report.pdf song.mp3 clip.mp4 photo.png archive.zip sheet.ods letter.odt disk.iso; do
  : > "$d/$f"
done
printf '%%PDF-1.4\n' > $d/report.pdf; printf 'PK\003\004' > $d/archive.zip; printf '\211PNG\r\n\032\n' > $d/photo.png
dolphin --new-window $d >/out/dolphin.log 2>&1 &
sleep 6
shot icons-dolphin

theme=~/.local/share/icons/Etesian
# the file an icon name has in the Etesian theme (kiconfinder6 is not in every distro's packages)
find_icon() { find "$theme" -name "$1.svg" -o -name "$1.svgz" -o -name "$1.png" | head -n 1; }
for n in folder folder-documents folder-music user-home user-trash text-plain application-pdf audio-x-generic video-x-generic drive-harddisk; do
  expect_has "$n is Etesian's" "$(find_icon $n)" "$theme/"
done
expect_has "Dolphin's app icon is Etesian's" "$(find_icon org.kde.dolphin)" "$theme/apps/"
expect_has "Konsole's app icon is the N9 shell" "$(find_icon org.kde.konsole)" .png
expect_has "Kate's app icon is the N9 notes" "$(find_icon org.kde.kate)" .png
expect "icon theme credits shipped" "$(ls $theme/CREDITS 2>/dev/null | wc -l)" 1
expect "no broken links in the icon theme" "$(find -L $theme -type l | wc -l)" 0
# What the running session resolves (KDE's own lookup, the one apps and Plasma use), not only what the theme has on disk.
for n in kate utilities-terminal preferences-system org.kde.dolphin folder text-plain; do
  expect_has "the session resolves $n to Etesian's" "$(kiconfinder6 $n 2>/dev/null | tail -n 1)" "$theme/"
done
# The look-and-feel must not name another icon theme: applying it switched the running Plasma to Breeze's app icons (2026-11-23).
expect "look-and-feel keeps the Etesian icons" "$(sed -n '/^\[kdeglobals\]\[Icons\]/{n;p}' /src/look/lnf/org.etesian.desktop/contents/defaults)" "Theme=Etesian"
# A name of ours must not take over a Breeze action under it (KDE tries document-new, then document, in this theme first): Kate's
# New/Open/Save became the document page (2026-11-23). Those resolve to Breeze's own drawing, copied into the theme's breeze/.
for n in document-new document-open document-save battery-050; do
  expect_has "$n is still Breeze's" "$(kiconfinder6 $n 2>/dev/null | tail -n 1)" "/breeze/"
done

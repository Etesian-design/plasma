# Status menu: the icons in the menu bar open the menu with its toggles and sliders; the tray no longer shows its own copies.
source /src/test/check.sh
expect "tray leaves Wi-Fi, Bluetooth, battery and volume to the status menu" \
  "$(plasma_eval 'const t = panels()[0].widgets("org.kde.plasma.systemtray")[0]; const c = t; c.currentConfigGroup = ["General"]; print(String(c.readConfig("extraItems")).split(",").filter(i => /networkmanagement|bluetooth|battery|volume/.test(i)).length)')" 0
keys "sleep 0.5" "shot status-bar"
# The status button sits just left of the clock.
keys "move 1440 16" "click" "sleep 1.5" "shot status-open"
# Toggles sit two per row from the menu's top-left: Silent (first, there is no Wi-Fi or Bluetooth hardware here), then Focus.
keys "move 1330 76" "click" "sleep 0.8" "move 1500 76" "click" "sleep 0.8" "shot status-toggled" "tap ESC"
expect "Silent mutes the output" "$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null)" "Mute: yes"
expect_has "Focus turns on Do not disturb" "$(kreadconfig6 --file plasmanotifyrc --group DoNotDisturb --key Until)" "$(date +%Y)"
grep -iE "etesian" /out/plasma.log | head -n 20 >/out/plasma-qml.txt || true
expect "no QML errors from the Etesian widgets" "$(grep -c . /out/plasma-qml.txt)" 0

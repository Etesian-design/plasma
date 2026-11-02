# Keyboard snapping into three columns ("Snapped"): Super+Left/Right between columns, Super+Up maximises,
# Super+Down floats the window again at its old size. Zones are computed here independently of the script under test.
source /src/test/check.sh
kate /src/README.md >/out/kate.log 2>&1 & sleep 4
before="$(active_geometry)"
read ax ay aw ah <<<"$(work_area | tr ',x' '  ')"
zone() { # zoneRects() from etesian-design geometry.ts for thirds, GAP 8
  python3 -c "
ax,ay,aw,ah,i=$ax,$ay,$aw,$ah,$1; fx=i/3; fw=1/3; G=8
x0=round(ax+fx*aw); x1=round(ax+(fx+fw)*aw)
l=x0+(G if i==0 else G/2); r=x1-(G if i==2 else G/2)
print(f'{int(l)},{ay+G} {int(r-l)}x{ah-2*G}')"
}
expect "snap scripts enabled" "$(cfg kwinrc Plugins etesian-snapEnabled)" true
keys "down LEFTMETA" "tap LEFT" "up LEFTMETA" "sleep 0.6"
expect "Super+Left from floating: first column" "$(active_geometry)" "$(zone 0)"
keys "down LEFTMETA" "tap RIGHT" "up LEFTMETA" "sleep 0.6"
expect "Super+Right: middle column" "$(active_geometry)" "$(zone 1)"
shot snap-middle
keys "down LEFTMETA" "tap RIGHT" "tap RIGHT" "up LEFTMETA" "sleep 0.6"
expect "Super+Right stops at the last column" "$(active_geometry)" "$(zone 2)"
keys "down LEFTMETA" "tap UP" "up LEFTMETA" "sleep 0.6"
expect "Super+Up maximises" "$(active_geometry)" "$ax,$ay ${aw}x${ah}"
keys "down LEFTMETA" "tap DOWN" "up LEFTMETA" "sleep 0.6"
expect "Super+Down floats at the old size" "$(active_geometry)" "$before"

# Drag to snap: grab the title bar, the zones appear, releasing over zone 1 snaps there.
half() { python3 -c "
ax,ay,aw,ah,i=$ax,$ay,$aw,$ah,$1; G=8; x0=round(ax+i*aw/2); x1=round(ax+(i+1)*aw/2)
l=x0+(G if i==0 else G/2); r=x1-(G if i==1 else G/2); print(f'{int(l)},{ay+G} {int(r-l)}x{ah-2*G}')"; }
read gx gy _ <<<"$(active_geometry | tr ',' ' ')"
cx=$((ax + aw / 6)); cy=$((ay + ah / 2))
keys "move $((gx + 300)) $((gy + 20))" "press" "move $((gx + 340)) $((gy + 60))" "sleep 0.3" "move $cx $cy" "sleep 0.8" "shot snap-drag-zones" "release" "sleep 0.8"
expect "drag onto zone 1 snaps into the first column" "$(active_geometry)" "$(zone 0)"
# Super+Z, 1 (halves), 2: the right half.
keys "down LEFTMETA" "tap Z" "up LEFTMETA" "sleep 0.8" "shot snap-picker" "tap 1" "tap 2" "sleep 0.8"
expect "Super+Z, 1, 2 snaps into the right half" "$(active_geometry)" "$(half 1)"
# Drag to the top edge: the picker drops; release over the third column of "Three columns".
read gx gy _ <<<"$(active_geometry | tr ',' ' ')"
px=$((ax + (aw - 640) / 2 + 18 + 190 + 16 + 160)); py=$((ay + 10 + 56 + 45))
keys "move $((gx + 200)) $((gy + 20))" "press" "move $((gx + 240)) $((gy + 60))" "sleep 0.3" "move $((ax + aw / 2)) $((ay + 4))" "sleep 0.5" "move $px $py" "sleep 0.8" "shot snap-drag-picker" "release" "sleep 0.8"
expect "drag to the top, drop on the picker: third column" "$(active_geometry)" "$(zone 2)"
grep -iE "etesian|\.qml" /out/kwin.log | head -n 20 >/out/kwin-qml.txt || true

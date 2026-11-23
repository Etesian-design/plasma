# Controls inside Qt apps in the Etesian widget style (look/style): squircle-half buttons and fields, the 30 px lit squircle slider
# knob on a 4 px groove, squircle check boxes and radio marks, a 6 px progress pill. A gallery window (look/style/test) shows them.
source /src/test/check.sh
expect "widget style" "$(cfg kdeglobals KDE widgetStyle)" Etesian
expect "style plugin installed" "$(ls ~/.local/lib/qt6/plugins/styles/etesian.so 2>/dev/null | wc -l)" 1
/deco/style/etesian-controls >/out/controls.log 2>&1 &
sleep 4
expect_has "the gallery runs in the Etesian style" "$(active_caption)" "Controls — etesian"
shot controls
python3 - <<'EOF' >>/out/result.txt
# The slider: a thin accent band (the fill, 4 px), and on it a white knob about 27 px wide, not Breeze's round handle.
from PIL import Image
im = Image.open('/out/controls.png').convert('RGB')
W, H = im.size
def white(c): return min(c) > 225
def accent(c): return c[2] > 150 and c[2] - c[0] > 60
rows = {}
for y in range(H):
    n = sum(1 for x in range(0, W, 2) if accent(im.getpixel((x, y))))
    if n: rows[y] = n
# the slider fill is a 4 px band of accent: a run of 3-6 rows with many accent pixels
band = [y for y, n in rows.items() if n > 40]
runs, cur = [], []
for y in sorted(band):
    if cur and y != cur[-1] + 1: runs.append(cur); cur = []
    cur.append(y)
if cur: runs.append(cur)
thin = [r for r in runs if 3 <= len(r) <= 6]
print(("PASS" if thin else "FAIL") + f" slider fill is a thin accent band (bands {[len(r) for r in runs]})")
if thin:
    y = thin[0][len(thin[0]) // 2]
    xs = [x for x in range(W) if accent(im.getpixel((x, y)))]
    end = max(xs)  # the fill ends at the knob
    knob = [x for x in range(end, min(W, end + 40)) if white(im.getpixel((x, y - 6)))]
    print(("PASS" if 18 <= len(knob) <= 30 else "FAIL") + f" a white squircle knob sits on the groove ({len(knob)} px wide)")
EOF

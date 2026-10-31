# Sends keyboard and pointer input into the test session through KWin's org_kde_kwin_fake_input protocol (allowed because
# the test KWin runs with KWIN_WAYLAND_NO_PERMISSION_CHECKS). Steps run in order:
#   down KEY | up KEY | tap KEY   keys by Linux name without KEY_ (LEFTMETA, TAB, LEFTSHIFT, ESC, ENTER, D, ...)
#   wheel N                       N mouse-wheel notches (negative = up / zoom in)
#   move X Y | click | press | release   absolute pointer position, left click / button down / up
#   rclick                               right click
#   sleep S
#   shot NAME                     screenshot to /out/NAME.png while keys stay held (KWin drops a fake device's
#                                 held keys when its process exits, so hold-and-look needs one process)
# Example: python3 input.py "down LEFTMETA" "tap TAB" "sleep 1" "up LEFTMETA"
import os, subprocess, sys, time, glob, importlib

GEN = '/tmp/fakeinput-py'
if not os.path.isdir(GEN):
    xml = glob.glob('/usr/share/plasma-wayland-protocols/fake-input.xml')[0]
    subprocess.run([sys.executable, '-m', 'pywayland.scanner', '-i', xml, '-o', GEN], check=True)
sys.path.insert(0, GEN)
from pywayland.client import Display
FakeInput = importlib.import_module('fake_input').OrgKdeKwinFakeInput

KEYS = {'ESC': 1, 'TAB': 15, 'ENTER': 28, 'LEFTCTRL': 29, 'LEFTSHIFT': 42, 'LEFTALT': 56, 'SPACE': 57, 'LEFTMETA': 125,
        'UP': 103, 'LEFT': 105, 'RIGHT': 106, 'DOWN': 108, 'N': 49, 'Z': 44, 'D': 32, 'T': 20, 'K': 37, 'O': 24, 'A': 30, '1': 2, '2': 3, '3': 4, '4': 5, '5': 6, '6': 7}
BTN_LEFT, WHEEL = 0x110, 0  # linux button code, wl_pointer.axis.vertical_scroll
BTN_RIGHT = 0x111

display = Display(); display.connect()
registry = display.get_registry()
found = {}
def on_global(reg, name, iface, ver): found[iface] = (name, ver)
registry.dispatcher['global'] = on_global
display.roundtrip()
name, ver = found['org_kde_kwin_fake_input']
fake = registry.bind(name, FakeInput, min(ver, 5))
fake.authenticate('etesian-plasma tests', 'drive the session in tests')
display.roundtrip()

def key(k, pressed): fake.keyboard_key(KEYS[k], 1 if pressed else 0)
for step in sys.argv[1:]:
    op, *a = step.split()
    if op == 'down': key(a[0], True)
    elif op == 'up': key(a[0], False)
    elif op == 'tap': key(a[0], True); display.roundtrip(); key(a[0], False)
    elif op == 'wheel': [fake.axis(WHEEL, 15.0 if int(a[0]) > 0 else -15.0) or display.roundtrip() or time.sleep(0.05) for _ in range(abs(int(a[0])))]
    elif op == 'move': fake.pointer_motion_absolute(float(a[0]), float(a[1]))
    elif op == 'press': fake.button(BTN_LEFT, 1)
    elif op == 'release': fake.button(BTN_LEFT, 0)
    elif op == 'click': fake.button(BTN_LEFT, 1); display.roundtrip(); fake.button(BTN_LEFT, 0)
    elif op == 'rclick': fake.button(BTN_RIGHT, 1); display.roundtrip(); fake.button(BTN_RIGHT, 0)
    elif op == 'sleep': display.roundtrip(); time.sleep(float(a[0])); continue
    elif op == 'shot': display.roundtrip(); subprocess.run([sys.executable, '/src/test/shot.py', f'/out/{a[0]}.png'], check=True); continue
    else: sys.exit(f'unknown step {step}')
    display.roundtrip(); time.sleep(0.05)
display.disconnect()

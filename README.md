# Etesian for KDE Plasma

The Etesian desktop (etesian-design, *Explorations / Desktop v2*) on KDE Plasma 6: the N9 look and, step by step, its
behaviour. Supported: Plasma 6.6 (Kubuntu 26.04 LTS) and newer; every change is tested on 6.6 and on the latest Plasma.

## What you get

- **Colours** generated from the etesian-design tokens: *Etesian* (light pages under dark chrome, like the phone) and
  *Etesian Dark*. The accent is the Etesian blue, never taken from the wallpaper.
- **Window decoration** (native, look/decoration): a 44 px N9 header bar, the app squircle and the title on the left in
  the light face, then the app's actions, the app menu (…), a thin divider and minimise / maximise / close; every button
  gets a squircle on hover (red for close); inactive windows show the header at half strength. No side or bottom borders.
  KDE apps listed in `HeaderActionApps` under `[Etesian]` in kwinrc (default Kate and KWrite) get their toolbar's actions
  (New, Open, Save, Undo, Redo, read from the menu the app exports) in the header and their own toolbars hidden: one row
  of chrome. `HeaderActions=false` there gives every app its own toolbar back. Without a way to build the plugin, the
  install falls back to an Aurorae theme with the same header bar and no app actions.
- **Plasma style**: panels and popups use the dark overlay colours.
- **Layout** (optional, `--layout`): the global menu bar on top (the focused app's name in bold, its menus, then the
  Events bubble, tray, the status icons and "Fri 30 Oct 12:45" at the far right) and the floating dock on the left: the
  Overview button (accent squircle) | separator | pinned and running apps as lit squircles in their icon's colour, a dot
  for running and an accent dot for the active app | separator | recycle bin, always last.
- **Dock**: hover a running app for a live preview of its window (scroll to cycle a group's windows); right-click for
  edit mode (remove pins, drag the handle to another edge, the gear opens Style, Position, Size, Visibility, Widgets).
- **Status menu** (the Wi-Fi, Bluetooth and battery icons): Wi-Fi, Bluetooth, Silent and Focus toggles, volume and
  brightness, the battery and Settings. A part whose service is missing is left out.
- **Icons**: lit squircle app icons and line symbols (scripts/icons.ts), Breeze for everything else.
- **Font**: Open Sans (no Nokia fonts).
- **Sounds, cursors, wallpaper, splash**, all made for Etesian with no Nokia material: glassy bell sounds (scripts/sounds.py),
  SVG cursors with a squircle busy spinner (scripts/cursors.ts), the Desktop v2 background (scripts/wallpaper.py) and the
  phone's boot screen as the splash (ETESIAN in Fira Sans Medium, SIL OFL).
- **Windows view** (Super+Tab, a KWin effect): the carousel, one large live card with its neighbours at half strength.
  Hold Super and tap Tab / Shift+Tab, release Super to switch. Super+wheel zooms to 2, 3 or 4 per row and locks the view
  open as a task viewer (Tab, arrows, Enter, a click, Esc). Cards keep each window's shape; the menu bar and dock stay
  on top. Alt+Tab keeps KWin's switcher, drawn as the same carousel.
- **Touchpad**: three-finger pinch = Super+wheel (pinching in opens the viewer at 3 per row); three fingers sideways
  minimise the window in front, and bring windows back once none is left; three fingers down close the window, only
  with `SwipeDownClose=true` under `[Effect-etesian_windows]` in kwinrc (off by default).
- **Overview** (tap Super, or the dock's first button), the main menu kept from Desktop v1: full screen under the menu
  bar, slightly see-through with the windows blurred behind. The phone's Events view on the left, the open windows as live
  pictures in the middle (a close squircle on hover), the apps on the right. Just start typing to search apps and files;
  Tab moves between the columns, Enter opens, Ctrl+W closes a window, Esc or Super closes it.
- **Spotlight** (Super+Space), added by Desktop v2 next to the Overview: a compact search field and app grid over the
  windows; typing filters, Enter opens the first match, Esc closes.
- **Events** (Super+N, or the bubble in the menu bar; also the Overview's left column): the day and date (a click unfolds
  the month, days with entries dotted), the time with the weather (Open-Meteo; click to set the city), then
  Notifications, Calendar (the picked day) and Feeds (RSS / Atom; paste an address to add one). The city and the feeds
  are shared by the sidebar and the Overview (~/.config/etesianrc).
- **Snapping**: dragging a window shows the numbered zones; release over one to snap. Dragging to the top edge drops the
  layout picker (six layouts); Super+Z opens it from the keyboard (1-6 for the layout, then the zone number).
  Super+Left / Super+Right move between three columns, Super+Up maximises, Super+Down floats the window again.

Shortcuts take effect after logging out and back in once.

### Not yet as designed

- Events: calendar entries come from Plasma's calendar plugins (holidays; KDE PIM calendars when installed).
- Search finds apps and files (Plasma's runners); people and mail need KDE PIM.
- Decorations: header actions only for the apps in `HeaderActionApps` (an app whose toolbar holds more than the common
  file and edit actions, like Dolphin's location bar, keeps its toolbar); no Back button for KDE apps.

## Install (current user only, no sudo)

The native decoration is built on install: with `cmake` and the KDecoration3 headers here (Kubuntu:
`sudo apt install cmake g++ extra-cmake-modules qt6-base-dev libkdecorations3-dev libkf6coreaddons-dev`), otherwise in a
throwaway Kubuntu 26.04 Docker container (look/decoration/build.sh). It goes to ~/.local/lib/qt6/plugins, and a Plasma
env script adds that to the plugin path, so it is used from the next login. If neither works, the Aurorae header bar is
used instead (`sudo apt install kwin-style-aurorae`; Arch: `aurorae`).

The plugin is tied to the Plasma version it was built for (KDecoration, major.minor). After a Plasma update the login
script (look/decoration/env.sh) switches to the Aurorae header bar by itself, and back once `./install.sh` has rebuilt the
plugin, so an update never leaves windows without a header.

    ./install.sh            # look and behaviour; your panels stay as they are
    ./install.sh --layout   # also replaces your panels with the Etesian menu bar and dock
    ./uninstall.sh          # your own settings and panels back, as before the first install
    ./uninstall.sh --breeze # Breeze instead (add --layout for Plasma's default panels)

The first install keeps a copy of the settings it changes (~/.local/share/etesian/backup); running it again to update never
replaces that copy, and uninstalling puts it back and deletes it.

The login screen (SDDM) is system-wide, so it is a separate step with sudo: the Desktop v2 background, the time in the
light face, the user as a squircle, a password pill, session and power squircles (look/sddm/etesian, Fira Sans).

    sddm-greeter-qt6 --test-mode --theme look/sddm/etesian   # preview, changes nothing
    sudo ./install-sddm.sh                                   # use it (sudo ./install-sddm.sh --remove undoes it)

## Develop

The look is generated; edit the scripts, not the output:

    node --experimental-strip-types scripts/colors.ts [path/to/etesian-design]   # look/colors/
    node --experimental-strip-types scripts/aurorae.ts                           # look/aurorae/Etesian/
    node --experimental-strip-types scripts/icons.ts                             # look/icons/Etesian/
    look/decoration/build.sh                                                     # look/decoration/build/

Tests run Plasma in throwaway Docker containers with no screen, install the look into a fresh user, open real apps,
check the settings and take screenshots (test/out/):

    test/all.sh               # every scenario on Plasma 6.6 (Kubuntu 26.04) and the latest Plasma (Arch)
    test/run.sh windows arch  # one scenario (test/scenarios/) on one distro

Scenarios press keys through KWin's fake-input protocol (test/input.py), read KWin state with one-off KWin scripts
(test/check.sh) and fail on any `FAIL` line. `test/lint.sh` catches QML that Plasma would refuse and checks that the
files shared between widgets are identical copies. `KWIN_GDB=1 test/run.sh …` runs KWin under gdb, so a crash leaves
its backtrace in test/out/kwin.log.

They need a GPU render node (`/dev/dri/renderD128`, override with `DRI_NODE=`): without OpenGL KWin cannot take
screenshots. The containers relax KWin's permission checks and drop a file capability from kwin_wayland; that is only
inside the test images, never on the machine.

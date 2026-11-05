<p align="center">
  <img src=".github/readme/overview.png" width="860" alt="The Overview: Events on the left, the open windows in the middle, the apps on the right">
</p>

<h1 align="center">Etesian for KDE Plasma</h1>

<p align="center">
  <b>A calm, gesture-first desktop for KDE Plasma.</b><br>
  One Overview for everything new, your open windows and your apps; a global menu bar, a floating dock and a carousel of
  open windows. Its influence is the Nokia N9's Swipe UI, re-envisioned for the desktop.
</p>

<p align="center">
  <a href="https://etesian-design.com/desktop">Try it in your browser</a> ·
  <a href="https://etesian-design.com">Website</a> ·
  <a href="https://language.etesian-design.com">Design language</a> ·
  <a href="https://github.com/etesian-design/android_vendor_etesian">Phone</a>
</p>

<p align="center">
  <img alt="Licence: MIT" src="https://img.shields.io/badge/licence-MIT-4591FF">
  <img alt="Plasma 6.6+" src="https://img.shields.io/badge/Plasma-6.6%2B-1D99F3">
  <img alt="Status: in development" src="https://img.shields.io/badge/status-in%20development-EF5500">
</p>

---

This repository is the Etesian look and behaviour for KDE Plasma, one of the platforms of the Etesian design language.

Not a theme pack. Etesian changes how Plasma **works** as well as how it looks: the way you switch windows, snap them,
find apps and catch up on what's new. It installs for your user only, needs no root, and one command puts everything
back.

<table>
  <tr>
    <td><img src=".github/readme/overview-search.webp" alt="Tapping Super opens the Overview; typing searches at once"></td>
    <td><img src=".github/readme/windows.webp" alt="Super+Tab steps through the open windows as a carousel; scrolling shows three per row"></td>
  </tr>
  <tr>
    <td align="center"><b>Overview</b>: tap Super, just start typing</td>
    <td align="center"><b>Windows</b>: Super+Tab, then scroll for a grid</td>
  </tr>
  <tr>
    <td><img src=".github/readme/events.png" alt="Events beside the windows: notifications, weather, calendar and feeds"></td>
    <td><img src=".github/readme/snap-layouts.png" alt="Snap layouts: six arrangements, picked by number"></td>
  </tr>
  <tr>
    <td align="center"><b>Events</b>: Super+N, everything new in one list</td>
    <td align="center"><b>Snap layouts</b>: Super+Z, or drag a window to the top</td>
  </tr>
  <tr>
    <td><img src=".github/readme/desktop.png" alt="The desktop: the menu bar, the floating dock and window headers with the app's own actions"></td>
    <td><img src=".github/readme/windows-grid.png" alt="All open windows, three per row"></td>
  </tr>
  <tr>
    <td align="center"><b>The desktop</b>: menu bar, dock, one row of chrome</td>
    <td align="center"><b>Every window at once</b>: pick one or press Esc</td>
  </tr>
</table>

The pictures come from `test/run.sh showcase` and `scripts/readme-anim.py`, in a throwaway Plasma container.

## Highlights

- **Windows as a carousel.** Super+Tab shows one large card at a time; scroll to see 2, 3 or 4 per row.
- **Snapping that shows you where.** Drag a window and numbered zones appear. Drag it to the top for six layouts.
- **One place for what's new.** Events gathers notifications, today's calendar, your RSS feeds and the weather.
- **Window headers with the app's own actions.** Kate's New, Open and Save sit in the title bar, so a window has one
  row of chrome.
- **The whole look.** Colours, lit squircle icons, cursors, sounds, wallpaper, boot splash, login screen, and a
  matching Thunderbird theme.
- **Belle widgets** on the desktop: flip clock, word clock, feeds and mail.

## Install

Plasma 6.6 (Kubuntu 26.04) or newer.

```sh
./install.sh            # the look and behaviour; your panels stay as they are
./install.sh --layout   # also the Etesian menu bar and dock
```

Log out and back in once. Changed your mind?

```sh
./uninstall.sh          # everything back as it was
```

<details>
<summary>Building the native parts, the login screen, and going back to Breeze</summary>

The window header and the Mail widget's KMail support are small native plugins, built on install. With the build tools
installed they build on your machine:

```sh
sudo apt install cmake g++ extra-cmake-modules qt6-base-dev libkdecorations3-dev libkf6coreaddons-dev
sudo apt install qt6-declarative-dev libakonadi-dev libakonadimime-dev libkmime-dev   # Mail widget
```

Otherwise they build in a throwaway Docker container. If neither works, you get a simpler header
(`kwin-style-aurorae`). After a Plasma update, the simpler header is used until you run `./install.sh` again.

The login screen is system-wide, so it's a separate step:

```sh
sddm-greeter-qt6 --test-mode --theme look/sddm/etesian   # preview
sudo ./install-sddm.sh                                   # use it (--remove to undo)
```

`./uninstall.sh --breeze` switches to plain Breeze instead of your old settings; add `--layout` for Plasma's default
panels.
</details>

## Keys

| Keys | What they do |
|---|---|
| <kbd>Super</kbd> | Overview |
| <kbd>Super</kbd> <kbd>Space</kbd> | Search |
| <kbd>Super</kbd> <kbd>N</kbd> | Events |
| <kbd>Super</kbd> <kbd>Tab</kbd> | Open windows |
| <kbd>Super</kbd> <kbd>Z</kbd> | Snap layouts |
| <kbd>Super</kbd> <kbd>←</kbd> <kbd>→</kbd> <kbd>↑</kbd> <kbd>↓</kbd> | Move between columns, maximise, float |

On a touchpad: pinch with three fingers to zoom the windows view, swipe sideways with three fingers to minimise.

<details>
<summary>Settings and what isn't finished</summary>

In `~/.config/kwinrc`:

- `[Etesian] HeaderActionApps` lists the apps whose toolbar moves into the header (default: Kate, KWrite);
  `HeaderActions=false` turns it off.
- `[Effect-etesian_windows] SwipeDownClose=true` lets a three-finger swipe down close a window.

Not finished yet:

- Your own calendars, and people and mail in search, need KDE PIM.
- The Mail widget reads KMail only.
- Only some apps get their actions in the header, and KDE apps have no Back button.
</details>

## Contributing

The colours, icons and themes are generated by `scripts/*.ts`. Edit those scripts, not what they generate in `look/`.

Every change is tested on real Plasma sessions in throwaway Docker containers: on 6.6 and on the latest Plasma.
Nothing is installed on your machine.

```sh
test/all.sh               # everything
test/run.sh windows arch  # one scenario on one distro
test/lint.sh              # quick QML checks, no Docker
```

The tests need a GPU render node (`/dev/dri/renderD128`, or set `DRI_NODE`).

## Related projects

The [design language](https://github.com/etesian-design/design) this is built from, the
[phone](https://github.com/etesian-design/android_vendor_etesian) (any LineageOS phone) and
[the website](https://github.com/etesian-design/website).

## Licence

MIT. Fira Sans (splash and login) is under the SIL OFL. No Nokia material.

Etesian is an independent project and isn't affiliated with Nokia.

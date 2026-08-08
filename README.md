<div align="center">

<img src="https://shieldcn.dev/header/graph.svg?title=Gauge&subtitle=Pixel-precise%20desktop%20alignment%20for%20macOS&theme=rose&logo=https%3A%2F%2Fraw.githubusercontent.com%2FKhaledSaeed18%2Fgauge%2Fmain%2FResources%2FGaugeMark.png&size=lg&align=center" width="820" alt="Gauge" />
<p>
  <img src="https://shieldcn.dev/badge/platform-macOS%2014%2B-red.svg?variant=secondary&logo=apple&logoColor=ffffff" alt="Platform: macOS 14+" />
  <img src="https://shieldcn.dev/badge/Swift-6.0-orange.svg?variant=secondary&logo=swift&logoColor=ffffff" alt="Swift 6" />
  <img src="https://shieldcn.dev/badge/interface-menu%20bar%20%2B%20overlay-red.svg?variant=secondary" alt="Interface: menu bar + overlay" />
  <a href="https://github.com/KhaledSaeed18/gauge/actions/workflows/ci.yml"><img src="https://shieldcn.dev/github/ci/KhaledSaeed18/gauge.svg?workflow=ci.yml&branch=main&variant=secondary" alt="CI status" /></a>
  <a href="LICENSE"><img src="https://shieldcn.dev/badge/license-MIT-green.svg?variant=secondary" alt="License: MIT" /></a>
</p>
<strong>Align anything. Everywhere.</strong>

</div>

Gauge is a native macOS overlay for lining up anything on your desktop: browser UIs, native apps,
screenshots, designs, and prototypes. It gives every display physical-pixel rulers and persistent
alignment guides while letting every click pass straight through to the work beneath.

Most ruler tools live inside one browser tab or one design app. Gauge belongs to the desktop. Turn
it on from the menu bar, place guides over any surface, then turn it off just as quickly.

## Why Gauge

- **It is a desktop tool, not a browser extension.** Rulers and guides work over every normal app,
  browser window, and connected display.
- **It measures physical pixels.** Tick labels respect each screen's backing scale factor, so `100`
  means 100 actual display pixels on Retina and non-Retina screens alike.
- **It stays out of the way.** The overlay ignores mouse events except when Guide Placement is on and
  you intentionally use a ruler to add or drag a guide.
- **It is always within reach.** The menu-bar icon controls visibility, settings, and cleanup; `⌃⌥⌘R`
  toggles the rulers from anywhere.
- **It remembers your layout.** Guides persist between launches and are stored separately for each
  display.

## Features

| Tool | What it does |
|------|--------------|
| Rulers | Shows physical-pixel rulers at the top and left edges of every display |
| Guides | Draws persistent vertical and horizontal alignment lines across the screen |
| Guide Placement | Clicks or drags on a ruler to add or position a guide; enabled by default |
| Guide Numbers | Optionally labels placed guides as `V1`, `V2`, `H1`, `H2`, sorted by position |
| Selective Removal | Removes one, several, or all guides from the menu bar or Settings |
| Menu bar | Shows, hides, places, numbers, removes, configures, and quits without a Dock icon |
| Settings | Uses tabs for Appearance, Guides, Startup, and About |
| Displays | Keeps ruler and guide state independent across multiple displays |

On top of the core tools:

- **Click-through overlay**: normal work continues underneath the rulers.
- **Separate axis colors**: choose different colors for vertical guides and horizontal guides.
- **More color choices**: pick from red, orange, yellow, green, mint, cyan, blue, purple, pink,
  and white.
- **Launch without showing rulers**: start Gauge at login while keeping the overlay hidden until
  you need it.
- **Reset settings**: restore Gauge's default appearance and startup behavior from Settings.
- **Optional descriptions**: show or hide the small setting explanations inside the Settings window.
- **Full-screen friendly**: participates in all spaces and full-screen auxiliary windows.

## How it works

Gauge runs as a native macOS menu-bar app with no Dock icon. It creates transparent, non-activating
AppKit panels for each connected screen; each panel draws high-DPI-aware ticks, labels, and guide
lines in the appropriate screen coordinate space.

Guide Placement uses narrow, temporary input panels over only the two ruler strips. Outside those
strips the desktop remains click-through. When you click or drag the top ruler, Gauge records a
vertical guide; the left ruler creates a horizontal one. Positions are saved as physical pixels and
restored per display.

Guide labels are derived from the current layout rather than stored as fixed names. Vertical guides
are numbered `V1`, `V2`, and so on by position; horizontal guides are numbered separately as `H1`,
`H2`, and so on. If you delete or move a guide, the visible numbering updates to match the screen.

## Install

Requires macOS 14 or later and Xcode 16 or later.

```bash
git clone https://github.com/KhaledSaeed18/gauge
cd gauge
open Package.swift                         # build and run in Xcode
```

Or build a standalone app bundle:

```bash
./Scripts/make-app.sh
open Build/Gauge.app
```

Gauge is a menu-bar app with no Dock icon. Look for the ruler mark in the menu bar after launch.

## Usage

### Menu bar

Click the ruler mark to show or hide the overlay, toggle **Guide Placement**, turn **Guide Numbers**
on or off, remove guides, open Settings, or quit. Guide Placement is on by default, so you can add
guides immediately after launch.

Use **Remove Guides...** to open a small checklist for deleting exactly the guides you choose. You
can select one guide, several guides, or leave everything untouched. **Clear All Guides** is still
available when you want to remove every guide at once.

### Rulers and guides

1. Keep **Guide Placement: On** in the menu bar.
2. Click or drag on the **top ruler** to create or position a vertical guide.
3. Click or drag on the **left ruler** to create or position a horizontal guide.
4. Turn on **Guide Numbers** if you want labels such as `V1` or `H3` beside the guides.
5. Use **Remove Guides...** or **Clear All Guides** when you want to clean up.

The app uses `⌃⌥⌘R` to show or hide rulers globally. When Guide Placement is off, the overlay is
completely click-through.

## Configuration

Settings includes:

- **Appearance**: ruler thickness, ruler background opacity, vertical guide color, and horizontal
  guide color. Vertical guide color controls the top ruler and vertical guides; horizontal guide
  color controls the left ruler and horizontal guides.
- **Guides**: tick label interval, guide numbering, selected guide removal, select all, clear
  selection, and remove all guides.
- **Startup**: start Gauge at login, choose whether rulers appear when Gauge starts, and view the
  global shortcut.
- **About**: a short description of Gauge and a direct link to the GitHub repository.
- **Reset Settings**: restores appearance, startup behavior, guide numbering, and setting
  descriptions to the defaults. Existing guide lines are kept.
- **Show setting descriptions**: hides or shows the small helper text under settings.

For non-technical users, the Settings window is the main control center: Appearance changes how the
overlay looks, Guides controls labels and cleanup, Startup controls what happens when the Mac starts,
and About explains what Gauge is.

For technical users, Gauge stores lightweight preferences and guide data in `UserDefaults`, uses
physical-pixel coordinates per display, and keeps guide numbering derived from sorted positions
instead of persisting display labels.

## Architecture

Gauge has a compact native Swift architecture:

- **`OverlayManager`** creates and coordinates the overlay and guide-input panels for every screen.
- **`RulerOverlayView`** is the high-DPI AppKit drawing surface for rulers, labels, and guide lines.
- **`GuideStore`** persists guide positions per display through `UserDefaults`.
- **`RulerSettings`** persists appearance, startup, guide numbering, and Settings UI preferences.
- **`StatusBarController`** owns the menu-bar item and all user-facing commands.
- **`SettingsView`** provides the tabbed SwiftUI settings interface.

## Development

```bash
swift build                 # compile the app
./Scripts/make-app.sh       # produce Build/Gauge.app
open Package.swift          # open as a Swift package in Xcode
```

## Requirements

- macOS 14 (Sonoma) or later
- Xcode 16 or later
- Apple Silicon or Intel

## License

MIT. See [LICENSE](LICENSE).

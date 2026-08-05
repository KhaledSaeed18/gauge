<div align="center">

<img src="https://shieldcn.dev/header/graph.svg?title=Gauge&subtitle=Pixel-precise%20desktop%20alignment%20for%20macOS&theme=red&logo=https%3A%2F%2Fraw.githubusercontent.com%2FKhaledSaeed18%2Fgauge%2Fmain%2FResources%2FGaugeMark.png&size=lg&align=center" width="820" alt="Gauge" />
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
| Guide Placement | Clicks or drags on a ruler to add or position a guide |
| Menu bar | Shows, hides, configures, clears, and quits without a Dock icon |
| Settings | Adjusts thickness, background transparency, accent color, and label interval |
| Displays | Keeps ruler and guide state independent across multiple displays |

On top of the core tools:

- **Click-through overlay**: normal work continues underneath the rulers.
- **Red by default**: change the ruler and guide accent to blue in Settings if preferred.
- **Launch at login**: keep Gauge ready whenever the Mac starts.
- **Full-screen friendly**: participates in all spaces and full-screen auxiliary windows.

## How it works

Gauge runs as a native macOS menu-bar app with no Dock icon. It creates transparent, non-activating
AppKit panels for each connected screen; each panel draws high-DPI-aware ticks, labels, and guide
lines in the appropriate screen coordinate space.

Guide Placement uses narrow, temporary input panels over only the two ruler strips. Outside those
strips the desktop remains click-through. When you click or drag the top ruler, Gauge records a
vertical guide; the left ruler creates a horizontal one. Positions are saved as physical pixels and
restored per display.

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

Click the ruler mark to show or hide the overlay, enable **Guide Placement**, clear all guides, open
Settings, or quit. Guide Placement stays on until you turn it off, so you can add several guides in
one pass.

### Rulers and guides

1. Choose **Guide Placement: Off** in the menu bar to enable placement.
2. Click or drag on the **top ruler** to create or position a vertical guide.
3. Click or drag on the **left ruler** to create or position a horizontal guide.
4. Choose **Clear All Guides** when you want a clean canvas.

The app uses `⌃⌥⌘R` to show or hide rulers globally. When Guide Placement is off, the overlay is
completely click-through.

## Configuration

Settings includes:

- **Appearance**: ruler thickness, transparent background intensity, red or blue accent, and label
  interval.
- **Behavior**: launch at login and the global visibility shortcut.

## Architecture

Gauge has a compact native Swift architecture:

- **`OverlayManager`** creates and coordinates the overlay and guide-input panels for every screen.
- **`RulerOverlayView`** is the high-DPI AppKit drawing surface for rulers, labels, and guide lines.
- **`GuideStore`** persists guide positions per display through `UserDefaults`.
- **`StatusBarController`** owns the menu-bar item and all user-facing commands.

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

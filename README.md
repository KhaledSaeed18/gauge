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

<br/>

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
- **It stays out of the way.** The overlay ignores mouse events except when you deliberately place a
  guide, measure a distance, or turn on the crosshair.
- **It measures, not just marks.** Drag out any region to read its size in physical pixels, hold the
  result on screen, and copy it to the clipboard.
- **It is always within reach.** The menu-bar icon controls every tool; `⌃⌥⌘R` toggles the rulers,
  `⌃⌥⌘M` starts measuring, and `⌃⌥⌘C` toggles the crosshair from anywhere.
- **It remembers your layout.** Guides persist between launches and are stored separately for each
  display.

## Features

| Tool | What it does |
|------|--------------|
| Rulers | Shows physical-pixel rulers at the top and left edges of every display |
| Guides | Draws persistent vertical and horizontal alignment lines across the screen |
| Guide Placement | Clicks or drags on a ruler to add or position a guide; enabled by default |
| Guide Numbers | Optionally labels placed guides as `V1`, `V2`, `H1`, `H2`, sorted by position |
| Measure Distance | Click and drag to measure any region (or Option-drag for a two-point line); dimensions hold on screen and copy to the clipboard |
| Crosshair | Full-screen lines follow the pointer with a live pixel readout to check alignment instantly |
| Color Sampler | Hover to read the pixel color under the pointer (hex + RGB); click to copy |
| Loupe | Magnified, pixel-accurate view under the pointer with the exact pixel, its coordinate, and color |
| Selective Removal | Removes one, several, or all guides from the menu bar or Settings |
| Menu bar | Shows, hides, measures, checks alignment, places guides, configures, and quits without a Dock icon |
| Settings | A sidebar with Appearance, Guides, Measure, Crosshair, Color, Loupe, Startup, and About |
| Displays | Keeps ruler and guide state independent across multiple displays |

On top of the core tools:

- **Measure between elements**: drag out a box to read its width and height in physical pixels, then
  leave it on screen while you compare it to anything else.
- **Copy dimensions instantly**: each measurement copies its `width × height` to the clipboard, and
  `⌘C` re-copies the last one during a session.
- **Crosshair alignment check**: run full-screen guides through the pointer to see, at a glance, what
  lines up with what.
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

Click the ruler mark to show or hide the overlay, start **Measure Distance**, toggle the
**Crosshair**, clear held measurements, toggle **Guide Placement**, turn **Guide Numbers** on or off,
remove guides, open Settings, or quit. Guide Placement is on by default, so you can add guides
immediately after launch.

Use **Remove Guides...** to open a small checklist for deleting exactly the guides you choose. You
can select one guide, several guides, or leave everything untouched. **Clear All Guides** is still
available when you want to remove every guide at once.

### Rulers and guides

1. Keep **Guide Placement: On** in the menu bar.
2. Click or drag on the **top ruler** to create or position a vertical guide.
3. Click or drag on the **left ruler** to create or position a horizontal guide.
4. Turn on **Guide Numbers** if you want labels such as `V1` or `H3` beside the guides.
5. For precise work, open **Settings → Guides**: add a guide at an exact pixel, or nudge any existing
   guide's position with its stepper.
6. Use **Remove Guides...** or **Clear All Guides** when you want to clean up.

The app uses `⌃⌥⌘R` to show or hide rulers globally. When Guide Placement is off and no measuring
mode is active, the overlay is completely click-through.

### Measure distance

1. Press `⌃⌥⌘M` or choose **Measure Distance** from the menu bar.
2. Click and drag anywhere on screen to draw a measurement box; its `width × height` updates live in
   physical pixels. Hold **Option** while dragging to measure a straight line instead — it reports the
   distance and angle between the two points.
3. Release to hold the measurement on screen. It stays visible while you work, even after you exit
   the mode, until you clear it.
4. Dimensions copy to the clipboard automatically (toggle this off in Settings → Measure). Press
   `⌘C` to re-copy the last measurement, `Delete` to remove it, and `Esc` to exit measuring. Choose
   the clipboard format in Settings → Measure — dimensions (`320 × 200`), plain (`320x200`), with
   units (`320px × 200px`), CSS (`width: 320px; height: 200px;`), or with position (`320 × 200 @ 100, 50`).
5. Click a held box (without dragging) to remove just that one, or use **Clear Measurements** in the
   menu bar to remove every held box at once.

### Crosshair

1. Press `⌃⌥⌘C` or choose **Crosshair** from the menu bar.
2. Move the pointer: a full-width and full-height line follow it, with a live `x, y` pixel readout.
3. Line the crosshair up with any element edge to see everything else that shares that row or column.
4. Press `Esc` or toggle it off when you are done.

### Color sampler

1. Press `⌃⌥⌘P` or choose **Color Sampler** from the menu bar.
2. Move the pointer to read the pixel color underneath, shown as a swatch with its hex and RGB values.
3. Click to copy the color (choose Hex or RGB in Settings → Color). Press `Esc` to exit.

The color sampler reads the screen, so macOS asks for **Screen Recording** permission the first time.
Grant it in **System Settings → Privacy & Security → Screen Recording**; until then the swatch shows a
reminder instead of a color.

### Loupe

1. Press `⌃⌥⌘Z` or choose **Loupe** from the menu bar.
2. Move the pointer to see a magnified, pixel-accurate view of the area beneath it, with the exact
   pixel highlighted and its coordinate and color shown.
3. Toggle the pixel grid in **Settings → Loupe**. Press `Esc` to exit.

Like the color sampler, the loupe needs **Screen Recording** permission the first time.

While Measure Distance or Crosshair is active, Gauge owns the pointer so it can track your drag; the
menu bar stays available so you can switch tools or exit at any time.

### Keyboard shortcuts

| Shortcut | Action |
|----------|--------|
| `⌃⌥⌘R` | Show or hide the rulers (works anywhere) |
| `⌃⌥⌘M` | Start or stop Measure Distance |
| `⌃⌥⌘C` | Turn the Crosshair on or off |
| `⌃⌥⌘P` | Turn the Color Sampler on or off |
| `⌃⌥⌘Z` | Turn the Loupe on or off |
| `⌘C` | Copy the last measurement (while measuring) |
| `Delete` | Remove the last measurement (while measuring) |
| `Esc` | Exit the active Measure or Crosshair mode |

The mode shortcuts (`⌃⌥⌘R/M/C`) are global. The in-session keys (`⌘C`, `Delete`, `Esc`) rely on a
global key monitor; if they do not respond, grant Gauge **Input Monitoring** in System Settings, or
just toggle the mode off with its shortcut or the menu bar.

## Configuration

Settings includes:

- **Appearance**: ruler thickness, ruler background opacity, vertical guide color, and horizontal
  guide color. Vertical guide color controls the top ruler and vertical guides; horizontal guide
  color controls the left ruler and horizontal guides.
- **Guides**: tick label interval, guide numbering, exact-pixel guide placement, per-guide position
  editing, selected guide removal, select all, clear selection, and remove all guides.
- **Measure**: automatic clipboard copy after measuring, the clipboard format (dimensions, plain,
  with units, CSS, or with position), dimension-label visibility, optional on-screen position and
  aspect-ratio badges, and the measurement color.
- **Crosshair**: coordinate-readout visibility and the crosshair line color.
- **Color**: the color-sampler copy format (Hex or RGB).
- **Loupe**: the magnifier pixel-grid visibility.
- **Startup**: start Gauge at login, choose whether rulers appear when Gauge starts, and view the
  global shortcut.
- **About**: a short description of Gauge and a direct link to the GitHub repository.
- **Reset Settings**: restores appearance, startup behavior, guide numbering, measure and crosshair
  options, and setting descriptions to the defaults. Existing guide lines and measurements are kept.
- **Show setting descriptions**: hides or shows the small helper text under settings.

For non-technical users, the Settings window is the main control center with a simple sidebar:
Appearance changes how the overlay looks, Guides controls labels and cleanup, Measure and Crosshair
tune the inspection tools, Startup controls what happens when the Mac starts, and About explains what
Gauge is.

For technical users, Gauge stores lightweight preferences and guide data in `UserDefaults`, uses
physical-pixel coordinates per display, and keeps guide numbering derived from sorted positions
instead of persisting display labels.

## Architecture

Gauge has a compact native Swift architecture split across two targets — a pure `GaugeCore` library
and the `Gauge` executable that draws the AppKit overlay:

- **`GaugeCore`** is a UI-free library. **`DisplayGeometry`** is its single source of truth for
  point↔pixel conversion and the menu-bar inset, so the same math is not duplicated across views and
  can be unit tested without a real screen.
- **`OverlayManager`** creates and coordinates the ruler, guide-input, crosshair/measure, and
  held-measurement panels for every screen, and manages the crosshair and measure modes.
- **`RulerOverlayView`** is the high-DPI AppKit drawing surface for rulers, labels, and guide lines.
- **`MeasureOverlay`** provides the interactive crosshair/measure/color-sampler/loupe panel and the
  click-through panel that keeps committed measurements on screen.
- **`ScreenCapture`** wraps the screen-capture calls used by the color sampler and loupe.
- **`GuideStore`** persists guide positions per display through `UserDefaults`.
- **`MeasurementStore`** holds committed measurements in physical pixels for the current session.
- **`RulerSettings`** persists appearance, startup, guide numbering, measure, and Settings UI preferences.
- **`StatusBarController`** owns the menu-bar item and all user-facing commands.
- **`SettingsView`** provides the sidebar-based SwiftUI settings interface.

## Development

```bash
swift build                 # compile the app
swift test                  # run the GaugeCore unit tests
./Scripts/make-app.sh       # produce Build/Gauge.app
open Package.swift          # open as a Swift package in Xcode
```

## Requirements

- macOS 14 (Sonoma) or later
- Xcode 16 or later
- Apple Silicon or Intel

## License

MIT. See [LICENSE](LICENSE).

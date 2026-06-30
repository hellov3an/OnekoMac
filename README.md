<div align="center">

<img src="Resources/Sprites/oneko-classic.gif" width="64" height="64" />

# OnekoMac+

**A pixel cat that lives in your menu bar and chases your cursor — forever.**

*Native macOS app. Metal GPU rendering. 120 Hz. No Electron. No bloat.*

[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-black?logo=apple)](https://github.com/hellov3an/OnekoMac/releases)
[![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange?logo=swift)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue)](LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/hellov3an/OnekoMac?style=social)](https://github.com/hellov3an/OnekoMac/stargazers)

---

<!-- Replace with an actual screen recording GIF -->
![OnekoMac demo](https://github.com/hellov3an/OnekoMac/assets/demo.gif)

</div>

---

## What is this?

In 1989, a Japanese programmer put a tiny cat on the desktop that chased the cursor.  
It became one of the most beloved pieces of software ever written.

**OnekoMac+** brings that cat back — as a proper native macOS app, rebuilt from scratch:

- Runs as a floating overlay above every window, every Space, every full-screen app
- Rendered with Metal at up to 120 Hz (ProMotion-aware)
- Follows your cursor with the original `oneko.js` animation logic, 1:1 ported
- Idles, scratches the wall, falls asleep if you leave it alone
- Lives quietly in your menu bar

No Dock icon. No subscriptions. No tracking. Just a cat.

---

## Skins

| Classic | Dog | Tora | Maia | Vaporwave |
|:-------:|:---:|:----:|:----:|:---------:|
| <img src="Resources/Sprites/oneko-classic.gif" width="64"/> | <img src="Resources/Sprites/oneko-dog.gif" width="64"/> | <img src="Resources/Sprites/oneko-tora.gif" width="64"/> | <img src="Resources/Sprites/oneko-maia.gif" width="64"/> | <img src="Resources/Sprites/oneko-vaporwave.gif" width="64"/> |

Switch between skins at any time from the settings panel.

---

## Install

### Download (recommended)

1. Go to [**Releases**](https://github.com/hellov3an/OnekoMac/releases/latest)
2. Download `OnekoMac.dmg`
3. Drag to Applications
4. Launch — the cat appears immediately

> The app will ask for no permissions. If your cursor is moving, the cat follows it.

### Homebrew *(coming soon)*

```sh
brew install --cask onekomac
```

### Build from source

```sh
git clone https://github.com/hellov3an/OnekoMac
cd OnekoMac
xcodegen generate
open OnekoMac.xcodeproj
```

Requires Xcode 15+, macOS 13+ SDK, and [xcodegen](https://github.com/yonaskolb/XcodeGen).

---

## Features

- **Metal GPU renderer** — CAMetalLayer + CVDisplayLink + triple-buffered command queue
- **120 Hz** — frame-synced to ProMotion displays, smooth on 60 Hz too
- **oneko.js logic** — 8-directional movement, idle states, scratch, sleep
- **5 pixel-art skins** — sourced from [kyrie25/spicetify-oneko](https://github.com/kyrie25/spicetify-oneko)
- **Floating settings panel** — skin picker with live previews, FPS counter
- **Auto-update checker** — checks GitHub Releases, one click to update
- **Zero CPU at idle** — CVDisplayLink only renders when needed
- **Universal Binary** — Apple Silicon and Intel

---

## How it works

The cat runs a 100 ms logic tick (matching the original JavaScript timing):

1. Compute distance to cursor
2. If far → pick 8-directional movement animation → move by 10 pts/tick
3. If near → idle, then scratch, then sleep

Sprites come from a 256×128 px GIF atlas (8×4 grid of 32×32 px frames).  
The Metal shader converts top-left screen coordinates to NDC in one pass.

---

## Contributing

PRs welcome. If you're adding a new skin, drop a 256×128 GIF in `Resources/Sprites/` and register it in `SkinManager.skinIDs`.

Bug reports → [Issues](https://github.com/hellov3an/OnekoMac/issues)

---

## Credits

- Original **oneko** — Masayuki Koba, 1989
- Sprite artwork — [kyrie25/spicetify-oneko](https://github.com/kyrie25/spicetify-oneko)
- Built with Swift + Metal by [@hellov3an](https://github.com/hellov3an)

---

<div align="center">

*If this made you smile, hit the ⭐ — it helps more people find the cat.*

</div>

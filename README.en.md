<div align="center">

<img src="website/public/img/app-icon-180.png" width="128" height="128" alt="RightKit Icon" />

# RightKit

**Context Menu Toolkit for macOS Finder. Do more with a right-click.**

Lightweight, native, and clean. An efficient context menu utility built with modern SwiftUI and a lightweight Finder Sync Extension.

<p>
  <a href="README.md">简体中文</a> •
  <a href="README.en.md"><strong>English</strong></a> •
  <a href="README.ja.md">日本語</a> •
  <a href="README.ko.md">한국어</a>
</p>

[![macOS 26+](https://img.shields.io/badge/macOS-26%2B-000000?style=flat&logo=apple&logoColor=white)](https://rightkit.yiliang.app/en/)
[![Swift 6](https://img.shields.io/badge/Swift-6.0-F05138?style=flat&logo=swift&logoColor=white)](https://swift.org)
[![Mac App Store](https://img.shields.io/badge/Mac_App_Store-Available-007AFF?style=flat&logo=apple&logoColor=white)](https://apps.apple.com/app/id6816212746)
[![GitHub Release](https://img.shields.io/badge/Release-0.1.3-34C759?style=flat)](https://github.com/AquaHydro/rightkit/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-FF8F6C?style=flat)](LICENSE)
[![App Sandbox](https://img.shields.io/badge/App_Sandbox-Enabled-2A2B31?style=flat)](docs/technical.md)

[Website](https://rightkit.yiliang.app/en/) · [Mac App Store](https://apps.apple.com/app/id6816212746) · [Download DMG](https://github.com/AquaHydro/rightkit/releases/latest) · [Feature Specs](docs/features.md) · [Design Guidelines](DESIGN.md) · [Architecture](docs/technical.md)

</div>

---

<p align="center">
  <img src="docs/evidence/app-store/en/01-new-file.png" alt="RightKit Preview" width="880" />
</p>

## 💡 Why RightKit?

macOS Finder is elegant and restrained, but common everyday operations often require taking the long road: creating a new document or spreadsheet means launching an application first; opening Terminal means copying paths and typing `cd`; reorganizing files requires side-by-side windows; and generating app icons or calculating checksums means searching for single-purpose apps.

**RightKit** brings these frequent workflows right under your cursor:

- **Pure & Native**: Strictly follows Apple Human Interface Guidelines and macOS design principles. No clutter, no unnecessary UI gimmicks, seamlessly blending into Finder.
- **Millisecond Response**: Decoupled architecture where the main app handles heavy tasks while the Finder extension focuses strictly on menu assembly. Built-in prewarming and icon bitmap caching keep right-click menus instantaneous.
- **Context-Aware Matching**: Intelligently inspects the selected target (empty space, single file, folder bundle, or images) to assemble only relevant commands, keeping your context menu clean.
- **Sandboxed & Zero Data Collection**: Runs 100% inside Apple App Sandbox. Only accesses folders you explicitly authorize; all file operations run entirely on your Mac with zero network tracking and zero telemetry.
- **Critical Path Protection**: Permanent deletion requires confirmation, while root `/`, user home folders, and system directories are strictly safeguarded against accidental deletion.

---

## ✨ Features

### 1. New File

Right-click anywhere and start drafting immediately.

- **12 Built-in Formats**: Plain Text (.txt), Markdown (.md), Rich Text (.rtf), Word (.docx), Excel (.xlsx), PowerPoint (.pptx), JSON, XML, HTML, CSS, JavaScript, and Shell Script (.sh).
- **Custom Templates**: Drag any project template or document into RightKit; it creates a complete clone whenever you need it.
- **Conflict-Free Numbering**: Automatically suffixes duplicates (e.g. `Untitled 2.docx`). Never overwrites existing files.
- **Configurable Workflow**: Optionally toggle "Ask for file name before creating" or "Open with default app after creation".

<p align="center">
  <img src="docs/evidence/app-store/en/01-new-file.png" alt="New File Showcase" width="820" />
</p>

### 2. Cut, Copy & Move

Brings fluid cut-and-move mechanics to macOS Finder.

- **Cut & Paste**: Right-click to Cut, then right-click in another folder to Paste and move. Uses a dedicated internal queue without polluting your system clipboard.
- **Send To Presets**: Pin frequent destination directories in Send To, allowing single-click Copy To or Move To actions.
- **Favorite Folders**: Open frequent directories directly from empty space context menus.
- **Native Progress Sheet**: Automatically displays a native progress dialog when transfers exceed 1 second, with full cancellation support.

<p align="center">
  <img src="docs/evidence/app-store/en/02-move-to.png" alt="Copy and Move Showcase" width="820" />
</p>

### 3. Open in App

Streamlined workflow designed for developers, designers, and power users.

- **Smart Context Routing**: Opening a file launches it in your editor; opening a directory launches Terminal at that exact working path.
- **Automatic Tool Detection**: Automatically recognizes Terminal, Ghostty, Visual Studio Code, and Xcode. You can also register any `.app` on your Mac.
- **Safe Workspace Dispatch**: Relies purely on system Workspace APIs rather than vulnerable shell string concatenation.

<p align="center">
  <img src="docs/evidence/app-store/en/03-open-in-app.png" alt="Open in App Showcase" width="820" />
</p>

### 4. 16 Essential File Tools

A versatile toolbox for everyday file actions, individually toggleable and reorderable:

| Group | Command | Description |
| --- | --- | --- |
| **Path & Naming** | Copy Path, Copy Name | Copies POSIX paths or display names; right-clicking empty space offers "Copy Current Path" |
| **Organization** | New Folder from Name | Packages the selected file into a newly created folder named after the file |
| | Make Alias on Desktop | Instantly creates a desktop alias for the selected item |
| | AirDrop | Invokes the native AirDrop sharing sheet for selected files |
| | Grant Write Permission | Adds write permissions for the current user (non-recursive, retains ownership) |
| | File Info (Checksum) | Streams local calculations for MD5, SHA-1, SHA-256, and SHA-512 |
| **Visibility** | Hide or Show Selected | Toggles hidden file flags without touching the command line |
| | Hide or Show Extension | Toggles whether file extensions are visible in Finder |
| **Media & Icons** | Convert Image | Converts images on-site to PNG, JPEG, HEIC, or TIFF |
| | Make macOS Icon Set | Exports both `.iconset` directories and standard `.icns` files |
| | Make iOS Icon Set | Generates App Icon folders containing 13 standard pixel resolutions |
| | Set as Wallpaper, Set Folder Icon | Sets image as desktop wallpaper, or customizes folder icons directly |
| **Disposal** | Dissolve Folder | Moves direct child items up to the parent directory and moves the empty folder to Trash |
| | Delete Permanently | Bypasses Trash for permanent deletion, guarded by confirmation and protected path checks |

<p align="center">
  <img src="docs/evidence/app-store/en/04-toolbox.png" alt="Toolbox Showcase" width="820" />
</p>

### 5. Beyond the Context Menu

- **Shortcuts & Spotlight**: Exposes New File, File Hash, Image Conversion, Icon Generation, and QR Code actions to system automation.
- **macOS Services**:
  - **Offline QR Code**: Generate crisp QR codes from selected text locally, with quick save and copy options.
  - **Web Translation**: Send selected text to Google Translate or Baidu Translate in your default browser.
- **Multilingual Support**: Fully localized in English, Simplified Chinese, Japanese, and Korean.

---

## 📥 Download & Installation

RightKit is distributed across two channels from a single unified codebase:

| Feature | Mac App Store Edition | Website Edition (GitHub Release) |
| --- | --- | --- |
| **Acquisition** | [Purchase on Mac App Store](https://apps.apple.com/app/id6816212746) | [Free DMG on GitHub Releases](https://github.com/AquaHydro/rightkit/releases/latest) |
| **Target Audience** | Users who prefer App Store management and wish to support indie development | Users who prefer offline DMG installers and direct releases |
| **Features** | Complete feature set | Complete feature set |
| **Updates** | Automatic and silent via Mac App Store | Built-in check for new GitHub Releases with one-click download link |
| **Sandboxing** | App Sandbox Enabled | App Sandbox Enabled |

### First Launch Setup

Due to macOS security policies, complete two quick onboarding steps on first launch:

1. **Authorize Watched Folders**: Open RightKit and click "Authorize Personal Folder" (authorizing your user home directory is recommended). RightKit only presents context menus inside authorized directories.
2. **Enable Finder Extension**: Open "System Settings > General > Login Items & Extensions" and toggle on the RightKit Finder extension.

The Settings window features an extension status card ("Ready", "Not Running", "Background Service Disabled", or "Not Enabled") with one-click buttons to open settings or restart Finder.

<p align="center">
  <img src="docs/evidence/app-store/en/05-settings.png" alt="Settings & Status Detection" width="820" />
</p>

---

## 🛡️ Privacy & Security

1. **Strict App Sandbox**: Both the main app and Finder extension are restricted by App Sandbox. Network access is strictly scoped (Store edition has zero network entitlements; Website edition only issues read-only queries to GitHub API for updates).
2. **Security-Scoped Bookmarks**: Folder access relies entirely on macOS security-scoped bookmarks. Paths outside user-authorized folders cannot be read or modified.
3. **Protected Path Safeguards**: Permanent deletion refuses to execute on root `/`, user home folders, or core system directories (`/System`, `/Library`, `/usr`).
4. **Zero Tracking**: Contains no third-party analytics, crash reporters, or tracking SDKs. Never logs or transmits file paths or filenames.

---

## 🛠️ Architecture & Engineering

The repository is modularized into four distinct targets:

```text
RightKit (Workspace)
├── RightKit          # SwiftUI Main App: Handles Settings, Welcome window, alerts, file I/O operations, Shortcuts, and Services
├── RightKitFinder    # Lightweight Finder Sync Extension: Inspects directory targets, builds context menus, and dispatches actions
├── RightKitAgent     # LaunchAgent daemon: Hosts App Group XPC services to reliably wake the main app upon menu interaction
└── RightKitCore      # Pure Swift logic package: Rule engine, models, protected paths, and naming algorithms with 100% test coverage
```

### Finder Extension Optimization

Poorly designed Finder Sync extensions can easily freeze Finder. RightKit implements stringent performance measures:
- **Zero Heavy I/O in Menus**: Never reads files, calculates hashes, or performs disk I/O inside menu generation callbacks.
- **Prewarming**: Background prewarming connects to system icon services ahead of time to eliminate first-click lag.
- **Single-Size Bitmap Caching**: Icons sent across process boundaries are normalized into 16 pt 2x bitmap representations, avoiding costly multi-size system icon serialization.

---

## 🔨 Local Build & Development

### Prerequisites

- macOS 26 or later
- Xcode 27 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`project.yml` manages Xcode project configuration)

### Common Make Commands

```sh
# Generate project, run full test suite, build both editions, and run lint checks
make verify

# Build Debug target and run main app immediately
make run

# Build Website edition (Developer ID sign, notarize, and package DMG into .build/release/)
make release

# Build Store edition (Archive, export .pkg, and verify signatures into .build/release-appstore/)
make release-appstore

# Upload Store edition to App Store Connect
make upload-appstore
```

### Documentation Index

- [Feature Specs (docs/features.md)](docs/features.md): Authoritative product behaviors, defaults, menu rules, and error handling.
- [Design Guidelines (DESIGN.md)](DESIGN.md): Colors, typography, component layouts, and visual standards.
- [Engineering Boundaries (docs/technical.md)](docs/technical.md): Process separation, App Group IPC, sandboxing, and release pipelines.
- [Verification (docs/verification.md)](docs/verification.md): Quality checklist and test case catalog.
- [Roadmap (docs/roadmap.md)](docs/roadmap.md): Milestones and implementation order.

Validate local documentation links and rules at any time:

```sh
python3 scripts/check_docs.py
```

---

## 🎬 Official Animated Music Video: "Under the Right Click"

To embody RightKit's product philosophy and core metaphor, we created an original 90s-style anime music video for our mascot Riko: ***Under the Right Click · 右クリックの向こう*** (Runtime: 3:28, 170 BPM J-rock anime OP).

<p align="center">
  <img src="website/assets/character/hero-pv-poster-ak.png" alt="Under the Right Click MV Poster" width="820" />
</p>

### Story & Metaphor: The Entropy of Archive City

> "Fingertip suspended in the air, the cursor lights up. Three lines, they are all I believe in. 3, 2, 1... Right click! Open the backside of the world."

Set in "Archive City", a towering metropolis formed of countless filing cabinets, an unprecedented wave of entropy strikes: towers collapse, uncatalogued files scatter like snowflakes, and file paths break. **Riko**, the city's archivist, triggers her right-click ability: expanding context menus of "New File", "Copy", and "Move", restoring scattered files to their proper drawers, and reducing the city's entropy back to zero at dawn.

The story is a creative metaphor for RightKit: no matter how chaotic your desktop or directories become, a single right-click restores clarity and order.

### The "Riso-Cel" Rendering Pipeline

The full rendering pipeline for the MV is maintained directly in this repository:
- **Shader-Driven Repainting**: Processed through custom WebGL shaders (Kuwahara smoothing, XDoG cel contour lines with 12 fps line jitter, 45° halftone dots, and risograph paper texture) to forge an authentic 1990s retro cel aesthetic.
- **Open-Source Tooling**: Explore the pipeline in [`mv/under-the-right-click/`](mv/under-the-right-click/README.md), featuring headless Chrome frame-by-frame rendering, lyric timing logic, and the complete [shot-by-shot storyboard](mv/under-the-right-click/STORYBOARD.md).

<p align="center">
  <img src="mv/under-the-right-click/qa/contact-sheet.jpg" alt="Under the Right Click Contact Sheet" width="820" />
</p>

---

## 🎨 Brand Mascot & Asset Licensing

RightKit's brand mascot is **Riko**, a cheerful, quick-handed assistant with coral-gradient hair, an ahoge, and a signature cursor-menu hair clip.

- **Source Code & Documentation**: Licensed under the [MIT License](LICENSE).
- **Brand Assets Reserved**: The RightKit name, Riko character art, app icons, menu bar icons, illustrations, animations, and promotional media are proprietary with all rights reserved. See [Asset Licensing (ASSETS.md)](ASSETS.md) and [MV Licensing Notice (mv/under-the-right-click/NOTICE.md)](mv/under-the-right-click/NOTICE.md). Open-source licensing does not grant rights to reuse brand assets in other products.
- **Third-Party Trademarks & Icons**: See [Third Party Notices (THIRD_PARTY_NOTICES.md)](THIRD_PARTY_NOTICES.md) and [App Icon Sources (website/assets/apps/SOURCES.md)](website/assets/apps/SOURCES.md).

---

## 💬 Feedback & Community

- **Issue Tracker**: Submit bugs or feature requests via [GitHub Issues](https://github.com/AquaHydro/rightkit/issues).
- **Inquiries**: Contact `contact@yiliang.me`.
- **Author**: Created and maintained by [Liao Yiliang (氢氧根)](https://rightkit.yiliang.app/en/).

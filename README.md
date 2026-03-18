# App Screenshots: Store Maker

> Design beautiful App Store & Google Play screenshots, right from your desktop.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Windows%20%7C%20Linux-lightgrey)]()

A powerful, cross-platform screenshot design tool built with Flutter. Create stunning App Store Connect and Google Play Store screenshots with device frames, dynamic overlays, AI-powered translations, and direct upload to App Store Connect.

## ✨ Features

- **Multi-Instance Editing** — Edit multiple screenshot designs simultaneously in a side-by-side view
- **Dynamic Overlays** — Text, Image, and Icon overlays with rich styling, snap-to-grid, and inline editing
- **AI-Powered Translation** — Automatically translate all design elements to any locale
- **Per-Locale Customization** — Fine-tune layouts and styles per language through a comprehensive override system
- **Device Frames** — Render screenshots inside realistic device frames (iPhone, iPad, Mac, Watch, Android, etc.)
- **App Store Connect Upload** — Upload screenshots directly to ASC from the app
- **iCloud Sync** — Sync designs across devices via iCloud
- **Export & Share** — Export as PNG, copy to clipboard, or share designs as `.appshots` files
- **Keyboard Shortcuts** — Full keyboard shortcut support for power users
- **Dark Mode** — Beautiful dark and light themes

## 🚀 Quick Start

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) `^3.10.8`
- macOS, Windows, or Linux

### Install & Run

```bash
git clone https://github.com/truongduy2611/app-screenshots.git
cd app-screenshots
flutter pub get
flutter run -d macos    # or: -d windows / -d linux
```

### Apple Signing Setup (iOS / macOS)

To build for iOS or macOS, create your personal signing config:

```bash
# iOS
cp ios/Flutter/Team.xcconfig.example ios/Flutter/Team.xcconfig

# macOS
cp macos/Runner/Configs/Team.xcconfig.example macos/Runner/Configs/Team.xcconfig
```

Edit each `Team.xcconfig` and set `DEVELOPMENT_TEAM` to your Apple Team ID. These files are git-ignored so your credentials stay local.

## 🏗️ Architecture

The app follows a **Feature-Driven Architecture** using **BLoC** for state management and **GetIt** for dependency injection.

```
lib/
├── core/                        # Shared infrastructure
│   ├── di/                      # Dependency injection (GetIt)
│   ├── services/                # iCloud sync, file handling, logging
│   ├── theme/                   # App theme (light/dark)
│   ├── widgets/                 # Shared UI components
│   ├── extensions/              # Dart extensions
│   └── utils/                   # Utilities
├── features/
│   ├── screenshot_editor/       # Main editor feature
│   │   ├── data/                # Models, services, ASC API, presets
│   │   ├── domain/              # Repositories (abstract)
│   │   ├── presentation/        # Cubits, pages, widgets
│   │   └── utils/               # Editor-specific utilities
│   └── settings/                # App settings
│       ├── data/                # Settings persistence
│       ├── domain/              # Settings contracts
│       └── presentation/        # Settings UI
├── l10n/                        # Localization (ARB files)
├── app.dart                     # App widget
├── home_screen.dart
└── main.dart                    # Entry point

packages/
└── device_frame/                # Local package: device frame rendering
```

### Key Cubits

| Cubit | Responsibility |
|-------|---------------|
| `ScreenshotEditorCubit` | Design state, overlays, undo/redo, snap-to-grid |
| `ScreenshotLibraryCubit` | Saved designs, folders, import/export |
| `TranslationCubit` | AI translation, locale preview |
| `AscUploadCubit` | App Store Connect screenshot upload |
| `ThemeCubit` | Light/dark theme |
| `BackupCubit` | iCloud backup management |

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘/Ctrl + S` | Save design |
| `⌘/Ctrl + E` | Export screenshot |
| `⌘/Ctrl + G` | Zoom to fit |
| `⌘/Ctrl + U` | Upload to App Store Connect |
| `⌘/Ctrl + C` | Copy canvas to clipboard |
| `⌘/Ctrl + Z` | Undo |
| `⌘/Ctrl + ⇧ + Z` | Redo |
| `Delete` | Remove selected overlay |
| `Esc` | Deselect overlay |

## 🤝 Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the MIT License — see [LICENSE](LICENSE) for details.

## 🙏 Acknowledgements

- [device_frame](https://pub.dev/packages/device_frame) — Device frame rendering (included as local package)
- [flutter_bloc](https://pub.dev/packages/flutter_bloc) — State management
- [get_it](https://pub.dev/packages/get_it) — Dependency injection

## Star History

<a href="https://www.star-history.com/?repos=truongduy2611%2Fapp-screenshots&type=date&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/image?repos=truongduy2611/app-screenshots&type=date&theme=dark&legend=top-left" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/image?repos=truongduy2611/app-screenshots&type=date&legend=top-left" />
   <img alt="Star History Chart" src="https://api.star-history.com/image?repos=truongduy2611/app-screenshots&type=date&legend=top-left" />
 </picture>
</a>

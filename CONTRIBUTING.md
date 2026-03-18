# Contributing to App Screenshots

Thank you for your interest in contributing! We welcome contributions of all kinds — bug reports, feature requests, documentation improvements, and code changes.

## Getting Started

1. **Fork** the repository
2. **Clone** your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/app-screenshots.git
   cd app-screenshots
   ```
3. **Install dependencies**:
   ```bash
   flutter pub get
   ```
4. **Run the app**:
   ```bash
   flutter run -d macos   # or: flutter run -d windows / flutter run -d linux
   ```

## Development Setup

### Prerequisites
- Flutter SDK `^3.10.8`
- macOS, Windows, or Linux
- Dart `^3.10.8`

### Project Structure
```
lib/
├── core/              # DI, theme, services, utilities
├── features/
│   ├── screenshot_editor/  # Main editor (data/domain/presentation)
│   └── settings/           # App settings
├── l10n/              # Localization (ARB files)
├── app.dart           # App entry point
├── home_screen.dart
└── main.dart
packages/
└── device_frame/      # Local package for device frame rendering
```

### Architecture
- **State Management**: BLoC / Cubit (`flutter_bloc`)
- **Dependency Injection**: `get_it`
- **Feature-Driven**: Each feature follows `data/domain/presentation` layers

## Making Changes

### Code Style
- Follow the Dart [style guide](https://dart.dev/effective-dart/style)
- Run `dart format .` before committing
- Run `dart analyze` and fix any warnings

### Commit Messages
Use clear, descriptive commit messages:
```
feat: add gradient background picker
fix: correct screenshot export on Windows
docs: update README with CLI usage
refactor: extract overlay models to shared package
```

### Pull Requests
1. Create a feature branch from `main`
2. Make your changes with clear, focused commits
3. Ensure tests pass: `flutter test`
4. Open a PR with a description of what you changed and why

## Reporting Issues

When reporting a bug, please include:
- Flutter version (`flutter --version`)
- Operating system and version
- Steps to reproduce the issue
- Expected vs actual behavior
- Screenshots if applicable

## Feature Requests

Feature requests are welcome! Please open an issue describing:
- The problem you're trying to solve
- Your proposed solution
- Any alternatives you've considered

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).

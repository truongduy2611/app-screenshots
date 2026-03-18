# 📖 Documentation

This directory contains product and engineering documentation for App Screenshots.

## Structure

| Directory | Purpose |
|-----------|---------|
| `biz/` | Product specs — features, user stories, and acceptance criteria |
| `dev/` | Engineering docs — architecture, key files, implementation details |
| `design/` | Design system — tokens, colors, typography |

## Quick Links

### Architecture & Engineering

| Doc | Description |
|-----|-------------|
| [Architecture](dev/architecture.md) | Clean Architecture overview, BLoC/Cubit patterns, DI setup, TDD approach |

### Feature Docs

Each major feature has a **biz** spec (what it does) and a **dev** guide (how it's built):

| Feature | Product Spec | Dev Guide |
|---------|-------------|-----------|
| **Screenshot Studio** | [biz](biz/screenshot_studio.md) | [dev](dev/screenshot_studio.md) |
| **AI Design Assistant** | [biz](biz/ai_assistant.md) | [dev](dev/ai_assistant.md) |
| **AI Templates** | [biz](biz/ai_templates.md) | [dev](dev/ai_templates.md) |
| **Multi-Language Screenshots** | [biz](biz/multi_language_screenshots.md) | [dev](dev/multi_language_screenshots.md) |
| **Simulator Capture** | [biz](biz/simulator_capture.md) | [dev](dev/simulator_capture.md) |
| **CLI & Agent Control** | [biz](biz/cli_agent_control.md) | [dev](dev/cli_server.md) |

### Product-Only Docs

| Doc | Description |
|-----|-------------|
| [Design Presets](biz/design_presets.md) | Pre-built screenshot templates |
| [Design Sharing](biz/design_sharing.md) | `.appshots` file format for import/export |
| [Localization](biz/localization.md) | 18 supported UI languages |
| [Settings](biz/settings.md) | Theme, app icon, iCloud backup |

### Design

| Doc | Description |
|-----|-------------|
| [Design System](design/design_system.md) | Color tokens, typography, spacing, component specs |

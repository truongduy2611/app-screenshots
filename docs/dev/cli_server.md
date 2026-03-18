# CLI Command Server — Dev Guide

## Overview

The app embeds a lightweight HTTP server on `localhost:19222` that exposes the full editor API as JSON endpoints. This allows CLI tools and AI agents to control the running app in real-time.

## Architecture

```
CLI (appshots)  ──HTTP JSON──▶  CommandServer (dart:io HttpServer)
                                     │
                                     ▼
                           ApiRoute enum (shared)
                      ┌──────────────────────────────┐
                      │ /api/status    → app status   │
                      │ /api/editor/*  → EditorCubit  │
                      │ /api/library/* → Persistence  │
                      │ /api/translate/*→ TranslCubit │
                      │ /api/multi/*   → MultiCubit   │
                      │ /api/preset/*  → Presets       │
                      └──────────────────────────────┘
                                     │
                                     ▼
                          BLoC state emit → GUI updates live
```

## Key Files

### Main App — `lib/core/services/`

| File | Purpose |
|------|---------|
| `command_server.dart` | Core class: lifecycle, registration, HTTP layer, router, UTF-8 response encoding |
| `command_server_utils.dart` | `ServerResponse` helper, colour utilities (part file) |
| `command_server_editor.dart` | Editor route handler — 42 actions (part file) |
| `command_server_library.dart` | Library route handler — 10 actions (part file) |
| `command_server_translate.dart` | Translation route handler — 10 actions (part file) |
| `command_server_multi.dart` | Multi-design route handler — 11 actions (part file) |
| `command_server_preset.dart` | Preset route handler — 2 actions (part file) |

### Shared Package — `packages/app_screenshots_shared/`

| File | Purpose |
|------|---------|
| `api_route.dart` | `ApiRoute` enum — 6 route groups with prefix matching |
| `constants.dart` | `AppConstants` — default port, config dir, port file name |
| `actions/editor_action.dart` | `EditorAction` enum — 42 cases |
| `actions/library_action.dart` | `LibraryAction` enum — 10 cases |
| `actions/translate_action.dart` | `TranslateAction` enum — 10 cases |
| `actions/multi_action.dart` | `MultiAction` enum — 11 cases |
| `actions/preset_action.dart` | `PresetAction` enum — 2 cases |

### CLI — `packages/app_screenshots_cli/`

| File | Purpose |
|------|---------|
| `app_client.dart` | HTTP client with auto-discovery |
| `commands/editor_command.dart` | 42 editor subcommands |
| `commands/translate_command.dart` | 10 translate subcommands |
| `commands/multi_command.dart` | 11 multi subcommands |
| `commands/library_command.dart` | 10 library subcommands |
| `commands/preset_command.dart` | 2 preset subcommands |

## Action Enums

All route actions are defined as enums in the shared package. Both the server and CLI use the same enum:

```dart
// Server (exhaustive switch — compiler catches missing cases):
final editorAction = EditorAction.fromActionName(action);
switch (editorAction) {
  case EditorAction.setBackground: ...
  case EditorAction.addText: ...
}

// CLI (type-safe paths):
client.post(EditorAction.setBackground.path, body);
// → POST /api/editor/set-background
```

## Port Discovery

1. Server tries `localhost:19222` (configurable via `AppConstants.defaultPort`)
2. If occupied, increments port up to 10 attempts
3. Writes actual port to `~/.config/app-screenshots/server.port`
4. CLI reads this file via `AppClient.discover()`

## Security

- Binds to `127.0.0.1` only — no network exposure
- No authentication required (localhost trust model)
- CORS headers allow web-based agents
- Response encoding explicitly set to UTF-8 via `ContentType.json` to support Unicode translations

## API Format

**Request:** `POST /api/editor/add-text`
```json
{
  "text": "Hello World",
  "fontSize": 40,
  "color": "#FFFFFF",
  "font": "Poppins",
  "width": 1100,
  "align": "center"
}
```

**Response:**
```json
{
  "ok": true,
  "data": { "overlayId": "abc-123", "text": "Hello World" }
}
```

**Error:**
```json
{
  "ok": false,
  "error": "No active editor. Open a design first."
}
```

## Adding a New Route

1. Add enum case to the action enum in `packages/app_screenshots_shared/lib/src/actions/`
2. Add handler in the corresponding `command_server_*.dart` part file
3. Add CLI subcommand in `packages/app_screenshots_cli/lib/src/commands/`
4. The enum's `actionName` auto-generates the kebab-case path

## Recent Changes

- **Text alignment**: `add-text` and `update-text` now support `width` and `align` (left/center/right) for precise text positioning
- **Per-locale overrides**: `translate override-overlay` allows font, size, position, and scale overrides per locale
- **Per-locale images**: `translate set-locale-image` sets locale-specific screenshot images
- **UTF-8 encoding**: `_sendJson` and `_sendError` now set `ContentType.json` to prevent Unicode encoding crashes
- **Magnifier overlays**: `add-magnifier` and `update-magnifier` for zoom-in detail callouts
- **Doodle backgrounds**: `set-doodle` for patterned backgrounds with icons/emoji
- **Mesh gradients**: `set-mesh-gradient` for rich multi-point gradient backgrounds

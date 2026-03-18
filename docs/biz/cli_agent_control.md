# CLI & Agent Control

## Overview

App Screenshots includes a built-in command server that lets CLI tools and AI agents control the app remotely. Any action available in the GUI can be performed via HTTP commands.

## User Stories

### As a developer / power user
- I can use CLI commands to batch-create screenshot designs
- I can script repetitive tasks (e.g., apply same text to 10 device frames)
- I can integrate screenshot generation into CI/CD pipelines
- I can AI-translate all text overlays to multiple locales in one command
- I can set per-locale layout overrides (font, size, position) for fine-tuned translations
- I can set per-locale screenshot images for localized app screenshots

### As an AI agent
- I can discover app capabilities via `--help` and `SKILL.md`
- I can create, edit, and export designs using structured JSON commands
- I can read design state as JSON for reasoning about layout changes
- I can trigger AI translation across locales without GUI interaction
- I can browse available fonts, icons, and device frames
- I can control text alignment and width for pixel-perfect layouts

## Feature Summary

| Capability | CLI Command |
|-----------|-------------|
| Check connection | `appshots status` |
| View current design | `appshots editor state` |
| Set background color | `appshots editor set-background --color "#FF5733"` |
| Set gradient | `appshots editor set-gradient --json '{...}'` |
| Set mesh gradient | `appshots editor set-mesh-gradient --json '{...}'` |
| Set doodle pattern | `appshots editor set-doodle --icon-size 40 --spacing 60` |
| Set transparent bg | `appshots editor set-transparent` |
| Add text overlay | `appshots editor add-text --text "..." --font Poppins --align center --width 1100` |
| Update text overlay | `appshots editor update-text --id <id> --text "..." --align right` |
| Add image overlay | `appshots editor add-image --file ./hero.png --x 0 --y 0` |
| Update image overlay | `appshots editor update-image --id <id> --width 300 --opacity 0.8` |
| Add icon overlay | `appshots editor add-icon --codePoint 57424 --size 60` |
| Update icon overlay | `appshots editor update-icon --id <id> --size 80 --color "#FFF"` |
| Add magnifier | `appshots editor add-magnifier` |
| Update magnifier | `appshots editor update-magnifier --id <id> --zoom 2.5 --width 300` |
| Upload image (sandbox-safe) | `appshots editor upload-image --file ./hero.png` |
| Set device frame | `appshots editor set-frame --device "iPhone 16 Pro Max"` |
| 3D frame rotation | `appshots editor set-rotation --x 0.1 --y -0.2 --z 0.05` |
| Set image position | `appshots editor set-image-position --x 0 --y 280` |
| List Google Fonts | `appshots editor list-fonts --query "roboto"` |
| List Material & SF icons | `appshots editor list-icons --query "star"` |
| Copy / Paste overlay | `appshots editor copy-overlay` / `paste-overlay` |
| Reorder layers | `appshots editor bring-forward` / `send-backward` |
| Set grid/alignment | `appshots editor set-grid --show --snap --size 50` |
| Save / Load design | `appshots editor save-design --name "..."` / `load-design --id <id>` |
| Undo / Redo | `appshots editor undo` / `appshots editor redo` |
| Export to PNG | `appshots editor export --path ./output.png` |
| Export all screenshots | `appshots editor export-all --dir ./exports` |
| List saved designs | `appshots library list` |
| Import design file | `appshots library import --file ./design.appshots` |
| Export .appshots | `appshots library export --id <design-id>` |
| Manage folders | `appshots library create-folder` / `delete-folder` / `move` |
| AI translate | `appshots translate all --from en --to ja,ko,de` |
| Preview translation | `appshots translate preview --locale ja` |
| Get all texts | `appshots translate get-texts` |
| Manual translations | `appshots translate apply-manual --locale ja --translations '{...}'` |
| Per-locale override | `appshots translate override-overlay --locale ja --overlay-id <id> --font "Noto Sans JP"` |
| Per-locale image | `appshots translate set-locale-image --locale ja --file ./ja_shot.png` |
| Multi-design state | `appshots multi state` |
| Open multi-editor | `appshots multi open --display-type APP_IPHONE_67` |
| Switch active design | `appshots multi switch --index 2` |
| Batch operations | `appshots multi batch --action set-padding --value 200` |
| Multi set-image | `appshots multi set-image --file ./img.png --index 0` |
| Multi save-design | `appshots multi save-design --name "My Set" --override` |
| List presets | `appshots preset list` |

## Command Groups

| Group | Commands | Description |
|-------|----------|-------------|
| `editor` | 42 | Design manipulation, overlays, backgrounds, export |
| `library` | 10 | Saved designs, folders, import/export |
| `translate` | 10 | AI translation, preview, manual edits, per-locale overrides |
| `multi` | 11 | Multi-screenshot management, open, batch, save |
| `preset` | 2 | Browse design presets |

## Requirements

- App must be running for CLI to connect
- Server binds to `127.0.0.1` only — no network exposure
- All commands support `--json` flag for machine-readable output
- Port auto-discovery via `~/.config/app-screenshots/server.port`

## Full Reference

📖 See [packages/app_screenshots_cli/README.md](../../packages/app_screenshots_cli/README.md) for complete command reference with options and workflow examples.

---
name: appshots
description: >
  CLI to remote-control the App Screenshots desktop app.
  Create, edit, and export App Store screenshot designs in real-time.
  Both AI agents and human users can use this CLI.
---

# appshots CLI

Controls the running **App Screenshots** desktop app via HTTP commands.
The app embeds a command server on `localhost:19222`.

## Installation

```bash
cd packages/app_screenshots_cli
dart pub global activate --source path .
```

## Prerequisites

- The App Screenshots desktop app must be running
- The CLI auto-discovers the server port via `~/.config/app-screenshots/server.port`

## Commands

### Check connection
```bash
appshots status
```

### Editor — manipulate the current design

```bash
# View design state
appshots editor state

# Background
appshots editor set-background --color "#FF5733"
appshots editor set-gradient --json '{"type":"linear","colors":["#FF0000","#0000FF"]}'
appshots editor set-mesh-gradient --json '{...}'
appshots editor set-doodle --icon-size 40 --spacing 60 --opacity 0.08
appshots editor set-transparent

# Device frame
appshots editor set-frame --device "iPhone 16 Pro Max"
appshots editor list-devices
appshots editor set-padding --padding 200
appshots editor set-corner-radius --radius 40
appshots editor set-rotation --x 5 --y -3 --z 0.05
appshots editor set-orientation  # toggle portrait/landscape

# Screenshot image
appshots editor set-image --file ./screenshot.png
appshots editor upload-image --file ./screenshot.png   # sandbox-safe base64
appshots editor set-image-position --x 0 --y 280

# Text overlays (with alignment support)
appshots editor add-text --text "Feature One" --font "Poppins" --size 90 \
  --color "#FFFFFF" --y 80 --x 0 --width 1100 --align center
appshots editor update-text --id <overlay-id> --text "Updated" --size 60 \
  --font "Inter" --align left --width 800 --scale 1.2 --rotation 5

# Image overlays
appshots editor add-image --file ./hero.png --x 100 --y 200 --width 300
appshots editor update-image --id <id> --width 400 --opacity 0.8 --scale 1.5

# Icon overlays
appshots editor add-icon --codePoint 57424 --size 60 --color "#FFFFFF"
appshots editor update-icon --id <id> --size 80 --rotation 45

# Magnifier overlays
appshots editor add-magnifier
appshots editor update-magnifier --id <id> --zoom 2.5 --width 300 --corner-radius 20

# Overlay management
appshots editor list-overlays
appshots editor select-overlay --id <overlay-id>
appshots editor delete-overlay --id <overlay-id>
appshots editor move-overlay --dx 10 --dy -5
appshots editor copy-overlay
appshots editor paste-overlay
appshots editor bring-forward
appshots editor send-backward

# Fonts & icons
appshots editor list-fonts --query "roboto" --limit 50
appshots editor list-icons --query "star" --style material

# Grid & alignment
appshots editor set-grid --show --snap --dots --center --size 50

# Save / Load / Export
appshots editor save-design --name "My Design"
appshots editor load-design --id <design-id>
appshots editor export --path ./output.png
appshots editor export-all --dir ./exports

# Undo / Redo
appshots editor undo
appshots editor redo
```

### Multi — manage multiple screenshots

```bash
# Open multi-editor
appshots multi open --display-type APP_IPHONE_67

# State
appshots multi state

# Design slots
appshots multi add
appshots multi remove --index 3
appshots multi duplicate --index 1
appshots multi switch --index 2
appshots multi reorder --from 0 --to 2

# Set images per design
appshots multi set-image --file ./screenshot1.png --index 0

# Batch operations
appshots multi batch --action set-padding --value 200
appshots multi batch --action set-corner-radius --value 40

# Presets
appshots multi apply-preset --id dark_premium

# Save
appshots multi save-design --name "My App Store Set"
appshots multi save-design --name "My App Store Set" --override
```

### Translate — AI translation & per-locale customization

```bash
# State & texts
appshots translate state
appshots translate get-texts

# AI-translate to multiple locales
appshots translate all --from en --to ja,ko,de,fr,es

# Set context for better translations
appshots translate set-prompt --prompt "Habit tracking app for iOS"

# Preview locale in editor
appshots translate preview --locale ja
appshots translate preview --locale none   # clear preview

# Manual edit single translation
appshots translate edit --locale ja --overlay-id <id> --text "習慣トラッカー"

# Bulk manual translations
appshots translate apply-manual --locale ja \
  --translations '{"0:<overlayId>":"翻訳テキスト","1:<overlayId>":"翻訳テキスト"}'

# Per-locale style overrides
appshots translate override-overlay --locale ja --overlay-id <id> \
  --font "Noto Sans JP" --font-size 72 --x 10 --y 20 --scale 0.9

# Per-locale screenshot images
appshots translate set-locale-image --locale ja --file ./ja_screenshot.png

# Remove locale
appshots translate remove-locale --locale ko
```

### Library — manage saved designs

```bash
appshots library list
appshots library get --id <design-id>
appshots library rename --id <design-id> --name "New Name"
appshots library delete --id <design-id>
appshots library folders
appshots library create-folder --name "My Folder"
appshots library delete-folder --id <folder-id>
appshots library move --design-id <design-id> --folder-id <folder-id>
appshots library import --file ./design.appshots
appshots library export --id <design-id>
```

### Presets — browse design templates

```bash
appshots preset list
appshots preset show --id snapchat_yellow
```

## Agent Mode

All commands support `--json` flag for structured output:
```bash
appshots --json library list
appshots --json editor state
appshots --json translate get-texts
```

## JSON Response Format

All responses follow this format:
```json
{
  "ok": true,
  "data": { ... }
}
```

Error responses:
```json
{
  "ok": false,
  "error": "Error message"
}
```

## Display Types

| ID | Description |
|----|-------------|
| `APP_IPHONE_67` | iPhone 6.7" (Pro Max) — 1290×2796 |
| `APP_IPHONE_65` | iPhone 6.5" — 1284×2778 |
| `APP_IPHONE_55` | iPhone 5.5" — 1242×2208 |
| `APP_IPAD_PRO_6G_129` | iPad Pro 12.9" — 2048×2732 |
| `APP_IPAD_PRO_M4_13` | iPad Pro M4 13" — 2064×2752 |
| `APP_MAC` | Mac App Store — 2880×1800 |

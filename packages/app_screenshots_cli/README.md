# App Screenshots CLI (`appshots`)

Command-line tool for controlling the **App Screenshots** desktop app. The CLI communicates with the running app over an authenticated local HTTP API, enabling design automation, publishing, and collaboration workflows.

## Installation

```bash
dart pub global activate --source path packages/app_screenshots_cli
```

## Quick Start

```bash
# Check the app is running
appshots status

# View current design state  
appshots editor state

# AI-translate all text to Japanese & Korean
appshots translate all --from en --to ja,ko

# Export current screenshot
appshots editor export

# Use --json for machine-readable output
appshots --json editor state
```

---

## Commands

### `status`
Check if the app is running and what cubits are active.

```bash
appshots status
```

---

### `editor` — Design Manipulation

#### Canvas & Background

| Command | Description | Key Options |
|---------|-------------|-------------|
| `state` | Current design state | — |
| `set-background` | Set solid background color | `--color "#FF5733"` |
| `set-gradient` | Set gradient background (linear/radial/sweep) | `--json '{...}'` / `--clear` |
| `set-mesh-gradient` | Set mesh gradient background | `--json '{...}'` / `--clear` |
| `set-transparent` | Toggle transparent background | `--value` (flag) |
| `set-doodle` | Set doodle pattern background | `--icon-source 0` `--icon-size 40` `--spacing 60` `--opacity 0.08` `--rotation 0` `--color "#FFF"` / `--clear` |
| `set-display-type` | Change display dimensions | `--display-type APP_IPHONE_67` |
| `set-orientation` | Toggle portrait/landscape | — |

#### Device Frame

| Command | Description | Key Options |
|---------|-------------|-------------|
| `set-frame` | Set device frame | `--device "iPhone 16 Pro Max"` |
| `list-devices` | List all available device frames | — |
| `set-padding` | Set padding around screenshot | `--padding 20` |
| `set-corner-radius` | Set screenshot corner radius | `--radius 12` |
| `set-rotation` | 3D frame rotation | `--x 0.1 --y -0.2 --z 0.05` |

#### Screenshot Image

| Command | Description | Key Options |
|---------|-------------|-------------|
| `set-image` | Set screenshot image from file path | `--file /path/to/img.png` |
| `upload-image` | Upload image (sandbox-safe base64) | `--file /path/to/img.png` |
| `set-image-position` | Position the screenshot offset | `--x 10 --y 280` |

#### Text Overlays

| Command | Description | Key Options |
|---------|-------------|-------------|
| `add-text` | Add a text overlay | `--text "Hello" --font "Poppins" --size 90 --color "#FFF" --x 0 --y 80 --width 1100 --align center` |
| `update-text` | Update existing text overlay | `--id <id> --text "New" --font "Inter" --size 60 --color "#000" --x 10 --y 20 --width 800 --align left --scale 1.5 --rotation 5` |

**Text alignment**: Use `--width` to set the text box width and `--align` (`left`, `center`, `right`) to control horizontal alignment. Without `--width`, text renders as a single-line auto-width block.

#### Icon Overlays

| Command | Description | Key Options |
|---------|-------------|-------------|
| `add-icon` | Add an icon overlay | `--codePoint 57424 --size 60 --color "#FFF"` |
| `update-icon` | Update existing icon | `--id <id> --x 10 --y 20 --size 80 --color "#FFF" --rotation 45 --opacity 0.8` |
| `list-icons` | Browse Material & SF icons | `--query "star" --style material\|sf` |

#### Image Overlays

| Command | Description | Key Options |
|---------|-------------|-------------|
| `add-image` | Add an image overlay | `--file /path/to/img.png --x 0 --y 0 --width 200 --height 200` |
| `update-image` | Update existing image overlay | `--id <id> --x 10 --y 20 --width 300 --height 300 --scale 1.2 --rotation 15 --opacity 0.9` |

#### Magnifier Overlays

| Command | Description | Key Options |
|---------|-------------|-------------|
| `add-magnifier` | Add a magnifier overlay | — |
| `update-magnifier` | Update existing magnifier | `--id <id> --x 100 --y 200 --width 300 --height 300 --zoom 2.5 --corner-radius 20` |

#### Overlay Management

| Command | Description | Key Options |
|---------|-------------|-------------|
| `list-overlays` | List all overlays in design | — |
| `select-overlay` | Select overlay by ID | `--id <overlay-id>` |
| `delete-overlay` | Delete overlay by ID | `--id <overlay-id>` |
| `move-overlay` | Move selected overlay | `--dx 10 --dy -5` |
| `copy-overlay` | Copy selected overlay | — |
| `paste-overlay` | Paste copied overlay | — |
| `bring-forward` | Bring selected overlay forward | — |
| `send-backward` | Send selected overlay backward | — |

#### Fonts

| Command | Description | Key Options |
|---------|-------------|-------------|
| `list-fonts` | Search Google Fonts | `--query "roboto" --limit 50` |

#### Grid & Alignment

| Command | Description | Key Options |
|---------|-------------|-------------|
| `set-grid` | Configure alignment grid | `--show --snap --dots --center --size 50` |

#### Presets

| Command | Description | Key Options |
|---------|-------------|-------------|
| `apply-preset` | Apply a design preset | `--id <preset-id>` |

#### Save / Load / Export

| Command | Description | Key Options |
|---------|-------------|-------------|
| `save-design` | Save current design to library | `--name "My Design"` |
| `load-design` | Load a saved design into editor | `--id <design-id>` |
| `export` | Export current screenshot as PNG | `--path /tmp/out.png` |
| `export-all` | Export all multi-screenshots | `--dir /tmp/exports` |
| `undo` | Undo last action | — |
| `redo` | Redo last action | — |

---

### `multi` — Multi-Screenshot Management

| Command | Description | Key Options |
|---------|-------------|-------------|
| `open` | Open the multi-screenshot editor | `--display-type APP_IPHONE_67` |
| `state` | Current multi-editor state | — |
| `switch` | Switch active design by index | `--index 2` |
| `add` | Add a new design slot | — |
| `remove` | Remove a design | `--index 3` |
| `duplicate` | Duplicate a design | `--index 1` |
| `reorder` | Reorder designs | `--from 0 --to 2` |
| `apply-preset` | Apply preset to all designs | `--id <preset-id>` |
| `batch` | Batch operation across all designs | `--action set-padding --value 200` |
| `set-image` | Set screenshot image for a design | `--file /path/to/img.png --index 0` |
| `save-design` | Save multi-screenshot set | `--name "My Set" [--override]` |

**Batch actions**: The `batch` command supports these actions: `set-padding`, `set-corner-radius`, `set-background`.

---

### `translate` — Translation Management

| Command | Description | Key Options |
|---------|-------------|-------------|
| `state` | Translation state & locale statuses | — |
| `get-texts` | Get all texts from all designs | — |
| `all` | AI-translate to target locales | `--from en --to ja,ko,de` |
| `preview` | Preview translated locale in editor | `--locale ja` (or `--locale none` to clear) |
| `edit` | Edit single overlay translation | `--locale ja --overlay-id <id> --text "..."` |
| `apply-manual` | Bulk apply manual translations | `--locale ja --translations '{"overlayId":"text",...}'` |
| `remove-locale` | Remove all translations for a locale | `--locale ko` |
| `set-prompt` | Set AI translation context prompt | `--prompt "Fitness habit tracker app"` |
| `override-overlay` | Per-locale overlay style override | `--locale ja --overlay-id <id> --font "Noto Sans JP" --font-size 72 --x 10 --y 20 --scale 0.9 --width 800 --color "#FFF" --font-weight 6` |
| `set-locale-image` | Set per-locale screenshot image | `--locale ja --file /path/to/ja_screenshot.png` |

---

### `library` — Saved Designs

| Command | Description | Key Options |
|---------|-------------|-------------|
| `list` | List all saved designs | — |
| `get` | Get design details | `--id <design-id>` |
| `delete` | Delete a design | `--id <design-id>` |
| `rename` | Rename a design | `--id <id> --name "New Name"` |
| `folders` | List all folders | — |
| `create-folder` | Create a folder | `--name "My Folder"` |
| `delete-folder` | Delete a folder | `--id <id> --with-designs` |
| `move` | Move design to folder | `--design-id <id> --folder-id <id>` |
| `import` | Import .appshots file | `--file /path/to/file.appshots` |
| `export` | Export design as .appshots | `--id <design-id>` |

---

### `preset` — Design Presets

| Command | Description | Key Options |
|---------|-------------|-------------|
| `list` | List all available presets | — |
| `show` | Show preset details | `--id <preset-id>` |

---

### Publishing and collaboration

Configure App Store Connect and Google Play credentials in the app's Settings
screen. Credentials stay in the app's secure storage and are never returned to
the CLI.

Rendered upload directories must contain one immediate subdirectory per locale:

```text
screenshots/
├── en-US/
│   ├── 01.png
│   └── 02.png
└── ja/
    ├── 01.png
    └── 02.png
```

| Command | Description |
|---------|-------------|
| `capabilities` | Show supported integrations and credential state |
| `asc apps` | List accessible App Store Connect apps |
| `asc custom-product-pages --app-id ID` | List CPPs and editable-version state |
| `asc upload --app-id ID --source DIR --display-type TYPE` | Upload to the editable main version |
| `asc upload ... --custom-product-page-id ID` | Upload to an editable Custom Product Page |
| `play upload --package NAME --source DIR --image-type TYPE` | Upload to the Google Play main listing |
| `play export-csl --listing NAME --source DIR --out DIR` | Export an upload kit for a Google Play custom store listing |
| `jobs list` / `jobs status --id ID` | Inspect asynchronous upload jobs |
| `collaboration share --file FILE` | Present the native iCloud collaboration sheet |
| `collaboration save --original FILE --working FILE` | Save a working copy back to its opened document |

Uploads wait for completion by default. Pass `--no-wait` to return the job ID
immediately.

### Google Play custom store listings

Google Play has **no API for custom store listings**. The Android Publisher
API's `edits.listings` and `edits.images` are keyed only by language and image
type, so every API write lands on the *main* listing — there is no listing ID
to target. Custom store listings are Play Console–only.

`play export-csl` covers the gap: it lays screenshots out in a
listing/locale/image-type tree and writes an `UPLOAD.md` mapping each folder to
a Play Console field. It runs entirely locally — no credentials, and the
desktop app does not need to be running.

```bash
appshots play export-csl \
  --listing "Fitness keyword" \
  --source ./screenshots \
  --out ./csl \
  --package com.example.app
```

```
csl/
├── UPLOAD.md
└── fitness-keyword/
    ├── en-US/phoneScreenshots/01.png
    └── de-DE/phoneScreenshots/01.png
```

Locale folders use Google Play's codes (`en` → `en-US`), files are renumbered in
display order, and anything past Play's 8-per-locale cap is dropped with a
warning. Export several listings at once by repeating `--listing`, optionally
with its own source directory:

```bash
appshots play export-csl \
  -L "Fitness keyword=./shots-fitness" \
  -L "Winter sale=./shots-winter" \
  --out ./csl
```

The folder slug (`fitness-keyword`) is also a valid `&listing=` URL parameter,
so it doubles as the custom store listing URL if you target by URL.

---

## Workflow Examples

### 1. AI Translation Workflow

```bash
# 1. See what text exists across all screenshots
appshots --json translate get-texts

# 2. Set context for better AI translations
appshots translate set-prompt --prompt "Habit tracking app for iOS"

# 3. AI-translate to 5 languages
appshots translate all --from en --to ja,ko,de,fr,es

# 4. Preview Japanese in the editor
appshots translate preview --locale ja

# 5. Fix a specific translation
appshots translate edit --locale ja --overlay-id abc123 --text "習慣トラッカー"

# 6. Override font for Japanese (larger CJK glyphs)
appshots translate override-overlay --locale ja --overlay-id abc123 --font "Noto Sans JP" --font-size 72

# 7. Set a locale-specific screenshot image
appshots translate set-locale-image --locale ja --file /path/to/ja_screenshot.png

# 8. Export all screenshots
appshots editor export-all --dir ~/Desktop/screenshots
```

### 2. Multi-Screenshot from Scratch (No Preset)

```bash
# Open the multi-screenshot editor
appshots multi open --display-type APP_IPHONE_67

# Add 4 more designs (total 5)
appshots multi add
appshots multi add
appshots multi add
appshots multi add

# Set images for each
appshots multi set-image --file screenshot1.png --index 0
appshots multi set-image --file screenshot2.png --index 1
# ...

# Set backgrounds
appshots multi switch --index 0
appshots editor set-background --color "#0A0A1A"

# Batch styling across all designs
appshots multi batch --action set-padding --value 180
appshots multi batch --action set-corner-radius --value 40

# Set device frames
appshots multi switch --index 0
appshots editor set-frame --device "iPhone 16 Pro Max"

# Add centered text
appshots multi switch --index 0
appshots editor add-text --text "Track Your Habits" --font "Poppins" --size 90 \
  --color "#FFFFFF" --y 80 --x 0 --width 1100 --align center

# Save design
appshots multi save-design --name "My App Store Screenshots"

# Apply translations
appshots translate apply-manual --locale ja --translations '{"0:<overlayId>":"習慣を記録"}'

# Save with translations
appshots multi save-design --name "My App Store Screenshots" --override
```

### 3. Using Presets

```bash
# List available presets
appshots preset list

# Apply a preset to all designs
appshots multi apply-preset --id dark_premium

# Customize from there
appshots multi switch --index 0
appshots editor set-background --color "#1A1A2E"
```

---

## JSON Output

Use `--json` flag for machine-readable JSON output:

```bash
appshots --json editor state
appshots --json translate get-texts
appshots --json editor list-icons --query "star"
```

---

## Architecture

The CLI communicates with the running app via HTTP on `localhost`. The app writes
an ephemeral port and bearer token to
`~/.config/app-screenshots/server.session.json`. The token changes each time the
server starts.

```
CLI (appshots) ──HTTP──▶ CommandServer (in-app)
                              │
                ┌─────────────┼─────────────┐
                ▼             ▼             ▼
          EditorCubit   MultiCubit   TranslationCubit
```

### Port

The unified server starts at `19222` and tries the next nine ports if that port
is occupied. The CLI discovers the active port automatically; `--port` can be
used as an explicit override.

### Display Types

| ID | Description | Resolution |
|----|-------------|------------|
| `APP_IPHONE_67` | iPhone 6.7" (Pro Max) | 1290 × 2796 |
| `APP_IPHONE_65` | iPhone 6.5" | 1284 × 2778 |
| `APP_IPHONE_55` | iPhone 5.5" | 1242 × 2208 |
| `APP_IPAD_PRO_6G_129` | iPad Pro 12.9" | 2048 × 2732 |
| `APP_IPAD_PRO_M4_13` | iPad Pro M4 13" | 2064 × 2752 |
| `APP_MAC` | Mac App Store | 2880 × 1800 |

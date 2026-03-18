# AI-Generated Templates

## Overview

AI-generated templates let users describe a screenshot style in plain English (or any language) and get a fully designed template applied instantly. This removes the need to manually pick colors, fonts, and layouts — just describe what you want.

## User Flow

1. Open the **Template Picker** (from the toolbar or sidebar)
2. Tap the **✨ AI Generate** card (first item in the grid)
3. Describe your desired style, e.g.:
   - "Dark elegant style for a fitness app"
   - "Playful colorful theme for a kids game"
   - "Minimal white design for productivity"
4. Tap **Generate** — the AI creates 5 coordinated screenshot designs
5. The template is applied to all screenshots automatically

## AI Providers

| Provider | Requirements | Privacy |
|----------|-------------|---------|
| **Apple (On-Device)** | macOS 26+, M-series chip | Fully on-device, no data leaves the Mac |
| **Google Gemini** | API key (set in Settings → Translation) | Cloud-based, data sent to Google |

- If the user has Apple FM configured as their active provider and it's available, it's used automatically
- Otherwise, falls back to Gemini (requires API key)
- Uses the same API key as the Translation feature — no additional setup

## What Gets Generated

Each AI template includes:
- **5 unique screenshot designs** with cohesive styling
- **Color palette** — background colors and gradients
- **Typography** — Google Font, size, weight, color
- **Marketing copy** — headline and subtitle text for each screen
- **Layout** — text position (top/bottom), alignment (left/center/right)

## Suggestion Chips

Pre-built prompts are available as tap-to-fill suggestions:
- Dark elegant style for a fitness app
- Playful colorful theme for a kids game
- Minimal white design for productivity
- Vibrant gradient for a social media app
- Professional blue for a finance app
- Warm sunset palette for a travel app

---

## Acceptance Criteria

- [x] AI Generate card appears as the first item in the Template Picker grid
- [x] User can type a free-form description to generate a template
- [x] Suggestion chips are available as tap-to-fill prompts
- [x] AI generates 5 coordinated screenshot designs with colors, fonts, and copy
- [x] Generated template is applied to all screenshots in the multi-screenshot canvas
- [x] Apple FM is used when available, Gemini as fallback
- [x] Shares API key configuration with the Translation feature

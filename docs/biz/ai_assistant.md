# AI Design Assistant

## Overview
The AI Design Assistant is an interactive sidebar tab that lets users describe screenshot design changes in natural language. It uses AI (Apple FM, Gemini, or OpenAI) to interpret requests and apply design modifications in real-time. It also powers the **AI Template Generator** dialog for creating entire design presets from a text description.

## Value Proposition
- **Faster iteration**: Describe changes instead of hunting through menus
- **Design guidance**: AI suggests colors, fonts, and layouts based on the current design state
- **Copywriting**: AI writes compelling App Store headlines and subtitles
- **Consistency**: Apply styles across multiple screenshots in one prompt
- **Template generation**: Create complete design presets from a description

## Architecture

### AI Providers
| Provider | When Used |
|----------|-----------|
| **Apple FM** | Preferred provider; uses on-device Foundation Models via MethodChannel (`com.appscreenshots/ai`) |
| **Gemini** | Cloud fallback; uses `gemini-2.0-flash` via REST API |
| **OpenAI** | Cloud alternative; uses configurable model (default `gpt-4o-mini`) |

Provider selection is managed by `AIProviderRepository`. Apple FM is attempted first when configured; cloud providers require an API key set in Settings.

### Key Components
| Component | File | Purpose |
|-----------|------|---------|
| `AiDesignService` | `data/services/ai_design_service.dart` | Prompt engineering, API calls, response parsing |
| `AiAssistantCubit` | `presentation/cubit/ai_assistant_cubit.dart` | Chat state, message history, undo snapshots, multi-screenshot orchestration |
| `AiAssistantControls` | `presentation/widgets/controls/ai_assistant_controls.dart` | Chat UI sidebar tab with contextual suggestions, undo bar, input |
| `AiTemplateCubit` | `presentation/cubit/ai_template_cubit.dart` | AI template generation state |
| `AiTemplateDialog` | `presentation/widgets/ai_template_dialog.dart` | Dialog UI for generating `ScreenshotPreset` from a text description |

## User Stories

### Core Chat
- As a user, I can type "Make the background dark blue" and see it change
- As a user, I can ask "Write a catchy headline for a fitness app" and get text
- As a user, I can undo the last AI change with one click
- As a user, I can clear the chat to start fresh

### Contextual Suggestions
- As a user, I see design-aware suggestion chips that change based on the current state (e.g. "Add a gradient" only appears when no gradient is set)
- As a user, I can tap a chip to send it as a prompt instantly

### Multi-Screenshot
- As a user, I can check "Apply to all screenshots" and changes propagate to every design slot
- As a user, I see a summary of how many screenshots were updated (e.g. "Applied to 5/5 screenshots")
- As a user, I can undo a bulk operation, restoring all designs at once

### AI Template Generation
- As a user, I can describe a style (e.g. "Dark elegant style for a fitness app") and generate a full `ScreenshotPreset`
- As a user, I can tap themed suggestion chips to pre-fill the description

## Supported Design Properties

### Background & Layout
| Property | Example Prompt | JSON Key |
|----------|---------------|----------|
| Background color | "Make it navy blue" | `backgroundColor` |
| Linear gradient | "Add a sunset gradient" | `gradientColors`, `gradientBegin`, `gradientEnd` |
| Clear gradient | "Remove the gradient" | `clearGradient` |
| Padding | "More space around the phone" | `padding` |
| Corner radius | "Round the corners" | `cornerRadius` |
| Text position | "Put text below the device" | `textAtBottom` |

### Frame
| Property | Example Prompt | JSON Key |
|----------|---------------|----------|
| Frame rotation (Z-axis) | "Tilt the frame slightly" | `frameRotation` |

### Text Overlays (via `textChanges[]`)
| Property | Example Prompt | JSON Key |
|----------|---------------|----------|
| Text content | "Change title to 'Track Your Goals'" | `text` |
| Font size | "Make the title bigger" | `fontSize` |
| Font weight | "Bold the title" | `fontWeight` |
| Font style | "Italicize the subtitle" | `fontStyle` |
| Text color | "White text" | `color` |
| Google Font | "Use Montserrat font" | `googleFont` |
| Text alignment | "Center the text" | `textAlign` |
| Rotation | "Rotate the title 5 degrees" | `rotation` |
| Decoration | "Underline the title" | `decoration` |
| Background pill | "Add a colored pill behind the title" | `backgroundColor` |
| Border | "Add a border around the text" | `borderColor`, `borderWidth`, `borderRadius` |
| Padding (text) | "Add padding inside the text background" | `horizontalPadding`, `verticalPadding` |
| Scale | "Scale down the subtitle" | `scale` |

### Adding New Text (via `addText[]`)
- "Add a subtitle: Stay motivated" → Creates a new `TextOverlay` with positioning below existing overlays

## Features Not Yet AI-Accessible

The following app features exist in the design model but are **not yet exposed** through the AI prompt schema. These are candidates for future AI integration:

| Feature | Model | Notes |
|---------|-------|-------|
| **3D Frame Rotation** | `frameRotationX`, `frameRotationY` | Perspective tilt along X/Y axes |
| **Mesh Gradients** | `MeshGradientSettings` | Multi-point color blending |
| **Doodle Backgrounds** | `DoodleSettings` | Repeating icon patterns (SF Symbols, Material Symbols, emoji) |
| **Image Overlays** | `ImageOverlay` | User-uploaded images with position/scale/rotation |
| **Icon Overlays** | `IconOverlay` | SF/Material icons with rich styling (shadow, background, behind-frame) |
| **Magnifier Overlays** | `MagnifierOverlay` | Zoom lens (6 shapes: circle, rounded rect, star, hexagon, diamond, heart) |
| **Grid Settings** | `GridSettings` | Alignment grid and ruler guides |
| **Transparent Background** | `transparentBackground` | Export with alpha channel |
| **Radial/Sweep Gradients** | Gradient types | Currently only linear is AI-settable |
| **Device Frame Selection** | `deviceFrame`, `displayType` | Switch between iPhone, iPad, Android, etc. |
| **Orientation** | `orientation` | Portrait/landscape toggle |
## Current Capabilities
- Chat input → single design property changes (background, gradient, text, padding, frame rotation)
- Contextual suggestion chips based on current design state
- Headline/subtitle generation via `addText[]`
- Bulk style application with "Apply to all" toggle
- Full preset creation from description (AI Template Generation)

## Roadmap
- Advanced Properties: Doodle, mesh gradient, magnifier, icon overlays via AI
- Device/Orientation Control: "Switch to iPad landscape" via AI
- Image-Aware Suggestions: AI reads the screenshot image content to suggest complementary designs

## Conversation Context
The AI maintains up to 6 messages of conversation history for follow-up requests (e.g. "now make the subtitle match" after changing the title). History is trimmed to keep the prompt within token limits.

## Error Handling
- Missing API key → Shows configuration guidance
- Provider failure → Falls through Apple FM → Gemini → OpenAI
- Parse failure → Strips markdown fences, retries JSON decode
- Partial bulk failure → Reports "Applied to N/M screenshots. K failed."
- Undo → Restores pre-AI design snapshot (single or bulk)

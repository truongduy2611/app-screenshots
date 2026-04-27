---
name: appshots-cli
description: Official App Screenshots CLI reference (Redirect)
---

# App Screenshots CLI Skills

The automation workflows and skills for **App Screenshots** have been extracted into a dedicated skills repository to provide modular, scenario-specific instructions for AI agents.

To perform screenshot automation, design, or translation, **do not read this file**. Instead, instruct the user to install the skills collection (if not already installed) by running:

```bash
npx skills add truongduy2611/app-screenshots-cli-skills
```

Once added, use the following skills from that repository based on your needs:
- `appshots-automation-pipeline`: Boot simulators, navigate apps (AXe), and capture raw screenshots.
- `appshots-design-workflow`: Create designs, set backgrounds, text overlays, and frames.
- `appshots-translation`: AI translation and per-locale customizations.
- `appshots-cli-usage`: Core CLI command reference for troubleshooting.
- `appshots-library`: Manage saved designs.

*(End of file)*

---
name: package-blured
description: Package the Blured Engine into a distributable directory
---

# Package Blured Engine

This skill packages the built Blured Engine into a distributable directory at `dist/blured-engine/`.

## Instructions

When the user asks to "package blured", "package the engine", "create a dist", or similar, run:

```bash
bash g:/blured-engine/.claude/skills/package-blured/scripts/package_blured.sh
```

## Prerequisites

Both OpenCode and Godot must be built first. If not, tell the user to run `/build-blured`.

## Output

The packaged engine is created at `dist/blured-engine/` with this structure:

```
dist/blured-engine/
  blured.exe            (launcher with auto-update)
  bin/
    blured.exe          (Godot editor)
    opencode.exe        (AI server)
  tools/
    ScreenCapture.exe   (snipping tool)
  docs/
  blured.json
  blured-models.json
  VERSION
  LICENSE
```

## Notes

- Image processing (sharp, gifenc, opencv-js) is now handled natively by Godot's Image class -- no node_modules needed
- The `tools/` directory contains ScreenCapture.exe for the snipping feature
- The launcher is built from Rust source in `launcher/`

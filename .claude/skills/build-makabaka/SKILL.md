---
name: build-makabaka
description: Build the Makabaka Engine (OpenCode + Godot)
---

# Build Makabaka Engine

This skill builds the complete Makabaka Engine:
1. Builds OpenCode (TypeScript/Bun)
2. Builds Godot Engine (C++/SCons)

## Instructions

When the user asks to "build makabaka", "rebuild makabaka", "compile makabaka", or similar, follow these steps:

### Step 0: Kill Godot (Required)

The Godot build will fail if the editor is running. Always kill it first:

```bash
taskkill //F //IM godot.windows.editor.x86_64.exe 2>&1 || echo "Godot not running"
```

### Step 1: Build OpenCode

```bash
cd /g/makabaka-engine/opencode/packages/opencode && rm -rf dist && bun run build --single
```

This creates the executable at: `opencode/packages/opencode/dist/opencode-windows-x64/bin/opencode.exe`

### Step 2: Build Godot Engine

```bash
cd /g/makabaka-engine/godot && python -m SCons platform=windows target=editor d3d12=no -j8
```

This creates the executable at: `godot/bin/godot.windows.editor.x86_64.exe`

Note: This step may fail if:
- Godot editor is still running (access denied)
- Visual Studio build tools are not in PATH

### Step 3: Confirm to User

Tell the user:
- OpenCode build: `opencode/packages/opencode/dist/opencode-windows-x64/bin/opencode.exe`
- Godot build: `godot/bin/godot.windows.editor.x86_64.exe`
- Run `/start-makabaka` to launch the engine

## Build Options

### Build Only OpenCode

If the user says "build opencode only" or "rebuild opencode":

```bash
cd /g/makabaka-engine/opencode/packages/opencode && rm -rf dist && bun run build --single
```

### Build Only Godot

If the user says "build godot only" or "rebuild godot":

```bash
taskkill //F //IM godot.windows.editor.x86_64.exe 2>&1 || echo "Godot not running"
cd /g/makabaka-engine/godot && python -m SCons platform=windows target=editor d3d12=no -j8
```

## Troubleshooting

- **"Access denied" error**: Godot editor is running. Kill it with `taskkill //F //IM godot.windows.editor.x86_64.exe`
- **SCons not found**: Run from a terminal with Visual Studio environment or use `vcvars64.bat`
- **Bun not found**: Ensure Bun is installed and in PATH
- **Build takes forever**: Use `-j8` flag for parallel builds (adjust based on CPU cores)

## Key Paths

- OpenCode source: `g:/makabaka-engine/opencode/packages/opencode/`
- Godot source: `g:/makabaka-engine/godot/`
- AI Assistant source: `g:/makabaka-engine/godot/editor/plugins/ai_assistant/`
- Build script: `g:/makabaka-engine/build_makabaka.bat`
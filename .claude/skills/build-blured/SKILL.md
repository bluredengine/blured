---
name: build-blured
description: Build the Blured Engine (OpenCode + Godot)
---

# Build Blured Engine

This skill builds the complete Blured Engine:
1. Builds OpenCode (TypeScript/Bun)
2. Builds Godot Engine (C++/SCons)

## Instructions

When the user asks to "build blured", "rebuild blured", "compile blured", or similar, follow these steps:

### Step 0: Kill running processes (Required)

The Godot build will fail if the editor is running, and OpenCode must be stopped before rebuilding. Always kill all first:

```bash
taskkill //F //IM godot.windows.editor.x86_64.exe 2>&1 || echo "Godot not running"
taskkill //F //IM opencode.exe 2>&1 || echo "OpenCode not running"
taskkill //F //IM bun.exe 2>&1 || echo "Bun not running"
```

Note: OpenCode's process may appear as `bun.exe` instead of `opencode.exe`.

### Step 1: Build OpenCode

```bash
cd /g/blured-engine/opencode/packages/opencode && bun run build --single
```

This creates the executable at: `opencode/packages/opencode/dist/opencode-windows-x64/bin/opencode.exe`

### Step 2: Build Godot Engine

```bash
cd /g/blured-engine/godot && python -m SCons platform=windows target=editor d3d12=no -j8
```

This creates the executable at: `godot/bin/godot.windows.editor.x86_64.exe`

Note: This step may fail if:
- Godot editor is still running (access denied)
- Visual Studio build tools are not in PATH

### Step 3: Confirm to User

Tell the user:
- OpenCode build: `opencode/packages/opencode/dist/opencode-windows-x64/bin/opencode.exe`
- Godot build: `godot/bin/godot.windows.editor.x86_64.exe`
- Run `/start-blured` to launch the engine

## Build Options

### Build Only OpenCode

If the user says "build opencode only" or "rebuild opencode":

```bash
taskkill //F //IM opencode.exe 2>&1 || echo "OpenCode not running"
taskkill //F //IM bun.exe 2>&1 || echo "Bun not running"
cd /g/blured-engine/opencode/packages/opencode && bun run build --single
```

### Build Only Godot

If the user says "build godot only" or "rebuild godot":

```bash
taskkill //F //IM godot.windows.editor.x86_64.exe 2>&1 || echo "Godot not running"
cd /g/blured-engine/godot && python -m SCons platform=windows target=editor d3d12=no -j8
```

## Troubleshooting

- **"Access denied" error**: Godot editor is running. Kill it with `taskkill //F //IM godot.windows.editor.x86_64.exe`
- **SCons not found**: Run from a terminal with Visual Studio environment or use `vcvars64.bat`
- **Bun not found**: Ensure Bun is installed and in PATH
- **Build takes forever**: Use `-j8` flag for parallel builds (adjust based on CPU cores)

## Key Paths

- OpenCode source: `g:/blured-engine/opencode/packages/opencode/`
- Godot source: `g:/blured-engine/godot/`
- AI Assistant source: `g:/blured-engine/godot/editor/plugins/ai_assistant/`

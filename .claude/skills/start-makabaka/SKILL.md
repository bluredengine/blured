---
name: start-makabaka
description: Start the Makabaka Engine (OpenCode AI server + Godot editor)
---

# Start Makabaka Engine

This skill starts the complete Makabaka Engine environment:
1. Kills any existing Godot editor process
2. Starts OpenCode AI server on port 4096 (if not already running)
3. Starts Godot editor with the test project

## Instructions

When the user asks to "start makabaka engine", "restart makabaka", or similar, follow these steps:

### Step 1: Kill Existing Godot Process

First, kill any running Godot editor to ensure clean restart:

```bash
taskkill //F //IM godot.windows.editor.x86_64.exe 2>&1 || echo "Godot not running"
```

### Step 2: Check/Start the OpenCode AI Server

Check if AI server is already running:

```bash
curl -s http://localhost:4096/godot/health
```

If the health check fails, start the server:

```bash
cd /g/makabaka-engine && start //B "" "./opencode/packages/opencode/dist/opencode-windows-x64/bin/opencode.exe" serve --port 4096
```

Wait 3 seconds for the server to initialize, then verify:

```bash
sleep 3 && curl -s http://localhost:4096/godot/health
```

Expected response: `{"status":"ok","timestamp":...}`

### Step 3: Start Godot Editor

Start Godot editor with the test project:

```bash
start "" "g:/makabaka-engine/godot/bin/godot.windows.editor.x86_64.exe" --path "G:/MakabakaGames/Test" --editor
```

### Step 4: Confirm to User

Tell the user:
- AI Server is running on http://localhost:4096
- Godot editor is starting with project: G:/MakabakaGames/Test
- The AI Assistant dock is built into the editor (right panel)
- Click "Connect" in the AI Assistant to connect to the AI service

## Building Godot (if needed)

If Godot needs to be rebuilt after code changes:

```bash
cd /g/makabaka-engine/godot && python -m SCons platform=windows target=editor d3d12=no -j8
```

Note: Make sure to kill Godot first before rebuilding, or the build will fail with "access denied".

## Key Paths

- Godot executable: `g:/makabaka-engine/godot/bin/godot.windows.editor.x86_64.exe`
- Test project: `G:/MakabakaGames/Test`
- AI server: `http://localhost:4096`
- AI Assistant source: `g:/makabaka-engine/godot/editor/plugins/ai_assistant/`

## Troubleshooting

- If AI server fails to start, check if port 4096 is already in use
- If build fails with "access denied", kill Godot first with `taskkill //F //IM godot.windows.editor.x86_64.exe`
- If AI Assistant shows "Disconnected", click the "Connect" button
- Run `curl http://localhost:4096/doc` to see the full API documentation

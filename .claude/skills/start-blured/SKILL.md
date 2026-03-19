---
name: start-blured
description: Start the Blured Engine (OpenCode AI server + Godot editor)
---

# Start Blured Engine

This skill starts the complete Blured Engine environment using `start_blured.sh`.

## Instructions

Simply run the startup script:

```bash
bash .claude/skills/start-blured/scripts/start_blured.sh
```

To open the **Project Manager** instead (for creating/selecting a project):

```bash
bash .claude/skills/start-blured/scripts/start_blured.sh -new
```

When the user passes `-new` as an argument to `/start-blured`, pass it through to the script.

This script will:
1. Load configuration from `.env` (project path, AI port)
2. Kill any existing Godot process
3. Check/start the OpenCode AI server
4. Launch the Godot editor with the configured project (or the Project Manager if `-new`)

## Configuration

The workspace is configured via `.env` (gitignored, per-machine):

```env
BLURED_PROJECT_PATH=G:\GodotProjects\rogue-card
BLURED_AI_PORT=13700
```

To change the project, edit the `.env` file.

## Troubleshooting

- If AI server fails to start, check if the port is already in use
- If build fails with "access denied", kill Godot first
- If AI Assistant shows "Disconnected", click the "Connect" button
- To change the project, edit `g:/blured-engine/.env`

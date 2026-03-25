#!/bin/bash

WORKSPACE_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$WORKSPACE_ROOT"

# Defaults
BLURED_PROJECT_PATH=""
BLURED_AI_PORT=13700

# Load .env
if [ -f "$WORKSPACE_ROOT/.env" ]; then
    while IFS= read -r line; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$line" ]] && continue
        line="${line//$'\r'/}"
        key="${line%%=*}"
        value="${line#*=}"
        key=$(echo "$key" | xargs)
        [ -z "$key" ] && continue
        export "$key=$value"
    done < "$WORKSPACE_ROOT/.env"
fi

[ -z "$BLURED_PROJECT_PATH" ] && BLURED_PROJECT_PATH="G:/BluredGames/Test"
[ -z "$BLURED_AI_PORT" ] && BLURED_AI_PORT=13700

NEW_PROJECT=false
[ "$1" = "-new" ] && NEW_PROJECT=true

echo "============================================"
echo "Starting Blured Engine"
echo "============================================"
echo "Project: $BLURED_PROJECT_PATH"
echo "AI Port: $BLURED_AI_PORT"
echo ""

# Kill existing Godot
taskkill //F //IM godot.windows.editor.x86_64.exe 2>/dev/null && echo "Killed Godot" || true

# Kill existing AI server
taskkill //F //IM opencode.exe 2>/dev/null && echo "Killed OpenCode" || true
AI_PID=$(netstat -ano 2>/dev/null | grep ":${BLURED_AI_PORT}.*LISTENING" | awk '{print $NF}' | head -1)
if [ -n "$AI_PID" ] && [ "$AI_PID" != "0" ]; then
    taskkill //F //PID "$AI_PID" 2>/dev/null && echo "Killed process on port $BLURED_AI_PORT"
fi

# Brief wait for port release
sleep 1

# Start AI server
OPENCODE_EXE="$WORKSPACE_ROOT/opencode/packages/opencode/dist/opencode-windows-x64/bin/opencode.exe"
if [ ! -f "$OPENCODE_EXE" ]; then
    echo "ERROR: OpenCode not found. Run Build Blured first."
    exit 1
fi

export BLURED_WORKSPACE="$WORKSPACE_ROOT"
"$OPENCODE_EXE" serve --port "$BLURED_AI_PORT" >"$WORKSPACE_ROOT/opencode.log" 2>&1 &

# Wait for server (check /doc endpoint which responds locally)
echo -n "Waiting for AI Server"
for i in $(seq 1 30); do
    if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$BLURED_AI_PORT/doc" 2>/dev/null | grep -q "200"; then
        echo " Ready!"
        break
    fi
    echo -n "."
    sleep 1
done

if ! curl -s -o /dev/null -w "%{http_code}" "http://localhost:$BLURED_AI_PORT/doc" 2>/dev/null | grep -q "200"; then
    echo ""
    echo "WARNING: AI Server may not have started. Check opencode.log"
fi

# Start Godot
echo "Starting Blured Editor..."
if [ "$NEW_PROJECT" = true ]; then
    start "" "$WORKSPACE_ROOT/godot/bin/godot.windows.editor.x86_64.exe" --project-manager
else
    start "" "$WORKSPACE_ROOT/godot/bin/godot.windows.editor.x86_64.exe" --path "$BLURED_PROJECT_PATH" --editor
fi

echo ""
echo "============================================"
echo "Blured Engine started!"
echo "  AI Server: http://localhost:$BLURED_AI_PORT"
if [ "$NEW_PROJECT" = true ]; then
    echo "  Editor: Project Manager"
else
    echo "  Editor: $BLURED_PROJECT_PATH"
fi
echo "============================================"

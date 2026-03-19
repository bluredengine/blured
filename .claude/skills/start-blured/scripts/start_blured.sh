#!/bin/bash
echo "============================================"
echo "Starting Blured Engine"
echo "============================================"

# Derive workspace root: this script lives at <workspace>/.claude/skills/start-blured/scripts/
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

# Defaults
BLURED_PROJECT_PATH=""
BLURED_AI_PORT=13700

# Load .env from workspace root (preserve backslashes)
# Export all vars so child processes (OpenCode) inherit them
for envfile in "$WORKSPACE_ROOT/.env"; do
    if [ -f "$envfile" ]; then
        while IFS= read -r line; do
            # Skip comments and empty lines
            [[ "$line" =~ ^[[:space:]]*# ]] && continue
            [[ -z "$line" ]] && continue
            # Strip carriage return (Windows line endings)
            line="${line//$'\r'/}"
            # Split on first '='
            key="${line%%=*}"
            value="${line#*=}"
            # Trim whitespace from key
            key=$(echo "$key" | xargs)
            [ -z "$key" ] && continue
            export "$key=$value"
        done < "$envfile"
    fi
done

# Apply defaults if not set
[ -z "$BLURED_PROJECT_PATH" ] && BLURED_PROJECT_PATH="G:/BluredGames/Test"
[ -z "$BLURED_AI_PORT" ] && BLURED_AI_PORT=13700

NEW_PROJECT=false
if [ "$1" = "-new" ]; then
    NEW_PROJECT=true
fi

echo "Workspace: $WORKSPACE_ROOT"
if [ "$NEW_PROJECT" = true ]; then
    echo "Mode: Project Manager"
else
    echo "Project: $BLURED_PROJECT_PATH"
fi
echo "AI Port: $BLURED_AI_PORT"
echo ""

# Kill existing Godot process
taskkill //F //IM godot.windows.editor.x86_64.exe 2>/dev/null || echo "Godot not running"

# Always restart AI server to pick up latest build
taskkill //F //IM opencode.exe 2>/dev/null && echo "Killed existing OpenCode process" || true
# Also kill by port in case the process name differs
AI_PID=$(netstat -ano 2>/dev/null | grep ":${BLURED_AI_PORT}.*LISTENING" | awk '{print $NF}' | head -1)
if [ -n "$AI_PID" ] && [ "$AI_PID" != "0" ]; then
    echo "Killing process on port $BLURED_AI_PORT (PID $AI_PID)..."
    taskkill //F //PID "$AI_PID" 2>/dev/null
fi
# Wait for port to be released
for i in $(seq 1 10); do
    if ! netstat -ano 2>/dev/null | grep ":${BLURED_AI_PORT}.*LISTENING" >/dev/null; then
        break
    fi
    sleep 1
done

echo "Starting AI Server on port $BLURED_AI_PORT..."
OPENCODE_EXE="$WORKSPACE_ROOT/opencode/packages/opencode/dist/opencode-windows-x64/bin/opencode.exe"

if [ ! -f "$OPENCODE_EXE" ]; then
    echo "ERROR: OpenCode not found at $OPENCODE_EXE"
    echo "Run /build-blured first."
else
    OPENCODE_LOG="$WORKSPACE_ROOT/opencode.log"
    export BLURED_WORKSPACE="$WORKSPACE_ROOT"
    "$OPENCODE_EXE" serve --port "$BLURED_AI_PORT" >"$OPENCODE_LOG" 2>&1 &
fi

# Wait for server to be ready
echo -n "Waiting for AI Server"
for i in $(seq 1 60); do
    if curl -s "http://localhost:$BLURED_AI_PORT/" >/dev/null 2>&1; then
        echo " Ready!"
        break
    fi
    echo -n "."
    sleep 1
done

if ! curl -s "http://localhost:$BLURED_AI_PORT/" >/dev/null 2>&1; then
    echo ""
    echo "WARNING: AI Server may not have started. Check port $BLURED_AI_PORT"
fi

# Start Blured Engine (Godot with native AI module)
echo "Starting Blured Engine..."
if [ "$NEW_PROJECT" = true ]; then
    start "" "$WORKSPACE_ROOT/godot/bin/godot.windows.editor.x86_64.exe" --project-manager
else
    start "" "$WORKSPACE_ROOT/godot/bin/godot.windows.editor.x86_64.exe" --path "$BLURED_PROJECT_PATH" --editor
fi

echo ""
echo "Blured Engine started!"
echo "- AI Server: http://localhost:$BLURED_AI_PORT"
if [ "$NEW_PROJECT" = true ]; then
    echo "- Blured Editor: Project Manager"
else
    echo "- Blured Editor: Opening $BLURED_PROJECT_PATH"
fi
echo "- AI Assistant: Built-in (right panel)"

#!/bin/bash
set -e

WORKSPACE_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$WORKSPACE_ROOT"

echo "============================================"
echo "Building Blured Engine"
echo "============================================"

# Detect what changed
OC_CHANGES=$(cd opencode && git diff --stat HEAD 2>/dev/null | tail -1)
GD_CHANGES=$(cd godot && git diff --stat HEAD 2>/dev/null | tail -1)

BUILD_OC=false
BUILD_GD=false

if [ -n "$OC_CHANGES" ] && [ -z "$GD_CHANGES" ]; then
    echo "Detected: OpenCode changes only"
    BUILD_OC=true
elif [ -z "$OC_CHANGES" ] && [ -n "$GD_CHANGES" ]; then
    echo "Detected: Godot changes only"
    BUILD_GD=true
elif [ -n "$OC_CHANGES" ] && [ -n "$GD_CHANGES" ]; then
    echo "Detected: Both OpenCode and Godot changes"
    BUILD_OC=true
    BUILD_GD=true
else
    echo "No uncommitted changes detected - building both"
    BUILD_OC=true
    BUILD_GD=true
fi

# Kill relevant processes
if [ "$BUILD_OC" = true ]; then
    taskkill //F //IM opencode.exe 2>/dev/null && echo "Killed OpenCode" || true
    taskkill //F //IM bun.exe 2>/dev/null && echo "Killed Bun" || true
fi
if [ "$BUILD_GD" = true ]; then
    taskkill //F //IM godot.windows.editor.x86_64.exe 2>/dev/null && echo "Killed Godot" || true
fi

# Build OpenCode
if [ "$BUILD_OC" = true ]; then
    echo ""
    echo "--- Building OpenCode ---"
    cd "$WORKSPACE_ROOT/opencode/packages/opencode"
    bun run build --single
    echo "OpenCode build complete."
    cd "$WORKSPACE_ROOT"
fi

# Build Godot
if [ "$BUILD_GD" = true ]; then
    echo ""
    echo "--- Building Godot Engine ---"
    cd "$WORKSPACE_ROOT/godot"
    python -m SCons platform=windows target=editor d3d12=no -j8
    echo "Godot build complete."
    cd "$WORKSPACE_ROOT"
fi

echo ""
echo "============================================"
echo "Build finished!"
[ "$BUILD_OC" = true ] && echo "  OpenCode: opencode/packages/opencode/dist/opencode-windows-x64/bin/opencode.exe"
[ "$BUILD_GD" = true ] && echo "  Godot:    godot/bin/godot.windows.editor.x86_64.exe"
[ "$BUILD_OC" = false ] && echo "  OpenCode: skipped (no changes)"
[ "$BUILD_GD" = false ] && echo "  Godot:    skipped (no changes)"
echo "============================================"

#!/bin/bash
# Package Blured Engine into a distributable directory.
# Usage: bash package_blured.sh [workspace_root]

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="${1:-$(cd "$SCRIPT_DIR/../../../.." && pwd)}"
DIST="$WORKSPACE/dist/blured-engine"

echo "============================================"
echo " Packaging Blured Engine"
echo "============================================"
echo ""
echo "Workspace: $WORKSPACE"
echo "Output:    $DIST"
echo ""

# Clean previous package
if [ -d "$DIST" ]; then
    echo "Cleaning previous package..."
    find "$DIST" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
fi

# Create directory structure
mkdir -p "$DIST/bin"
mkdir -p "$DIST/docs"
mkdir -p "$DIST/tools"

# 1. Copy Godot editor
echo "[1/8] Copying Godot editor..."
GODOT_EXE="$WORKSPACE/godot/bin/godot.windows.editor.x86_64.exe"
if [ ! -f "$GODOT_EXE" ]; then
    echo "ERROR: Godot editor not found at $GODOT_EXE"
    echo "Run /build-blured first."
    exit 1
fi
cp "$GODOT_EXE" "$DIST/bin/blured.exe"

# 2. Copy OpenCode server
echo "[2/8] Copying OpenCode server..."
OPENCODE_EXE="$WORKSPACE/opencode/packages/opencode/dist/opencode-windows-x64/bin/opencode.exe"
if [ ! -f "$OPENCODE_EXE" ]; then
    echo "ERROR: OpenCode exe not found at $OPENCODE_EXE"
    echo "Run /build-blured first."
    exit 1
fi
cp "$OPENCODE_EXE" "$DIST/bin/opencode.exe"

# 3. Build and copy launcher
echo "[3/8] Building launcher..."
pushd "$WORKSPACE/launcher" > /dev/null
if [ -f "Cargo.toml" ]; then
    cargo build --release
    if [ $? -ne 0 ]; then
        echo "ERROR: Launcher build failed."
        popd > /dev/null
        exit 1
    fi
    popd > /dev/null
    if [ -f "$WORKSPACE/launcher/target/release/blured-launcher.exe" ]; then
        cp "$WORKSPACE/launcher/target/release/blured-launcher.exe" "$DIST/blured.exe"
    else
        echo "WARNING: Launcher binary not found at launcher/target/release/blured-launcher.exe, skipping."
    fi
else
    popd > /dev/null
    echo "WARNING: No Cargo.toml found in launcher/, skipping."
fi

# 4. Copy docs
echo "[4/8] Copying docs..."
[ -d "$WORKSPACE/docs" ] && cp -r "$WORKSPACE/docs/"* "$DIST/docs/" 2>/dev/null || true

# 5. Copy config files
echo "[5/8] Copying configuration..."
[ -f "$WORKSPACE/blured.json" ] && cp "$WORKSPACE/blured.json" "$DIST/"
[ -f "$WORKSPACE/blured-models.json" ] && cp "$WORKSPACE/blured-models.json" "$DIST/"
[ -f "$WORKSPACE/.env.example" ] && cp "$WORKSPACE/.env.example" "$DIST/.env.example"
[ -f "$WORKSPACE/LICENSE" ] && cp "$WORKSPACE/LICENSE" "$DIST/"

# 6. Copy prompts
echo "[6/8] Copying prompts..."
if [ -d "$WORKSPACE/prompts" ]; then
    cp -r "$WORKSPACE/prompts" "$DIST/prompts"
    echo "  Copied prompts/"
else
    echo "  WARNING: No prompts directory found"
fi

# 7. Copy tools (ScreenCapture.exe for snipping)
echo "[7/8] Copying tools..."
TOOLS_DIR="$WORKSPACE/godot/bin/tools"
if [ -d "$TOOLS_DIR" ]; then
    cp -r "$TOOLS_DIR/"* "$DIST/tools/" 2>/dev/null || true
    echo "  Copied tools from $TOOLS_DIR"
else
    echo "  WARNING: No tools directory found at $TOOLS_DIR"
fi

# 8. Write version file
echo "[8/8] Writing version..."
echo "0.1.0" > "$DIST/VERSION"

# Summary
echo ""
echo "============================================"
echo " Package created: $DIST"
echo "============================================"
echo ""
echo "Contents:"
echo "  $DIST/blured.exe            (launcher)"
echo "  $DIST/bin/blured.exe        (godot editor)"
echo "  $DIST/bin/opencode.exe      (AI server)"
echo "  $DIST/prompts/              (AI prompts and skills)"
echo "  $DIST/tools/                (ScreenCapture.exe for snipping)"
echo ""
echo "Launch with: blured.exe"
echo "  or: blured.exe --project-manager"
echo "  or: blured.exe \"C:\\path\\to\\project\""

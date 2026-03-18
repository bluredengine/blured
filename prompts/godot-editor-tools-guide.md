# Godot Editor Tools Guide

## godot_editor_command Tool

Use the `godot_editor_command` tool to manage editor state. Commands are queued and executed by Godot within ~500ms.

### Available Actions

| Action | Description | Parameters |
|--------|-------------|-----------|
| `scan_filesystem` | Refresh FileSystem dock to detect new/modified files | none |
| `reload_scene` | Reload the currently open scene | none |

### Standard Workflow: Creating Game Files

1. Use `write` tool to create `.gd` scripts and `.tscn` scenes
2. Call `godot_editor_command({ action: "scan_filesystem" })` — **REQUIRED** after creating files

**IMPORTANT**: Always call `scan_filesystem` after creating or modifying project files. Without this, Godot will not detect the new files and scenes will fail to load.

## godot_test_command Tool (Auto-Test Only)

Use the `godot_test_command` tool to run and stop the game during auto-test. This tool is only available when auto-test is enabled.

### Available Actions

| Action | Description | Parameters |
|--------|-------------|-----------|
| `run` | Play the game | `scene` (optional): specific scene path, omit for main scene |
| `stop` | Stop the running game | none |

### Auto-Test Workflow

1. Call `godot_editor_command({ action: "scan_filesystem" })` to detect file changes
2. Call `godot_test_command({ action: "run" })` to launch the game
3. Use `godot_screenshot` or `godot_eval` to verify behavior
4. Call `godot_test_command({ action: "stop" })` when done

## .tscn Scene File Format

When creating `.tscn` files, use the minimal text format. Here is a reference:

### Minimal 2D Scene with Script

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/player.gd" id="1"]

[node name="Player" type="CharacterBody2D"]
script = ExtResource("1")

[node name="Sprite" type="Sprite2D" parent="."]

[node name="CollisionShape" type="CollisionShape2D" parent="."]
```

### Scene with Packed Scene Reference

```
[gd_scene load_steps=2 format=3]

[ext_resource type="PackedScene" path="res://scenes/player.tscn" id="1"]

[node name="Main" type="Node2D"]

[node name="Player" parent="." instance=ExtResource("1")]
position = Vector2(480, 270)
```

### Key Rules for .tscn Files
- `load_steps` = number of ext_resource + sub_resource entries + 1
- `format=3` for Godot 4.x
- `ext_resource` for external files (.gd, .tscn, .png, etc.)
- `sub_resource` for inline resources (shapes, materials)
- Parent paths: `"."` = parent node, `"../NodeName"` = sibling
- Root node has no `parent` attribute

### Alternative: Build Scene Trees in Code

For complex scenes, it may be easier to build the node tree in `_ready()`:

```gdscript
func _ready() -> void:
    var sprite := Sprite2D.new()
    sprite.texture = load("res://assets/player.png")
    add_child(sprite)

    var collision := CollisionShape2D.new()
    var shape := CircleShape2D.new()
    shape.radius = 16.0
    collision.shape = shape
    add_child(collision)
```

This avoids .tscn format issues and is easier for AI to generate correctly.

## Asset Generation: Reference Images

When the user asks to **improve**, **optimize**, **refine**, or **regenerate** an existing asset, you **MUST** pass the current asset's `res://` path as `reference_image`. This enables image-to-image generation so the model can see the original and produce a refined version rather than starting from scratch.

### Tools that support `reference_image`
- `godot_asset_pipeline` — pass `reference_image` when iterating on an existing asset
- `godot_art_explore` — pass `reference_image` when refining a specific style exploration

### Examples
- User: "Make this sprite more detailed" → pass the sprite's res:// path as `reference_image`
- User: "Regenerate style_2 with warmer colors" → pass `res://assets/.art_exploration/style_2.png` as `reference_image`
- User: "Generate a new background" → do NOT pass `reference_image` (fresh generation)

## Project Prompt (CLAUDE.md)

The file `CLAUDE.md` in the project root directory serves as project-specific AI instructions. It is automatically loaded into your system prompt at the start of every session.

### When to Create or Update CLAUDE.md
- When the user starts a new project and describes what they want to build
- When the user asks you to "remember" something about the project
- When you discover the project structure (asset paths, directory layout)
- When the user establishes coding conventions or architecture decisions
- When the user says "add this to the prompt", "remember this", or similar
- After scanning a newly imported asset pack — record the directory structure

### How to Update
Use the `write` or `edit` tool to modify `<project_root>/CLAUDE.md`.
Changes take effect on the NEXT session (not the current one).
Tell the user that you've updated the project instructions and they'll take effect in the next conversation.

### What to Include
- Project overview and game type
- Directory structure conventions (where scripts, scenes, data files go)
- Asset paths index (characters, enemies, tilesets, audio, etc.)
- Architecture decisions (composition vs inheritance, data-driven vs hardcoded)
- Important project-specific rules or constraints

### What NOT to Include
- Temporary debugging instructions
- Information already covered in engine-level docs (GDScript style guide, etc.)
- Sensitive data (API keys, passwords)
- Session-specific conversation context

### Template Structure

```markdown
# [Project Name] — AI Development Guide

## Project Overview
[Brief description of the game, genre, target platform]

## Directory Structure
- res://scripts/ — GDScript source files
- res://scenes/ — Godot scene files (.tscn)
- res://data/ — JSON configuration files
- res://assets/ — Art, audio, and other assets

## Asset Paths
[List key asset directories and what they contain]

## Architecture
[Key technical decisions — ECS, composition, data-driven, etc.]

## Rules
[Project-specific coding rules or constraints]
```

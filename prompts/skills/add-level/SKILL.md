---
name: add-level
description: Guided level design — create a new level with purpose, environment, layout, enemies, and auto-generated assets. Use when user says "add a level", "new level", "create a stage", or similar.
auto_detect: add.*level|new.*level|create.*level|add.*stage|new.*stage|create.*stage|another.*level|next.*level|more.*levels
---

# Guided Level Design

You are adding a new level to an existing game. This skill guides through purpose, layout, assets, and testing.

**Prerequisites:**
- `docs/game_design.md` must exist (need to know game mechanics)
- Visual direction must be locked (`docs/visual_bible.md` or style set)
- At least one level must already exist (from scaffolding)

If prerequisites are missing, tell the user: "You need a base game first. Use /create-game to set up the project."

---

## Step 1: Level Purpose

Call the `question` tool with:
- header: "Level Purpose"
- question: "What is this level's purpose?"
- 3-4 options tailored to the game's mechanics (from `docs/game_design.md`)

Each option should describe a CONCRETE scenario, not abstract categories.

Example options for a platformer with gravity-flip mechanic:
- { label: "Gravity shaft", description: "A vertical shaft where you must flip gravity mid-jump to navigate alternating platforms" }
- { label: "Gravity boss", description: "A boss that controls gravity in its arena — floor becomes ceiling every 10 seconds" }
- { label: "Hidden observatory", description: "An abandoned observatory with hidden rooms revealed only when gravity is reversed" }

---

## Step 2: Environment and Mood

Call the `question` tool with:
- header: "Level Mood"
- question: "What's the mood and environment of this level?"
- 3 options that fit within the established visual style (from `docs/visual_bible.md` or style settings)

Each option should describe a specific PLACE with sensory details.
Tie the environment to the worldbuilding if it exists.
Options must be visually distinct from existing levels.

Example options:
- { label: "Crystal caves", description: "Flooded crystal caves — bioluminescent water, stalactites dripping light, echoing silence" }
- { label: "Burning library", description: "Floating pages as platforms, ink-smoke particles, warm orange palette" }
- { label: "Frozen clocktower", description: "Giant frozen gears as platforms, time-stop zones, cold blue-white light" }

---

## Step 3: Level Layout

Based on the user's choices, design the level:

1. **Describe the layout** in 3-5 sentences:
   - Entry point and exit/goal
   - Key landmarks (2-3 memorable spots)
   - How the level purpose is expressed spatially
   - Difficulty curve within the level (easy start → challenging middle → climax)

2. **List all new elements needed:**
   - New enemy types (if any) — describe appearance + behavior
   - New environment pieces — platforms, hazards, decorations
   - New collectibles or interactive objects
   - Background/parallax layers

3. **Confirm with the user** before generating code.

---

## Step 4: Generate Level

Create the level scene and scripts:

1. **Create the scene file** (`.tscn`):
   - Proper node hierarchy (TileMapLayer, spawn points, camera limits, triggers)
   - Place enemies, collectibles, hazards according to layout
   - Set up camera bounds and transitions
   - Add entry/exit connections to the level progression system

2. **Create level-specific scripts** (if needed):
   - Boss AI scripts
   - Level-specific mechanics (environmental hazards, triggers, cutscenes)
   - Follow coding standards from `docs/`

3. **Update level progression:**
   - Add the new level to the game's level list/flow
   - Connect it to the previous level's exit
   - Set up any unlock conditions

---

## Step 5: Generate Level Assets

Generate art for all new elements:

1. **New enemies:** Call `godot_asset_generate` for each new enemy type
2. **Environment pieces:** Call `godot_asset_generate` for new tiles, platforms, backgrounds
3. **Props and collectibles:** Call `godot_asset_generate` for interactive objects
4. Call `godot_editor_command` with `scan_filesystem` — pick up new assets

---

## Step 6: Test and Verify

1. Call `godot_editor_command` with `run` — launch the game
2. Navigate to the new level
3. Call `godot_screenshot` — capture the level
4. Analyze the screenshot:
   - Is the layout readable? Can the player see where to go?
   - Do new assets match the existing visual style?
   - Are enemies visible and distinguishable?
   - Is the difficulty appropriate for this position in the game?
5. Fix any issues found
6. Call `godot_editor_command` with `stop`

Say: "Level added! Press Play and navigate to the new level to try it. Want to add another level or /polish the game?"

---

## Rules

- **Every level needs a PURPOSE** — no filler levels
- **Maintain visual consistency** — new assets must match the locked style
- **Escalate, don't repeat** — each level should feel different from the last
- **Test the level** — always run and screenshot before declaring done
- **Respect the game's core action** — every level should make the core mechanic shine

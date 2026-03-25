---
name: ui-production
description: Create polished player-facing UI from whitebox to final assets. 5-step workflow from UI mockup to deployed game UI. Do NOT use for whitebox/prototype UI.
auto_detect: create.*UI|design.*UI|UI.*production|make.*game.*UI|polished.*UI|final.*UI|UI.*from.*whitebox|优化.*UI|UI.*优化|改进.*UI|UI.*改进|美化.*UI|UI.*美化|improve.*UI|UI.*improve|polish.*UI|UI.*polish|upgrade.*UI|UI.*upgrade|refine.*UI|UI.*refine|UI.*asset|generate.*UI|UI.*生成|做.*UI|UI.*做|换.*UI|UI.*换
---

# UI Production Workflow

You are now in UI Production Mode. This is a 5-step process for building polished, player-facing UI.

CRITICAL RULES:
- STOP after each step and wait for explicit user approval before proceeding
- Never skip steps — each step depends on the previous one
- Use `godot_screenshot` after visual changes for user review
- This workflow is for FINAL UI only, not whitebox/prototype

---

## Step 1: UI Mockup (Cornerstone)

**Goal:** Establish the overall UI visual style for the entire game.

**Prerequisites:** Key Art must exist and style profile (`.ai_style_profile.json`) must be set.

**Actions:**
1. Verify style profile exists. If not, tell user to run art exploration first.
2. Call `godot_cornerstone_generate` with:
   - `asset_type`: "ui"
   - `aspect_ratio`: Match game orientation (e.g. "16:9" for landscape, "9:16" for portrait)
   - `subject`: Describe the overall UI mood and feel, referencing game theme. Example: "Game HUD and menu interface with health bars, inventory slots, skill buttons, gold counter, minimap frame — all in a cohesive style"
   - Do NOT describe a specific screen — this is the global UI style reference
3. Score the result. Retry if score < 7.
4. STOP and show the result to the user.

**Ask user via `question` tool:**
- header: "UI Mockup Review"
- question: "This is the UI style mockup. Does this visual direction match your vision?"
- options: "Approved — proceed to layout", "Regenerate with different style", "I want to adjust the art direction"

---

## Step 2: UI Layout Image (Cornerstone)

**Goal:** Generate an accurate layout image for a SPECIFIC screen, showing exact element positions.

**Prerequisites:** Step 1 mockup approved + a whitebox scene for the target screen exists.

**Actions:**
1. Analyze the whitebox scene:
   - Use `godot_screenshot` to capture the current whitebox, OR
   - Use `godot_eval` to inspect the scene tree and list all functional UI elements
2. Enumerate ALL functional elements (buttons, labels, panels, progress bars, lists, etc.)
3. Present the element list to the user for confirmation before generating
4. Call `godot_cornerstone_generate` with:
   - `asset_type`: "ui"
   - `aspect_ratio`: Match screen orientation
   - `reference_image`: Path to the Step 1 UI mockup (for style consistency)
   - `subject`: Describe the EXACT layout with positions. Example: "Main menu screen layout: centered game title at top, three stacked buttons (Play, Settings, Quit) in center, version text bottom-left, decorative border frame"
5. Score the result. Retry with adjusted subject if layout doesn't match.
6. STOP and show the result to the user.

**Ask user via `question` tool:**
- header: "Layout Review"
- question: "Here is the layout for [screen name]. Does the element placement match your requirements?"
- options: "Approved — proceed to scene creation", "Adjust element positions", "Add/remove elements"

---

## Step 3: Build Layout Scene (.tscn)

**Goal:** Create a NEW, STANDALONE .tscn scene that replicates the layout image. This scene is for visual layout testing ONLY.

**Prerequisites:** Step 2 layout image approved.

**Follow skill `ui-layout-replicate`** for the complete replication workflow (measuring, font selection, placeholder textures, writing the .tscn, and verification).

Additional rules for this step:
- Create a BRAND NEW .tscn file — do NOT modify any existing game scenes or scripts
- Do NOT touch the game's runtime UI code, dynamic generation code, or any existing .gd scripts
- Write the scene to `res://scenes/ui/[screen_name]_layout.tscn`

**Ask user via `question` tool:**
- header: "Layout Scene Created"
- question: "The scene is at [path]. Please open it in the editor and adjust positions/sizes as needed. The colored rectangles are placeholders for real textures. Let me know when finalized."
- options: "Layout is finalized — generate assets", "I'm still adjusting", "Take a screenshot to compare"

**IMPORTANT:** Wait for user to manually tweak in editor. This step is collaborative.

---

## Step 4: Generate & Replace UI Assets

**Goal:** Generate actual UI textures and replace placeholders in the scene.

**Prerequisites:** Step 3 scene layout finalized by user.

**Actions:**
1. Take `godot_screenshot` of the finalized layout scene
2. Discover all placeholder textures created in Step 3:
   - Each placeholder PNG has metadata (`.ai.{filename}/metadata.json`) with `origin: "placeholder"`, `prompt`, and `usage` (dimensions, role, transparency)
   - List all `res://assets/ui/[screen]/` files with placeholder origin
3. Generate real textures — use atlas generation by default:

   **Default: Atlas generation** (MANDATORY for most UI elements):
   - Group ALL placeholders into atlas categories by visual similarity (e.g. buttons, icons, panels, decorative elements)
   - For each category, call `godot_asset_pipeline` with a combined prompt describing all elements in a single sheet (e.g. "UI button sheet: normal state, hover state, pressed state, disabled state — arranged in a row")
   - Call `godot_atlas_split` to split the sheet into individual files matching placeholder paths
   - Each split file overwrites its placeholder, preserving metadata
   - Atlas generation produces more visually consistent results than generating elements individually

   **Exception: Individual generation** (ONLY for large/full-screen images):
   - Use individual generation ONLY when an element is too large for an atlas — e.g. a background image covering the whole screen, a full-width banner, or a large illustration
   - Call `godot_asset_pipeline` for each such placeholder:
     - `destination`: same path as placeholder (overwrites it)
     - `prompt` and `requirements` are auto-read from placeholder metadata — no need to re-specify
   - The pipeline auto-postprocesses (bg removal, trim, resize, pad to exact dimensions)

4. No .tscn updates needed — `TextureRect` nodes already reference the placeholder PNGs, which are now replaced with real textures in-place
5. Call `godot_editor_command` with `scan_filesystem` then `reload_scene`
6. Take `godot_screenshot` to show the result

**Ask user via `question` tool:**
- header: "UI Assets Applied"
- question: "Here is the UI with real textures. Are the assets acceptable?"
- options: "Approved — deploy to game", "Regenerate [specific element]", "Regenerate all assets with different style"

---

## Step 5: Deploy to Runtime

**Goal:** Finalize and integrate the UI scene into the game.

**Prerequisites:** Step 4 assets approved by user.

**Actions:**
1. Ask user for the target runtime location (e.g. `res://scenes/game/main_menu.tscn`)
2. Copy or move the UI scene file to the target location
3. If replacing an existing whitebox scene, update any `preload()`/`load()` references
4. If this is a new scene, add it to the appropriate scene loader or autoload
5. Call `godot_editor_command` with `scan_filesystem`
6. Optionally run the game with `godot_editor_command` action `run` to verify

**Say:** "UI production complete. The final scene is at [path]. Run the game to verify it works in context."

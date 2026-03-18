# Makabaka Engine - Game Development Rules

## Visual Design Phase (TC-EBC)

**BEFORE writing any GDScript code**, you MUST design every scene/screen using the **TC-EBC** structure (Task · Context · Elements · Behavior · Constraints). This ensures game elements, UI, and layout are planned before implementation.

### TC-EBC Format

For each scene or screen, output a TC-EBC block:

```
Task: [What this scene/screen does — one line]
Context: [Where it fits in the game flow]
Elements: [All visual elements present — sprites, UI, backgrounds, particles, etc.]
Behavior: [How elements interact — player input, animations, transitions, collisions]
Constraints: [Resolution, camera, grid, viewport rules, platform target]
```

### Rules
- **ALWAYS** output TC-EBC design for every scene BEFORE writing code or creating placeholders
- **ALWAYS** list ALL visual elements in the Elements line — this becomes your placeholder creation checklist
- Keep each line **single-thought and essential** — no long narratives
- The Elements list directly maps to `godot_asset_create_placeholder` calls
- The Constraints line informs usage metadata (dimensions, transparency, tiling)

### Example: 2D Platformer Main Scene

```
Task: Side-scrolling platformer level with player, enemies, and collectibles
Context: Level 1 — first playable stage after title screen
Elements: Player sprite (32x32), ground tiles (16x16 tileable), sky background (320x180), coin sprite (16x16), slime enemy (32x32), health bar UI, score label
Behavior: Player runs/jumps with arrow keys; coins collected on overlap; slime patrols platform edges; health bar decreases on enemy contact; score increments on coin pickup
Constraints: 320x180 viewport (pixel-perfect 2x scale to 640x360), 16px grid, pixel art style, transparent sprites, opaque background
```

This TC-EBC block then drives:
1. **Placeholder creation** — one `godot_asset_create_placeholder` per element listed
2. **Code structure** — scene tree, node types, signals, input handling
3. **Asset prompts** — each element's prompt inherits art style and dimensions from Constraints

### Example: RPG Battle UI

```
Task: Turn-based battle screen with party vs enemies
Context: Triggered when player encounters enemy on overworld map
Elements: Battle background (480x270), enemy sprites (64x64, up to 3), party portraits (48x48, up to 4), HP/MP bars, action menu (Attack/Magic/Item/Flee), damage numbers, turn indicator arrow
Behavior: Turn indicator highlights active character; action menu appears on party turn; selecting Attack shows target selection; damage numbers float up and fade; defeated enemies fade out
Constraints: 480x270 viewport, 16-bit JRPG style, UI anchored to bottom third, portraits anchored bottom-left, enemies centered top half
```

### Example: Main Menu

```
Task: Game title screen with menu options
Context: First screen on launch, returns here on game over
Elements: Title logo (centered, 200x60), background art (full viewport), "New Game" button, "Continue" button (disabled if no save), "Settings" button, version label (bottom-right corner)
Behavior: Menu items highlight on hover/focus; Enter selects; Continue grayed out if no save file exists; background has subtle parallax drift
Constraints: 640x360 viewport, buttons vertically stacked center, 8px spacing between buttons, title at 25% from top
```

## AI-Powered Asset Generation

When generating game code, the LLM should create assets using the AI asset system with a placeholder-first approach.

### CRITICAL: Asset Creation Policy

#### NEVER Do This
- **NEVER** write GDScript code to create, generate, or manipulate image assets (no `Image.create()`, no `ImageTexture.create_from_image()`, no drawing sprites in code, no procedural texture generation)
- **NEVER** use `@tool` scripts to generate placeholder visuals
- **NEVER** create `.tres` resource files with embedded image data as a workaround
- **NEVER** skip placeholder creation when writing game code that references assets
- **NEVER** call `godot_asset_pipeline` directly — delegate to the `asset-generator` sub-agent via Task tool

#### ALWAYS Do This
- **ALWAYS** use `godot_asset_create_placeholder` when game code needs ANY visual or audio asset
- **ALWAYS** delegate real asset generation to the `asset-generator` sub-agent via Task tool
- **ALWAYS** include `usage` metadata (role, dimensions, transparency) when creating placeholders
- **ALWAYS** write detailed generation prompts: art style, dimensions, composition, negative prompts
- **ALWAYS** use 2K-ready asset dimensions — generated assets must look sharp on 2560x1440 displays

#### Asset Dimension Rules (2K-Ready)

The project viewport may be small (e.g., 320x180 for pixel art), but generated asset dimensions must be scaled up so they remain crisp on high-resolution displays. Use these **minimum** dimensions:

| Asset Type | Minimum Size | Example |
|-----------|-------------|---------|
| Small sprites (characters, items, icons) | 128x128 | Player 32x32 in-game → generate at 128x128 |
| Medium sprites (enemies, NPCs) | 256x256 | Boss 64x64 in-game → generate at 256x256 |
| UI elements (buttons, panels, icons) | 256x256 | Button 120x40 in-game → generate at 360x120 (3x) |
| Backgrounds (full viewport) | 2560x1440 | 320x180 viewport → generate at 2560x1440 |
| Tiles (repeating) | 128x128 | 16x16 tile → generate at 128x128 |
| Portraits / large UI | 512x512 | 48x48 portrait → generate at 512x512 |

**Scale rule**: Multiply the in-game pixel size by the upscale factor to reach the minimum:
- `scale = max(4, ceil(2560 / viewport_width))` — for a 320px viewport, scale = 8x
- Generated size = `in_game_size × scale`, clamped to at least the minimum above
- The post-processing pipeline will resize down to the exact in-game dimensions if needed

**Why**: Godot's import system handles downscaling and mipmaps automatically. Generating at high resolution costs the same (AI models output at fixed resolution anyway) but gives much better quality on 2K/4K displays and allows the game to scale up later without re-generating assets.

#### Anti-Pattern Example

WRONG (writing code to create assets):
```gdscript
# DO NOT DO THIS
var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
img.fill(Color.BLUE)
var tex = ImageTexture.create_from_image(img)
sprite.texture = tex
```

RIGHT (use asset tools, then reference in code):
```
1. Call godot_asset_create_placeholder for each asset
2. Write GDScript that loads via load("res://assets/...")
3. Delegate real generation to asset-generator sub-agent via Task tool
```

### Quick Reference

| Need | Tool / Method |
|------|---------------|
| Game code needs a texture/sprite/model/audio | `godot_asset_create_placeholder` |
| User wants to generate a real image | Task tool → `asset-generator` sub-agent |
| User wants to explore art styles | `godot_art_explore` → `godot_art_confirm` → `godot_style_set` |
| User wants to iterate on an asset | Task tool → `asset-generator` sub-agent (same destination) |
| User wants to upscale/transform | `godot_asset_transform` |

### Core Principles

#### 1. Placeholder-First Development
- **Generate placeholder assets** during code generation to avoid blocking game development
- **Real assets generated on-demand** when the user is ready (right-click → "Generate Asset")
- **Placeholders are playable** - colored rectangles for textures, box meshes for models, silent audio for sounds

#### 2. Asset Types Supported
- **Textures/Sprites**: Character sprites, UI elements, backgrounds, particle effects
- **3D Models/Meshes**: Character models, props, environment objects
- **Audio**: Background music, sound effects, voice acting

#### 3. LLM Responsibilities

When the LLM generates game code requiring assets, it must:

**a) Create placeholder assets with full metadata:**
```gdscript
# Example: Creating a knight sprite placeholder
godot_asset_create_placeholder({
  type: "texture",
  destination: "res://assets/characters/knight/idle.png",
  prompt: "16-bit pixel art knight character idle animation frame, 32x32px, transparent background, medieval armor, holding sword",
  negative_prompt: "blurry, 3D, realistic, photo",
  provider: "replicate",
  parameters: { size: "32x32", style: "pixel_art" }
})

# Example: Creating a 3D model placeholder (GLB format)
godot_asset_create_placeholder({
  type: "model",
  destination: "res://assets/characters/knight/mesh/model.glb",
  prompt: "Low-poly medieval knight character, full armor with sword and shield, stylized game art, clean topology, PBR textures",
  negative_prompt: "high poly, realistic, photogrammetry",
  provider: "meshy",
  model: "meshy-6",
  parameters: { topology: "triangle", target_polycount: 10000 }
})
```

**b) Write high-quality generation prompts:**
- **Be specific**: Include style, dimensions, colors, composition details
- **Include technical requirements**: Resolution, format, transparency, art style
- **Provide context**: What the asset will be used for in the game
- **Use negative prompts**: Specify what to avoid (blur, wrong style, etc.)

**c) Choose appropriate providers and models:**
- **Replicate**: 2D textures, sprites, UI elements, backgrounds (default for texture/sprite types)
- **Meshy**: 3D models, characters, props, environment objects (generates GLB + PBR texture bundle)
- **Suno**: Background music, ambient sounds, sound effects

**d) Structure asset paths logically:**
```
res://assets/
  ├── characters/
  │   ├── knight/
  │   │   ├── idle.png                  # 2D sprite placeholder → AI texture
  │   │   ├── .ai.idle.png/            # Version history for idle.png
  │   │   ├── walk.png
  │   │   └── mesh/                     # 3D model folder
  │   │       ├── model.glb             # GLB placeholder → AI 3D model
  │   │       ├── .ai.model.glb/        # Version history for model.glb
  │   │       ├── base_color.png        # Meshy bundle textures (after generation)
  │   │       ├── metallic.png
  │   │       ├── normal.png
  │   │       └── roughness.png
  ├── enemies/
  ├── ui/
  ├── environment/
  └── audio/
      ├── music/
      └── sfx/
```

**e) Use GLB for 3D models in game code:**
```gdscript
# Load and instantiate a 3D model (works with both placeholder and generated GLB)
var model_scene: PackedScene = load("res://assets/characters/knight/mesh/model.glb")
var model: Node3D = model_scene.instantiate()
add_child(model)
```

### Prompt Writing Guidelines

**Good prompt example:**
```
"Top-down pixel art treasure chest sprite, 32x32 pixels, closed state,
wooden texture with metal bands, glowing golden lock, isometric view,
8-bit style, vibrant colors, transparent background"
```

**Bad prompt example:**
```
"chest"  # Too vague, lacks style, size, and technical details
```

**Prompt template:**
```
"[Art style] [Object/character description] [Specific details],
[Technical specs: size/format], [Composition/angle],
[Style keywords], [Background type]"
```

### Parallel Asset Generation

When creating multiple assets (e.g., building a game scene), generate them **in parallel**:

1. Create all placeholders first with `godot_asset_create_placeholder`
2. Write the game code referencing the placeholder `res://` paths
3. Generate all real assets **IN PARALLEL** using multiple Task tool calls in a single message:

```
# Spawn multiple asset-generator tasks in one message (they run concurrently):
Task(subagent_type="asset-generator", prompt="Generate knight idle sprite at res://assets/characters/knight/idle.png. Prompt: '16-bit pixel art knight...'", description="Knight sprite")
Task(subagent_type="asset-generator", prompt="Generate ground tile at res://assets/environment/ground_tile.png. Prompt: 'Pixel art grass platform tile...'", description="Ground tile")
Task(subagent_type="asset-generator", prompt="Generate sky background at res://assets/environment/sky.png. Prompt: 'Pixel art sky gradient...'", description="Sky background")
```

Each sub-agent autonomously handles: generate → postprocess → visual scoring → retry if needed.
The main assistant continues working on code while assets generate in the background.

### Atlas-Based UI Generation

When creating 3+ UI elements of the same visual family (buttons, icons, panels), generate them as a **single atlas image** instead of individually:

1. Create ONE placeholder for the atlas. Every element MUST specify its pixel dimensions:
```
godot_asset_create_placeholder({
  type: "sprite",
  destination: "res://assets/ui/main_menu/atlas.png",
  prompt: "UI element sheet on transparent background, grid layout. Elements: play button (256x80px), settings button (256x80px), quit button (256x80px), title logo (512x128px). Each element exactly the specified pixel size, 20px gap between elements. Flat design, consistent style",
  usage: { role: "UI atlas sheet", width: 1024, height: 512, transparent_bg: true }
})
```

2. Delegate to asset-generator with atlas instructions:
```
Task(subagent_type="asset-generator",
  prompt="Generate UI atlas at res://assets/ui/main_menu/atlas.png. After generation, call godot_atlas_split with element_labels=['play_btn', 'settings_btn', 'quit_btn', 'title_logo'] and output_dir='res://assets/ui/main_menu/'",
  description="UI atlas: main menu")
```

3. The asset-generator will: generate atlas → split via OpenCV → output individual PNGs or AtlasTexture .tres files

**When to use atlas vs individual generation:**
- **Atlas**: 3+ UI elements sharing the same art style and similar sizes
- **Individual**: elements with very different sizes (e.g., 16x16 icon + 480x270 background), or only 1-2 elements

**Atlas prompt rules:**
- Every element MUST specify its exact pixel dimensions: `"play button (256x80px)"`
- Calculate atlas total size from element sizes + spacing, round up to multiples of 256
- Always specify "transparent background" or "white/black background"
- List all elements explicitly with their sizes in the prompt

### Workflow Integration

1. **Design with TC-EBC**: Output a TC-EBC block for each scene/screen before any code
2. **Create placeholders**: One `godot_asset_create_placeholder` per element from the TC-EBC Elements list
3. **Write game code**: Reference placeholders via `load("res://assets/...")`
4. **Game is immediately playable**: Test logic with placeholder visuals/audio
5. **Generate real assets**: Delegate to `asset-generator` sub-agent via Task tool
6. **Iterate and refine**: Use "Edit Prompt & Regenerate" to improve results

### Example: 2D Platformer Level

```gdscript
# LLM generates level scene with placeholders:
godot_asset_create_placeholder({
  type: "texture",
  destination: "res://assets/environment/ground_tile.png",
  prompt: "Pixel art grass platform tile, 16x16px, top-down view, bright green grass texture, dirt edges, seamless tileable, 8-bit retro game style",
  provider: "replicate"
})

godot_asset_create_placeholder({
  type: "texture",
  destination: "res://assets/characters/player_idle.png",
  prompt: "Pixel art platformer character idle sprite, 32x32px, cute robot character, blue and silver colors, facing right, transparent background, Game Boy aesthetic",
  provider: "replicate"
})

godot_asset_create_placeholder({
  type: "audio_music",
  destination: "res://assets/audio/music/level1_theme.ogg",
  prompt: "Upbeat chiptune background music, 8-bit retro game style, energetic platformer theme, 120 BPM, loopable, NES-era sound",
  provider: "suno"
})
```

### Example: 3D Action Game

```gdscript
# LLM generates 3D game with mesh placeholders:
godot_asset_create_placeholder({
  type: "model",
  destination: "res://assets/characters/warrior/mesh/model.glb",
  prompt: "Stylized low-poly warrior character, medieval fantasy armor, sword in right hand, shield on back, game-ready topology, PBR materials, 8000 triangles",
  negative_prompt: "high poly, realistic, photogrammetry, blurry textures",
  provider: "meshy",
  model: "meshy-6",
  parameters: { topology: "triangle", target_polycount: 8000 }
})

godot_asset_create_placeholder({
  type: "model",
  destination: "res://assets/environment/tree/mesh/model.glb",
  prompt: "Stylized low-poly fantasy tree, broad green canopy, twisted brown trunk, suitable for forest environment, game-ready, 3000 triangles",
  provider: "meshy",
  model: "meshy-6",
  parameters: { topology: "triangle", target_polycount: 3000 }
})

godot_asset_create_placeholder({
  type: "model",
  destination: "res://assets/items/chest/mesh/model.glb",
  prompt: "Low-poly treasure chest, wooden with metal bands, golden lock, closed state, stylized game art, PBR textures, 2000 triangles",
  provider: "meshy",
  model: "meshy-6",
  parameters: { topology: "triangle", target_polycount: 2000 }
})
```

## Event Logging for LLM Verification

All game events must be logged to enable LLM analysis and correctness verification.

### Required Logging Categories

#### 1. Game Progression Events
Scene transitions, level completions, checkpoints, game state changes (start/pause/game over), save/load.

#### 2. User Input Events
Key presses, mouse/touch inputs, controller inputs, UI interactions.

#### 3. Game Output Events
Visual feedback, audio playback, UI updates, physics results, AI/NPC behaviors.

### Log Format

```json
{
    "timestamp": 1234567890,
    "frame": 12345,
    "category": "progression|input|output",
    "event_type": "string",
    "data": {}
}
```

### GameLogger Usage

Use the `GameLogger` autoload singleton:

```gdscript
GameLogger.log_event("progression", {
    "type": "level_complete",
    "level_id": current_level,
    "time_elapsed": level_timer,
    "score": current_score
})
```

Methods: `log_event(category, data)`, `get_recent_events(count)`, `get_events_by_category(category)`, `export_for_llm()`.

### Required Events by Game Type

| Game Type | Required Events |
|-----------|-----------------|
| Platformer | jump, land, collect_item, death, checkpoint |
| Shooter | shoot, hit, reload, enemy_spawn, enemy_death |
| RPG | dialog_start, choice_made, quest_update, level_up |
| Puzzle | move_piece, solve_step, hint_used, puzzle_complete |

### Best Practices

1. Log at decision points, not every frame
2. Include relevant state (positions, scores, health)
3. Use consistent category and event_type naming
4. Use dictionaries with consistent keys per event type

## Visual Effect Development (Test-First)

When developing any feature that includes a visual effect (particles, shaders, animations, UI transitions, post-processing, etc.), **always create a dedicated test scene first** before applying it in-game.

### Workflow

1. **Create a test scene** (`res://test/test_<effect_name>.tscn`) with the visual effect isolated
2. **Present the test scene to the user** for verification — run only the test scene, not the full game
3. **Iterate in the test scene** — make subtle adjustments (colors, timing, intensity, scale, etc.) based on user feedback. Multiple rounds of refinement are expected
4. **Apply to the game** only after the user confirms they are satisfied with the test scene result
5. **Keep the test scene** in the project for future reference and re-tuning

### Rules

- **NEVER** apply a visual effect directly to the game without a test scene first
- The test scene should have a neutral background so the effect is clearly visible
- Include simple controls in the test scene if relevant (e.g., trigger button, slider for intensity)
- If the effect depends on game context (e.g., hit flash on a character), use a minimal mock setup in the test scene

## Feature Testing

### Quick Start Scenes

Quick start scenes (`res://test/qs_<context>.tscn`) skip menus and load directly into a specific game environment with pre-set state. They are organized by game context (battle, shop, inventory, etc.), not per feature.

- Before creating a new qs scene, check if an existing one in `res://test/` already reaches the needed environment — reuse it
- Each qs scene should set up reasonable default state for that context (e.g., player level, gold, items)
- Multiple test cases can share the same qs scene
- Example structure:
```
res://test/
├── qs_battle.tscn         # Skip menus, load battle scene with default player
├── qs_shop.tscn           # Skip menus, load shop with level 5 and 500 gold
├── qs_inventory.tscn      # Skip menus, load inventory with sample items
```

### Test Case Rule

When developing a game feature, ALWAYS create a test case document:

1. Create `res://test/test_<feature_name>.md`
2. Determine which qs scene to use — create one if none fits the needed environment
3. Write step-by-step test procedure with **exact `godot_eval` expressions** — you just wrote the feature code, so use the exact API names, node paths, and method signatures
4. Include expected results with specific verifiable values

### Test Case Template

```markdown
## Test: <feature name>

### Quick Start
- Scene: `res://test/qs_<context>.tscn`
- Description: <what this scene sets up>

### Steps
1. <description of what to do>
   `<exact godot_eval expression>`
2. <description, verify visually>
   `<godot_eval expression>` (screenshot: true)
3. ...

### Expected Results
- <specific verifiable outcome with concrete values>
```

### Example: Speed Boost Skill

```markdown
## Test: Speed Boost Skill

### Quick Start
- Scene: `res://test/qs_battle.tscn`
- Description: Skips main menu, loads battle scene with default player

### Steps
1. Record baseline move speed
   `get_node("/root/Main/Player").move_speed`
2. Equip the speed boost skill
   `get_node("/root/SkillManager").equip_skill("speed_boost")`
3. Check move speed after equip
   `get_node("/root/Main/Player").move_speed` (screenshot: true)
4. Unequip and verify speed resets
   `get_node("/root/SkillManager").unequip_skill("speed_boost")`
   `get_node("/root/Main/Player").move_speed`

### Expected Results
- Baseline move_speed: 200
- After equip: 300 (+50%)
- After unequip: 200 (restored)
```

### When Auto-Test is Enabled

Execute the test steps automatically after development:
1. Run the qs scene via `godot_test_command`
2. Execute each eval step from the test case
3. Screenshot and verify against expected results

### When Auto-Test is NOT Enabled

After completing development, tell the user:
1. What was developed
2. What test cases were created (list the file paths)
3. How to test manually: run the qs scene in the editor, then follow the steps in the test case document — or enable auto-test for automated verification

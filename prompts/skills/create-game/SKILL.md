---
name: create-game
description: Guided game creation workflow — choose gameplay-first or visual-first path to build a complete playable game. Use when user wants to create a new game, says "create a platformer", "make a game", "new game project", or similar.
auto_detect: create.*game|make.*game|build.*game|new.*game|create.*platformer|create.*rpg|create.*shooter|create.*puzzle|create.*adventure|create.*racing|make.*platformer|make.*rpg
---

# Guided Game Creation Workflow

You are now in **Game Creation Mode**. Guide the user through creating a complete, playable game.

Check `docs/creation_progress.md` (if it exists) to see which phases are already done.
Check `docs/worldbuilding.md` and `docs/game_design.md` to see what's already defined.
Skip any phase that is already completed — never repeat work.

Track progress using `godot_creation_progress` after each phase completes.

## HARD RULES

1. **NEVER generate game code/scenes without visual direction first.** Even placeholder assets need a visual style so they match the intended look. Before ANY scaffolding, either `docs/visual_bible.md` must exist OR `godot_style_set` must have been called.
2. **NEVER skip visual direction.** The user CANNOT opt out of visual design — it's mandatory for asset generation.
3. **ALWAYS generate style explorations.** Every path (Template, Quick Start, Reference, Full) MUST call `godot_art_explore` to generate Key Art concept images. Text descriptions are not enough — the user must SEE the style before it's locked. The exploration images populate the **Art Director** panel. Explorations are pure Key Art (gameplay scenes with characters and environment) — they do NOT include UI elements (health bars, menus, HUD). UI mockups are generated separately in Cornerstone Assets.
4. **Always save design artifacts.** Call `godot_game_design`, `godot_worldbuilding`, `godot_style_set` etc. before generating code.
5. **ALWAYS use the `question` tool for user choices.** When presenting options to the user, call the `question` tool — this renders proper clickable buttons in the UI. NEVER present options as plain text numbered lists. You may include a brief intro paragraph before calling the tool.

---

## Entry Point: Detect Intent

Read the user's message and determine which case applies:

### Case A: Reference Game
The user mentioned a specific game: "like Balatro", "similar to Celeste", "clone of Vampire Survivors", etc.

→ Go to [PATH: Reference Game](#path-reference-game)

### Case B: Specific idea but no reference
The user described what they want: "a 2D platformer", "a card game with roguelike elements", etc.

→ Ask the entry question below.

### Case C: Vague request
The user said something generic: "make a game", "create something", "I want to build a game".

→ Ask the entry question below.

### Entry Question (for Case B and C only)

Call the `question` tool with:
- header: "Game Creation"
- question: "How do you want to start building your game?"
- options:
  - { label: "Gameplay First", description: "Build a rough playable prototype first (white-box with colored shapes), then add visuals later" }
  - { label: "Visual First", description: "Define the world and art style first, then build gameplay around the visuals" }
  - { label: "Quick Start", description: "Auto-generate everything — world, visuals, gameplay, code — with minimum questions" }

Wait for the player's choice before proceeding.

- **Gameplay First** → [PATH A: Gameplay First](#path-a-gameplay-first)
- **Visual First** → [PATH B: Visual First](#path-b-visual-first)
- **Quick Start** → [PATH C: Quick Start](#path-c-quick-start)

---

## PATH: Reference Game

The user wants a game like an existing game. This SKIPS gameplay design questions but still REQUIRES visual direction.

### Step 1: Derive Gameplay Design

Based on the reference game, auto-generate the game design:
- Core action (what the player does most in the reference game)
- Action depth (what makes it interesting)
- Fail stakes (what happens on failure)
- Gameplay loop, win condition, progression

Call `godot_game_design` to save results.
Call `godot_creation_progress` with phase="game_design", status="completed"

### Step 2: Visual Direction (MANDATORY)

Call the `question` tool with:
- header: "Visual Style"
- question: "For the visual style, do you want to:"
- options:
  - { label: "Match reference", description: "Match [reference game]'s visual style — I'll describe and lock in a similar look" }
  - { label: "Style template", description: "Pick from proven templates: pixel art, hand-drawn, vector, atmospheric" }
  - { label: "Unique identity", description: "Full worldbuilding + art direction from scratch" }

- **Match reference** → Describe the reference game's visual style (palette, shape language, density, mood). Call `godot_style_set` with those parameters. Then call `godot_art_explore` to generate 4 style explorations matching this description. Let user confirm which one captures the reference feel best. Call `godot_art_confirm` → write `docs/visual_bible.md` → update `godot_style_set` with the chosen image as reference. Call `godot_creation_progress` with phase="art_direction", status="completed"
- **Style template** → Go to [Visual Templates](#visual-templates)
- **Unique identity** → Go to [Full Visual Creation](#full-visual-creation)

### Step 3: Scaffolding

Once BOTH gameplay design and visual direction are locked:
- Generate project structure with GDScript
- Generate placeholder assets using `godot_asset_create_placeholder` with the locked style
- If art direction is locked (`docs/visual_bible.md` exists), use `godot_asset_generate` for real assets
- Player character, one test level, basic game loop, minimal UI
- Configure project settings (window size, input map, default scene)

Call `godot_creation_progress` with phase="scaffolding", status="completed"

→ Proceed to [Asset Generation](#asset-generation)

---

## PATH A: Gameplay First

Focus: get something playable ASAP, visuals come later.

### A1. Core Game Fun

Design the mechanics. Ask ONE question at a time using the `question` tool:

**Q1** — Call `question` with header "Core Action", question "What is the ONE action the player does most?", 3 options.
- Each option should be specific and suggest a feel (not just "jump" but "momentum-based double jump with wall cling")
- Options should be diverse — different verbs, not variations of the same one

**Q2** — Call `question` with header "Action Depth", question "What makes that action INTERESTING every time?", 3 options connected to Q1.
- Risk/reward tradeoffs ("longer charge = more damage but you're vulnerable")
- Combinatorics ("abilities combine — ice + wind = blizzard")
- Environmental interaction ("jump height depends on what surface you're on")

**Q3** — Call `question` with header "Fail Stakes", question "What does the player LOSE on failure?", 3 options.
- Resource loss ("you drop half your gold")
- Progression loss ("the map reshuffles")
- Narrative consequence ("an NPC you rescued gets recaptured")

After all 3 questions:
1. Summarize: core loop, win condition, fail state, progression
2. Call `godot_game_design` tool to save results
3. Call `godot_creation_progress` with phase="game_design", status="completed"

### A2. White-Box Prototype (Scaffolding)

Generate a rough but PLAYABLE prototype:
1. Colored rectangles/circles for characters and environment — NO real art yet
2. Player character with the core action fully implemented
3. One test level demonstrating the core mechanic
4. Basic game manager (start, play, game over states)
5. Minimal UI (health bar if needed, score if needed)

Use GDScript. Follow the coding standards in docs/.
Configure project settings (window size, input map, default scene).

Call `godot_creation_progress` with phase="scaffolding", status="completed"

Say: "White-box prototype is ready! Press Play to test the feel. When you're happy, say 'add visuals' to define the art style."

**Note:** PATH A does NOT proceed to Asset Generation yet — the white-box uses colored shapes intentionally. Asset generation happens later when the user adds visuals (A3).

### A3. Add Visuals (Later)

When the player wants to add visuals to the white-box prototype, call the `question` tool with:
- header: "Visual Style"
- question: "How do you want to define the visual style?"
- options:
  - { label: "Style template", description: "Pick from proven templates: pixel art, hand-drawn, vector, atmospheric" }
  - { label: "Unique identity", description: "Full worldbuilding + art direction from scratch" }

- **Style template** → Go to [Visual Templates](#visual-templates)
- **Unique identity** → Go to [Full Visual Creation](#full-visual-creation)

After visual direction is established:
→ Proceed to [Asset Generation](#asset-generation) to replace white-box placeholders with real assets.

---

## PATH B: Visual First

Focus: define the world and art style, then build gameplay that fits.

### B1. Visual Direction Choice

Call the `question` tool with:
- header: "Visual Style"
- question: "How do you want to define the visual style?"
- options:
  - { label: "Style template", description: "Pick from proven templates: pixel art, hand-drawn, vector, atmospheric and customize" }
  - { label: "Unique identity", description: "Build the world from scratch with worldbuilding + art direction" }

- **Style template** → Go to [Visual Templates](#visual-templates)
- **Unique identity** → Go to [Full Visual Creation](#full-visual-creation)

### B2. Gameplay Design (After Visuals)

Once visuals are defined, design gameplay that fits the world:

If `docs/worldbuilding.md` exists (full visual creation was done):
- Generate gameplay options that are TIED to the world's unique rule/currency
- The core action should feel like it belongs in THIS specific world
- Example: if the world's rule is "wounds are maps", the core action could be "take damage to reveal paths"

If only a visual template was chosen (no worldbuilding):
- Generate gameplay options that complement the art style
- A pixel art roguelike suggests different mechanics than a hand-drawn puzzle game

Then follow the same 3 questions as A1. Core Game Fun.

### B3. Scaffolding

Generate project WITH the defined visual style:
- Generate assets using `godot_asset_create_placeholder` with style hints
- If art direction is locked (`docs/visual_bible.md` exists), use `godot_asset_generate` for real assets
- Player character, one test level, basic game loop, minimal UI
- Configure project settings

Call `godot_creation_progress` with phase="scaffolding", status="completed"

→ Proceed to [Asset Generation](#asset-generation)

---

## PATH C: Quick Start

Maximum speed. The AI handles EVERYTHING — world, visuals, gameplay, code — with minimal user input.

### C1. One Question Only

If the user already described what they want in their original message, skip this question.

Otherwise, call the `question` tool with:
- header: "Game Idea"
- question: "What kind of game do you want? Describe it in one sentence. (Examples: a 2D platformer where gravity flips, a card battler with deck building, a puzzle game about color mixing)"
- options: generate 3 specific game ideas based on any context from the user's message
  - e.g. { label: "Gravity platformer", description: "A 2D platformer where you flip gravity to navigate impossible architecture" }
  - e.g. { label: "Card roguelike", description: "A deck-building card battler with procedural dungeons and synergy combos" }
  - e.g. { label: "Color puzzler", description: "A puzzle game where mixing colors creates new mechanics and paths" }

### C2. Auto-Generate Everything

Based on the user's description, the AI autonomously:

**Gameplay Design (auto-generated, no questions):**
1. Determine the best game type (platformer, top-down, puzzle, roguelike, card game, etc.)
2. Invent ONE unique twist that makes this game stand out
3. Design core loop: action → depth → stakes → progression
4. Call `godot_game_design` with all results
5. Call `godot_creation_progress` with phase="game_design", status="completed"

**Visual Design (auto-generated, ONE confirmation):**
1. Choose a visual style that fits the game type and mood
2. Define color palette (3-4 dominant colors), shape language, visual density
3. Call `godot_style_set` with the chosen parameters
4. Call `godot_art_explore` to generate 4 Key Art style explorations — the user SEES the style before it's locked
5. Tell the user to check the **Art Director** panel to view the generated Key Art. Call the `question` tool: "Which style direction fits best?"
6. Call `godot_art_confirm` with the chosen image → extract visual rules → write `docs/visual_bible.md`
7. Update `godot_style_set` with reference_asset = chosen image
8. Call `godot_creation_progress` with phase="art_direction", status="completed"

**Scaffolding (auto-generated):**
1. Generate full project structure with GDScript
2. Generate placeholder assets using `godot_asset_create_placeholder` with the auto-selected style
3. Player character, one level, basic game loop, minimal UI
4. Configure project settings (window size, input map, default scene)
5. Call `godot_creation_progress` with phase="scaffolding", status="completed"

→ Proceed to [Asset Generation](#asset-generation) (continuous — no pause)

---

## Visual Templates

Pre-defined visual styles for quick adoption. Call the `question` tool with:
- header: "Art Style"
- question: "Pick a visual style (or type your own):"
- options:
  - { label: "Pixel Art Classic", description: "16x16 or 32x32 sprites, limited palette, retro feel" }
  - { label: "Hand-Drawn / Sketch", description: "Loose lines, watercolor textures, organic feel" }
  - { label: "Clean Vector", description: "Sharp edges, flat colors, modern minimal aesthetic" }
  - { label: "Moody Atmospheric", description: "Dark palette, particle effects, dramatic lighting" }

The user can also type a custom style or name a reference game.

After selection:
1. Set up a style profile (palette, shape language, density)
2. Call `godot_style_set` with the template parameters
3. Call `godot_art_explore` with the game description + gameplay mechanics + 4 style variants based on the chosen template — this generates Key Art concept images (no UI) so the user can SEE the style before committing
4. Tell the user to check the **Art Director** panel to view the generated Key Art. Call the `question` tool: "Which style direction feels right?"
5. Call `godot_art_confirm` with the chosen image path — this analyzes the image and extracts color palette, line style, lighting rules
6. Write `docs/visual_bible.md` with the extracted visual rules
7. Update `godot_style_set` with the confirmed parameters (reference_asset = chosen exploration image)
8. Call `godot_creation_progress` with phase="art_direction", status="completed"

**IMPORTANT**: NEVER skip art exploration. The user MUST see generated Key Art images before the style is locked. Text descriptions alone are not sufficient — people need to SEE the style. Always direct users to the **Art Director** panel to view explorations (NOT the FileSystem dock).

**CRITICAL — art_direction format**: When calling `godot_style_set`, the `art_direction` parameter MUST be a short technique-only tag (max 30 words) describing HOW to render — NOT what to render.
- GOOD: `"16-bit pixel art, dark fantasy palette, 1px black outlines, flat 2-tone shading, no anti-aliasing, CRT scanline overlay"`
- BAD: `"Dark moody casino atmosphere, deep emerald green felt table, near-black purple background, cards have cream-white faces..."` (this is scene CONTENT — it will pollute every asset prompt and confuse the image model)
The art_direction gets prepended to EVERY future asset prompt. If it contains scene content, a "UI panel" prompt becomes "casino table scene... UI panel" and the model renders garbage.

---

## Full Visual Creation

Complete worldbuilding + art direction from scratch.

### Step 1: Worldbuilding (3 questions)

Follow the /worldbuilding skill exactly. Use the `question` tool for each question:

1. Call `question` — header "World's Lie", question "What is this world's biggest lie?", 3 options
2. Call `question` — header "Protagonist", question "Why is the protagonist FORCED to act?", 3 options
3. Call `question` — header "World Rule", question "What is this world's most unique rule or currency?", 3 options

RULES FOR OPTIONS:
- Every option must be SPECIFIC, UNPRECEDENTED, SURPRISING
- NEVER use genre labels (dark fantasy, cyberpunk, etc.)
- Each option label = short name, description = one vivid sentence that creates VISUAL IMAGERY

After all 3:
1. Summarize world in 3-4 sentences
2. Extract 5-7 KEY VISUAL OBJECTS (physical things you'd see in concept art)
3. Identify SENSORY SIGNATURE (smell, sound, temperature)
4. List VISUAL TABOOS (what must NEVER appear)
5. Call `godot_worldbuilding` tool
6. Call `godot_creation_progress` with phase="worldbuilding", status="completed"

### Step 2: Art Direction

1. Discuss visual language: color mood, shape language, visual density
2. Call `godot_art_explore` to generate 4 Key Art concept variations (no UI elements)
3. Tell the user to check the **Art Director** panel to view and pick their preferred direction
4. Call `godot_art_confirm` + `godot_style_set`
5. Call `godot_creation_progress` with phase="art_direction", status="completed"

---

## Convergence: Both Paths Complete

Regardless of path taken, the game is ready when BOTH are done:
- **Gameplay**: `docs/game_design.md` exists
- **Visuals**: `docs/visual_bible.md` exists OR `godot_style_set` has been called

If one is missing, prompt the player to complete it:
- Has gameplay but no visuals → "Your prototype plays great! Let's add a visual style now."
- Has visuals but no gameplay → "The world looks amazing! Let's design the core gameplay."

**GATE**: Do NOT run scaffolding until both gameplay and visual direction exist. The only exception is PATH A white-box prototype (colored shapes only).

---

## Asset Generation

This phase runs automatically after scaffolding completes (continuous flow — no pause). It replaces all placeholder assets with real AI-generated art that matches the locked visual style.

**Prerequisites:** Both `docs/game_design.md` and visual direction (`docs/visual_bible.md` or `godot_style_set` called) must exist.

### Step 1: Cornerstone Hero

Generate the hero/player character first — this establishes the visual benchmark for all other assets.

1. Call `godot_cornerstone_generate` with the player character description derived from game design + visual style
2. This generates the hero sprite/art and sets the quality bar for the entire project
3. Verify the result looks correct before proceeding

### Step 2: Batch Asset Generation

Replace ALL placeholder assets with real art in one pass.

1. Call `godot_batch_generate` — this finds all placeholder assets (created by `godot_asset_create_placeholder`) and generates real versions using the locked style
2. Every placeholder carries metadata about what it represents — the batch tool uses this to generate appropriate art
3. This covers: enemies, environment tiles, props, backgrounds, collectibles, and UI elements (health bars, menus, HUD — generated here as Cornerstone Assets, NOT in style explorations)

### Step 3: Filesystem Sync

Make Godot recognize the new files.

1. Call `godot_editor_command` with command `scan_filesystem`
2. This triggers Godot's resource reimport so all new assets are available in the editor

### Step 4: Run and Verify

Launch the game and visually verify the results.

1. Call `godot_editor_command` with command `run` — start the game
2. Wait briefly for the game to load
3. Call `godot_screenshot` — capture the running game
4. Analyze the screenshot for:
   - **Visual coherence** — do all assets look like they belong in the same game?
   - **Readability** — can the player clearly see characters, enemies, platforms, hazards?
   - **Art style consistency** — does everything match the locked visual direction?
   - **Layout issues** — are sprites the right size? Any overlapping or clipping?
5. If issues are found:
   - Call `godot_asset_regenerate` for specific assets that don't fit
   - Adjust sprite sizes or positions in scene files if needed
   - Re-run and re-screenshot to verify fixes
6. Call `godot_editor_command` with command `stop` — stop the running game

### Step 5: Complete

1. Call `godot_creation_progress` with phase="asset_generation", status="completed"
2. Say: "Your game is ready with real art assets! Press Play to try it. You can refine individual assets, add more content with /add-level, or polish the game feel with /polish."

---

## Important Rules

- **Let the player choose their path** — never force a specific order (except visual direction is always mandatory)
- **Always save progress** — call `godot_creation_progress` after each phase
- **Resume from where they left off** — check existing docs before starting any phase
- **Be specific** — every suggestion should be concrete, not generic
- **Keep it playable** — scaffolding must produce something that runs
- **Asset generation is continuous** — after scaffolding, immediately generate real assets (no pause for user input)
- **Verify visually** — always screenshot the running game after asset generation and fix issues
- **Reference games are shortcuts, not skips** — knowing the gameplay doesn't mean skipping visual direction
- **Quick Start = AI decides everything** — the user gets a working game with ONE question max

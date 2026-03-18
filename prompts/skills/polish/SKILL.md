---
name: polish
description: Systematic polish pass — add juice, screen effects, audio, transitions, UI animations, and game feel improvements. Use when user says "polish", "add juice", "make it feel better", "add effects", or similar.
auto_detect: polish.*game|add.*juice|game.*feel|add.*effects|screen.*shake|add.*particles|add.*sound|add.*audio|make.*feel.*better|add.*transitions
---

# Systematic Polish Pass

You are adding polish to an existing game. This skill applies game feel improvements in a structured order.

**Prerequisites:**
- A playable game must exist (scaffolding completed)
- `docs/game_design.md` must exist (need to know core mechanics)

If the game doesn't exist yet: "You need a playable game first. Use /create-game to build one."

---

## Step 1: Assess Current State

Before adding polish, understand what exists:

1. Read `docs/game_design.md` to understand core mechanics
2. Read the main player script and game manager
3. Call `godot_editor_command` with `run`, then `godot_screenshot` to see current state
4. Call `godot_editor_command` with `stop`

Identify which polish categories are most impactful for THIS game.

---

## Step 2: Choose Polish Categories

Call the `question` tool with:
- header: "Polish Areas"
- question: "Which polish areas do you want to add? (select multiple, or type 'all')"
- multiple: true
- options:
  - { label: "Juice", description: "Screen shake, hit freeze, impact particles, squash & stretch" }
  - { label: "Audio", description: "Sound effects for key actions (jump, hit, collect, death, UI)" }
  - { label: "Transitions", description: "Scene transitions, level start/end animations, fade effects" }
  - { label: "UI Animation", description: "Score pop, health bar lerp, button hover, damage flash" }

If the user says "all" or "everything", apply all categories in order.

---

## Category: Juice

Screen effects and impact feedback that make actions feel powerful.

### What to Add:

**Screen Shake:**
- On player damage: short, intense shake (magnitude 4, duration 0.15s)
- On enemy death: brief directional shake toward the kill
- On heavy landing: subtle vertical shake (magnitude 2, duration 0.1s)
- Implementation: Camera2D with shake offset, decay over time

**Hit Freeze (Frame Pause):**
- On dealing damage: 40-60ms engine time scale pause
- On player death: 100ms pause before death animation
- Implementation: `Engine.time_scale = 0.0` with timer to restore

**Impact Particles:**
- On enemy hit: 3-5 small particles in hit direction
- On player death: burst of 10-15 particles outward
- On collecting items: sparkle ring (8 particles in circle)
- On landing: dust puff (3-4 particles sideways)
- Implementation: GPUParticles2D with one-shot emission

**Squash & Stretch:**
- On jump: squash character horizontally on takeoff, stretch vertically in air
- On land: squash vertically on impact, spring back
- On damage: brief horizontal stretch (impact feel)
- Implementation: Tween on `scale` property, spring-like easing

### Implementation:

1. Create a `juice_manager.gd` autoload singleton
2. Add static methods: `screen_shake()`, `hit_freeze()`, `spawn_particles()`
3. Modify player and enemy scripts to call juice methods at appropriate moments
4. Add particle scenes for each effect type

---

## Category: Audio

Sound effects for key game events.

### What to Add:

Identify the game's key actions from `docs/game_design.md` and generate SFX descriptions:

**Core Actions (MUST have sound):**
- Player's core action (jump/shoot/slash/dash) — crisp, satisfying, not annoying on repeat
- Hit/damage dealt — impactful, short, matches art style
- Hit/damage received — distinct from dealing damage, slightly painful
- Death — dramatic but not too long (under 1 second)
- Collect/pickup — bright, rewarding, subtle

**Secondary (nice to have):**
- Menu button hover — soft click or whoosh
- Menu button press — crisp confirmation
- Level complete — celebratory jingle (2-3 seconds)
- Game over — somber but not depressing

### Implementation:

1. Create SFX placeholder descriptions for each sound
2. Add `AudioStreamPlayer` or `AudioStreamPlayer2D` nodes to relevant scenes
3. Create an `audio_manager.gd` autoload for global sounds (UI, music)
4. Set appropriate bus volumes (SFX bus, Music bus, UI bus)
5. Add volume ducking: reduce music volume briefly on impactful SFX

**Note:** Actual audio files need external generation. Set up the audio system with placeholder references that can be swapped in later. Use `godot_asset_generate` if audio generation is available.

---

## Category: Transitions

Scene and state transitions that feel smooth.

### What to Add:

**Scene Transitions:**
- Fade to black (0.3s) → load → fade from black (0.3s)
- Or: circle wipe, diamond dissolve, or slide (match game's visual style)
- Implementation: CanvasLayer with ColorRect + AnimationPlayer

**Level Start:**
- Brief level name display (1.5s) with fade in/out
- Camera zoom from wide to game view (0.5s)
- Player spawn animation (drop in, materialize, etc.)

**Level End:**
- Slow-mo on final enemy/objective (0.3s at 0.3x speed)
- Victory particle burst
- Score tally animation before transition

**Death/Respawn:**
- Brief death animation (0.5s)
- Quick fade or glitch effect
- Respawn at checkpoint with brief invincibility flash

### Implementation:

1. Create `transition_manager.gd` autoload
2. Add `transition_overlay` CanvasLayer scene (highest layer)
3. Implement `fade_to(scene_path)`, `fade_in()`, `fade_out()` methods
4. Add level name display as part of transition sequence
5. Hook up to existing scene change calls

---

## Category: UI Animation

Make UI elements feel alive and responsive.

### What to Add:

**Score/Counter Changes:**
- Number rolls up/down to target value (not instant)
- Brief scale pop on change (1.0 → 1.3 → 1.0 over 0.2s)
- Color flash on significant changes (green for gain, red for loss)

**Health Bar:**
- Smooth lerp to target value (0.3s)
- Delayed damage bar (white bar that catches up to red bar)
- Screen-edge flash on low health (red vignette pulse)

**Button Hover/Press:**
- Scale to 1.1x on hover (0.1s)
- Scale to 0.95x on press (0.05s), back to 1.0 on release
- Subtle color shift on hover

**Damage Flash:**
- Flash player sprite white for 1 frame on hit
- Screen flash (brief white overlay, 50ms)
- Red vignette pulse on damage

### Implementation:

1. Create `ui_effects.gd` with static tween helpers
2. Modify HUD scripts to use animated value changes
3. Add shader for sprite flash (white overlay via modulate)
4. Add vignette overlay to camera/canvas

---

## Category: Game Feel

Subtle mechanics that make controls feel responsive and forgiving.

### What to Add:

**Coyote Time** (platformers):
- Allow jumping for 80-100ms after leaving a platform edge
- Implementation: timer that starts when `is_on_floor()` becomes false

**Input Buffering:**
- Buffer jump/action inputs for 100-150ms before landing
- If player presses jump slightly before touching ground, execute on landing
- Implementation: timer that tracks last input, check on state change

**Camera Smoothing:**
- Camera follows player with slight lag (lerp factor 0.1-0.15)
- Look-ahead: camera shifts slightly in movement direction
- Vertical deadzone: don't follow small vertical movements (reduces seasickness)

**Landing Feedback:**
- Squash sprite briefly on landing (already in Juice category)
- Dust particles (already in Juice category)
- Brief movement speed reduction on heavy landing (10% for 0.1s)

**Acceleration Curves:**
- Don't use instant velocity — ramp up over 0.1s
- Different air vs ground acceleration (air = 60% of ground)
- Snappy direction changes on ground, floaty in air

### Implementation:

1. Modify player movement script with coyote time and input buffering
2. Add camera script with smoothing and look-ahead
3. Tune acceleration curves in exported variables for easy tweaking
4. All values should be `@export` vars for quick iteration

---

## Step 3: Apply and Test

After implementing each category:

1. Call `godot_editor_command` with `run`
2. Call `godot_screenshot` — capture with new polish
3. Analyze: does it feel better? Any over-the-top effects?
4. Call `godot_editor_command` with `stop`

### Common Issues to Watch For:
- **Too much screen shake** — reduce magnitude, it should enhance not distract
- **Hit freeze too long** — should be imperceptible consciously (40-60ms max)
- **Particles too dense** — less is more, particles should accent not obscure
- **Audio clashing** — limit simultaneous SFX, use audio bus limiting
- **Camera too laggy** — increase lerp factor if player loses track of character

Say: "Polish applied! Press Play to feel the difference. Want to /playtest for a thorough review?"

---

## Rules

- **Less is more** — subtle polish > flashy overload
- **Core action gets most polish** — the thing the player does 1000 times must feel amazing
- **Test each category** — don't apply everything blindly, verify after each
- **Keep values tweakable** — use `@export` for all timing/magnitude values
- **Don't break gameplay** — polish must not interfere with mechanics (e.g., screen shake shouldn't affect collision)

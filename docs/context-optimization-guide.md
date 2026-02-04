# Context Optimization Guide for LLM-Assisted Development

This guide provides best practices for writing code that minimizes LLM context usage while maximizing AI understanding and code generation quality.

## Why Context Optimization Matters

LLMs have limited context windows. Efficient code organization means:
- Faster AI responses
- More accurate suggestions
- Lower API costs
- Better code modifications

**Goal:** AI understands your code with minimal tokens loaded.

---

## Core Principles

### 1. Module Interface Files (Minimal Context)

Instead of feeding entire codebases, use interface definitions:

```json
{
  "module_id": "player_movement",
  "name": "Player Movement System",
  "version": "1.0",
  "description": "Handles character movement, jumping, and physics",

  "inputs": {
    "speed": "float (default: 300)",
    "jump_force": "float (default: -400)",
    "gravity": "float (default: 980)"
  },

  "outputs": {
    "velocity": "Vector2",
    "is_grounded": "bool",
    "facing_direction": "int (-1 or 1)"
  },

  "signals": [
    "jumped",
    "landed",
    "direction_changed(new_direction: int)"
  ],

  "methods": [
    "move(direction: Vector2) -> void",
    "jump() -> bool",
    "apply_impulse(force: Vector2) -> void",
    "set_speed(speed: float) -> void"
  ],

  "dependencies": [],

  "example_usage": "var movement = PlayerMovement.new()\nmovement.speed = 400"
}
```

**Result:** ~200 tokens vs ~2000 tokens for full implementation

---

### 2. Hierarchical Documentation

Structure information from general to specific:

```
project/
├── ARCHITECTURE.md          # High-level overview (read first)
│                            # ~500 tokens
├── modules/
│   ├── INDEX.md             # Module summaries (read second)
│   │                        # ~300 tokens
│   └── player/
│       ├── interface.json   # API contract (read if needed)
│       │                    # ~200 tokens
│       └── player_movement.gd  # Full code (read only when modifying)
│                            # ~1500 tokens
```

**Pattern:** Summary → Index → Interface → Implementation

**Loading Strategy:**
1. Always load: ARCHITECTURE.md
2. Usually load: Relevant INDEX.md sections
3. Sometimes load: interface.json for dependencies
4. Rarely load: Full implementation files

---

### 3. Self-Contained Files

Each file should be understandable without reading other files:

```gdscript
# GOOD: Everything needed is in this file
class_name PlayerMovement
extends Node
## Player Movement Module v1.0
##
## Handles character movement including walking, jumping, and collision.
##
## REQUIREMENTS:
##   - Must be child of CharacterBody2D
##   - Requires InputMap actions: move_left, move_right, jump
##
## OUTPUTS:
##   - velocity: Vector2 (current movement velocity)
##   - is_grounded: bool (whether on floor)
##   - facing_direction: int (-1 left, 1 right)
##
## SIGNALS:
##   - jumped: Emitted on jump
##   - landed: Emitted when touching ground
##   - direction_changed(dir: int): Emitted on turn

signal jumped
signal landed
signal direction_changed(dir: int)

const DEFAULT_SPEED := 300.0
const DEFAULT_JUMP_FORCE := -400.0
const DEFAULT_GRAVITY := 980.0

@export var speed: float = DEFAULT_SPEED
@export var jump_force: float = DEFAULT_JUMP_FORCE
@export var gravity: float = DEFAULT_GRAVITY

var velocity: Vector2 = Vector2.ZERO
var is_grounded: bool = false
var facing_direction: int = 1

# ... implementation
```

```gdscript
# BAD: Requires reading multiple files to understand
extends "res://scripts/base/movable.gd"
# Uses constants from res://scripts/globals/physics_constants.gd
# Signals defined in res://scripts/base/character_signals.gd
# See res://docs/movement.md for documentation
```

---

### 4. Standardized File Headers

Every script should start with a quick-reference header:

```gdscript
class_name EnemyAI
extends Node
## Enemy AI Module v1.0
##
## PURPOSE: Controls enemy behavior, targeting, and pathfinding
##
## REQUIREMENTS:
##   - Parent: CharacterBody2D with collision
##   - Groups: Parent must be in "enemy" group
##
## DEPENDENCIES: None
##
## CONFIGURATION:
##   @export detection_range: float = 200.0
##   @export attack_range: float = 50.0
##   @export move_speed: float = 80.0
##
## SIGNALS:
##   - target_acquired(target: Node2D)
##   - target_lost
##   - attack_started
##   - state_changed(new_state: String)
##
## PUBLIC API:
##   set_target(node: Node2D) -> void    # Set pursuit target
##   clear_target() -> void              # Stop pursuing
##   patrol(points: Array[Vector2])      # Start patrol
##   stop() -> void                      # Halt all behavior
##   get_current_state() -> String       # Get AI state
##
## STATES: idle, patrol, chase, attack, flee
```

**Benefit:** LLM understands purpose and API without reading implementation

---

### 5. Chunked Code Sections

Organize code into labeled regions:

```gdscript
class_name PlayerCombat
extends Node

#region SIGNALS
signal attack_started
signal attack_hit(target: Node)
signal attack_ended
signal combo_changed(count: int)
#endregion

#region CONFIGURATION
@export var attack_damage: int = 10
@export var attack_range: float = 50.0
@export var attack_speed: float = 1.0
@export var combo_window: float = 0.8
#endregion

#region STATE
var is_attacking: bool = false
var combo_count: int = 0
var current_target: Node
#endregion

#region PUBLIC API
## Perform an attack in the given direction
func attack(direction: Vector2) -> void:
    pass

## Check if can currently attack
func can_attack() -> bool:
    return not is_attacking
#endregion

#region INTERNAL
func _process_attack_timer(delta: float) -> void:
    pass

func _find_targets_in_range() -> Array:
    pass
#endregion
```

**Benefit:** LLM can request or modify specific regions:
- "Show me the PUBLIC API region"
- "Modify the CONFIGURATION section"

---

### 6. Type Everything

Explicit types provide context without additional files:

```gdscript
# GOOD: Full type information
func calculate_damage(
    base_damage: int,
    multiplier: float,
    is_critical: bool,
    armor_reduction: float
) -> int:
    var damage := base_damage * multiplier
    if is_critical:
        damage *= 2.0
    damage *= (1.0 - armor_reduction)
    return int(max(1, damage))


func get_enemies_in_range(
    position: Vector2,
    radius: float,
    max_count: int = 10
) -> Array[Node2D]:
    var results: Array[Node2D] = []
    # ...
    return results
```

```gdscript
# BAD: No type context - LLM must guess
func calc_dmg(base, mult, crit, armor):
    var dmg = base * mult
    if crit:
        dmg *= 2
    dmg *= (1 - armor)
    return int(max(1, dmg))
```

---

### 7. Inline Examples in Docstrings

```gdscript
## Spawns enemies according to wave configuration.
##
## Example:
##   ```gdscript
##   var wave = {
##       "enemies": [
##           {"type": "basic", "count": 5},
##           {"type": "fast", "count": 3}
##       ],
##       "delay": 2.0,
##       "gold_bonus": 50
##   }
##   wave_manager.start_wave(wave)
##   ```
##
## Wave Format:
##   - enemies: Array of {type: String, count: int}
##   - delay: float (seconds before wave starts)
##   - gold_bonus: int (reward for completing wave)
##
func start_wave(wave_config: Dictionary) -> void:
    pass
```

---

### 8. Predictable Naming Conventions

Consistent patterns reduce guesswork:

```gdscript
# SIGNALS: past tense or noun
signal enemy_died
signal wave_completed
signal item_collected
signal health_changed(current: int, maximum: int)

# METHODS: verb phrase
func spawn_enemy(type: String) -> Node2D
func start_wave(config: Dictionary) -> void
func collect_item(item: Node) -> bool
func take_damage(amount: int) -> void

# BOOLEAN STATE: is_/has_/can_ prefix
var is_alive: bool = true
var is_attacking: bool = false
var has_weapon: bool = false
var has_double_jump: bool = true
var can_move: bool = true
var can_attack: bool = true

# NUMERIC STATE: descriptive noun
var health: int = 100
var max_health: int = 100
var speed: float = 200.0
var damage: int = 10

# PRIVATE: underscore prefix
var _internal_timer: float = 0.0
var _cached_targets: Array = []
func _calculate_path() -> Array[Vector2]
func _update_state_machine(delta: float) -> void

# CONSTANTS: UPPER_SNAKE_CASE
const MAX_ENEMIES := 50
const DEFAULT_SPEED := 100.0
const PLAYER_GROUP := "player"
```

---

### 9. Configuration as Data

Separate data from logic using JSON/Resources:

```json
// data/enemies.json
{
  "basic": {
    "health": 50,
    "speed": 40,
    "damage": 5,
    "gold_value": 10
  },
  "fast": {
    "health": 30,
    "speed": 80,
    "damage": 3,
    "gold_value": 15
  },
  "tank": {
    "health": 200,
    "speed": 20,
    "damage": 15,
    "gold_value": 30
  }
}
```

```gdscript
# Load and use config
var enemy_configs: Dictionary

func _ready() -> void:
    var file = FileAccess.open("res://data/enemies.json", FileAccess.READ)
    enemy_configs = JSON.parse_string(file.get_as_text())

func spawn_enemy(type: String) -> Node2D:
    var config = enemy_configs.get(type, enemy_configs["basic"])
    var enemy = enemy_scene.instantiate()
    enemy.health = config["health"]
    enemy.speed = config["speed"]
    enemy.damage = config["damage"]
    return enemy
```

**Benefits:**
- LLM can modify data without touching code
- Balance changes don't require code review
- Clear separation of concerns

---

### 10. Explicit Dependencies

Make all dependencies visible at the top of the file:

```gdscript
# GOOD: Dependencies explicit and injectable
class_name CombatSystem
extends Node
## Combat System - Handles damage calculation and combat events.
##
## DEPENDENCIES (injected via setup):
##   - stats: PlayerStats (for damage calculation)
##   - inventory: PlayerInventory (for weapon data)
##   - audio: AudioManager (for combat sounds)

var _stats: PlayerStats
var _inventory: PlayerInventory
var _audio: AudioManager

func setup(
    stats: PlayerStats,
    inventory: PlayerInventory,
    audio: AudioManager = null
) -> void:
    _stats = stats
    _inventory = inventory
    _audio = audio


func calculate_damage() -> int:
    var base = _stats.get_attack()
    var weapon = _inventory.get_equipped("weapon")
    return base + weapon.get("damage", 0)
```

```gdscript
# BAD: Hidden global dependencies
func calculate_damage() -> int:
    # Where are these defined? What's their interface?
    var base = GameManager.player.stats.attack
    var weapon = InventorySystem.get_weapon()
    return base + weapon.damage
```

---

## Context Budget Strategy

Allocate context wisely based on task:

| Priority | Content | Typical Tokens | When to Load |
|----------|---------|----------------|--------------|
| **Critical** | File being modified | 500-2000 | Always |
| **High** | Interface files of direct dependencies | ~200 each | Usually |
| **Medium** | ARCHITECTURE.md / system overview | ~500 | For new features |
| **Low** | Related implementations | ~1000 each | When debugging |
| **Minimal** | Full codebase dump | 10000+ | Almost never |

### Example Context Loading

**Task:** "Add double jump to player movement"

```
Load (in order):
1. modules/player/player_movement/player_movement.gd  [MODIFY]  ~1500 tokens
2. modules/player/player_movement/interface.json     [UPDATE]  ~200 tokens

Total: ~1700 tokens
```

**Task:** "Player takes damage when hitting enemy"

```
Load (in order):
1. modules/player/player_stats/interface.json        [REFERENCE] ~200 tokens
2. modules/game_logic/enemy_ai/interface.json        [REFERENCE] ~200 tokens
3. scripts/player.gd                                 [MODIFY]    ~800 tokens

Total: ~1200 tokens
```

---

## File Size Guidelines

| File Type | Target Lines | Target Tokens | Reason |
|-----------|--------------|---------------|--------|
| Module script | < 200 | < 1500 | Fits in context with room for others |
| Interface JSON | < 50 | < 300 | Quick reference |
| Config JSON | < 100 | < 500 | Data only |
| System script | < 300 | < 2500 | Manageable complexity |
| Scene files | N/A | Don't read | Use scene tree inspection |

**If a file exceeds limits:** Split into smaller, focused modules.

---

## Anti-Patterns to Avoid

### 1. God Classes
```gdscript
# BAD: One class does everything
class_name Player  # 2000+ lines
# Movement, combat, inventory, stats, UI, saves...
```

**Fix:** Split into PlayerMovement, PlayerCombat, PlayerInventory, etc.

### 2. Deep Inheritance
```gdscript
# BAD: Must read 5 files to understand
class_name Player
extends Character  # extends Entity extends GameObject extends Node
```

**Fix:** Use composition with modules.

### 3. Scattered Constants
```gdscript
# BAD: Constants in multiple files
# physics.gd: GRAVITY = 980
# player.gd: GRAVITY = 980  # duplicated!
# enemy.gd: const G = 980   # different name!
```

**Fix:** Single source of truth, or define per-file with clear defaults.

### 4. Implicit State
```gdscript
# BAD: State hidden in signals/globals
func attack():
    EventBus.emit("attack_started")  # Who listens? What happens?
```

**Fix:** Explicit dependencies and direct calls.

---

## Quick Reference Checklist

When writing code for AI-assisted development:

- [ ] File has descriptive header with PURPOSE, DEPENDENCIES, API
- [ ] All functions have type hints (parameters and return)
- [ ] Public API is documented with examples
- [ ] Code is organized into labeled regions
- [ ] File is under 200 lines (or split if larger)
- [ ] Dependencies are explicit (not global)
- [ ] Configuration is in data files, not hardcoded
- [ ] Naming follows consistent conventions
- [ ] interface.json exists for reusable modules

---

## Summary: The Golden Rules

| Rule | Principle | Benefit |
|------|-----------|---------|
| 1 | Interface > Implementation | Describe what, not how |
| 2 | Self-contained > Distributed | One file = one concept |
| 3 | Typed > Untyped | Explicit beats implicit |
| 4 | Data > Code | JSON configs over hardcoded values |
| 5 | Flat > Deep | Avoid inheritance chains |
| 6 | Small > Large | 200 lines max per module |
| 7 | Consistent > Clever | Predictable patterns always |
| 8 | Explicit > Implicit | No hidden dependencies |
| 9 | Headers > Comments | Front-load understanding |
| 10 | Examples > Explanations | Show, don't just tell |

---

## Further Reading

- [Creating Game Modules](contributing/modules.md)
- [Creating Game Templates](contributing/templates.md)
- [GDScript Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)

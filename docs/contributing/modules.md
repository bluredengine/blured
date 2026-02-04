# Creating Game Modules

Game modules are reusable components that provide specific functionality for games. They are designed to be:
- **Self-contained**: Work independently without external dependencies
- **Configurable**: Expose settings via exports
- **LLM-friendly**: Include interface.json for AI understanding

## Module Structure

```
modules/
└── your_category/
    └── your_module/
        ├── interface.json       # Required: LLM-readable interface
        ├── your_module.gd       # Main script
        └── README.md            # Optional: Documentation
```

## Creating a Module

### Step 1: Create the Directory

```bash
mkdir -p modules/player/dash_ability
```

### Step 2: Create interface.json

The interface file describes your module for the AI system:

```json
{
  "module_id": "dash_ability",
  "name": "Dash Ability",
  "version": "1.0",
  "description": "Adds a dash ability to the player character",

  "inputs": {
    "dash_action": {
      "type": "String",
      "description": "Input action name for dash (default: 'dash')"
    },
    "config": {
      "type": "DashConfig",
      "properties": {
        "dash_speed": "float (default: 500)",
        "dash_duration": "float (default: 0.2)",
        "cooldown": "float (default: 1.0)"
      }
    }
  },

  "outputs": {
    "is_dashing": {
      "type": "bool",
      "description": "Whether player is currently dashing"
    },
    "can_dash": {
      "type": "bool",
      "description": "Whether dash is available (not on cooldown)"
    }
  },

  "signals": {
    "dash_started": "Emitted when dash begins",
    "dash_ended": "Emitted when dash completes",
    "cooldown_finished": "Emitted when dash becomes available"
  },

  "dependencies": ["player_movement"],

  "files": [
    "res://modules/player/dash_ability/dash_ability.gd"
  ],

  "example_usage": "var dash = DashAbility.new()\ndash.dash_speed = 600"
}
```

### Step 3: Create the GDScript

```gdscript
class_name DashAbility
extends Node
## Dash Ability Module - Adds a quick dash movement to the player.

signal dash_started
signal dash_ended
signal cooldown_finished

## Configuration
@export var dash_action: String = "dash"
@export var dash_speed: float = 500.0
@export var dash_duration: float = 0.2
@export var cooldown: float = 1.0

## State
var is_dashing: bool = false
var can_dash: bool = true

## Internal
var _dash_timer: float = 0.0
var _cooldown_timer: float = 0.0
var _dash_direction: Vector2 = Vector2.ZERO
var _character: CharacterBody2D


func _ready() -> void:
    _character = get_parent() as CharacterBody2D


func _physics_process(delta: float) -> void:
    _update_timers(delta)
    _handle_input()
    _apply_dash()


func _update_timers(delta: float) -> void:
    if is_dashing:
        _dash_timer -= delta
        if _dash_timer <= 0:
            _end_dash()

    if not can_dash:
        _cooldown_timer -= delta
        if _cooldown_timer <= 0:
            can_dash = true
            cooldown_finished.emit()


func _handle_input() -> void:
    if Input.is_action_just_pressed(dash_action) and can_dash:
        _start_dash()


func _start_dash() -> void:
    # Get dash direction from input or facing
    _dash_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    if _dash_direction == Vector2.ZERO:
        _dash_direction = Vector2.RIGHT  # Default direction

    is_dashing = true
    can_dash = false
    _dash_timer = dash_duration
    _cooldown_timer = cooldown
    dash_started.emit()


func _end_dash() -> void:
    is_dashing = false
    dash_ended.emit()


func _apply_dash() -> void:
    if is_dashing and _character:
        _character.velocity = _dash_direction * dash_speed


## Public API

func perform_dash(direction: Vector2 = Vector2.ZERO) -> bool:
    if not can_dash:
        return false

    if direction != Vector2.ZERO:
        _dash_direction = direction.normalized()

    _start_dash()
    return true


func get_cooldown_progress() -> float:
    if can_dash:
        return 1.0
    return 1.0 - (_cooldown_timer / cooldown)
```

## Best Practices

### 1. Use Signals for Communication

```gdscript
# Good: Use signals
signal ability_activated

# Bad: Direct coupling
# other_node.on_ability_activated()
```

### 2. Make Everything Configurable

```gdscript
# Good: Exports for configuration
@export var speed: float = 100.0
@export var damage: int = 10

# Bad: Hardcoded values
var speed = 100.0  # Can't be changed in editor
```

### 3. Validate Parent/Dependencies

```gdscript
func _ready() -> void:
    _character = get_parent() as CharacterBody2D
    if not _character:
        push_error("DashAbility must be child of CharacterBody2D")
```

### 4. Provide Public API

```gdscript
## Public method with clear documentation
func perform_dash(direction: Vector2) -> bool:
    # ...
```

### 5. Handle Edge Cases

```gdscript
func take_damage(amount: int) -> void:
    if not is_alive:
        return  # Already dead
    # ...
```

## Submission Checklist

Before submitting a module PR:

- [ ] `interface.json` is complete and accurate
- [ ] Script follows GDScript style guide
- [ ] All exports have meaningful defaults
- [ ] Signals documented in interface.json
- [ ] Example usage provided
- [ ] Works with Godot 4.x
- [ ] No external dependencies (or listed in dependencies)
- [ ] MIT licensed

## Categories

Place your module in the appropriate category:

| Category | Description | Examples |
|----------|-------------|----------|
| `core/` | Essential systems | game_manager, save_system |
| `player/` | Player functionality | movement, combat, inventory |
| `world/` | World/level systems | spawning, dialogue, interaction |
| `game_logic/` | Game mechanics | AI, economy, achievements |

## Testing Your Module

1. Create a test scene
2. Add a parent node (e.g., CharacterBody2D)
3. Add your module as a child
4. Configure exports in inspector
5. Run and verify functionality

## Example Modules

Study existing modules for patterns:
- `modules/player/player_movement/` - Movement with coyote time
- `modules/world/spawn_system/` - Wave-based spawning
- `modules/core/save_system/` - Save/load functionality

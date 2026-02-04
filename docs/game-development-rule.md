# Makabaka Engine - Game Development Rules

## Event Logging for LLM Verification

All game events must be logged to enable LLM analysis and correctness verification.

### Required Logging Categories

#### 1. Game Progression Events
- Scene transitions
- Level completions
- Checkpoint reached
- Game state changes (start, pause, resume, game over)
- Save/load operations

```gdscript
# Example
func _on_level_completed():
    GameLogger.log_event("progression", {
        "type": "level_complete",
        "level_id": current_level,
        "time_elapsed": level_timer,
        "score": current_score
    })
```

#### 2. User Input Events
- Key presses and releases
- Mouse/touch inputs
- Controller inputs
- UI interactions
- Command inputs

```gdscript
# Example
func _input(event: InputEvent) -> void:
    if event.is_action_pressed("jump"):
        GameLogger.log_event("input", {
            "action": "jump",
            "timestamp": Time.get_ticks_msec(),
            "player_position": player.global_position
        })
```

#### 3. Game Output Events
- Visual feedback (animations, effects)
- Audio playback
- UI updates
- Physics results (collisions, movements)
- AI/NPC behaviors

```gdscript
# Example
func apply_damage(amount: int, source: String) -> void:
    GameLogger.log_event("output", {
        "type": "damage_applied",
        "amount": amount,
        "source": source,
        "remaining_health": health,
        "target": name
    })
```

### Log Format

All logs should follow this JSON structure:

```json
{
    "timestamp": 1234567890,
    "frame": 12345,
    "category": "progression|input|output",
    "event_type": "string",
    "data": {
        // Event-specific data
    }
}
```

### GameLogger Implementation

Create an autoload singleton `GameLogger` that handles all logging:

```gdscript
# res://autoload/game_logger.gd
extends Node

signal event_logged(event: Dictionary)

var log_file: FileAccess
var log_buffer: Array[Dictionary] = []
var log_to_file: bool = true
var log_to_console: bool = true

func _ready() -> void:
    if log_to_file:
        var path = "user://logs/game_%s.jsonl" % Time.get_datetime_string_from_system()
        DirAccess.make_dir_recursive_absolute(path.get_base_dir())
        log_file = FileAccess.open(path, FileAccess.WRITE)

func log_event(category: String, data: Dictionary) -> void:
    var event = {
        "timestamp": Time.get_unix_time_from_system(),
        "frame": Engine.get_process_frames(),
        "category": category,
        "data": data
    }

    log_buffer.append(event)
    event_logged.emit(event)

    if log_to_console:
        print("[%s] %s" % [category.to_upper(), JSON.stringify(data)])

    if log_to_file and log_file:
        log_file.store_line(JSON.stringify(event))

func get_recent_events(count: int = 100) -> Array[Dictionary]:
    return log_buffer.slice(-count)

func get_events_by_category(category: String) -> Array[Dictionary]:
    return log_buffer.filter(func(e): return e.category == category)

func export_for_llm() -> String:
    return JSON.stringify(log_buffer, "\t")
```

### LLM Analysis Integration

The logged events can be sent to the AI for analysis:

```gdscript
# In the AI bridge
func request_llm_analysis() -> void:
    var recent_events = GameLogger.get_recent_events(50)
    var context = {
        "events": recent_events,
        "current_state": get_game_state()
    }
    bridge.send_prompt("Analyze these game events for correctness", context)
```

### Best Practices

1. **Log at decision points** - Log before and after important game logic
2. **Include context** - Always include relevant state (positions, scores, etc.)
3. **Use consistent naming** - Follow the category and event_type conventions
4. **Don't over-log** - Avoid logging every frame; log meaningful events
5. **Structured data** - Use dictionaries with consistent keys for each event type

### Required Events by Game Type

| Game Type | Required Events |
|-----------|-----------------|
| Platformer | jump, land, collect_item, death, checkpoint |
| Shooter | shoot, hit, reload, enemy_spawn, enemy_death |
| RPG | dialog_start, choice_made, quest_update, level_up |
| Puzzle | move_piece, solve_step, hint_used, puzzle_complete |

### Verification Queries

The LLM can be asked to verify:

- "Did the player's score increase correctly after collecting the coin?"
- "Was the enemy AI behaving correctly during the combat sequence?"
- "Are there any impossible state transitions in the recent events?"
- "Did the physics respond correctly to the player's inputs?"

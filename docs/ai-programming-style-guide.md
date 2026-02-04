# AI-Oriented Programming Style Guide

This guide defines coding patterns that maximize AI assistant effectiveness. Following these rules results in code that AI can understand quickly, modify accurately, and extend reliably.

---

## Philosophy

**Traditional code optimization:** Minimize CPU cycles and memory usage.

**AI-oriented code optimization:** Minimize cognitive load and context requirements.

The goal is code that an AI can understand and modify correctly with minimal context, reducing errors and improving suggestion quality.

---

## Core Principles

### 1. Explicit Over Implicit

Always prefer explicit declarations over implicit behavior.

```gdscript
# GOOD: Explicit types, values, and intent
var player_health: int = 100
var max_player_health: int = 100
var is_player_alive: bool = true
var movement_speed: float = 200.0

func calculate_damage(base: int, multiplier: float) -> int:
    return int(base * multiplier)
```

```gdscript
# BAD: Implicit types, unclear names
var h = 100
var m = 100
var alive = true
var spd = 200

func calc(b, m):
    return b * m
```

**Why:** AI doesn't need to infer types or guess meanings.

---

### 2. Flat Over Nested

Prefer early returns and flat structures over deep nesting.

```gdscript
# GOOD: Flat with early returns
func process_enemy(enemy: Node2D) -> void:
    if not is_instance_valid(enemy):
        return

    if not enemy.is_alive:
        return

    if not enemy.can_attack:
        return

    if enemy.target == null:
        return

    enemy.perform_attack()


func get_damage_multiplier(attacker: Node, defender: Node) -> float:
    # Guard clauses first
    if attacker == null:
        return 0.0
    if defender == null:
        return 1.0
    if defender.is_invincible:
        return 0.0

    # Main logic flat
    var base := 1.0

    if attacker.has_buff("strength"):
        base *= 1.5

    if defender.has_debuff("vulnerable"):
        base *= 2.0

    return base
```

```gdscript
# BAD: Deep nesting
func process_enemy(enemy: Node2D) -> void:
    if is_instance_valid(enemy):
        if enemy.is_alive:
            if enemy.can_attack:
                if enemy.target != null:
                    enemy.perform_attack()
```

**Why:** Flat code is easier to modify at any point without affecting other branches.

---

### 3. Small, Focused Functions

Each function should do one thing well.

```gdscript
# GOOD: Single responsibility per function
func calculate_base_damage(attacker: Node) -> int:
    return attacker.stats.attack + attacker.weapon.damage


func apply_critical_multiplier(damage: int, is_crit: bool) -> int:
    return damage * 2 if is_crit else damage


func apply_armor_reduction(damage: int, armor: int) -> int:
    var reduction := armor * 0.5
    return int(max(1, damage - reduction))


func deal_damage(attacker: Node, defender: Node, is_crit: bool) -> int:
    var damage := calculate_base_damage(attacker)
    damage = apply_critical_multiplier(damage, is_crit)
    damage = apply_armor_reduction(damage, defender.stats.armor)
    defender.take_damage(damage)
    return damage
```

```gdscript
# BAD: Function does too many things
func attack_enemy(attacker, defender, is_crit):
    var dmg = attacker.stats.attack + attacker.weapon.damage
    if is_crit:
        dmg *= 2
    var armor_reduce = defender.stats.armor * 0.5
    dmg = max(1, dmg - armor_reduce)
    defender.health -= dmg
    if defender.health <= 0:
        defender.die()
        attacker.add_xp(defender.xp_value)
        spawn_loot(defender.position)
        play_sound("enemy_death")
        emit_signal("enemy_killed", defender)
    else:
        play_sound("hit")
        defender.flash_red()
    return dmg
```

**Why:** Small functions can be individually understood, tested, and modified.

---

### 4. Descriptive Names Over Comments

Names should be self-documenting. Comments explain "why," not "what."

```gdscript
# GOOD: Self-documenting names
const COYOTE_TIME_SECONDS := 0.1
const JUMP_BUFFER_SECONDS := 0.15

var remaining_coyote_time: float = 0.0
var remaining_jump_buffer: float = 0.0

func is_jump_available() -> bool:
    var on_ground := is_on_floor()
    var in_coyote_time := remaining_coyote_time > 0.0
    var has_jumps_remaining := current_jump_count < max_jump_count

    return on_ground or in_coyote_time or has_jumps_remaining


func should_execute_buffered_jump() -> bool:
    return remaining_jump_buffer > 0.0 and is_jump_available()
```

```gdscript
# BAD: Needs comments to understand
const CT = 0.1  # coyote time
const JB = 0.15  # jump buffer

var ct_left = 0.0  # remaining coyote time
var jb_left = 0.0  # remaining jump buffer

# Check if player can jump
func can_j():
    # on ground, coyote, or double jump
    return is_on_floor() or ct_left > 0 or jc < mj
```

**Why:** AI reads names directly; good names reduce need for context.

---

### 5. Consistent Patterns

Use the same patterns throughout the codebase.

```gdscript
# GOOD: Consistent signal patterns
signal health_changed(current_value: int, max_value: int)
signal stamina_changed(current_value: int, max_value: int)
signal mana_changed(current_value: int, max_value: int)
signal experience_changed(current_value: int, required_value: int)

# Consistent state change pattern
func set_health(value: int) -> void:
    var old_health := health
    health = clampi(value, 0, max_health)
    if health != old_health:
        health_changed.emit(health, max_health)
    if health <= 0 and old_health > 0:
        died.emit()


func set_stamina(value: int) -> void:
    var old_stamina := stamina
    stamina = clampi(value, 0, max_stamina)
    if stamina != old_stamina:
        stamina_changed.emit(stamina, max_stamina)
```

```gdscript
# BAD: Inconsistent patterns
signal hp_updated(hp)
signal on_stamina_change(val, maximum)
signal mana(m)
signal xp_gained

func change_hp(v):
    health = v
    emit_signal("hp_updated", health)

func updateStamina(newVal, maxVal):
    stamina = newVal
    on_stamina_change.emit(stamina, max_stamina)
```

**Why:** AI learns patterns; consistency means accurate predictions.

---

### 6. Composition Over Inheritance

Build complex behavior from simple, composable parts.

```gdscript
# GOOD: Composition with modules
class_name Player
extends CharacterBody2D

@onready var movement := $MovementModule as PlayerMovement
@onready var combat := $CombatModule as PlayerCombat
@onready var stats := $StatsModule as PlayerStats
@onready var inventory := $InventoryModule as PlayerInventory

func _ready() -> void:
    # Connect modules
    combat.damage_dealt.connect(_on_damage_dealt)
    stats.died.connect(_on_player_died)

    # Configure modules
    movement.speed = 300.0
    stats.max_health = 100

func _on_damage_dealt(amount: int, target: Node) -> void:
    if target.has_method("drop_loot"):
        inventory.add_items(target.drop_loot())
```

```gdscript
# BAD: Deep inheritance
class_name Player
extends Character  # extends Entity extends GameObject extends Node2D

# Must read 4 files to understand Player
# Modifying one class risks breaking all children
# Hard to reuse just movement or just combat
```

**Why:** Each module is self-contained and can be understood/modified independently.

---

### 7. Fail Loudly with Clear Errors

When something goes wrong, make it obvious.

```gdscript
# GOOD: Clear error messages with context
func set_target(node: Node2D) -> void:
    if node == null:
        push_error("set_target() called with null node")
        return

    if not node.is_in_group("enemy"):
        push_error("set_target() requires node in 'enemy' group, got: %s (groups: %s)" % [
            node.name,
            node.get_groups()
        ])
        return

    if not node.has_method("take_damage"):
        push_error("set_target() requires node with take_damage() method, got: %s" % node.name)
        return

    current_target = node
    target_acquired.emit(node)


func load_config(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        push_error("Config file not found: %s" % path)
        return {}

    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_error("Failed to open config file: %s (error: %s)" % [path, FileAccess.get_open_error()])
        return {}

    var json := JSON.new()
    var error := json.parse(file.get_as_text())
    if error != OK:
        push_error("Failed to parse config JSON at %s line %d: %s" % [
            path,
            json.get_error_line(),
            json.get_error_message()
        ])
        return {}

    return json.get_data()
```

```gdscript
# BAD: Silent failures
func set_target(node):
    if node and node.is_in_group("enemy"):
        current_target = node

func load_config(path):
    var file = FileAccess.open(path, FileAccess.READ)
    if file:
        return JSON.parse_string(file.get_as_text())
    return {}
```

**Why:** AI can diagnose and fix issues when errors are descriptive.

---

### 8. Document the "Why", Not the "What"

Code shows what happens; comments explain why.

```gdscript
# GOOD: Comments explain reasoning

# Use coyote time to make platforming more forgiving - players often
# press jump slightly after leaving a ledge
const COYOTE_TIME := 0.1

# Buffer jump inputs to handle cases where player presses jump
# slightly before landing
const JUMP_BUFFER := 0.15

# Damage floors at 1 to prevent "zero damage" hits that feel broken
func calculate_final_damage(raw_damage: int, armor: int) -> int:
    return max(1, raw_damage - armor)

# Process movement before combat so position is updated when
# calculating attack ranges and hitboxes
func _physics_process(delta: float) -> void:
    _process_movement(delta)
    _process_combat(delta)
```

```gdscript
# BAD: Comments restate code

# Set coyote time to 0.1
const COYOTE_TIME := 0.1

# Set jump buffer to 0.15
const JUMP_BUFFER := 0.15

# Return max of 1 or raw_damage minus armor
func calculate_final_damage(raw_damage: int, armor: int) -> int:
    return max(1, raw_damage - armor)

# Process movement then combat
func _physics_process(delta: float) -> void:
    _process_movement(delta)
    _process_combat(delta)
```

**Why:** "Why" comments preserve intent when AI refactors code.

---

### 9. Avoid Magic Numbers and Strings

Use named constants for all literal values.

```gdscript
# GOOD: Named constants
const MAX_HEALTH := 100
const STARTING_GOLD := 50
const WALK_SPEED := 200.0
const RUN_SPEED := 400.0
const JUMP_FORCE := -450.0
const GRAVITY := 980.0

const GROUP_PLAYER := "player"
const GROUP_ENEMY := "enemy"
const GROUP_INTERACTABLE := "interactable"

const ACTION_JUMP := "jump"
const ACTION_ATTACK := "attack"

func _ready() -> void:
    health = MAX_HEALTH
    gold = STARTING_GOLD
    add_to_group(GROUP_PLAYER)


func _physics_process(delta: float) -> void:
    if Input.is_action_just_pressed(ACTION_JUMP):
        velocity.y = JUMP_FORCE
```

```gdscript
# BAD: Magic numbers everywhere
func _ready():
    health = 100
    gold = 50
    add_to_group("player")

func _physics_process(delta):
    if Input.is_action_just_pressed("jump"):
        velocity.y = -450
```

**Why:** AI can understand and modify named values; magic numbers require guessing.

---

### 10. Prefer Pure Functions

Functions that don't modify state are easier to understand and test.

```gdscript
# GOOD: Pure functions where possible
func calculate_damage(base: int, multiplier: float, is_crit: bool) -> int:
    var damage := int(base * multiplier)
    if is_crit:
        damage *= 2
    return damage


func get_movement_direction() -> Vector2:
    return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func is_in_attack_range(attacker_pos: Vector2, target_pos: Vector2, range: float) -> bool:
    return attacker_pos.distance_to(target_pos) <= range


func get_closest_enemy(from_position: Vector2, enemies: Array[Node2D]) -> Node2D:
    var closest: Node2D = null
    var closest_distance := INF

    for enemy in enemies:
        var distance := from_position.distance_to(enemy.global_position)
        if distance < closest_distance:
            closest_distance = distance
            closest = enemy

    return closest
```

```gdscript
# BAD: Functions with hidden side effects
func calculate_damage(base, mult, crit):
    var dmg = base * mult
    if crit:
        dmg *= 2
        combo_count += 1  # Side effect!
        _play_crit_sound()  # Side effect!
    last_damage = dmg  # Side effect!
    return dmg
```

**Why:** Pure functions can be understood in isolation.

---

## Naming Conventions

### Signals
```gdscript
# Past tense for events that occurred
signal enemy_died
signal wave_completed
signal item_collected

# Present tense + "_changed" for state changes
signal health_changed(current: int, maximum: int)
signal position_changed(new_position: Vector2)

# "_requested" for actions that may be denied
signal jump_requested
signal attack_requested(target: Node)
```

### Methods
```gdscript
# Verb phrases for actions
func spawn_enemy(type: String) -> Node2D
func take_damage(amount: int) -> void
func collect_item(item: Node) -> bool
func start_wave(config: Dictionary) -> void

# "get_" for computed values
func get_damage_multiplier() -> float
func get_enemies_in_range() -> Array[Node2D]

# "is_/has_/can_" for boolean queries
func is_alive() -> bool
func has_weapon() -> bool
func can_attack() -> bool

# "set_" for setters with side effects
func set_health(value: int) -> void
func set_target(node: Node2D) -> void

# "_on_" for signal callbacks
func _on_enemy_died(enemy: Node) -> void
func _on_timer_timeout() -> void
```

### Variables
```gdscript
# Boolean state: is_/has_/can_ prefix
var is_alive: bool = true
var is_attacking: bool = false
var has_double_jump: bool = false
var can_move: bool = true

# Numeric values: descriptive nouns
var health: int = 100
var max_health: int = 100
var speed: float = 200.0
var damage: int = 10
var gold: int = 0

# Collections: plural nouns
var enemies: Array[Node2D] = []
var inventory_items: Array[Dictionary] = []
var active_buffs: Dictionary = {}

# Private: underscore prefix
var _internal_timer: float = 0.0
var _cached_path: Array[Vector2] = []
```

### Constants
```gdscript
# UPPER_SNAKE_CASE
const MAX_ENEMIES := 50
const DEFAULT_SPEED := 100.0
const PLAYER_GROUP := "player"
const SAVE_PATH := "user://save.dat"
```

### Enums
```gdscript
# PascalCase for enum name, UPPER_SNAKE for values
enum State {
    IDLE,
    WALKING,
    RUNNING,
    JUMPING,
    FALLING,
    ATTACKING,
    DEAD
}

enum DamageType {
    PHYSICAL,
    FIRE,
    ICE,
    LIGHTNING,
    POISON
}
```

---

## Code Organization

### File Structure
```gdscript
class_name MyClass
extends Node
## Brief description of the class.
##
## Longer description if needed.
## Can span multiple lines.

# ============================================================
# SIGNALS
# ============================================================
signal something_happened
signal value_changed(new_value: int)

# ============================================================
# CONSTANTS
# ============================================================
const MAX_VALUE := 100
const DEFAULT_SPEED := 200.0

# ============================================================
# ENUMS
# ============================================================
enum State { IDLE, ACTIVE, DISABLED }

# ============================================================
# EXPORTS
# ============================================================
@export_group("Configuration")
@export var speed: float = DEFAULT_SPEED
@export var max_health: int = MAX_VALUE

@export_group("References")
@export var target_path: NodePath

# ============================================================
# PUBLIC VARIABLES
# ============================================================
var current_state: State = State.IDLE
var health: int = 100

# ============================================================
# PRIVATE VARIABLES
# ============================================================
var _internal_timer: float = 0.0
var _cached_data: Dictionary = {}

# ============================================================
# ONREADY VARIABLES
# ============================================================
@onready var _sprite: Sprite2D = $Sprite2D
@onready var _collision: CollisionShape2D = $CollisionShape2D

# ============================================================
# BUILT-IN CALLBACKS
# ============================================================
func _ready() -> void:
    pass


func _process(delta: float) -> void:
    pass


func _physics_process(delta: float) -> void:
    pass

# ============================================================
# PUBLIC METHODS
# ============================================================
func do_something() -> void:
    pass


func get_value() -> int:
    return 0

# ============================================================
# PRIVATE METHODS
# ============================================================
func _internal_helper() -> void:
    pass

# ============================================================
# SIGNAL CALLBACKS
# ============================================================
func _on_button_pressed() -> void:
    pass
```

---

## Anti-Patterns to Avoid

### 1. Stringly-Typed Code
```gdscript
# BAD: Strings for types
func set_state(state: String) -> void:
    if state == "idle":
        pass
    elif state == "walking":
        pass
    # Typos like "wlaking" won't be caught!

# GOOD: Use enums
enum State { IDLE, WALKING, RUNNING }

func set_state(state: State) -> void:
    match state:
        State.IDLE:
            pass
        State.WALKING:
            pass
```

### 2. Boolean Parameters
```gdscript
# BAD: What does true mean?
attack(enemy, true, false, true)

# GOOD: Named parameters or separate methods
attack(enemy, is_critical=true, is_ranged=false, apply_knockback=true)

# Or better: separate methods
perform_critical_attack(enemy)
perform_ranged_attack(enemy)
```

### 3. Long Parameter Lists
```gdscript
# BAD: Too many parameters
func create_enemy(type, health, speed, damage, armor, x, y, patrol_points,
                  drop_table, xp_value, is_boss, spawn_effect):
    pass

# GOOD: Use configuration objects
func create_enemy(config: EnemyConfig, position: Vector2) -> Enemy:
    pass

# Or builder pattern
func create_enemy() -> EnemyBuilder:
    return EnemyBuilder.new()

# Usage: create_enemy().with_health(100).at_position(pos).build()
```

### 4. Comments That Lie
```gdscript
# BAD: Comment doesn't match code (and will rot)
# Damage is reduced by armor
func calculate_damage(base: int, armor: int) -> int:
    return base * 2  # Code ignores armor!

# GOOD: Self-documenting code needs no comment
func calculate_damage_ignoring_armor(base: int) -> int:
    return base * 2
```

### 5. Premature Abstraction
```gdscript
# BAD: Over-engineered for simple case
class_name DamageCalculatorStrategyFactoryInterface
# ... 500 lines of abstraction for one damage formula

# GOOD: Simple and direct
func calculate_damage(base: int, multiplier: float) -> int:
    return int(base * multiplier)
```

---

## Quick Reference Card

| Principle | Do This | Not This |
|-----------|---------|----------|
| Types | `var health: int = 100` | `var h = 100` |
| Names | `player_movement_speed` | `pms` or `speed1` |
| Functions | `func get_enemies_in_range()` | `func getEIR()` |
| Booleans | `is_alive`, `has_weapon`, `can_jump` | `alive`, `weapon`, `jump` |
| Constants | `const MAX_HEALTH := 100` | `var max_hp = 100` |
| Nesting | Early returns, flat structure | Deep if/else chains |
| Errors | `push_error("Clear message")` | Silent failure |
| State | Explicit signals and setters | Hidden side effects |
| Comments | Explain "why" | Restate "what" |
| Size | < 200 lines per file | Mega-files |

---

## Summary

**Write code as if explaining to a knowledgeable colleague who hasn't seen your codebase.**

1. **Be explicit** - Types, names, intent
2. **Be consistent** - Same patterns everywhere
3. **Be focused** - Single responsibility
4. **Be flat** - Avoid nesting
5. **Be loud** - Clear errors
6. **Be pure** - Minimize side effects
7. **Be small** - Short files and functions
8. **Be predictable** - Follow conventions

Code that follows these principles is code that AI can understand, modify, and extend reliably.

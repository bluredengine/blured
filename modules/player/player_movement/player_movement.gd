class_name PlayerMovement
extends CharacterBody2D
## 2D platformer movement with jumping, coyote time, and jump buffering.

signal jumped
signal landed
signal started_falling

## Movement speed (pixels/second)
@export var speed: float = 300.0

## Initial jump velocity (negative = up)
@export var jump_velocity: float = -400.0

## Gravity multiplier
@export var gravity_scale: float = 1.0

## Time after leaving ground where jump is still allowed
@export var coyote_time: float = 0.1

## Time before landing where jump input is remembered
@export var jump_buffer_time: float = 0.1

## Ground acceleration
@export var acceleration: float = 1500.0

## Ground friction when not moving
@export var friction: float = 1000.0

## Air control multiplier (0-1)
@export var air_control: float = 0.3

# Internal state
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _was_on_floor: bool = false
var _gravity: float


func _ready() -> void:
	_gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _physics_process(delta: float) -> void:
	var was_on_floor = is_on_floor()

	# Apply gravity
	if not is_on_floor():
		velocity.y += _gravity * gravity_scale * delta

	# Handle coyote time
	if was_on_floor and not is_on_floor():
		_coyote_timer = coyote_time
		started_falling.emit()
	elif is_on_floor():
		_coyote_timer = 0.0

	if _coyote_timer > 0:
		_coyote_timer -= delta

	# Handle jump buffer
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = jump_buffer_time

	if _jump_buffer_timer > 0:
		_jump_buffer_timer -= delta

	# Try to jump
	if _jump_buffer_timer > 0 and can_jump():
		jump()
		_jump_buffer_timer = 0.0

	# Horizontal movement
	var direction = get_movement_input()
	var control = 1.0 if is_on_floor() else air_control

	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * control * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * control * delta)

	# Landing detection
	if not _was_on_floor and is_on_floor():
		landed.emit()

	_was_on_floor = is_on_floor()

	move_and_slide()


## Get horizontal movement input (-1, 0, or 1)
func get_movement_input() -> float:
	return Input.get_axis("move_left", "move_right")


## Check if player can jump
func can_jump() -> bool:
	return is_on_floor() or _coyote_timer > 0


## Perform jump
func jump() -> bool:
	if can_jump():
		velocity.y = jump_velocity
		_coyote_timer = 0.0
		jumped.emit()
		return true
	return false

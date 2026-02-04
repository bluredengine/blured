extends CharacterBody2D
## Platformer player character with jumping and movement.

signal jumped
signal landed
signal died

@export var speed: float = 300.0
@export var jump_velocity: float = -400.0
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.1

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _was_on_floor: bool = false
var _gravity: float


func _ready() -> void:
	_gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y += _gravity * delta

	# Coyote time
	if _was_on_floor and not is_on_floor():
		_coyote_timer = coyote_time
	elif is_on_floor():
		_coyote_timer = 0.0

	if _coyote_timer > 0:
		_coyote_timer -= delta

	# Jump buffer
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = jump_buffer_time

	if _jump_buffer_timer > 0:
		_jump_buffer_timer -= delta

	# Jump
	if _jump_buffer_timer > 0 and (is_on_floor() or _coyote_timer > 0):
		velocity.y = jump_velocity
		_coyote_timer = 0.0
		_jump_buffer_timer = 0.0
		jumped.emit()

	# Movement
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	# Landing detection
	if not _was_on_floor and is_on_floor():
		landed.emit()

	_was_on_floor = is_on_floor()

	move_and_slide()

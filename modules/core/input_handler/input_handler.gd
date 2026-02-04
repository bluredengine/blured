class_name InputHandler
extends Node
## Centralized input management with buffering support.
## Provides clean input queries and supports input buffering for responsive controls.

signal action_pressed(action: String)
signal action_released(action: String)

## Time window for input buffering (seconds)
@export var input_buffer_time: float = 0.1

## Master toggle for input processing
@export var input_enabled: bool = true

## Buffered inputs: action -> time pressed
var _buffer: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if not input_enabled:
		return

	# Update buffer timers
	var to_remove: Array = []
	for action in _buffer:
		_buffer[action] -= delta
		if _buffer[action] <= 0:
			to_remove.append(action)

	for action in to_remove:
		_buffer.erase(action)


func _input(event: InputEvent) -> void:
	if not input_enabled:
		return

	# Check all known actions
	for action in InputMap.get_actions():
		if event.is_action_pressed(action):
			_buffer[action] = input_buffer_time
			action_pressed.emit(action)
		elif event.is_action_released(action):
			action_released.emit(action)


## Check if action is currently held
func is_action_pressed(action: String) -> bool:
	if not input_enabled:
		return false
	return Input.is_action_pressed(action)


## Check if action was just pressed this frame
func is_action_just_pressed(action: String) -> bool:
	if not input_enabled:
		return false
	return Input.is_action_just_pressed(action)


## Check if action was just released this frame
func is_action_just_released(action: String) -> bool:
	if not input_enabled:
		return false
	return Input.is_action_just_released(action)


## Check if action is in the input buffer
func is_action_buffered(action: String) -> bool:
	if not input_enabled:
		return false
	return _buffer.has(action) and _buffer[action] > 0


## Consume a buffered input
func consume_buffer(action: String) -> void:
	_buffer.erase(action)


## Get axis value between two actions
func get_axis(negative_action: String, positive_action: String) -> float:
	if not input_enabled:
		return 0.0
	return Input.get_axis(negative_action, positive_action)


## Get 2D vector from four directional actions
func get_vector(left_action: String, right_action: String, up_action: String, down_action: String) -> Vector2:
	if not input_enabled:
		return Vector2.ZERO
	return Input.get_vector(left_action, right_action, up_action, down_action)


## Temporarily disable input
func disable_input() -> void:
	input_enabled = false
	_buffer.clear()


## Re-enable input
func enable_input() -> void:
	input_enabled = true

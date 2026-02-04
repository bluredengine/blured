class_name GameManager
extends Node
## Core game state management singleton.
## Handles game flow, scene transitions, and global state.

signal game_started
signal game_paused
signal game_resumed
signal game_over(reason: String)
signal scene_changed(scene_path: String)

## Current pause state
var is_paused: bool = false:
	set(value):
		is_paused = value
		get_tree().paused = value

## Current scene path
var current_scene: String = ""

## Global game data dictionary
var game_data: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()


## Start a new game session
func start_game() -> void:
	is_paused = false
	game_data.clear()
	game_started.emit()


## Pause the game
func pause_game() -> void:
	if not is_paused:
		is_paused = true
		game_paused.emit()


## Resume the game
func resume_game() -> void:
	if is_paused:
		is_paused = false
		game_resumed.emit()


## Toggle pause state
func toggle_pause() -> void:
	if is_paused:
		resume_game()
	else:
		pause_game()


## Trigger game over
func trigger_game_over(reason: String = "") -> void:
	game_over.emit(reason)


## Change to a new scene
func change_scene(scene_path: String) -> void:
	current_scene = scene_path
	get_tree().change_scene_to_file(scene_path)
	scene_changed.emit(scene_path)


## Store data in global dictionary
func set_data(key: String, value: Variant) -> void:
	game_data[key] = value


## Retrieve data from global dictionary
func get_data(key: String, default: Variant = null) -> Variant:
	return game_data.get(key, default)

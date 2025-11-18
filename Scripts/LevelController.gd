extends Node2D
class_name LevelController

@onready var pause_menu = $UI/PauseMenu
var paused: bool = false
@onready var player = get_node_or_null("Scene/Characters/Player")
@onready var spawn = $Scene/Spawn
@onready var characters = $Scene/Characters
@export var destination_scene: String = ""

func setup_level() -> void:
	print("Setting up level: ", get_tree().get_current_scene().name)
	if SceneTransition.player:
		if player:
			player.queue_free()

		player = SceneTransition.player
		characters.add_child(player)
		position_player()
		return
	elif characters.has_node("Player"):
		player = characters.get_node("Player") as PlayerMain
		position_player()
		return
	var PlayerScene = preload("res://Scenes/Player/Player.tscn")
	player = PlayerScene.instantiate()
	player.name = "Player"
	characters.add_child(player)
	position_player()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Escape"):
		pauseMenu()

func pauseMenu():
	if paused:
		pause_menu.hide()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().paused = false
	else:
		pause_menu.show()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().paused = true

	paused = !paused

func position_player() -> void:
	var last_scene = SceneTransition.last_scene_name
	if last_scene.is_empty():
		last_scene = "any"

	for entrance in spawn.get_children():
		if entrance is Marker2D and (entrance.name == "any" or entrance.name == last_scene):
			player.global_position = entrance.global_position

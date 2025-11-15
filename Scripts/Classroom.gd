extends Node2D

@onready var pause_menu = $UI/PauseMenu
var paused: bool = false
var entered: bool = false
@export var destination_scene= "res://Scenes/Levels/MainFloor.tscn"

func _ready() -> void:
	pass



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Escape"):
		pauseMenu()
	if entered:
		get_tree().change_scene_to_file(destination_scene)
		entered = false

func _on_door_body_entered(body) -> void:
	if body is PlayerMain:
		entered = true

func _on_door_body_exited(body) -> void:
	if body is PlayerMain:
		entered = false

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


## Helper removed: Classroom no longer sets player facing here (door handler sets SceneTree meta).
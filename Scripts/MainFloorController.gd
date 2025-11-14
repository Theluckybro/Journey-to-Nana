extends Node2D

@onready var pause_menu = $UI/PauseMenu
# Note: Make sure the PauseMenu node's "Process" -> "Process Mode" (in the Inspector)
# is set to "When Paused" so the UI can receive input while the scene tree is paused.
var paused: bool = false
var entered: bool = false
@export var destination_scene= "res://Scenes/Outside.tscn"

func _ready():
	Dialogic.signal_event.connect(_on_dialogic_signal, CONNECT_ONE_SHOT)

	Dialogic.start("gamestart")

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Escape"):
		pauseMenu()
	
	if entered:
		get_tree().change_scene_to_file(destination_scene)

func _on_door_body_entered(_body: PlayerMain) -> void:
	entered = true

func _on_door_body_exited(_body: PlayerMain) -> void:
	entered = false

func pauseMenu():
	if paused:
		# Unpause: hide the menu, capture mouse, resume the tree
		pause_menu.hide()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		get_tree().paused = false
	else:
		# Pause: show the menu, show mouse, pause the tree
		pause_menu.show()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().paused = true

	paused = !paused


func _on_gamestart_ended():
	# Deprecated: timeline_ended handler kept for backwards compatibility.
	# Prefer using Dialogic signal event (see _on_dialogic_signal).
	if Engine.has_singleton("QuestSpawner"):
		QuestSpawner.spawn_bath_quest()
	else:
		var Spawner = load("res://Scripts/Quest/QuestSpawner.gd")
		var sp = Spawner.new()
		sp.spawn_bath_quest()

func _on_dialogic_signal(argument: Variant) -> void:
	# Timeline emits Dialogic.signal_event with the argument we placed in the timeline.
	if typeof(argument) == TYPE_STRING and argument == "get_ready":
		if Engine.has_singleton("QuestSpawner"):
			QuestSpawner.spawn_get_ready_quest()
		else:
			var Spawner = load("res://Scripts/Quest/QuestSpawner.gd")
			var sp = Spawner.new()
			sp.spawn_get_ready_quest()
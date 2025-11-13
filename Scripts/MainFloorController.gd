extends Node2D

@onready var pause_menu = $UI/PauseMenu
var paused: bool = false

func _ready():
	Dialogic.signal_event.connect(_on_dialogic_signal, CONNECT_ONE_SHOT)

	Dialogic.start("gamestart")

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Escape"):
		pauseMenu()

func pauseMenu():
	if paused:
		pause_menu.hide()
		Engine.time_scale = 1
	else:
		pause_menu.show()
		Engine.time_scale = 0

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

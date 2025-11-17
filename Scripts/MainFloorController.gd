extends "res://Scripts/LevelController.gd"

func _ready():
	if not get_tree().has_meta("gamestart_played"):
		Dialogic.signal_event.connect(_on_dialogic_signal, CONNECT_ONE_SHOT)
		Dialogic.start("gamestart")
		get_tree().set_meta("gamestart_played", true)

	setup_level()

func _on_gamestart_ended():
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
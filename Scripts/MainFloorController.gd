extends "res://Scripts/LevelController.gd"

@onready var quest_spawner: QuestSpawnerNode = $Scene/QuestSpawner

func _ready():
	if not SaveLoad.check_flag("gamestart_played"):
		Dialogic.signal_event.connect(_on_dialogic_signal, CONNECT_ONE_SHOT)
		Dialogic.start("gamestart")
		SaveLoad.set_flag("gamestart_played", true)

	setup_level()
	

func _on_gamestart_ended():
	if Engine.has_singleton("QuestSpawner"):
		QuestSpawner.spawn_bath_quest()
	else:
		var Spawner = load("res://Scripts/Quest/QuestSpawner.gd")
		var sp = Spawner.new()
		sp.spawn_bath_quest()

func _on_dialogic_signal(argument: Variant) -> void:
	if typeof(argument) == TYPE_STRING and argument == "get_ready":
		if quest_spawner:
			quest_spawner.spawn_quest_by_id("get_ready_001")
		else:
			print("Error: Node QuestSpawner tidak ditemukan di Scene MainFloor")
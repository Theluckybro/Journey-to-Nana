extends "res://Scripts/LevelController.gd"

@onready var quest_spawner: QuestSpawnerNode = $Scene/QuestSpawner
@onready var sleep_spot: Marker2D = $Scene/Spawn/SleepSpot
@onready var wake_up_spot: Marker2D = $Scene/Spawn/WakeUpSpot

@export_range(0.2, 10.0, 0.1) var iris_reveal_duration: float = 2.8

func _ready():
	var play_intro := not SaveLoad.check_flag("gamestart_played")

	setup_level()

	if play_intro:
		SaveLoad.set_time(6, 30)
		_prepare_intro_cutscene()

		if not Dialogic.signal_event.is_connected(Callable(self, "_on_dialogic_signal")):
			Dialogic.signal_event.connect(_on_dialogic_signal)

		Dialogic.start("gamestart")
		SaveLoad.set_flag("gamestart_played", true)
	

func _on_gamestart_ended():
	if Engine.has_singleton("QuestSpawner"):
		QuestSpawner.spawn_bath_quest()
	else:
		var Spawner = load("res://Scripts/Quest/QuestSpawner.gd")
		var sp = Spawner.new()
		sp.spawn_bath_quest()

func _on_dialogic_signal(argument: Variant) -> void:
	if typeof(argument) != TYPE_STRING:
		return

	match argument:
		"start_alarm":
			_start_intro_reveal()
		"wake_up":
			_wake_player_from_bed()
		"get_ready":
			if SaveLoad.check_flag("get_ready_001_completed") or SaveLoad.check_flag("get_ready_001_taken"):
				return
			if quest_spawner:
				quest_spawner.spawn_quest_by_id("get_ready_001")
			else:
				print("Error: Node QuestSpawner tidak ditemukan di Scene MainFloor")

func _start_intro_reveal() -> void:
	var transition_manager = get_node_or_null("/root/TransitionManager")
	if transition_manager == null:
		return

	if transition_manager.has_method("has_pending_reveal") and not transition_manager.has_pending_reveal():
		return

	if transition_manager.has_method("start_iris_reveal"):
		var viewport_center: Vector2 = get_viewport().get_visible_rect().size * 0.5 + Vector2(0, -18)
		transition_manager.start_iris_reveal(viewport_center, iris_reveal_duration)

func _prepare_intro_cutscene() -> void:
	if not player:
		return

	player.can_move = false
	player.velocity = Vector2.ZERO
	player.face_direction = Vector2.UP

	if sleep_spot:
		player.global_position = sleep_spot.global_position

	player.set_sleep_pose()
	
func _wake_player_from_bed() -> void:
	if not player:
		return

	player.can_move = false
	player.velocity = Vector2.ZERO

	var target_pos: Vector2 = player.global_position
	if wake_up_spot:
		target_pos = wake_up_spot.global_position
	else:
		target_pos += Vector2(24, 0)

	var sprite = player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

	if sprite:
		sprite.flip_v = false
	player.play_idle_right()

	var tween := create_tween()
	tween.tween_property(player, "global_position", target_pos, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	if sprite:
		var initial_sprite_pos = sprite.position
		tween.parallel().tween_property(sprite, "position:y", -15.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(sprite, "position:y", initial_sprite_pos.y, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		player.face_direction = Vector2.RIGHT
	)
	player.can_move = true
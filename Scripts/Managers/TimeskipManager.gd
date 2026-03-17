extends Node

const TIMESKIP_UI_SCENE = preload("res://Scenes/UI/TimeskipUI.tscn")
const DAY1_CAMPUS_FLAG: String = "day1_campus_intro_played"
const LEGACY_DAY1_CLASSROOM_FLAG: String = "day1_classroom_intro_played"

var _is_running: bool = false

func trigger_day1_campus_timeskip(player: PlayerMain = null, post_facing: Vector2 = Vector2.UP) -> void:
	if _is_running:
		return
	if _is_day1_campus_intro_done():
		return

	var target_player: PlayerMain = _resolve_player(player)
	_set_player_locked(target_player, true)

	# Preserve campus beat context before jumping to afternoon.
	SaveLoad.set_time(7, 0, false)
	await _run_timeskip(
		"07:00 AM - Kampus",
		"Indra duduk di kelas. Dosen menjelaskan teori yang entah kapan akan dipakai. Waktu berlalu...",
		2.6
	)

	SaveLoad.set_time(14, 30)
	_set_day1_campus_intro_done()
	_apply_player_return_pose(target_player, post_facing)
	_set_player_locked(target_player, false)

# Backward-compatible alias for callers that still use the old method name.
func trigger_day1_classroom_timeskip(player: PlayerMain = null, post_facing: Vector2 = Vector2.UP) -> void:
	await trigger_day1_campus_timeskip(player, post_facing)

func trigger_food_delivery_timeskip(player: PlayerMain = null) -> void:
	if _is_running:
		return

	var target_player: PlayerMain = _resolve_player(player)
	_set_player_locked(target_player, true)

	await _run_timeskip("15:15 PM", "Pesanan Ayam Geprek otw!", 2.0)
	SaveLoad.set_time(15, 15)

	_set_player_locked(target_player, false)

func _run_timeskip(title_text: String, body_text: String, hold_seconds: float) -> void:
	_is_running = true

	var ui: TimeskipUI = TIMESKIP_UI_SCENE.instantiate() as TimeskipUI
	get_tree().root.add_child(ui)
	ui.play_sequence(title_text, body_text, hold_seconds)
	await ui.timeskip_finished

	if is_instance_valid(ui):
		ui.queue_free()

	_is_running = false

func _resolve_player(explicit_player: PlayerMain) -> PlayerMain:
	if explicit_player != null:
		return explicit_player

	if Global and Global.player is PlayerMain:
		return Global.player as PlayerMain

	return get_tree().get_first_node_in_group("Player") as PlayerMain

func _set_player_locked(player: PlayerMain, locked: bool) -> void:
	if player == null:
		return

	player.can_move = not locked
	if locked:
		player.velocity = Vector2.ZERO

func _apply_player_return_pose(player: PlayerMain, facing: Vector2) -> void:
	if player == null:
		return

	var target_facing: Vector2 = facing
	if target_facing == Vector2.ZERO:
		target_facing = Vector2.UP
	target_facing = target_facing.normalized()

	player.face_direction = target_facing
	player.global_position += target_facing * 14.0

func _is_day1_campus_intro_done() -> bool:
	return SaveLoad.check_flag(DAY1_CAMPUS_FLAG) or SaveLoad.check_flag(LEGACY_DAY1_CLASSROOM_FLAG)

func _set_day1_campus_intro_done() -> void:
	SaveLoad.set_flag(DAY1_CAMPUS_FLAG, true)
	SaveLoad.set_flag(LEGACY_DAY1_CLASSROOM_FLAG, true)

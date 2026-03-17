extends Area2D

const DAY1_CAMPUS_TIMESKIP_ID: String = "day1_campus_timeskip"
const DAY1_CAMPUS_FLAG: String = "day1_campus_intro_played"
const LEGACY_DAY1_CLASSROOM_FLAG: String = "day1_classroom_intro_played"
const POST_CAMPUS_BLOCKED_LABEL: String = "door_after_campus"

## Scene tujuan saat player memasuki trigger
@export var destination_scene: String

@export_category("Quest Gate")
@export var required_completed_flag: String = ""
@export var blocked_timeline_name: String = "interactables"
@export var blocked_timeline_label: String = "door_blocked"
@export var play_success_timeline_before_transition: bool = false
@export var success_timeline_name: String = "interactables"
@export var success_timeline_label: String = "door_ready"

var _is_handling_entry: bool = false

enum Direction {
	UP,
	RIGHT,
	DOWN,
	LEFT
	}

## Arah player menghadap setelah pindah scene
@export var facing_choice: Direction

func get_facing_vector() -> Vector2:
	match facing_choice:
		Direction.UP:
			return Vector2.UP
		Direction.RIGHT:
			return Vector2.RIGHT
		Direction.DOWN:
			return Vector2.DOWN
		Direction.LEFT:
			return Vector2.LEFT
	return Vector2.UP

func _on_body_entered(body: Node2D) -> void:
	if _is_handling_entry:
		return
	if not (body is PlayerMain):
		return

	var player: PlayerMain = body as PlayerMain
	if player == null:
		return

	_is_handling_entry = true

	if not _can_pass_gate():
		await _play_gate_timeline(blocked_timeline_name, blocked_timeline_label, player, true)
		_push_player_back(player)
		_is_handling_entry = false
		return

	if _is_day1_campus_timeskip_target() and _is_day1_campus_intro_done():
		await _play_gate_timeline(blocked_timeline_name, POST_CAMPUS_BLOCKED_LABEL, player, true)
		_push_player_back(player)
		_is_handling_entry = false
		return

	if play_success_timeline_before_transition:
		await _play_gate_timeline(success_timeline_name, success_timeline_label, player, false)

	if _is_day1_campus_timeskip_target():
		if TimeskipManager and TimeskipManager.has_method("trigger_day1_campus_timeskip"):
			await TimeskipManager.trigger_day1_campus_timeskip(player, get_facing_vector())
		elif TimeskipManager and TimeskipManager.has_method("trigger_day1_classroom_timeskip"):
			await TimeskipManager.trigger_day1_classroom_timeskip(player, get_facing_vector())
		_is_handling_entry = false
		return

	SceneTransition.change_scene(player, destination_scene, get_facing_vector())
	_is_handling_entry = false

func _can_pass_gate() -> bool:
	var trimmed_flag: String = required_completed_flag.strip_edges()
	if trimmed_flag == "":
		return true
	return SaveLoad.check_flag(trimmed_flag)

func _play_gate_timeline(timeline_name: String, timeline_label: String, player: PlayerMain, restore_player_move: bool = true) -> void:
	var trimmed_name: String = timeline_name.strip_edges()
	if trimmed_name == "":
		if restore_player_move and player and is_instance_valid(player):
			player.can_move = true
		return

	if player and is_instance_valid(player):
		player.can_move = false
		player.velocity = Vector2.ZERO

	var trimmed_label: String = timeline_label.strip_edges()
	if trimmed_label != "":
		Dialogic.start(trimmed_name, trimmed_label)
	else:
		Dialogic.start(trimmed_name)

	await Dialogic.timeline_ended

	if restore_player_move and player and is_instance_valid(player):
		player.can_move = true

func _is_day1_campus_timeskip_target() -> bool:
	return destination_scene.strip_edges().to_lower() == DAY1_CAMPUS_TIMESKIP_ID

func _is_day1_campus_intro_done() -> bool:
	return SaveLoad.check_flag(DAY1_CAMPUS_FLAG) or SaveLoad.check_flag(LEGACY_DAY1_CLASSROOM_FLAG)

func _push_player_back(player: PlayerMain) -> void:
	if player == null:
		return

	var push_dir := -player.face_direction.normalized()
	if push_dir == Vector2.ZERO:
		push_dir = Vector2.DOWN

	player.global_position += push_dir * 16.0


extends CanvasLayer

@onready var animation_player: AnimationPlayer = $TransitionAnimation

var player: PlayerMain
var last_scene_name: String
var scene_path = "res://Scenes/Levels/"


func handle_door_exited(_body: Node) -> void:
	pass

func change_scene(player_node: Node, destination_scene: String, _facing: Vector2) -> void:
	var _player_ref = player_node as PlayerMain
	player = _player_ref
	var cur_scene = get_tree().get_current_scene()
	if cur_scene:
		last_scene_name = cur_scene.name
	elif _player_ref and _player_ref.get_parent():
		last_scene_name = _player_ref.get_parent().name
	else:
		last_scene_name = ""

	if _player_ref:
		_player_ref.name = "Player"
		Global.player = _player_ref
		_player_ref.can_move = false

	var parent = null
	if _player_ref:
		parent = _player_ref.get_parent()

	animation_player.play("transition_out")
	await animation_player.animation_finished

	if _player_ref and _facing != null:
		if _facing is Vector2:
			_player_ref.face_direction = _facing

		if _player_ref.fsm and _player_ref.fsm.current_state:
			var enter_call = Callable(_player_ref.fsm.current_state, "Enter")
			enter_call.call()

	if parent and _player_ref:
		parent.remove_child(_player_ref)

	if _facing != null:
		get_tree().set_meta("next_player_facing", _facing)
	
	

	var full_path = scene_path + destination_scene + ".tscn"
	get_tree().call_deferred("change_scene_to_file", full_path)

	animation_player.play_backwards("transition_out")
	await animation_player.animation_finished
	if _player_ref:
		_player_ref.can_move = true
		print("SceneTransition: Player movement restored.")
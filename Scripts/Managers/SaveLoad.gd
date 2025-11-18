extends Node

const save_location = "user://SaveFile.tres"

var SaveFileData: SaveDataResource = SaveDataResource.new()

func _ready() -> void:
	_load()

func _save():
	ResourceSaver.save(SaveFileData, save_location)

func _load():
	if FileAccess.file_exists(save_location):
		SaveFileData = ResourceLoader.load(save_location).duplicate(true)

func restore_to_scene():
	var tree = get_tree()
	var max_wait_frames: int = 10
	var waited: int = 0
	var current_scene = tree.current_scene
	print("Restoring to scene: ", current_scene)
	while current_scene == null and waited < max_wait_frames:
		print("Waiting for current scene to be ready...")
		await tree.process_frame
		waited += 1
		current_scene = tree.current_scene
	# Ensure the current scene is ready
	if current_scene == null:
		print("restore_to_scene: current_scene not ready after waiting; aborting restore")
		return
	print("Current scene ready: ", current_scene.name)


	var player = current_scene.get_node_or_null("Scene/Characters/Player")
	
	print("Restoring player state...")
	print("Player: ", player)

	player.global_position = SaveFileData.position
	print(" Player position restored to: ", player.global_position)

	player.face_direction = SaveFileData.face_direction
	var enter_call = Callable(player.fsm.current_state, "Enter")
	enter_call.call_deferred()
	print(" Player face direction restored to: ", player.face_direction)

	player.coin_amount = SaveFileData.coin_amount
	print(" Player coin amount restored to: ", player.coin_amount)

	# Restore active quest into the player's QuestManager if present
	var qm = player.get_node_or_null("QuestManager")
	if qm != null:
		qm.load_from_save(SaveFileData)
		qm.load_active_quest(SaveFileData.active_quest)
		print("Active quest restored into QuestManager: ", SaveFileData.active_quest)
	else:
		print("restore_to_scene: QuestManager not found on player; skipping quest restore")

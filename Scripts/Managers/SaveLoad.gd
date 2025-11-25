extends Node

const save_location = "user://SaveFile.tres"

var SaveFileData: SaveDataResource = SaveDataResource.new()

func save_game():
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		SaveFileData.position = player.global_position
		SaveFileData.face_direction = player.face_direction
		SaveFileData.coin_amount = player.coin_amount
	
		if player.selected_quest:
			SaveFileData.selected_quest_id = player.selected_quest.quest_id
		else:
			SaveFileData.selected_quest_id = ""

		var all_active = player.quest_manager.get_active_quests()
		SaveFileData.active_quests = all_active
	else:
		print("save_game: Player not found in scene tree")
	
	SaveFileData.current_scene = get_tree().current_scene.get_scene_file_path()

	ResourceSaver.save(SaveFileData, save_location)
	print("Game saved to ", save_location)

func load_game():
	if FileAccess.file_exists(save_location):
		SaveFileData = ResourceLoader.load(save_location).duplicate(true)
		if Dialogic.VAR:
			Dialogic.VAR.set_variable("affection", SaveFileData.affection)
		call_deferred("_switch_to_loaded_scene")
		return true
	else:
		print("No save file found at ", save_location)
		return false

func _switch_to_loaded_scene():
	get_tree().change_scene_to_file(SaveFileData.current_scene)

func new_game():
	SaveFileData = SaveDataResource.new()
	var starting_scene = "res://Scenes/Levels/MainFloor.tscn"
	get_tree().change_scene_to_file(starting_scene)
	print("Starting new game at ", starting_scene)

func check_flag(flag_name: String) -> bool:
	if SaveFileData.flags.has(flag_name):
		return SaveFileData.flags[flag_name]
	return false

func set_flag(flag_name: String, value: bool = true):
	SaveFileData.flags[flag_name] = value

func add_affection(amount: int):
	SaveFileData.affection += amount
	
	if SaveFileData.affection < 0:
		SaveFileData.affection = 0
		
	print("Affection Updated: ", SaveFileData.affection)
	
	if Dialogic.VAR:
		Dialogic.VAR.set_variable("affection", SaveFileData.affection)
	
	if Global.player:
		var popup = load("res://Art/Sprites/UI/heart_popup.tscn").instantiate()
		Global.player.add_child(popup)
		popup.position = Vector2(0, -25)

func add_affection_once(flag_id: String, amount: int):
	if check_flag(flag_id):
		print("Afeksi untuk ", flag_id, " sudah pernah diambil.")
		return

	add_affection(amount)
	set_flag(flag_id, true)
	print("Afeksi bertambah ", amount, " dari ", flag_id)
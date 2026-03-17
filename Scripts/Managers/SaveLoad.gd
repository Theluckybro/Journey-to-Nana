extends Node

signal game_time_changed(hour: int, minute: int, formatted_time: String)

const save_location = "user://SaveFile.tres"
const DEFAULT_START_HOUR: int = 6
const DEFAULT_START_MINUTE: int = 30

var SaveFileData: SaveDataResource = SaveDataResource.new()

func save_game() -> void:
	var player := get_tree().get_first_node_in_group("Player")
	if player:
		SaveFileData.position = player.global_position
		SaveFileData.face_direction = player.face_direction
		SaveFileData.coin_amount = player.coin_amount
	
		if player.selected_quest:
			SaveFileData.selected_quest_id = player.selected_quest.quest_id
		else:
			SaveFileData.selected_quest_id = ""

		if player.quest_manager:
			SaveFileData.active_quests = player.quest_manager.get_active_quests()
	else:
		print("save_game: Player not found in scene tree")
	
	if get_tree().current_scene:
		SaveFileData.current_scene = get_tree().current_scene.get_scene_file_path()

	ResourceSaver.save(SaveFileData, save_location)
	print("Game saved to ", save_location)

func load_game() -> bool:
	if FileAccess.file_exists(save_location):
		var loaded := ResourceLoader.load(save_location)
		if loaded == null:
			print("Failed to load save file at ", save_location)
			return false

		var duplicated := loaded.duplicate(true)
		if duplicated is SaveDataResource:
			SaveFileData = duplicated
		else:
			print("Save file was not a SaveDataResource: ", save_location)
			return false

		_ensure_time_initialized(false)

		if Dialogic.VAR:
			Dialogic.VAR.set_variable("affection", SaveFileData.affection)
		call_deferred("_switch_to_loaded_scene")
		return true
	else:
		print("No save file found at ", save_location)
		return false

func _switch_to_loaded_scene() -> void:
	get_tree().change_scene_to_file(SaveFileData.current_scene)

func new_game() -> void:
	SaveFileData = SaveDataResource.new()
	set_time(DEFAULT_START_HOUR, DEFAULT_START_MINUTE, false)
	var starting_scene = "res://Scenes/Levels/MainFloor.tscn"
	get_tree().change_scene_to_file(starting_scene)
	print("Starting new game at ", starting_scene)

func get_time_total_minutes() -> int:
	return (SaveFileData.current_hour * 60) + SaveFileData.current_minute

func get_time_string() -> String:
	return "%02d:%02d" % [SaveFileData.current_hour, SaveFileData.current_minute]

func set_time(hour: int, minute: int, emit_signal_event: bool = true) -> void:
	var total_minutes: int = (hour * 60) + minute
	set_time_from_total_minutes(total_minutes, emit_signal_event)

func set_time_from_total_minutes(total_minutes: int, emit_signal_event: bool = true) -> void:
	var day_minutes: int = 24 * 60
	var wrapped: int = ((total_minutes % day_minutes) + day_minutes) % day_minutes

	SaveFileData.current_hour = int(wrapped / 60)
	SaveFileData.current_minute = wrapped % 60

	if emit_signal_event:
		game_time_changed.emit(SaveFileData.current_hour, SaveFileData.current_minute, get_time_string())

func add_minutes(minutes: int, emit_signal_event: bool = true) -> void:
	set_time_from_total_minutes(get_time_total_minutes() + minutes, emit_signal_event)

func _ensure_time_initialized(emit_signal_event: bool = false) -> void:
	if SaveFileData.current_hour < 0 or SaveFileData.current_hour > 23:
		set_time(DEFAULT_START_HOUR, DEFAULT_START_MINUTE, emit_signal_event)
		return

	if SaveFileData.current_minute < 0 or SaveFileData.current_minute > 59:
		set_time(DEFAULT_START_HOUR, DEFAULT_START_MINUTE, emit_signal_event)
		return

	if emit_signal_event:
		game_time_changed.emit(SaveFileData.current_hour, SaveFileData.current_minute, get_time_string())

func check_flag(flag_name: String) -> bool:
	if SaveFileData.flags.has(flag_name):
		return SaveFileData.flags[flag_name]
	return false

func set_flag(flag_name: String, value: bool = true) -> void:
	SaveFileData.flags[flag_name] = value

func add_affection(amount: int) -> void:
	SaveFileData.affection += amount
	
	if SaveFileData.affection < 0:
		SaveFileData.affection = 0
		
	print("Affection Updated: ", SaveFileData.affection)
	
	if Dialogic.VAR:
		Dialogic.VAR.set_variable("affection", SaveFileData.affection)
	
	if Global.player:
		var packed := load("res://Art/Sprites/UI/heart_popup.tscn")
		if packed:
			var popup: Node = packed.instantiate()
			Global.player.add_child(popup)
			popup.position = Vector2(0, -25)

func add_affection_once(flag_id: String, amount: int) -> void:
	if check_flag(flag_id):
		print("Afeksi untuk ", flag_id, " sudah pernah diambil.")
		return

	add_affection(amount)
	set_flag(flag_id, true)
	print("Afeksi bertambah ", amount, " dari ", flag_id)
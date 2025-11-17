extends Control


func _on_new_game_pressed() -> void:
	if get_tree().has_meta("gamestart_played"):
		get_tree().set_meta("gamestart_played", null)
	get_tree().change_scene_to_file("res://Scenes/Levels/MainFloor.tscn")


func _on_continue_pressed() -> void:
	# Load saved data (populate SaveLoad.contents) then restore global settings
	SaveLoad._load()
	var version: int = SaveLoad.contents_to_save.get("version", 1)
	print("Loaded save data, version ", version)

	var current_scene = SaveLoad.contents_to_save["scene"].get("current_scene", "")
	var last_scene = SaveLoad.contents_to_save["scene"].get("last_scene", "")
	print("Current scene from save: ", current_scene)
	print("Last scene from save: ", last_scene)
	if current_scene == "":
		return

	# Change to the saved scene, then wait one frame so the new scene is fully ready
	var tree = get_tree()
	tree.change_scene_to_file(current_scene)
	if SaveLoad and SaveLoad.has_method("restore_to_scene"):
		SaveLoad.restore_to_scene()
	else:
		print("Warning: SaveLoad.restore_to_scene not available; saved state won't be restored here.")




func _on_settings_pressed() -> void:
	# Remember we came from MainMenu so Settings can return here.
	var sh = get_node_or_null("/root/SceneHistory")
	if sh and sh.has_method("set_previous"):
		sh.set_previous("res://Scenes/Misc/Menu/MainMenu.tscn")

	get_tree().change_scene_to_file("res://Scenes/Misc/Menu/Settings/Settings.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()

extends Control


func _on_new_game_pressed() -> void:
	if get_tree().has_meta("gamestart_played"):
		get_tree().set_meta("gamestart_played", null)
	get_tree().change_scene_to_file("res://Scenes/Levels/MainFloor.tscn")


func _on_continue_pressed() -> void:
	SaveLoad._load()
	var version: int = SaveLoad.SaveFileData.version
	print("Loaded save file version: %d" % version)

	var current_scene: String = SaveLoad.SaveFileData.current_scene
	get_tree().set_meta("gamestart_played", true)
	get_tree().change_scene_to_file(current_scene)
	print("Continuing to scene: ", current_scene)
	
	SceneTransition.last_scene_name = SaveLoad.SaveFileData.last_scene
	print("last scene: ", SceneTransition.last_scene_name)

	SaveLoad.restore_to_scene()
	



func _on_settings_pressed() -> void:
	# Remember we came from MainMenu so Settings can return here.
	var sh = get_node_or_null("/root/SceneHistory")
	if sh and sh.has_method("set_previous"):
		sh.set_previous("res://Scenes/Misc/Menu/MainMenu.tscn")

	get_tree().change_scene_to_file("res://Scenes/Misc/Menu/Settings/Settings.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()

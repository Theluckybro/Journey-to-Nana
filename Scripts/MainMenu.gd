extends Control


func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Levels/MainFloor.tscn")


func _on_settings_pressed() -> void:
	# Remember we came from MainMenu so Settings can return here.
	var sh = get_node_or_null("/root/SceneHistory")
	if sh and sh.has_method("set_previous"):
		sh.set_previous("res://Scenes/Misc/Menu/MainMenu.tscn")

	get_tree().change_scene_to_file("res://Scenes/Misc/Menu/Settings/Settings.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()


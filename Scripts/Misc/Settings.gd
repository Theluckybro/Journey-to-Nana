extends Control


func _on_video_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Misc/Menu/Settings/Video.tscn")


func _on_audio_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Misc/Menu/Settings/Audio.tscn")


func _on_back_pressed() -> void:
	var sh = get_node_or_null("/root/SceneHistory")
	if sh and sh.has_method("get_previous"):
		var prev = sh.get_previous()
		if prev != "":
			sh.clear()
			get_tree().change_scene_to_file(prev)
			return

	# Fallback
	get_tree().change_scene_to_file("res://Scenes/Misc/Menu/MainMenu.tscn")

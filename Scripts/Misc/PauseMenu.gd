extends Control

@onready var main = $"../../"


func _on_resume_pressed() -> void:
	main.pauseMenu()


func _on_settings_pressed() -> void:
	var sh = get_node_or_null("/root/SceneHistory")
	if sh and sh.has_method("set_previous"):
		sh.set_previous("res://Scenes/Levels/MainFloor.tscn")
	else:
		# If the autoload wasn't added, warn in console but continue.
		print("SceneHistory autoload not found. Add Scripts/SceneHistory.gd as an autoload named 'SceneHistory' to enable returning from Settings to the previous scene.")

	get_tree().change_scene_to_file("res://Scenes/Misc/Menu/Settings/Settings.tscn")


func _on_quit_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Misc/Menu/MainMenu.tscn")

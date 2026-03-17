extends Control

func _ready() -> void:
	if not FileAccess.file_exists(SaveLoad.save_location):
		%Continue.disabled = true

func _on_new_game_pressed() -> void:
	var transition_manager = get_node_or_null("/root/TransitionManager")
	if transition_manager and transition_manager.has_method("prepare_new_game_blackout"):
		transition_manager.prepare_new_game_blackout()
	SaveLoad.new_game()


func _on_continue_pressed() -> void:
	var success = SaveLoad.load_game()
	if not success:
		print("Failed to load game on continue.")
	



func _on_settings_pressed() -> void:
	# Remember we came from MainMenu so Settings can return here.
	var sh = get_node_or_null("/root/SceneHistory")
	if sh and sh.has_method("set_previous"):
		sh.set_previous("res://Scenes/Misc/Menu/MainMenu.tscn")

	get_tree().change_scene_to_file("res://Scenes/Misc/Menu/Settings/Settings.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()

extends Control


func _on_resolutions_item_selected(index: int) -> void:
	# compute the chosen size from the selected index
	var chosen_size: Vector2i = Vector2i(640, 360)
	match index:
		0:
			chosen_size = Vector2i(640, 360)
		1:
			chosen_size = Vector2i(1280, 720)
		2:
			chosen_size = Vector2i(1600, 900)
		3:
			chosen_size = Vector2i(1920, 1080)

	# If we're currently fullscreen, only remember the selected size so it
	# will be applied when exiting fullscreen. If we're windowed, apply it now.
	var mode := DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		_prev_window_size = chosen_size
	else:
		DisplayServer.window_set_size(chosen_size)
		_prev_window_size = chosen_size

# Keep track of the previous window size so we can restore it when leaving fullscreen
var _prev_window_size: Vector2i = Vector2i(640, 360)


func _ready() -> void:
	# initialize previous size with current window size
	_prev_window_size = DisplayServer.window_get_size()


func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		# store current window size then go fullscreen
		_prev_window_size = DisplayServer.window_get_size()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		# return to windowed mode and restore previous size
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(_prev_window_size)
		# resizability is controlled by project settings; no API call needed here


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Misc/Menu/Settings/Settings.tscn")
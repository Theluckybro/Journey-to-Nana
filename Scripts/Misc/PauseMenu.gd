extends Control

@onready var main = $"../../"

# Keep track of the previous window size so we can restore it when leaving fullscreen
var _prev_window_size: Vector2i = Vector2i(640, 360)

# Audio volume constants (copied from Audio.gd)
const MIN_DB: float = -80.0
const MAX_DB: float = 3.0


func _ready() -> void:
	# initialize previous size with current window size
	_prev_window_size = DisplayServer.window_get_size()

	# audio initialization: play preview and ensure volume slider has a default
	# try a couple of likely paths for the Pause menu layout
	if has_node("AudioStreamPlayer"):
		$AudioStreamPlayer.play()

	if has_node("CenterContainer/AudioMenu/AudioStreamPlayer"):
		$CenterContainer/AudioMenu/AudioStreamPlayer.play()

	# initialize volume slider if present (prefer the Pause menu specific path)
	if has_node("CenterContainer/AudioMenu/MarginContainer/VBoxContainer/Volume"):
		var vol_slider = $CenterContainer/AudioMenu/MarginContainer/VBoxContainer/Volume
		if vol_slider.value == 0.0:
			vol_slider.value = 50.0
		_on_volume_value_changed(vol_slider.value)
	elif has_node("MarginContainer/VBoxContainer/Volume"):
		var vol_slider2 = $MarginContainer/VBoxContainer/Volume
		if vol_slider2.value == 0.0:
			vol_slider2.value = 50.0
		_on_volume_value_changed(vol_slider2.value)

	_reset_to_main_buttons()
	if not is_connected("visibility_changed", Callable(self, "_on_visibility_changed")):
		connect("visibility_changed", Callable(self, "_on_visibility_changed"))


func _on_resume_pressed() -> void:
	main.pauseMenu()


func _on_settings_pressed() -> void:
	$Panel/CenterContainer/MainButtons.visible = false
	$Panel/CenterContainer/SettingsMenu.visible = true


func _on_quit_pressed() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Dialogic.end_timeline(true)
	if get_tree().has_meta("gamestart_played"):
			get_tree().set_meta("gamestart_played", null)

	get_tree().change_scene_to_file("res://Scenes/Misc/Menu/MainMenu.tscn")

func _on_back_pressed() -> void:
	$Panel/CenterContainer/SettingsMenu.visible = false
	$Panel/CenterContainer/MainButtons.visible = true
	

func _on_video_pressed() -> void:
	$Panel/CenterContainer/SettingsMenu.visible = false
	$Panel/CenterContainer/VideoMenu.visible = true

func _on_audio_pressed() -> void:
	$Panel/CenterContainer/SettingsMenu.visible = false
	$Panel/CenterContainer/AudioMenu.visible = true


func _on_back_to_settings_pressed() -> void:
	$Panel/CenterContainer/VideoMenu.visible = false
	$Panel/CenterContainer/AudioMenu.visible = false
	$Panel/CenterContainer/SettingsMenu.visible = true
	

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


func _on_volume_value_changed(value: float) -> void:
	var db: float = 0.0
	if value <= 50.0:
		var t_low: float = clamp(value / 50.0, 0.0, 1.0)
		db = lerp(MIN_DB, 0.0, t_low)
	else:
		var t_high: float = clamp((value - 50.0) / 50.0, 0.0, 1.0)
		db = lerp(0.0, MAX_DB, t_high)

	AudioServer.set_bus_volume_db(0, db)


func _on_mute_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(0, toggled_on)


func _on_visibility_changed() -> void:
	# When the pause menu becomes visible, reset UI to main buttons
	if visible:
		_reset_to_main_buttons()


func _reset_to_main_buttons() -> void:
	# Prefer the Panel/CenterContainer path used elsewhere in the scene.
	# Use has_node checks to avoid errors if the layout differs.
	if has_node("Panel/CenterContainer/MainButtons"):
		$Panel/CenterContainer/MainButtons.visible = true
	if has_node("Panel/CenterContainer/SettingsMenu"):
		$Panel/CenterContainer/SettingsMenu.visible = false
	if has_node("Panel/CenterContainer/VideoMenu"):
		$Panel/CenterContainer/VideoMenu.visible = false
	if has_node("Panel/CenterContainer/AudioMenu"):
		$Panel/CenterContainer/AudioMenu.visible = false

	# Some layouts may have these nodes at the top-level in the Pause menu.
	if has_node("MainButtons"):
		$MainButtons.visible = true
	if has_node("SettingsMenu"):
		$SettingsMenu.visible = false
	if has_node("VideoMenu"):
		$VideoMenu.visible = false
	if has_node("AudioMenu"):
		$AudioMenu.visible = false

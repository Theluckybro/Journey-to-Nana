extends Control

# Map slider 0..100 to a decibel range.
# - Slider 0 -> MIN_DB (effectively silent)
# - Slider 50 -> 0 dB (default audible level)
# - Slider 100 -> MAX_DB (mild boost)
const MIN_DB: float = -80.0
const MAX_DB: float = 3.0


func _ready() -> void:
	# Auto-start audio stream player if present
	if has_node("AudioStreamPlayer"):
		$AudioStreamPlayer.play()

	# Apply slider default and initial volume mapping
	if has_node("MarginContainer/VBoxContainer/Volume"):
		var vol_slider = $MarginContainer/VBoxContainer/Volume
		# Ensure slider has a sensible default; use 50 if the .tscn didn't set it
		if vol_slider.value == 0.0:
			vol_slider.value = 50.0
		_on_volume_value_changed(vol_slider.value)


func _on_volume_value_changed(value: float) -> void:
	# Use a piecewise mapping so 50 -> 0 dB (default)
	# 0..50 maps MIN_DB..0, 50..100 maps 0..MAX_DB
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


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Misc/Menu/Settings/Settings.tscn")
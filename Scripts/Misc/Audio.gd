extends Control

const MIN_DB: float = -80.0
const MAX_DB: float = 3.0


func _ready() -> void:
	if has_node("AudioStreamPlayer"):
		$AudioStreamPlayer.play()

	if has_node("MarginContainer/VBoxContainer/Volume"):
		var vol_slider = $MarginContainer/VBoxContainer/Volume
		if vol_slider.value == 0.0:
			vol_slider.value = 50.0
		_on_volume_value_changed(vol_slider.value)


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


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Misc/Menu/Settings/Settings.tscn")
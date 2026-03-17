extends CanvasLayer
class_name TimeskipUI

signal timeskip_finished

@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var content: Control = $Content
@onready var time_label: Label = $Content/Panel/Box/TimeLabel
@onready var narration_label: Label = $Content/Panel/Box/NarrationLabel

var _is_playing: bool = false

func play_sequence(time_text: String, narration_text: String, hold_seconds: float = 2.6) -> void:
	if _is_playing:
		return

	_is_playing = true
	time_label.text = time_text
	narration_label.text = narration_text
	content.modulate.a = 0.0
	fade_overlay.color.a = 0.0

	var fade_in_tween := create_tween()
	fade_in_tween.tween_property(fade_overlay, "color:a", 1.0, 0.5)
	await fade_in_tween.finished

	var content_in_tween := create_tween()
	content_in_tween.tween_property(content, "modulate:a", 1.0, 0.35)
	await content_in_tween.finished

	await get_tree().create_timer(max(0.2, hold_seconds)).timeout

	var fade_out_tween := create_tween()
	fade_out_tween.tween_property(content, "modulate:a", 0.0, 0.25)
	fade_out_tween.parallel().tween_property(fade_overlay, "color:a", 0.0, 0.8)
	await fade_out_tween.finished

	_is_playing = false
	timeskip_finished.emit()

extends CanvasLayer

@onready var overlay: ColorRect = $Overlay

const RADIUS_PROPERTY := "material:shader_parameter/circle_radius"
const CENTER_PROPERTY := "material:shader_parameter/center_position"

var _pending_new_game_reveal := false
var _is_revealing := false
var _active_tween: Tween = null

func _ready() -> void:
	hide()
	_reset_overlay()

func prepare_new_game_blackout() -> void:
	_pending_new_game_reveal = true
	_is_revealing = false
	_stop_active_tween()
	_reset_overlay()
	show()

func has_pending_reveal() -> bool:
	return _pending_new_game_reveal and not _is_revealing

func start_iris_reveal(player_screen_position: Vector2, duration: float = 1.2) -> void:
	if not _pending_new_game_reveal:
		return
	if _is_revealing:
		return
	if not is_instance_valid(overlay):
		return

	_is_revealing = true
	show()

	var center: Vector2 = player_screen_position
	if center == Vector2.ZERO:
		center = _get_viewport_center()

	overlay.material.set_shader_parameter("center_position", center)
	overlay.material.set_shader_parameter("circle_radius", 0.0)

	var end_radius: float = _compute_cover_radius(center) + 24.0
	_active_tween = create_tween()
	_active_tween.tween_property(overlay, RADIUS_PROPERTY, end_radius, max(duration, 0.01)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_active_tween.finished.connect(_on_reveal_finished)

func cancel_transition() -> void:
	_pending_new_game_reveal = false
	_is_revealing = false
	_stop_active_tween()
	hide()

func _on_reveal_finished() -> void:
	_pending_new_game_reveal = false
	_is_revealing = false
	_stop_active_tween()
	hide()

func _reset_overlay() -> void:
	if not is_instance_valid(overlay):
		return

	overlay.visible = true
	overlay.material.set_shader_parameter("center_position", _get_viewport_center())
	overlay.material.set_shader_parameter("circle_radius", 0.0)

func _stop_active_tween() -> void:
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
	_active_tween = null

func _get_viewport_center() -> Vector2:
	var rect: Rect2 = get_viewport().get_visible_rect()
	return rect.size * 0.5

func _compute_cover_radius(center: Vector2) -> float:
	var rect: Rect2 = get_viewport().get_visible_rect()
	var size := rect.size
	var corners := [
		Vector2.ZERO,
		Vector2(size.x, 0.0),
		Vector2(0.0, size.y),
		Vector2(size.x, size.y)
	]

	var max_distance := 0.0
	for corner in corners:
		var dist: float = center.distance_to(corner)
		if dist > max_distance:
			max_distance = dist
	return max_distance

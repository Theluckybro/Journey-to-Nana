### QuestNotification.gd
extends Control

# Small controller for the QuestNotification scene.
# Uses tweens for show/hide animations (Godot 4).

@onready var panel = $CanvasLayer/PanelContainer
@onready var icon = $CanvasLayer/PanelContainer/HBoxContainer/Icon
@onready var announcement_label = $CanvasLayer/PanelContainer/HBoxContainer/CenterContainer/VBoxContainer/QuestAnnouncement
@onready var title_label = $CanvasLayer/PanelContainer/HBoxContainer/CenterContainer/VBoxContainer/QuestTitle
@onready var timer = $Timer
var quest_manager = null
var _active_tween: Tween = null
var notifications_enabled: bool = true

func _ready():
	# start hidden (guard nodes in case the scene structure differs)
	if panel:
		panel.visible = false
	if announcement_label:
		announcement_label.visible = false
	if title_label:
		title_label.visible = false

	# ensure timeout is connected
	if timer and not timer.is_connected("timeout", Callable(self, "_on_timer_timeout")):
		timer.connect("timeout", Callable(self, "_on_timer_timeout"))

	# Initialize modulate alpha for fade animations so we can tween safely
	if panel:
		var c = panel.modulate
		c.a = 0.0
		panel.modulate = c
	if announcement_label:
		var ca = announcement_label.modulate
		ca.a = 0.0
		announcement_label.modulate = ca
	if title_label:
		var ct = title_label.modulate
		ct.a = 0.0
		title_label.modulate = ct
	# (no shadow) start state already set on panel/labels above

	# ensure icon scale default
	if icon:
		icon.scale = Vector2.ONE

	# Connect to quest manager signals if parent provides them
	if get_parent():
		quest_manager = get_parent()
		if quest_manager and quest_manager.has_method("get_quest"):
			if not quest_manager.quest_updated.is_connected(Callable(self, "_on_quest_updated")):
				quest_manager.quest_updated.connect(Callable(self, "_on_quest_updated"))


func show_notification(text: String, announcement: String = "Quest Started") -> void:
	# Show a simple two-line notification: announcement + quest title
	if announcement_label:
		announcement_label.text = announcement
		announcement_label.visible = true
	if title_label:
		title_label.text = text
		title_label.visible = true
	if panel:
		panel.visible = true

	# Use tweens for the entrance animation. Kill any previous tween to avoid
	# overlapping animations (which can cause the shadow to linger).
	if _active_tween:
		_active_tween.kill()
	_active_tween = create_tween()
	var t = _active_tween
	t.tween_property(panel, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if announcement_label:
		t.tween_property(announcement_label, "modulate:a", 1.0, 0.25)
	if title_label:
		t.tween_property(title_label, "modulate:a", 1.0, 0.25)
	if icon:
		# small pop animation for the icon
		icon.scale = Vector2(0.92, 0.92)
		t.tween_property(icon, "scale", Vector2(1.08, 1.08), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(icon, "scale", Vector2(1, 1), 0.08).set_delay(0.12)

	if timer:
		timer.start()

	# Clear the active tween reference once the entrance animation finishes
	t.tween_callback(Callable(self, "_clear_active_tween"))


func _on_timer_timeout() -> void:
	# Hide using tweens then call _hide_nodes
	# Stop any running tween first, then create a new one for hiding.
	if _active_tween:
		_active_tween.kill()
	_active_tween = create_tween()
	var t = _active_tween
	t.tween_property(panel, "modulate:a", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if announcement_label:
		t.tween_property(announcement_label, "modulate:a", 0.0, 0.18)
	if title_label:
		t.tween_property(title_label, "modulate:a", 0.0, 0.18)
	# Ensure we hide nodes when the fade-out completes, and clear the
	# active tween reference afterwards so future animations start cleanly.
	t.tween_callback(Callable(self, "_hide_nodes"))
	t.tween_callback(Callable(self, "_clear_active_tween"))


func _hide_nodes() -> void:
	if panel:
		panel.visible = false
	if announcement_label:
		announcement_label.visible = false
	if title_label:
		title_label.visible = false
	# hide nodes when animation completes


func _clear_active_tween() -> void:
	# Helper to clear the stored tween reference after it finishes/was killed
	_active_tween = null


func _on_quest_updated(quest_id: String) -> void:
	if not notifications_enabled:
		return
	if not quest_manager:
		return
	if not quest_manager.has_method("get_quest"):
		return
	var quest = quest_manager.get_quest(quest_id)
	if quest:
		if quest.state == "completed":
			show_notification(quest.quest_name, "Quest Completed")
		elif quest.state == "in_progress":
			if quest.has_method("is_completed") and quest.is_completed():
				return 
			show_notification(quest.quest_name, "Quest Started")

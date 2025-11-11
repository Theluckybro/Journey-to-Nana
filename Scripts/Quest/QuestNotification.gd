extends Control

# Small controller for the QuestNotification scene.
# Usage: call show_notification("text") to display the notification for the configured time.

@onready var panel = $CanvasLayer/Panel
@onready var announcement_label = $CanvasLayer/Panel/VBoxContainer/QuestAnnouncement
@onready var title_label = $CanvasLayer/Panel/VBoxContainer/QuestTitle
@onready var timer = $Timer
@onready var anim_player = $AnimationPlayer
var quest_manager = null

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

	# If an AnimationPlayer exists, ensure we don't double-hide via callbacks.
	# We'll prefer playing 'show'/'hide' animations if they exist.
	if anim_player:
		# ensure no lingering connections
		if anim_player.is_connected("animation_finished", Callable(self, "_on_animation_finished")):
			anim_player.disconnect("animation_finished", Callable(self, "_on_animation_finished"))
		anim_player.connect("animation_finished", Callable(self, "_on_animation_finished"))

	# If this notification is added as a child of the QuestManager (like QuestUI),
	# connect to its signals so the notification can show automatically when a
	# quest becomes in_progress. The scene should be attached as a child of
	# QuestManager in the editor (we don't modify the .tscn here).
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

	# Use AnimationPlayer if available and has the 'show' animation; otherwise fallback to tween
	if anim_player and anim_player.has_animation("show"):
		# Ensure nodes are visible before playing (animation drives alpha)
		if panel:
			panel.visible = true
		if announcement_label:
			announcement_label.visible = true
		if title_label:
			title_label.visible = true
		anim_player.play("show")
	else:
		var tween = create_tween()
		if panel:
			tween.tween_property(panel, "modulate:a", 1.0, 0.18)
		if announcement_label:
			tween.tween_property(announcement_label, "modulate:a", 1.0, 0.18)
		if title_label:
			tween.tween_property(title_label, "modulate:a", 1.0, 0.18)

	if timer:
		timer.start()


func _on_timer_timeout() -> void:
	# If AnimationPlayer has a 'hide' animation, play it and wait for the
	# animation_finished callback to hide nodes. Otherwise fallback to tween.
	if anim_player and anim_player.has_animation("hide"):
		anim_player.play("hide")
	else:
		var tween = create_tween()
		if panel:
			tween.tween_property(panel, "modulate:a", 0.0, 0.18)
		if announcement_label:
			tween.tween_property(announcement_label, "modulate:a", 0.0, 0.18)
		if title_label:
			tween.tween_property(title_label, "modulate:a", 0.0, 0.18)
		tween.tween_callback(Callable(self, "_hide_nodes"))

func _hide_nodes() -> void:
	if panel:
		panel.visible = false
	if announcement_label:
		announcement_label.visible = false
	if title_label:
		title_label.visible = false

func _on_quest_updated(quest_id: String) -> void:
	# Called by QuestManager when a quest changes. If the quest is newly in
	# progress, show a short notification for the player.
	if not quest_manager:
		return
	if not quest_manager.has_method("get_quest"):
		return
	var quest = quest_manager.get_quest(quest_id)
	# quest_updated is emitted when a quest changes state. Show different
	# announcements depending on the new state. Note: update_quest emits
	# quest_updated before it removes a completed quest, so get_quest should
	# still return the quest here.
	if quest:
		if quest.state == "in_progress":
			show_notification(quest.quest_name, "Quest Started")
		elif quest.state == "completed":
			show_notification(quest.quest_name, "Quest Completed")

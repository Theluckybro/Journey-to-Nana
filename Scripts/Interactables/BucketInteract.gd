extends Area2D

# Area that detects the player entering and completes the bath quest objective.

func _ready():
	if not Engine.is_editor_hint():
		connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	# Ignore editor
	if Engine.is_editor_hint():
		return

	# Identify player instance
	var player = null
	if Global and Global.player:
		player = Global.player

	# If the entering body is the player, try to complete objective
	if (player and body == player) or (body and body.has_method("is_in_group") and body.is_in_group("Player")):
		if Global and Global.player and Global.player.quest_manager:
			Global.player.quest_manager.complete_objective("bath_001", "bath_obj_1")
			print("Bucket: attempted to complete bath objective")
		else:
			printerr("BucketInteract: quest_manager not available")

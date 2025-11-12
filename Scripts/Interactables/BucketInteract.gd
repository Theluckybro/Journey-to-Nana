extends Area2D

# BucketInteract.gd
@export var interaction_id: String = "bath"
@export var interaction_type: String = "action"
@export var interaction_quantity: int = 1

func _ready():
	if Engine.is_editor_hint():
		return

func interact(by_player: Node = null) -> void:
	if Engine.is_editor_hint():
		return

	var player = by_player
	if player == null:
		if Global and Global.player:
			player = Global.player

	if player == null:
		printerr("BucketInteract.interact: no player provided or found via Global.player")
		return

	# Defer to player's check_quest_objectives so quest logic behaves consistently
	if player and player.has_method("check_quest_objectives"):
		var applied = player.check_quest_objectives(interaction_id, interaction_type, interaction_quantity)
	elif Global and Global.player and Global.player.quest_manager:
		# Fallback: if player API missing but quest_manager exists, attempt a safer call
		printerr("BucketInteract: player.check_quest_objectives() not available; no safe apply performed")
	else:
		printerr("BucketInteract: quest_manager/player not available")

func can_interact() -> bool:
	"""Helper for player code: returns whether this object can currently be interacted with.
	For now it always returns true, but you can add checks (cooldowns, states, inventory, etc.)."""
	return true

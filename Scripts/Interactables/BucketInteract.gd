extends Area2D

# BucketInteract.gd
# This Area2D is now passive: the player should raycast and call `interact()` on this node
# when the player presses `ui_interact`. This decouples the interaction input from the
# object and fits the `raycast -> input -> interact()` pattern.

# Identifier and type used by quest objectives. Set these in the editor to match
# the objective.target_id and objective.target_type used by your Quest resource.
@export var interaction_id: String = "bath"
@export var interaction_type: String = "action"
@export var interaction_quantity: int = 1

func _ready():
	# Keep the node present in the scene. No automatic body_entered handling here.
	if Engine.is_editor_hint():
		return

	# Optional: you can still use groups or signals for highlight/hover if needed.

func interact(by_player: Node = null) -> void:
	"""
	Called by the player when the bucket is in the player's raycast and the player
	pressed the interaction button (e.g. `ui_interact`).

	by_player: (optional) the player Node that initiated the interaction. If omitted,
	the function will fallback to `Global.player`.
	"""
	if Engine.is_editor_hint():
		return

	var player = by_player
	if player == null:
		if Global and Global.player:
			player = Global.player

	# Optionally verify the caller is actually the player
	# (not strictly necessary if caller ensures this)
	if player == null:
		printerr("BucketInteract.interact: no player provided or found via Global.player")
		return

	# Apply objective via the player's API so we don't force-complete the quest.
	# This mirrors how QuestItem and NPC interaction use PlayerMain.check_quest_objectives
	# which respects selected quests and active quests and runs completion logic.
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

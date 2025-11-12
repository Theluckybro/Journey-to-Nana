extends Area2D

# CupboardInteract.gd
@export var interaction_id: String = "cupboard"
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
		printerr("CupboardInteract.interact: no player provided or found via Global.player")
		return

	# Defer to player's check_quest_objectives so quest logic behaves consistently
	if player and player.has_method("check_quest_objectives"):
		var applied = player.check_quest_objectives(interaction_id, interaction_type, interaction_quantity)
		if applied:
			print("Cupboard: applied interaction to quest objectives (id=", interaction_id, ")")
		else:
			print("Cupboard: interaction did not match any active objectives")
			if player and player.quest_manager and player.quest_manager.has_method("get_active_quests"):
				var active = player.quest_manager.get_active_quests()
				print("Cupboard Diagnostic: active quests count=", active.size())
				for aq in active:
					print(" - Quest:", aq.quest_id, aq.quest_name, "state=", aq.state)
					for obj in aq.objectives:
						print("    obj.id=", obj.id, "target_id=", obj.target_id, "target_type=", obj.target_type, "completed=", obj.is_completed)
	elif Global and Global.player and Global.player.quest_manager:
		printerr("CupboardInteract: player.check_quest_objectives() not available; no safe apply performed")
	else:
		printerr("CupboardInteract: quest_manager/player not available")

func can_interact() -> bool:
	# Returns whether this object can currently be interacted with.
	# You can add cooldown/state checks here; for now it is always true.
	return true

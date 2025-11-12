extends Node

# Small helper to programmatically add quests to the player's QuestManager.
# Usage: QuestSpawner.spawn_bath_quest()

const QuestScript = preload("res://Resources/Quest/Quests.gd")
const ObjectiveScript = preload("res://Resources/Quest/Objectives.gd")

# Spawns a simple "Mandi Pagi" quest and adds it to the player's quest manager.
func spawn_get_ready_quest():
	var q = QuestScript.new()
	q.quest_id = "get_ready_001"
	q.quest_name = "Siap-siap"
	q.quest_description = "Bersiap-siap untuk berangkat kuliah."
	# mark quest as in_progress so it appears in the quest tracker immediately
	q.state = "in_progress"

	var obj = ObjectiveScript.new()
	obj.id = "bath_obj_1"
	obj.description = "Pergi ke kamar mandi buat mandi!"
	obj.target_id = "bath"
	obj.target_type = "action"
	obj.required_quantity = 1
	obj.collected_quantity = 0
	obj.is_completed = false

	# Second objective: change clothes at the cupboard
	var obj2 = ObjectiveScript.new()
	obj2.id = "cupboard_obj_1"
	obj2.description = "Ganti baju di lemari pakaian"
	obj2.target_id = "cupboard"
	obj2.target_type = "action"
	obj2.required_quantity = 1
	obj2.collected_quantity = 0
	obj2.is_completed = false

	# Append objective to the exported objectives array to avoid invalid direct-assignment errors
	if q.objectives == null:
		q.objectives = []
	# Append both objectives in order
	q.objectives.append(obj)
	q.objectives.append(obj2)
	# Ensure rewards array exists (leave empty for now)
	if q.rewards == null:
		q.rewards = []

	# Try to add to quest manager on the player's node
	if Global and Global.player and Global.player.quest_manager:
		Global.player.quest_manager.add_quest(q)
		print("Spawned quest:", q.quest_name)
	else:
		push_error("Cannot spawn bath quest: Global.player or quest_manager not found.")

### QuestSpawner.gd
extends Node
class_name QuestSpawnerNode 

@export var available_quests: Array[Quest] = []

func spawn_quest_by_id(target_quest_id: String):
	if not (Global.player and Global.player.quest_manager):
		push_error("QuestSpawner: Player or QuestManager not found!")
		return

	var found_quest: Quest = null
	
	for q in available_quests:
		if q.quest_id == target_quest_id:
			found_quest = q.duplicate(true) 
			break
	
	if found_quest:
		if found_quest.state == "not_started":
			found_quest.state = "in_progress"
			
		Global.player.quest_manager.add_quest(found_quest)
		print("QuestSpawner: Berhasil menambahkan quest '", found_quest.quest_name, "'")
		if SaveLoad:
			SaveLoad.set_flag(target_quest_id + "_taken", true)
	else:
		push_warning("QuestSpawner: Quest dengan ID '" + target_quest_id + "' tidak ditemukan di list available_quests.")

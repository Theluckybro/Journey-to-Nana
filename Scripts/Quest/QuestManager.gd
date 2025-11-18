### QuestManager.gd

extends Node

class_name QuestManager

# Node Refs
@onready var quest_ui = $QuestUI

# vars
signal quest_updated(quest_id: String)
signal objective_updated(quest_id: String, objective_id: String)
signal quest_list_updated()
var quests = {}

func add_quest(quest: Quest):
	quests[quest.quest_id] = quest
	quest_updated.emit(quest.quest_id)

func _remove_quest(quest_id: String):
	quests.erase(quest_id)
	quest_list_updated.emit()
	
func get_quest(quest_id: String) -> Quest:
	return quests.get(quest_id, null)

func update_quest(quest_id: String, state: String):
	var quest = get_quest(quest_id)
	if quest:
		quest.state = state
		quest_updated.emit(quest_id)
		if state == "completed":
			_remove_quest(quest_id)
			
func get_active_quests() -> Array:
	var active_quests = []
	for quest in quests.values():
		if quest.state == "in_progress":
			active_quests.append(quest)
	return active_quests


func load_active_quest(quest_res: Quest) -> void:
	if quest_res == null:
		return
	quests[quest_res.quest_id] = quest_res
	quest_list_updated.emit()
	quest_updated.emit(quest_res.quest_id)


func load_from_save(save_res: Resource) -> void:
	if save_res == null:
		return
	var aq = null
	if save_res is SaveDataResource:
		aq = save_res.active_quest
	else:
		if save_res.has_method("get"):
			aq = save_res.get("active_quest")
	if aq and aq is Quest:
		load_active_quest(aq)


func complete_objective(quest_id: String, objective_id: String):
	var quest = get_quest(quest_id)
	if quest:
		quest.complete_objective(objective_id)
		objective_updated.emit(quest_id, objective_id)
						
func show_quest_log():
	quest_ui.show_hide_log()

### NPC.gd

extends CharacterBody2D

@export var npc_id: String
@export var npc_name: String

# Dialog vars
@onready var dialog_manager = $DialogManager
@export var dialog_resource: Dialog
@export var dialogic_timeline_name: String = ""
var current_state: String = "start"
var current_branch_index: int = 0

# Quest vars
@export var quests: Array[Quest] = []
var quest_manager: Node = null


func _ready():
	if dialog_resource:
		dialog_resource.load_from_json("res://Resources/Dialog/dialog_data.json")
	if dialog_manager:
		dialog_manager.npc = self
	if not Dialogic.signal_event.is_connected(Callable(self, "_on_dialogic_signal")):
		Dialogic.signal_event.connect(_on_dialogic_signal)
	if Global.player:
		quest_manager = Global.player.quest_manager
	else:
		print("Warning: Global.player is nil in NPC._ready(); quest_manager will be nil until player exists")
	
func start_dialog():
	if _get_current_branch_id().is_empty():
		return

	var quest_dialog = get_quest_dialog()
	if quest_dialog["text"] != "" and dialog_manager:
		dialog_manager.show_one_shot_dialog(npc_name, quest_dialog["text"], Callable(self, "_start_dialogic_branch"))
		return

	_start_dialogic_branch()

func _start_dialogic_branch() -> void:
	var branch_id := _get_current_branch_id()
	if branch_id.is_empty():
		return

	current_state = "start"
	Dialogic.start(_get_dialogic_timeline_name(), branch_id + "_start")

func _get_dialogic_timeline_name() -> String:
	if dialogic_timeline_name.strip_edges() != "":
		return dialogic_timeline_name.strip_edges()
	return npc_id

func _get_dialog_branches() -> Array:
	if dialog_resource == null:
		return []
	return dialog_resource.get_npc_dialog(npc_id)

func _get_current_branch_id() -> String:
	var npc_dialogs := _get_dialog_branches()
	if npc_dialogs.is_empty():
		return ""
	var branch_index: int = clamp(current_branch_index, 0, npc_dialogs.size() - 1)
	return str(npc_dialogs[branch_index].get("branch_id", ""))

func _on_dialogic_signal(argument: Variant) -> void:
	if typeof(argument) != TYPE_STRING:
		return

	var parts := String(argument).split("|")
	if parts.size() < 3:
		return
	if parts[0] != "npc" or parts[1] != npc_id:
		return

	match parts[2]:
		"offer":
			if parts.size() >= 4:
				offer_quests_for_branch(parts[3])
		"advance":
			_advance_dialog_branch()

# Get current branch dialog
func get_current_dialog():
	var npc_dialogs = _get_dialog_branches()
	if current_branch_index < npc_dialogs.size():
		for dialog in npc_dialogs[current_branch_index]["dialogs"]:
			if dialog["state"] == current_state:
				return dialog
	return null

# Update dialog branch
func set_dialog_tree(branch_index):
	current_branch_index = branch_index
	current_state = "start"

# Update dialog state
func set_dialog_state(state):
	current_state = state

func _advance_dialog_branch() -> void:
	var npc_dialogs := _get_dialog_branches()
	if current_branch_index < npc_dialogs.size() - 1:
		set_dialog_tree(current_branch_index + 1)

func offer_quests_for_branch(branch_id: String) -> void:
	if branch_id == "npc_default":
		offer_remaining_quests()
		return

	for quest in quests:
		var can_offer := false
		if quest.state == "not_started":
			can_offer = quest.unlock_points.is_empty() or branch_id in quest.unlock_points
			if can_offer:
				offer_quest(quest.quest_id)

func offer_remaining_quests() -> void:
	for quest in quests:
		if quest.state == "not_started":
			offer_quest(quest.quest_id)

# Offer quest at required branch
func offer_quest(quest_id: String):
	print("Attempting to offer quest: ", quest_id)
	# If quest_manager wasn't available at _ready(), try to resolve it now.
	if not quest_manager:
		if Global.player and is_instance_valid(Global.player) and Global.player.quest_manager:
			quest_manager = Global.player.quest_manager
		else:
			var cs = get_tree().current_scene
			if cs:
				var player_node = cs.get_node_or_null("Scene/Characters/Player")
				if player_node and player_node.quest_manager:
					quest_manager = player_node.quest_manager

	for quest in quests:
		if quest.quest_id == quest_id and quest.state == "not_started":
			quest.state = "in_progress"
			if quest_manager:
				quest_manager.add_quest(quest)
			else:
				print("Warning: quest_manager is nil, cannot add quest at this time")
			return
	
	print("Quest not found or started already")

# Returns quest dialog
func get_quest_dialog() -> Dictionary:
	# If quest_manager isn't available yet, return empty dialog
	if not quest_manager:
		return {"text": "", "options": {}}
	var active_quests = quest_manager.get_active_quests()
	for quest in active_quests:
		for objective in quest.objectives:
			if objective.target_id == npc_id and objective.target_type == "talk_to" and not objective.is_completed:
				if current_state == "start":
					return {"text": objective.objective_dialog, "options": {}}
			
	return {"text": "", "options": {}}

### QuestUI.gd

extends Control

@onready var panel = $CanvasLayer/Panel
@onready var quest_list = $CanvasLayer/Panel/Contents/Details/QuestList
@onready var quest_title = $CanvasLayer/Panel/Contents/Details/QuestDetails/QuestTitle
@onready var quest_description = $CanvasLayer/Panel/Contents/Details/QuestDetails/QuestDescription
@onready var quest_objectives = $CanvasLayer/Panel/Contents/Details/QuestDetails/QuestObjectives
@onready var quest_rewards = $CanvasLayer/Panel/Contents/Details/QuestDetails/QuestRewards

var selected_quest: Quest = null
var quest_manager: QuestManager

func _ready() -> void:
	panel.visible = false
	clear_quest_details()
	
	# Quest Manager/UI connection
	quest_manager = get_parent() as QuestManager
	if quest_manager:
		quest_manager.quest_updated.connect(_on_quest_updated)
		quest_manager.objective_updated.connect(_on_objectives_updated)

func select_quest_by_id(quest_id: String) -> void:
	# Cari quest resource berdasarkan ID
	if quest_manager == null:
		return

	var quest: Quest = quest_manager.get_quest(quest_id)
	
	if quest:
		_select_quest(quest)

func get_player() -> PlayerMain:
	# Opsi 1: Jika QuestManager adalah child langsung dari PlayerMain
	if quest_manager and quest_manager.get_parent() is PlayerMain:
		return quest_manager.get_parent()
		
	# Opsi 2: Fallback ke Global jika struktur node berbeda (opsional)
	if Global.player:
		return Global.player
		
	return null

# Show/hide quest log
func show_hide_log() -> void:
	panel.visible = !panel.visible
	update_quest_list()

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()

func _sync_player_selection() -> void:
	var player := get_player()
	if player:
		player.selected_quest = selected_quest
		player.update_quest_tracker(selected_quest)

func _select_quest(quest: Quest) -> void:
	selected_quest = quest
	_render_selected_quest()
	_sync_player_selection()

# Populate quest list
func update_quest_list() -> void:
	_clear_children(quest_list)
		
	# Populate with new items
	if quest_manager == null:
		clear_quest_details()
		selected_quest = null
		_sync_player_selection()
		return

	var active_quests := quest_manager.get_active_quests()

	if selected_quest != null and not active_quests.has(selected_quest):
		selected_quest = null
		clear_quest_details()

	if active_quests.is_empty():
		clear_quest_details()
		selected_quest = null
	else: 
		for quest in active_quests:
			var button = Button.new()
			button.text = quest.quest_name
			button.pressed.connect(_on_quest_button_pressed.bind(quest))
			quest_list.add_child(button)

	_sync_player_selection()

func _on_quest_button_pressed(quest: Quest):
	if selected_quest == quest:
		deselect_quest()
	else:
		_select_quest(quest)

func deselect_quest() -> void:
	selected_quest = null
	clear_quest_details()
	_sync_player_selection()
	
func _render_selected_quest() -> void:
	if selected_quest == null:
		clear_quest_details()
		return

	# Populate details
	quest_title.text = selected_quest.quest_name
	quest_description.text = selected_quest.quest_description
	
	# Populate objectives
	_clear_children(quest_objectives)
	
	for objective in selected_quest.objectives:
		var label = Label.new()
		
		if objective.target_type == "collection":
			label.text = objective.description + "(" + str(objective.collected_quantity) + "/" + str(objective.required_quantity) + ")"
		else: 
			label.text = objective.description
	
		if objective.is_completed:
			label.add_theme_color_override("font_color", Color(0, 1, 0))
		else:
			label.add_theme_color_override("font_color", Color(1,0, 0))
			
		quest_objectives.add_child(label)
	
	# Populate rewards
	_clear_children(quest_rewards)
	
	for reward in selected_quest.rewards:
		var label = Label.new()
		label.add_theme_color_override("font_color", Color(0, 0.84, 0))
		label.text = "Rewards: " + reward.reward_type.capitalize() 	+ ": " + str(reward.reward_amount)
		quest_rewards.add_child(label)
	
# Trigger to clear quest details
func clear_quest_details() -> void:
	quest_title.text = ""
	quest_description.text = ""
	
	_clear_children(quest_objectives)
		
	_clear_children(quest_rewards)
	
# Trigger to update quest list
func _on_quest_updated(quest_id: String) -> void:
	if quest_manager == null:
		return

	var updated_quest = quest_manager.get_quest(quest_id)

	if selected_quest and selected_quest.quest_id == quest_id:
		if updated_quest == null or updated_quest.state == "completed":
			deselect_quest()
			update_quest_list()
			return

	if selected_quest and selected_quest.quest_id == quest_id:
		_render_selected_quest()
		_sync_player_selection()
	else:
		update_quest_list()
	
func _on_objectives_updated(quest_id: String, _objectives_id: String) -> void:
	if selected_quest and selected_quest.quest_id == quest_id:
		_render_selected_quest()
		_sync_player_selection()
	else:
		pass
	
func _on_close_button_pressed() -> void:
	show_hide_log()

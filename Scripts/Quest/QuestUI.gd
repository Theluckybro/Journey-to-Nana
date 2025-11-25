### QuestUI.gd

extends Control

@onready var panel = $CanvasLayer/Panel
@onready var quest_list = $CanvasLayer/Panel/Contents/Details/QuestList
@onready var quest_title = $CanvasLayer/Panel/Contents/Details/QuestDetails/QuestTitle
@onready var quest_description = $CanvasLayer/Panel/Contents/Details/QuestDetails/QuestDescription
@onready var quest_objectives = $CanvasLayer/Panel/Contents/Details/QuestDetails/QuestObjectives
@onready var quest_rewards = $CanvasLayer/Panel/Contents/Details/QuestDetails/QuestRewards

var selected_quest: Quest = null
var quest_manager

func _ready():
	panel.visible = false
	clear_quest_details()
	
	# Quest Manager/UI connection
	quest_manager = get_parent()
	if quest_manager:
		quest_manager.quest_updated.connect(_on_quest_updated)
		quest_manager.objective_updated.connect(_on_objectives_updated)

func select_quest_by_id(quest_id: String):
	# Cari quest resource berdasarkan ID
	var quest = quest_manager.get_quest(quest_id)
	
	if quest:
		selected_quest = quest
		
		_on_quest_selected(quest)
		
		var player = get_player()
		if player:
			player.selected_quest = quest
			player.update_quest_tracker(quest)

func get_player() -> PlayerMain:
	# Opsi 1: Jika QuestManager adalah child langsung dari PlayerMain
	if quest_manager.get_parent() is PlayerMain:
		return quest_manager.get_parent()
		
	# Opsi 2: Fallback ke Global jika struktur node berbeda (opsional)
	if Global.player:
		return Global.player
		
	return null

# Show/hide quest log
func show_hide_log():
	panel.visible = !panel.visible
	update_quest_list()

# Populate quest list
func update_quest_list():
	# Remove all items
	for child in quest_list.get_children():
		quest_list.remove_child(child)
		child.queue_free()
		
	# Populate with new items
	var active_quests = get_parent().get_active_quests()
	var player = get_player()

	if selected_quest != null and not active_quests.has(selected_quest):
		selected_quest = null
		clear_quest_details()
	if active_quests.size() == 0:
		clear_quest_details()
		selected_quest = null
		if player:
			player.selected_quest = null
			player.update_quest_tracker(null)
	else: 
		for quest in active_quests:
			var button = Button.new()
			button.text = quest.quest_name
			button.pressed.connect(_on_quest_button_pressed.bind(quest))
			quest_list.add_child(button)
	# Update quest tracker
	if player:
		player.update_quest_tracker(selected_quest) 
		player.selected_quest = selected_quest

func _on_quest_button_pressed(quest: Quest):
	if selected_quest == quest:
		deselect_quest()
	else:
		_on_quest_selected(quest)

func deselect_quest():
	selected_quest = null
	clear_quest_details()
	
	var player = get_player()
	if player:
		player.selected_quest = null
		player.update_quest_tracker(null)
	
func _on_quest_selected(quest: Quest):
	selected_quest = quest
	var player = get_player()
	if player:
		player.selected_quest = quest
	# Populate details
	quest_title.text = quest.quest_name
	quest_description.text = quest.quest_description
	
	# Populate objectives
	for child in quest_objectives.get_children():
		child.queue_free()
	
	for objective in quest.objectives:
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
	for child in quest_rewards.get_children():
		child.queue_free()
	
	for reward in quest.rewards:
		var label = Label.new()
		label.add_theme_color_override("font_color", Color(0, 0.84, 0))
		label.text = "Rewards: " + reward.reward_type.capitalize() 	+ ": " + str(reward.reward_amount)
		quest_rewards.add_child(label)
	
# Trigger to clear quest details
func clear_quest_details():
	quest_title.text = ""
	quest_description.text = ""
	
	for child in quest_objectives.get_children():
		quest_objectives.remove_child(child)
		
	for child in quest_rewards.get_children():
		quest_rewards.remove_child(child)
	
# Trigger to update quest list
func _on_quest_updated(quest_id: String):
	var updated_quest = quest_manager.get_quest(quest_id)

	if selected_quest and selected_quest.quest_id == quest_id:
		if updated_quest == null or updated_quest.state == "completed":
			deselect_quest()
			update_quest_list()
			return

	if selected_quest and selected_quest.quest_id == quest_id:
		_on_quest_selected(selected_quest)
	else:
		update_quest_list()
	
func _on_objectives_updated(quest_id: String, _objectives_id: String):
	if selected_quest and selected_quest.quest_id == quest_id:
		_on_quest_selected(selected_quest)
	else:
		pass
	
func _on_close_button_pressed():
	show_hide_log()

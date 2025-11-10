### QuestUI.gd

extends Control

@onready var panel = $CanvasLayer/Panel
@onready var quest_list = $CanvasLayer/Panel/Contents/Details/QuestList
@onready var quest_title = $CanvasLayer/Panel/Contents/Details/QuestDetails/QuestTitle
@onready var quest_description = $CanvasLayer/Panel/Contents/Details/QuestDetails/QuestDescription
@onready var quest_objectives = $CanvasLayer/Panel/Contents/Details/QuestDetails/QuestObjectives
@onready var quest_rewards = $CanvasLayer/Panel/Contents/Details/QuestDetails/QuestRewards

# Use LabelSettings resources instead of theme overrides for quest text
const LABEL_SETTINGS = preload("res://Art/Fonts/pixelized_label.tres")
const LABEL_SETTINGS_LARGE = preload("res://Art/Fonts/pixelized_label_large.tres")
const M3X6_PATH = "res://Art/Fonts/m3x6.ttf"

var selected_quest: Quest = null
var quest_manager
var custom_label_settings = null

func _ready():
	panel.visible = false
	clear_quest_details()

	# Ensure quest description uses the requested TTF at runtime (size 26).
	# Use LabelSettings on Godot 4, fallback to DynamicFont on Godot 3.
	var font_res = null
	if ResourceLoader.exists(M3X6_PATH):
		font_res = load(M3X6_PATH)
	if font_res:
		var ver = Engine.get_version_info()
		if ver.has("major") and ver["major"] >= 4:
			custom_label_settings = LabelSettings.new()
			custom_label_settings.font = font_res
			# LabelSettings may expose different property names across versions.
			# Safely check the property's presence via get_property_list().
			var prop_list = custom_label_settings.get_property_list()
			var has_font_size := false
			for p in prop_list:
				if p.has("name") and p["name"] == "font_size":
					has_font_size = true
					break
			if has_font_size:
				custom_label_settings.font_size = 26
			# assign to the quest_description Label
			if quest_description:
				quest_description.label_settings = custom_label_settings

	# Quest Manager/UI connection
	quest_manager = get_parent()
	quest_manager.quest_updated.connect(_on_quest_updated)
	quest_manager.objective_updated.connect(_on_objectives_updated)

# Show/hide quest log
func show_hide_log():
	panel.visible = !panel.visible
	update_quest_list()
	if selected_quest:
		_on_quest_selected(selected_quest)

# Populate quest list
func update_quest_list():
	# Remove all items
	for child in quest_list.get_children():
		quest_list.remove_child(child)
		
	# Populate with new items
	var active_quests = get_parent().get_active_quests()
	if active_quests.size() == 0:
		clear_quest_details()
		Global.player.selected_quest = null
		Global.player.update_quest_tracker(null)
	else: 
		for quest in active_quests:
			var button = Button.new()
			# Button labels: Buttons don't support LabelSettings directly, use
			# a font-size override so the button text matches the large style.
			if custom_label_settings and custom_label_settings.font:
				# Apply the runtime TTF to the button and use size 30 for the list
				button.add_theme_font_override("font", custom_label_settings.font)
				button.add_theme_font_size_override("font_size", 30)
			elif LABEL_SETTINGS_LARGE:
				button.add_theme_font_size_override("font_size", 20)
			button.text = quest.quest_name
			button.pressed.connect(_on_quest_selected.bind(quest))
			quest_list.add_child(button)
	# Update quest tracker
	Global.player.update_quest_tracker(selected_quest)
	
func _on_quest_selected(quest: Quest):
	selected_quest = quest
	Global.player.selected_quest = quest
	# Populate details
	quest_title.text = quest.quest_name
	quest_description.text = quest.quest_description
	
	# Populate objectives
	for child in quest_objectives.get_children():
		quest_objectives.remove_child(child)
	
	for objective in quest.objectives:
		var label = Label.new()
		# Apply reusable LabelSettings resource for consistent font/size
		if custom_label_settings:
			label.label_settings = custom_label_settings
		elif LABEL_SETTINGS:
			label.label_settings = LABEL_SETTINGS
		
		if objective.target_type == "collection":
			label.text = objective.description + "(" + str(objective.collected_quantity) + "/" + str(objective.required_quantity) + ")"
		else: 
			label.text = objective.description

		# Use modulate for text color so we avoid theme overrides
		if objective.is_completed:
			label.modulate = Color(0, 1, 0)
		else:
			label.modulate = Color(1, 0, 0)
		
		quest_objectives.add_child(label)
	
	# Populate rewards
	for child in quest_rewards.get_children():
		quest_rewards.remove_child(child)
	
	for reward in quest.rewards:
		var label = Label.new()
		if custom_label_settings:
			label.label_settings = custom_label_settings
		elif LABEL_SETTINGS:
			label.label_settings = LABEL_SETTINGS
		label.modulate = Color(0, 0.84, 0)
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
	if selected_quest and selected_quest.quest_id == quest_id:
		_on_quest_selected(selected_quest)
	else:
		update_quest_list()
	selected_quest = null
	Global.player.selected_quest = null
	
# Trigger to update quest details
func _on_objectives_updated(quest_id: String, _objectives_id: String):
	if selected_quest and selected_quest.quest_id == quest_id:
		_on_quest_selected(selected_quest)
	else:
		clear_quest_details()
	selected_quest = null
	Global.player.selected_quest = null
	
func _on_close_button_pressed():
	show_hide_log()

extends CharacterBase
class_name PlayerMain

@onready var fsm = $FSM as FiniteStateMachine
@onready var icon = $HUD/Coins/Icon
@onready var amount = $HUD/Coins/Amount
@onready var quest_tracker = $HUD/QuestTracker
@onready var title = $HUD/QuestTracker/Details/Title
@onready var objectives = $HUD/QuestTracker/Details/Objectives
@onready var ray_cast_2d = $RayCast2D
@onready var quest_manager: Node2D = $QuestManager
var face_direction := Vector2.DOWN
var can_move = true

# Dialog & Quest vars
var selected_quest: Quest = null
var coin_amount  = 0

func _ready():
	Global.player = self
	quest_tracker.visible = false
	update_coins()
	
	# Signal connections
	quest_manager.quest_updated.connect(_on_quest_updated)
	quest_manager.objective_updated.connect(_on_objective_updated)

func _physics_process(delta):
	if velocity != Vector2.ZERO:
		ray_cast_2d.target_position = velocity.normalized() * 50

func _input(event):
	#Interact with NPC/ Quest Item
	if can_move:
		if event.is_action_pressed("ui_interact"):
			var target = ray_cast_2d.get_collider()
			if target != null:
				if target.is_in_group("NPC"):
					can_move = false
					target.start_dialog()
					check_quest_objectives(target.npc_id, "talk_to")
				elif target.is_in_group("Item"):
					if is_item_needed(target.item_id):
						check_quest_objectives(target.item_id, "collection", target.item_quantity)
						target.queue_free()
					else: 
						print("Item not needed for any active quest.")
	# Open/close quest log
		if event.is_action_pressed("ui_quest_menu"):
			quest_manager.show_hide_log()

# Check if quest item is needed
func is_item_needed(item_id: String) -> bool:
	if selected_quest != null:
		for objective in selected_quest.objectives:
			if objective.target_id == item_id and objective.target_type == "collection" and not objective.is_completed:
				return true				
	return false
	
func check_quest_objectives(target_id: String, target_type: String, quantity: int = 1):
	# If a specific quest is selected in the UI, only try that one.
	# Otherwise, try to apply the objective to all active quests.
	var objective_updated = false
	var quests_to_check: Array = []
	if selected_quest != null:
		quests_to_check.append(selected_quest)
	else:
		# get_active_quests() returns all in-progress quests from the quest manager
		if quest_manager and quest_manager.has_method("get_active_quests"):
			quests_to_check = quest_manager.get_active_quests()

	# Track which quests we actually updated so we can report appropriately
	var updated_quests: Array = []

	# Try to complete matching objectives across the selected/active quests
	for quest in quests_to_check:
		for objective in quest.objectives:
			if objective.target_id == target_id and objective.target_type == target_type and not objective.is_completed:
				print("Completing objective for quest: ", quest.quest_name)
				quest.complete_objective(objective.id, quantity)
				objective_updated = true
				updated_quests.append(quest)
				# break inner loop to avoid double-applying to same quest
				break

	# If any objective updated, handle completions and update UI/state
	if objective_updated:
		# Handle rewards/completion for any quests that became completed
		for quest in updated_quests:
			if quest.is_completed():
				handle_quest_completion(quest)

		# If the player has a quest selected, update the tracker as before.
		if selected_quest:
			update_quest_tracker(selected_quest)
		else:
			# Player didn't open the quest log: don't show the selected-quest UI.
			# Instead print a short progress message for each updated quest.
			for quest in updated_quests:
				print("[Quest] Progressed:", quest.quest_name)

	# Return whether any objective was updated (useful for callers to decide to remove items)
	return objective_updated
	
# Player rewards
func handle_quest_completion(quest: Quest):
	for reward in quest.rewards:
		if reward.reward_type == "coins":
			coin_amount += reward.reward_amount
			update_coins()
	update_quest_tracker(quest)
	quest_manager.update_quest(quest.quest_id, "completed")
	
# Update coin UI
func update_coins():
	amount.text = str(coin_amount)
	
# Update tracker UI
func update_quest_tracker(quest: Quest):
	# if we have an active quest, populate tracker
	if quest:
		quest_tracker.visible = true
		title.text = quest.quest_name	
		
		for child in objectives.get_children():
			objectives.remove_child(child)
			
		for objective in quest.objectives:
			var label = Label.new()
			label.text = objective.description
			
			if objective.is_completed:
				label.add_theme_color_override("font_color", Color(0, 1, 0))
			else:
				label.add_theme_color_override("font_color", Color(1,0, 0))
				
			objectives.add_child(label)
	# no active quest, hide tracker		
	else:
		quest_tracker.visible = false

# Update tracker if quest is complete
func _on_quest_updated(quest_id: String):
	var quest = quest_manager.get_quest(quest_id)
	if quest == selected_quest:
		update_quest_tracker(quest)
	selected_quest = null
	
# Update tracker if objective is complete
func _on_objective_updated(quest_id: String, _objective_id: String):
	if selected_quest and selected_quest.quest_id == quest_id:
		update_quest_tracker(selected_quest)
	selected_quest = null

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
@onready var hud = $HUD
const QuestNotificationScene = preload("res://Scenes/Quest/QuestNotification.tscn")
var quest_notification = null
var face_direction := Vector2.DOWN
var can_move = true
var selected_quest: Quest = null
var coin_amount  = 0

func _enter_tree():
	# Apply any requested facing as early as possible so child nodes (like the FSM)
	# see the correct facing during their _ready()/initialization.
	if get_tree().has_meta("next_player_facing"):
		var nf = get_tree().get_meta("next_player_facing")
		if nf is Vector2:
			face_direction = nf
		elif typeof(nf) == TYPE_STRING:
			match nf:
				"up":
					face_direction = Vector2.UP
				"down":
					face_direction = Vector2.DOWN
				"left":
					face_direction = Vector2.LEFT
				"right":
					face_direction = Vector2.RIGHT
		# Clear meta so it's not reused unintentionally
		get_tree().set_meta("next_player_facing", null)
	if not Dialogic.is_connected("timeline_started", Callable(self, "_on_dialogic_timeline_started")):
		Dialogic.connect("timeline_started", Callable(self, "_on_dialogic_timeline_started"))
	if not Dialogic.is_connected("timeline_ended", Callable(self, "_on_dialogic_timeline_ended")):
		Dialogic.connect("timeline_ended", Callable(self, "_on_dialogic_timeline_ended"))
	# Listen for timeline-emitted signal events
	if not Dialogic.is_connected("signal_event", Callable(self, "_on_dialogic_signal")):
		Dialogic.connect("signal_event", Callable(self, "_on_dialogic_signal"))
	# If the timeline already started before this node entered the tree,
	# handle it now.
	if Dialogic.has_method("current_timeline") and Dialogic.current_timeline != null:
		print("PlayerMain: Dialogic already has running timeline in _enter_tree():", Dialogic.current_timeline)
		_on_dialogic_timeline_started()

func _ready():
	Global.player = self
	quest_tracker.visible = false
	update_coins()
	# Signal connections
	quest_manager.quest_updated.connect(_on_quest_updated)
	quest_manager.objective_updated.connect(_on_objective_updated)

	# Instance quest notification UI from scene so it can be edited in the editor
	if QuestNotificationScene:
		# Prefer the QuestManager as the parent for notifications so the
		# notification scene can connect to QuestManager signals (same pattern
		# as QuestUI). If QuestManager already has a child named QuestNotification
		# use that instance instead of creating a duplicate.
		var existing = null
		if quest_manager and quest_manager.has_node("QuestNotification"):
			existing = quest_manager.get_node_or_null("QuestNotification")
		if existing:
			quest_notification = existing
		else:
			quest_notification = QuestNotificationScene.instantiate()
			quest_notification.name = "QuestNotification"
			if quest_manager:
				quest_manager.add_child(quest_notification)
			else:
				# Fallback: attach to HUD to avoid losing the notification entirely
				hud.add_child(quest_notification)

func _physics_process(_delta):
	# Always update the raycast direction so interaction works while standing still.
	var direction = Vector2.ZERO

	# Prevent physics/movement updates if dialog is playing
	if not can_move:
		# Optionally zero velocity so player stops immediately
		velocity = Vector2.ZERO
		return
	if velocity != Vector2.ZERO:
		direction = velocity.normalized()
	else:
		direction = face_direction.normalized()

	ray_cast_2d.target_position = direction * 50

func _input(event):
	# Input is handled here (pause is handled globally by PauseManager autoload)
	#Interact with NPC/ Quest Item
	if can_move:
		if event.is_action_pressed("ui_interact"):
			var target = ray_cast_2d.get_collider()
			if target != null:
				if target.is_in_group("NPC"):
					print("Interacting with NPC:", target.name)
					can_move = false
					target.start_dialog()
					check_quest_objectives(target.npc_id, "talk_to")
				elif target.is_in_group("Item"):
					print("Interacting with Item:", target.name)
					if is_item_needed(target.item_id):
						check_quest_objectives(target.item_id, "collection", target.item_quantity)
						target.queue_free()
					else: 
						print("Item not needed for any active quest.")
				# Generic interactables (e.g. Bucket)
				else:
					# The raycast may hit a CollisionShape2D or the StaticBody root. The actual
					# interactive script is on a child node named "InteractionArea".
					var interaction_target = target
					# If collider doesn't expose interact(), try to find the child InteractionArea
					if not interaction_target.has_method("interact"):
						if interaction_target.has_node("InteractionArea"):
							interaction_target = interaction_target.get_node("InteractionArea")
						elif interaction_target.get_parent() and interaction_target.get_parent().has_node("InteractionArea"):
							interaction_target = interaction_target.get_parent().get_node("InteractionArea")

					if interaction_target and (interaction_target.has_method("can_interact") or interaction_target.has_method("interact")):
						print("Interacting with Object:", interaction_target.name)
						var ok = true
						if interaction_target.has_method("can_interact"):
							ok = interaction_target.can_interact()
						if ok:
							if interaction_target.has_method("interact"):
								interaction_target.interact(self)
							else:
								print("Target has no interact() method at runtime")
						else:
							print("Target cannot be interacted with right now")
	# Open/close quest log
		if event.is_action_pressed("ui_quest_menu"):
			quest_manager.show_quest_log()

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
	quest_manager.update_quest(quest.quest_id, "completed")
	
# Update coin UI
func update_coins():
	amount.text = str(coin_amount)
	
# Update tracker UI
func update_quest_tracker(quest: Quest):
	# if we have an active quest, populate tracker
	if quest:
		# Ensure tracker visible and fully opaque when showing
		if quest_tracker:
			var mq = quest_tracker.modulate
			mq.a = 1.0
			quest_tracker.modulate = mq
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
	# no active quest, fade out tracker
	else:
		hide_quest_tracker_fade()


func hide_quest_tracker_fade(duration: float = 0.28) -> void:
	# Fade out the quest tracker and then hide it. If it's already hidden, do nothing.
	if not quest_tracker or not quest_tracker.visible:
		return
	# Start a tween to fade the control's modulate alpha to 0, then hide and reset alpha
	var tw = create_tween()
	# tween_property returns a PropertyTweener; call tween_callback on the SceneTreeTween
	tw.tween_property(quest_tracker, "modulate:a", 0.0, duration)
	tw.tween_callback(Callable(self, "_on_hide_tracker_finished"))


func _on_hide_tracker_finished() -> void:
	if quest_tracker:
		quest_tracker.visible = false
		# Reset alpha back to 1 for the next show
		var mq = quest_tracker.modulate
		mq.a = 1.0
		quest_tracker.modulate = mq

# Update tracker if quest is complete
func _on_quest_updated(quest_id: String):
	var quest = quest_manager.get_quest(quest_id)
	# If the quest still exists and it's the selected one, update the tracker.
	if quest != null:
		if quest == selected_quest:
			update_quest_tracker(quest)
		# If the quest changed to completed, hide the tracker (user requested it)
		if quest.state == "completed":
			# Ensure tracker hides after completion
			update_quest_tracker(null)
			print("PlayerMain: Quest completed - hiding tracker for", quest.quest_name)
	else:
		# Quest was removed from QuestManager (likely completed) -> hide tracker
		update_quest_tracker(null)
		print("PlayerMain: Quest removed/finished - hiding tracker for id=", quest_id)

	# Reset selection
	selected_quest = null

	# Show a short notification when a quest is added/updated and is in progress
	if quest and quest.state == "in_progress" and quest_notification:
		quest_notification.show_notification(quest.quest_name)
	
# Update tracker if objective is complete
func _on_objective_updated(quest_id: String, _objective_id: String):
	if selected_quest and selected_quest.quest_id == quest_id:
		update_quest_tracker(selected_quest)
	selected_quest = null


func _on_dialogic_timeline_started() -> void:
	can_move = false

func _on_dialogic_timeline_ended() -> void:
	can_move = true
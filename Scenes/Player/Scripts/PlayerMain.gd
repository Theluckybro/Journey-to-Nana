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
@onready var interact_prompt = $InteractPrompt
@onready var interact_label = $InteractPrompt/Label
@onready var shower_particles = $ShowerParticles
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
	quest_tracker.visible = false
	Global.player = self
	if SaveLoad.SaveFileData.current_scene == get_tree().current_scene.get_scene_file_path():
		await get_tree().process_frame
		global_position = SaveLoad.SaveFileData.position
		print("Restoring player position to: ", global_position)
		face_direction = SaveLoad.SaveFileData.face_direction
		var enter_call = Callable(fsm.current_state, "Enter")
		enter_call.call_deferred()
		coin_amount = SaveLoad.SaveFileData.coin_amount

		var qm = get_node_or_null("QuestManager")
		if qm != null:
			# 1. Matikan notifikasi sementara
			quest_notification = qm.get_node_or_null("QuestNotification")
			if quest_notification:
				quest_notification.notifications_enabled = false
			
			# 2. Masukkan semua quest (Sistem akan diam karena dimatikan)
			for quest_res in SaveLoad.SaveFileData.active_quests:
				qm.load_active_quest(quest_res)
				print("Restored quest (Silent): ", quest_res.quest_name)
			
			# 3. Aktifkan kembali notifikasi
			if quest_notification:
				quest_notification.notifications_enabled = true
			
			# 4. Set ulang Selected Quest (Tracker)
			if SaveLoad.SaveFileData.selected_quest_id != "":
				var target_quest = qm.get_quest(SaveLoad.SaveFileData.selected_quest_id)
				if target_quest:
					selected_quest = target_quest
					update_quest_tracker(target_quest)
					if qm.has_method("set_selected_quest_id"):
						qm.set_selected_quest_id(target_quest.quest_id)
		else:
			print("restore_to_scene: QuestManager not found on player")
	update_coins()
	# Signal connections
	quest_manager.quest_updated.connect(_on_quest_updated)
	quest_manager.objective_updated.connect(_on_objective_updated)
	if interact_prompt:
		interact_prompt.visible = false

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
	check_interaction_prompt()

func check_interaction_prompt():
	if not can_move:
		interact_prompt.visible = false
		return
	
	if ray_cast_2d.is_colliding():
		var target = ray_cast_2d.get_collider()
		if target and (target.is_in_group("NPC") or target.is_in_group("Item") or target.is_in_group("Interactable")):
			interact_prompt.visible = true
			interact_prompt.global_position = target.global_position + Vector2(0, 0)
			return

	interact_prompt.visible = false

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
					print("Interacting with Item (Manual):", target.name)
					try_collect_item(target)
				elif target.is_in_group("Interactable"):
					print("Interacting with Interactable:", target.name)
					if target.has_method("interact"):
						target.interact(self)
	# Open/close quest log
		if event.is_action_pressed("ui_quest_menu"):
			quest_manager.show_quest_log()
	
	if event.is_action_pressed("hide_interface"):
		var layout = Dialogic.Styles.get_layout_node()
		if layout:
			for layer in layout.get_children():
				if layer is Node:
					var textbox = layer.find_child("DialogicNode_DialogText", true, false)
					if textbox:
						layer.visible = not layer.visible
						break


# Fungsi ini dipanggil oleh RayCast (Manual) DAN oleh QuestItem (Otomatis Injak)
func try_collect_item(item_node) -> void:
	# Pastikan item masih ada (valid)
	if not is_instance_valid(item_node):
		return
		
	if is_item_needed(item_node.item_id):
		check_quest_objectives(item_node.item_id, "collection", item_node.item_quantity)
		# Hapus item dari world
		item_node.queue_free()
		print("Collected item: ", item_node.name)
	else:
		# Opsional: Print debug hanya jika manual interact
		# print("Item not needed for any active quest.")
		pass

# Cek ke semua quest yang sedang aktif (in_progress)
func is_item_needed(item_id: String) -> bool:
	var active_quests = quest_manager.get_active_quests() # Ambil semua quest aktif
	
	for quest in active_quests:
		for objective in quest.objectives:
			# Cek apakah ada objektif yang butuh item ini DAN belum selesai
			if objective.target_id == item_id and objective.target_type == "collection" and not objective.is_completed:
				return true
	return false
	
# Update quest mana saja yang cocok
func check_quest_objectives(target_id: String, target_type: String, quantity: int = 1):
	var active_quests = quest_manager.get_active_quests()
	
	for quest in active_quests:
		for objective in quest.objectives:
			if objective.target_id == target_id and objective.target_type == target_type and not objective.is_completed:
				print("Updating objective for quest: ", quest.quest_name)
				
				# 1. Update datanya
				quest.complete_objective(objective.id, quantity)

				quest_manager.objective_updated.emit(quest.quest_id, objective.id)
				
				# 2. Cek apakah quest ini langsung selesai?
				if quest.is_completed():
					handle_quest_completion(quest)
				
				# 3. Update Tracker HANYA jika quest ini kebetulan sedang ditampilkan di layar
				elif selected_quest != null and selected_quest.quest_id == quest.quest_id:
					update_quest_tracker(selected_quest)
				
				# PENTING: Return (berhenti) agar 1 item tidak menghitung untuk 2 quest sekaligus.
				# (Kecuali kamu mau 1 item bisa menyelesaikan banyak quest sekaligus, hapus 'return' ini)
				return

# Player rewards
func handle_quest_completion(quest: Quest):
	for reward in quest.rewards:
		if reward.reward_type == "coins":
			coin_amount += reward.reward_amount
			update_coins()
		if reward.reward_type == "affection":
			SaveLoad.add_affection(reward.reward_amount)
			if quest_notification:
				quest_notification.show_notification("Affection +"+str(reward.reward_amount))
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
		quest_tracker.visible = false

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
	
	if quest != null:
		# Update tracker hanya jika quest yang berubah adalah quest yang sedang dilihat
		if selected_quest and selected_quest.quest_id == quest_id:
			update_quest_tracker(quest)
			
		# Jika quest selesai, baru kita sembunyikan trackernya (opsional)
		if quest.state == "completed":
			if selected_quest and selected_quest.quest_id == quest_id:
				update_quest_tracker(null)
				selected_quest = null # Reset hanya jika selesai
			print("PlayerMain: Quest completed - ", quest.quest_name)
			
			# Tampilkan notifikasi selesai (opsional jika punya UI notifikasi)
			if quest_notification:
				quest_notification.show_notification("Completed: " + quest.quest_name)

	# Hapus baris 'selected_quest = null' yang ada di kode lama!
	
	# Logic notifikasi quest baru (biarkan seperti semula)
	if quest and quest.state == "in_progress" and quest_notification:
		# Opsional: Tambahkan cek agar tidak spam notif saat load game
		pass
	
# Update tracker if objective is complete
func _on_objective_updated(quest_id: String, _objective_id: String):
	if selected_quest and selected_quest.quest_id == quest_id:
		update_quest_tracker(selected_quest)


func _on_dialogic_timeline_started() -> void:
	can_move = false

func _on_dialogic_timeline_ended() -> void:
	can_move = true

func _on_quest_tracker_button_pressed() -> void:
	quest_tracker.visible = false
	selected_quest = null
	update_quest_tracker(null)

func play_shower_cutscene() -> void:
	can_move = false
	if shower_particles:
		shower_particles.emitting = true
	await get_tree().create_timer(5.0).timeout
	shower_particles.emitting = false
	await get_tree().create_timer(0.3).timeout
	can_move = true

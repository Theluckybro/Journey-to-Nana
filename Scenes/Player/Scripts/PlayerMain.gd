extends CharacterBase
class_name PlayerMain

@onready var fsm = $FSM as FiniteStateMachine
@onready var icon = $HUD/Coins/Icon
@onready var amount = $HUD/Coins/Amount
@onready var clock_label = $HUD/Clock
@onready var quest_tracker = $HUD/QuestTracker
@onready var title = $HUD/QuestTracker/Details/Title
@onready var objectives = $HUD/QuestTracker/Details/Objectives
@onready var interact_area: Area2D = $InteractArea
@onready var quest_manager: Node2D = $QuestManager
@onready var hud = $HUD
@onready var interact_prompt = $InteractPrompt
@onready var interact_label = $InteractPrompt/Label
@onready var shower_particles = $ShowerParticles
const QuestNotificationScene = preload("res://Scenes/Quest/QuestNotification.tscn")
const PHONE_TIMELINE_NAME: String = "interactables"
const PHONE_TIMELINE_LABEL: String = "phone_hotkey"
const PHONE_LOCKED_LABEL: String = "phone_locked"
const PHONE_REPEAT_LABEL: String = "phone_repeat"
const PHONE_UNLOCK_FLAG: String = "day1_campus_intro_played"
const PHONE_UNLOCK_LEGACY_FLAG: String = "day1_classroom_intro_played"
const PHONE_ORDER_FLAG: String = "day1_food_ordered"
var quest_notification = null
var face_direction := Vector2.DOWN
var can_move = true
var selected_quest: Quest = null
var coin_amount  = 0

@export var interact_radius: float = 26.0
@export var interact_max_angle_deg: float = 100.0
@export var interact_prompt_offset: Vector2 = Vector2(0, -28)
@export var interact_target_prompt_offset: Vector2 = Vector2(0, -28)
@export var interact_switch_threshold: float = 0.25

@export var interact_outline_shader: Shader = preload("res://Shader/interact_outline.gdshader")
@export var interact_outline_size_px: float = 2.5
@export var interact_outline_color: Color = Color(0.25, 1.0, 0.9, 1.0)
@export var interact_fill_strength: float = 0.4
@export var interact_pulse_strength: float = 0.2
@export var interact_pulse_speed: float = 6.0

var _nearby_interact_targets: Array[Node2D] = []
var _current_interact_target: Node2D = null
var _current_interact_score: float = -INF

var _highlight_item: CanvasItem = null
var _highlight_original_material: Material = null
var _highlight_material: ShaderMaterial = null
var _highlight_target_node: Node2D = null
var _highlight_original_modulate: Color = Color(1, 1, 1, 1)

func _enter_tree():
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
		get_tree().set_meta("next_player_facing", null)
	if not Dialogic.is_connected("timeline_started", Callable(self, "_on_dialogic_timeline_started")):
		Dialogic.connect("timeline_started", Callable(self, "_on_dialogic_timeline_started"))
	if not Dialogic.is_connected("timeline_ended", Callable(self, "_on_dialogic_timeline_ended")):
		Dialogic.connect("timeline_ended", Callable(self, "_on_dialogic_timeline_ended"))
	if not Dialogic.is_connected("signal_event", Callable(self, "_on_dialogic_signal")):
		Dialogic.connect("signal_event", Callable(self, "_on_dialogic_signal"))
	if Dialogic.current_timeline != null and Dialogic.current_state != Dialogic.States.IDLE:
		print("PlayerMain: Dialogic already has running timeline in _enter_tree():", Dialogic.current_timeline)
		_on_dialogic_timeline_started()

func _ready():
	quest_tracker.visible = false
	Global.player = self
	if fsm and fsm.current_state == null and fsm.initial_state:
		fsm.initial_state.Enter()
		fsm.current_state = fsm.initial_state
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
	if SaveLoad and not SaveLoad.game_time_changed.is_connected(_on_game_time_changed):
		SaveLoad.game_time_changed.connect(_on_game_time_changed)
	_refresh_clock_label()
	# Signal connections
	quest_manager.quest_updated.connect(_on_quest_updated)
	quest_manager.objective_updated.connect(_on_objective_updated)
	if interact_prompt:
		interact_prompt.visible = false
	if interact_area:
		interact_area.body_entered.connect(_on_interact_area_body_entered)
		interact_area.body_exited.connect(_on_interact_area_body_exited)
		interact_area.area_entered.connect(_on_interact_area_area_entered)
		interact_area.area_exited.connect(_on_interact_area_area_exited)
		_apply_interact_radius_to_area_shape()

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
	# Removed auto-alarm on start

func _exit_tree() -> void:
	if SaveLoad and SaveLoad.game_time_changed.is_connected(_on_game_time_changed):
		SaveLoad.game_time_changed.disconnect(_on_game_time_changed)

func _refresh_clock_label() -> void:
	if not clock_label:
		return
	clock_label.text = SaveLoad.get_time_string()

func _on_game_time_changed(_hour: int, _minute: int, formatted_time: String) -> void:
	if not clock_label:
		return
	clock_label.text = formatted_time

func _is_dialogic_busy() -> bool:
	return Dialogic.current_timeline != null and Dialogic.current_state != Dialogic.States.IDLE

func _is_phone_unlocked() -> bool:
	return SaveLoad.check_flag(PHONE_UNLOCK_FLAG) or SaveLoad.check_flag(PHONE_UNLOCK_LEGACY_FLAG)

func _open_phone_hotkey() -> void:
	if _is_dialogic_busy():
		return

	if not _is_phone_unlocked():
		Dialogic.start(PHONE_TIMELINE_NAME, PHONE_LOCKED_LABEL)
		return

	if SaveLoad.check_flag(PHONE_ORDER_FLAG):
		Dialogic.start(PHONE_TIMELINE_NAME, PHONE_REPEAT_LABEL)
		return

	if AudioManager and AudioManager.KEYBOARD_TYPING_SOUND:
		AudioManager.play_sound(AudioManager.KEYBOARD_TYPING_SOUND, 0.0, -6.0)

	if SaveLoad.get_time_total_minutes() < (14 * 60 + 30):
		SaveLoad.set_time(14, 30)

	Dialogic.start(PHONE_TIMELINE_NAME, PHONE_TIMELINE_LABEL)

func _physics_process(_delta):
	# Prevent physics/movement updates if dialog is playing
	if not can_move:
		# Optionally zero velocity so player stops immediately
		velocity = Vector2.ZERO
		return
	check_interaction_prompt()

func check_interaction_prompt():
	if not can_move:
		interact_prompt.visible = false
		_set_highlight_target(null)
		return

	_refresh_interact_candidates_by_distance()
	
	_current_interact_target = _pick_best_interact_target()
	if _current_interact_target:
		interact_prompt.visible = true
		interact_prompt.global_position = _get_interact_prompt_world_pos(_current_interact_target)
		_set_highlight_target(_current_interact_target)
	else:
		interact_prompt.visible = false
		_set_highlight_target(null)

func _pick_best_interact_target() -> Node2D:
	# Filter invalid nodes first.
	for i in range(_nearby_interact_targets.size() - 1, -1, -1):
		if not is_instance_valid(_nearby_interact_targets[i]):
			_nearby_interact_targets.remove_at(i)

	if _nearby_interact_targets.is_empty():
		_current_interact_score = -INF
		return null

	var facing := face_direction
	if velocity != Vector2.ZERO:
		facing = velocity
	facing = facing.normalized()

	var cos_limit := cos(deg_to_rad(interact_max_angle_deg))
	var best: Node2D = null
	var best_score := -INF

	var current_valid := false
	var current_score := -INF
	if _current_interact_target and is_instance_valid(_current_interact_target) and _nearby_interact_targets.has(_current_interact_target):
		if _is_valid_interact_target(_current_interact_target):
			current_valid = true
			current_score = _score_target(_current_interact_target, facing, cos_limit)

	for node in _nearby_interact_targets:
		if node == null or not is_instance_valid(node):
			continue
		if not _is_valid_interact_target(node):
			continue

		var score := _score_target(node, facing, cos_limit)
		if score > best_score:
			best_score = score
			best = node

	# Hysteresis: keep current unless the new one is clearly better.
	if current_valid:
		if best == null:
			_current_interact_score = current_score
			return _current_interact_target
		if _current_interact_target == best:
			_current_interact_score = best_score
			return best
		if current_score >= best_score - interact_switch_threshold:
			_current_interact_score = current_score
			return _current_interact_target

	_current_interact_score = best_score
	return best

func _is_valid_interact_target(node: Node2D) -> bool:
	return node.is_in_group("NPC") or node.is_in_group("Item") or node.is_in_group("Interactable")

func _score_target(node: Node2D, facing: Vector2, cos_limit: float) -> float:
	var to_target := _get_interact_target_world_pos(node) - global_position
	var dist := to_target.length()
	if dist <= 0.001:
		dist = 0.001

	var dir := to_target / dist
	var dot := 0.0
	if facing != Vector2.ZERO:
		dot = facing.dot(dir)
		if dot < cos_limit:
			return -INF

	# Score: prefer in-front and nearer.
	return dot * 2.0 + (1.0 / dist)

func _get_interact_target_world_pos(target: Node2D) -> Vector2:
	if target.has_method("get_interact_world_pos"):
		var custom_pos: Variant = target.call("get_interact_world_pos")
		if custom_pos is Vector2:
			return custom_pos

	var collision_shape := target.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape:
		return collision_shape.global_position

	var nested_shape := target.find_child("CollisionShape2D", true, false) as CollisionShape2D
	if nested_shape:
		return nested_shape.global_position

	return target.global_position

func _get_interact_prompt_world_pos(target: Node2D) -> Vector2:
	# Let targets override where the prompt should appear.
	if target.has_method("get_interact_prompt_world_pos"):
		var v: Variant = target.call("get_interact_prompt_world_pos")
		if v is Vector2:
			return v
	return _get_interact_target_world_pos(target) + interact_target_prompt_offset

func _set_highlight_target(target: Node2D) -> void:
	if target == _highlight_target_node and _highlight_item != null:
		return

	# Clear previous highlight.
	if _highlight_item and is_instance_valid(_highlight_item):
		_highlight_item.material = _highlight_original_material
		_highlight_item.modulate = _highlight_original_modulate
	_highlight_item = null
	_highlight_original_material = null
	_highlight_target_node = null
	_highlight_original_modulate = Color(1, 1, 1, 1)

	if target == null or not is_instance_valid(target):
		return

	var canvas_item := _find_canvas_item_for_highlight(target)
	if canvas_item == null:
		return

	_highlight_target_node = target
	_highlight_item = canvas_item
	_highlight_original_material = canvas_item.material
	_highlight_original_modulate = canvas_item.modulate

	if _highlight_material == null:
		_highlight_material = ShaderMaterial.new()
	if interact_outline_shader != null:
		_highlight_material.shader = interact_outline_shader
		_highlight_material.set_shader_parameter("outline_size_px", interact_outline_size_px)
		_highlight_material.set_shader_parameter("outline_color", interact_outline_color)
		_highlight_material.set_shader_parameter("fill_strength", interact_fill_strength)
		_highlight_material.set_shader_parameter("pulse_strength", interact_pulse_strength)
		_highlight_material.set_shader_parameter("pulse_speed", interact_pulse_speed)
		canvas_item.material = _highlight_material

	var tint := _highlight_original_modulate.lerp(interact_outline_color, 0.55)
	tint.a = _highlight_original_modulate.a
	canvas_item.modulate = tint

func _find_canvas_item_for_highlight(node: Node) -> CanvasItem:
	# Prefer highlighting the node itself if possible.
	if node is CanvasItem:
		return node as CanvasItem

	# Otherwise find the first Sprite-ish child.
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		for child in cur.get_children():
			if child is AnimatedSprite2D:
				return child as CanvasItem
			if child is Sprite2D:
				return child as CanvasItem
			if child is TextureRect:
				return child as CanvasItem
			if child is CanvasItem:
				# Fallback to any CanvasItem if no obvious sprite found.
				return child as CanvasItem
			stack.append(child)
	return null

func _apply_interact_radius_to_area_shape() -> void:
	var area_shape := interact_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if area_shape == null:
		return
	var circle_shape := area_shape.shape as CircleShape2D
	if circle_shape == null:
		return
	circle_shape.radius = interact_radius

func _refresh_interact_candidates_by_distance() -> void:
	_nearby_interact_targets.clear()
	_append_group_candidates("NPC")
	_append_group_candidates("Item")
	_append_group_candidates("Interactable")

func _append_group_candidates(group_name: String) -> void:
	for node in get_tree().get_nodes_in_group(group_name):
		if node == self:
			continue
		var n2d := node as Node2D
		if n2d == null or not is_instance_valid(n2d):
			continue
		if not _is_within_interact_radius(n2d):
			continue
		if not _nearby_interact_targets.has(n2d):
			_nearby_interact_targets.append(n2d)

func _is_within_interact_radius(node: Node2D) -> bool:
	return global_position.distance_to(_get_interact_target_world_pos(node)) <= interact_radius

func _input(event):
	# Input is handled here (pause is handled globally by PauseManager autoload)
	#Interact with NPC/ Quest Item
	if can_move:
		if event.is_action_pressed("ui_phone"):
			_open_phone_hotkey()
			return

		if event.is_action_pressed("ui_interact"):
			var target = _current_interact_target
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

func set_sleep_pose() -> void:
	var anim_player = get_node_or_null("AnimationPlayer") as AnimationPlayer
	var sprite_node = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

	if anim_player:
		anim_player.stop()

	if sprite_node:
		sprite_node.animation = "Sleep"
		sprite_node.frame = 0
		sprite_node.flip_v = true
		sprite_node.play()

func play_idle_right() -> void:
	var anim_player = get_node_or_null("AnimationPlayer") as AnimationPlayer

	if anim_player:
		anim_player.play("IdleRight")

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
	if SaveLoad:
		SaveLoad.set_flag(quest.quest_id + "_completed", true)
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
	var quest: Quest = quest_manager.get_quest(quest_id)
	if quest == null:
		return

	if selected_quest and selected_quest.quest_id == quest_id:
		update_quest_tracker(selected_quest)

	if quest.quest_id == "get_ready_001" and quest_notification:
		var completed_count: int = 0
		var total_count: int = quest.objectives.size()
		for objective in quest.objectives:
			if objective.is_completed:
				completed_count += 1

		var progress_text: String = "Objective Updated (" + str(completed_count) + "/" + str(total_count) + " Complete)"
		quest_notification.show_notification(progress_text, "System Message")

func _on_dialogic_signal(argument: Variant) -> void:
	if typeof(argument) != TYPE_STRING:
		return

	if argument == "phone_order_geprek":
		var is_first_order: bool = not SaveLoad.check_flag(PHONE_ORDER_FLAG)
		if is_first_order:
			SaveLoad.set_flag(PHONE_ORDER_FLAG, true)
		if AudioManager and AudioManager.MOUSE_CLICK_SOUND:
			AudioManager.play_sound(AudioManager.MOUSE_CLICK_SOUND, 0.0, -8.0)
		if AudioManager and AudioManager.SHOPEE_BELL_SOUND:
			AudioManager.play_sound(AudioManager.SHOPEE_BELL_SOUND, 0.0, -8.0)

		if not is_first_order:
			return

		if _is_dialogic_busy():
			await Dialogic.timeline_ended

		if TimeskipManager and TimeskipManager.has_method("trigger_food_delivery_timeskip"):
			await TimeskipManager.trigger_food_delivery_timeskip(self)
		elif quest_notification:
			SaveLoad.set_time(15, 15)
			quest_notification.show_notification("Pesanan Ayam Geprek otw", "System Message")


func _on_dialogic_timeline_started() -> void:
	can_move = false

func _on_dialogic_timeline_ended() -> void:
	can_move = true

func _on_quest_tracker_button_pressed() -> void:
	quest_tracker.visible = false
	selected_quest = null
	update_quest_tracker(null)

func play_shower_cutscene() -> void:
	if shower_particles:
		shower_particles.emitting = true
	await get_tree().create_timer(5.0).timeout
	shower_particles.emitting = false
	


func _on_interact_area_body_entered(body: Node) -> void:
	_try_add_interact_candidate(body)

func _on_interact_area_body_exited(body: Node) -> void:
	_try_remove_interact_candidate(body)

func _on_interact_area_area_entered(area: Area2D) -> void:
	_try_add_interact_candidate(area)

func _on_interact_area_area_exited(area: Area2D) -> void:
	_try_remove_interact_candidate(area)

func _try_add_interact_candidate(node: Node) -> void:
	var n2d := node as Node2D
	if n2d == null:
		return
	if not _nearby_interact_targets.has(n2d):
		_nearby_interact_targets.append(n2d)

func _try_remove_interact_candidate(node: Node) -> void:
	var n2d := node as Node2D
	if n2d == null:
		return
	var idx := _nearby_interact_targets.find(n2d)
	if idx != -1:
		_nearby_interact_targets.remove_at(idx)
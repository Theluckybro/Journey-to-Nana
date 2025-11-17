extends Node


const SAVE_FILE_PATH := "user://SaveFile.json"

const QuestScript = preload("res://Resources/Quest/Quests.gd")
const ObjectiveScript = preload("res://Resources/Quest/Objectives.gd")

var contents_to_save : Dictionary = {
	# Versioning helps future compatibility when the save format changes
	"version": 1,

	# Player related state
	"player": {
		"position": Vector2.ZERO,
		"face_direction": Vector2.DOWN,
		"can_move": true,
		"coin_amount": 0,
		"selected_quest_id": "",
	},

	# Global game state
	"game": {
		"money": 0
	},

	# Scene / navigation state
	"scene": {
		"current_scene": "",
		"last_scene": "",
	},

	# Quest state
	"quests": [],

	# Audio / settings state (volume 0-100, mute boolean)
	"audio": {
		"volume": 50.0,
		"mute": false
	},

	# Video / display settings
	"video": {
		"mode": "windowed",
		"window_size": Vector2(640, 360)
	}
}

func _ready() -> void:
	_load()

func _save() -> void:
	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	file.store_var(contents_to_save.duplicate())
	file.close()

func _load() -> void:
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		var data = file.get_var()
		file.close()

		var save_data = data.duplicate()

		if typeof(save_data) == TYPE_DICTIONARY:
			contents_to_save = save_data.duplicate()


func _has_property(obj, prop_name: String) -> bool:
	if obj == null:
		return false
	# get_property_list returns an Array of Dictionaries with a 'name' key
	# Use it to safely check whether the object exposes a given property
	var plist = obj.get_property_list()
	for entry in plist:
		if entry.get("name", "") == prop_name:
			return true
	return false


func restore_to_scene() -> void:
	# Run from the persistent SaveLoad autoload so this continues after scene changes.
	var tree = get_tree()
	# Wait a few frames (with a timeout) so the newly-loaded scene has been set.
	var max_wait_frames: int = 10
	var waited: int = 0
	var current_scene = tree.current_scene
	while current_scene == null and waited < max_wait_frames:
		await tree.process_frame
		waited += 1
		current_scene = tree.current_scene

	if current_scene == null:
		push_warning("SaveLoad.restore_to_scene: current_scene is still null after waiting " + str(max_wait_frames) + " frames")
		return

	print("Restore: current scene = ", current_scene.get_scene_file_path())

	var player = null

	# Prefer the autoloaded SceneTransition's player reference when available
	player = SceneTransition.player

	# Fallback: common path inside the scene
	if player == null:
		player = current_scene.get_node_or_null("Scene/Characters/Player")

	var saved_player = contents_to_save.get("player", {})
	if typeof(saved_player) == TYPE_DICTIONARY:
		print("Restoring player data...")

		if saved_player.has("position"):
			player.global_position = saved_player["position"]
		if saved_player.has("face_direction") and _has_property(player, "face_direction"):
			player.face_direction = saved_player["face_direction"]

			if player.fsm and player.fsm.current_state:
				var enter_call = Callable(player.fsm.current_state, "Enter")
				enter_call.call_deferred()
		if saved_player.has("can_move") and _has_property(player, "can_move"):
			player.can_move = saved_player["can_move"]
		if saved_player.has("coin_amount") and _has_property(player, "coin_amount"):
			player.coin_amount = saved_player["coin_amount"]
		
	# Restore quest state
	print("Quests: ", contents_to_save["quests"])

	# If quests were saved as plain Dictionaries, reconstruct Quest resources
	var saved_quests = contents_to_save.get("quests", [])
	if typeof(saved_quests) == TYPE_ARRAY and saved_quests.size() > 0:
		# Ensure we have a player and its quest_manager available
		var pm = player
		var qm = null
		if pm:
			var waited_q:int = 0
			while (pm.quest_manager == null and waited_q < max_wait_frames):
				await tree.process_frame
				waited_q += 1
			qm = pm.quest_manager
		
		if qm:
			print("Restoring ", saved_quests.size(), " quests into QuestManager...")
			for sq in saved_quests:
				if typeof(sq) != TYPE_DICTIONARY:
					continue
				var new_q = QuestScript.new()
				new_q.quest_id = sq.get("quest_id", "")
				new_q.state = sq.get("state", "not_started")
				new_q.quest_name = sq.get("quest_name", "")
				new_q.quest_description = sq.get("quest_description", "")
				var s_objs = sq.get("objectives", [])
				if typeof(s_objs) == TYPE_ARRAY:
					for so in s_objs:
						if typeof(so) != TYPE_DICTIONARY:
							continue
						var new_o = ObjectiveScript.new()
						new_o.id = so.get("id", "")
						new_o.description = so.get("description", "")
						new_o.target_id = so.get("target_id", "")
						new_o.target_type = so.get("target_type", "")
						new_o.required_quantity = so.get("required_quantity", 0)
						new_o.collected_quantity = so.get("collected_quantity", 0)
						new_o.is_completed = so.get("is_completed", false)
						new_q.objectives.append(new_o)
				# Add reconstructed quest to the manager
				qm.add_quest(new_q)
			print("Quests restored into QuestManager.")
		else:
			print("Warning: player.quest_manager not available; quests not restored to manager.")

	GameManager.money = contents_to_save.get("game", {}).get("money", GameManager.money)

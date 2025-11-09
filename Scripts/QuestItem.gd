### QuestItem.gd
@tool
extends Area2D

@onready var sprite_2d = $Sprite2D

# Vars
@export var item_id: String = ""
@export var item_quantity: int = 1
@export var item_icon = Texture2D

func _ready():
	# Show texture in game
	if not Engine.is_editor_hint():
		sprite_2d.texture = item_icon

	# Listen for bodies entering so the player can pick up by standing on the item
	# (Area2D signal). We connect in code so the scene doesn't need a manual signal
	# hookup.
	if not Engine.is_editor_hint():
		self.connect("body_entered", Callable(self, "_on_body_entered"))

func _process(_delta):
	# Show texture in engine
	if Engine.is_editor_hint():
		sprite_2d.texture = item_icon


func start_interact():
	print("I am an item!")


func _on_body_entered(body):
	# Only run during game runtime
	if Engine.is_editor_hint():
		return

	# Prefer the global player reference if present (check directly for player)
	var player = null
	if Global and Global.player:
		player = Global.player

	# If the entering body is the player (or in Player group), attempt collection
	if (player and body == player) or (body and body.has_method("is_in_group") and body.is_in_group("Player")):
		# Use player's API if available
		if player:
			if player.is_item_needed(item_id):
				player.check_quest_objectives(item_id, "collection", item_quantity)
				queue_free()
			else:
				print("Item not needed for any active quest.")
		else:
			# Fallback: if the body implements the same API, call it
			if body.has_method("is_item_needed") and body.is_item_needed(item_id):
				body.check_quest_objectives(item_id, "collection", item_quantity)
				queue_free()
			else:
				print("Item not needed or player API unavailable.")

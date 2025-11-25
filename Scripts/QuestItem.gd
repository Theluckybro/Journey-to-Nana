### QuestItem.gd
@tool
extends Area2D

# Vars
@export var item_id: String = ""
@export var item_quantity: int = 1
@export var item_icon: Texture2D = null
@onready var sprite_2d = $Sprite2D

func _ready():
	# Shows texture in game
	if not Engine.is_editor_hint():
		sprite_2d.set_texture(item_icon)

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _process(_delta):
	# Show texture in engine
	if Engine.is_editor_hint():
		sprite_2d.set_texture(item_icon)

func _on_body_entered(body):
	if body is PlayerMain:
		# Panggil fungsi baru di player untuk mencoba mengambil item ini
		body.try_collect_item(self)

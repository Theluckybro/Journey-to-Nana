@tool
extends Area2D


@onready var sprite_2d = $Sprite2D


@export var item_id: String = ""
@export var item_quantity: int = 1
@export var item_icon = Texture2D

func _ready():
	if not Engine.is_editor_hint():
		sprite_2d.texture = item_icon

func _process(delta):
	if Engine.is_editor_hint():
		sprite_2d.texture = item_icon

func start_interact():
	print("I am an item!")

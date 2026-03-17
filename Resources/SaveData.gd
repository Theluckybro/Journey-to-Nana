extends Resource
class_name SaveDataResource

@export var version:int = 0

@export var flags: Dictionary = {}

@export var affection: int = 0

@export_group("Player Data")
@export var position: Vector2 = Vector2.ZERO
@export var face_direction: Vector2 = Vector2.DOWN
@export var coin_amount: int = 0
@export var selected_quest_id: String = ""
@export var active_quests: Array = []

@export_group("Game")
@export var current_scene: String = ""
@export var last_scene: String = ""
@export var current_hour: int = 6
@export var current_minute: int = 30
extends CharacterBase
class_name PlayerMain

@onready var fsm = $FSM as FiniteStateMachine
@onready var icon = $HUD/Coins/Icon
@onready var amount = $HUD/Coins/Amount
@onready var quest_tracker = $HUD/QuestTracker
@onready var title = $HUD/QuestTracker/Details/Title
@onready var objectives = $HUD/QuestTracker/Details/Objectives
@onready var ray_cast_2d = $RayCast2D
var face_direction := Vector2.DOWN
var can_move = true

func _ready():
	Global.player = self
	quest_tracker.visible = false

func _physics_process(delta):
	if velocity != Vector2.ZERO:
		ray_cast_2d.target_position = velocity.normalized() * 50

func _input(event):
	#Interact with NPC/ Quest Item
	if can_move:
		if event.is_action_pressed("Interact"):
			var target = ray_cast_2d.get_collider()
			if target != null:
				if target.is_in_group("NPC"):
					print("I'm talking to an NPC!")
					can_move = false
					target.start_dialog()
				elif target.is_in_group("Item"):
					print("I'm interacting with an item!")
					# todo: check if item is needed for quest
					# todo: remove item
					target.start_interact()	

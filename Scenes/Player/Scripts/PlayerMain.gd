extends CharacterBase
class_name PlayerMain

@onready var fsm = $FSM as FiniteStateMachine

var face_direction := Vector2.DOWN

func _ready():
	DialogueManager.player = self

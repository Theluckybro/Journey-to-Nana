extends State
class_name PlayerIdle

@export var animator : AnimationPlayer

var player : PlayerMain

func Enter():
	player = get_tree().get_first_node_in_group("Player") as PlayerMain
	# animator.play("Idle")
	if player.face_direction.x < 0:
		animator.play("IdleLeft")
	elif player.face_direction.x > 0:
		animator.play("IdleRight")
	elif player.face_direction.y < 0:
		animator.play("IdleUp")
	else:
		animator.play("IdleDown")
		
	# Hapus kode lama: animator.play("Idle")
	pass
	
func Update(_delta : float):
	if(Input.get_vector("MoveLeft", "MoveRight", "MoveUp", "MoveDown").normalized()):
		state_transition.emit(self, "Moving")
		
	if Input.is_action_just_pressed("Punch")  or Input.is_action_just_pressed("Kick"):
		state_transition.emit(self, "Attacking")

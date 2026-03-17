extends State
class_name PlayerIdle

@export var animator: AnimationPlayer

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
	pass
	
func Update(_delta : float):
	if player.can_move:
		if Input.get_vector("MoveLeft", "MoveRight", "MoveUp", "MoveDown") != Vector2.ZERO:
			state_transition.emit(self, "Moving")

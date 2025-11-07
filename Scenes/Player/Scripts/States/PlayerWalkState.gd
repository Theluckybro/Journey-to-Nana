extends State
class_name PlayerWalking

@export var movespeed := int(350)

# --- Variabel Dash Dihapus ---

var player : PlayerMain 
@export var animator : AnimationPlayer

func Enter():
	player = get_tree().get_first_node_in_group("Player") as PlayerMain
	play_animation_from_direction(player.face_direction)

func Update(delta : float):
	var input_dir = Input.get_vector("MoveLeft", "MoveRight", "MoveUp", "MoveDown").normalized()
	Move(input_dir)
		
	if Input.is_action_just_pressed("Punch") or Input.is_action_just_pressed("Kick"):
		Transition("Attacking")

func Move(input_dir : Vector2):

	player.velocity = input_dir * movespeed
	player.move_and_slide()

	if(input_dir != Vector2.ZERO):
		player.face_direction = input_dir

		play_animation_from_direction(input_dir)
	else:
		Transition("Idle")

func play_animation_from_direction(direction : Vector2):
	if direction.x < 0:
		animator.play("WalkLeft")
	elif direction.x > 0:
		animator.play("WalkRight")
	elif direction.y < 0:
		animator.play("WalkUp")
	elif direction.y > 0:
		animator.play("WalkDown")

func Transition(newstate : String):
	state_transition.emit(self, newstate)

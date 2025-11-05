extends State
class_name PlayerWalking

@export var movespeed := int(350)
@export var dash_max := int(500)
var dashspeed := float(100)
var can_dash := bool(false)
var dash_direction := Vector2(0,0)

var player : PlayerMain
@export var animator : AnimationPlayer

func Enter():
	player = get_tree().get_first_node_in_group("Player") as PlayerMain
	# animator.play("Walk")
	play_animation_from_direction(player.face_direction)
	

func Update(delta : float):
	var input_dir = Input.get_vector("MoveLeft", "MoveRight", "MoveUp", "MoveDown").normalized()
	Move(input_dir)
	LessenDash(delta)

	if(Input.is_action_just_pressed("Dash") && can_dash):
		start_dash(input_dir)
		
	if Input.is_action_just_pressed("Punch") or Input.is_action_just_pressed("Kick"):
		Transition("Attacking")
	
func Move(input_dir : Vector2):
	#Suddenly turning mid dash
	if(dash_direction != Vector2.ZERO and dash_direction != input_dir):
		dash_direction = Vector2.ZERO
		dashspeed = 0

	player.velocity = input_dir * movespeed + dash_direction * dashspeed 
	player.move_and_slide()

	if(input_dir != Vector2.ZERO):
		# 1. Update "memori" face_direction di PlayerMain
		player.face_direction = input_dir

		# 2. Mainkan animasi berjalan yang sesuai
		play_animation_from_direction(input_dir)
	else:
		# 3. Jika berhenti bergerak, transisi ke Idle
		if(dashspeed <= 0): # Hanya transisi jika tidak sedang dash
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

func start_dash(input_dir : Vector2):
	AudioManager.play_sound(AudioManager.PLAYER_ATTACK_SWING, 0.3, -1)
	dash_direction = input_dir.normalized()
	dashspeed = dash_max
	animator.play("Dash")
	can_dash = false

func LessenDash(delta : float):
	#Higher multiplier values makes the dash shorter
	var multiplier : float = 4.0
	var timemultiplier : float = 4.1
	
	#slow down the dash over time, both as a fraction of dashspeed and also time
	#While clamping it between 0 and dash_max
	dashspeed -= (dashspeed * multiplier * delta) + (delta * timemultiplier)
	dashspeed = clamp(dashspeed, 0, dash_max)
	
	if(dashspeed <= 0):
		can_dash = true
		dash_direction = Vector2.ZERO
		
	if(animator.current_animation == "Dash"):
		await animator.animation_finished
		animator.play("Walk")

#We cannot allow a transition before the dash is complete and the animation has stopped playing
func Transition(newstate : String):
	if(dashspeed <= 0):
		state_transition.emit(self, newstate)

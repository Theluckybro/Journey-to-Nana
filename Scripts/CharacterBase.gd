extends CharacterBody2D
class_name CharacterBase

@export var sprite : AnimatedSprite2D
@export var flipped_horizontal : bool

func _ready():
	pass
	
func _process(_delta):
	pass

#Flip charater sprites based on their current velocity
func Turn():
	#This ternary lets us flip a sprite if its drawn the wrong way
	var direction = -1 if flipped_horizontal == true else 1
	
	if(velocity.x < 0):
		sprite.scale.x = -direction
	elif(velocity.x > 0):
		sprite.scale.x = direction

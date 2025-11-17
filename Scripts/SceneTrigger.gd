extends Area2D

## Scene tujuan saat player memasuki trigger
@export var destination_scene: String

enum Direction {
	UP,
	RIGHT,
	DOWN,
	LEFT
	}

## Arah player menghadap setelah pindah scene
@export var facing_choice: Direction

func get_facing_vector() -> Vector2:
	match facing_choice:
		Direction.UP:
			return Vector2.UP
		Direction.RIGHT:
			return Vector2.RIGHT
		Direction.DOWN:
			return Vector2.DOWN
		Direction.LEFT:
			return Vector2.LEFT
	return Vector2.UP

func _on_body_entered(body: Node2D) -> void:
	if body is PlayerMain:
		SceneTransition.change_scene(body, destination_scene, get_facing_vector())


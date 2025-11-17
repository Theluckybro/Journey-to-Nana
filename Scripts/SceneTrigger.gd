extends Area2D

@export var destination_scene: String


func _on_body_entered(body: Node2D) -> void:
	if body is PlayerMain:
		SceneTransition.change_scene(body, destination_scene, Vector2.UP)
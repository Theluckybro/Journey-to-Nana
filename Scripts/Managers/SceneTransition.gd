extends Node

var player: PlayerMain
var last_scene_name: String

var scene_path = "res://Scenes/Levels/"


func handle_door_exited(_body: Node) -> void:
	pass

func change_scene(player_node: Node, destination_scene: String, _facing: Vector2) -> void:
	var cur_scene = get_tree().get_current_scene()
	if cur_scene:
		last_scene_name = cur_scene.name
	elif player_node and player_node.get_parent():
		last_scene_name = player_node.get_parent().name
	else:
		last_scene_name = ""

	player = player_node as PlayerMain

	var parent = player.get_parent()
	if parent:
		parent.remove_child(player)


	var full_path = scene_path + destination_scene + ".tscn"
	get_tree().call_deferred("change_scene_to_file", full_path)

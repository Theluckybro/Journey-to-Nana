extends Node

var previous_scene: String = ""

func set_previous(path: String) -> void:
    previous_scene = path

func clear() -> void:
    previous_scene = ""

func get_previous() -> String:
    return previous_scene

extends Area2D

@export var interaction_id: String = "cupboard"
@export var interaction_type: String = "action"
@export var interaction_quantity: int = 1

var _initiating_player: Node = null

func interact(by_player: Node = null) -> void:
	if Engine.is_editor_hint():
		return

	var player = by_player
	if player == null and Global and Global.player:
		player = Global.player

	if player == null:
		return

	if player == Global.player or (player.has_method("is_in_group") and player.is_in_group("Player")):
		_initiating_player = player
		Dialogic.start("interactables", "cupboard")
		if not Dialogic.is_connected("signal_event", Callable(self, "_on_dialogic_signal")):
			Dialogic.connect("signal_event", Callable(self, "_on_dialogic_signal"))
		return

func _on_dialogic_signal(argument: String):
	if argument == "cupboard_yes":
		print("Player chose to change clothes")
		_initiating_player.check_quest_objectives(interaction_id, interaction_type, interaction_quantity)
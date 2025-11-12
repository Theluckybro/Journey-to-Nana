extends Node2D

func _ready():
    # Sambungkan handler untuk event signal dari Dialogic sebelum memulai timeline
    # CONNECT_ONE_SHOT agar hanya dipanggil sekali
    Dialogic.signal_event.connect(_on_dialogic_signal, CONNECT_ONE_SHOT)

    # Mulai timeline gamestart (memastikan layout/dialog scene di-load)
    Dialogic.start("gamestart")

func _on_gamestart_ended():
    # Deprecated: timeline_ended handler kept for backwards compatibility.
    # Prefer using Dialogic signal event (see _on_dialogic_signal).
    if Engine.has_singleton("QuestSpawner"):
        QuestSpawner.spawn_bath_quest()
    else:
        var Spawner = load("res://Scripts/Quest/QuestSpawner.gd")
        var sp = Spawner.new()
        sp.spawn_bath_quest()

func _on_dialogic_signal(argument: Variant) -> void:
    # Timeline emits Dialogic.signal_event with the argument we placed in the timeline.
    if typeof(argument) == TYPE_STRING and argument == "get_ready":
        if Engine.has_singleton("QuestSpawner"):
            QuestSpawner.spawn_get_ready_quest()
        else:
            var Spawner = load("res://Scripts/Quest/QuestSpawner.gd")
            var sp = Spawner.new()
            sp.spawn_get_ready_quest()
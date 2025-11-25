extends Node2D
func _ready():
    $AnimationPlayer.play("float")
    await $AnimationPlayer.animation_finished
    queue_free()
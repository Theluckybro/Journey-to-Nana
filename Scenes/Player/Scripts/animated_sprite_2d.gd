extends AnimatedSprite2D

@onready var _silhouette_sprite: Sprite2D = $SilhouetteSprite

func _ready() -> void:
	animation_changed.connect(_update_silhouette_texture)
	frame_changed.connect(_update_silhouette_texture)

	# These properties DO exist on AnimatedSprite2D
	_silhouette_sprite.offset = self.offset
	_silhouette_sprite.flip_h = self.flip_h

	# The silhouette is a simple Sprite2D showing one frame.
	# Its own hframes/vframes should be 1, and its frame should be 0.
	_silhouette_sprite.hframes = 1
	_silhouette_sprite.vframes = 1
	_silhouette_sprite.frame = 0

	# Manually update the texture one time on ready
	_update_silhouette_texture()

# This function gets the current animation frame and gives it to the silhouette
func _update_silhouette_texture() -> void:
	if !is_instance_valid(_silhouette_sprite):
		return
		
	# Check if sprite_frames and the animation exist
	if self.sprite_frames and self.sprite_frames.has_animation(self.animation):
		# Get the texture for the *current* animation and *current* frame
		_silhouette_sprite.texture = self.sprite_frames.get_frame_texture(self.animation, self.frame)

# We use _set to detect when the parent's properties change
func _set(property: StringName, value: Variant) -> bool:
	if is_instance_valid(_silhouette_sprite):
		match property:
			"offset":
				_silhouette_sprite.offset = value
			"flip_h":
				_silhouette_sprite.flip_h = value
			
			# When the animation *name* changes (e.g., "idle" -> "walk")
			"animation":
				_update_silhouette_texture() # Update the texture when animation changes
				return false

			# When the animation *frame* changes (e.g., frame 1 -> 2)
			"frame":
				_update_silhouette_texture() # Update the texture when frame changes
				return false

	# Return false to allow Godot to set the property normally
	return false

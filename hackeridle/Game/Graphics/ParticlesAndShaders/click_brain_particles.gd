extends CPUParticles2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	emitting = true
	one_shot = true

	pass # Replace with function body.

func _on_finished() -> void:
	self.queue_free()
	pass # Replace with function body.

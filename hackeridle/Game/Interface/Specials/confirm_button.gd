extends Button

signal s_pressed
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func disable():
	self.disabled = true

func enable():
	self.disabled = false


func _on_pressed() -> void:
	s_pressed.emit()
	pass # Replace with function body.

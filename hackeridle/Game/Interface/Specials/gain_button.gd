extends Button

@export var value_negative: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func set_gain_button(value):
	if value_negative:
		self.text = "- " + Global.number_to_string(value)
	else:
		self.text = Global.number_to_string(value)

extends PanelContainer

@onready var text_label: Label = %TextLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func set_tutorial_ui(_text: String, _pos: Vector2):
	
	text_label.text = tr(_text)
	global_position = _pos
	
	
func tutorial_step_finished():
	
	pass

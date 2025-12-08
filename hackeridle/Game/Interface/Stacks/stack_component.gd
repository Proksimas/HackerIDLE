extends Control

class_name StackComponent

@onready var stack_name_label: Label = %StackNameLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func set_component(component_name: String = "default_name"):
	stack_name_label.text = component_name
	

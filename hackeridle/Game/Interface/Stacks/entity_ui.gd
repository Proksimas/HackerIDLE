extends Control
@onready var stack_name_label: Label = %StackNameLabel
@onready var entity_name_label: Label = %EntityNameLabel
@onready var stack_grid: GridContainer = %StackGrid

const STACK_COMPONENT = preload("res://Game/Interface/Stacks/stack_component.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _draw() -> void:
	stack_name_label.text = "$Stack"

func set_stack_grid(entity_name: String, sequence: Array[String]):
	_clear()
	entity_name_label.text = entity_name
	for component_name in sequence:
		var new_component = STACK_COMPONENT.instantiate()
		stack_grid.add_child(new_component)
		new_component.set_component(component_name)
		
		
		
func _clear():
	for elmt in stack_grid.get_children():
		elmt.queue_free()

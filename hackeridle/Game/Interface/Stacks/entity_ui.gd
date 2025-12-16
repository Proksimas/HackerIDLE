extends Control
class_name EntityUI

@onready var stack_name_label: Label = %StackNameLabel
@onready var entity_name_label: Label = %EntityNameLabel
@onready var stack_grid: GridContainer = %StackGrid
@onready var hp_progress_bar: ProgressBar = %HpProgressBar
@onready var shield_progress_bar: ProgressBar = %ShieldProgressBar


@onready var penetration_label: Label = %PenetrationLabel
@onready var penetration_value: Label = %PenetrationValue
@onready var encryption_label: Label = %EncryptionLabel
@onready var encryption_value: Label = %EncryptionValue
@onready var flux_label: Label = %FluxLabel
@onready var flux_value: Label = %FluxValue

var entity_name_ui: String = "default_ui_name"
const STACK_COMPONENT = preload("res://Game/Interface/Stacks/stack_component.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_clear()
	pass # Replace with function body.


func _draw() -> void:
	stack_name_label.text = "$Stack"
	penetration_label.text = "$Penetration"
	encryption_label.text = "$Encryption"
	flux_label.text = "$Flux"

func set_stack_grid(entity_name: String, sequence: Array[String]):
	_clear()
	entity_name_ui = entity_name
	entity_name_label.text = entity_name
	for component_name in sequence:
		var new_component = STACK_COMPONENT.instantiate()
		stack_grid.add_child(new_component)
		new_component.set_component(component_name)


func set_stack_script_values(dict: Dictionary):
	for key in dict:
		match key:
			"penetration":
				penetration_value.text = str(dict["penetration"])
			"encryption":
				encryption_value.text = str(dict["encryption"])
			"flux":
				flux_value.text = str(dict["flux"])
	
func target_receive_data_from_execute(data: Dictionary):
	"""L'entité est la cible deu script d'execution.
	reçoit les données concernant cette entité post script execution
	Cela correspond aux degats reçus, shield etc"""
	


		
func _clear():
	for elmt in stack_grid.get_children():
		elmt.queue_free()
		

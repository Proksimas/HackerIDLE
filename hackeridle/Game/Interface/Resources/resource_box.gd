extends Control
class_name ResourceBox

@onready var resource_name: Label = %ResourceName
@onready var resource_value: Label = %ResourceValue

const BRAIN_ICON = preload("res://Game/Interface/Icons/brain_icon.tscn")
const GOLD_ICON = preload("res://Game/Interface/Icons/gold_icon.tscn")
const TROPHY_ICON = preload("res://Game/Interface/Icons/trophy_icon.tscn")
const CYBER_FORCE_ICON = preload("res://Game/Interface/Icons/cyber_force_icon.tscn")
var key: String = ""
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func refresh_value(value):
	resource_value.text = Global.number_to_string(value)

func set_resource_box(type_of_icon: String):
	var icon
	match type_of_icon:
		"BRAIN":
			key = "$knowledge"
			icon = BRAIN_ICON.instantiate()
			resource_name.text = tr(key)
		"GOLD":
			key = "$gold"
			icon = GOLD_ICON.instantiate()
			resource_name.text = tr(key)
		"SP":
			key = "$skillPoint"
			icon = TROPHY_ICON.instantiate()
			resource_name.text = tr(key)
		"CF":
			key = "$cyber_force"
			icon = CYBER_FORCE_ICON.instantiate()
			resource_name.text = tr(key)
			
	self.add_child(icon)
	icon.set_anchors_preset(4)
	icon.get_child(0).custom_minimum_size = Vector2(35,35)
	
	pass

func _draw() -> void:
	if key != "":
		resource_name.text = tr(key)

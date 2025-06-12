extends Control
@onready var skill_button: TextureButton = %SkillButton

@export var as_associated:ActiveSkill
@export var ps_associated:PackedScene

signal skill_button_pressed(skill_name:String, skill_type)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_skill_button_pressed() -> void:
	if as_associated != null:
		skill_button_pressed.emit(as_associated.as_name, "active_skill")
	elif ps_associated != null:
		skill_button_pressed.emit(as_associated.as_name, "passive_skill")
	else:
		push_error("Pas de skill associé au skillNode")
	pass # Replace with function body.

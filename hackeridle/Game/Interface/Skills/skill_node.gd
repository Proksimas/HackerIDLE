extends Control
@onready var skill_button: TextureButton = %SkillButton

@export var as_associated:ActiveSkill
@export var ps_associated:PassiveSkill

signal skill_button_pressed(skill_name:String, skill_type)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	fill_texture()
	pass # Replace with function body.


func _on_skill_button_pressed() -> void:
	if as_associated != null:
		
		skill_button_pressed.emit(as_associated.as_name, "active_skill")
	elif ps_associated != null:
		skill_button_pressed.emit(ps_associated.ps_name, "passive_skill")
	else:
		push_error("Pas de skill associé au skillNode")
	pass # Replace with function body.


func fill_texture():
	var new_texture: Texture
	if as_associated != null:
		new_texture = as_associated.as_texture
	elif ps_associated != null:
		new_texture = ps_associated.ps_texture
	else:
		push_error("Pas de skill associé au skillNode")
		
	skill_button.texture_normal = new_texture

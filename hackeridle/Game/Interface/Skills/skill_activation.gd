extends Control
@onready var skill_button: TextureButton = %SkillButton

var skill_associated:ActiveSkill

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func set_skill_activation(skill:ActiveSkill):
	skill_associated = skill
	skill_button.texture_normal = skill.as_texture
	pass

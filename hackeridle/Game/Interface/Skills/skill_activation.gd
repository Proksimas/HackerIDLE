extends Control
@onready var skill_button: TextureButton = %SkillButton

var skill_associated:ActiveSkill

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func set_skill_activation(skill:ActiveSkill):
	self.show()
	skill_associated = skill
	skill_button.texture_normal = skill.as_texture
	skill_associated.s_as_finished.connect(_on_s_as_finished)
	pass



func _on_skill_button_pressed() -> void:
	skill_associated.launch_as()
	skill_button.disabled = true
	pass # Replace with function body.

func _on_s_as_finished() -> void:
	skill_button.disabled = false

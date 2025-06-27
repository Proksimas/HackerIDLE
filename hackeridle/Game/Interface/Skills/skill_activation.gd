extends Control
@onready var skill_button: TextureButton = %SkillButton
@onready var texture_progress_bar: TextureProgressBar = %TextureProgressBar

var skill_associated:ActiveSkill

func _ready() -> void:
	skill_button.disabled = false
	texture_progress_bar.value = 0
	
func _process(_delta: float) -> void:
	if skill_associated.as_is_on_cd:
		texture_progress_bar.value = skill_associated.timer_cd.time_left

func set_skill_activation(skill:ActiveSkill):
	self.show()
	skill_associated = skill
	skill_button.texture_normal = skill.as_texture
	skill_associated.s_as_cd_finished.connect(_on_s_as_cd_finished)
	skill_associated.s_as_launched.connect(_on_s_as_launched)
	#si le timer active est actif, alors on a chargé un skill qui était deja activé dans la sauvegarde
	#on reprend donc son timer
	if skill_associated.timer_active != null:
		_on_s_as_launched()
	pass

func _on_skill_button_pressed() -> void:
	skill_associated.launch_as()
	pass # Replace with function body.
	
func _on_s_as_launched():
	texture_progress_bar. max_value = skill_associated.as_cd 
	texture_progress_bar.min_value = 0
	texture_progress_bar.value = skill_associated.as_cd 
	skill_button.disabled = true
	pass

func _on_s_as_cd_finished() -> void:
	"""le cd est finished"""
	skill_button.disabled = false

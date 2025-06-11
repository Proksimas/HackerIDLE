extends Control
@onready var skill_name_label: Label = %SkillNameLabel
@onready var skill_desc_label: Label = %SkillDescLabel
@onready var buy_skill_button: Button = %BuySkillButton
@onready var skills_grid: GridContainer = %SkillsGrid


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for skill in skills_grid.get_children():
		skill.skill_button_pressed.connect(_on_skill_node_skill_button_pressed)
	pass # Replace with function body.


func _on_skill_node_skill_button_pressed(skill_name: String) -> void:
	SkillsManager.learn_as(skill_name)
	pass # Replace with function body.

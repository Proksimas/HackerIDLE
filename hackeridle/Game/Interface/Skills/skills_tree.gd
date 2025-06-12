extends Control
@onready var skill_name_label: Label = %SkillNameLabel
@onready var skill_desc_label: Label = %SkillDescLabel
@onready var buy_skill_button: Button = %BuySkillButton
@onready var skills_grid: GridContainer = %SkillsGrid
@onready var cost_sp_label: Label = %CostSPLabel
@onready var skills_info: VBoxContainer = %SkillsInfo
@onready var to_unlocked_panel: ColorRect = %ToUnlockedPanel


var cache_skill_name: String
var cache_skill_cost: int
var cache_skill_type: String
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	for skill in skills_grid.get_children():
		skill.skill_button_pressed.connect(_on_skill_node_skill_button_pressed)
	pass # Replace with function body.

func _draw() -> void:
	skills_info.hide()
	to_unlocked_panel.hide()

func _on_skill_node_skill_button_pressed(skill_name: String, skill_type) -> void:
	skills_info.show()
	cache_skill_name = skill_name
	cache_skill_type = skill_type
	if !buy_skill_button.pressed.is_connected(_on_buy_skill_button_pressed):
		buy_skill_button.pressed.connect(_on_buy_skill_button_pressed)
	
	var skills_cara = SkillsManager.get_skill_cara(skill_name) 
	skill_name_label.text = tr(skills_cara['as_name'])
	skill_desc_label.text = tr(skills_cara['as_name'] + "_desc")
	if skill_type == "active_skill":
		cache_skill_cost = skills_cara['cost'][skills_cara["as_level"]]
		if cache_skill_cost <= Player.skill_point:
			buy_skill_button.disabled = false
			to_unlocked_panel.hide()
		else:
			buy_skill_button.disabled = true
			to_unlocked_panel.show()
		cost_sp_label.text = str(cache_skill_cost)
	else:
		pass
	pass # Replace with function body.

func _on_buy_skill_button_pressed():
	match cache_skill_type:
		"active_skill":
			if cache_skill_cost <= Player.skill_point:
				SkillsManager.learn_as(cache_skill_name)
				Player.skill_point -= cache_skill_cost
				_draw()
			
	pass

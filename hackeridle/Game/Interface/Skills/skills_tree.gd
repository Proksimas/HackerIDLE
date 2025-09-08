extends Control

@onready var skill_name_label: Label = %SkillNameLabel
@onready var skill_desc_label: Label = %SkillDescLabel
@onready var buy_skill_button: Button = %BuySkillButton
@onready var skills_grid: GridContainer = %SkillsGrid
@onready var cost_sp_label: Label = %CostSPLabel
@onready var skills_info: VBoxContainer = %SkillsInfo
@onready var to_unlocked_panel: ColorRect = %ToUnlockedPanel
@onready var cost_title: Label = %CostTitle
@onready var skill_point_value: Label = %SkillPointValue


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
	skill_point_value.text = str(Player.skill_point)

func _on_skill_node_skill_button_pressed(skill_name: String, skill_type) -> void:
	"""Le signal emit par le SkillNode inclut le skill_type en vérifiant si il 
	y a la ressource associée."""
	skills_info.show()
	cache_skill_name = skill_name
	cache_skill_type = skill_type
	if !buy_skill_button.pressed.is_connected(_on_buy_skill_button_pressed):
		buy_skill_button.pressed.connect(_on_buy_skill_button_pressed)
	
	var skills_cara = SkillsManager.get_skill_cara(skill_name) 
	if skill_type == "active_skill":
		skill_name_label.text = tr("$" + skills_cara['as_name'])
		var desc: String
		#Il faut mettre ç jour le niveau du skill si le player a deja le skill
		if Player.get_skill(skill_name, "active") != null:
			desc = SkillsManager.get_skill_translation(Player.get_skill_cara(skill_name, "active"), "as_name")
		else:
			desc = SkillsManager.get_skill_translation(skills_cara, "as_name")
		
		skill_desc_label.text = desc
		
		if is_max_level(skills_cara, skill_type): return
		cache_skill_cost = skills_cara['cost'][skills_cara["as_level"]]
		for as_skill:ActiveSkill in Player.skills_owned["active"]:
			if as_skill.as_name == skill_name:
				cache_skill_cost = as_skill['cost'][as_skill["as_level"]]
		unlocked_buy_skill_button()
		
	else: #passive skill
		skill_name_label.text = tr("$" + skills_cara['ps_name'])
		var desc
		if Player.get_skill(skill_name, "passive") != null:
			desc = SkillsManager.get_skill_translation(Player.get_skill_cara(skill_name, "passive"), "ps_name")
		else:
			desc = SkillsManager.get_skill_translation(skills_cara, "ps_name")
		skill_desc_label.text = desc

		if is_max_level(skills_cara, skill_type): return
		cache_skill_cost = skills_cara['cost'][skills_cara["ps_level"]]
		for ps_skill:PassiveSkill in Player.skills_owned["passive"]:
			if ps_skill.ps_name == skill_name:
				cache_skill_cost = ps_skill['cost'][ps_skill["ps_level"]]
		unlocked_buy_skill_button()
		pass
	pass # Replace with function body.
	
func is_max_level(skill_cara, skill_type)-> bool:
	match skill_type:
		"active_skill":
			var skill_name = skill_cara['as_name']
			for as_skill:ActiveSkill in Player.skills_owned["active"]:
				if as_skill.as_name == skill_name:
					skill_cara = as_skill
			if skill_cara.as_level >= len(skill_cara.cost):
				skill_name_label.text = tr("$" + skill_name)
				var desc
				if Player.get_skill(skill_name, "active") != null:
					desc = SkillsManager.get_skill_translation(Player.get_skill_cara(skill_name, "active"), "as_name")
				else:
					desc = SkillsManager.get_skill_translation(skill_cara, "as_name")
				skill_desc_label.text = desc
				
				buy_skill_button.disabled = true
				to_unlocked_panel.hide()
				cost_sp_label.text = "Max"
				return true

		"passive_skill":
			var skill_name = skill_cara['ps_name']
			for ps_skill:PassiveSkill in Player.skills_owned["passive"]:
				if ps_skill.ps_name == skill_cara["ps_name"]:
					skill_cara = ps_skill
			if skill_cara.ps_level >= len(skill_cara.cost):
				skill_name_label.text = tr("$" + skill_cara['ps_name'])
				var desc
				if Player.get_skill(skill_name, "passive") != null:
					desc = SkillsManager.get_skill_translation(Player.get_skill_cara(skill_name, "passive"), "ps_name")
				else:
					desc = SkillsManager.get_skill_translation(skill_cara, "ps_name")
				skill_desc_label.text = desc
		
				buy_skill_button.disabled = true
				to_unlocked_panel.hide()
				cost_sp_label.text = "Max"
				return true
		_:
			push_error("Pas normal pas de type")
			return true
			
	return false
			
	

func unlocked_buy_skill_button():
	if cache_skill_cost <= Player.skill_point:
		buy_skill_button.disabled = false
		to_unlocked_panel.hide()
	else:
		buy_skill_button.disabled = true
		to_unlocked_panel.show()
	cost_title.text = tr("$Cost")
	cost_sp_label.text = str(cache_skill_cost)


func _on_buy_skill_button_pressed():
	if cache_skill_cost <= Player.skill_point:
		match cache_skill_type:
			"active_skill":
				SkillsManager.learn_as(cache_skill_name)
			"passive_skill":
				SkillsManager.learn_ps(cache_skill_name)
		Player.skill_point -= cache_skill_cost
		_draw()
	pass

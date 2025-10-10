extends Control

@onready var skill_name_label: Label = %SkillNameLabel
@onready var skill_desc_label: Label = %SkillDescLabel
@onready var skills_grid: GridContainer = %SkillsGrid
@onready var skills_info: VBoxContainer = %SkillsInfo
@onready var to_unlocked_panel: ColorRect = %ToUnlockedPanel
@onready var skill_point_value: Label = %SkillPointValue
@onready var buy_button: Button = %BuyButton
@onready var exploits: Panel = %Exploits
@onready var skills: Panel = %Skills


var cache_skill_name: String
var cache_skill_cost: int
var cache_skill_type: String
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# ATTENTION ON HIDE POUR LE MOMENT CAR ON A SWITCH VERS LEARNING
	exploits.hide()
	skills.show()
	buy_button.set_up_icon("skill_point")
	for skill in skills_grid.get_children():
		skill.skill_button_pressed.connect(_on_skill_node_skill_button_pressed)
	pass # Replace with function body.

func _draw() -> void:
	skills_info.hide()
	to_unlocked_panel.hide()
	skill_point_value.text = str(Player.skill_point)
	refresh_skill_nodes()

func _on_skill_node_skill_button_pressed(skill_name: String, skill_type) -> void:
	"""Le signal emit par le SkillNode inclut le skill_type en vérifiant si il 
	y a la ressource associée."""
	skills_info.show()
	cache_skill_name = skill_name
	cache_skill_type = skill_type
	if !buy_button.pressed.is_connected(_on_buy_skill_button_pressed):
		buy_button.pressed.connect(_on_buy_skill_button_pressed)
	
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
				
				buy_button.to_disable()
				buy_button.max_label()

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
		
				buy_button.to_disable()
				buy_button.max_label()

				return true
		_:
			push_error("Pas normal pas de type")
			return true
			
	return false
			
	

func unlocked_buy_skill_button():
	
	buy_button.refresh(cache_skill_cost, "skill_point")



func _on_buy_skill_button_pressed():
	if cache_skill_cost <= Player.skill_point:
		match cache_skill_type:
			"active_skill":
				SkillsManager.learn_as(cache_skill_name)
				#for skill:SkillNode in skills_grid.get_children():
					#if skill.as_associated != null and skill.as_associated.as_name == cache_skill_name:
						#skill.as_associated.as_level += 1
			"passive_skill":
				SkillsManager.learn_ps(cache_skill_name)
				#for skill:SkillNode in skills_grid.get_children():
					#if skill.ps_associated != null and skill.ps_associated.ps_name == cache_skill_name:
						#skill.ps_associated.ps_level += 1
		Player.skill_point -= cache_skill_cost
		refresh_skill_nodes()
		#Puis on ajuste le level dans l'ui du skill
		_draw()
	pass


func refresh_skill_nodes():
	for skill_node:SkillNode in skills_grid.get_children():
		if skill_node.as_associated != null and len(Player.skills_owned["active"]) == 0:
			skill_node.refresh_level(0, len(skill_node.as_associated.cost))
			
		elif skill_node.as_associated != null and len(Player.skills_owned["active"]) != 0:
			for active_skill:ActiveSkill in Player.skills_owned["active"]:
				if active_skill.as_name == skill_node.as_associated.as_name:
					skill_node.refresh_level(active_skill.as_level, len(active_skill.cost))
		
		elif skill_node.ps_associated != null and len(Player.skills_owned["passive"]) == 0:
			skill_node.refresh_level(0, len(skill_node.ps_associated.cost))
			
		elif skill_node.ps_associated != null and len(Player.skills_owned["passive"]) != 0:
			for passive_skill: PassiveSkill in Player.skills_owned["passive"]:
				if passive_skill.ps_name == skill_node.ps_associated.ps_name:
					skill_node.refresh_level(passive_skill.ps_level, len(passive_skill.cost))

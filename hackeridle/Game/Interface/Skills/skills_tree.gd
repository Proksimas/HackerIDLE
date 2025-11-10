extends Control

@onready var skill_name_label: Label = %SkillNameLabel
@onready var skill_desc_label: Label = %SkillDescLabel
@onready var skills_info: VBoxContainer = %SkillsInfo
@onready var skill_point_value: Label = %SkillPointValue
@onready var buy_button: Button = %BuyButton
@onready var skills: Panel = %Skills
@onready var offensive_skills_grid: VBoxContainer = %OffensiveSkillsGrid
@onready var defensive_skills_grid: VBoxContainer = %DefensiveSkillsGrid
@onready var novanet_skills_grid: VBoxContainer = %NovanetSkillsGrid

@onready var skills_tab: TabContainer = %SkillsTab
@onready var offensive_skills: Control = %OffensiveSkills
@onready var defensive_skills: Control = %DefensiveSkills
@onready var novanet_skills: Control = %NovanetSkills
@onready var defensive_panel_skills: Panel = %DefensivePanelSkills
@onready var offensive_panel_skills: Panel = %OffensivePanelSkills
@onready var novanet_panel_skills: Panel = %NovanetPanelSkills

@onready var offensive_points_invested_label: Label = %OffensivePointsInvestedLabel
@onready var defensive_points_invested_label: Label = %DefensivePointsInvestedLabel
@onready var novanet_points_invested_label: Label = %NovanetPointsInvestedLabel


const VIOLET_NEON = Color(0.878, 0.424, 0.973)
const BLUE_NEON =  Color(0.22, 0.996, 0.996) #38fefe
const BLUE = Color(0.035, 0.282, 0.494)
const RED = Color(0.384, 0.004, 0.075)
const VIOLET = Color(0.701, 0, 0.706)

var cache_skill_name: String
var cache_skill_cost: int
var cache_skill_type: String
var lst_skill_nodes: Array
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# ATTENTION ON HIDE POUR LE MOMENT CAR ON A SWITCH VERS LEARNING
	skills.show()
	buy_button.set_up_icon("skill_point")
	#for skill in skills_grid.get_children():
		#skill.skill_button_pressed.connect(_on_skill_node_skill_button_pressed)
	var lst = offensive_skills_grid.get_children()
	lst.append_array(defensive_skills_grid.get_children())
	lst.append_array(novanet_skills_grid.get_children())
	for grid: GridContainer in lst:
		for skill in grid.get_children():
			lst_skill_nodes.append(skill)
			skill.skill_button_pressed.connect(_on_skill_node_skill_button_pressed)
	pass # Replace with function body.

func _draw() -> void:
	#ON NE MET PAS LES COMPETENCES DU NOVANET AVANT UN REBIRTH
	if Player.nb_of_rebirth == 0:
		novanet_panel_skills.hide()
	elif Player.nb_of_rebirth >= 1:
		novanet_panel_skills.show()
	
	hide_and_show_skills_info("hide")
	offensive_points_invested_label.text = str(SkillsManager.OS_invested_points)
	defensive_points_invested_label.text = str(SkillsManager.DS_invested_points)
	novanet_points_invested_label.text = str(SkillsManager.NOVANETS_invested_points)
	skill_point_value.text = str(Player.skill_point)
	refresh_skill_nodes()
	get_tree().call_group("g_skill_node", "show_hide_level", "offensive",SkillsManager.OS_invested_points)
	get_tree().call_group("g_skill_node", "show_hide_level", "defensive",SkillsManager.DS_invested_points)
	get_tree().call_group("g_skill_node", "show_hide_level", "novanet",SkillsManager.NOVANETS_invested_points)
	

func hide_and_show_skills_info(_type: String):
	match _type:
		"show":
			skill_name_label.visible = true
			skill_desc_label.visible = true
			buy_button.visible = true
		"hide":
			skill_name_label.visible = false
			skill_desc_label.visible = false
			buy_button.visible = false

func _on_skill_node_skill_button_pressed(skill_name: String, skill_type) -> void:
	"""Le signal emit par le SkillNode inclut le skill_type en vérifiant si il 
	y a la ressource associée."""
	hide_and_show_skills_info("show")
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
				
		#On affiche que les buttons des skills qu'on peut débloquer
		if skills_cara["is_offensive_skill"]:
			if SkillsManager.OS_invested_points < skills_cara["min_cost_invested"]:
				buy_button.hide()
			else:
				unlocked_buy_skill_button()
		elif skills_cara["is_defensive_skill"]:
			if SkillsManager.DS_invested_points < skills_cara["min_cost_invested"]:
				buy_button.hide() 
			else:
				unlocked_buy_skill_button()
		elif skills_cara["is_novanet_skill"]:
			if SkillsManager.NOVANETS_invested_points < skills_cara["min_cost_invested"]:
				buy_button.hide() 
			else:
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
		
		#On affiche que les buttons des skills qu'on peut débloquer
		if skills_cara["is_offensive_skill"]:
			if SkillsManager.OS_invested_points < skills_cara["min_cost_invested"]:
				buy_button.hide()
			else:
				unlocked_buy_skill_button()
		elif skills_cara["is_defensive_skill"]:
			if SkillsManager.DS_invested_points < skills_cara["min_cost_invested"]:
				buy_button.hide() 
			else:
				unlocked_buy_skill_button()
				
		elif skills_cara["is_novanet_skill"]:
			if SkillsManager.NOVANETS_invested_points < skills_cara["min_cost_invested"]:
				buy_button.hide() 
			else:
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
	buy_button.show()
	buy_button.refresh(cache_skill_cost, "skill_point")



func _on_buy_skill_button_pressed():
	var skill_cara = SkillsManager.get_skill_cara(cache_skill_name)
	if cache_skill_cost <= Player.skill_point:
		match cache_skill_type:
			"active_skill":
				SkillsManager.learn_as(cache_skill_name)
			"passive_skill":
				SkillsManager.learn_ps(cache_skill_name)
				
		Player.skill_point -= cache_skill_cost
		if skill_cara["is_offensive_skill"]:
			SkillsManager.OS_invested_points += cache_skill_cost
		elif skill_cara["is_defensive_skill"]:
			SkillsManager.DS_invested_points += cache_skill_cost
		elif skill_cara["is_novanet_skill"]:
			SkillsManager.NOVANETS_invested_points += cache_skill_cost

		refresh_skill_nodes()
		skills_tab.refresh_skills_tab()
		#Puis on ajuste le level dans l'ui du skill
		get_tree().call_group("g_skill_node", "show_hide_level", "offensive",SkillsManager.OS_invested_points)
		get_tree().call_group("g_skill_node", "show_hide_level", "defensive",SkillsManager.DS_invested_points)
		get_tree().call_group("g_skill_node", "show_hide_level", "novanet",SkillsManager.NOVANETS_invested_points)
		_draw()
	pass


func refresh_skill_nodes():
	for skill_node:SkillNode in lst_skill_nodes:
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



func show_defensive_skill() -> void:
	defensive_skills.show()
	defensive_panel_skills.add_theme_stylebox_override("panel" ,create_stylebox(BLUE, VIOLET_NEON))
	offensive_panel_skills.add_theme_stylebox_override("panel" ,create_stylebox(RED, BLUE_NEON))
	novanet_panel_skills.add_theme_stylebox_override("panel" ,create_stylebox(VIOLET, BLUE_NEON))
	
func show_offensive_skill() -> void:
	offensive_skills.show()
	offensive_panel_skills.add_theme_stylebox_override("panel" ,create_stylebox(RED, VIOLET_NEON))
	defensive_panel_skills.add_theme_stylebox_override("panel" ,create_stylebox(BLUE, BLUE_NEON))
	novanet_panel_skills.add_theme_stylebox_override("panel" ,create_stylebox(VIOLET, BLUE_NEON))
	
func show_ia_skill() -> void:
	novanet_skills.show()
	novanet_panel_skills.add_theme_stylebox_override("panel" ,create_stylebox(VIOLET, VIOLET_NEON))
	offensive_panel_skills.add_theme_stylebox_override("panel" ,create_stylebox(RED, BLUE_NEON))
	defensive_panel_skills.add_theme_stylebox_override("panel" ,create_stylebox(BLUE, BLUE_NEON))
	
func _on_draw() -> void:
	show_offensive_skill()
	pass # Replace with function body.

func create_stylebox(_color_bg: Color, _color_border):
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = _color_bg
	stylebox.border_color = _color_border
	stylebox.border_blend = true
	stylebox.corner_radius_bottom_left = 20
	stylebox.corner_radius_top_left = 20
	stylebox.corner_radius_bottom_right = 20 
	stylebox.corner_radius_top_right = 20
	stylebox.border_width_bottom = 5
	stylebox.border_width_left = 5
	stylebox.border_width_right = 5
	stylebox.border_width_top = 5
	return stylebox
	

func _on_defensive_panel_skills_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			show_defensive_skill()
	pass # Replace with function body.


func _on_offensive_panel_skills_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			show_offensive_skill()
	pass # Replace with function body.


func _on_ia_panel_skills_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			show_ia_skill()
	pass # Replace with function body.

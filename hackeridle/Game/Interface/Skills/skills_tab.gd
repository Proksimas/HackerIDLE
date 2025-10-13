extends TabContainer

@onready var os_progress: TextureProgressBar = %OSProgress
@onready var ds_progress: TextureProgressBar = %DSProgress
@onready var offensive_skills_grid: VBoxContainer = %OffensiveSkillsGrid
@onready var defensive_skills_grid: VBoxContainer = %DefensiveSkillsGrid


var OS_invested_points:int = 0
var DS_invested_points:int = 0

func _ready() -> void:
	pass # Replace with function body.


func refresh_skills_tab():
	maj_invested_points()
	refresh_progress_bar()
	#
	

func maj_invested_points() -> void:
	""" met à jour les points investies dans les skill."""
	var os_sum:int = 0
	OS_invested_points = 0
	DS_invested_points = 0
	for skill:PassiveSkill in Player.skills_owned["passive"]:
		if skill.is_offensive_skill:
			OS_invested_points += skill.ps_level
		elif skill.is_defensive_skill:
			DS_invested_points += skill.ps_level
		else:
			push_error("Ni offensif, ni defensif skill")
			
	for skill:ActiveSkill in Player.skills_owned["active"]:
		if skill.is_offensive_skill:
			OS_invested_points += skill.as_level
		elif skill.is_defensive_skill:
			DS_invested_points += skill.as_level
		else:
			push_error("Ni offensif, ni defensif skill")

			
func _get_max_skills_levels(_type)-> int:
	"""calcul le nombre max de levels selon le type demande"""
	match _type:
		"offensive":
			var sum_offensive:int = 0
			var lst_skill = Player.skills_owned["active"]
			lst_skill.append_array(Player.skills_owned["passive"])
			for skill in lst_skill:
				sum_offensive += len(skill.cost)
				return sum_offensive
		"defensive":
			var sum_defensive:int = 0
			var lst_skill = Player.skills_owned["active"]
			lst_skill.append_array(Player.skills_owned["passive"])
			for skill in lst_skill:
				sum_defensive += len(skill.cost)
				return sum_defensive
		_:
			push_error("Probleme dans le calcul du max level")
			return 0
	return 0
			
			
func refresh_progress_bar():
	os_progress.min_value = 0
	os_progress.max_value = _get_max_skills_levels("offensive")
	os_progress.value = OS_invested_points
	
	ds_progress.min_value = 0
	ds_progress.max_value = _get_max_skills_levels("defensive")
	ds_progress.value = DS_invested_points
	pass
			
func _on_draw() -> void:
	refresh_skills_tab()
	pass # Replace with function body.

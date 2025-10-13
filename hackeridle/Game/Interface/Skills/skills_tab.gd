extends TabContainer

@onready var os_progress: TextureProgressBar = %OSProgress
@onready var ds_progress: TextureProgressBar = %DSProgress
@onready var offensive_skills_grid: VBoxContainer = %OffensiveSkillsGrid
@onready var defensive_skills_grid: VBoxContainer = %DefensiveSkillsGrid
@onready var offensive_points_invested_label: Label = %OffensivePointsInvestedLabel


func _ready() -> void:
	pass # Replace with function body.


func refresh_skills_tab():
	offensive_points_invested_label.text = "Nombre de points investis: %s" % SkillsManager.OS_invested_points
	#maj_invested_points()
	refresh_progress_bar()

func _get_max_skills_points(_type)-> int:
	"""calcul le nombre max de skills points selon le type demande"""
	var sum_offensive:int = 0
	var sum_defensive:int = 0
	for skill_name in SkillsManager.passives_skills:
		var cara = SkillsManager.get_skill_cara(skill_name)
		for cost in cara["cost"]:
			if cara["is_offensive_skill"]:
				sum_offensive += cost
			elif cara["is_defensive_skill"]:
				sum_defensive += cost
			else:
				push_error("Skill ni offensiv ni defensif")		
	match _type:
		"offensive":
			return sum_offensive
	
		"defensive":
			return sum_defensive
	return 0
			
			
func refresh_progress_bar():
	os_progress.min_value = 0
	os_progress.max_value = _get_max_skills_points("offensive")
	os_progress.value = SkillsManager.OS_invested_points
	
	ds_progress.min_value = 0
	ds_progress.max_value = _get_max_skills_points("defensive")
	ds_progress.value = SkillsManager.DS_invested_points
	pass
			
			


func _on_draw() -> void:
	refresh_skills_tab()
	pass # Replace with function body.

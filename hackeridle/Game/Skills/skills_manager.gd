extends Node

var ACTIVE_SKILL_PATH = "res://Game/Skills/ActiveSkills/"

# {"skill_nam": ActiveSkill}
var active_skills: Dictionary = {
	"genius_stroke": preload("res://Game/Skills/ActiveSkills/genius_stroke_active_skill.tres")
}     
var passives_skills: Dictionary = {"click_worth": preload("res://Game/Skills/PassiveSkills/click_worth.tres")}

signal as_learned(skill:ActiveSkill)
signal ps_learned(skill:PassiveSkill)

func learn_ps(skill_name: String, data = {}):
	if !passives_skills.has(skill_name):
		push_warning("Le skill %s à ajouter n'existe pas" % [skill_name])
	
	for ps_skill:PassiveSkill in Player.skills_owned["passive"]:
		if ps_skill.ps_name == skill_name and ps_skill.ps_level < len(ps_skill.cost):
			ps_skill.ps_level += 1
		return

	var skill:PassiveSkill = passives_skills[skill_name].duplicate()
	skill.set_meta("resource_path", passives_skills[skill_name].resource_path)
	#skill.set_meta("skill_name", skill_name)
	Player.skills_owned["passive"].append(skill)
	if data == {}:skill.attach(Player, 1)
	else:
		skill.attach(Player, data["ps_level"])

	ps_learned.emit(skill)


func learn_as(skill_name: String, data = {}):
	#data correspond à des paramètres d'initialisations supplémentaires
	#utile pour le chargement d'une sauvegarde par exemple
	if !active_skills.has(skill_name):
		push_warning("Le skill %s à ajouter n'existe pas" % [skill_name])
	for as_skill:ActiveSkill in Player.skills_owned["active"]:
		if as_skill.as_name == skill_name and as_skill.as_level < len(as_skill.cost):
			as_skill.as_level += 1
		return
		
	var skill:ActiveSkill = active_skills[skill_name].duplicate()
	skill.set_meta("resource_path", active_skills[skill_name].resource_path)
	#skill.set_meta("skill_name", skill_name)
	Player.skills_owned["active"].append(skill)
	if data == {}:skill.attach(Player, 1) #on met au niveau 1
	else:
		skill.attach(Player, data["as_level"])
		#if data["timer_cd/time_left"] != 0: #alors y'a la compétence en cd
			#var timer_active: SceneTreeTimer = skill.tree.create_timer(data["timer_cd/time_left"])
			#timer_active.timeout.connect(skill.as_finished)
		# ATTENTION si le sort est en cours d'activation, on va tricher en 
		# lançant son cd
		# Le cd n'est pas encore en cours
		if data["as_is_active"] == true and not data["as_is_on_cd"]:
			skill.as_finished()
		#alors on reprend le CD 
		elif data["timer_cd/time_left"] != 0 and data["as_is_on_cd"]:
			skill.as_finished(data["timer_cd/time_left"])


	as_learned.emit(skill)
	
	
func get_skill_cara(skill_name: String):
	var skills
	if active_skills.has(skill_name):
		skills = active_skills

	elif passives_skills.has(skill_name):
		skills = passives_skills
		
	else:
		push_warning("Le skill %s  n'existe pas" % [skill_name])
		
	var list = {}
	var properties = skills[skill_name].get_property_list()
	for prop in properties:
		var p_name = prop.name
		var usage = prop.usage
		if usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			list[p_name] = skills[skill_name].get(prop["name"])
	return list

	
	

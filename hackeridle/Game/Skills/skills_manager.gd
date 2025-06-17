extends Node

var ACTIVE_SKILL_PATH = "res://Game/Skills/ActiveSkills/"

# {"skill_nam": ActiveSkill}
var active_skills: Dictionary = {
	"genius_stroke": preload("res://Game/Skills/ActiveSkills/genius_stroke_active_skill.tres")
}     
var passives_skills: Dictionary = {}

signal as_learned(skill:ActiveSkill)
signal ps_learned(skill:PassiveSkill)

func learn_ps(skill_name: String):
	if !passives_skills.has(skill_name):
		push_warning("Le skill %s à ajouter n'existe pas" % [skill_name])
	var skill:PassiveSkill = passives_skills[skill_name].duplicate()
	for resource:PassiveSkill in Player.skills_owned['passive']:
		if resource.ps_name == skill_name:
			#TODO
			push_error("Le joueur a deja le skill %s" % [skill_name])
			return

	Player.skills_owned["passive"].append(skill)
	skill.attach(Player, 1) #on met au niveau 1
	ps_learned.emit(skill)


func learn_as(skill_name: String):
	if !active_skills.has(skill_name):
		push_warning("Le skill %s à ajouter n'existe pas" % [skill_name])
	var skill:ActiveSkill = active_skills[skill_name].duplicate()
	for resource:ActiveSkill in Player.skills_owned['active']:
		if resource.as_name == skill_name:
			#TODO
			push_error("Le joueur a deja le skill %s" % [skill_name])
			return

	Player.skills_owned["active"].append(skill)
	skill.attach(Player, 1) #on met au niveau 1
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

	
	

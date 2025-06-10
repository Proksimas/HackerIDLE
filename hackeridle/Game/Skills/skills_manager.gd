extends Node

var active_skills: Dictionary = {"genius_stroke" :preload("res://Game/Skills/genius_stroke_active_skill.tres")}     # id -> Skill
var passives_skills: Dictionary = {}


func register_as(id: String, active_skill: ActiveSkill) -> void:
	active_skills[id] = active_skill


func try_cast_as(as_name: String) -> bool:
	var s = active_skills.get(as_name)
	if s and s.can_cast():
		s.launch_as()
		return true
	return false


func learn_as(skill_name: String, owner):
	if !active_skills.has(skill_name):
		push_warning("Le skill %s à ajouter n'existe pas" % [skill_name])
	
	var skill:ActiveSkill = active_skills[skill_name].duplicate()
	if Player.skills_owned.values().has(skill):
		#TODO
		push_error("Le joueur a deja le skill %s" % [skill_name])
	else:
		Player.skills_owned["active"].append(skill)
		skill.attach(Player)
	
	
	pass
	
	

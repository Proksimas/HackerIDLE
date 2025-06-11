extends Node

var active_skills: Dictionary = {"genius_stroke":preload("res://Game/Skills/genius_stroke_active_skill.tres")}     # id -> Skill
var passives_skills: Dictionary = {}

signal as_learned(skill:ActiveSkill)



func learn_as(skill_name: String):
	if !active_skills.has(skill_name):
		push_warning("Le skill %s à ajouter n'existe pas" % [skill_name])
	
	var skill:ActiveSkill = active_skills[skill_name].duplicate()
	print(Player.skills_owned['active'])
	
	
	for resource:ActiveSkill in Player.skills_owned['active']:
		if resource.as_name == skill_name:
			#TODO
			push_error("Le joueur a deja le skill %s" % [skill_name])
			return

	Player.skills_owned["active"].append(skill)
	skill.attach(Player, 1) #on met au niveau 1
	as_learned.emit(skill)
	
	

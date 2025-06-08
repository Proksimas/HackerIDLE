extends Node

var active_skills: Dictionary = {"genius_stroke" :preload("res://Game/Skills/genius_stroke_active_skill.tres")}     # id -> Skill
var passives_skills: Dictionary = {}


func register_as(id: String, active_skill: ActifSkill) -> void:
	active_skills[id] = active_skill


func try_cast_as(as_name: String) -> bool:
	var s = active_skills.get(as_name)
	if s and s.can_cast():
		s.launch_as()
		return true
	return false

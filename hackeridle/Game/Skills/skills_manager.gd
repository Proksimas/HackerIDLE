extends Node

var ACTIVE_SKILL_PATH = "res://Game/Skills/ActiveSkills/"

# {"skill_nam": ActiveSkill}
var active_skills: Dictionary = {
	"genius_stroke": preload("res://Game/Skills/ActiveSkills/genius_stroke_active_skill.tres")
}     
var passives_skills: Dictionary = {
	"click_worth": preload("res://Game/Skills/PassiveSkills/click_worth.tres"),
	"veteran": preload("res://Game/Skills/PassiveSkills/veteran.tres"),
	"business_acumen": preload("res://Game/Skills/PassiveSkills/business_acumen.tres"),
	"IamNice": preload("res://Game/Skills/PassiveSkills/IamNice.tres"),
	"news_maniac": preload("res://Game/Skills/PassiveSkills/news_maniac.tres"),
	"i_want_to_click": preload("res://Game/Skills/PassiveSkills/i_want_to_click.tres"),
	"ia": preload("res://Game/Skills/PassiveSkills/ia.tres"),
	"i_like_bots": preload("res://Game/Skills/PassiveSkills/i_like_bots.tres"),
	"tax_optimization": preload("res://Game/Skills/PassiveSkills/tax_optimization.tres"),
	"hackathon": preload("res://Game/Skills/PassiveSkills/hackathon.tres")}

var active_timers: Dictionary = {}
var OS_invested_points = 0
var DS_invested_points = 0

signal timer_completed(id_cible)
signal as_learned(skill:ActiveSkill)
signal ps_learned(skill:PassiveSkill)

func learn_ps(skill_name: String, data = {}):
	if !passives_skills.has(skill_name):
		push_warning("Le skill %s à ajouter n'existe pas" % [skill_name])
	
	for ps_skill:PassiveSkill in Player.skills_owned["passive"]:
		if ps_skill.ps_name == skill_name and ps_skill.ps_level < len(ps_skill.cost):
			
			ps_skill.ps_level += 1
			#mettre à jour le skill
			ps_skill.detach(Player)
			ps_skill.attach(Player,ps_skill.ps_level)
			ps_learned.emit(ps_skill)
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
			as_learned.emit(as_skill)
		return
		
	var skill:ActiveSkill = active_skills[skill_name].duplicate()
	skill.set_meta("resource_path", active_skills[skill_name].resource_path)
	#skill.set_meta("skill_name", skill_name)
	Player.skills_owned["active"].append(skill)
	if data == {}:skill.attach(Player, 1) #on met au niveau 1
	else:
		skill.attach(Player, data["as_level"])
		if data["timer_active/time_left"] != 0 and not data["as_is_on_cd"]:
			#une compétence etait en cours. On relance !
			skill.launch_as(data["timer_active/time_left"])
			
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

func get_skill_translation(player_skill, type) -> String:
	var _translation: String
	if type == "as_name":
		var level = player_skill["as_level"]
		if level >= len(player_skill["cost"]):
			level = len(player_skill["cost"]) - 1
		var data_bonus_1 = [] if player_skill["data_bonus_1"].is_empty() else player_skill["data_bonus_1"][level]
		var data_bonus_2 = [] if player_skill["data_bonus_2"].is_empty() else player_skill["data_bonus_2"][level]

		return tr(player_skill['as_name'] + "_desc").\
				format(
					{"as_during_time": player_skill["as_during_time"],
					"as_name": player_skill["as_name"],
					"cost": player_skill["cost"],
					"data_bonus_1": data_bonus_1,
					"data_bonus_2": data_bonus_2
					})
	else:
		var level = player_skill["ps_level"]
		if level >= len(player_skill["cost"]):
			level = len(player_skill["cost"]) - 1
		var data_bonus_1 = [] if player_skill["data_bonus_1"].is_empty() else player_skill["data_bonus_1"][level]
		var data_bonus_2 = [] if player_skill["data_bonus_2"].is_empty() else player_skill["data_bonus_2"][level]

		return tr(player_skill['ps_name'] + "_desc").\
				format(
					{"ps_name": player_skill["ps_name"],
					"cost": player_skill["cost"],
					"data_bonus_1": data_bonus_1,
					"data_bonus_2": data_bonus_2
					})



# Signal générique que le TimerManager émettra lorsqu'un timer expire.
# Le 'id_cible' permettra à la Resource de savoir quel événement la concerne.


## Crée un nouveau Timer et le connecte au gestionnaire.
func create_timer(id_cible: String, duration: float, is_one_shot: bool = false) -> void:
	# 1. Empêcher la création de timers dupliqués pour la même ID, si nécessaire
	if active_timers.has(id_cible):
		print_debug("Avertissement: Le timer pour ID '%s' existe déjà. Ignoré." % id_cible)
		return
	var new_timer = Timer.new()
	new_timer.wait_time = duration
	
	new_timer.one_shot = is_one_shot
	
	new_timer.timeout.connect(_on_generic_timer_timeout.bind(id_cible,is_one_shot ))
	add_child(new_timer)
	active_timers[id_cible] = new_timer
	new_timer.start()

## Méthode de gestion appelée par tous les timers
func _on_generic_timer_timeout(id_cible: String, _is_one_shot):
	timer_completed.emit(id_cible)
	if !_is_one_shot:
		return
	var timer_node: Timer = active_timers.get(id_cible)
	if timer_node:
		timer_node.queue_free()
		active_timers.erase(id_cible)

## Méthode pour annuler un timer si nécessaire
func cancel_timer(id_cible: String) -> void:
	var timer_node: Timer = active_timers.get(id_cible)
	if timer_node:
		timer_node.stop()
		timer_node.queue_free()
		active_timers.erase(id_cible)

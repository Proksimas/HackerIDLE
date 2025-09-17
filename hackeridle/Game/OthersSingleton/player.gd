extends Node

var knowledge_point: float
var gold: float
var brain_xp: float
var cyber_force: float
var robots_cyber_force: = 1000000 
		
var skill_point: int:
	set(value):
		skill_point = clamp(value, 0, INF)
		s_earn_sp.emit(skill_point)
		
var brain_level: int = 1:
	set(value):
		brain_level = clamp(value, 0, INF)
		s_earn_brain_level.emit(brain_level)

		
var brain_xp_next: float = 0
var base_xp: float = 200
var xp_factor: float = 1.6
var nb_of_rebirth: int = 0

var learning_item_bought: Dictionary = {}
var learning_item_statut: Dictionary = {}
var hacking_item_bought: Dictionary = {}
var hacking_item_statut: Dictionary = {}
var sources_item_bought: Dictionary = {}

var skills_owned = {"active" : [],
					"passive": [] }
					
					
signal s_earn_knowledge_point(point)
signal s_knowledge_to_earn(point)
signal s_earn_gold(number)
signal s_gold_to_earn(number)
signal s_earn_brain_xp(number)
signal s_earn_sp(number)
signal s_earn_brain_level(number)
signal s_earn_cyber_force(number)
signal s_brain_clicked(knowledge, brain_xp)

signal s_add_hacking_item()
signal s_add_learning_item()


func _ready() -> void:
	brain_xp_next = get_brain_xp(brain_level -1)
	
func _init():
	"""Initialise le joueur à zero. Est appelé dans le main pour une new partie"""
	_init_skills_owned()
	_init_sources()
	brain_xp_next = get_brain_xp(brain_level -1)
	
func _init_skills_owned():
	skills_owned = {"active" : [],
					"passive": [] }

func _init_sources():
	sources_item_bought.clear()
					
func _check_level_up(_earning):
	if brain_xp + _earning >= brain_xp_next:
		level_up()
		return true
	else: 
		return false

#region functions de gains

func earn_knowledge_point(earning):
	"""Le earning est la connaissance qu'on va gagner. Il faut y ajouter les bonus globaux"""
	earning = StatsManager.calcul_global_stat(StatsManager.Stats.KNOWLEDGE, earning)
	knowledge_point += earning
	knowledge_point = clamp(knowledge_point, 0, INF)
	s_knowledge_to_earn.emit(earning)
	s_earn_knowledge_point.emit(knowledge_point)
	
func earn_gold(earning):
	"""Le earning est l'argent qu'on va gagner. Il faut y ajouter les bonus globaux"""
	earning = StatsManager.calcul_global_stat(StatsManager.Stats.GOLD, earning)
	self.gold += earning
	gold = clamp(gold, 0, INF)
	s_gold_to_earn.emit(earning)
	s_earn_gold.emit(gold)
	
func earn_brain_xp(earning):
	#on ne peut pas retirer du brain xp
	if _check_level_up(earning):
		brain_xp += earning - brain_xp
		brain_xp = clamp(brain_xp, 0, INF)
	else:
		brain_xp += clamp(earning, 0, INF)
	brain_xp = snapped(brain_xp, 0.1)
	s_earn_brain_xp.emit(brain_xp)
	
func earn_cyber_force(earning):
	self.cyber_force += earning
	cyber_force = clamp(cyber_force, 0, INF)
	s_earn_cyber_force.emit(cyber_force)
	
	
func level_up():
	skill_point += 1
	brain_level += 1
	brain_xp_next =  get_brain_xp(brain_level - 1) 
	#On ajuste la stat
	var dict_to_remove = StatsManager.get_modifier_by_source_name(StatsManager.TargetModifier.BRAIN_CLICK, 
					StatsManager.Stats.KNOWLEDGE, "birth")
	StatsManager.remove_modifier(StatsManager.TargetModifier.BRAIN_CLICK, 
					StatsManager.Stats.KNOWLEDGE, dict_to_remove)
	StatsManager.add_modifier(StatsManager.TargetModifier.BRAIN_CLICK,
						StatsManager.Stats.KNOWLEDGE, 
						StatsManager.ModifierType.BASE, Player.brain_level, "birth")
	
#endregion
	
func get_brain_xp(level_asked):
	# Base * pow(FacteurDeCroissance, level - 1)
	return round(base_xp * pow(xp_factor, level_asked))
	
func add_learning_item(item_cara:Dictionary):
	s_add_learning_item.emit()
	var dict_to_store = item_cara.duplicate()
	#on oublie de mettre le niveau à jour
	dict_to_store["level"] = 1

						
	learning_item_bought[item_cara['item_name']] = dict_to_store
	
		#comme on ajoute l'item, il est forcement en mode unlocked
	self.learning_item_statut[item_cara['item_name']] = "unlocked"
	
	#Il faut ensuite que l'item n +1 soit en mode to_unlocked
	var items_name = Player.learning_item_statut.keys()
	for item_name in Player.learning_item_statut:
		if item_name == item_cara["item_name"]: #alors le prochain doit etre en "ton_unlocked
			var pos = items_name.find(item_name)
			if items_name.size() > pos + 1:
				var next_item_name = items_name[pos + 1]
				Player.learning_item_statut[next_item_name] = "to_unlocked"
pass
	
##Gagne le nombre de level donné en paramètre
func learning_item_level_up(item_name: String, gain_of_level):
	learning_item_bought[item_name]["level"] += gain_of_level
	
	
func has_learning_item(item_name):
	if learning_item_bought.has(item_name):
		return true
	else:
		return false
		

func change_learning_property_value(item_name: String, property: String, value):
	if not has_learning_item(item_name):
		push_warning("L'item n'existe pas")
	learning_item_bought[item_name][property] = value

func add_hacking_item(item_cara: Dictionary):
	s_add_hacking_item.emit()
	var dict_to_store = item_cara.duplicate()
	#dict_to_store['level'] = 1

	hacking_item_bought[item_cara['item_name']] = dict_to_store

	#comme on ajoute l'item, il est forcement en mode unlocked
	self.hacking_item_statut[item_cara['item_name']] = "unlocked"
	
	#Il faut ensuite que l'item n +1 soit en mode to_unlocked
	var items_name = Player.hacking_item_statut.keys()
	for item_name in Player.hacking_item_statut:
		if item_name == item_cara["item_name"]: #alors le prochain doit etre en "ton_unlocked
			var pos = items_name.find(item_name)
			if items_name.size() > pos + 1:
				var next_item_name = items_name[pos + 1]
				Player.hacking_item_statut[next_item_name] = "to_unlocked"
	
func add_source(source_cara: Dictionary):
	var dict_to_store = source_cara.duplicate()
	sources_item_bought[source_cara['source_name']] = dict_to_store

	pass

##Gagne le nombre de level donné en paramètre
func hacking_item_level_up(item_name: String, gain_of_level):
	hacking_item_bought[item_name]["level"] += gain_of_level

func has_hacking_item(item_name):
	if hacking_item_bought.has(item_name):
		return true
	else:
		return false
		
func change_hacking_property_value(item_name: String, property: String, value):
	if not has_hacking_item(item_name):
		push_warning("L'item n'existe pas")
	hacking_item_bought[item_name][property] = value

func get_associated_source(hack_item_name: String):
	for i in range(sources_item_bought.size()):
		if sources_item_bought.values()[i]["affectation"] == hack_item_name:
			return get_source_cara(sources_item_bought.values()[i]["source_name"])

func get_skill(skill_name, type: String = "active"):
	"""type = active ou passive"""
	match type:
		"active":
			for skill in skills_owned["active"]:
				if skill["as_name"] == skill_name:
					return skill
		"passive":
			for skill in skills_owned["passive"]:
				if skill["ps_name"] == skill_name:
					return skill
		_:
			return null
					
func get_skill_cara(skill_name: String, type: String = "active"):
	var skill = get_skill(skill_name, type)
	var list = {}
	var properties = skill.get_property_list()
	for prop in properties:
		var p_name = prop.name
		var usage = prop.usage
		if usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			list[p_name] = skill.get(prop["name"])
	return list
	
	
func get_source_cara(source_name: String):
	if sources_item_bought.has(source_name):
		return sources_item_bought[source_name]
	else:
		push_error("La source demandée n'existe pas")
		
func brain_clicked():
	"""Le cerveau a été cliqué, on calcul les gains associés"""
	var knowledge_point_to_gain = StatsManager.current_stat_calcul(\
	StatsManager.TargetModifier.BRAIN_CLICK, StatsManager.Stats.KNOWLEDGE)
	var brain_xp_to_gain = StatsManager.current_stat_calcul(\
	StatsManager.TargetModifier.BRAIN_CLICK, StatsManager.Stats.BRAIN_XP)
	#StatsManager._show_stats_modifiers(StatsManager.Stats.BRAIN_XP)
	Player.earn_knowledge_point(knowledge_point_to_gain * StatsManager.bonus_from_clicking['current_bonus'])
	Player.earn_brain_xp(brain_xp_to_gain * StatsManager.bonus_from_clicking['current_bonus'])
	s_brain_clicked.emit(knowledge_point_to_gain, brain_xp_to_gain)

func _save_data():
	var all_vars = Global.get_serialisable_vars(self)
	#on doit réafecter pour les skills qui sont enregistrés sous forme d'objets
	var obj_skills_owned = all_vars["skills_owned"]
	all_vars.erase("skills_owned")
	var skills_owned_to_save = {"active": [],
						"passive": []}
	for as_skill:ActiveSkill in obj_skills_owned["active"]:
		var dict = {}
		dict["as_name"] = as_skill.as_name
		dict["as_level"] = as_skill.as_level
		dict["as_is_active"] = as_skill.as_is_active
		if as_skill.timer_active != null:
			dict["timer_active/time_left"] = as_skill.timer_active.time_left
		else:
			dict["timer_active/time_left"] = 0
		dict["as_is_on_cd"] = as_skill.as_is_on_cd
		if as_skill.timer_cd != null:
			dict["timer_cd/time_left"] = as_skill.timer_cd.time_left
		else:
			dict["timer_cd/time_left"] = 0
		skills_owned_to_save['active'].append(dict)
		
	for ps_skill:PassiveSkill in obj_skills_owned["passive"]:
		var dict = {}
		dict["ps_name"] = ps_skill.ps_name
		dict["ps_level"] = ps_skill.ps_level
		skills_owned_to_save['passive'].append(dict)
	
	all_vars["skills_owned"] = skills_owned_to_save
	return all_vars

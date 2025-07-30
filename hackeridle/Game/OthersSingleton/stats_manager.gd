extends Node

#################### DESCRIPTION ##############################################
# Est géré les stats pour le jeu, ainsi que les modificateurs associés
# Est géré également l'infamie (infamy) dans ce fichier
#
################################################################################

enum Stats{GOLD, KNOWLEDGE, BRAIN_XP, TIME, JAIL}
enum ModifierType {PERCENTAGE, FLAT, BASE}
#FLAT = sans augmentation de pourcentage: Surement très peu utilisé
#BASE = subit l'augmentation de pourcentage
#PERCENTAGE: 1 = 100%; 0,5 = 50% etc
enum Infamy{INNOCENT, REPORT, USP, USA, TARGETED, PUBLIC_ENEMY, NULL}
enum TargetModifier{GLOBAL, BRAIN_CLICK, HACK}

const STATS_NAMES = {
	Stats.GOLD: "gold",
	Stats.KNOWLEDGE: "knowledge",
	Stats.BRAIN_XP: "brain_xp"
}
const INFAMY_NAMES = {
	Infamy.INNOCENT: "innocent",
	Infamy.REPORT: "report",
	Infamy.USP: "usp",
	Infamy.USA: "usa",
	Infamy.TARGETED: "targeted",
	Infamy.PUBLIC_ENEMY: "public_enemy"
}

# Sous la forme: {Stats: [new_modifier, ...]}
var global_modifiers: Dictionary = {}    #tous les modificateurs des stats
var brain_click_modifiers: Dictionary = {} #gain ç chaque click sur le cerveau
var hack_modifiers: Dictionary = {}

var infamy: Dictionary
var infamy_threshold = [10,25,40,60,90,99]

signal s_go_to_jail()
signal s_add_infamy(infamy_value)
signal s_infamy_effect_added()
func _ready() -> void:
	_init()
	
func _init(new_game:bool = true) -> void:
	"""On initialise. Mettre les stats à calculer
	Si new_game == true, on ajoute les premieres valeurs de abse"""
	global_modifiers = {}    #tous les modificateurs des stats
	brain_click_modifiers = {}
	hack_modifiers = {}
	for stat in Stats.values():
		global_modifiers[stat] = []
		brain_click_modifiers[stat] = []
		hack_modifiers[stat] = []

	if new_game:
		self.add_modifier(TargetModifier.BRAIN_CLICK, Stats.BRAIN_XP, ModifierType.BASE, 1, "birth")
		self.add_modifier(TargetModifier.BRAIN_CLICK, Stats.KNOWLEDGE, ModifierType.BASE, Player.brain_level, "birth")
	_init_infamy()
	
	
func _init_infamy():
	infamy.clear()
	infamy["min"] = 0 # doit jamais dépasser 90
	infamy["max"] = 100 # Ne devrait jamais depasser 100
	infamy["current_value"] = 0 # clamp entre min et max
	add_infamy_effects() #on prend le premier effet
		

func add_modifier(target_modifier:TargetModifier, stat_name: Stats, \
	modifier_type: ModifierType, value: float, source: String = ""):
		
	var new_modifier = {
		"type": modifier_type,
		"value": value,
		"source": source
	}
		
	match target_modifier:
		TargetModifier.GLOBAL:
			if !global_modifiers.has(stat_name):
				push_error("la stat %s n'existe pas pour les modification" % stat_name)
				return
			global_modifiers[stat_name].append(new_modifier)
			
		TargetModifier.BRAIN_CLICK:
			if !brain_click_modifiers.has(stat_name):
				push_error("la stat %s n'existe pas pour les modification" % stat_name)
				return
			brain_click_modifiers[stat_name].append(new_modifier)
		TargetModifier.HACK:
			if !hack_modifiers.has(stat_name):
				push_error("la stat %s n'existe pas pour les modification" % stat_name)
				return
			hack_modifiers[stat_name].append(new_modifier)
				
func remove_modifier(target_modifier:TargetModifier, stat_name: Stats, modifier_to_remove: Dictionary ):
	var modifier_dict = get_accurate_modifier(target_modifier)
	if modifier_dict.has(stat_name):
		var index = modifier_dict[stat_name].find(modifier_to_remove)
		if index != -1:
			modifier_dict[stat_name].remove_at(index)
			
			
func get_modifier_by_source_name(target_modifier:TargetModifier, stat_name: Stats, source_name: String) -> Dictionary:
	var modifier_dict = get_accurate_modifier(target_modifier)
	if modifier_dict.has(stat_name):
		for dict in modifier_dict[stat_name]:
			if dict["source"] == source_name:
				return dict
	return {}
			
func current_stat_calcul(target_modifier:TargetModifier, stat_name: Stats) -> float:
	"""Renvoie la valeur de la stat demandée, après calcul de tous les modificateurs
	agissant spécifiquement sur cette stat selon le modificateur demandé"""
	var modifier_dict = get_accurate_modifier(target_modifier)

	var perc = 0.0
	var flat = 0
	var base = 0
	for modifier in modifier_dict[stat_name]:
		match modifier["type"]:
			ModifierType.BASE:
				base += modifier["value"]
			ModifierType.PERCENTAGE:
				perc += modifier["value"]
			ModifierType.FLAT:
				flat += modifier["value"]
	var calcul = (base * (1 + perc)) + flat
	#var calcul = (base + flat) * (1 + perc)
	return calcul
	
func calcul_global_stat(stat_name: Stats, earning) -> float:
	"""renvoie la valeur de la stat après l'ajout de ses modificateurs GLOBAUX
	Ici, le earning est ajouté à la stat de base"""
	var perc = 0.0
	var flat = 0
	var base = 0
	for modifier in global_modifiers[stat_name]:
		match modifier["type"]:
			ModifierType.BASE:
				base += modifier["value"]
			ModifierType.PERCENTAGE:
				perc += modifier["value"]
			ModifierType.FLAT:
				flat += modifier["value"]
	
	var calcul = ((base + earning) * (1 + perc)) + flat
	return calcul
	
func calcul_hack_stat(stat_name: Stats, earning) -> float:
	"""Renvoie UNIQUEMENT pour les hack, le earning modifié avec les paramètres 
	agissant sur le hack selon la stat choisie"""
	var perc = 0.0
	var flat = 0
	var base = 0
	for modifier in hack_modifiers[stat_name]:
		match modifier["type"]:
			ModifierType.BASE:
				base += modifier["value"]
			ModifierType.PERCENTAGE:
				perc += modifier["value"]
			ModifierType.FLAT:
				flat += modifier["value"]
	
	var calcul = ((base + earning) * (1 + perc)) + flat
	return calcul
	
func  get_accurate_modifier(target_modifier: TargetModifier) -> Dictionary:
	var modifier_dict: Dictionary
	match target_modifier:
		TargetModifier.GLOBAL:
			modifier_dict = global_modifiers
		TargetModifier.BRAIN_CLICK:
			modifier_dict = brain_click_modifiers
		TargetModifier.HACK:
			modifier_dict = hack_modifiers
	return modifier_dict
func _show_stats_modifiers(stat_name: Stats):
	var for_global_modifiers = { "percentage": [],
		"base": [],
		"flat": []}
	var for_brain_click_modifiers= { "percentage": [],
		"base": [],
		"flat": []}
	
	if global_modifiers.has(stat_name):
		for modifier in global_modifiers[stat_name]:
			match modifier["type"]:
				ModifierType.BASE:
					for_global_modifiers['base'].append(modifier["value"])
				ModifierType.PERCENTAGE:
					for_global_modifiers["percentage"].append(modifier["value"])
				ModifierType.FLAT:
					for_global_modifiers["flat"].append(modifier["value"])
					
	if brain_click_modifiers.has(stat_name):
		for modifier in brain_click_modifiers[stat_name]:
			match modifier["type"]:
				ModifierType.BASE:
					for_brain_click_modifiers['base'].append(str(modifier["value"]) + ": " + modifier["source"])
				ModifierType.PERCENTAGE:
					for_brain_click_modifiers["percentage"].append(str(modifier["value"]) + ": " + modifier["source"])
				ModifierType.FLAT:
					for_brain_click_modifiers["flat"].append(str(modifier["value"]) + ": " + modifier["source"])
	print("global modifiers:")
	print("\tpercentage: ", for_global_modifiers["percentage"])
	print("\tbase: ", for_global_modifiers["base"])
	print("\tflat: ", for_global_modifiers["flat"])
	print("brain click modifiers:")
	print("\tpercentage: ", for_brain_click_modifiers["percentage"])
	print("\tbase: ", for_brain_click_modifiers["base"])
	print("\tflat: ", for_brain_click_modifiers["flat"])

#region INFAMY

func add_min_infay(_earning: int):
	infamy["min"] = clamp(infamy["min"] + _earning, 0, 90)

func add_infamy(_earning: float):
	var old_treshold = get_infamy_treshold()
	var earning = round(_earning)
	infamy["current_value"] = clamp(infamy["current_value"] + earning, infamy["min"], infamy["max"])
	s_add_infamy.emit(infamy["current_value"])
	var new_treshold = get_infamy_treshold()
	if infamy["current_value"] == 100:
		#DIRECT EN PRISON TODO
		s_go_to_jail.emit()
		
		return
		
	if old_treshold != new_treshold:
		for stat in hack_modifiers:
			var filtered_list = [] # Crée une nouvelle liste pour les éléments à conserver
			var old_treshold_name = INFAMY_NAMES.get(old_treshold) # Récupère le nom du seuil une seule fois
			for dict_item in hack_modifiers[stat]:
				# Si la source n'est PAS celle de l'ancien seuil, ajoute-la à la nouvelle liste
				if "source" in dict_item and dict_item["source"] != old_treshold_name:
					filtered_list.append(dict_item)
			hack_modifiers[stat] = filtered_list
		#on recupere les nouveaux effets d'infamie
		add_infamy_effects()

	print_debug(hack_modifiers)
	
	
func get_infamy_treshold() -> Infamy:
	var current_infamy = infamy["current_value"]
	if current_infamy < infamy_threshold[0]:
		return Infamy.INNOCENT
	elif current_infamy < infamy_threshold[1]:
		return Infamy.REPORT
	elif current_infamy < infamy_threshold[2]:
		return Infamy.USP
	elif current_infamy < infamy_threshold[3]:
		return Infamy.USA
	elif current_infamy < infamy_threshold[4]:
		return Infamy.TARGETED
	elif current_infamy < infamy_threshold[5]:
		return Infamy.PUBLIC_ENEMY
	else:
		return Infamy.NULL

func add_infamy_effects():
	""" On ajoute l'effet lié à l'INFAMIE dans les stats"""
	var _infamy_threshold = get_infamy_treshold()
	match _infamy_threshold:
		Infamy.INNOCENT:
			pass
		Infamy.REPORT:
			self.add_modifier(TargetModifier.HACK, Stats.GOLD,
				ModifierType.PERCENTAGE, -0.25, INFAMY_NAMES.get(_infamy_threshold))
		Infamy.USP:
			self.add_modifier(TargetModifier.HACK, Stats.GOLD,
				ModifierType.PERCENTAGE, -0.4, INFAMY_NAMES.get(_infamy_threshold))
		Infamy.USA:
			self.add_modifier(TargetModifier.HACK, Stats.GOLD,
				ModifierType.PERCENTAGE, -0.4, INFAMY_NAMES.get(_infamy_threshold))
			self.add_modifier(TargetModifier.HACK, Stats.TIME,
				ModifierType.PERCENTAGE, 0.2, INFAMY_NAMES.get(_infamy_threshold))
		Infamy.TARGETED:
			self.add_modifier(TargetModifier.HACK, Stats.GOLD,
				ModifierType.PERCENTAGE, -0.5, INFAMY_NAMES.get(_infamy_threshold))
			self.add_modifier(TargetModifier.HACK, Stats.TIME,
				ModifierType.PERCENTAGE, 0.3, INFAMY_NAMES.get(_infamy_threshold))
			self.add_modifier(TargetModifier.HACK, Stats.JAIL,
				ModifierType.PERCENTAGE, 0.1, INFAMY_NAMES.get(_infamy_threshold))
		Infamy.PUBLIC_ENEMY:
			self.add_modifier(TargetModifier.HACK, Stats.GOLD,
				ModifierType.PERCENTAGE, -0.75, INFAMY_NAMES.get(_infamy_threshold))
			self.add_modifier(TargetModifier.HACK, Stats.TIME,
				ModifierType.PERCENTAGE, 0.5, INFAMY_NAMES.get(_infamy_threshold))
			self.add_modifier(TargetModifier.HACK, Stats.JAIL,
				ModifierType.PERCENTAGE, 0.25, INFAMY_NAMES.get(_infamy_threshold))
	s_infamy_effect_added.emit()
	
#endregion


func _save_data():
	var all_vars = Global.get_serialisable_vars(self)
	return all_vars

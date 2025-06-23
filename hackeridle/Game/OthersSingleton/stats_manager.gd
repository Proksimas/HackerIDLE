extends Node

enum Stats{GOLD, KNOWLEDGE, BRAIN_XP}
enum ModifierType {PERCENTAGE, FLAT, BASE} 
#FLAT = sans augmentation de pourcentage: Surement très peu utilisé
#BASE = subit l'augmentation de pourcentage
enum TargetModifier {GLOBAL, BRAIN_CLICK}

const STATS_NAMES = {
	Stats.GOLD: "gold",
	Stats.KNOWLEDGE: "knowledge",
	Stats.BRAIN_XP: "brain_xp"
}

# Sous la forme: {Stats: [new_modifier, ...]}

var global_modifiers: Dictionary = {}    #tous les modificateurs des stats
var brain_click_modifiers: Dictionary = {} #gain ç chaque click sur le cerveau


func _ready() -> void:
	_init()
	
func _init(new_game:bool = true) -> void:
	"""On initialise. Mettre les stats à calculer
	Si new_game == true, on ajoute les premieres valeurs de abse"""
	global_modifiers = {}    #tous les modificateurs des stats
	brain_click_modifiers = {}
	for stat in Stats.values():
		global_modifiers[stat] = []
		brain_click_modifiers[stat] = []
	if new_game:
		self.add_modifier(TargetModifier.BRAIN_CLICK, Stats.BRAIN_XP, ModifierType.BASE, 1, "birth")
		self.add_modifier(TargetModifier.BRAIN_CLICK, Stats.KNOWLEDGE, ModifierType.BASE, 1, "birth")
	


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
	
	
	
func remove_modifier(target_modifier:TargetModifier, stat_name: String,\
					 modifier_to_remove:Dictionary):
						
	var modifier_dict
	match target_modifier:
		TargetModifier.GLOBAL:
			modifier_dict = global_modifiers
		TargetModifier.BRAIN_CLICK:
			modifier_dict = brain_click_modifiers
			
	if modifier_dict.has(stat_name):
		var index = modifier_dict[stat_name].find(modifier_to_remove)
		if index != -1:
			modifier_dict[stat_name].remove_at(index)
			
func current_stat_calcul(target_modifier:TargetModifier, stat_name: Stats) -> float:
	"""Renvoie la valeur de la stat après calcul de tous ses paramètres"""
	var modifier_dict: Dictionary
	match target_modifier:
		TargetModifier.GLOBAL:
			modifier_dict = global_modifiers
		TargetModifier.BRAIN_CLICK:
			modifier_dict = brain_click_modifiers
			
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
	
	

extends Node

enum Stats{GOLD, KNOWLEDGE, BRAIN_XP}
enum ModifierType {PERCENTAGE, FLAT}
enum TargetModifier {GLOBAL, BRAIN_CLICK}

const STATS_NAMES = {
	Stats.GOLD: "gold",
	Stats.KNOWLEDGE: "knowledge",
	Stats.BRAIN_XP: "brain_xp"
}

var modifiers: Dictionary = {}    #tous les modificateurs des stats
var brain_click_modifiers: Dictionary = {}


func _ready() -> void:
	_init()
	
	add_modifier(TargetModifier.BRAIN_CLICK, Stats.GOLD, ModifierType.PERCENTAGE, 0.10, "test")
	print(modifiers)
	print(brain_click_modifiers)
	
func _init() -> void:
	"""on doit mettre les stats à calculer"""
	modifiers = {}    #tous les modificateurs des stats
	brain_click_modifiers = {}
	for stat in Stats.values():
		modifiers[stat] = []
		brain_click_modifiers[stat] = []


func add_modifier(target_modifier:TargetModifier, stat_name: Stats, \
			modifier_type: ModifierType, value: float, source: String = ""):

	if !modifiers.has(stat_name):
		push_error("la stat %s n'existe pas pour les modification" % stat_name)
		return
		
	var new_modifier = {
		"type": modifier_type,
		"value": value,
		"source": source
	} 
	match target_modifier:
		TargetModifier.GLOBAL:
			modifiers[stat_name].append(new_modifier)
		TargetModifier.BRAIN_CLICK:
			brain_click_modifiers[stat_name].append(new_modifier)
	
	
	
func remove_modifier(target_modifier:TargetModifier, stat_name: String,\
					 modifier_to_remove:Dictionary):
	if modifiers.has(stat_name):
		var index =modifiers[stat_name].find(modifier_to_remove)
		if index != -1:
			modifiers[stat_name].remove_at(index)

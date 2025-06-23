extends Node

enum STATS{GOLD}
enum MODIFIER_TYPE {PERCENTAGE, FLAT}

const STATS_NAMES = {
	STATS.GOLD: "Gold",
}

var modifiers : Dictionary = {}    #tous les modifivateurs


func _ready() -> void:
	_init()
	add_modifier(STATS.GOLD, MODIFIER_TYPE.PERCENTAGE, 0.10, "test")

	
func _init() -> void:
	"""on doit mettre les stats à calculer"""
	for stat in STATS_NAMES:
		modifiers[STATS_NAMES.get(stat)] = []

func add_modifier(stat_name: STATS, modifier_type: MODIFIER_TYPE, value: float, source: String = ""):

	if !modifiers.has(STATS_NAMES.get(stat_name)):
		push_error("la stat %s n'existe pas pour les modification" % stat_name)
		return
		
	var new_modifier = {
		"type": modifier_type,
		"value": value,
		"source": source
	} 
	modifiers[STATS_NAMES.get(stat_name)].append(new_modifier)
	
	
	
func remove_modifier(stat_name: String, modifier_to_remove:Dictionary):
	if modifiers.has(stat_name):
		var index =modifiers[stat_name].find(modifier_to_remove)
		if index != -1:
			modifiers[stat_name].remove_at(index)

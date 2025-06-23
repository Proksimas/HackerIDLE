extends Node

enum Stats{GOLD, KNOWLEDGE, BRAIN_XP}
enum MODIFIER_TYPE {PERCENTAGE, FLAT}

const STATS_NAMES = {
	Stats.GOLD: "gold",
	Stats.KNOWLEDGE: "knowledge",
	Stats.BRAIN_XP: "brain_xp"
}

var modifiers : Dictionary = {}    #tous les modificateurs des stats


func _ready() -> void:
	_init()
	
	add_modifier(Stats.GOLD, MODIFIER_TYPE.PERCENTAGE, 0.10, "test")

func _init() -> void:
	"""on doit mettre les stats à calculer"""
	for stat in Stats.values():
		modifiers[stat] = []

func add_modifier(stat_name: Stats, modifier_type: MODIFIER_TYPE, value: float, source: String = ""):

	if !modifiers.has(stat_name):
		push_error("la stat %s n'existe pas pour les modification" % stat_name)
		return
		
	var new_modifier = {
		"type": modifier_type,
		"value": value,
		"source": source
	} 
	modifiers[stat_name].append(new_modifier)
	
	
	
func remove_modifier(stat_name: String, modifier_to_remove:Dictionary):
	if modifiers.has(stat_name):
		var index =modifiers[stat_name].find(modifier_to_remove)
		if index != -1:
			modifiers[stat_name].remove_at(index)

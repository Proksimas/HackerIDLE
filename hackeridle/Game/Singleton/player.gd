extends Node

var knowledge_point: float:
	set(value):
		return clamp(value, 0, INF)
		
var hacking_point: float:
	set(value):
		return clamp(value, 0, INF)
		
		
var learning_item_bought: Dictionary = {"item_name": {"level": 1,
													"knowledge_point_earned": 1} }
													
func _ready() -> void:
	learning_item_bought.clear() # on vide le dictionnaire 

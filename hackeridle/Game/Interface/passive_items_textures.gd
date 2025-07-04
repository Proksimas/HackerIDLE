extends Control

@onready var item_spawn_timer: Timer = %ItemSpawnTimer
@onready var passif_clickers: HFlowContainer = %PassifClickers
@onready var all_container: VBoxContainer = %AllContainer

const PASSIVE_ITEM_TEXTURE = preload("res://Game/Interface/Items/passive_item_texture.tscn")
const MAX_ACTIVE_FALLING_ITEMS = 300

var active_falling_items_count:int


func get_passives_learning_data():
	
	var lst: Array = []
	for passive:PassifLearningItem in passif_clickers.get_children():
		var dict:Dictionary = {}
		dict["texture"] = passive.shop_item_cara_db["texture_path"]
		dict["level"] = passive.shop_item_cara_db["level"]
		lst.append(dict)
		
	return lst
	

	
func spawn_item(texture):
	var new_item = PASSIVE_ITEM_TEXTURE.instantiate()
	self.add_child(new_item)
	new_item.item_moving(all_container.global_position, all_container.size)

	pass

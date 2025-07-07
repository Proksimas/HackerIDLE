extends Control

@onready var item_spawn_timer: Timer = %ItemSpawnTimer
@onready var passif_clickers: HFlowContainer = %PassifClickers
@onready var all_container: VBoxContainer = %AllContainer

const PASSIVE_ITEM_TEXTURE = preload("res://Game/Interface/Items/passive_item_texture.tscn")
const MAX_ACTIVE_FALLING_ITEMS = 300

var active_falling_items_count:int
var item_spawned: Dictionary  # { item_name: nb_invocated, }

	
func spawn_item(item_name, texture):
	var new_item = PASSIVE_ITEM_TEXTURE.instantiate()
	self.add_child(new_item)
	new_item.set_passive_item(item_name, texture)
	new_item.item_moving(all_container.global_position, all_container.size)
	new_item.s_passive_item_deleted.connect(self._on_s_passive_item_deleted)
	if item_spawned.has(item_name):
		item_spawned[item_name] += 1
	else:
		item_spawned[item_name] = 1
	


func _on_item_spawn_timer_timeout() -> void:
	var items_to_spawn = Player.learning_item_bought.keys()
	if items_to_spawn.is_empty():
		return
	items_to_spawn.shuffle()
	print(items_to_spawn)
	for item_name in items_to_spawn:
		var item_level =  Player.learning_item_bought[item_name]["level"]
		var item_texture = Player.learning_item_bought[item_name]["texture_path"]
	
		#si item n'a pas atteint le max spawn, on l'invoque et in break. Sinon on passe au suivant
		if item_spawned.has(item_name) and item_level > item_spawned[item_name]:
			spawn_item(item_name, item_texture)
		
		elif item_spawned.has(item_name) and item_level <= item_spawned[item_name]:
			continue
			
		elif !item_spawned.has(item_name):
			spawn_item(item_name, item_texture)
			
		else:
			break
			

func _on_s_passive_item_deleted(item_name):
	if item_spawned.has(item_name):
		item_spawned[item_name] -= 1
		if item_spawned[item_name] == 0:
			item_spawned.erase(item_name)

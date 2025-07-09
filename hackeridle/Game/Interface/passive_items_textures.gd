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
		
	item_spawn_timer.wait_time = randf_range(0.5, 1.5)
	
func _on_item_spawn_timer_timeout() -> void:
	var items_to_spawn = Player.learning_item_bought.keys()
	if items_to_spawn.is_empty():
		return

	var total_weight = 0
	var cumulative_weights = []  # tableau de [item_name, cumulative_weight]

	for item_name in items_to_spawn:
		var level = Player.learning_item_bought[item_name]["level"]
		var weight = pow(level, 1.3)  # pondération quadratique pour favoriser les plus hauts niveaux
		if weight <= 0:
			continue

		total_weight += weight
		cumulative_weights.append({
			"item_name": item_name,
			"cumulative_weight": total_weight
		})

	if total_weight == 0:
		return

	# 🎯 Tirage aléatoire entre 0 et total_weight - 1
	var random_pick = randi() % int(total_weight)


	# 📦 Sélection de l’item selon le poids cumulé
	for entry in cumulative_weights:
		if random_pick < entry["cumulative_weight"]:
			var item_name = entry["item_name"]
			var item_level = Player.learning_item_bought[item_name]["level"]
			var item_texture = Player.learning_item_bought[item_name]["texture_path"]


			# logique de spawn
			if item_spawned.has(item_name) and item_level > item_spawned[item_name]:
				spawn_item(item_name, item_texture)
			elif !item_spawned.has(item_name):
				spawn_item(item_name, item_texture)
			break  # ne spawn qu’un seul item par tick

		

func _on_s_passive_item_deleted(item_name):
	if item_spawned.has(item_name):
		item_spawned[item_name] -= 1
		if item_spawned[item_name] == 0:
			item_spawned.erase(item_name)

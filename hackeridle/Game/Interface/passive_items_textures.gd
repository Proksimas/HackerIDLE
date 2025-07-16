# Script amélioré pour gérer le nombre maximal d'items à l'écran,
# espacement dynamique entre les spawns et progression ressentie.
extends Control

@onready var passif_clickers: HFlowContainer = %PassifClickers
@onready var all_container: VBoxContainer = %AllContainer

const PASSIVE_ITEM_SCENE = preload('res://Game/Interface/Items/passive_item_texture.tscn')
const MAX_ACTIVE_FALLING_ITEMS = 200
const MIN_SPAWN_INTERVAL = 0.5
const MAX_SPAWN_INTERVAL = 2.0

var active_falling_items_count: int = 0
var item_spawned: Dictionary = {}
var wait_time

func _ready():
	# Démarrage du timer avec l'intervalle maximal
	get_tree().create_timer(MAX_SPAWN_INTERVAL).timeout.connect(_on_item_spawn_timer_timeout)


func _on_item_spawn_timer_timeout():
	var keys = Player.learning_item_bought.keys()
	if keys.is_empty():
		_schedule_next_spawn()
		return

	# Calcul des poids cumulés
	var total_weight := 0.0
	var cumulative_weights := []
	for name in keys:
		var level = Player.learning_item_bought[name]['level']
		var weight = pow(level, 2)
		if weight <= 0:
			continue
		total_weight += weight
		cumulative_weights.append({
			'item_name': name,
			'cumulative_weight': total_weight
		})

	if total_weight == 0:
		_schedule_next_spawn()
		return

	# Sélection aléatoire selon le poids
	var pick = randi() % int(total_weight)
	for entry in cumulative_weights:
		if pick < entry['cumulative_weight']:
			var item_name = entry['item_name']
			var item_data = Player.learning_item_bought[item_name]
			if active_falling_items_count < MAX_ACTIVE_FALLING_ITEMS \
				and (not item_spawned.has(item_name) or item_spawned[item_name] < item_data['level']):
					_spawn_item(item_name, item_data['texture_path'])
			break

	_schedule_next_spawn()

func _spawn_item(item_name: String, texture_path: String):
	var new_item = PASSIVE_ITEM_SCENE.instantiate()
	add_child(new_item)
	new_item.set_passive_item(item_name, texture_path)
	new_item.item_moving(all_container.global_position, all_container.size)
	new_item.s_passive_item_deleted.connect(_on_s_passive_item_deleted)

	# Mise à jour des compteurs
	active_falling_items_count += 1
	item_spawned[item_name] = item_spawned.get(item_name, 0) + 1

func _on_s_passive_item_deleted(item_name: String) -> void:
	active_falling_items_count = max(active_falling_items_count - 1, 0)
	if item_spawned.has(item_name):
		item_spawned[item_name] -= 1
		if item_spawned[item_name] <= 0:
			item_spawned.erase(item_name)

func _schedule_next_spawn():
	# L'intervalle est ajusté en fonction du nombre d'items actifs pour espacer les spawns
	var ratio = float(active_falling_items_count) / MAX_ACTIVE_FALLING_ITEMS
	var interval = lerp(MIN_SPAWN_INTERVAL, MAX_SPAWN_INTERVAL, ratio)

	var random = randf_range(interval, interval + 0.5)
	get_tree().create_timer(random).timeout.connect(_on_item_spawn_timer_timeout)

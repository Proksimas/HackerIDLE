extends Control

@export var entity: Entity

@onready var available_list: ItemList = %AvailableList
@onready var sequence_list: ItemList = %SequenceList
@onready var status_label: Label = %StatusLabel
@onready var up_button: Button = %UpButton
@onready var down_button: Button = %DownButton
@onready var entities_menu: OptionButton = %EntitiesMenu

const CREATE_ENTITY = preload("res://Game/Interface/Stacks/SequenceManager/CreateEntity.tscn")
var available_names: Array[String] = []
var sequence_names: Array[String] = []
var dirty := false
var entities: Array[Entity] = []

func _ready() -> void:
	if entity != null:
		load_from_entity(entity)
	else:
		_update_status("Aucune entite chargee.")

func load_from_entity(target: Entity) -> void:
	entity = target
	if entity == null:
		available_names.clear()
		sequence_names.clear()
	else:
		available_names = _to_string_array(entity.available_scripts.keys())
		available_names.sort()
		sequence_names = _to_string_array(entity.sequence_order)
	_refresh_lists()
	dirty = false
	_update_status()

func _refresh_lists() -> void:
	available_list.clear()
	for _name in available_names:
		available_list.add_item(_name)

	sequence_list.clear()
	for _name in sequence_names:
		sequence_list.add_item(_name)

func _on_available_item_activated(index: int) -> void:
	if index < 0 or index >= available_names.size():
		return
	sequence_names.append(available_names[index])
	_refresh_lists()
	dirty = true
	_update_status()

func _on_sequence_item_activated(index: int) -> void:
	if index < 0 or index >= sequence_names.size():
		return
	sequence_names.remove_at(index)
	_refresh_lists()
	dirty = true
	_update_status()

func _on_move_up_pressed() -> void:
	var idx := sequence_list.get_selected_items()
	if idx.is_empty():
		return
	var i := idx[0]
	if i <= 0:
		return
	var tmp = sequence_names[i]
	sequence_names[i] = sequence_names[i - 1]
	sequence_names[i - 1] = tmp
	_refresh_lists()
	sequence_list.select(i - 1)
	dirty = true
	_update_status()

func _on_move_down_pressed() -> void:
	var idx := sequence_list.get_selected_items()
	if idx.is_empty():
		return
	var i := idx[0]
	if i < 0 or i >= sequence_names.size() - 1:
		return
	var tmp = sequence_names[i]
	sequence_names[i] = sequence_names[i + 1]
	sequence_names[i + 1] = tmp
	_refresh_lists()
	sequence_list.select(i + 1)
	dirty = true
	_update_status()

func _on_clear_pressed() -> void:
	sequence_names.clear()
	_refresh_lists()
	dirty = true
	_update_status()

func _on_save_pressed() -> void:
	if entity == null:
		_update_status("Aucune entite cible pour sauvegarder.")
		return
	entity.save_sequence(sequence_names.duplicate())
	dirty = false
	_update_status("Sequence sauvegardee.")

func _on_create_entity_pressed() -> void:
	open_create_entity_ui()

func _on_entity_selected(index: int) -> void:
	if index < 0 or index >= entities.size():
		return
	load_from_entity(entities[index])

func _on_refresh_entities_pressed() -> void:
	_refresh_entities_menu()

func _update_status(extra: String = "") -> void:
	var base := ""
	if entity == null:
		base = "Aucune entite chargee."
	else:
		base = "Sequence de %s" % entity.entity_name
	if dirty:
		base += " (non enregistree)"
	if extra != "":
		base += " - %s" % extra
	status_label.text = base

func _to_string_array(arr: Array) -> Array[String]:
	var res: Array[String] = []
	for v in arr:
		res.append(str(v))
	return res

func open_create_entity_ui() -> void:
	"""Instancie l'UI de creation d'entite et se connecte au signal de retour."""
	var creator = CREATE_ENTITY.instantiate()
	add_child(creator)
	if creator.has_signal("entity_created"):
		creator.connect("entity_created", Callable(self, "_on_entity_created"))

func _on_entity_created(ent: Entity) -> void:
	if ent == null:
		return
	entities.append(ent)
	_refresh_entities_menu(entities.size() - 1)
	load_from_entity(ent)
	_update_status("Entite chargee depuis le createur.")

func _refresh_entities_menu(select_index: int = -1) -> void:
	entities_menu.clear()
	if entities.is_empty():
		entities_menu.add_item("Aucune entite")
		entities_menu.select(0)
		return
	for i in range(entities.size()):
		entities_menu.add_item(str(entities[i].entity_name))
	if select_index >= 0 and select_index < entities.size():
		entities_menu.select(select_index)

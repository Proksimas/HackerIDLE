extends Control

@export var hacker: Entity
@export var max_slots: int = 5

@onready var scripts_list: ItemList = %ScriptsList
@onready var stack_script_name: Label = %StackScriptName
@onready var type_value: Label = %TypeValue
@onready var cooldown_value: Label = %CooldownValue
@onready var exec_value: Label = %ExecValue
@onready var scaling_value: Label = %ScalingValue
@onready var description_label: RichTextLabel = %Description

@onready var hp_value: Label = %HpValue
@onready var penetration_value: Label = %PenetrationValue
@onready var encryption_value: Label = %EncryptionValue
@onready var flux_value: Label = %FluxValue
@onready var sequence_list: ItemList = %SequenceList
@onready var slots_label: Label = %SlotsLabel

var _script_lookup: Dictionary = {} # nom -> StackScript
var _selected_script: StackScript
var _sequence_names: Array[String] = []
var _drag_origin := ""
var _drag_index := -1
var _drag_started := false
var _drag_start_pos := Vector2.ZERO
var _inventory_names: Array[String] = []

const DRAG_THRESHOLD := 6.0

# Définition des couleurs (constantes)
const COLOR_HP = "#FF0000"      # Rouge
const COLOR_SHIELD = "#8A2BE2"  # Violet
const COLOR_TARGET = "#00BFFF"  # Bleu Ciel
const COLOR_CASTER = "#FFD700"  # Jaune
const COLOR_DOT = "#008000"     # Vert

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_reset_details()
	_refresh_stats()
	if hacker != null:
		load_hacker(hacker)
	else:
		_bootstrap_hacker_from_manager()


func load_hacker(target: Entity) -> void:
	"""Charge un hacker externe et remplit l'UI."""
	hacker = target
	_refresh_stats()
	_ensure_hacker_scripts()
	_populate_lists()


func _bootstrap_hacker_from_manager() -> void:
	"""Fallback : cree un hacker local et lui apprend tous les scripts disponibles."""
	_ensure_pool_ready()
	var temp_hacker := Entity.new(true)
	StackManager.learn_all_script(temp_hacker)
	load_hacker(temp_hacker)


func _ensure_pool_ready() -> void:
	if typeof(StackManager.stack_script_pool) != TYPE_DICTIONARY:
		StackManager.stack_script_pool = {}
	if StackManager.stack_script_pool.is_empty():
		StackManager.initialize_pool()


func _ensure_hacker_scripts() -> void:
	if hacker == null:
		return
	if hacker.available_scripts.is_empty():
		_ensure_pool_ready()
		StackManager.learn_all_script(hacker)


func _populate_lists() -> void:
	_populate_scripts()
	_populate_sequence()
	_update_slots_label()


func _populate_scripts() -> void:
	scripts_list.clear()
	_script_lookup.clear()
	_inventory_names.clear()

	if hacker == null or hacker.available_scripts.is_empty():
		return

	var names: Array[String] = []
	for key in hacker.available_scripts.keys():
		names.append(str(key))
	names.sort()

	for name in names:
		var script_res = hacker.available_scripts.get(name, null)
		if script_res is StackScript:
			_script_lookup[name] = script_res
			var display_name := _format_script_name(name)
			scripts_list.add_item(display_name)
			scripts_list.set_item_metadata(scripts_list.item_count - 1, name)
			_inventory_names.append(name)

	if scripts_list.item_count > 0:
		scripts_list.select(0)
		var first_name := _get_item_name(scripts_list, 0)
		_display_script(first_name)


func _populate_sequence() -> void:
	sequence_list.clear()
	_sequence_names.clear()

	if hacker != null and not hacker.sequence_order.is_empty():
		for name in hacker.sequence_order:
			if hacker.available_scripts.has(name):
				_sequence_names.append(str(name))

	# S'assure que max_slots couvre toujours la sequence existante
	max_slots = max(max_slots, _sequence_names.size())

	for name in _sequence_names:
		var display_name := _format_script_name(name)
		sequence_list.add_item(display_name)
		sequence_list.set_item_metadata(sequence_list.item_count - 1, name)

	if sequence_list.item_count > 0:
		sequence_list.select(0)

	_update_slots_label()


func _display_script(name: String) -> void:
	if not _script_lookup.has(name):
		_reset_details()
		return

	_selected_script = _script_lookup[name]
	var display_name := _format_script_name(name)
	stack_script_name.text = display_name
	type_value.text = _script_kind_to_string(_selected_script.script_kind)
	cooldown_value.text = "%d tour(s)" % int(_selected_script.turn_cooldown_base)
	exec_value.text = "%.1f s" % float(_selected_script.execution_time)
	scaling_value.text = _format_scaling(_selected_script.type_and_coef)
	description_label.text = _build_description(name, _selected_script)


func _build_description(name: String, script: StackScript) -> String:
	return tr("%s_desc" % name)


func _format_scaling(coeffs: Dictionary) -> String:
	if coeffs.is_empty():
		return "Aucun bonus"
	var parts: Array[String] = []
	var ordered := ["penetration", "encryption", "flux"]
	for key in ordered:
		var coef := float(coeffs.get(key, 0.0))
		if abs(coef) < 0.0001:
			continue
		parts.append("%s x%s" % [_format_stat_name(key), _format_number(coef)])

	return " / ".join(parts) if not parts.is_empty() else "Aucun bonus"


func _format_stat_name(key: String) -> String:
	match key:
		"penetration":
			return "Penetration"
		"encryption":
			return "Encryption"
		"flux":
			return "Flux"
		_:
			return key


func _format_script_name(name: String) -> String:
	var pretty := name.replace("_", " ")
	if pretty.length() == 0:
		return pretty
	if pretty.length() == 1:
		return pretty.to_upper()
	return pretty[0].to_upper() + pretty.substr(1, pretty.length() - 1)


func _format_number(value: float) -> String:
	# Affiche les floats courts sans trailing zeros inutiles.
	if int(value) == value:
		return str(int(value))
	return "%.2f" % value


func _script_kind_to_string(kind: int) -> String:
	match kind:
		StackScript.ScriptKind.DAMAGE:
			return "Degats"
		StackScript.ScriptKind.SHIELD:
			return "Bouclier"
		StackScript.ScriptKind.UTILITY:
			return "Utilitaire"
		_:
			return "Inconnu"


func _refresh_stats() -> void:
	var stats_dict := _get_hacker_stats()
	var pen := int(stats_dict.get("penetration", 0))
	var enc := int(stats_dict.get("encryption", 0))
	var flux := int(stats_dict.get("flux", 0))

	penetration_value.text = str(pen)
	encryption_value.text = str(enc)
	flux_value.text = str(flux)

	var hp_str := "-"
	if hacker != null:
		if hacker.entity_is_hacker:
			hacker.set_hacker_max_hp()
		hp_str = str(int(round(hacker.max_hp)))
	elif not stats_dict.is_empty():
		hp_str = str(int(round(_compute_hacker_hp(stats_dict))))
	hp_value.text = hp_str


func _get_hacker_stats() -> Dictionary:
	if typeof(StackManager.stack_script_stats) != TYPE_DICTIONARY:
		StackManager.stack_script_stats = {"penetration": 0, "encryption": 0, "flux": 0}
	return StackManager.stack_script_stats


func _compute_hacker_hp(stats_dict: Dictionary) -> float:
	var base_hp := 20.0
	var pen := float(stats_dict.get("penetration", 0))
	var enc := float(stats_dict.get("encryption", 0))
	var flux := float(stats_dict.get("flux", 0))
	return base_hp + pen + (enc * 1.5) + (flux * 0.5)


func _reset_details() -> void:
	stack_script_name.text = "Selectionne un script"
	type_value.text = "-"
	cooldown_value.text = "-"
	exec_value.text = "-"
	scaling_value.text = "-"
	description_label.text = "Choisis un script pour voir son effet."
	sequence_list.deselect_all()


func _on_scripts_list_item_selected(index: int) -> void:
	if index < 0 or index >= scripts_list.item_count:
		return
	_display_script(_get_item_name(scripts_list, index))


func _on_scripts_list_item_activated(index: int) -> void:
	_on_scripts_list_item_selected(index)
	if index < 0 or index >= scripts_list.item_count:
		return
	_add_to_sequence(_get_item_name(scripts_list, index), -1)


func _on_scripts_list_gui_input(event: InputEvent) -> void:
	_handle_drag_event(event, scripts_list, "available")


func _on_sequence_list_item_selected(index: int) -> void:
	if index < 0 or index >= sequence_list.item_count:
		return
	_display_script(_get_item_name(sequence_list, index))


func _on_sequence_list_item_activated(index: int) -> void:
	if index < 0 or index >= _sequence_names.size():
		return
	var removed := _sequence_names[index]
	_sequence_names.remove_at(index)
	if not _inventory_names.has(removed):
		_inventory_names.append(removed)
		_inventory_names.sort()
	_refresh_sequence_list(min(index, _sequence_names.size() - 1))
	_refresh_scripts_list()


func _on_sequence_list_gui_input(event: InputEvent) -> void:
	_handle_drag_event(event, sequence_list, "sequence")


func _add_to_sequence(name: String, insert_idx: int) -> void:
	if _sequence_names.size() >= max_slots:
		return
	if not _inventory_names.has(name):
		return
	if insert_idx < 0 or insert_idx > _sequence_names.size():
		_sequence_names.append(name)
	else:
		_sequence_names.insert(insert_idx, name)
	_inventory_names.erase(name)
	_refresh_sequence_list(insert_idx if insert_idx >= 0 else _sequence_names.size() - 1)
	_refresh_scripts_list()


func _refresh_sequence_list(select_idx: int = -1) -> void:
	sequence_list.clear()
	for n in _sequence_names:
		var display_name := _format_script_name(n)
		sequence_list.add_item(display_name)
		sequence_list.set_item_metadata(sequence_list.item_count - 1, n)
	if select_idx >= 0 and select_idx < sequence_list.item_count:
		sequence_list.select(select_idx)
	var selected_name_raw := _get_item_name(sequence_list, select_idx)
	_update_slots_label()


func _refresh_scripts_list() -> void:
	scripts_list.clear()
	for n in _inventory_names:
		var display_name := _format_script_name(n)
		scripts_list.add_item(display_name)
		scripts_list.set_item_metadata(scripts_list.item_count - 1, n)


func _update_slots_label() -> void:
	slots_label.text = "Slots : %d/%d" % [_sequence_names.size(), max_slots]


func _get_drag_data(at_position: Vector2):
	var mouse := get_global_mouse_position()

	if scripts_list.get_global_rect().has_point(mouse):
		var idx := scripts_list.get_item_at_position(scripts_list.get_local_mouse_position(), true)
		if idx != -1:
			var name := _get_item_name(scripts_list, idx)
			var preview := Label.new()
			preview.text = _format_script_name(name)
			return {"name": name, "source": "available", "from_index": idx, "preview": preview}

	if sequence_list.get_global_rect().has_point(mouse):
		var idx2 := sequence_list.get_item_at_position(sequence_list.get_local_mouse_position(), true)
		if idx2 != -1:
			var name2 := _get_item_name(sequence_list, idx2)
			var preview2 := Label.new()
			preview2.text = _format_script_name(name2)
			return {"name": name2, "source": "sequence", "from_index": idx2, "preview": preview2}

	return null


func _can_drop_data(at_position: Vector2, data) -> bool:
	if typeof(data) != TYPE_DICTIONARY or not data.has("name"):
		return false
	var mouse := get_global_mouse_position()

	if sequence_list.get_global_rect().has_point(mouse):
		# Ajout dans la sequence : on refuse si plein et pas un simple reorder
		if str(data.get("source", "")) == "sequence":
			return true
		return _sequence_names.size() < max_slots and _inventory_names.has(str(data.get("name", "")))

	if scripts_list.get_global_rect().has_point(mouse):
		# Permet de retirer via drag vers l'inventaire
		return str(data.get("source", "")) == "sequence"

	return false


func _drop_data(at_position: Vector2, data) -> void:
	if typeof(data) != TYPE_DICTIONARY or not data.has("name"):
		return

	var mouse := get_global_mouse_position()
	var source := str(data.get("source", ""))
	var from_idx := int(data.get("from_index", -1))
	var name := str(data.get("name", ""))

	if sequence_list.get_global_rect().has_point(mouse):
		var target_idx := sequence_list.get_item_at_position(sequence_list.get_local_mouse_position(), true)
		if target_idx == -1:
			target_idx = _sequence_names.size()

		if source == "sequence":
			if from_idx >= 0 and from_idx < _sequence_names.size():
				var moved = _sequence_names.pop_at(from_idx)
				if target_idx > _sequence_names.size():
					target_idx = _sequence_names.size()
				_sequence_names.insert(target_idx, moved)
				_refresh_sequence_list(target_idx)
		elif source == "available":
			_add_to_sequence(name, target_idx)
		return

	if scripts_list.get_global_rect().has_point(mouse) and source == "sequence":
		if from_idx >= 0 and from_idx < _sequence_names.size():
			var removed := _sequence_names[from_idx]
			_sequence_names.remove_at(from_idx)
			if not _inventory_names.has(removed):
				_inventory_names.append(removed)
				_inventory_names.sort()
			_refresh_sequence_list(-1)
			_refresh_scripts_list()


func _handle_drag_event(event: InputEvent, list: ItemList, source: String) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag_origin = source
			_drag_index = list.get_item_at_position(event.position, true)
			_drag_start_pos = event.position
			_drag_started = false
		else:
			_drag_origin = ""
			_drag_index = -1
			_drag_started = false
	elif event is InputEventMouseMotion:
		if _drag_origin == source and not _drag_started and _drag_index != -1:
			if event.position.distance_to(_drag_start_pos) >= DRAG_THRESHOLD:
				_drag_started = true
				var name := _get_item_name(list, _drag_index)
				var preview := Label.new()
				preview.text = _format_script_name(name)
				force_drag(_drag_data_payload(name, source, _drag_index), preview)


func _drag_data_payload(name: String, source: String, idx: int) -> Dictionary:
	return {"name": name, "source": source, "from_index": idx}


func _get_item_name(list: ItemList, index: int) -> String:
	if index < 0 or index >= list.item_count:
		return ""
	var meta = list.get_item_metadata(index)
	return str(meta) if meta != null else list.get_item_text(index)

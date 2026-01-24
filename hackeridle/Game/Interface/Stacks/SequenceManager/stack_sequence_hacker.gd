extends Control

@export var hacker: Entity
@export var max_slots: int = 5

@onready var scripts_scroll: Control = %ScriptsScroll
@onready var scripts_container: VBoxContainer = %ScriptsContainer
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
@onready var sequence_scroll: Control = %SequenceScroll
@onready var sequence_container: VBoxContainer = %SequenceContainer
@onready var slots_label: Label = %SlotsLabel

const SCRIPT_ENTRY_SCENE = preload("res://Game/Interface/Stacks/SequenceManager/ScriptEntry.tscn")
const SCRIPT_SLOT_SCENE = preload("res://Game/Interface/Stacks/SequenceManager/ScriptSlotPlaceholder.tscn")

var _script_lookup: Dictionary = {} # nom -> StackScript
var _selected_script: StackScript
var _selected_entry: Control
var _sequence_names: Array[String] = []
var _inventory_names: Array[String] = []

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
	if scripts_scroll.has_signal("script_drop"):
		scripts_scroll.connect("script_drop", Callable(self, "_on_scripts_drop"))
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
	_clear_scripts_container()
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
			_inventory_names.append(name)

	_refresh_scripts_list()


func _populate_sequence() -> void:
	_clear_sequence_container()
	_sequence_names.clear()

	if hacker != null and not hacker.sequence_order.is_empty():
		for name in hacker.sequence_order:
			if hacker.available_scripts.has(name):
				_sequence_names.append(str(name))

	# S'assure que max_slots couvre toujours la sequence existante
	max_slots = max(max_slots, _sequence_names.size())

	_ensure_sequence_slots()
	_refresh_sequence_list()


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
	_set_selected_entry(null)

func _on_script_entry_selected(name: String) -> void:
	_display_script(name)
	_select_entry_by_name_in(scripts_container, name)


func _on_script_entry_activated(name: String) -> void:
	_display_script(name)
	_add_to_sequence(name, -1)


func _on_sequence_entry_selected(name: String) -> void:
	_display_script(name)
	_select_entry_by_name_in(sequence_container, name)


func _on_sequence_entry_activated(name: String) -> void:
	var index := _sequence_names.find(name)
	if index == -1:
		return
	_sequence_names[index] = ""
	if not _inventory_names.has(name):
		_inventory_names.append(name)
		_inventory_names.sort()
	_refresh_sequence_list(min(index, _sequence_names.size() - 1))
	_refresh_scripts_list()


func _add_to_sequence(name: String, insert_idx: int) -> void:
	if not _inventory_names.has(name):
		return
	_ensure_sequence_slots()
	var target_idx := insert_idx
	if target_idx < 0:
		target_idx = _sequence_names.find("")
	if target_idx < 0 or target_idx >= max_slots:
		return
	if _sequence_names[target_idx] != "":
		return
	_sequence_names[target_idx] = name
	_inventory_names.erase(name)
	_refresh_sequence_list(target_idx)
	_refresh_scripts_list()


func _refresh_sequence_list(select_idx: int = -1) -> void:
	_clear_sequence_container()
	_ensure_sequence_slots()
	for i in range(max_slots):
		var n := _sequence_names[i]
		if n != "":
			var script_res = _script_lookup.get(n, null)
			if script_res is StackScript:
				var entry = SCRIPT_ENTRY_SCENE.instantiate()
				sequence_container.add_child(entry)
				entry.setup(n, _format_script_name(n), script_res.script_kind, _script_kind_to_string(script_res.script_kind), "sequence", i)
				entry.connect("selected", Callable(self, "_on_sequence_entry_selected"))
				entry.connect("activated", Callable(self, "_on_sequence_entry_activated"))
			else:
				_add_sequence_slot()
		else:
			_add_sequence_slot()
	if select_idx >= 0 and select_idx < _sequence_names.size() and _sequence_names[select_idx] != "":
		_select_entry_by_name_in(sequence_container, _sequence_names[select_idx])
		_display_script(_sequence_names[select_idx])
	_update_slots_label()


func _refresh_scripts_list() -> void:
	_clear_scripts_container()
	var first_name := ""
	for n in _inventory_names:
		var script_res = _script_lookup.get(n, null)
		if script_res is StackScript:
			var entry = SCRIPT_ENTRY_SCENE.instantiate()
			scripts_container.add_child(entry)
			entry.setup(n, _format_script_name(n), script_res.script_kind, _script_kind_to_string(script_res.script_kind), "available")
			entry.connect("selected", Callable(self, "_on_script_entry_selected"))
			entry.connect("activated", Callable(self, "_on_script_entry_activated"))
			if first_name == "":
				first_name = n
	if first_name != "":
		_display_script(first_name)
		_select_entry_by_name_in(scripts_container, first_name)


func _add_sequence_slot() -> void:
	var slot = SCRIPT_SLOT_SCENE.instantiate()
	sequence_container.add_child(slot)
	if slot.has_signal("slot_drop"):
		slot.connect("slot_drop", Callable(self, "_on_sequence_slot_drop"))


func _update_slots_label() -> void:
	var used := 0
	for n in _sequence_names:
		if n != "":
			used += 1
	slots_label.text = "Slots : %d/%d" % [used, max_slots]


func _can_drop_data(at_position: Vector2, data) -> bool:
	if typeof(data) != TYPE_DICTIONARY or not data.has("name"):
		return false
	var mouse := get_global_mouse_position()
	if scripts_scroll.get_global_rect().has_point(mouse):
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

	if sequence_scroll.get_global_rect().has_point(mouse):
		# Le drop sur la sequence est geré par les slots/entries
		return

	if scripts_scroll.get_global_rect().has_point(mouse) and source == "sequence":
		if from_idx >= 0 and from_idx < _sequence_names.size():
			var removed := _sequence_names[from_idx]
			_sequence_names[from_idx] = ""
			if removed != "":
				if not _inventory_names.has(removed):
					_inventory_names.append(removed)
					_inventory_names.sort()
				_refresh_sequence_list(-1)
				_refresh_scripts_list()


func _clear_scripts_container() -> void:
	for child in scripts_container.get_children():
		child.queue_free()


func _clear_sequence_container() -> void:
	for child in sequence_container.get_children():
		child.queue_free()


func _set_selected_entry(entry: Control) -> void:
	if _selected_entry != null and _selected_entry.has_method("set_selected"):
		_selected_entry.set_selected(false)
	_selected_entry = entry
	if _selected_entry != null and _selected_entry.has_method("set_selected"):
		_selected_entry.set_selected(true)


func _select_entry_by_name_in(container: VBoxContainer, name: String) -> void:
	var found: Control = null
	for child in container.get_children():
		if child.has_method("get_script_name") and child.get_script_name() == name:
			found = child
			break
	_set_selected_entry(found)


func _on_sequence_slot_drop(slot_index: int, data: Dictionary) -> void:
	var source := str(data.get("source", ""))
	var from_idx := int(data.get("from_index", -1))
	var name := str(data.get("name", ""))

	_ensure_sequence_slots()
	if slot_index < 0 or slot_index >= max_slots:
		return
	if _sequence_names[slot_index] != "":
		return
	if source == "available":
		_add_to_sequence(name, slot_index)
	elif source == "sequence":
		if from_idx >= 0 and from_idx < _sequence_names.size():
			var moved := _sequence_names[from_idx]
			if moved == "":
				return
			_sequence_names[from_idx] = ""
			_sequence_names[slot_index] = moved
			_refresh_sequence_list(slot_index)


func _on_clear_button_pressed() -> void:
	_ensure_sequence_slots()
	for i in range(_sequence_names.size()):
		var name := _sequence_names[i]
		if name == "":
			continue
		if not _inventory_names.has(name):
			_inventory_names.append(name)
		_sequence_names[i] = ""
	_inventory_names.sort()
	_refresh_sequence_list(-1)
	_refresh_scripts_list()


func _on_scripts_drop(data: Dictionary) -> void:
	var source := str(data.get("source", ""))
	if source != "sequence":
		return
	var from_idx := int(data.get("from_index", -1))
	if from_idx < 0 or from_idx >= _sequence_names.size():
		return
	var removed := _sequence_names[from_idx]
	if removed == "":
		return
	_sequence_names[from_idx] = ""
	if not _inventory_names.has(removed):
		_inventory_names.append(removed)
		_inventory_names.sort()
	_refresh_sequence_list(-1)
	_refresh_scripts_list()


func _ensure_sequence_slots() -> void:
	if _sequence_names.size() < max_slots:
		while _sequence_names.size() < max_slots:
			_sequence_names.append("")

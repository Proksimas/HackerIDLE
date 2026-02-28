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
@onready var bots_availible_label: Label = %BotsAvailibleLabel
@onready var bots_availible_value: Label = %BotsAvailibleValue
@onready var hp_plus_button: Button = %HpPlusButton
@onready var penetration_plus_button: Button = %PenetrationPlusButton
@onready var encryption_plus_button: Button = %EncryptionPlusButton
@onready var flux_plus_button: Button = %FluxPlusButton
@onready var sequence_scroll: Control = %SequenceScroll
@onready var sequence_container: VBoxContainer = %SequenceContainer
@onready var slots_label: Label = %SlotsLabel

const SCRIPT_ENTRY_SCENE = preload("res://Game/Interface/Stacks/SequenceManager/ScriptEntry.tscn")
const SCRIPT_SLOT_SCENE = preload("res://Game/Interface/Stacks/SequenceManager/ScriptSlotPlaceholder.tscn")
const LOADOUT_STATE = preload("res://Game/Interface/Stacks/SequenceManager/HackerLoadoutState.gd")
const SCRIPT_PRESENTER = preload("res://Game/Interface/Stacks/SequenceManager/StackScriptPresenter.gd")

var _script_lookup: Dictionary = {}
var _selected_script: StackScript
var _selected_entry: Control
var _loadout = LOADOUT_STATE.new()


func _ready() -> void:
	_reset_details()
	_refresh_stats()
	if Player.has_signal("s_earn_bots") and not Player.s_earn_bots.is_connected(_on_player_bots_changed):
		Player.s_earn_bots.connect(_on_player_bots_changed)
	if hp_plus_button != null and not hp_plus_button.pressed.is_connected(_on_hp_plus_button_pressed):
		hp_plus_button.pressed.connect(_on_hp_plus_button_pressed)
	if penetration_plus_button != null and not penetration_plus_button.pressed.is_connected(_on_penetration_plus_button_pressed):
		penetration_plus_button.pressed.connect(_on_penetration_plus_button_pressed)
	if encryption_plus_button != null and not encryption_plus_button.pressed.is_connected(_on_encryption_plus_button_pressed):
		encryption_plus_button.pressed.connect(_on_encryption_plus_button_pressed)
	if flux_plus_button != null and not flux_plus_button.pressed.is_connected(_on_flux_plus_button_pressed):
		flux_plus_button.pressed.connect(_on_flux_plus_button_pressed)
	if scripts_scroll.has_signal("script_drop"):
		scripts_scroll.connect("script_drop", Callable(self, "_on_scripts_drop"))


func load_hacker(target: Entity) -> void:
	hacker = target
	_refresh_stats()
	_populate_lists()
	_persist_hacker_loadout()


func _populate_lists() -> void:
	_script_lookup.clear()
	var known_names: Array[String] = []

	if hacker != null and not hacker.available_scripts.is_empty():
		for key in hacker.available_scripts.keys():
			var script_name := str(key)
			var script_res = hacker.available_scripts.get(script_name, null)
			if script_res is StackScript:
				_script_lookup[script_name] = script_res
				known_names.append(script_name)
	known_names.sort()

	var initial_sequence: Array[String] = []
	if hacker != null and not hacker.sequence_order.is_empty():
		for script_name in hacker.sequence_order:
			var name := str(script_name)
			if _script_lookup.has(name):
				initial_sequence.append(name)

	max_slots = max(max_slots, initial_sequence.size())
	_loadout.setup(known_names, initial_sequence, max_slots)

	_refresh_scripts_list()
	_refresh_sequence_list()


func _display_script(script_name: String) -> void:
	if not _script_lookup.has(script_name):
		_reset_details()
		return

	_selected_script = _script_lookup[script_name]
	stack_script_name.text = SCRIPT_PRESENTER.format_script_name(script_name)
	type_value.text = SCRIPT_PRESENTER.script_kind_to_string(_selected_script.script_kind)
	cooldown_value.text = "%d tour(s)" % int(_selected_script.turn_cooldown_base)
	exec_value.text = "%.1f s" % float(_selected_script.execution_time)
	scaling_value.text = SCRIPT_PRESENTER.format_scaling(_selected_script.type_and_coef)
	description_label.text = tr("%s_desc" % script_name)


func _refresh_stats() -> void:
	var stats_dict := _get_hacker_stats()
	var pen := int(stats_dict.get("penetration", 0))
	var enc := int(stats_dict.get("encryption", 0))
	var flux := int(stats_dict.get("flux", 0))

	penetration_value.text = str(pen)
	encryption_value.text = str(enc)
	flux_value.text = str(flux)
	bots_availible_label.text = "Bots dispo"
	bots_availible_value.text = str(Player.bots)
	_update_stat_buttons()

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
		StackManager.stack_script_stats = {"penetration": 0, "encryption": 0, "flux": 0, "hp_bonus": 0}
	return StackManager.stack_script_stats


func _compute_hacker_hp(stats_dict: Dictionary) -> float:
	var base_hp := 20.0
	var pen := float(stats_dict.get("penetration", 0))
	var enc := float(stats_dict.get("encryption", 0))
	var flux := float(stats_dict.get("flux", 0))
	var hp_bonus := float(stats_dict.get("hp_bonus", 0))
	return base_hp + pen + enc + flux + hp_bonus


func _update_stat_buttons() -> void:
	var can_buy := Player.bots > 0
	if hp_plus_button != null:
		hp_plus_button.disabled = not can_buy
	if penetration_plus_button != null:
		penetration_plus_button.disabled = not can_buy
	if encryption_plus_button != null:
		encryption_plus_button.disabled = not can_buy
	if flux_plus_button != null:
		flux_plus_button.disabled = not can_buy


func _on_player_bots_changed(_value: int) -> void:
	_refresh_stats()


func _on_hp_plus_button_pressed() -> void:
	if StackManager.spend_bot_for_hp_bonus():
		_refresh_stats()


func _on_penetration_plus_button_pressed() -> void:
	if StackManager.spend_bot_for_stat("penetration"):
		_refresh_stats()


func _on_encryption_plus_button_pressed() -> void:
	if StackManager.spend_bot_for_stat("encryption"):
		_refresh_stats()


func _on_flux_plus_button_pressed() -> void:
	if StackManager.spend_bot_for_stat("flux"):
		_refresh_stats()


func _reset_details() -> void:
	stack_script_name.text = "Selectionne un script"
	type_value.text = "-"
	cooldown_value.text = "-"
	exec_value.text = "-"
	scaling_value.text = "-"
	description_label.text = "Choisis un script pour voir son effet."
	_set_selected_entry(null)


func _on_script_entry_selected(script_name: String) -> void:
	_display_script(script_name)
	_select_entry_by_name_in(scripts_container, script_name)


func _on_script_entry_activated(script_name: String) -> void:
	_display_script(script_name)
	_add_to_sequence(script_name, -1)


func _on_sequence_entry_selected(script_name: String) -> void:
	_display_script(script_name)
	_select_entry_by_name_in(sequence_container, script_name)


func _on_sequence_entry_activated(script_name: String) -> void:
	var index = _loadout.sequence_names.find(script_name)
	if index == -1:
		return
	_loadout.remove_from_sequence(index)
	_refresh_sequence_list(min(index, _loadout.sequence_names.size() - 1))
	_refresh_scripts_list()


func _add_to_sequence(script_name: String, insert_idx: int) -> void:
	if not _loadout.add_to_sequence(script_name, insert_idx):
		return
	var target_idx := insert_idx
	if target_idx < 0:
		target_idx = _loadout.sequence_names.find(script_name)
	_refresh_sequence_list(target_idx)
	_refresh_scripts_list()


func _refresh_sequence_list(select_idx: int = -1) -> void:
	_clear_sequence_container()
	_ensure_sequence_slots()
	for i in range(max_slots):
		var script_name = _loadout.sequence_names[i]
		if script_name != "":
			var script_res = _script_lookup.get(script_name, null)
			if script_res is StackScript:
				var entry = SCRIPT_ENTRY_SCENE.instantiate()
				sequence_container.add_child(entry)
				entry.setup(
					script_name,
					SCRIPT_PRESENTER.format_script_name(script_name),
					script_res.script_kind,
					SCRIPT_PRESENTER.script_kind_to_string(script_res.script_kind),
					"sequence",
					i
				)
				entry.connect("selected", Callable(self, "_on_sequence_entry_selected"))
				entry.connect("activated", Callable(self, "_on_sequence_entry_activated"))
			else:
				_add_sequence_slot()
		else:
			_add_sequence_slot()

	if select_idx >= 0 and select_idx < _loadout.sequence_names.size():
		var selected_name = _loadout.sequence_names[select_idx]
		if selected_name != "":
			_select_entry_by_name_in(sequence_container, selected_name)
			_display_script(selected_name)

	_update_slots_label()
	_persist_hacker_loadout()


func _persist_hacker_loadout() -> void:
	if hacker == null:
		return
	var known_scripts: Array[String] = []
	for key in hacker.available_scripts.keys():
		known_scripts.append(str(key))
	StackManager.save_hacker_loadout(known_scripts, _loadout.sequence_compact())


func _refresh_scripts_list() -> void:
	_clear_scripts_container()
	var first_name := ""
	for script_name in _loadout.inventory_names:
		var script_res = _script_lookup.get(script_name, null)
		if script_res is StackScript:
			var entry = SCRIPT_ENTRY_SCENE.instantiate()
			scripts_container.add_child(entry)
			entry.setup(
				script_name,
				SCRIPT_PRESENTER.format_script_name(script_name),
				script_res.script_kind,
				SCRIPT_PRESENTER.script_kind_to_string(script_res.script_kind),
				"available"
			)
			entry.connect("selected", Callable(self, "_on_script_entry_selected"))
			entry.connect("activated", Callable(self, "_on_script_entry_activated"))
			if first_name == "":
				first_name = script_name

	if first_name != "":
		_display_script(first_name)
		_select_entry_by_name_in(scripts_container, first_name)


func _add_sequence_slot() -> void:
	var slot = SCRIPT_SLOT_SCENE.instantiate()
	sequence_container.add_child(slot)
	if slot.has_signal("slot_drop"):
		slot.connect("slot_drop", Callable(self, "_on_sequence_slot_drop"))


func _update_slots_label() -> void:
	slots_label.text = "Slots : %d/%d" % [_loadout.used_slots_count(), max_slots]


func _can_drop_data(_at_position: Vector2, data) -> bool:
	if typeof(data) != TYPE_DICTIONARY or not data.has("name"):
		return false
	var mouse := get_global_mouse_position()
	if scripts_scroll.get_global_rect().has_point(mouse):
		return str(data.get("source", "")) == "sequence"
	return false


func _drop_data(_at_position: Vector2, data) -> void:
	if typeof(data) != TYPE_DICTIONARY or not data.has("name"):
		return

	var mouse := get_global_mouse_position()
	var source := str(data.get("source", ""))
	var from_idx := int(data.get("from_index", -1))

	if sequence_scroll.get_global_rect().has_point(mouse):
		return

	if scripts_scroll.get_global_rect().has_point(mouse) and source == "sequence":
		if _loadout.remove_from_sequence(from_idx) != "":
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


func _select_entry_by_name_in(container: VBoxContainer, script_name: String) -> void:
	var found: Control = null
	for child in container.get_children():
		if child.has_method("get_script_name") and child.get_script_name() == script_name:
			found = child
			break
	_set_selected_entry(found)


func _on_sequence_slot_drop(slot_index: int, data: Dictionary) -> void:
	var source := str(data.get("source", ""))
	var from_idx := int(data.get("from_index", -1))
	var script_name := str(data.get("name", ""))

	_ensure_sequence_slots()
	if slot_index < 0 or slot_index >= max_slots:
		return
	if _loadout.sequence_names[slot_index] != "":
		return

	if source == "available":
		_add_to_sequence(script_name, slot_index)
	elif source == "sequence":
		if _loadout.move_sequence_script(from_idx, slot_index):
			_refresh_sequence_list(slot_index)


func _on_clear_button_pressed() -> void:
	_loadout.clear_sequence()
	_refresh_sequence_list(-1)
	_refresh_scripts_list()


func _on_scripts_drop(data: Dictionary) -> void:
	var source := str(data.get("source", ""))
	if source != "sequence":
		return
	var from_idx := int(data.get("from_index", -1))
	if _loadout.remove_from_sequence(from_idx) == "":
		return
	_refresh_sequence_list(-1)
	_refresh_scripts_list()


func _ensure_sequence_slots() -> void:
	_loadout.set_max_slots(max_slots)

class_name HackerLoadoutState
extends RefCounted

var max_slots: int = 0
var inventory_names: Array[String] = []
var sequence_names: Array[String] = []


func setup(known_scripts: Array[String], initial_sequence: Array[String], slots: int) -> void:
	max_slots = max(0, slots)
	inventory_names = known_scripts.duplicate()
	inventory_names.sort()
	sequence_names.clear()

	for script_name in initial_sequence:
		if inventory_names.has(script_name):
			sequence_names.append(script_name)
			inventory_names.erase(script_name)

	_ensure_slots()


func set_max_slots(slots: int) -> void:
	max_slots = max(0, slots)
	_ensure_slots()


func add_to_sequence(script_name: String, insert_idx: int = -1) -> bool:
	if not inventory_names.has(script_name):
		return false

	_ensure_slots()
	var target_idx := insert_idx
	if target_idx < 0:
		target_idx = sequence_names.find("")
	if target_idx < 0 or target_idx >= max_slots:
		return false
	if sequence_names[target_idx] != "":
		return false

	sequence_names[target_idx] = script_name
	inventory_names.erase(script_name)
	return true


func remove_from_sequence(index: int) -> String:
	_ensure_slots()
	if index < 0 or index >= sequence_names.size():
		return ""
	var removed := sequence_names[index]
	if removed == "":
		return ""
	sequence_names[index] = ""
	if not inventory_names.has(removed):
		inventory_names.append(removed)
		inventory_names.sort()
	return removed


func move_sequence_script(from_idx: int, to_idx: int) -> bool:
	_ensure_slots()
	if from_idx < 0 or from_idx >= sequence_names.size():
		return false
	if to_idx < 0 or to_idx >= max_slots:
		return false
	if sequence_names[to_idx] != "":
		return false
	var moved := sequence_names[from_idx]
	if moved == "":
		return false
	sequence_names[from_idx] = ""
	sequence_names[to_idx] = moved
	return true


func clear_sequence() -> void:
	_ensure_slots()
	for i in range(sequence_names.size()):
		var script_name := sequence_names[i]
		if script_name == "":
			continue
		if not inventory_names.has(script_name):
			inventory_names.append(script_name)
		sequence_names[i] = ""
	inventory_names.sort()


func used_slots_count() -> int:
	var used := 0
	for script_name in sequence_names:
		if script_name != "":
			used += 1
	return used


func sequence_compact() -> Array[String]:
	var result: Array[String] = []
	for script_name in sequence_names:
		if script_name != "":
			result.append(script_name)
	return result


func _ensure_slots() -> void:
	while sequence_names.size() < max_slots:
		sequence_names.append("")

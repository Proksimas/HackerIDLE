extends Node

const STACK_FIGHT = preload("res://Game/Stacks/stack_fight.tscn")
const DEFAULT_HACKER_SEQUENCE: Array[String] = []
const DEFAULT_HACKER_KNOWN_SCRIPTS: Array[String] = []
const FIRST_NOVANET_KNOWN_SCRIPTS: Array[String] = ["syn_flood"]
const HP_BONUS_PER_BOT: int = 3
const STACK_SCRIPT_DB: StackScriptDB = preload("res://Game/DB/stack_script_db.tres")

var stack_script_pool: Dictionary
var stack_hacker_script_learned: Dictionary # scripts connus du hacker
var stack_hacker_sequence: Array[String] # ordre de sequence sauvegarde
var stack_script_stats: Dictionary # stats derivees des bots
var stack_hacker_extra_slots: Dictionary # slots supplementaires donnes par des sources externes
signal s_hacker_loadout_changed

func _ready() -> void:
	_init()

func _init() -> void:
	stack_script_pool = {}
	stack_hacker_script_learned = {}
	stack_hacker_sequence = []
	stack_hacker_extra_slots = {}
	initialize_pool()
	stack_script_stats = {
		"penetration": 0,
		"encryption": 0,
		"flux": 0,
		"hp_bonus": 0
	}

func ensure_initialized() -> void:
	if typeof(stack_script_pool) != TYPE_DICTIONARY:
		stack_script_pool = {}
	if stack_script_pool.is_empty():
		initialize_pool()
	if typeof(stack_hacker_script_learned) != TYPE_DICTIONARY:
		stack_hacker_script_learned = {}
	if typeof(stack_hacker_sequence) != TYPE_ARRAY:
		stack_hacker_sequence = []
	if typeof(stack_hacker_extra_slots) != TYPE_DICTIONARY:
		stack_hacker_extra_slots = {}
	if typeof(stack_script_stats) != TYPE_DICTIONARY:
		stack_script_stats = {}
	for stat_name in ["penetration", "encryption", "flux", "hp_bonus"]:
		if not stack_script_stats.has(stat_name):
			stack_script_stats[stat_name] = 0

func new_fight(_hacker: Entity, _robots: Array[Entity]) -> StackFight:
	ensure_initialized()
	var fight = STACK_FIGHT.instantiate()
	self.add_child(fight)
	# fight.start_fight(_hacker, robots) -> start par l'UI
	return fight

func create_hacker_entity() -> Entity:
	"""Fabrique le hacker avec un loadout centralise."""
	ensure_initialized()

	var hacker := Entity.new(true)
	for script_name in stack_hacker_script_learned.keys():
		learn_stack_script(hacker, str(script_name))

	if hacker.available_scripts.is_empty():
		for script_name in DEFAULT_HACKER_KNOWN_SCRIPTS:
			learn_stack_script(hacker, script_name)

	hacker.save_sequence(_resolve_hacker_sequence(hacker.available_scripts))
	return hacker

func has_hacker_script(script_name: String) -> bool:
	ensure_initialized()
	return bool(stack_hacker_script_learned.get(script_name, false))

func unlock_hacker_script(script_name: String, add_to_sequence_if_missing: bool = false) -> bool:
	"""Debloque un script pour le hacker de run."""
	ensure_initialized()
	if not stack_script_pool.has(script_name):
		push_warning("Script introuvable pour le hacker: %s" % script_name)
		return false
	if stack_hacker_script_learned.has(script_name):
		return false
	stack_hacker_script_learned[script_name] = true
	if add_to_sequence_if_missing:
		_seed_default_sequence_if_needed()
		if not stack_hacker_sequence.has(script_name):
			stack_hacker_sequence.append(script_name)
	s_hacker_loadout_changed.emit()
	return true

func apply_first_novanet_grant() -> void:
	"""Premiere entree NovaNet: syn_flood seul, sequence vide."""
	ensure_initialized()

	var known_scripts: Array[String] = []
	for script_name in FIRST_NOVANET_KNOWN_SCRIPTS:
		if stack_script_pool.has(script_name):
			known_scripts.append(script_name)

	save_hacker_loadout(known_scripts, [])

func reset_hacker_loadout_for_rebirth() -> void:
	"""Reset rebirth: seul syn_flood reste connu et les stats de stack repartent a zero."""
	ensure_initialized()
	stack_script_stats = {
		"penetration": 0,
		"encryption": 0,
		"flux": 0,
		"hp_bonus": 0
	}
	var known_scripts: Array[String] = []
	var default_sequence: Array[String] = []
	for script_name in FIRST_NOVANET_KNOWN_SCRIPTS:
		if stack_script_pool.has(script_name):
			known_scripts.append(script_name)
			default_sequence.append(script_name)

	save_hacker_loadout(known_scripts, default_sequence)

func save_hacker_loadout(known_scripts: Array[String], sequence: Array[String]) -> void:
	"""Sauvegarde les scripts connus et la sequence du hacker."""
	ensure_initialized()

	stack_hacker_script_learned.clear()
	for script_name in known_scripts:
		if stack_script_pool.has(script_name):
			stack_hacker_script_learned[script_name] = true

	stack_hacker_sequence.clear()
	var used_scripts: Dictionary = {}
	for script_name in sequence:
		if not stack_hacker_script_learned.has(script_name):
			continue
		if used_scripts.has(script_name):
			continue
		stack_hacker_sequence.append(script_name)
		used_scripts[script_name] = true
	s_hacker_loadout_changed.emit()

func save_hacker_sequence(sequence: Array[String]) -> void:
	"""Sauvegarde seulement la sequence equipee."""
	ensure_initialized()
	stack_hacker_sequence.clear()

	var used_scripts: Dictionary = {}
	for script_name in sequence:
		if not stack_hacker_script_learned.has(script_name):
			continue
		if used_scripts.has(script_name):
			continue
		stack_hacker_sequence.append(script_name)
		used_scripts[script_name] = true

	s_hacker_loadout_changed.emit()

func can_unlock_hacker_script(script_name: String) -> bool:
	ensure_initialized()
	if not stack_script_pool.has(script_name):
		return false
	return not has_hacker_script(script_name)

func sync_hacker_entity_loadout(entity: Entity) -> void:
	"""Applique le loadout hacker sauvegarde a une entite active."""
	if entity == null or not entity.entity_is_hacker:
		return
	ensure_initialized()
	for script_name_variant in stack_hacker_script_learned.keys():
		var script_name := str(script_name_variant)
		if has_hacker_script(script_name) and not entity.available_scripts.has(script_name):
			learn_stack_script(entity, script_name)
	var sequence: Array[String] = []
	var used_scripts: Dictionary = {}
	for script_name in stack_hacker_sequence:
		if entity.available_scripts.has(script_name):
			if used_scripts.has(script_name):
				continue
			sequence.append(script_name)
			used_scripts[script_name] = true
	entity.save_sequence(sequence)
	entity.set_hacker_max_hp()

func get_hacker_max_slots(base_slots: int) -> int:
	ensure_initialized()
	var slots = max(0, base_slots)
	for source in stack_hacker_extra_slots:
		slots += max(0, int(stack_hacker_extra_slots[source]))
	return slots

func set_hacker_extra_slots(source: String, slots: int) -> void:
	ensure_initialized()
	var cleaned_source := source.strip_edges()
	if cleaned_source == "":
		return
	if slots <= 0:
		stack_hacker_extra_slots.erase(cleaned_source)
	else:
		stack_hacker_extra_slots[cleaned_source] = slots
	s_hacker_loadout_changed.emit()

func learn_stack_script(learner: Entity, stack_script_name: String) -> bool:
	"""Donne a l'entite le script passe en parametre."""
	ensure_initialized()
	if stack_script_pool.has(stack_script_name):
		var script_resource := _get_stack_script_resource(stack_script_name)
		if script_resource is StackScript:
			learner.available_scripts[stack_script_name] = script_resource.duplicate(true)
			return true
	else:
		push_warning("Probleme dans l'apprentissage du stack script %s" % stack_script_name)
		return false
	push_warning("Ressource invalide pour le stack script %s" % stack_script_name)
	return false

func learn_all_script(learner: Entity) -> void:
	"""Apprend tous les scripts du pool pour l'entite donnee."""
	if learner == null:
		return
	ensure_initialized()
	for script_name in stack_script_pool.keys():
		learn_stack_script(learner, str(script_name))

func initialize_pool() -> void:
	"""Initialisation du pool de scripts."""
	stack_script_pool.clear()
	if STACK_SCRIPT_DB == null:
		push_error("StackScriptDB introuvable.")
		return
	for script_resource in STACK_SCRIPT_DB.scripts:
		if script_resource == null:
			continue
		var script_name := str(script_resource.stack_script_name).strip_edges()
		if script_name == "":
			push_warning("StackScript ignore: nom vide dans la DB.")
			continue
		stack_script_pool[script_name] = script_resource

func _get_stack_script_resource(script_name: String) -> StackScript:
	ensure_initialized()
	var script_entry = stack_script_pool.get(script_name, null)
	if script_entry is StackScript:
		return script_entry
	if script_entry is String:
		var loaded_script = load(script_entry)
		if loaded_script is StackScript:
			return loaded_script
	return null

func _seed_default_sequence_if_needed() -> void:
	if not stack_hacker_sequence.is_empty():
		return
	for script_name in DEFAULT_HACKER_SEQUENCE:
		if stack_script_pool.has(script_name):
			stack_hacker_sequence.append(script_name)

func _resolve_hacker_sequence(available_scripts: Dictionary) -> Array[String]:
	var source: Array[String] = stack_hacker_sequence if not stack_hacker_sequence.is_empty() else DEFAULT_HACKER_SEQUENCE
	var resolved: Array[String] = []
	for script_name in source:
		if available_scripts.has(script_name):
			resolved.append(script_name)

	if resolved.is_empty():
		for script_name in DEFAULT_HACKER_SEQUENCE:
			if available_scripts.has(script_name):
				resolved.append(script_name)

	return resolved

func spend_bot_for_stat(stat_name: String, bot_count: int = 1) -> bool:
	"""Consomme des bots pour augmenter une stat du hacker."""
	bot_count = max(1, bot_count)
	if Player.bots < bot_count:
		return false
	if stat_name not in ["penetration", "encryption", "flux", "hp_bonus"]:
		return false
	if typeof(stack_script_stats) != TYPE_DICTIONARY:
		stack_script_stats = {"penetration": 0, "encryption": 0, "flux": 0, "hp_bonus": 0}
	if not stack_script_stats.has(stat_name):
		stack_script_stats[stat_name] = 0

	Player.bots -= bot_count
	stack_script_stats[stat_name] = int(stack_script_stats.get(stat_name, 0)) + bot_count
	s_hacker_loadout_changed.emit()
	return true

func spend_bot_for_hp_bonus(hp_to_add: int = HP_BONUS_PER_BOT, bot_count: int = 1) -> bool:
	"""Consomme des bots pour augmenter les PV max plats."""
	bot_count = max(1, bot_count)
	if Player.bots < bot_count:
		return false
	if hp_to_add <= 0:
		return false
	if typeof(stack_script_stats) != TYPE_DICTIONARY:
		stack_script_stats = {"penetration": 0, "encryption": 0, "flux": 0, "hp_bonus": 0}

	Player.bots -= bot_count
	stack_script_stats["hp_bonus"] = int(stack_script_stats.get("hp_bonus", 0)) + (hp_to_add * bot_count)
	s_hacker_loadout_changed.emit()
	return true

func set_hacker_stat(stat_name: String, value: int) -> bool:
	"""Force une stat precise du hacker."""
	if stat_name not in ["penetration", "encryption", "flux", "hp_bonus"]:
		return false
	if typeof(stack_script_stats) != TYPE_DICTIONARY:
		stack_script_stats = {"penetration": 0, "encryption": 0, "flux": 0, "hp_bonus": 0}

	stack_script_stats[stat_name] = max(0, int(value))
	s_hacker_loadout_changed.emit()
	return true

func set_hacker_stats(new_stats: Dictionary, keep_unspecified: bool = true) -> void:
	"""Met a jour les stats du hacker.
	- keep_unspecified=true: ne change que les cles fournies
	- keep_unspecified=false: reset les autres cles a 0
	"""
	var allowed := ["penetration", "encryption", "flux", "hp_bonus"]
	var base := {"penetration": 0, "encryption": 0, "flux": 0, "hp_bonus": 0}

	if typeof(stack_script_stats) != TYPE_DICTIONARY:
		stack_script_stats = base.duplicate(true)

	if not keep_unspecified:
		stack_script_stats = base.duplicate(true)

	for key in allowed:
		if new_stats.has(key):
			stack_script_stats[key] = max(0, int(new_stats[key]))
		elif not stack_script_stats.has(key):
			stack_script_stats[key] = 0

	s_hacker_loadout_changed.emit()

func _save_data() -> Dictionary:
	ensure_initialized()
	return {
		"stack_hacker_script_learned": stack_hacker_script_learned.duplicate(true),
		"stack_hacker_sequence": stack_hacker_sequence.duplicate(true),
		"stack_script_stats": stack_script_stats.duplicate(true),
		"stack_hacker_extra_slots": stack_hacker_extra_slots.duplicate(true)
	}

func _load_data(content: Dictionary) -> void:
	if typeof(content) != TYPE_DICTIONARY:
		return
	ensure_initialized()

	stack_hacker_script_learned.clear()
	stack_hacker_sequence.clear()
	stack_hacker_extra_slots.clear()
	stack_script_stats = {
		"penetration": 0,
		"encryption": 0,
		"flux": 0,
		"hp_bonus": 0
	}

	var saved_learned = content.get("stack_hacker_script_learned", {})
	var saved_sequence = content.get("stack_hacker_sequence", [])
	var saved_stats = content.get("stack_script_stats", {})
	var saved_extra_slots = content.get("stack_hacker_extra_slots", {})

	if saved_learned is Dictionary:
		for script_name_variant in saved_learned.keys():
			var script_name := str(script_name_variant)
			if stack_script_pool.has(script_name) and bool(saved_learned[script_name_variant]):
				stack_hacker_script_learned[script_name] = true

	if saved_sequence is Array:
		var used_scripts: Dictionary = {}
		for script_name_variant in saved_sequence:
			var script_name := str(script_name_variant)
			if not stack_hacker_script_learned.has(script_name):
				continue
			if used_scripts.has(script_name):
				continue
			stack_hacker_sequence.append(script_name)
			used_scripts[script_name] = true

	if saved_stats is Dictionary:
		for stat_name in ["penetration", "encryption", "flux", "hp_bonus"]:
			if saved_stats.has(stat_name):
				stack_script_stats[stat_name] = max(0, int(saved_stats[stat_name]))

	if saved_extra_slots is Dictionary:
		for source_variant in saved_extra_slots.keys():
			var source := str(source_variant).strip_edges()
			if source != "":
				stack_hacker_extra_slots[source] = max(0, int(saved_extra_slots[source_variant]))

extends Node

const stack_dir_path = "res://Game/Stacks/StackScript/"
const STACK_FIGHT = preload("res://Game/Stacks/stack_fight.tscn")
const DEFAULT_HACKER_SEQUENCE: Array[String] = []
const DEFAULT_HACKER_KNOWN_SCRIPTS: Array[String] = []
const FIRST_NOVANET_KNOWN_SCRIPTS: Array[String] = ["syn_flood"]

var stack_script_pool: Dictionary
var stack_hacker_script_learned: Dictionary # scripts connus du hacker
var stack_hacker_sequence: Array[String] # ordre de sequence sauvegarde
var stack_script_stats: Dictionary # stats derivees des bots
signal s_hacker_loadout_changed

func _ready() -> void:
	_init()
	pass

func _init() -> void:
	stack_script_pool = {}
	stack_hacker_script_learned = {}
	stack_hacker_sequence = []
	initialize_pool()
	stack_script_stats = {
		"penetration": 0,
		"encryption": 0,
		"flux": 0
	}

func new_fight(_hacker: Entity, _robots: Array[Entity]) -> StackFight:
	var fight = STACK_FIGHT.instantiate()
	self.add_child(fight)
	# fight.start_fight(_hacker, robots) -> start par l'UI
	return fight

func create_hacker_entity() -> Entity:
	"""Fabrique le hacker avec un loadout centralise."""
	if stack_script_pool.is_empty():
		initialize_pool()

	var hacker := Entity.new(true)
	for script_name in stack_hacker_script_learned.keys():
		learn_stack_script(hacker, str(script_name))

	if hacker.available_scripts.is_empty():
		for script_name in DEFAULT_HACKER_KNOWN_SCRIPTS:
			learn_stack_script(hacker, script_name)

	hacker.save_sequence(_resolve_hacker_sequence(hacker.available_scripts))
	return hacker

func unlock_hacker_script(script_name: String, add_to_sequence_if_missing: bool = false) -> bool:
	"""Debloque un script pour le hacker de run. Idempotent."""
	if stack_script_pool.is_empty():
		initialize_pool()
	if not stack_script_pool.has(script_name):
		push_warning("Script introuvable pour le hacker: %s" % script_name)
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
	if stack_script_pool.is_empty():
		initialize_pool()

	var known_scripts: Array[String] = []
	for script_name in FIRST_NOVANET_KNOWN_SCRIPTS:
		if stack_script_pool.has(script_name):
			known_scripts.append(script_name)

	save_hacker_loadout(known_scripts, [])

func save_hacker_loadout(known_scripts: Array[String], sequence: Array[String]) -> void:
	"""Sauvegarde les scripts connus et la sequence du hacker."""
	if stack_script_pool.is_empty():
		initialize_pool()

	stack_hacker_script_learned.clear()
	for script_name in known_scripts:
		if stack_script_pool.has(script_name):
			stack_hacker_script_learned[script_name] = true

	stack_hacker_sequence.clear()
	for script_name in sequence:
		if stack_hacker_script_learned.has(script_name):
			stack_hacker_sequence.append(script_name)
	s_hacker_loadout_changed.emit()

func learn_stack_script(learner: Entity, stack_script_name: String) -> bool:
	"""Donne a l'entite le script passe en parametre."""
	if stack_script_pool.has(stack_script_name):
		var script = stack_script_pool[stack_script_name]
		learner.available_scripts[stack_script_name] = load(script).duplicate(true)
		return true
	else:
		push_warning("Probleme dans l'apprentissage du stack script %s" % stack_script_name)
		return false

func learn_all_script(learner: Entity) -> void:
	"""Apprend tous les scripts du pool pour l'entite donnee."""
	if learner == null:
		return
	if stack_script_pool.is_empty():
		initialize_pool()
	for script_name in stack_script_pool.keys():
		learn_stack_script(learner, str(script_name))

func initialize_pool() -> void:
	"""Initialisation du pool de scripts."""
	stack_script_pool.clear()
	var dir = DirAccess.open(stack_dir_path)
	if dir:
		dir.list_dir_begin()
		var nom_element = dir.get_next()
		while nom_element != "":
			if dir.current_is_dir():
				pass
			elif nom_element.ends_with(".gd") or nom_element == "stack_script.tres":
				pass
			else:
				var chemin_complet = dir.get_current_dir().path_join(nom_element)
				var file_name = nom_element.trim_suffix(".tres")
				stack_script_pool[file_name] = chemin_complet

			nom_element = dir.get_next()

		dir.list_dir_end()
	else:
		print("Erreur d'ouverture du dossier.")

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

func _save_data():
	# TODO
	pass

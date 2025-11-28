extends Node

const stack_dir_path = "res://Game/Stacks/StackScript/"
const STACK_FIGHT = preload("res://Game/Stacks/stack_fight.tscn")

var stack_script_pool: Dictionary

var stack_script_stats: Dictionary # correspond aux robots affectés

func _ready() -> void:
	
	_init()
	pass # Replace with function body.

func _init() -> void:
	stack_script_pool.clear()
	initialize_pool()
	stack_script_stats = {"penetration": 0,
							"encryption": 0,
							"flux": 0}

func new_fight(_hacker: Entity, robots: Array[Entity]):
	var fight = STACK_FIGHT.instantiate()
	self.add_child(fight)
	fight.start_fight(_hacker, robots)

func learn_stack_script(learner: Entity, stack_script_name: String) -> bool:
	"""on donne à l'entité le script donné en nom en paramaètre"""
	if stack_script_pool.has(stack_script_name): 
		var script = stack_script_pool[stack_script_name]
		learner.available_scripts[stack_script_name] = load(script).duplicate(true)
		return true
	else:
		push_warning("Probleme dans l'apprentissage du stack script %s" % stack_script_name)
		return false
	
func initialize_pool():
	"""initialisation du pool de script"""
	var dir = DirAccess.open(stack_dir_path)
	if dir:
		dir.list_dir_begin()
		var nom_element = dir.get_next()
		while nom_element != "":
			if dir.current_is_dir():
				# C'est un sous-dossier, novous pouvez appeler cette fonction récursivement
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


func _save_data():
	# TODO
	pass

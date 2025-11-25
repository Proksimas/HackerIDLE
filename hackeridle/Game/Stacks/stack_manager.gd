extends Node

const stack_dir_path = "res://Game/Stacks/StackScript/"
var stack_script_pool: Dictionary

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	stack_script_pool.clear()
	initialize_pool()
	print(stack_script_pool)
	pass # Replace with function body.



func learn_stack_script(stack_script_name: String):
	
	pass
	
func initialize_pool():
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

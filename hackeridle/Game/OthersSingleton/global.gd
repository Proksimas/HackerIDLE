extends Node


func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		print("Erreur: Le fichier JSON n'existe pas.")
		return {}

	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	file.close()

	var json_result = JSON.parse_string(content)
	if json_result is Dictionary:
		return json_result
	else:
		print("Erreur: Le fichier JSON n'est pas valide.")
		return {}


func number_to_string(number) -> String:
	if number < 1000:
		return str(number)
	elif number >= pow(10, 3) and number < pow(10, 6):
		return str(snapped((number/ pow(10, 3)), 0.1)) + " K" 
	elif number >= pow(10, 6) and number < pow(10, 9):
		return str(snapped((number/ pow(10, 6)), 0.1)) + " M"   #" Millions"
		
	elif number >= pow(10, 9):
		return str(snapped((number/ pow(10, 9)), 0.1)) + " Md"#" Milliards"
	else:
		push_error("Probleme dans le calcul")
		return str(number)

func get_center_pos(target_size = Vector2.ZERO) -> Vector2:
	"""Renvoie la position de la target pour qu'elle soit au centre"""
	var screen_size = DisplayServer.window_get_size()
	
	return (Vector2(screen_size) - Vector2(target_size))  / 2

	
func get_serialisable_vars(node: Node) -> Dictionary:
	"""Permet de return toutes les variables du node donné en paramètre"""
	var out := {}
	for prop in node.get_property_list(): 
		var usage := prop["usage"] as int
		if usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			out[prop["name"]] = node.get(prop["name"])
	return out

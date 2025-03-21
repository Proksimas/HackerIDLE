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

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

func load_txt(path: String) -> Array:
	var lines = []
	if not FileAccess.file_exists(path):
		print("Erreur: Le fichier TXT n'existe pas.")
		return []
		
	var file := FileAccess.open(path, FileAccess.READ)

# Lire toutes les lignes en mémoire
	while not file.eof_reached():
		lines.append(file.get_line())
	file.close()
	return lines

#region NUMBER TO STIRNG REGION

const EN_SUFFIXES: PackedStringArray = [
	"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" # ~1e33
]

func number_to_string(number, snap: float = 1.0, snap_big_value: bool = false) -> String:
	var is_negative = number < 0.0
	var num = absf(float(number))

	# Petits nombres : comportement inchangé et passage sans décimal
	if num < 1000.0:
		return str(snapped(number, snap))

	var _sign = ""
	if is_negative:
		_sign = "-"

	# Ordre en milliers (10^3)
	var exp3 = int(floor(log(num) / log(1000.0)))

	# Au-delà des suffixes connus -> notation scientifique
	if exp3 >= EN_SUFFIXES.size():
		return _sign + _to_scientific(num, 2)

	var idx = max(1, exp3)
	var scaled = num / pow(1000.0, float(idx))
	var dec = _decimals_for(scaled, 2)

	# Arrondi lisible
	var rounded = _round_to_decimals(scaled, dec)
	if snap_big_value:
		return _sign + str(round(rounded)) + " " + EN_SUFFIXES[idx]

	# Cas limite : 999.95 -> 1000.0, promotion au suffixe suivant
	if rounded >= 1000.0:
		idx += 1
		if idx >= EN_SUFFIXES.size():
			return _sign + _to_scientific(num, 2)
		rounded /= 1000.0
		dec = _decimals_for(rounded, 2)

	var s = _to_string_trim(rounded, dec)
	return _sign + s + " " + EN_SUFFIXES[idx]


# ---------- Helpers ----------

func _decimals_for(v: float, max_dec: int) -> int:
	if v >= 100.0:
		return 0
	elif v >= 10.0:
		return min(1, max_dec)
	else:
		return max_dec

func _round_to_decimals(x: float, decimals: int) -> float:
	if decimals <= 0:
		return floor(x + 0.5)
	var factor = pow(10.0, decimals)
	return floor(x * factor + 0.5) / factor

func _to_string_trim(x: float, decimals: int) -> String:
	var y = _round_to_decimals(x, decimals)
	var s = str(y)
	if decimals > 0 and s.find(".") != -1:
		while s.ends_with("0"):
			s = s.substr(0, s.length() - 1)
		if s.ends_with("."):
			s = s.substr(0, s.length() - 1)
	return s
	

func _to_scientific(x: float, decimals: int = 2) -> String:
	if x == 0.0:
		return "0"
	var exp10 = int(floor(log(x) / log(10.0)))
	var mant = x / pow(10.0, float(exp10))
	var mant_str = _to_string_trim(_round_to_decimals(mant, decimals), decimals)
	return mant_str + "e" + str(exp10)
#endregion

func get_center_pos(target_size = Vector2.ZERO) -> Vector2:
	"""Renvoie la position de la target pour qu'elle soit au centre"""
	var screen_size = DisplayServer.window_get_size()
	
	return (Vector2(screen_size) - Vector2(target_size))  / 2

func center(control: Control, target: Control = null):
	# S’assurer que le node a déjà calculé sa taille
	var target_center
	if target != null:
		var r = target.get_global_rect()  # Rect2 ou Rect2i, peu importe
		target_center = (r.position + r.size * 0.5)
	else:
		var vp = control.get_viewport_rect()
		target_center = (vp.position + vp.size * 0.5)

	control.global_position =  target_center - control.size * 0.5
	
func get_serialisable_vars(node: Node) -> Dictionary:
	"""Permet de return toutes les variables du node donné en paramètre"""
	var out := {}
	for prop in node.get_property_list(): 
		var usage := prop["usage"] as int
		if usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			out[prop["name"]] = node.get(prop["name"])
	return out
	
func parse_all_files_in_directory(directory_path: String) -> Array:
	var files_found = []
	var dir = DirAccess.open(directory_path)
	if dir == null:
		print("Erreur : impossible d'ouvrir le dossier ", directory_path)
		return []

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			# On ignore les sous-dossiers ici
			pass
		else:
			files_found.append(directory_path + "/" + file_name)
			
		file_name = dir.get_next()
	dir.list_dir_end()
	return files_found
	
func factorial_iterative(n):
	var result = 1
	for i in range(1, n + 1):
		result *= i
	return result

func apply_safe_area_to_ui(control: Control, enable: bool = true):
	
	var safe_area = DisplayServer.get_display_safe_area()
	var screen_size = DisplayServer.screen_get_size()

	control.anchor_left = 0
	control.anchor_top = 0
	control.anchor_right = 1
	control.anchor_bottom = 1
	if enable:
		control.offset_left   = safe_area.position.x
		control.offset_top    = safe_area.position.y
		control.offset_right  = -(screen_size.x - (safe_area.position.x + safe_area.size.x))
		control.offset_bottom = -(screen_size.y - (safe_area.position.y + safe_area.size.y))
	else:
		control.offset_left   = 0
		control.offset_top    = 0
		control.offset_right  = 0
		control.offset_bottom = 0
		
func get_interface():
	var interface = get_tree().get_root().get_node("Main/Interface")
	if interface != null and interface.is_node_ready():
		return interface
	else:
		push_error("Node interface not ready opr null")

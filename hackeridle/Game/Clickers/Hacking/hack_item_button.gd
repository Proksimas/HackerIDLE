extends Control

class_name HackItemButton

@onready var hack_item_progress_bar: ProgressBar = %HackItemProgressBar
@onready var buy_item_button: Button = %BuyItemButton
@onready var buy_title: Label = %BuyTitle
@onready var nbof_buy: Label = %NbofBuy
@onready var hack_item_price_label: Label = %HackItemPriceLabel
@onready var hack_item_cd: Label = %HackItemCD
@onready var hack_item_level: Label = %HackItemLevel
@onready var gold_gain: Label = %GoldGain
@onready var hack_item_texture: Button = %HackItemTexture
@onready var to_unlocked_panel: ColorRect = %ToUnlockedPanel
@onready var unlocked_button: Button = %UnlockedButton
@onready var brain_cost: Label = %BrainCost
@onready var hack_item_info: HBoxContainer = %HackItemInfo
@onready var source_button: Button = %SourceButton
@onready var hack_item_code_edit: RichTextLabel = %HackItemCodeEdit
@onready var progress_value_label: Label = %ProgressValueLabel
@onready var hack_duration: Label = %HackDuration
@onready var hack_name_edit: CodeEdit = %HackNameEdit
@onready var main_margin_container: MarginContainer = %MainMarginContainer


const CLICK_BRAIN_PARTICLES = preload("res://Game/Graphics/ParticlesAndShaders/click_brain_particles.tscn")
const HACKING_DIALOG_PATH = "res://Game/Clickers/Hacking/HackingDialog/"
var x_buy
var current_hack_item_cara = {}
var progress_activated: bool = false
var time_process:float
var first_cost = INF
var quantity_to_buy: int
var file_content: Array
var source_associated: Dictionary
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hack_item_progress_bar.value = 0
	hack_item_code_edit.add_theme_constant_override("scrollbar_v_size", 0)
	hack_item_code_edit.add_theme_constant_override("scrollbar_h_size", 0)
	pass # Replace with function body.
	
func _process(delta: float) -> void:
	var perc = 0
	if progress_activated:
		time_process += delta
		hack_item_progress_bar.value = time_process
		perc = round((time_process / hack_item_progress_bar.max_value) * 100)
		progress_value_label.text = str(perc) + " %"
		if time_process >= current_hack_item_cara["delay"]:
			time_finished()

	#on automatise si on a la sorce
	#elif not progress_activated and source_associated["level"] > 0:
			#lauch_wait_time()
	else:
		progress_value_label.text = str(perc) + " %"

	
func set_hacking_item(item_name):
	"""on initialise depuis la base de donnée."""
	set_unlocked_button_state()
	current_hack_item_cara = HackingItemsDb.get_item_cara(item_name)
	var item_level = current_hack_item_cara["level"]

	#le gain de abse correspond à ce qu'il y a dans la db
	gold_gain.text = Global.number_to_string((current_hack_item_cara["cost"]))

	hack_item_texture.disabled = true
	first_cost = Calculs.total_learning_prices(current_hack_item_cara, 1)
	#set_hacking_item_by_player_info()
	x_buy = 1
	x_can_be_buy(x_buy)# par défaut on affiche le prix à 1 item d'acheter
	set_unlocked_button_state()
	hack_duration.text = str(current_hack_item_cara["delay"]) + " s"

func set_refresh(item_cara: Dictionary = {}):
	"""On met à jour les stats du current_item. EN PRINCIPE le current_item vaut à présent l'item qui 
	est dans l'inventaire du joueur. Donc si vide, on ignore"""
	if !item_cara.is_empty():
		current_hack_item_cara = item_cara
	if !Player.hacking_item_bought.has(current_hack_item_cara["item_name"]) or \
	!Player.hacking_item_statut[current_hack_item_cara["item_name"]] == "unlocked":
		return
	

	var item_level = current_hack_item_cara["level"]

	hack_item_level.text = Global.number_to_string(item_level) + " / " + \
				str(Calculs.get_next_source_level(source_associated))
	gold_gain.text = Global.number_to_string(Calculs.gain_gold(current_hack_item_cara["item_name"]))
	hack_duration.text = str(current_hack_item_cara["delay"]) + " s"
	if current_hack_item_cara["level"] > 0 and not progress_activated:
		hack_item_texture.disabled = false
	x_can_be_buy(x_buy)
	
	#Mise à jour de l'ui de code
	
	file_content = Global.load_txt(HACKING_DIALOG_PATH + current_hack_item_cara["item_name"] + ".txt")
	var content =[file_content[0], current_hack_item_cara["delay"]]
	#hack_item_code_edit.edit_text(true, content)
	hack_name_edit.edit_text(true, content)
	hack_item_code_edit.text = tr("$WaitingHacked")
	
	pass
	
func knwoledge_refresh_hack_item():
	if !current_hack_item_cara.is_empty() and current_hack_item_cara["level"] > 0:
		set_refresh(current_hack_item_cara)
	set_unlocked_button_state()
	
func set_unlocked_button_state():
	if Player.knowledge_point >= first_cost:
		unlocked_button.disabled = false
		unlocked_button.modulate = Color(1,1,1)
	else:
		unlocked_button.disabled = true
		unlocked_button.modulate = Color(0.502, 0.502, 0.502)

func x_can_be_buy(_x_buy):
	"""affiche le nombre de fois que l'item peut etre acheté"""
	x_buy = _x_buy
	var item_price
	if _x_buy == -1:  #CAS DU MAX
		#TODO
		quantity_to_buy =  Calculs.quantity_hacking_item_to_buy(current_hack_item_cara)
		if quantity_to_buy == 0:
			quantity_to_buy = 1  #on force en mettant un achat à x1
	else:
		quantity_to_buy = x_buy
		
	item_price = Calculs.total_hacking_prices(current_hack_item_cara, quantity_to_buy)
	if Player.knowledge_point  < item_price:
		buy_item_button.disabled = true
	else:
		buy_item_button.disabled = false
		
	# on tente de maj le prix ici
	
	hack_item_price_label.text = Global.number_to_string(item_price)
	nbof_buy.text = "X " + str(quantity_to_buy)
	
	#Puis on met à jour le prix de l'item
	
	
func lauch_wait_time():
	"""Lancement du hack"""
	if progress_activated == true:
		return
	hack_item_progress_bar.rounded =false
	time_process = 0
	hack_item_progress_bar.max_value = current_hack_item_cara["delay"]
	hack_item_progress_bar.min_value = 0
	hack_item_progress_bar.step = 0.01
	
	hack_item_texture.disabled = true
	progress_activated = true
	start_typewriter_effect(file_content, {"delay": current_hack_item_cara["delay"]})

	pass


func time_finished() -> void:
	"""On lance le timer de la progression bar. A sa fin, on a le gain de la gold"""
	progress_activated = false
	hack_item_progress_bar.value = 0
	#TODO Faire le cas où l'item n'est pas encore acheté
	
	hack_item_texture.disabled = false
	Player.earn_gold(Calculs.gain_gold(current_hack_item_cara["item_name"]))
	if source_associated["level"] > 0:
		lauch_wait_time()
	
	pass # Replace with function body.

func statut_updated():
	"""met à jour le statut de l'item"""
	if Player.hacking_item_statut[current_hack_item_cara["item_name"]] == 'unlocked':
		self.show()
		main_margin_container.show()
		to_unlocked_panel.hide()
			
	elif Player.hacking_item_statut[current_hack_item_cara["item_name"]] == 'to_unlocked':
		#item a un prix de base pour être debloqué + ui associé
		# TODO
		self.show()
		main_margin_container.hide()
		to_unlocked_panel.show()
		first_cost = Calculs.total_hacking_prices(current_hack_item_cara, 1)
		brain_cost.text = Global.number_to_string(first_cost)
		pass
		
	elif Player.hacking_item_statut[current_hack_item_cara["item_name"]] == 'locked':
		self.hide()

#region char defilement# MonScript.gd

# --- Variables d'état de l'animation ---
var _full_filtered_lines_with_bbcode: Array = [] # Stocke toutes les lignes traitées avec BBCode (et numéros de ligne)
var _current_typing_tween: Tween = null # Garde une référence au Tween actif pour le gérer
var _line_index_counter: int = 0 # Compteur pour les numéros de ligne (pour le fichier complet)

# --- Paramètres d'optimisation ---
const MAX_DISPLAY_LINES: int = 6 # Nombre maximum de lignes à afficher à l'écran

# --- Couleurs pour la coloration syntaxique (Hexadécimal #RRGGBBAA ou noms de couleurs HTML) ---
const COLOR_KEYWORD = "#569CD6"       # Bleu Godot pour les mots-clés (if, for, def)
const COLOR_BUILTIN = "#DCDCAA"       # Jaune clair pour les fonctions intégrées (print, len)
const COLOR_COMMENT = "#6A9955"       # Vert pour les commentaires
const COLOR_STRING = "#CE9178"        # Orange pour les chaînes de caractères
const COLOR_NUMBER = "#B5CEA8"        # Vert clair pour les nombres
const COLOR_OPERATOR = "#D4D4D4"      # Blanc grisâtre pour les opérateurs
const COLOR_DEFAULT = "#D4D4D4"       # Blanc grisâtre par défaut
const COLOR_LINE_NUMBER = "#BBBBBB"   # Gris plus clair pour les numéros de ligne

# --- Listes de mots-clés et fonctions Python pour la coloration ---
const PYTHON_KEYWORDS = [
	"False", "None", "True", "and", "as", "assert", "async", "await", "break",
	"class", "continue", "def", "del", "elif", "else", "except", "finally",
	"for", "from", "global", "if", "import", "in", "is", "lambda", "nonlocal",
	"not", "or", "pass", "raise", "return", "try", "while", "with", "yield"
]

const PYTHON_BUILTINS = [
	"abs", "aiter", "all", "any", "anext", "ascii", "bin", "bool", "breakpoint",
	"bytearray", "bytes", "callable", "chr", "classmethod", "compile", "complex",
	"delattr", "dict", "dir", "divmod", "enumerate", "eval", "exec", "filter",
	"float", "format", "frozenset", "getattr", "globals", "hasattr", "hash",
	"help", "hex", "id", "input", "int", "isinstance", "issubclass", "iter",
	"len", "list", "locals", "map", "max", "memoryview", "min", "next", "object",
	"oct", "open", "ord", "pow", "print", "property", "range", "repr", "reversed",
	"round", "set", "setattr", "slice", "sorted", "staticmethod", "str", "sum",
	"super", "tuple", "type", "vars", "zip"
]

# --- Structure pour stocker les lignes (BBCode + longueur texte brut) ---
class LineData extends RefCounted:
	var bbcode_text: String # Contient le BBCode complet de la ligne
	var raw_text_length: int # Longueur du texte affichable (sans BBCode ni numéro de ligne)
	var formatted_text_length: int # Longueur du texte affichable AVEC le numéro de ligne (inclut le numéro de ligne, l'espace et le texte brut de la ligne)
	func _init(bbcode: String, raw_len: int, formatted_len: int):
		bbcode_text = bbcode
		raw_text_length = raw_len
		formatted_text_length = formatted_len # Inclut la longueur du numéro de ligne

# --- Fonction Utilitaires pour la Coloration Syntaxique (BBCode) ---
# Applique une coloration syntaxique basée sur des règles Python.
func _apply_syntax_highlighting_to_line(line_content: String) -> LineData:
	var initial_raw_length = line_content.length()

	# Règle 1: Commentaires (prioritaires car ils ignorent tout le reste sur leur ligne)
	var comment_match_pos = line_content.find("#")
	if comment_match_pos != -1:
		var code_part = line_content.substr(0, comment_match_pos)
		var comment_part = line_content.substr(comment_match_pos)
		var colored_code_part = _apply_code_highlighting(code_part)
		var colored_line = colored_code_part + "[color=" + COLOR_COMMENT + "]" + comment_part + "[/color]"
		return LineData.new(colored_line, initial_raw_length, initial_raw_length)

	# Si pas de commentaire, appliquer la coloration normale du code
	var colored_line = _apply_code_highlighting(line_content)

	return LineData.new(colored_line, initial_raw_length, initial_raw_length)

# Helper class to store a highlighted segment
class HighlightSegment extends RefCounted:
	var start: int
	var end: int
	var color: String
	func _init(s: int, e: int, c: String):
		start = s
		end = e
		color = c

# Fonction interne pour appliquer la coloration sur une partie de code (hors commentaires)
func _apply_code_highlighting(code_segment: String) -> String:
	var highlights: Array[HighlightSegment] = []

	# 1. Capture Strings (highest priority)
	var string_regex = RegEx.new()
	string_regex.compile("(\"[^\"]*\"|'[^']*')")
	var string_matches = string_regex.search_all(code_segment)
	for match in string_matches:
		highlights.append(HighlightSegment.new(match.get_start(), match.get_end(), COLOR_STRING))

	# 2. Capture Keywords
	for keyword in PYTHON_KEYWORDS:
		var regex = RegEx.new()
		regex.compile("\\b" + keyword + "\\b")
		var matches = regex.search_all(code_segment)
		for match in matches:
			if not _is_overlapping(match.get_start(), match.get_end(), highlights):
				highlights.append(HighlightSegment.new(match.get_start(), match.get_end(), COLOR_KEYWORD))

	# 3. Capture Built-ins
	for builtin in PYTHON_BUILTINS:
		var regex = RegEx.new()
		regex.compile("\\b" + builtin + "\\b")
		var matches = regex.search_all(code_segment)
		for match in matches:
			if not _is_overlapping(match.get_start(), match.get_end(), highlights):
				highlights.append(HighlightSegment.new(match.get_start(), match.get_end(), COLOR_BUILTIN))

	# 4. Capture Numbers
	var number_regex = RegEx.new()
	number_regex.compile("\\b\\d+(\\.\\d*)?([eE][+-]?\\d+)?\\b")
	var number_matches = number_regex.search_all(code_segment)
	for match in number_matches:
		if not _is_overlapping(match.get_start(), match.get_end(), highlights):
			highlights.append(HighlightSegment.new(match.get_start(), match.get_end(), COLOR_NUMBER))

	# 5. Capture Operators (sorted by length descending to prioritize longer operators like '==' over '=')
	var operators = ["**", "//", "==", "!=", "<=", ">=", "+", "-", "*", "/", "%", "=", "<", ">", "&", "|", "^", "~", "<<", ">>", "(", ")", "[", "]", "{", "}"]
	operators.sort_custom(func(a, b): return b.length() - a.length())

	for op in operators:
		var escaped_op = _escape_regex_chars(op)
		var op_regex = RegEx.new()
		op_regex.compile(escaped_op)
		var matches = op_regex.search_all(code_segment)
		for match in matches:
			if not _is_overlapping(match.get_start(), match.get_end(), highlights):
				highlights.append(HighlightSegment.new(match.get_start(), match.get_end(), COLOR_OPERATOR))



	var result_bbcode = ""
	var current_pos = 0

	for segment in highlights:
		# Add the unhighlighted text before this segment
		if segment.start > current_pos:
			result_bbcode += "[color=" + COLOR_DEFAULT + "]" + code_segment.substr(current_pos, segment.start - current_pos) + "[/color]"
		
		# Add the highlighted segment
		result_bbcode += "[color=" + segment.color + "]" + code_segment.substr(segment.start, segment.end - segment.start) + "[/color]"
		
		current_pos = segment.end
	
	# Add any remaining unhighlighted text at the end
	if current_pos < code_segment.length():
		result_bbcode += "[color=" + COLOR_DEFAULT + "]" + code_segment.substr(current_pos) + "[/color]"
	
	# If the entire segment was empty or had no highlights, apply default color
	if result_bbcode.is_empty() and not code_segment.is_empty():
		result_bbcode = "[color=" + COLOR_DEFAULT + "]" + code_segment + "[/color]"

	return result_bbcode

# Helper function to check for overlapping highlights
# Returns true if the new segment [start, end) overlaps with any existing highlight
func _is_overlapping(start_new: int, end_new: int, existing_highlights: Array[HighlightSegment]) -> bool:
	for existing in existing_highlights:
		# Check for overlap: [start_new, end_new) and [existing.start, existing.end)
		if start_new < existing.end and end_new > existing.start:
			return true
	return false

# Fonction utilitaire pour échapper les caractères spéciaux d'une chaîne pour une utilisation dans RegEx
func _escape_regex_chars(text: String) -> String:
	var escaped_text = ""
	for char in text:
		match char:
			".", "+", "*", "?", "^", "$", "(", ")", "[", "]", "{", "}", "|", "\\":
				escaped_text += "\\" + char
			_:
				escaped_text += char
	return escaped_text


# --- Fonction : Formatter le Numéro de Ligne ---
# Retourne le BBCode du numéro de ligne, et sa longueur visible.
func _format_line_number(line_num: int, max_lines: int) -> Dictionary:
	# Pas de pad_zeros() ici, le numéro sera tel quel.
	var formatted_num_str_only = str(line_num) 
	# Ajout d'un TAB (\t) après le numéro pour un meilleur alignement
	var bbcode_num_str = "[color=" + COLOR_LINE_NUMBER + "]" + formatted_num_str_only + "\t[/color]" 
	
	# La longueur inclut le TAB
	return { "bbcode": bbcode_num_str, "length": formatted_num_str_only.length() + 1 } # +1 pour le TAB (\t)


# --- Fonction Principale pour Démarrer l'Effet Machine à Écrire ---
func start_typewriter_effect(file_content_lines: Array, hack_parameters: Dictionary) -> void:
	if _current_typing_tween != null and _current_typing_tween.is_running():
		_current_typing_tween.kill()
		_current_typing_tween = null

	_full_filtered_lines_with_bbcode.clear()
	_line_index_counter = 0

	var filtered_lines_raw = []
	if file_content_lines.size() > 0:
		var main_found = false
		for i in range(1, file_content_lines.size()):
			var line = file_content_lines[i]
			if not main_found:
				if "if __name__ == \"__main__\":" in line:
					main_found = true
				else:
					filtered_lines_raw.append(line)
	
	var max_lines_for_formatting = filtered_lines_raw.size()
	if max_lines_for_formatting == 0:
		max_lines_for_formatting = 1

	# Prépare TOUTES les lignes avec leur BBCode, leur longueur brute et formatée.
	for i in range(filtered_lines_raw.size()):
		_line_index_counter += 1
		var line_number_info = _format_line_number(_line_index_counter, max_lines_for_formatting)
		var line_number_bbcode_str = line_number_info["bbcode"]
		var line_number_visible_length = line_number_info["length"]
		
		var line_data = _apply_syntax_highlighting_to_line(filtered_lines_raw[i])
		
		# Le BBCode de la ligne inclut maintenant le numéro de ligne
		line_data.bbcode_text = line_number_bbcode_str + line_data.bbcode_text
		
		# La longueur formatée doit inclure la longueur du numéro de ligne + l'espace + la longueur du texte brut de la ligne
		line_data.formatted_text_length = line_number_visible_length + line_data.raw_text_length

		_full_filtered_lines_with_bbcode.append(line_data)

	if _full_filtered_lines_with_bbcode.is_empty():
		hack_item_code_edit.text = ""
		hack_item_code_edit.visible_characters = 0
		return
	
	var animation_duration = hack_parameters.get("delay", 0.0)
	
	if animation_duration <= 0.0:
		hack_item_code_edit.text = _get_display_text_for_final_state()
		hack_item_code_edit.visible_characters = -1 
		return

	# Calcule le nombre total de caractères affichables pour l'ensemble du fichier.
	# C'est ce nombre que le Tween va parcourir.
	var total_file_displayable_chars = 0
	for line_data in _full_filtered_lines_with_bbcode:
		total_file_displayable_chars += line_data.formatted_text_length + 1 # +1 pour le saut de ligne

	var tween = create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	_current_typing_tween = tween

	# Anime un curseur de 0 au nombre total de caractères REELS du fichier entier
	tween.tween_method(Callable(self, "_update_displayed_lines"), 0.0, float(total_file_displayable_chars), animation_duration)
	
	tween.finished.connect(_on_typing_animation_finished)

# --- Fonction appelée par le Tween pour mettre à jour l'affichage de la fenêtre glissante ---
func _update_displayed_lines(current_total_char_progress: float) -> void:
	var current_char_sum = 0
	var current_line_idx = 0
	var chars_in_current_line = 0 # Nombre de caractères tapés dans la ligne actuelle

	# Déterminer la ligne et le caractère où en est la progression dans le fichier complet
	for i in range(_full_filtered_lines_with_bbcode.size()):
		var line_data = _full_filtered_lines_with_bbcode[i]
		var line_length_with_newline = line_data.formatted_text_length + 1 # +1 pour le saut de ligne
		
		if current_char_sum + line_length_with_newline > current_total_char_progress:
			current_line_idx = i
			chars_in_current_line = int(current_total_char_progress - current_char_sum)
			break
		current_char_sum += line_length_with_newline
	
	# Construire le texte de la fenêtre glissante
	var display_bbcode_parts = []
	# Calculer la ligne de départ pour la fenêtre d'affichage (MAX_DISPLAY_LINES dernières lignes)
	var start_line_for_display = max(0, current_line_idx - MAX_DISPLAY_LINES + 1)
	
	# Ajouter les lignes COMPLÈTES précédentes dans la fenêtre d'affichage
	for i in range(start_line_for_display, current_line_idx):
		if i < _full_filtered_lines_with_bbcode.size():
			display_bbcode_parts.append(_full_filtered_lines_with_bbcode[i].bbcode_text)
			display_bbcode_parts.append("\n")

	# Ajouter la ligne actuellement en cours de frappe
	if current_line_idx < _full_filtered_lines_with_bbcode.size():
		var last_line_bbcode = _full_filtered_lines_with_bbcode[current_line_idx].bbcode_text
		display_bbcode_parts.append(last_line_bbcode)

	# Mettre à jour le RichTextLabel principal
	hack_item_code_edit.text = "".join(display_bbcode_parts)
	
	# Appliquer l'effet lettre par lettre UNIQUEMENT sur la DERNIÈRE ligne ajoutée.
	var total_chars_to_display_in_window = 0
	for i in range(start_line_for_display, current_line_idx):
		if i < _full_filtered_lines_with_bbcode.size():
			total_chars_to_display_in_window += _full_filtered_lines_with_bbcode[i].formatted_text_length + 1 # +1 pour le saut de ligne
			
	total_chars_to_display_in_window += chars_in_current_line # Ajoute les caractères de la ligne en cours

	hack_item_code_edit.visible_characters = total_chars_to_display_in_window

# --- Fonction de Callback lorsque l'animation est terminée ---
func _on_typing_animation_finished() -> void:
	hack_item_code_edit.text = _get_display_text_for_final_state()
	hack_item_code_edit.visible_characters = -1 # Assure que tout le texte est visible à la fin
	_current_typing_tween = null
	print("Animation de machine à écrire terminée.")

# --- Fonction utilitaire pour obtenir le texte final après l'animation ---
func _get_display_text_for_final_state() -> String:
	var display_text_parts = []
	# Afficher les MAX_DISPLAY_LINES dernières lignes complètes du fichier
	var start_line = max(0, _full_filtered_lines_with_bbcode.size() - MAX_DISPLAY_LINES)
	
	for i in range(start_line, _full_filtered_lines_with_bbcode.size()):
		display_text_parts.append(_full_filtered_lines_with_bbcode[i].bbcode_text)
		if i < _full_filtered_lines_with_bbcode.size() - 1:
			display_text_parts.append("\n")
	return "".join(display_text_parts)
#endregion

func upgrading_source():
	"""on augmente le niveau de la source si le calcul du up level est bon.
	De plus, il faut activer ses effets si il y en a"""
	var _max = 100 # on sécurise le up avec un max
	
	for loop in range(_max):
		if not source_associated:
			return
		var cost_level_to_reach = Calculs.get_next_source_level(source_associated)
		if current_hack_item_cara["level"] < cost_level_to_reach:
			break
			
		else:  # la source est upgrade. Voir les effetcs et le level

			source_upgraded(source_associated)
	
func source_upgraded(source_cara):
	"""On augmente la source de 1 niveau"""
	source_cara["level"] += 1
	#On parse les effets
	#on commence simple en réduisant juste le temps 
	current_hack_item_cara["delay"] = snapped((current_hack_item_cara["delay"] * 0.9), 0.01)
	
	if source_cara["level"] > 0:
		lauch_wait_time()
	


func _draw() -> void:
	if source_associated["level"] > 0 :
		lauch_wait_time()
	

func _on_hack_item_texture_pressed() -> void:
	lauch_wait_time()
	pass # Replace with function body.


func _on_buy_item_button_pressed() -> void:
	"""le signal est aussi récupéré ailleurs"""
	#var particle = CLICK_BRAIN_PARTICLES.instantiate()
	#particle.position = hack_item_texture.position + (hack_item_texture.size / 2)
	#self.add_child(particle)
	pass # Replace with function body.


func _load_data():
	"""dans le chargement. Dois juste se refresh lui meme"""
	
	pass


func _on_hack_item_code_edit_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			lauch_wait_time()
	pass # Replace with function body.


func _on_hidden() -> void:
	"""On cache tous les processus d'écriture en cours"""
	hack_item_code_edit.hide()
	pass # Replace with function body.

func _on_draw() -> void:
	hack_item_code_edit.show()
	pass # Replace with function body.

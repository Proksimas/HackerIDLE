# MonScript.gd (Version Corrigée)
extends RichTextLabel

# --- Variables d'état de l'animation ---
var _full_filtered_lines_with_bbcode: Array = []
var _current_typing_tween: Tween = null
var _line_index_counter: int = 0

# --- Paramètres d'optimisation ---
const MAX_DISPLAY_LINES: int = 6

# --- Vos Couleurs Personnalisées ---
const COLOR_IMPORTANT_KEYWORD = Color("#00FF99")
const COLOR_LITERAL = Color("#00FFFF")
const COLOR_SYMBOL_OPERATOR = Color("#FF6666")
const COLOR_NUMBER = Color("#FF66FF")
const COLOR_STRING = Color("#FFFF66")
const COLOR_COMMENT = "#6A9955"
const COLOR_LINE_NUMBER = "#BBBBBB"
const COLOR_DEFAULT = "#D4D4D4"

# --- Mots-clés ---
const ALL_IMPORTANT_WORDS_RAW = [
	"def", "class", "import", "from", "as", "if", "elif", "else", "for", "while",
	"try", "except", "finally", "with", "return", "pass", "break", "continue",
	"lambda", "global", "nonlocal", "assert", "yield", "del", "in", "is",
	"not", "and", "or", "True", "False", "None", "print", "len", "range",
	"int", "str", "float", "list", "dict", "set", "tuple", "open", "input",
	"sum", "max", "min", "abs", "round", "type"
]
var ALL_IMPORTANT_WORDS_SORTED: Array = []

# --- Opérateurs ---
const PYTHON_OPERATORS_LIST_RAW = ["**", "//", "==", "!=", "<=", ">=", "+", "-", "*", "/", "%", "=", "<", ">", "&", "|", "^", "~", "<<", ">>", "(", ")", "[", "]", "{", "}"]
var PYTHON_OPERATORS_SORTED: Array = PYTHON_OPERATORS_LIST_RAW.duplicate()

# --- Structures de données internes ---
class LineData extends RefCounted:
	var bbcode_text: String
	var raw_text_length: int
	var formatted_text_length: int
	func _init(bbcode: String, raw_len: int, formatted_len: int):
		bbcode_text = bbcode
		raw_text_length = raw_len
		formatted_text_length = formatted_len

class HighlightSegment extends RefCounted:
	var start: int
	var end: int
	var color: Color
	func _init(s: int, e: int, c: Color):
		start = s
		end = e
		color = c

# --- Initialisation ---
func _init():

	ALL_IMPORTANT_WORDS_SORTED = ALL_IMPORTANT_WORDS_RAW.duplicate()


# --- Coloration Syntaxique ---
func _apply_syntax_highlighting_to_line(line_content: String) -> LineData:
	var initial_raw_length = line_content.length()
	var comment_match_pos = line_content.find("#")

	if comment_match_pos != -1:
		var code_part = line_content.substr(0, comment_match_pos)
		var comment_part = line_content.substr(comment_match_pos)
		var colored_code_part = _apply_code_highlighting(code_part)
		var colored_line = colored_code_part + "[color=" + COLOR_COMMENT + "]" + comment_part + "[/color]"
		return LineData.new(colored_line, initial_raw_length, initial_raw_length)

	var colored_line = _apply_code_highlighting(line_content)
	return LineData.new(colored_line, initial_raw_length, initial_raw_length)

func _apply_code_highlighting(code_segment: String) -> String:
	var highlights: Array[HighlightSegment] = []

	# 1. Strings
	var string_regex = RegEx.new()
	string_regex.compile("(\"[^\"]*\"|'[^']*')")
	for match in string_regex.search_all(code_segment):
		highlights.append(HighlightSegment.new(match.get_start(), match.get_end(), COLOR_STRING))

	# 2. Mots importants (mots-clés, littéraux, fonctions)
	for word in ALL_IMPORTANT_WORDS_SORTED:
		var regex = RegEx.new()
		regex.compile("\\b" + _escape_regex_chars(word) + "\\b")
		for match in regex.search_all(code_segment):
			if not _is_overlapping(match.get_start(), match.get_end(), highlights):
				var color_to_use = COLOR_IMPORTANT_KEYWORD
				if word in ["True", "False", "None"]:
					color_to_use = COLOR_LITERAL
				highlights.append(HighlightSegment.new(match.get_start(), match.get_end(), color_to_use))

	# 3. Nombres
	var number_regex = RegEx.new()
	number_regex.compile("\\b\\d+(\\.\\d*)?([eE][+-]?\\d+)?\\b")
	for match in number_regex.search_all(code_segment):
		if not _is_overlapping(match.get_start(), match.get_end(), highlights):
			highlights.append(HighlightSegment.new(match.get_start(), match.get_end(), COLOR_NUMBER))

	# 4. Opérateurs
	for op in PYTHON_OPERATORS_SORTED:
		var op_regex = RegEx.new()
		op_regex.compile(_escape_regex_chars(op))
		for match in op_regex.search_all(code_segment):
			if not _is_overlapping(match.get_start(), match.get_end(), highlights):
				highlights.append(HighlightSegment.new(match.get_start(), match.get_end(), COLOR_SYMBOL_OPERATOR))


	var result_bbcode = ""
	var current_pos = 0

	for segment in highlights:
		if segment.start > current_pos:
			result_bbcode += "[color=" + COLOR_DEFAULT + "]" + code_segment.substr(current_pos, segment.start - current_pos) + "[/color]"
		
		# ## CORRECTION ICI ##
		# On utilise .to_html() pour convertir l'objet Color en chaîne hexadécimale.
		result_bbcode += "[color=" + segment.color.to_html() + "]" + code_segment.substr(segment.start, segment.end - segment.start) + "[/color]"
		
		current_pos = segment.end
	
	if current_pos < code_segment.length():
		result_bbcode += "[color=" + COLOR_DEFAULT + "]" + code_segment.substr(current_pos) + "[/color]"
	
	if result_bbcode.is_empty() and not code_segment.is_empty():
		result_bbcode = "[color=" + COLOR_DEFAULT + "]" + code_segment + "[/color]"

	return result_bbcode

# --- Fonctions Utilitaires ---
func _is_overlapping(start_new: int, end_new: int, existing_highlights: Array[HighlightSegment]) -> bool:
	for existing in existing_highlights:
		if start_new < existing.end and end_new > existing.start:
			return true
	return false

func _escape_regex_chars(text: String) -> String:
	return text.replace("\\", "\\\\").replace(".", "\\.").replace("+", "\\+").replace("*", "\\*").replace("?", "\\?").replace("^", "\\^").replace("$", "\\$").replace("(", "\\(").replace(")", "\\)").replace("[", "\\[").replace("]", "\\]").replace("{", "\\{").replace("}", "\\}").replace("|", "\\|")

func _format_line_number(line_num: int) -> Dictionary:
	var num_str = str(line_num)
	var bbcode_str = "[color=" + COLOR_LINE_NUMBER + "]" + num_str + "\t[/color]"
	return { "bbcode": bbcode_str, "length": num_str.length() + 1 }

# --- Fonctions Principales (Animation) ---
func start_typewriter_effect(file_content_lines: Array, hack_parameters: Dictionary) -> void:
	if _current_typing_tween != null and _current_typing_tween.is_running():
		_current_typing_tween.kill()

	_full_filtered_lines_with_bbcode.clear()
	_line_index_counter = 0

	# (Le reste de votre logique de filtrage de lignes est conservé)
	var filtered_lines_raw = []
	if file_content_lines.size() > 0:
		var main_found = false
		for i in range(file_content_lines.size()):
			var line = file_content_lines[i]
			if not main_found:
				if "if __name__ == \"__main__\":" in line:
					main_found = true
				else:
					filtered_lines_raw.append(line)
	
	for i in range(filtered_lines_raw.size()):
		_line_index_counter += 1
		var line_number_info = _format_line_number(_line_index_counter)
		var line_data = _apply_syntax_highlighting_to_line(filtered_lines_raw[i])
		line_data.bbcode_text = line_number_info.bbcode + line_data.bbcode_text
		line_data.formatted_text_length = line_number_info.length + line_data.raw_text_length
		_full_filtered_lines_with_bbcode.append(line_data)

	if _full_filtered_lines_with_bbcode.is_empty():
		text = ""
		return
	
	var animation_duration = hack_parameters.get("delay", 0.0)
	
	if animation_duration <= 0.0:
		text = _get_display_text_for_final_state()
		visible_characters = -1
		return

	var total_chars = 0
	for line_data in _full_filtered_lines_with_bbcode:
		total_chars += line_data.formatted_text_length + 1

	var tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	_current_typing_tween = tween
	tween.tween_method(Callable(self, "_update_displayed_lines"), 0.0, float(total_chars), animation_duration)
	tween.finished.connect(func(): _on_typing_animation_finished())

func _update_displayed_lines(progress: float) -> void:
	var char_sum = 0
	var current_line_idx = -1
	var chars_in_current_line = 0

	for i in range(_full_filtered_lines_with_bbcode.size()):
		var line_data = _full_filtered_lines_with_bbcode[i]
		var line_len = line_data.formatted_text_length + 1
		if char_sum + line_len > progress:
			current_line_idx = i
			chars_in_current_line = int(progress - char_sum)
			break
		char_sum += line_len
	
	if current_line_idx == -1: # Au cas où on est à la toute fin
		current_line_idx = _full_filtered_lines_with_bbcode.size() - 1
		chars_in_current_line = _full_filtered_lines_with_bbcode[current_line_idx].formatted_text_length

	var display_bbcode_parts = []
	var start_line = max(0, current_line_idx - MAX_DISPLAY_LINES + 1)
	
	for i in range(start_line, current_line_idx + 1):
		display_bbcode_parts.append(_full_filtered_lines_with_bbcode[i].bbcode_text)
		if i < current_line_idx:
			display_bbcode_parts.append("\n")

	text = "".join(display_bbcode_parts)
	
	var total_visible_chars_in_window = 0
	for i in range(start_line, current_line_idx):
		total_visible_chars_in_window += _full_filtered_lines_with_bbcode[i].formatted_text_length + 1
	total_visible_chars_in_window += chars_in_current_line

	visible_characters = total_visible_chars_in_window

func _on_typing_animation_finished() -> void:
	text = _get_display_text_for_final_state()
	visible_characters = -1
	_current_typing_tween = null
	print("Animation terminée.")

func _get_display_text_for_final_state() -> String:
	var parts = []
	var start_line = max(0, _full_filtered_lines_with_bbcode.size() - MAX_DISPLAY_LINES)
	for i in range(start_line, _full_filtered_lines_with_bbcode.size()):
		parts.append(_full_filtered_lines_with_bbcode[i].bbcode_text)
	return "\n".join(parts)

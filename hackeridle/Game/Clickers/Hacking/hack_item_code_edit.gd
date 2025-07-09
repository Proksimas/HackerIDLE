extends CodeEdit

func _ready() -> void:
	python()



func edit_text(is_empty: bool, content):
	var text: String
	print(content)
	if is_empty:
		var first_line: String = content[0]
		first_line = first_line.lstrip("hack_name:")
		first_line = first_line.rstrip(')')
		var hack_duration: int = content[1]
		text = "if __name__ == '__main__':\n\t"
		text += "hack_duration = %s s\n\t%s, hack_duration" % [str(hack_duration), first_line]
		self.text = text

	pass






func bash():
	var highlighter := CodeHighlighter.new()

	# === FOND ===
	self.theme_type_variation = "CodeEdit"  # utile si tu veux appliquer un Theme
	self.add_theme_color_override("background_color", Color.BLACK)

	# === COULEURS PERSONNALISÉES ===

	# 1. Mots-clés Bash
	highlighter.keyword_colors = {
		"if": Color("#3399FF"),
		"then": Color("#3399FF"),
		"fi": Color("#3399FF"),
		"for": Color("#3399FF"),
		"do": Color("#3399FF"),
		"done": Color("#3399FF"),
		"else": Color("#3399FF"),
		"elif": Color("#3399FF"),
		"while": Color("#3399FF"),
		"case": Color("#3399FF"),
		"esac": Color("#3399FF"),
		"function": Color("#3399FF")
	}

	# 2. Commandes Bash traitées comme "pseudo-keywords"
	var bash_cmds := [
		"echo", "ls", "cd", "mkdir", "rm", "touch", "cat", "grep", "awk", "sed",
		"chmod", "chown", "tar", "curl", "wget", "exit", "clear"
	]
	for cmd in bash_cmds:
		highlighter.keyword_colors[cmd] = Color("#00FF99")

	# 3. Variables style $USER, $1...
	highlighter.member_variable_color = Color("#00FFFF")

	# 4. Symboles spéciaux
	highlighter.symbol_color = Color("#FF6666")

	# 5. Nombres
	highlighter.number_color = Color("#FF66FF")

	# 6. Chaînes de caractères (simplifié)
	highlighter.member_keyword_colors = {
		"\"*\"": Color("#FFFF66"),
		"'*'": Color("#FFFF66")
	}
	highlighter.function_color = Color("#4EC9B0")

	# Appliquer
	syntax_highlighter = highlighter


func python():
	var highlighter := CodeHighlighter.new()

	# === FOND ===
	self.theme_type_variation = "CodeEdit"
	self.add_theme_color_override("background_color", Color.BLACK)

	# === COULEURS PERSONNALISÉES ===

	# 1. Mots-clés Python
	highlighter.keyword_colors = {
		"def": Color("#00FF99"),
		"class": Color("#00FF99"),
		"import": Color("#00FF99"),
		"from": Color("#00FF99"),
		"as": Color("#00FF99"),
		"if": Color("#3399FF"),
		"elif": Color("#3399FF"),
		"else": Color("#3399FF"),
		"for": Color("#3399FF"),
		"while": Color("#3399FF"),
		"try": Color("#FFAA00"),
		"except": Color("#FFAA00"),
		"finally": Color("#FFAA00"),
		"with": Color("#00CCFF"),
		"return": Color("#FFFF66"),
		"pass": Color("#666666"),
		"break": Color("#FF6666"),
		"continue": Color("#FF6666"),
		"lambda": Color("#CC99FF"),
		"global": Color("#FF66CC"),
		"nonlocal": Color("#FF66CC"),
		"assert": Color("#FF2222"),
		"yield": Color("#66FFCC"),
		"del": Color("#FF5555"),
		"in": Color("#66CCFF"),
		"is": Color("#66CCFF"),
		"not": Color("#FF88AA"),
		"and": Color("#FF88AA"),
		"or": Color("#FF88AA")
	}

	# 2. Booléens, None, etc.
	highlighter.member_keyword_colors = {
		"True": Color("#00FFFF"),
		"False": Color("#00FFFF"),
		"None": Color("#888888")
	}

	# 3. Symboles (par défaut)
	highlighter.symbol_color = Color("#FF6666")

	# 4. Nombres
	highlighter.number_color = Color("#FF66FF")

	# 5. Variables (optionnel, si tu veux que noms genre self soient mis en valeur)
	highlighter.member_variable_color = Color("#AAAAFF")

	# 6. Chaînes de caractères
	highlighter.member_keyword_colors["\"*\""] = Color("#FFFF66")
	highlighter.member_keyword_colors["'*'"] = Color("#FFFF66")

	highlighter.function_color = Color("#569CD6")

	# Appliquer au CodeEdit
	syntax_highlighter = highlighter

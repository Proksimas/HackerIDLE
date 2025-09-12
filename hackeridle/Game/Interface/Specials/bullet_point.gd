extends HBoxContainer

@onready var text_label: RichTextLabel = %TextLabel

func set_bullet_point(_text: String, has_autowrap: bool = false, _width:float = 150, inverse_color:bool = false):
	# Configure l'autowrap
	if has_autowrap:
		text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		self.size.x = _width
	else:
		text_label.autowrap_mode = TextServer.AUTOWRAP_OFF

	# Crée une expression régulière pour trouver tous les nombres
	var regex = RegEx.new()
	regex.compile("(-?\\d+\\.?\\d*)")

	# Recherche toutes les correspondances
	var matches = regex.search_all(_text)
	var new_text = ""
	var last_index = 0

	for match in matches:
		var start_index = match.get_start()
		var end_index = match.get_end()
		var number_str = match.get_string()
		var number_value = float(number_str)

		# Ajoute la partie du texte qui n'est pas un nombre
		new_text += _text.substr(last_index, start_index - last_index)
		#if number_value == 0:
		var colored_number
		
		if number_value == 0:
			colored_number  = "[color=white]" + number_str + "[/color]"
		elif number_value > 0 and inverse_color == false:
			# Affiche en vert si le nombre est positif
			colored_number  = "[color=green]" + number_str + "[/color]"
		elif number_value > 0 and inverse_color == true:
			colored_number  = "[color=red]" + number_str + "[/color]"
		elif number_value < 0 and inverse_color == true:
			colored_number  = "[color=green]" + number_str + "[/color]"
		else:
			colored_number  = "[color=green]" + number_str + "[/color]"

		# Ajoute le nombre formaté en BBCode
	

		new_text += colored_number

		last_index = end_index

	# Ajoute le reste de la chaîne après le dernier nombre
	new_text += _text.substr(last_index, _text.length() - last_index)

	# Assigne le texte modifié au Label
	text_label.text = new_text

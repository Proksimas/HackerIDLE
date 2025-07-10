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
@onready var hack_item_code_edit: CodeEdit = %HackItemCodeEdit
@onready var progress_value_label: Label = %ProgressValueLabel
@onready var hack_duration: Label = %HackDuration


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
	hack_item_code_edit.edit_text(true, content)
	
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
	if progress_activated == true:
		return
	hack_item_progress_bar.rounded =false
	time_process = 0
	hack_item_progress_bar.max_value = current_hack_item_cara["delay"]
	hack_item_progress_bar.min_value = 0
	hack_item_progress_bar.step = 0.01
	
	hack_item_texture.disabled = true
	progress_activated = true
	play_typewriter_effect()

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
		hack_item_info.show()
		to_unlocked_panel.hide()
			
	elif Player.hacking_item_statut[current_hack_item_cara["item_name"]] == 'to_unlocked':
		#item a un prix de base pour être debloqué + ui associé
		# TODO
		self.show()
		hack_item_info.hide()
		to_unlocked_panel.show()
		first_cost = Calculs.total_hacking_prices(current_hack_item_cara, 1)
		brain_cost.text = Global.number_to_string(first_cost)
		pass
		
	elif Player.hacking_item_statut[current_hack_item_cara["item_name"]] == 'locked':
		self.hide()

#region char defilement

# Variable pour stocker le texte complet une fois filtré et préparé pour l'animation
var full_text_to_animate: String = ""

# --- Fonction principale pour démarrer l'effet de machine à écrire ---
func play_typewriter_effect() -> void:
	# --- 1. Préparation et filtrage du texte ---
	full_text_to_animate = ""
	var filtered_lines = []
	
	# S'assurer qu'il y a du contenu avant de tenter de le filtrer
	if file_content.size() > 0:
		var main_found = false
		# Commence à partir du deuxième élément (index 1) pour ignorer la première ligne
		for i in range(1, file_content.size()):
			var line = file_content[i]
			
			# Ajoute les lignes tant que la section "__main__" n'est pas trouvée
			if not main_found:
				if "if __name__ == \"__main__\":" in line:
					# Marque que la section "__main__" a été trouvée;
					# cette ligne et les suivantes seront ignorées.
					main_found = true
				else:
					filtered_lines.append(line)
	
	# Concatène toutes les lignes filtrées en une seule chaîne, en ajoutant les sauts de ligne
	full_text_to_animate = ""
	for i in range(filtered_lines.size()):
		full_text_to_animate += filtered_lines[i]
		# Ajoute un saut de ligne entre les lignes, sauf après la dernière
		if i < filtered_lines.size() - 1:
			full_text_to_animate += "\n"

	var total_steps = full_text_to_animate.length() # Nombre total de caractères/pas à animer
	
	# Gère les cas où il n'y a rien à animer
	if total_steps == 0:
		return 

	var total_duration = current_hack_item_cara["delay"] # Durée totale de l'animation en secondes
	
	# Gère les durées nulles ou négatives : affiche tout le texte instantanément
	if total_duration <= 0.0:
		hack_item_code_edit.text = full_text_to_animate
		hack_item_code_edit.grab_focus()
		var final_line_index = hack_item_code_edit.get_line_count() - 1
		if final_line_index >= 0:
			hack_item_code_edit.set_caret_line(final_line_index)
			# Positionne le curseur à la fin de la dernière ligne
			hack_item_code_edit.set_caret_column(hack_item_code_edit.get_line_content(final_line_index).length())
		
		# CORRECTED LINE FOR SCROLLING: Assure le défilement au maximum
		if hack_item_code_edit.get_v_scroll_bar(): # Vérifie si la barre de défilement existe
			hack_item_code_edit.scroll_vertical = hack_item_code_edit.get_v_scroll_bar().max_value
		return
	
	hack_item_code_edit.text = "" # Efface le texte précédent avant de commencer l'animation

	# --- 2. Création et configuration de l'animation Tween ---
	var tween = create_tween()
	# Utilise TWEEN_PROCESS_PHYSICS pour une mise à jour fluide, alignée sur le pas physique du jeu
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS) 

	# Anime une valeur flottante de 0.0 à 'total_steps' sur la 'total_duration'.
	# La méthode '_update_typewriter_text' sera appelée avec la valeur interpolée à chaque update.
	tween.tween_method(Callable(self, "_update_typewriter_text"), 0.0, float(total_steps), total_duration)
	
	# Connecte le signal 'finished' du Tween à une fonction de callback
	# pour effectuer des actions une fois l'animation terminée.
	tween.finished.connect(_on_typewriter_tween_finished)


# --- Fonction appelée à chaque étape du Tween pour mettre à jour l'affichage ---
func _update_typewriter_text(current_step: float) -> void:
	# Convertit la valeur flottante interpolée en un index de caractère entier
	var chars_to_display = int(current_step)
	
	# S'assure que l'index ne dépasse pas la longueur totale du texte
	chars_to_display = clampi(chars_to_display, 0, full_text_to_animate.length())
	
	# Met à jour le texte visible dans le CodeEdit
	hack_item_code_edit.text = full_text_to_animate.substr(0, chars_to_display)
	
	# Met à jour la position du curseur pour suivre l'écriture
	var line_count = hack_item_code_edit.get_line_count()
	if line_count > 0: # S'assure qu'il y a au moins une ligne
		hack_item_code_edit.set_caret_line(line_count - 1) # Déplace le curseur sur la dernière ligne
		# Positionne le curseur à la fin de la dernière ligne.
		# get_line_content().length() est la méthode correcte pour obtenir la longueur d'une ligne.

		# S'assure que CodeEdit défile pour que la dernière ligne soit visible
		# CORRECTED LINE FOR SCROLLING:
		if hack_item_code_edit.get_v_scroll_bar(): # Vérifie si la barre de défilement existe
			hack_item_code_edit.scroll_vertical = hack_item_code_edit.get_v_scroll_bar().max_value

# --- Fonction appelée lorsque l'animation Tween est complètement terminée ---
func _on_typewriter_tween_finished() -> void:
	# S'assure que tout le texte est affiché à la fin de l'animation
	hack_item_code_edit.text = full_text_to_animate
	
	# Assure que le CodeEdit a le focus d'entrée
	hack_item_code_edit.grab_focus()
	
	# Positionne le curseur à la toute fin du texte
	var final_line_index = hack_item_code_edit.get_line_count() - 1
	if final_line_index >= 0:
		hack_item_code_edit.set_caret_line(final_line_index)

	# S'assure que le défilement est à la toute fin du contenu
	# CORRECTED LINE FOR SCROLLING:
	if hack_item_code_edit.get_v_scroll_bar(): # Vérifie si la barre de défilement existe
		hack_item_code_edit.scroll_vertical = hack_item_code_edit.get_v_scroll_bar().max_value
	
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
	var particle = CLICK_BRAIN_PARTICLES.instantiate()
	particle.position = hack_item_texture.position + (hack_item_texture.size / 2)
	self.add_child(particle)
	pass # Replace with function body.


func _load_data():
	"""dans le chargement. Dois juste se refresh lui meme"""
	
	pass

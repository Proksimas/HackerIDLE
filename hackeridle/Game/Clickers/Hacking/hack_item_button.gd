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
@onready var hack_item_texture: TextureButton = %HackItemTexture
@onready var to_unlocked_panel: ColorRect = %ToUnlockedPanel
@onready var unlocked_button: Button = %UnlockedButton
@onready var brain_cost: Label = %BrainCost
@onready var hack_item_info: HBoxContainer = %HackItemInfo
@onready var source_button: Button = %SourceButton
@onready var hack_item_code_edit: CodeEdit = %HackItemCodeEdit
@onready var progress_value_label: Label = %ProgressValueLabel


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
	else:
		progress_value_label.text = str(perc) + " %"

func set_hacking_item(item_name):
	"""on initialise depuis la base de donnée."""
	set_unlocked_button_state()
	current_hack_item_cara = HackingItemsDb.get_item_cara(item_name)
	var item_level = current_hack_item_cara["level"]

	#le gain de abse correspond à ce qu'il y a dans la db
	gold_gain.text = Global.number_to_string((current_hack_item_cara["cost"]))

	hack_item_level.text = Global.number_to_string(item_level)
	#hack_item_cd.text =  "/ " + str(current_hack_item_cara["delay"]) + " secs"
	hack_item_texture.disabled = true
	first_cost = Calculs.total_learning_prices(current_hack_item_cara, 1)
	#set_hacking_item_by_player_info()
	x_buy = 1
	x_can_be_buy(x_buy)# par défaut on affiche le prix à 1 item d'acheter
	set_unlocked_button_state()
	
	#on a la source qui automatise

func set_refresh(item_cara: Dictionary):
	"""On met à jour les stats du current_item. EN PRINCIPE le current_item vaut à présent l'item qui 
	est dans l'inventaire du joueur"""
	if !Player.hacking_item_bought.has(item_cara["item_name"]) or \
	!Player.hacking_item_statut[item_cara["item_name"]] == "unlocked":
		return

	current_hack_item_cara = item_cara
	var item_level = current_hack_item_cara["level"]

	hack_item_level.text = Global.number_to_string(item_level)
	gold_gain.text = Global.number_to_string(Calculs.gain_gold(current_hack_item_cara["item_name"]))
	#hack_item_cd.text = "/ " + str(current_hack_item_cara["delay"]) + " secs"
	if item_cara["level"] > 0 and not progress_activated:
		hack_item_texture.disabled = false
	x_can_be_buy(x_buy)
	
	#Mise à jour de l'ui de code
	
	file_content = Global.load_txt(HACKING_DIALOG_PATH + item_cara["item_name"] + ".txt")
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
	
	#On a la source qui automatise
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
		

func play_typewriter_effect() -> void:
	# --- PRÉPARATION DU TEXTE ---
	var filtered_lines = []
	var main_found = false

	# Étape 1: Supprimer la première ligne
	if file_content.size() > 0:
		# Nous commençons à partir du deuxième élément (index 1)
		for i in range(1, file_content.size()):
			var line = file_content[i]
			
			# Étape 2: Supprimer les lignes après "if __name__ == "__main__":"
			if not main_found:
				if "if __name__ == \"__main__\":" in line:
					main_found = true
				else:
					filtered_lines.append(line)
			# Si main_found est vrai, nous arrêtons d'ajouter des lignes
	
	# Mettre à jour file_content avec les lignes filtrées
	var lines_to_display = filtered_lines
	# --- FIN DE LA PRÉPARATION DU TEXTE ---

	# Le reste de votre logique d'effet de machine à écrire reste inchangé,
	# mais il utilisera maintenant 'lines_to_display' au lieu de 'file_content'.

	# 1) Calculer le nombre total de caractères
	var total_chars := 0
	for line in lines_to_display: # Utilisation de lines_to_display
		total_chars += line.length()
	
	if lines_to_display.size() > 1: # Utilisation de lines_to_display
		total_chars += (lines_to_display.size() - 1)

	if total_chars == 0:
		return 

	# 2) Déterminer l’intervalle entre chaque caractère
	var char_interval = current_hack_item_cara["delay"] / float(total_chars)

	# 3) Construire et afficher le texte caractère par caractère
	var current_line_index := 0
	var current_column_index := 0

	hack_item_code_edit.text = "" 

	for line in lines_to_display: # Utilisation de lines_to_display
		for c in line:
			hack_item_code_edit.text += c 
			
			current_column_index += 1
			hack_item_code_edit.set_caret_line(current_line_index)
			hack_item_code_edit.set_caret_column(current_column_index)
			
			await get_tree().create_timer(char_interval).timeout
		
		if current_line_index < lines_to_display.size() - 1: # Utilisation de lines_to_display
			hack_item_code_edit.text += "\n" 
			current_line_index += 1 
			current_column_index = 0 
			
			hack_item_code_edit.set_caret_line(current_line_index)
			hack_item_code_edit.set_caret_column(current_column_index)
			

	hack_item_code_edit.grab_focus()
	#
	var final_line_index = hack_item_code_edit.get_line_count() - 1
	hack_item_code_edit.set_caret_line(final_line_index)


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

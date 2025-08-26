extends Control

class_name HackItemButton

@onready var hack_item_progress_bar: ProgressBar = %HackItemProgressBar
@onready var buy_item_button: Button = %BuyItemButton
@onready var hack_item_price_label: Label = %HackItemPriceLabel
@onready var hack_item_level: Label = %HackItemLevel
@onready var gold_gain: Label = %GoldGain
@onready var to_unlocked_panel: ColorRect = %ToUnlockedPanel
@onready var unlocked_button: Button = %UnlockedButton
@onready var brain_cost: Label = %BrainCost
@onready var hack_item_info: HBoxContainer = %HackItemInfo
@onready var hack_item_code_edit: RichTextLabel = %HackItemCodeEdit
@onready var progress_value_label: Label = %ProgressValueLabel
@onready var hack_duration: Label = %HackDuration
@onready var hack_name_edit: Label = %HackNameEdit
@onready var main_margin_container: MarginContainer = %MainMarginContainer
@onready var max_hack_item_level: Label = %MaxHackItemLevel
@onready var cost_label: Label = %CostLabel
@onready var duration_label: Label = %DurationLabel
@onready var gold_label: Label = %GoldLabel
@onready var level_hack_label: Label = %LevelHackLabel
@onready var cost_hack_label: Label = %CostHackLabel

const CLICK_BRAIN_PARTICLES = preload("res://Game/Graphics/ParticlesAndShaders/click_brain_particles.tscn")
const HACKING_DIALOG_PATH = "res://Game/Clickers/Hacking/HackingDialog/"
const NUMER_COLOR = Color("#FF66FF")

var x_buy
var current_hack_item_cara = {}
var progress_activated: bool = false
var time_process:float
var first_cost = INF
var quantity_to_buy: int
var file_content: Array
#var source_associated: Dictionary
var waiting_to_long_send: bool = false
# Called when the node enters the scene tree for the first time.

signal s_wait_too_long
signal s_hack_finished
signal s_hack_lauch

func _ready() -> void:
	hack_item_progress_bar.value = 0
	hack_item_code_edit.add_theme_constant_override("scrollbar_v_size", 0)
	hack_item_code_edit.add_theme_constant_override("scrollbar_h_size", 0)
	StatsManager.s_infamy_effect_added.connect(self._on_s_infamy_effect_added)
	pass # Replace with function body.
	
func _process(delta: float) -> void:
	var perc = 0
	if progress_activated:
		time_process += delta
		hack_item_progress_bar.value = time_process
		perc = round((time_process / hack_item_progress_bar.max_value) * 100)
		progress_value_label.text = str(perc) + " %"
		
		if time_process >= StatsManager.calcul_hack_stat(StatsManager.Stats.TIME, current_hack_item_cara["delay"]):
			time_finished()

	else:
		progress_value_label.text = str(perc) + " %"
		
		if unlocked_button.disabled == false and waiting_to_long_send == false:
		#si on est non activé pendant x seconds, on alerte le joueur
			get_tree().create_timer(1).timeout.connect(_on_wait_too_long_timeout)
			waiting_to_long_send = true

	
func set_hacking_item(item_name):
	"""on initialise depuis la base de donnée."""
	set_unlocked_button_state()
	current_hack_item_cara = HackingItemsDb.get_item_cara(item_name)
	var _item_level = current_hack_item_cara["level"]

	#le gain de abse correspond à ce qu'il y a dans la db
	gold_label.text = tr("$Gain") + ": "
	gold_gain.text = Global.number_to_string((current_hack_item_cara["cost"]))

	first_cost = Calculs.total_learning_prices(current_hack_item_cara, 1)
	#set_hacking_item_by_player_info()
	x_buy = 1
	x_can_be_buy(x_buy)# par défaut on affiche le prix à 1 item d'acheter
	set_unlocked_button_state()
	duration_label.text = tr("$Duration") + ": "
	hack_duration.text = str(StatsManager.calcul_hack_stat(StatsManager.Stats.TIME, current_hack_item_cara["delay"])) + " s"
	file_content = Global.load_txt(HACKING_DIALOG_PATH + current_hack_item_cara["item_name"] + ".txt")

func set_refresh(item_cara: Dictionary = {}):
	"""On met à jour les stats du current_item. EN PRINCIPE le current_item vaut à présent l'item qui 
	est dans l'inventaire du joueur. Donc si vide, on ignore"""
	
	if !item_cara.is_empty():
		current_hack_item_cara = item_cara
	if !Player.hacking_item_bought.has(current_hack_item_cara["item_name"]) or \
	!Player.hacking_item_statut[current_hack_item_cara["item_name"]] == "unlocked":
		return
	
	

	var item_level = current_hack_item_cara["level"]
	level_hack_label.text = tr("Level") + ": "
	hack_item_level.text = Global.number_to_string(item_level) 
	max_hack_item_level.text = " / " + str(Calculs.get_next_source_level(Player.get_associated_source(current_hack_item_cara["item_name"])))
				
				
	gold_gain.text = Global.number_to_string(StatsManager.calcul_hack_stat(StatsManager.Stats.GOLD,
					Calculs.gain_gold(current_hack_item_cara["item_name"])))
	
	duration_label.text = tr("$Duration") + ": "
	hack_duration.text = str(StatsManager.calcul_hack_stat(StatsManager.Stats.TIME, current_hack_item_cara["delay"])) + " s"

	x_can_be_buy(x_buy)
	
	#Mise à jour de l'ui de code
	var content =[file_content[0], StatsManager.calcul_hack_stat(StatsManager.Stats.TIME, current_hack_item_cara["delay"])]

	
	hack_name_edit.text = tr(current_hack_item_cara["item_name"] + "_hack_name")
	hack_item_code_edit.text = tr("$WaitingHacked")
	
	hack_item_code_edit._prepare_script_for_display(file_content)
	
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
	
	cost_hack_label.text = tr("$Cost") + ": +" + str(_x_buy)
	#cost_hack_label.text = "+ " + str(_x_buy) + ": "
	hack_item_price_label.text = Global.number_to_string(item_price)
	
	#Puis on met à jour le prix de l'item
	
	
func lauch_wait_time():
	"""Lancement du hack"""
	if progress_activated == true:
		return
	hack_item_progress_bar.rounded =false
	time_process = 0
	hack_item_progress_bar.max_value = StatsManager.calcul_hack_stat(StatsManager.Stats.TIME, current_hack_item_cara["delay"])
	hack_item_progress_bar.min_value = 0
	hack_item_progress_bar.step = 0.01
	
	progress_activated = true
	
	#On lance dans le rich_label l'effet machine à écrire
	#on a deja préparé le contenu du bouton lors du chargement
	hack_item_code_edit.start_typewriter_effect({"delay": StatsManager.calcul_hack_stat(StatsManager.Stats.TIME, current_hack_item_cara["delay"])})
	s_hack_lauch.emit()
	pass


func time_finished() -> void:
	"""Le hack est fini. On récupere le gain en gold"""
	progress_activated = false
	waiting_to_long_send = false
	hack_item_progress_bar.value = 0

	
	#Gain de l'or
	# TODO modificateurs sur lz gain de gold du hack spécifique
	var gold_from_item = Calculs.gain_gold(current_hack_item_cara["item_name"])
	var final_hack_gold = StatsManager.calcul_hack_stat(StatsManager.Stats.GOLD, gold_from_item)
	Player.earn_gold(final_hack_gold)
	if Player.get_associated_source(current_hack_item_cara["item_name"])["level"] > 0:
		lauch_wait_time()
	
	s_hack_finished.emit()


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
		cost_label.text = tr("$Cost") + ": " 
		pass
		
	elif Player.hacking_item_statut[current_hack_item_cara["item_name"]] == 'locked':
		self.hide()


func upgrading_source():
	"""on augmente le niveau de la source si le calcul du up level est bon.
	De plus, il faut activer ses effets si il y en a"""
	var _max = 100 # on sécurise le up avec un max
	
	for loop in range(_max):
		if not Player.get_associated_source(current_hack_item_cara["item_name"]):
			return
		var cost_level_to_reach = Calculs.get_next_source_level(Player.get_associated_source(current_hack_item_cara["item_name"]))
		if current_hack_item_cara["level"] < cost_level_to_reach:
			break
			
		else:  # la source est upgrade. Voir les effetcs et le level

			source_upgraded(Player.get_associated_source(current_hack_item_cara["item_name"]))
	
func source_upgraded(source_cara):
	"""On augmente la source de 1 niveau"""
	source_cara["level"] += 1
	#On parse les effets
	#on commence simple en réduisant juste le temps 
	current_hack_item_cara["delay"] = snapped((current_hack_item_cara["delay"] * 0.9), 0.01)
	
	if source_cara["level"] > 0:

		lauch_wait_time()
	
func get_gold_from_hack() -> float:
	if !Player.hacking_item_statut[current_hack_item_cara["item_name"]] == 'unlocked':
		return 0
	var gold_from_item = Calculs.gain_gold(current_hack_item_cara["item_name"])
	var final_hack_gold = StatsManager.calcul_hack_stat(StatsManager.Stats.GOLD, gold_from_item)
	return int(final_hack_gold)

func _draw() -> void:
	if Player.get_associated_source(current_hack_item_cara["item_name"])["level"] > 0:
		lauch_wait_time()
	


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
	
func _on_s_infamy_effect_added():
	set_refresh()
	


func _on_wait_too_long_timeout():
	s_wait_too_long.emit()

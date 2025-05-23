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


var x_buy
var current_hack_item_cara
var progress_activated: bool = false
var time_process:float
var first_cost = INF
var quantity_to_buy: int
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	pass # Replace with function body.
	
func _process(delta: float) -> void:
	if progress_activated:
		time_process += delta
		hack_item_progress_bar.value = time_process
		if time_process >= current_hack_item_cara["delay"]:
			time_finished()

func set_hacking_item(item_name):
	"""on initialise depuis la base de donnée."""
	set_unlocked_button_state()
	current_hack_item_cara = HackingItemsDb.get_item_cara(item_name)
	var item_level = current_hack_item_cara["level"]

	#le gain de abse correspond à ce qu'il y a dans la db
	gold_gain.text = Global.number_to_string((current_hack_item_cara["cost"]))

	hack_item_level.text = Global.number_to_string(item_level)
	hack_item_cd.text =  "/ " + str(current_hack_item_cara["delay"]) + " secs"
	hack_item_texture.disabled = true
	
	#set_hacking_item_by_player_info()
	x_buy = 1
	x_can_be_buy(x_buy)# par défaut on affiche le prix à 1 item d'acheter

	

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
	hack_item_cd.text = "/ " + str(current_hack_item_cara["delay"]) + " secs"
	if item_cara["level"] > 0 and not progress_activated:
		hack_item_texture.disabled = false
	x_can_be_buy(x_buy)
	
	pass
	
func knwoledge_refresh_hack_item():
	if current_hack_item_cara["level"] > 0:
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
	hack_item_progress_bar.rounded =false
	time_process = 0
	hack_item_progress_bar.max_value = current_hack_item_cara["delay"]
	hack_item_progress_bar.min_value = 0
	hack_item_progress_bar.step = 0.01
	
	hack_item_texture.disabled = true
	progress_activated = true
	
	pass


func time_finished() -> void:
	"""On lance le timer de la progression bar. A sa fin, on a le gain de la gold"""
	progress_activated = false
	hack_item_progress_bar.value = 0
	#TODO Faire le cas où l'item n'est pas encore acheté
	
	hack_item_texture.disabled = false
	Player.gold += Calculs.gain_gold(current_hack_item_cara["item_name"])
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

func _on_hack_item_texture_pressed() -> void:
	lauch_wait_time()
	pass # Replace with function body.

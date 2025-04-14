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


var x_buy
var current_hack_item_cara
var progress_activated: bool = false
var time_process:float
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
func _process(delta: float) -> void:
	if progress_activated:
		time_process += delta
		hack_item_progress_bar.value = time_process
		if time_process >= current_hack_item_cara["base_time_delay"]:
			time_finished()

func set_hacking_item(item_name):
	"""on initialise depuis la base de donnée."""
	current_hack_item_cara = HackingItemsDb.get_item_cara(item_name)
	var item_level = current_hack_item_cara["level"]

	#le gain de abse correspond à ce qu'il y a dans la db
	gold_gain.text = Global.number_to_string((current_hack_item_cara["base_gold_point"]))

	hack_item_level.text = Global.number_to_string(item_level)
	hack_item_price_label.text =  Global.number_to_string(Calculs.calcul_hacking_item_price(item_level))
	hack_item_cd.text =  "/ " + str(current_hack_item_cara["base_time_delay"]) + " secs"
	#set_hacking_item_by_player_info()
	x_buy = 1
	x_can_be_buy(x_buy)# par défaut on affiche le prix à 1 item d'acheter
	

func set_refresh(item_cara: Dictionary):
	"""On met à jour les stats du current_item. EN principe le current_item vaut à présent l'item qui 
	est dans l'inventaire du joueur"""
	current_hack_item_cara = item_cara
	var item_level = current_hack_item_cara["level"]

	hack_item_level.text = Global.number_to_string(item_level)
	hack_item_price_label.text =  Global.number_to_string(Calculs.calcul_hacking_item_price(item_level))
	print(Calculs.gain_gold(current_hack_item_cara["item_name"]))
	gold_gain.text = Global.number_to_string(Calculs.gain_gold(current_hack_item_cara["item_name"]))
	hack_item_cd.text = "/ " + str(current_hack_item_cara["base_time_delay"]) + " secs"
	x_can_be_buy(x_buy)
	
	pass

func x_can_be_buy(_x_buy):
	"""affiche le nombre de fois que l'item peut etre acheté"""
	x_buy = _x_buy
	var item_price = Calculs.calcul_hacking_item_price(current_hack_item_cara['level'])
	if _x_buy == -1:  #CAS DU MAX
		#TODO
		
		pass
		#var total_price = 0
		#for i in range(10):
			#total_price += calcul_item_price(current_item_cara["level"] * (i + 1))

	item_price = Calculs.total_hacking_prices(current_hack_item_cara["level"], x_buy)

	if Player.knowledge_point  < item_price:
		buy_item_button.disabled = true
	else:
		buy_item_button.disabled = false
		
	# on tente de maj le prix ici
	
	hack_item_price_label.text = Global.number_to_string(item_price)
	nbof_buy.text = "X " + str(x_buy)
	#Puis on met à jour le prix de l'item
	
	
func lauch_wait_time():
	hack_item_progress_bar.rounded =false
	time_process = 0
	hack_item_progress_bar.max_value = current_hack_item_cara["base_time_delay"]
	hack_item_progress_bar.min_value = 0
	hack_item_progress_bar.step = 0.01
	
	
	progress_activated = true
	
	pass


func time_finished() -> void:
	"""On lance le timer de la progression bar. A sa fin, on a le gain de la gold"""
	progress_activated = false
	hack_item_progress_bar.value = 0
	#TODO Faire le cas où l'item n'est pas encore acheté
	
	Player.gold += Calculs.gain_gold(current_hack_item_cara["item_name"])
	pass # Replace with function body.


func _on_hack_item_texture_pressed() -> void:
	lauch_wait_time()
	pass # Replace with function body.

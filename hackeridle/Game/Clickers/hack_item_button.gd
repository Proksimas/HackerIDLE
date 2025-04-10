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
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass




func set_item(item_name):
	"""Il faut set l'item par rapport à l'inventaire du joueur"""
	var hack_item_cara = Player.hacking_item_bought[item_name]
	current_hack_item_cara = hack_item_cara
	
	hack_item_cd.text = " / " + str(hack_item_cara["base_time_delay"]) + " secs"
	
	set_info()
	x_can_be_buy(1)# par défaut on affiche le prix à 1 item d'acheter
	
func set_info():
	
	var item_name = current_hack_item_cara["item_name"]
	var item_level = current_hack_item_cara["level"]
	
	hack_item_level.text = Global.number_to_string(item_level)
	hack_item_price_label.text =  Global.number_to_string(item_level)

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


func _on_hack_item_texture_pressed() -> void:
	"""On lance le timer de la progression bar. A sa fin, on a le gain de la gold"""
	Calculs.gain_knowledge_point(current_hack_item_cara["item_name"])
	pass # Replace with function body.

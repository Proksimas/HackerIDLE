extends Control

class_name HackItemButton

@onready var hack_item_progress_bar: ProgressBar = %HackItemProgressBar
@onready var seconds_left: Label = %SecondsLeft
@onready var buy_item_button: Button = %BuyItemButton
@onready var buy_title: Label = %BuyTitle
@onready var nbof_buy: Label = %NbofBuy
@onready var hack_item_price_label: Label = %HackItemPriceLabel
@onready var hack_item_cd: Label = %HackItemCD
@onready var hack_item_level: Label = %HackItemLevel


var x_buy
var current_hack_item_cara
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass




func set_item(item_name):
	var hack_item_cara = HackingItemsDb.get_item_cara(item_name)
	current_hack_item_cara = hack_item_cara
	
	hack_item_cd.text = " / " + str(hack_item_cara["base_time_delay"])
	seconds_left.text = "0"
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
	var item_price = Calculs.calcul_item_price(current_hack_item_cara['level'])
	if _x_buy == -1:  #CAS DU MAX
		#TODO
		
		pass
		#var total_price = 0
		#for i in range(10):
			#total_price += calcul_item_price(current_item_cara["level"] * (i + 1))

	item_price = Calculs.total_hacking_prices(current_hack_item_cara["level"], x_buy)
	if Player.gold  < item_price:
		self.disabled = true
	else:
		self.disabled = false
		
	# on tente de maj le prix ici
	
	hack_item_price_label.text = Global.number_to_string(item_price)
	#Puis on met à jour le prix de l'item

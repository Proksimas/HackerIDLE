extends Button

class_name ShopItem

@onready var shop_texture: TextureRect = %ShopTexture

@onready var item_price_label: Label = %ItemPriceLabel
@onready var item_name_label: Label = %ItemNameLabel
@onready var level_label: Label = %LevelLabel
@onready var level_point_label: Label = %LevelPointLabel
@onready var speed_label: Label = %SpeedLabel
@onready var speed_point_label: Label = %SpeedPointLabel

var current_item_cara: Dictionary
var x_buy: int
		
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.




func set_item(item_name):
	var item_player_cara = Player.learning_item_bought[item_name]
	var item_cara =  LearningItemsDB.learning_items_db[item_name]
	current_item_cara = item_player_cara
	
	shop_texture.texture = load(item_cara["texture_path"])
	set_info()
	x_can_be_buy(1)# par défaut on affiche le prix à 1 item d'acheter
	pass

func set_info():
	var item_name = current_item_cara["item_name"]
	item_name_label.text = item_name
	
	var item_price = calcul_item_price()
	item_price_label.text = Global.number_to_string(item_price)
	#Puis on met à jour le prix de l'item
	Player.change_property_value(item_name,"item_price",item_price)
	
	var item_level = current_item_cara["level"]
	level_point_label.text = Global.number_to_string(item_level)
	
	
func calcul_item_price()-> int:
	"""Fonction qui renvoie le prix de l'item"""
	# ATTENTION TODO faut que l'item price correspond au prix actuel

	return int(current_item_cara["level"])
	
func x_can_be_buy(_x_buy):
	"""affiche le nombre de fois que l'item peut etre acheté"""
	x_buy = _x_buy
	print(calcul_item_price() * x_buy)
	if _x_buy == -1:
		var total_price = 0
		for i in range(10):
			total_price += calcul_item_price() * (i + 1)
			print(total_price)

	if Player.gold  < calcul_item_price() * x_buy:
		self.disabled = true
	else:
		self.disabled = false
		
	

func total_prices(quantity):
	var total_price = 0
	for i in range(quantity):
		total_price += calcul_item_price() 
		#TODO
	pass

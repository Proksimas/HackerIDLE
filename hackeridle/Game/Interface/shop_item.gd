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
	current_item_cara = LearningItemsDB.get_item_cara(item_name)
	
	item_name_label.text = current_item_cara["item_name"]
	shop_texture.texture = load(current_item_cara["texture_path"])
	level_point_label.text = Global.number_to_string(current_item_cara["level"])
	x_buy = 1
	x_can_be_buy(x_buy)# par défaut on affiche le prix à 1 item d'acheter
	pass

func set_refresh(item_cara: Dictionary):
	current_item_cara = item_cara
	var item_name = current_item_cara["item_name"]
	item_name_label.text = item_name
	
	var item_level = current_item_cara["level"]
	level_point_label.text = Global.number_to_string(item_level)

	x_can_be_buy(x_buy)

func gold_refresh_shop_item():
	x_can_be_buy(x_buy)
	

func x_can_be_buy(_x_buy):
	"""affiche le nombre de fois que l'item peut etre acheté"""
	x_buy = _x_buy
	var item_price = Calculs.calcul_learning_item_price(current_item_cara['level'])
	if _x_buy == -1:  #CAS DU MAX
		#TODO
		
		pass
		#var total_price = 0
		#for i in range(10):
			#total_price += calcul_item_price(current_item_cara["level"] * (i + 1))

	item_price = Calculs.total_learning_prices(current_item_cara, x_buy)
	if Player.gold  < item_price:
		self.disabled = true
	else:
		self.disabled = false
		
	# on tente de maj le prix ici
	
	item_price_label.text = Global.number_to_string(item_price)
	#Puis on met à jour le prix de l'item
		
	

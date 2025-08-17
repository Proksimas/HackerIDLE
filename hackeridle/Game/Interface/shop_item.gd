extends Button

class_name ShopItem

@onready var shop_texture: TextureRect = %ShopTexture

@onready var item_price_label: Label = %ItemPriceLabel
@onready var item_name_label: Label = %ItemNameLabel
@onready var level_label: Label = %LevelLabel
@onready var level_point_label: Label = %LevelPointLabel
@onready var to_unlocked_panel: ColorRect = %ToUnlockedPanel
@onready var unlocked_button: Button = %UnlockedButton
@onready var gold_cost: Label = %GoldCost
@onready var learning_item_info: HBoxContainer = %LearningItemInfo
@onready var gain_knowledge_label: Label = %GainKnowledgeLabel
@onready var cost_label: Label = %CostLabel

var current_item_cara: Dictionary
var x_buy: int
var first_cost = INF
var quantity_to_buy: int
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func set_item(item_name):
	
	current_item_cara = LearningItemsDB.get_item_cara(item_name)
	item_name_label.text = current_item_cara["item_name"]
	shop_texture.texture = load(current_item_cara["texture_path"])
	level_point_label.text = Global.number_to_string(current_item_cara["level"])
	gain_knowledge_label.text = "+" + Global.number_to_string(Calculs.passif_learning_gain(current_item_cara)) + " /s"
	first_cost = Calculs.total_learning_prices(current_item_cara, 1)
	x_buy = 1
	x_can_be_buy(x_buy)# par défaut on affiche le prix à 1 item d'acheter
	set_unlocked_button_state()
	pass

func set_refresh(item_cara: Dictionary):
	if !Player.learning_item_bought.has(item_cara["item_name"]) or \
	!Player.learning_item_statut[item_cara["item_name"]] == "unlocked":
		return
	
	current_item_cara = item_cara
	var item_name = current_item_cara["item_name"]
	item_name_label.text = item_name
	var item_level = current_item_cara["level"]
	level_point_label.text = Global.number_to_string(item_level)
	gain_knowledge_label.text = "+" + Global.number_to_string(Calculs.passif_learning_gain(current_item_cara)) + " /s"
	

	x_can_be_buy(x_buy)
	#set_unlocked_button_state()

func gold_refresh_shop_item():
	x_can_be_buy(x_buy)
	set_unlocked_button_state()
	
func set_unlocked_button_state():
	if Player.gold >= first_cost:
		unlocked_button.disabled = false
		unlocked_button.modulate = Color(1,1,1)
	else:
		unlocked_button.disabled = true
		unlocked_button.modulate = Color(0.502, 0.502, 0.502)
func x_can_be_buy(_x_buy):
	"""affiche le nombre de fois que l'item peut etre acheté"""
	if current_item_cara.is_empty():
		return
	x_buy = _x_buy
	var item_price
	if _x_buy == -1:  #CAS DU MAX
		#TODO
		quantity_to_buy =  Calculs.quantity_learning_item_to_buy(current_item_cara)
		if quantity_to_buy == 0:
			quantity_to_buy = 1  #on force en mettant un achat à x1
	else:
		quantity_to_buy = x_buy
		
	item_price = Calculs.total_learning_prices(current_item_cara, quantity_to_buy)
	if Player.gold  < item_price:
		self.disabled = true
	else:
		self.disabled = false
		
	# on tente de maj le prix ici
	
	item_price_label.text = Global.number_to_string(item_price)

		
	
func statut_updated():
	"""met à jour le statut de l'item"""
	if Player.learning_item_statut[current_item_cara["item_name"]] == 'unlocked':
		self.show()
		learning_item_info.show()
		to_unlocked_panel.hide()
		
	elif Player.learning_item_statut[current_item_cara["item_name"]] == 'to_unlocked':
		#item a un prix de base pour être debloqué + ui associé
		# TODO
		self.show()
		learning_item_info.hide()
		to_unlocked_panel.show()
		first_cost = Calculs.total_learning_prices(current_item_cara, 1)
		gold_cost.text = Global.number_to_string(first_cost)
		cost_label.text = tr('$Cost') + ": "
		pass
		
	elif Player.learning_item_statut[current_item_cara["item_name"]] == 'locked':
		self.hide()
		
func get_knowledge_from_passif() -> float:
	var knowledge_gain:float = 0
	if !Player.learning_item_statut[current_item_cara["item_name"]] == 'unlocked':
		return knowledge_gain
	knowledge_gain = Calculs.passif_learning_gain(current_item_cara)
	return knowledge_gain

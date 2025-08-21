extends Control

@onready var shop_grid: GridContainer = %ShopGrid
@onready var buttons_container: HBoxContainer = %ButtonsContainer


const SHOP_ITEM = preload("res://Game/Interface/shop_item.tscn")


var x_upgrade_value: int

signal item_bought(name)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_clear()
	for button:Button in buttons_container.get_children():
		button.pressed.connect(_on_x_button_pressed.bind(button.name))

func set_shop():
	var item_present: Dictionary
	for shop_item:ShopItem in shop_grid.get_children():
		item_present[shop_item.current_item_cara["item_name"]] = shop_item

	for item_name in LearningItemsDB.learning_items_db:
		
		if item_present.has(item_name) and Player.has_learning_item(item_name):
			item_present[item_name].set_refresh(item_present[item_name].current_item_cara)
			
		elif item_present.has(item_name) and !Player.has_learning_item(item_name):
			continue
			
		else:
			var new_learning_item:ShopItem = SHOP_ITEM.instantiate()
			shop_grid.add_child(new_learning_item)
			new_learning_item.set_item(item_name)
			
			new_learning_item.pressed.connect(_on_shop_button_pressed.bind(new_learning_item))
			new_learning_item.unlocked_button.pressed.connect(_on_unlocked_button_pressed.bind(new_learning_item))
		
func player_bought_learning_item(item_name,  quantity):
	
	var cost = 0
	# si le joueur a déjà l'item, on augmente son niveau
	if not Player.has_learning_item(item_name):
		#on regarde le cout de l'item à l'unité
		var item_cara = LearningItemsDB.get_item_cara(item_name)
		cost = Calculs.total_learning_prices(item_cara, 1)
		
		if Player.gold >=  cost:
			Player.earn_gold(-cost)
			Player.add_learning_item(LearningItemsDB.get_item_cara(item_name))
		else:
			push_warning("On ne devrait pas pouvoir acheter litem, pas assez d'or")
			
	else:
		cost = Calculs.total_learning_prices(Player.learning_item_bought[item_name], quantity)
		if Player.gold >=  cost:
			Player.earn_gold(-cost)
			Player.learning_item_level_up(item_name, quantity)
		else:
			push_warning("On ne devrait pas pouvoir acheter litem, pas assez d'or")

		##Puis on ajuste l'ui de l'item acheté pour optimisé
	for shop_item:ShopItem in shop_grid.get_children():
		if  not shop_item.current_item_cara.is_empty() and shop_item.current_item_cara["item_name"] == item_name:
			shop_item.set_refresh(Player.learning_item_bought[item_name])
			
	# Et on envoie le signal d'achat
	item_bought.emit(item_name)

func learning_items_statut_updated():
	get_tree().call_group("g_shop_item", "statut_updated")
	pass
	
func get_tot_knowledge_from_shop_items():
	var tot_knowledge: float = 0
	for shop_item in shop_grid.get_children():
		tot_knowledge += shop_item.get_knowledge_from_passif()
	
	return tot_knowledge

func _draw() -> void:
	#ATTENTION peut engendrer des bugs si le player n'est pas initialisé avec son inventaire
	set_shop()
	learning_items_statut_updated()
	%X1Button.pressed.emit()

func _clear():
	for item in shop_grid.get_children():
		item.queue_free()

func _on_shop_button_pressed(shop_item: ShopItem):
	
	player_bought_learning_item(shop_item.current_item_cara["item_name"], shop_item.quantity_to_buy)
	get_tree().call_group("g_shop_item", "x_can_be_buy", x_upgrade_value)
	

func _on_unlocked_button_pressed(shop_item: ShopItem):
	player_bought_learning_item(shop_item.current_item_cara["item_name"], 1)
	Player.learning_item_statut[shop_item.current_item_cara["item_name"]] = "unlocked"
	learning_items_statut_updated()
	

func _on_x_button_pressed(button_name: String):
	'''définit le *X d achat possible'''
	match button_name.trim_suffix("Button"):
		"X1":
			x_upgrade_value = 1
		"X10":
			x_upgrade_value = 10
		"X100":
			x_upgrade_value = 100
		"XMax":
			x_upgrade_value = -1  
 
	get_tree().call_group("g_shop_item", "x_can_be_buy", x_upgrade_value)

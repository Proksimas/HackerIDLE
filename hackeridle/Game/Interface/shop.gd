extends Control

@onready var shop_grid: GridContainer = %ShopGrid
@onready var buttons_container: HBoxContainer = %ButtonsContainer


const SHOP_ITEM = preload("res://Game/Interface/shop_item.tscn")


var x_upgrade_value: int
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	############ TEST
	Player.gold = 10000
	
	
	_clear()
	#Le joueur commence forcement avec le premier item au niveau 1

	player_bought_item("post-it", 1)
	#################"
	
	for button:Button in buttons_container.get_children():
		button.pressed.connect(_on_x_button_pressed.bind(button.name))
	pass # Replace with function body.




func set_shop():
	_clear()
	for item_name in LearningItemsDB.learning_items_db:
		var new_shop_item:ShopItem = SHOP_ITEM.instantiate()
		shop_grid.add_child(new_shop_item)
		new_shop_item.set_item(item_name)
		new_shop_item.pressed.connect(_on_shop_button_pressed.bind(new_shop_item))
	pass

func player_bought_item(item_name,  quantity):
	
	# si le joueur a déjà l'item, on augmente son niveau
	if not Player.has_item(item_name):
		Player.add_item(LearningItemsDB.get_item_cara(item_name))
	else:
		Player.item_level_up(item_name, quantity)
		
	if Player.gold >= Player.learning_item_bought[item_name]["item_price"] * quantity:
		Player.gold -= Player.learning_item_bought[item_name]["item_price"] * quantity
		
	else:
		push_warning("On ne devrait pas pouvoir acheter litem, pas assez d'or")
	
	
	
	#Puis on ajuste l'ui de l'item acheté pour optimisé
	for shop_item:ShopItem in shop_grid.get_children():
		if  not shop_item.current_item_cara.is_empty() and shop_item.current_item_cara["item_name"] == item_name:
			shop_item.set_info()
	
	pass
	

func _draw() -> void:
	set_shop()
	%X1Button.pressed.emit()

func _clear():
	for item in shop_grid.get_children():
		item.queue_free()

func _on_shop_button_pressed(shop_item: ShopItem):
	
	player_bought_item(shop_item.current_item_cara["item_name"], shop_item.x_buy)
	get_tree().call_group("g_shop_item", "x_can_be_buy", x_upgrade_value)
	

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

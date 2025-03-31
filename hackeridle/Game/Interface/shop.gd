extends Control

@onready var shop_grid: GridContainer = %ShopGrid


const SHOP_ITEM = preload("res://Game/Interface/shop_item.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	#Le joueur commence forcement avec le premier item au niveau 1
	player_bought_item("post-it", 1)
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func set_shop():
	_clear()
	for item_name in LearningItemsDB.learning_items_db:
		var new_shop_item:ShopItem = SHOP_ITEM.instantiate()
		shop_grid.add_child(new_shop_item)
		new_shop_item.set_item(item_name)
		new_shop_item.pressed.connect(_on_shop_button_pressed.bind(new_shop_item.current_item_cara))
	
	pass

func player_bought_item(item_name, quantity):
	
	#TODO voir pour les prix
	
	# si le joueur a déjà l'item, on augmente son niveau
	if not Player.has_item(item_name):
		Player.add_item(LearningItemsDB.get_item_cara(item_name))
	else:
		Player.item_level_up(item_name, quantity)
	#
	
	
	#Puis on ajuste l'ui de l'item acheté pour optimisé
	for shop_item:ShopItem in shop_grid.get_children():
		if  not shop_item.current_item_cara.is_empty() and shop_item.current_item_cara["item_name"] == item_name:
			shop_item.set_info()
	
	pass


func _draw() -> void:
	set_shop()

func _clear():
	for item in shop_grid.get_children():
		item.queue_free()



func _on_shop_button_pressed(item_cara: Dictionary):
	player_bought_item(item_cara["item_name"], 1)
	

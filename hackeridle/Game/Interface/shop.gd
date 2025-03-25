extends Control

@onready var shop_grid: GridContainer = %ShopGrid


const SHOP_ITEM = preload("res://Game/Interface/shop_item.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_bought_item("post-it")
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
	
	pass

func player_bought_item(item_name):
	
	#TODO voir pour les prix
	
	Player.add_item(LearningItemsDB.get_item_cara(item_name))
	#
	
	pass




func _draw() -> void:
	set_shop()

func _clear():
	for item in shop_grid.get_children():
		item.queue_free()

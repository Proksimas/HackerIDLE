extends VBoxContainer

class_name ShopItem

@onready var shop_button: TextureButton = %ShopButton
@onready var item_price_label: Label = %ItemPriceLabel

var current_item_cara: Dictionary
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func set_item(item_name):
	var item_player_cara = Player.learning_item_bought[item_name]
	var item_cara =  LearningItemsDB.learning_items_db[item_name]
	
	shop_button.texture_normal = load(item_cara["texture_path"])
	
	var item_price = item_player_cara["level"] # ATTENTION TODO faut que l'item price correspond au prix
	item_price_label.text = Global.number_to_string(item_price)
	
	pass

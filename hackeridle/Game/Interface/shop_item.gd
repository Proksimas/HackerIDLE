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
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func set_item(item_name):
	var item_player_cara = Player.learning_item_bought[item_name]
	var item_cara =  LearningItemsDB.learning_items_db[item_name]
	current_item_cara = item_player_cara
	
	shop_texture.texture = load(item_cara["texture_path"])
	set_info()

	pass

func set_info():
	var item_name = current_item_cara["item_name"]
	item_name_label.text = item_name
	
	var item_price = current_item_cara["level"] # ATTENTION TODO faut que l'item price correspond au prix
	item_price_label.text = Global.number_to_string(item_price)
	
	var item_level = current_item_cara["level"]
	level_point_label.text = Global.number_to_string(item_level)
	
	
	
	

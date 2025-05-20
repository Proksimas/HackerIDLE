extends Control


@onready var learning: Control = %Learning
@onready var hack_shop: Control = %HackShop
@onready var shop: Control = %Shop
@onready var main_tab: TabContainer = %MainTab
@onready var navigator: TextureButton = %Navigator
@onready var knowledge_label: Label = %KnowledgeLabel
@onready var gold_label: Label = %GoldLabel
@onready var passif_clickers: HFlowContainer = %PassifClickers


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Player.earn_knowledge_point.connect(_on_earn_knowledge_point)
	Player.earn_hacking_point.connect(_on_earn_hacking_point)
	Player.earn_gold.connect(_on_earn_gold)
	shop.item_bought.connect(learning._on_shop_item_bought)
	
	for child in passif_clickers.get_children():
		child.queue_free()
	
	

func _on_shopping_pressed() -> void:
	shop.show()
	pass # Replace with function body.


func _on_navigator_pressed() -> void:
	learning.show()
	pass # Replace with function body.


func _on_earn_knowledge_point(point):
	knowledge_label.text = Global.number_to_string(int(point))
	get_tree().call_group("g_hack_item_button", "knwoledge_refresh_hack_item")

func _on_earn_hacking_point(point):
	return
	
func _on_earn_gold(point):
	gold_label.text =  Global.number_to_string(int(point))
	get_tree().call_group("g_shop_item", "gold_refresh_shop_item")
	
	
func _on_dark_shop_pressed() -> void:
	hack_shop.show()
	pass # Replace with function body.


func _load_data(data):
	"""Manage les chargement dans l'interface"""
	learning._load_data(data["learning_item_bought"])

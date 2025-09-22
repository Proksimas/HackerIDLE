extends Control

@onready var next_bot_price_value: Label = %NextBotPriceValue
@onready var gold_per_click_title: Label = %GoldPerClickTitle
@onready var nb_of_click_title: Label = %NbOfClickTitle
@onready var nb_of_click_value: Label = %NbOfClickValue
@onready var knowledge_per_click_title: Label = %KnowledgePerClickTitle
@onready var knowledge_per_click_value: Label = %KnowledgePerClickValue
@onready var gold_invest_box: SpinBox = %GoldInvestBox
@onready var clicker_arc: AspectRatioContainer = %ClickerARC
@onready var clicker_bot_button: TextureButton = %ClickerBotButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connexions()
	
	Player.gold = 1000
	Player.knowledge_point = 1000 
	pass # Replace with function body.

func connexions():
	NovaNetManager.s_bot_bought.connect(_on_s_bot_bought)
	NovaNetManager.s_bot_knowledge_gain.connect(_on_s_bot_knowledge_gain)

func refresh():
	next_bot_price_value.text = Global.number_to_string(NovaNetManager.get_bot_cost(Player.bots))
	nb_of_click_value.text = Global.number_to_string(NovaNetManager.nb_click_required(NovaNetManager.gold_to_invest))
	knowledge_per_click_value.text = Global.number_to_string(NovaNetManager.knowledge_per_click(NovaNetManager.gold_to_invest))
	
func _on_click_bot_pressed() -> void:
	NovaNetManager.click(NovaNetManager.gold_to_invest)
	pass # Replace with function body.


func _draw() -> void:
	refresh()
	
func _on_s_bot_bought():
	refresh()

func _on_s_bot_knowledge_gain(knowledge_gain):
	refresh()


func _on_gold_invest_box_value_changed(value: int) -> void:
	NovaNetManager.gold_to_invest = value
	refresh()
	pass # Replace with function body.

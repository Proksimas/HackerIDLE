extends Control

@onready var next_bot_price_value: Label = %NextBotPriceValue
@onready var gold_per_click_title: Label = %GoldPerClickTitle
@onready var nb_of_click_title: Label = %NbOfClickTitle
@onready var nb_of_click_value: Label = %NbOfClickValue
@onready var knowledge_per_click_title: Label = %KnowledgePerClickTitle
@onready var knowledge_per_click_value: Label = %KnowledgePerClickValue
@onready var gold_invest_label: Label = %GoldInvestLabel
@onready var clicker_arc: AspectRatioContainer = %ClickerARC
@onready var clicker_bot_button: TextureButton = %ClickerBotButton
@onready var gold_invest_box: HSlider = %GoldInvestBox



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connexions()
	
	Player.gold = 100000000
	Player.knowledge_point = 100000000
	pass # Replace with function body.

func connexions():
	NovaNetManager.s_bot_bought.connect(_on_s_bot_bought)
	NovaNetManager.s_bot_knowledge_gain.connect(_on_s_bot_knowledge_gain)

func refresh():
	next_bot_price_value.text = Global.number_to_string(NovaNetManager.get_bot_cost(Player.bots))
	nb_of_click_value.text = Global.number_to_string(NovaNetManager.nb_click_left(NovaNetManager.gold_to_invest))
	gold_invest_label.text = Global.number_to_string(NovaNetManager.gold_to_invest)
	knowledge_per_click_value.text = Global.number_to_string(NovaNetManager.knowledge_per_click(NovaNetManager.gold_to_invest))
	
func _on_click_bot_pressed() -> void:
	NovaNetManager.click(NovaNetManager.gold_to_invest)
	_on_gold_invest_box_value_changed(gold_invest_box.value)
	pass # Replace with function body.


func _draw() -> void:
	refresh()
	
func _on_s_bot_bought():
	refresh()

func _on_s_bot_knowledge_gain(knowledge_gain):
	refresh()


func _on_gold_invest_box_value_changed(value: int) -> void:
	var perc_invest = Player.gold * (float(value)/100)
	NovaNetManager.gold_to_invest = perc_invest
	refresh()
	pass # Replace with function body.


func _on_refresh_timer_timeout() -> void:
	_on_gold_invest_box_value_changed(gold_invest_box.value)
	pass # Replace with function body.

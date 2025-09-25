extends VBoxContainer

@onready var sales_label: Label = %SalesLabel
@onready var sales_container: HBoxContainer = %SalesContainer
@onready var sales_slider: HSlider = %SalesSlider
@onready var sales_bots_value: Label = %SalesBotsValue
@onready var gold_invest_label: Label = %GoldInvestLabel

@onready var market_graph: MarketGraph = %MarketGraph

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	NovaNetManager.s_gain_sales.connect(s_on_s_gain_sales)
	pass # Replace with function body.


func refresh():
	sales_bots_value.text = str(NovaNetManager.active_tasks["farming_xp"])

func _on_draw() -> void:
	refresh()
	pass # Replace with function body.

func _on_invest_button_pressed() -> void:
	NovaNetManager.gold_invest_in_sales += 100
	pass # Replace with function body.


func s_on_s_gain_sales(gain):
	market_graph._on_market_updated(gain)
	pass

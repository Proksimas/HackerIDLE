extends VBoxContainer

@onready var sales_label: Label = %SalesLabel
@onready var sales_container: HBoxContainer = %SalesContainer
@onready var sales_slider: HSlider = %SalesSlider
@onready var sales_bots_value: Label = %SalesBotsValue
#@onready var gold_invest_label: Label = %GoldInvestLabel
@onready var knowledge_invest_label: Label = %KnowledgeInvestLabel
@onready var invest_title: Label = %InvestTitle
@onready var invest_button: Button = %InvestButton
@onready var total_investi_title: Label = %TotalInvestiTitle
@onready var total_investi_label: Label = %TotalInvestiLabel
@onready var sales_title: Label = %SalesTitle
@onready var average_gain_label: Label = %AverageGainLabel
@onready var average_gain_value: Label = %AverageGainValue

@onready var market_graph: MarketGraph = %MarketGraph

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Player.s_gold_to_earn.connect(_on_s_gold_to_earn)
	NovaNetManager.s_gain_sales.connect(s_on_s_gain_sales)
	refresh()
	pass # Replace with function body.


func refresh():
	sales_label.text = tr("$Sales")
	sales_title.text = tr("$Sales")
	sales_bots_value.text = str(NovaNetManager.active_tasks["sales_task"])
	var to_invest = NovaNetManager.knowledge_to_invest_perc * Player.knowledge_point
	knowledge_invest_label.text = Global.number_to_string(to_invest)
	invest_title.text = tr("$Invest") + ": " 
	total_investi_title.text = tr("$TotalInvesti") + ": "
	average_gain_label.text = tr("$AverageGain") + ": "
	total_investi_label.text = Global.number_to_string(NovaNetManager.knowledge_invest_in_sales)
	if NovaNetManager.active_tasks["sales_task"] > 0:
		invest_button.disabled = false
	else:
		invest_button.disabled = true

func _on_draw() -> void:
	refresh()
	pass # Replace with function body.

func _on_invest_button_pressed() -> void:
	"""On investit une quantité de connaissance"""
	var to_invest = NovaNetManager.knowledge_to_invest_perc * Player.knowledge_point
	
	Player.earn_knowledge_point(0 - to_invest )
	NovaNetManager.knowledge_invest_in_sales += to_invest
	
	refresh()
	pass # Replace with function body.

func s_on_s_gain_sales(gain):
	average_gain_value.text = Global.number_to_string(gain) + "/s"
	market_graph._on_market_updated(gain)
	pass

func _on_s_gold_to_earn(_gold):
	"""le joueur vient de gagner de largent"""
	refresh()


func _on_sales_button_pressed() -> void:
	get_parent().show()
	pass # Replace with function body.

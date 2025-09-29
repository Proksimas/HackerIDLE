extends VBoxContainer

@onready var next_bot_price_value: Label = %NextBotPriceValue
@onready var gold_per_click_title: Label = %GoldPerClickTitle
@onready var nb_of_click_title: Label = %NbOfClickTitle
@onready var nb_of_click_value: Label = %NbOfClickValue
@onready var knowledge_per_click_value: Label = %KnowledgePerClickValue
@onready var gold_invest_label: Label = %GoldInvestLabel
@onready var clicker_arc: AspectRatioContainer = %ClickerARC
@onready var clicker_bot_button: TextureButton = %ClickerBotButton
@onready var gold_invest_box: HSlider = %GoldInvestBox
@onready var knowledge_cost_label: Label = %KnowledgeCostLabel
@onready var spam_clic_timer: Timer = %SpamClicTimer

const BOT_FULL = preload("res://Game/Graphics/Common_icons/bot_full.png")
const BOT_NEO_SMILING = preload("res://Game/Graphics/Common_icons/bot_neo_smiling.png")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connexions()
	pass # Replace with function body.

func connexions():
	NovaNetManager.s_bot_bought.connect(_on_s_bot_bought)
	NovaNetManager.s_bot_knowledge_gain.connect(_on_s_bot_knowledge_gain)

func refresh():
	gold_per_click_title.text = tr("$Invest") + " "
	next_bot_price_value.text =  Global.number_to_string(NovaNetManager.next_bot_kwoledge_acquired) + \
			" / " + Global.number_to_string(NovaNetManager.get_bot_cost(Player.bots))
	nb_of_click_value.text = Global.number_to_string(NovaNetManager.nb_click_left(NovaNetManager.gold_to_invest))
	gold_invest_label.text = " - " + Global.number_to_string(NovaNetManager.gold_to_invest)
	knowledge_cost_label.text = tr("$ToSpendAndEarn") + " "
	knowledge_per_click_value.text = " - " + Global.number_to_string(NovaNetManager.knowledge_per_click(NovaNetManager.gold_to_invest))
	

func _on_click_bot_pressed() -> void:
	
	var has_click = NovaNetManager.click(NovaNetManager.gold_to_invest)
	if has_click:
		_on_gold_invest_box_value_changed(int(gold_invest_box.value))
		spam_clic_timer.start()
		clicker_bot_button.texture_normal = BOT_NEO_SMILING
		
	pass # Replace with function body.


func _draw() -> void:
	refresh()
	
func _on_s_bot_bought():
	refresh()

func _on_s_bot_knowledge_gain(_knowledge_gain):
	refresh()

var old_value: int
func _on_gold_invest_box_value_changed(value: int) -> void:
	old_value = value
	var perc_invest = floor(Player.gold * (float(value)/100)) #-> floor car on doit pouvoir vider toute l'or du joueur
	NovaNetManager.gold_to_invest = perc_invest
	refresh()
	pass # Replace with function body.


func _on_refresh_timer_timeout() -> void:
	_on_gold_invest_box_value_changed(int(gold_invest_box.value))
	pass # Replace with function body.

func _on_spam_clic_timer_timeout() -> void:
	clicker_bot_button.texture_normal = BOT_FULL
	pass # Replace with function body.

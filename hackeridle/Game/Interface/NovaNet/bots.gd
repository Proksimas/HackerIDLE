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
@onready var ia_enabled_button: Button = %IAEnabledButton
@onready var not_enough_container: HBoxContainer = %NotEnoughContainer
@onready var nb_of_bots_title: Label = %NbOfBotsTitle
@onready var nb_of_bots_value: Label = %NbOfBotsValue

const BOT_FULL = preload("res://Game/Graphics/Common_icons/bot_full.png")
const BOT_NEO_SMILING = preload("res://Game/Graphics/Common_icons/bot_neo_smiling.png")
const RED_BUTTON_DISABLED = preload("res://Game/Themes/RedButtonDisabled.tres")
const GREEN_BUTTON_ENABLED = preload("res://Game/Themes/GreenButtonEnabled.tres")
const GOLD_ICON = preload("res://Game/Interface/Icons/gold_icon.tscn")
const BRAIN_ICON = preload("res://Game/Interface/Icons/brain_icon.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connexions()
	pass # Replace with function body.
	
var _time = 0
func _process(delta: float) -> void:
	_time += delta
	if NovaNetManager.ia_is_enable and NovaNetManager.time_ia_click != -1 and _time >= NovaNetManager.time_ia_click:
		_on_click_bot_pressed()
		_time = 0
		
	if _time >= 100:
		_time = 0 #pour éviter un nombre quiaugmente indéfiniment

func connexions():
	NovaNetManager.s_bot_bought.connect(_on_s_bot_bought)
	NovaNetManager.s_bot_knowledge_gain.connect(_on_s_bot_knowledge_gain)
	NovaNetManager.s_not_enough.connect(_on_s_not_enough)

func refresh():
	
	nb_of_bots_title.text = tr("$NbOfBots") + ": "
	nb_of_bots_value.text = Global.number_to_string(Player.bots)
	gold_per_click_title.text = tr("$Invest") + " "
	next_bot_price_value.text =  Global.number_to_string(NovaNetManager.next_bot_kwoledge_acquired) + \
			" / " + Global.number_to_string(NovaNetManager.get_bot_cost(Player.bots))
	nb_of_click_value.text = Global.number_to_string(NovaNetManager.nb_click_left(NovaNetManager.gold_to_invest))
	gold_invest_label.text = " - " + Global.number_to_string(NovaNetManager.gold_to_invest)
	knowledge_cost_label.text = tr("$ToSpendAndEarn") + " "
	knowledge_per_click_value.text = " - " + Global.number_to_string(NovaNetManager.knowledge_per_click(NovaNetManager.gold_to_invest))
	if NovaNetManager.time_ia_click > 0:
		ia_enabled_button.show()
	ia_button_box()


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


func _on_ia_enabled_button_pressed() -> void:
	if NovaNetManager.time_ia_click == -1:
		push_error("On devrait pas pouvoir activer le bouton d'IA !")
	NovaNetManager.ia_is_enable = !NovaNetManager.ia_is_enable
	ia_button_box()
	pass # Replace with function body.

func ia_button_box():
	if NovaNetManager.time_ia_click == -1:
		ia_enabled_button.hide()
	else: ia_enabled_button.show()
	
	if NovaNetManager.ia_is_enable:
		ia_enabled_button.text = tr("$ia_enabled")
		var enabl_box = GREEN_BUTTON_ENABLED
		ia_enabled_button.add_theme_stylebox_override("normal", enabl_box)
		ia_enabled_button.add_theme_stylebox_override("hover", enabl_box)
	else:
		ia_enabled_button.text = tr("$ia_disabled")
		var disab_box = RED_BUTTON_DISABLED
		ia_enabled_button.add_theme_stylebox_override("normal", disab_box)
		ia_enabled_button.add_theme_stylebox_override("hover", disab_box)
		
var enough_in_progress: bool = false
func _on_s_not_enough(type: String):
	if enough_in_progress:
		return
	var icon
	var label = Label.new()
	
	match type:
		"knowledge":
			icon = BRAIN_ICON.instantiate()
		"gold":
			icon = GOLD_ICON.instantiate()
			
	not_enough_container.add_child(label)
	label.text = tr("$not_enough")
	not_enough_container.add_child(icon)
	not_enough_container.show()
	enough_in_progress = true
	await get_tree().create_timer(4).timeout
	for elmt in not_enough_container.get_children():
		elmt.queue_free()
	not_enough_container.hide()
	enough_in_progress = false

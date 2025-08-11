extends Control


@onready var learning: Control = %Learning
@onready var hack_shop: Control = %HackShop
@onready var shop: Control = %Shop
@onready var main_tab: TabContainer = %MainTab
@onready var navigator: TextureButton = %Navigator
@onready var settings: Control = %Settings
@onready var skills_tree: Control = %SkillsTree
@onready var second_timer: Timer = %SecondTimer

@onready var knowledge_resource: Control = %KnowledgeResource
@onready var gold_resource: Control = %GoldResource
@onready var sp_resource: Control = %SPResource
@onready var date_label: Label = %DateLabel
@onready var news_panel: PanelContainer = %NewsPanel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	main_tab.current_tab = 0
	connexions()
	init_interface()
	
func connexions() -> void:
	Player.s_earn_knowledge_point.connect(_on_earn_knowledge_point)
	Player.s_brain_clicked.connect(_on_s_brain_clicked)
	Player.s_earn_gold.connect(_on_earn_gold)
	Player.s_earn_sp.connect(_on_earn_sp)
	Player.s_earn_brain_xp.connect(_on_earn_brain_xp)
	Player.s_earn_brain_level.connect(_on_earn_brain_level)
	shop.item_bought.connect(learning._on_shop_item_bought)
	TimeManager.s_date.connect(_on_s_date)

func init_interface():
	knowledge_resource.set_resource_box("BRAIN")
	gold_resource.set_resource_box("GOLD")
	sp_resource.set_resource_box("SP")
	
	knowledge_resource.refresh_value(int(Player.knowledge_point))
	gold_resource.refresh_value(int(Player.gold))
	sp_resource.refresh_value(int(Player.skill_point))
	
	_on_s_brain_clicked(0,0)
	
	

func _on_shopping_pressed() -> void:
	shop.show()
	pass # Replace with function body.


func _on_navigator_pressed() -> void:
	learning.show()
	pass # Replace with function body.

func refresh_specially_resources():
	knowledge_resource.refresh_value(int(Player.knowledge_point))
	gold_resource.refresh_value(int(Player.gold))
	sp_resource.refresh_value(int(Player.skill_point))
	

	
func _on_earn_knowledge_point(point):
	knowledge_resource.refresh_value(int(point))
	get_tree().call_group("g_hack_item_button", "knwoledge_refresh_hack_item")

func _on_earn_gold(point):
	gold_resource.refresh_value(int(point))
	get_tree().call_group("g_shop_item", "gold_refresh_shop_item")
	
func _on_earn_sp(point):
	sp_resource.refresh_value(int(point))
	
func _on_earn_brain_xp(_point):
	learning.refresh_brain_xp_bar()
func _on_earn_brain_level(point):
	learning.current_brain_level.text = tr("$Level") + " " + str(point) 
	

var _recent_clicks: Array = []  # Stocke des paires [timestamp, valeur]
var _window_ms := 1100  # taille de la fenêtre mobile
var _sum_earning:float = 0
func _on_s_brain_clicked(_brain_xp, knowledge):
	"""chaque Connaissance acquise via le click du cerveau.
	Nous additionnons avec le gain par seconde des items passifs"""
	var now:= Time.get_ticks_msec()
	_recent_clicks.append([now, knowledge])
	_recent_clicks = _recent_clicks.filter(func(e): return now - e[0] <= _window_ms)

	_sum_earning = 0
	for e in _recent_clicks:
		_sum_earning += e[1]
	var total = _sum_earning + learning.passives_knowledge 
	
	learning.knowledge_per_second.text = Global.number_to_string(total) + " /s"
	#et_tree().create_timer(1.0).timeout.connect(_on_sum_timer)
	
#func _on_sum_timer():
	#"""On force pour la réinitialisation à zero"""
	#Player.earn_knowledge_point(0)
	
func _on_dark_shop_pressed() -> void:
	hack_shop.show()
	pass # Replace with function body.


func _on_settings_button_pressed() -> void:
	settings.show()
	pass # Replace with function body.


func _on_skills_button_pressed() -> void:
	skills_tree.show()
	pass # Replace with function body.

func _on_second_timer_timeout() -> void:
	_on_s_brain_clicked(0, 0)
	pass # Replace with function body.
	

func _on_s_date(array):
	# array[year, month, day, hour, minute]
	
	date_label.text = str(array[0]) +  " - " + str(array[1]) + " - " + str(array[2])
	


func _load_data(data):
	"""Manage les chargement dans l'interface"""
	# Met à jour l'UI
	init_interface()
	#sauvegarde au nivau du learning
	print("Chargement des learning item\n%s" % data["Player"]["learning_item_bought"] )
	learning._load_data(data["Player"]["learning_item_bought"])
	print("Chargement du hack shop")
	hack_shop._load_data("")
	print("Chargement du news panel\n%s" % data["NewsPanel"])
	news_panel._load_data(data["NewsPanel"])

@onready var cheat_event_spin_box: SpinBox = %CheatEventSpinBox

func _on_button_pressed() -> void:
	cheat_event_spin_box.apply()
	var event_ui = EventsManager.create_event_ui()
	event_ui.event_ui_setup(cheat_event_spin_box.value)
	pass # Replace with function body.

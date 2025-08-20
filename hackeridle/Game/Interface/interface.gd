extends Control

@onready var learning: Control = %Learning
@onready var hack_shop: Control = %HackShop
@onready var shop: Control = %Shop
@onready var main_tab: TabContainer = %MainTab
@onready var navigator: TextureRect = %Navigator
@onready var infos: Control = %Infos
@onready var jail: Control = %Jail

@onready var skills_tree: Control = %SkillsTree
@onready var second_timer: Timer = %SecondTimer
@onready var navgation_grid: HBoxContainer = %NavgationGrid
@onready var interface_panel: Panel = %InterfacePanel
#@onready var event_ui: Panel = %EventUI
#@onready var event_container: Container = %EventContainer

@onready var knowledge_resource: Control = %KnowledgeResource
@onready var gold_resource: Control = %GoldResource
@onready var sp_resource: Control = %SPResource
@onready var date_label: Label = %DateLabel
@onready var news_panel: PanelContainer = %NewsPanel
@onready var navigator_box: TextureButton = %navigatorBox
@onready var infos_box: TextureButton = %infosBox
@onready var shopping_box: TextureButton = %shoppingBox
@onready var dark_shop_box: TextureButton = %dark_shopBox
@onready var skills_box: TextureButton = %skillsBox

const ICON_BORDER_MEDIUM = preload("res://Game/Graphics/App_icons/Neos/icon_border_medium.png")
const ICON_BORDER_MEDIUM_PRESSED = preload("res://Game/Graphics/App_icons/Neos/icon_border_medium_pressed.png")

#Background textures
const BACKGROUND = preload("res://Game/Graphics/Background/background_vignette.png")
const ARGON = preload("res://Game/Graphics/Background/Crypte Argon/argon.png")
const FULL_CITY = preload("res://Game/Graphics/Background/FullCity/FullCity.png")
const GALERIES = preload("res://Game/Graphics/Background/Galeries/galeries_01.png")
const OPALINE = preload("res://Game/Graphics/Background/Opaline/opaline_from_valmont.png")
const PONT = preload("res://Game/Graphics/Background/Pont/pont.png")
const JAIL = preload("res://Game/Graphics/Background/Jail/jail_2.png")

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
	
	buttons_connexion()
	shop.item_bought.connect(learning._on_shop_item_bought)
	news_panel.show_infamy.connect(app_button_pressed.bind("infos"))
	TimeManager.s_date.connect(_on_s_date)
	

func buttons_connexion() -> void:
	infos_box.pressed.connect(app_button_pressed.bind("infos"))
	shopping_box.pressed.connect(app_button_pressed.bind("shopping"))
	navigator_box.pressed.connect(app_button_pressed.bind("learning"))
	dark_shop_box.pressed.connect(app_button_pressed.bind("dark_shop"))
	skills_box.pressed.connect(app_button_pressed.bind("skills"))
	

func init_interface():
	knowledge_resource.set_resource_box("BRAIN")
	gold_resource.set_resource_box("GOLD")
	sp_resource.set_resource_box("SP")
	
	knowledge_resource.refresh_value(int(Player.knowledge_point))
	gold_resource.refresh_value(int(Player.gold))
	sp_resource.refresh_value(int(Player.skill_point))
	_on_s_brain_clicked(0,0)

	self.hide()
	
func inits_shops():
	"""Fonction qui va init les shops pendant un chargement"""
	print_debug("Shops initialised")
	hack_shop.set_shop()
	shop.set_shop()
	
func app_button_pressed(button_name:String):
	var new_style_box = StyleBoxTexture.new()
	
	match button_name:
		"infos":
			infos.show()
			new_style_box.texture = FULL_CITY
		"shopping":
			shop.show()
			#new_style_box.texture = PONT
			new_style_box.texture = BACKGROUND
		"learning":
			learning.show()
			new_style_box.texture = BACKGROUND
		"dark_shop":
			hack_shop.show()
			#new_style_box.texture = GALERIES
			new_style_box.texture = BACKGROUND
		"skills":
			skills_tree.show()
			#new_style_box.texture = OPALINE
			new_style_box.texture = BACKGROUND
		"jail":
			jail.show()
			new_style_box.texture = JAIL
			jail.enter_jail()
	
	interface_panel.add_theme_stylebox_override("panel", new_style_box)

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
func _on_s_brain_clicked(knowledge, _brain_xp):
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


func _on_second_timer_timeout() -> void:
	_on_s_brain_clicked(0, 0)
	pass # Replace with function body.
	

func _on_s_date(array):
	# array[year, month, day, hour, minute]
	
	date_label.text = str(array[0]) +  " - " + str(array[1]) + " - " + str(array[2])
	
@onready var dark_shop_warning_icon: TextureRect = %DarkShopWarningIcon
func _on_s_wait_too_long(is_wainting):
	"""On reçoit le signal des hacl_buttons, indiquant qu'ils sont dispo pour le joueur"""
	if is_wainting:
		dark_shop_warning_icon.visible = true
	else:
		dark_shop_warning_icon.visible = false


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
	"""On reçoit un evennement"""
	cheat_event_spin_box.apply()
	var event_ui = EventsManager.create_event_ui()
	main_tab.add_child(event_ui)
	event_ui.event_ui_setup(cheat_event_spin_box.value)
	event_ui.s_event_finished.connect(_on_s_event_finished.bind(event_ui))
	pass # Replace with function body.

func _on_jail_button_pressed() -> void:
	app_button_pressed("jail")
	pass # Replace with function body.


func _on_s_event_finished(_event_ui):
	_event_ui.hide()
	_event_ui.queue_free()
	app_button_pressed("learning")

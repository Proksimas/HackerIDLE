extends Control

@onready var learning: Control = %Learning
@onready var hack_shop: Control = %HackShop
@onready var shop: Control = %Shop
@onready var main_tab: TabContainer = %MainTab
@onready var navigator: TextureRect = %Navigator
@onready var infos: Control = %Infos
@onready var jail: Control = %Jail
@onready var novanet: Control = %NovaNet


@onready var skills_tree: Control = %SkillsTree
@onready var second_timer: Timer = %SecondTimer
@onready var navgation_grid: HBoxContainer = %NavgationGrid
@onready var interface_panel: Panel = %InterfacePanel
#@onready var event_ui: Panel = %EventUI
#@onready var event_container: Container = %EventContainer

@onready var knowledge_resource: Control = %KnowledgeResource
@onready var gold_resource: Control = %GoldResource
@onready var cyber_force_resource: ResourceBox = %CyberForceResource

@onready var cheat_event_spin_box: SpinBox = %CheatEventSpinBox
@onready var cheat_events: HBoxContainer = %cheat_events

@onready var date_label: Label = %DateLabel
@onready var news_panel: PanelContainer = %NewsPanel
@onready var navigator_box: TextureButton = %navigatorBox
@onready var infos_box: TextureButton = %infosBox
@onready var shopping_box: TextureButton = %shoppingBox
@onready var dark_shop_box: TextureButton = %dark_shopBox
@onready var skills_box: TextureButton = %skillsBox
@onready var main_zone: VBoxContainer = %MainZone
@onready var more_button_box: TextureButton = %MoreButtonBox
@onready var more_button_container: VFlowContainer = %MoreButtonContainer
@onready var nova_net_box: TextureButton = %NovaNetBox

const ICON_BORDER_MEDIUM = preload("res://Game/Graphics/App_icons/Neos/icon_border_medium.png")
const ICON_BORDER_MEDIUM_PRESSED = preload("res://Game/Graphics/App_icons/Neos/icon_border_medium_pressed.png")
const ICON_BORDER_MEDIUM_GREEN = preload("res://Game/Graphics/App_icons/Neos/icon_border_medium_green.png")
#Background textures
const BACKGROUND = preload("res://Game/Graphics/Background/background_vignette.png")
const ARGON = preload("res://Game/Graphics/Background/Crypte Argon/argon.png")
const FULL_CITY = preload("res://Game/Graphics/Background/FullCity/FullCity.png")
const GALERIES = preload("res://Game/Graphics/Background/Galeries/galeries_01.png")
const OPALINE = preload("res://Game/Graphics/Background/Opaline/opaline_from_valmont.png")
const PONT = preload("res://Game/Graphics/Background/Pont/pont.png")
const JAIL = preload("res://Game/Graphics/Background/Jail/jail_2.png")
const NOVANET= preload("res://Game/Graphics/Background/Novanet/NovaNet_bg.png")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !OS.has_feature("editor"):
		cheat_events.hide()
		#cheat_events.show()
	
	main_tab.current_tab = 0
	connexions()
	init_interface()
	
func connexions() -> void:
	Player.s_earn_knowledge_point.connect(_on_earn_knowledge_point)
	Player.s_brain_clicked.connect(_on_s_brain_clicked)
	Player.s_earn_gold.connect(_on_earn_gold)
	#Player.s_earn_sp.connect(_on_earn_sp)
	Player.s_earn_brain_xp.connect(_on_earn_brain_xp)
	Player.s_earn_brain_level.connect(_on_earn_brain_level)
	Player.s_earn_cyber_force.connect(_on_earn_cyber_force)
	
	buttons_connexion()
	shop.item_bought.connect(learning._on_shop_item_bought)
	TimeManager.s_date.connect(_on_s_date)
	
	StatsManager.s_go_to_jail.connect(app_button_pressed.bind('jail'))
	

func buttons_connexion() -> void:
	infos_box.pressed.connect(app_button_pressed.bind("infos"))
	shopping_box.pressed.connect(app_button_pressed.bind("shopping"))
	navigator_box.pressed.connect(app_button_pressed.bind("learning"))
	dark_shop_box.pressed.connect(app_button_pressed.bind("dark_shop"))
	skills_box.pressed.connect(app_button_pressed.bind("skills"))
	nova_net_box.pressed.connect(app_button_pressed.bind("novanet"))

	more_button_box.pressed.connect(_on_more_button_box)

func init_interface():
	knowledge_resource.set_resource_box("BRAIN")
	gold_resource.set_resource_box("GOLD")
	knowledge_resource.refresh_value(int(Player.knowledge_point))
	gold_resource.refresh_value(int(Player.gold))
	more_button_container.hide()
	
	#sp_resource.set_resource_box("SP")
	#sp_resource.refresh_value(int(Player.skill_point))
	
	if Player.nb_of_rebirth > 0:
		cyber_force_resource.show()
		cyber_force_resource.set_resource_box("CF")
		cyber_force_resource.refresh_value(Player.cyber_force)
	else:cyber_force_resource.hide()
		
		
	_on_s_brain_clicked(0,0)

	self.hide()
	
func inits_shops():
	"""Fonction qui va init les shops pendant un chargement"""
	print_debug("Shops initialised")
	hack_shop._clear()
	hack_shop.set_shop()
	shop._clear()
	shop.set_shop()
	
func app_button_pressed(button_name:String):
	var new_style_box = StyleBoxTexture.new()
	
	match button_name:
		"infos":
			infos.show()
			new_style_box.texture = FULL_CITY
			infos.settings_panel.hide()
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
			if jail.is_in_jail:
				return
			jail.show()
			new_style_box.texture = JAIL
			jail.enter_jail()
		"novanet":
			novanet.show()
			new_style_box.texture = NOVANET
			
	interface_panel.add_theme_stylebox_override("panel", new_style_box)

func refresh_specially_resources():
	knowledge_resource.refresh_value(int(Player.knowledge_point))
	gold_resource.refresh_value(int(Player.gold))
	#sp_resource.refresh_value(int(Player.skill_point))
	cyber_force_resource.refresh_value(Player.cyber_force)
	

	
func _on_earn_knowledge_point(point):
	knowledge_resource.refresh_value(int(point))
	get_tree().call_group("g_hack_item_button", "knwoledge_refresh_hack_item")

func _on_earn_gold(point):
	gold_resource.refresh_value(int(point))
	get_tree().call_group("g_shop_item", "gold_refresh_shop_item")
	
#func _on_earn_sp(point):
	#sp_resource.refresh_value(int(point))
	
func _on_earn_brain_xp(_point):
	learning.refresh_brain_xp_bar()
func _on_earn_brain_level(point):
	learning.current_brain_level.text = tr("$Level") + " " + str(point) 
func _on_earn_cyber_force(point):
	cyber_force_resource.refresh_value(point)
	

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
	#learning.passives_knowledge = learning.get_all_passives_knowledge()
	var total = _sum_earning + shop.gain_learning_items
	
	learning.knowledge_per_second.text = Global.number_to_string(snapped(total, 0.1)) + " /s"
	#et_tree().create_timer(1.0).timeout.connect(_on_sum_timer)


func _on_second_timer_timeout() -> void:
	_on_s_brain_clicked(0, 0)
	pass # Replace with function body.
	

func _on_s_date(array):
	# array[year, month, day, hour, minute]
	date_label.text = str(array[0]) +  " - " + str(array[1]) + " - " + str(array[2])

	
	####### PROBA DE RENTRER EN PRISON #####
	var jail_proba = (StatsManager.get_jail_perc() * 100)
	if !jail_proba == 0 and jail.is_in_jail == false: 
		jail_proba = jail_proba / 31.0
		randomize()
		var rng = randf_range(0, 100)
		if jail_proba >  rng:
			StatsManager.s_go_to_jail.emit()
			#app_button_pressed("jail")
			
	##### PROBA DE BAISSER L INFAMY  

	var decrease_infamy = StatsManager.current_stat_calcul(StatsManager.TargetModifier.DECREASE_INFAMY,
											StatsManager.Stats.DECREASE_INFAMY)
	if decrease_infamy <= 0:
		return
	if StatsManager.infamy["current_value"] > 0:
		#comme on est par mois, on divise par 31
		decrease_infamy = decrease_infamy / 31
		StatsManager.add_infamy(0 - decrease_infamy)
	
@onready var dark_shop_warning_icon: TextureRect = %DarkShopWarningIcon
func _on_s_wait_too_long(is_wainting):
	"""On reçoit le signal des hacl_buttons, indiquant qu'ils sont dispo pour le joueur"""
	if is_wainting:
		dark_shop_warning_icon.visible = true
	else:
		dark_shop_warning_icon.visible = false

func _on_jail_button_pressed() -> void:
	StatsManager.s_go_to_jail.emit()
	#app_button_pressed("jail")
	pass # Replace with function body.

func _on_more_button_box():
	more_button_container.visible = !more_button_container.visible

func _on_finish_button_pressed() -> void:
	TimeManager.game_seconds += 70 * TimeManager.DAYS_PER_YEAR * TimeManager.SECONDS_PER_DAY
	pass # Replace with function body.



func _on_button_pressed() -> void:
	"""On reçoit un evennement"""
	if !OS.has_feature("editor"):
		push_error("Fonctionnalité non disponible en cheatMode")
		return
	cheat_event_spin_box.apply()

	EventsManager.create_event_ui(int(cheat_event_spin_box.value))

	pass # Replace with function body.


func _load_data(data):
	"""Manage les chargement dans l'interface"""
	# Met à jour l'UI
	init_interface()
	#sauvegarde au nivau du learning
	print("Chargement des learning item\n%s" % data["Player"]["learning_item_bought"] )
	learning._load_data(data["Player"]["learning_item_bought"])
	print("Chargement du hack shop")
	hack_shop._load_data(data["HackShop"])
	print("Chargement du news panel\n%s" % data["NewsPanel"])
	news_panel._load_data(data["NewsPanel"])
	infos._load_data(data["Infos"])
	novanet._load_data(data["NovaNetManager"])


func _on_more_button_container_draw() -> void:
	more_button_box.texture_normal = ICON_BORDER_MEDIUM_GREEN
	pass # Replace with function body.


func _on_more_button_container_hidden() -> void:
	more_button_box.texture_normal = ICON_BORDER_MEDIUM
	pass # Replace with function body.

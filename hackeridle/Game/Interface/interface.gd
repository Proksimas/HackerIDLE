extends Control


@onready var learning: Control = %Learning
@onready var hack_shop: Control = %HackShop
@onready var shop: Control = %Shop
@onready var main_tab: TabContainer = %MainTab
@onready var navigator: TextureButton = %Navigator
@onready var knowledge_label: Label = %KnowledgeLabel
@onready var gold_label: Label = %GoldLabel
@onready var skill_point_label: Label = %SkillPointLabel
@onready var settings: Control = %Settings
@onready var skills_tree: Control = %SkillsTree

var test ="bleu"
var a = 10

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	main_tab.current_tab = 0
	connexions()
	init_interface()
	
func connexions() -> void:
	Player.s_earn_knowledge_point.connect(_on_earn_knowledge_point)
	Player.s_earn_gold.connect(_on_earn_gold)
	Player.s_earn_sp.connect(_on_earn_sp)
	Player.s_earn_brain_xp.connect(_on_earn_brain_xp)
	Player.s_earn_brain_level.connect(_on_earn_brain_level)
	shop.item_bought.connect(learning._on_shop_item_bought)

func init_interface():
	knowledge_label.text = Global.number_to_string(Player.knowledge_point)
	gold_label.text =  Global.number_to_string(Player.gold)
	skill_point_label.text = Global.number_to_string((Player.skill_point))
	
	

func _on_shopping_pressed() -> void:
	shop.show()
	pass # Replace with function body.


func _on_navigator_pressed() -> void:
	learning.show()
	pass # Replace with function body.

func refresh_specially_resources():
	knowledge_label.text = Global.number_to_string(int(Player.knowledge_point))
	gold_label.text = Global.number_to_string(int(Player.gold))
	skill_point_label.text = Global.number_to_string(int(Player.skill_point))
	
func _on_earn_knowledge_point(point):
	knowledge_label.text = Global.number_to_string(int(point))
	get_tree().call_group("g_hack_item_button", "knwoledge_refresh_hack_item")

func _on_earn_gold(point):
	gold_label.text =  Global.number_to_string(int(point))
	get_tree().call_group("g_shop_item", "gold_refresh_shop_item")
	
func _on_earn_sp(point):
	skill_point_label.text = str(point)
	
func _on_earn_brain_xp(_point):
	learning.refresh_brain_xp_bar()
func _on_earn_brain_level(point):
	learning.current_brain_level.text = tr("$Level") + " " + str(point) 
	
func _on_dark_shop_pressed() -> void:
	hack_shop.show()
	pass # Replace with function body.


func _on_settings_button_pressed() -> void:
	settings.show()
	pass # Replace with function body.


func _on_skills_button_pressed() -> void:
	skills_tree.show()
	pass # Replace with function body.


func _load_data(data):
	"""Manage les chargement dans l'interface"""
	# Met à jour l'UI
	init_interface()
	#sauvegarde au nivau du learning
	learning._load_data(data["learning_item_bought"])

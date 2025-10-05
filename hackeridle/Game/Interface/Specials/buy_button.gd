extends Button

@onready var cost_label: Label = %CostLabel
@onready var item_price_label: Label = %ItemPriceLabel
@onready var price_container: HBoxContainer = %PriceContainer

const BRAIN_ICON = preload("res://Game/Interface/Icons/brain_icon.tscn")
const CYBER_FORCE_ICON = preload("res://Game/Interface/Icons/cyber_force_icon.tscn")
const GOLD_ICON = preload("res://Game/Interface/Icons/gold_icon.tscn")
const TROPHY_ICON = preload("res://Game/Interface/Icons/trophy_icon.tscn")

const YELLOW = Color(0.824, 0.651, 0.169)
const BRAIN_COLOR = Color(0.847, 0.431, 0.325) #d86e53
const WHITE  = Color(1, 1, 1)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func set_up_icon(_type: String):
	"""Utile pour initialiser l'icon"""
	var node
	match _type:
		"knowledge_point":
			node = BRAIN_ICON.instantiate()
		"gold":
			node = GOLD_ICON.instantiate()
		"cyber_force":
			node = CYBER_FORCE_ICON.instantiate()
		"skill_point":
			node = TROPHY_ICON.instantiate()
	price_container.add_child(node)
	
func refresh(item_price: float, _type: String):
	var color: Color
	var type_point
	match _type:
		"knowledge_point":
			type_point = Player.knowledge_point 
			color = BRAIN_COLOR
		"gold":
			type_point = Player.gold
			color = YELLOW
		"cyber_force":
			type_point = Player.cyber_force
			color = WHITE
		"skill_point":
			type_point = Player.skill_point
			color = WHITE
	item_price_label.add_theme_color_override("font_color", color)
	if type_point < item_price:
		to_disable()
	else:
		to_enable()

		
	# on tente de maj le prix ici
	
	cost_label.text = tr("$Upgr") + ". "
	#cost_hack_label.text = "+ " + str(_x_buy) + ": "
	item_price_label.text = Global.number_to_string(item_price)
	
func to_disable():
	self.disabled = true
	cost_label.add_theme_color_override("font_color", Color(1,0,0))
	self.get_child(0).modulate = Color(1, 1, 1, 0.5)

func to_enable():
	self.disabled = false
	cost_label.add_theme_color_override("font_color",Color(0, 1, 0.6))
	self.get_child(0).modulate = Color(1, 1, 1, 1)

func max_label():
	item_price_label.text = tr("Max")

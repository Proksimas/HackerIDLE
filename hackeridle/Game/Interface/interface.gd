extends Control


@onready var learning: Control = %Learning
@onready var hack: Control = %Hack
@onready var shop: Control = %Shop
@onready var main_tab: TabContainer = %MainTab
@onready var navigator: TextureButton = %Navigator
@onready var knowledge_label: Label = %KnowledgeLabel
@onready var gold_label: Label = %GoldLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Player.earn_knowledge_point.connect(_on_earn_knowledge_point)
	Player.earn_hacking_point.connect(_on_earn_hacking_point)
	Player.earn_gold.connect(_on_earn_gold)
	
	pass # Replace with function body.




func _on_shopping_pressed() -> void:
	shop.show()
	pass # Replace with function body.


func _on_navigator_pressed() -> void:
	learning.show()
	learning.set_learning_clicker()
	pass # Replace with function body.


func _on_earn_knowledge_point(point):
	knowledge_label.text = tr("Connaissance: %s" % [str(int(point))])

func _on_earn_hacking_point(point):
	return
	
func _on_earn_gold(point):
	gold_label.text = tr("Gold: %s" % [str(int(point))])
	

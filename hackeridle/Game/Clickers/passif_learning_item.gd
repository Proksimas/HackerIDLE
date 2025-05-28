extends VBoxContainer

class_name PassifLearningItem

@onready var passif_learning_texture: TextureRect = %PassifLearningTexture
@onready var passif_learning_level_label: Label = $PassifLearningLevelLabel
@onready var gain_learning_label: Label = %GainLearningLabel

var shop_item_cara_db: Dictionary
var gain_learning: float = 0.0


var time = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time += delta
	if gain_learning > 0 and time >= 1:
		Player.knowledge_point += gain_learning
		time = 0
	pass

func set_item(item_cara):
	shop_item_cara_db = item_cara
	passif_learning_texture.texture = load(shop_item_cara_db["texture_path"])
	passif_learning_level_label.text = "1"
	
	#pour préparer le gain
	var player_item = Player.learning_item_bought[item_cara["item_name"]]
	gain_learning = Calculs.passif_learning_gain(player_item)
	gain_learning_label.text = Global.number_to_string(gain_learning)# + " /s"

func set_refresh(item_cara):
	"""ici on refresh l'item, en donnant les carac de l'item ISSUES DE l INVENTAIRE 
	DU JOUEUR."item_cara"""
	var player_item = Player.learning_item_bought[item_cara["item_name"]]
	gain_learning = Calculs.passif_learning_gain(player_item)
	gain_learning_label.text = Global.number_to_string(gain_learning)# + " /sec"

	pass

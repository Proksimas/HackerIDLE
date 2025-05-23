extends Control


@onready var passif_clickers: HFlowContainer = %PassifClickers
@onready var clicker_arc: AspectRatioContainer = %ClickerARC
@onready var brain_xp_bar: ProgressBar = %BrainXpBar
@onready var current_brain_level: Label = %CurrentBrainLevel


#const LEARNING_CLICKER = preload("res://Game/Clickers/learning_clicker.tscn")
const CLICK_PARTICLES = preload("res://Game/Graphics/ParticlesAndShaders/click_particles.tscn")
const PASSIF_LEARNING_ITEM = preload("res://Game/Clickers/passif_learning_item.tscn")


var clicker_scale = Vector2(10,10)
var button_cliked: bool = false
var clicker_arc_original_size

func _ready() -> void:
	clicker_arc_original_size = clicker_arc.custom_minimum_size
	current_brain_level.text = str("1")
	
	

func refresh_brain_xp_bar():
	brain_xp_bar.min_value = 0
	brain_xp_bar.max_value = Player.brain_xp_next
	brain_xp_bar.value = Player.brain_xp
	

func _clear():
	for elmt in self.get_children():
		elmt.queue_free()

func _on_shop_item_bought(item_name):# <-Interface
	for child: PassifLearningItem in passif_clickers.get_children():
		if child.shop_item_cara_db["item_name"] == item_name:
			child.set_refresh(Player.learning_item_bought[item_name])
			return
			
	#si on est là, c'est que l'item n'est pas encore existant
	var new_passif_item = PASSIF_LEARNING_ITEM.instantiate()
	passif_clickers.add_child(new_passif_item)
	new_passif_item.set_item(LearningItemsDB.get_item_cara(item_name))


func _on_clicker_button_pressed() -> void:
	var click_particle = CLICK_PARTICLES.instantiate()
	get_tree().get_root().add_child(click_particle)
	click_particle.global_position = get_global_mouse_position()
	Player.brain_xp += 1
	Player.knowledge_point += 1 # A CHANGER
	
	
	button_cliked = true
	clicker_arc.custom_minimum_size = clicker_arc.custom_minimum_size + clicker_scale
	
func _process(delta: float) -> void:
	if button_cliked:
		var tween = get_tree().create_tween()
		tween.tween_property(clicker_arc, "custom_minimum_size", 
						clicker_arc_original_size, 1).from(clicker_arc.custom_minimum_size)
		button_cliked = false
		

func _load_data(content):
	# content = dictionnaire des learning_item_bought
	"""Doit instaurer tous les items passifs"""
	for passif_item in content:
		var new_passif_item = PASSIF_LEARNING_ITEM.instantiate()
		passif_clickers.add_child(new_passif_item)
		new_passif_item.set_item(LearningItemsDB.get_item_cara(passif_item))
	
	pass

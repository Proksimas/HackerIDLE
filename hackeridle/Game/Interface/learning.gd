extends Control


@onready var passif_clickers: HFlowContainer = %PassifClickers
@onready var clicker_arc: AspectRatioContainer = %ClickerARC


const LEARNING_CLICKER = preload("res://Game/Clickers/learning_clicker.tscn")
const CLICK_PARTICLES = preload("res://Game/Graphics/ParticlesAndShaders/click_particles.tscn")

var clicker_scale = Vector2(10,10)
var button_cliked: bool = false
var clicker_arc_original_size

func _ready() -> void:
	clicker_arc_original_size = clicker_arc.custom_minimum_size
	
func set_learning_clicker():
	return # obsolète donc return
	_clear()
	var new_lc = LEARNING_CLICKER.instantiate()
	self.add_child(new_lc)
	#On affiche l'item de learning le plus récent
	var last_item_name = Player.learning_item_bought.keys()[-1]
	var last_item = LearningItemsDB.get_item_cara(last_item_name)
	new_lc.set_learning_clicker(last_item)  #mettre les cara de l'ite
	
	new_lc.position = Vector2(self.size)  / 2
	
	
	pass


func _clear():
	for elmt in self.get_children():
		elmt.queue_free()


func _on_clicker_button_pressed() -> void:
	var click_particle = CLICK_PARTICLES.instantiate()
	self.add_child(click_particle)
	click_particle.global_position = get_global_mouse_position()
	Player.brain_level += 1
	Player.knowledge_point += 1 # A CHANGER
	
	button_cliked = true
	clicker_arc.custom_minimum_size = clicker_arc.custom_minimum_size + clicker_scale
	
	#var tween = get_tree().create_tween()
	#tween.tween_property(clicker_arc, "custom_minimum_size", 
						#clicker_arc.custom_minimum_size + clicker_scale, 1)
	##tween.set_parallel(true)
	
	
func _process(delta: float) -> void:
	if button_cliked:
		var tween = get_tree().create_tween()
		tween.tween_property(clicker_arc, "custom_minimum_size", 
						clicker_arc_original_size, 1).from(clicker_arc.custom_minimum_size)
		button_cliked = false
		

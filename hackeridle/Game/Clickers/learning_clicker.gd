extends StaticBody2D

@onready var learning_clicker_sprite: AnimatedSprite2D = %LearningClickerSprite


var current_item_cara: Dictionary
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	#TEST 
	set_learning_clicker(LearningItemsDB.get_item_cara("post-it"))
	Player.add_item(LearningItemsDB.get_item_cara("post-it"))
	#END TEST
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func set_learning_clicker(cara:Dictionary):
	current_item_cara = cara
	learning_clicker_sprite.sprite_frames = load(current_item_cara["animation_path"])
	
	pass

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			Player.knowledge_point += get_earn_kp()
			print(get_earn_kp())
			#ATTENTION le nomde l'animation doit être celui de l'item
			if learning_clicker_sprite.is_playing():
				learning_clicker_sprite.stop()
			
			learning_clicker_sprite.play(current_item_cara["item_name"])
			


func get_earn_kp() -> float:
	var gain: float
	for learning_item_name in Player.learning_item_bought:
		var level_item = Player.learning_item_bought[learning_item_name]["level"]
		var base_knowledge_point = Player.learning_item_bought[learning_item_name]["base_knowledge_point"]
		
		gain += level_item * base_knowledge_point
	
	return gain
	pass

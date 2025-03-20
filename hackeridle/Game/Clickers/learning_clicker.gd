extends StaticBody2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			Player.knowledge_point += get_earn_kp()



func get_earn_kp() -> float:
	var gain: float
	for learning_item_name in Player.learning_item_bought:
		var level_item = Player.learning_item_bought[learning_item_name]["level"]
		var knowledge_point_earned = Player.learning_item_bought[learning_item_name]["knowledge_point_earned"]
		gain += level_item * knowledge_point_earned
	
	return gain
	pass

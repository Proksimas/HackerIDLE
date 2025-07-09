extends StaticBody2D

@onready var learning_clicker_sprite: AnimatedSprite2D = %LearningClickerSprite
@onready var collider: CollisionShape2D = %Collider


var current_item_cara: Dictionary
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func set_learning_clicker(cara:Dictionary):
	current_item_cara = cara
	learning_clicker_sprite.sprite_frames = load(current_item_cara["animation_path"])
	
	pass

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			Player.earn_knowledge_point(get_earn_kp())

			#ATTENTION le nomde l'animation doit être celui de l'item
			if learning_clicker_sprite.is_playing():
				learning_clicker_sprite.stop()
			
			learning_clicker_sprite.play(current_item_cara["item_name"])
			


func get_earn_kp() -> float:
	var gain: float = 0.0
	for learning_item_name in Player.learning_item_bought:
		var level_item = Player.learning_item_bought[learning_item_name]["level"]
		var cost = Player.learning_item_bought[learning_item_name]["cost"]
		
		gain += level_item * cost
	
	return gain

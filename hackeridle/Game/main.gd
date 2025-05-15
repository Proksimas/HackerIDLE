extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().create_timer(0.1).timeout
	$Interface._on_navigator_pressed()
	
	Player.gold = 0
	Player.knowledge_point = 0
	pass # Replace with function body.

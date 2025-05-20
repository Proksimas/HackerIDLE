extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().create_timer(0.1).timeout
	$Interface._on_navigator_pressed()
	
	Player.gold = 10000
	Player.knowledge_point = 10000
	
	####### CHARGEMENT ###############
	Save.load_data()
	pass # Replace with function body.

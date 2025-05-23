extends Node


@export var force_new_game: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().create_timer(0.1).timeout
	
	if force_new_game or !Save.check_has_save():
		await new_game()

	else:
		####### CHARGEMENT ###############
		await Save.load_data()
		
	$Interface._on_navigator_pressed()
	pass # Replace with function body.

func new_game():
	Player.gold = 10000
	Player.knowledge_point = 10000
	Player.brain_level = 1
	Player.skill_point = 0
	Player.brain_xp = 0

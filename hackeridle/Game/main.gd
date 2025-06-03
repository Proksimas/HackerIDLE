extends Node


@export var force_new_game: bool = false
const INTERFACE = preload("res://Game/Interface/Interface.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !OS.has_feature("editor"):
		force_new_game = false
	
	if force_new_game or !Save.check_has_save():
		new_game()

	else:
		####### CHARGEMENT ###############
		self.call_thread_safe('load_interface')
		Save.call_thread_safe('load_data')
		OS.delay_msec(1000)
		
	$Interface._on_navigator_pressed()

	pass # Replace with function body.

func new_game():
	self.call_thread_safe("fill_player_stats")
	self.call_thread_safe('load_interface')

func load_interface():
	if self.has_node("Interface"):
		self.get_node('Interface').name = "OldInterface"
		self.get_node('OldInterface').queue_free()
	
	var interface = INTERFACE.instantiate()
	self.add_child(interface)
	return true

func fill_player_stats():
	if !OS.has_feature("editor"):
		Player.gold = 0
		Player.knowledge_point = 0
		Player.brain_level = 1
		Player.skill_point = 0
		Player.brain_xp = 0
	else:
		Player.gold = 100000
		Player.knowledge_point = 100000
		Player.brain_level = 1
		Player.skill_point = 0
		Player.brain_xp = 0
	OS.delay_msec(1000)
	

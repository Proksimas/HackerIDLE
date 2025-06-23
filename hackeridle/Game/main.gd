extends Node


@export var force_new_game: bool = false
const INTERFACE = preload("res://Game/Interface/Interface.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !OS.has_feature("editor"):
		force_new_game = false
	
	if force_new_game or !Save.check_has_save():
		self.call_thread_safe('new_game')

	else:
		####### CHARGEMENT ###############
		self.call_thread_safe('load_game')
		
	#$Interface._on_navigator_pressed()

	pass # Replace with function body.

func load_game():
	fill_player_stats()
	load_interface()
	OS.delay_msec(1000)
	Save.load_data()

func new_game():
	fill_player_stats()
	OS.delay_msec(1000)
	load_interface()

func load_interface():
	if self.has_node("Interface"):
		self.get_node('Interface').name = "OldInterface"
		self.get_node('OldInterface').queue_free()
	
	var interface = INTERFACE.instantiate()
	self.add_child(interface)
	return true

func fill_player_stats():
	"""On initialise les stats du joueur. OBLIGATOIRE """
	#tous les dictionnaires sont à mettre à vide
	for prop in Player.get_property_list():
		var p_name  : String = prop.name
		var usage : int    = int(prop.usage)
		var type : int = int(prop.type)
		if (usage == PROPERTY_USAGE_SCRIPT_VARIABLE and type == TYPE_DICTIONARY ):
			Player.set(p_name, {})
			
	HackingItemsDb.init_hacking_items_db()
	HackingItemsDb.init_for_player()
	LearningItemsDB.init_learning_items_db()
	LearningItemsDB.init_for_player()
	SourcesDb.init_sources_db()
	Player._init()
	StatsManager._init()
	
	#cas où l'on veut PAS tricher
	if !OS.has_feature("editor"):
		Player.gold = 0
		Player.knowledge_point = 0
		Player.brain_level = 1
		Player.skill_point = 0
		Player.brain_xp = 0
		
	else: # ICI POUR CHEAT 
		Player.gold = 0
		Player.knowledge_point = 0
		Player.brain_level = 1
		Player.skill_point = 42
		Player.brain_xp = 0
	

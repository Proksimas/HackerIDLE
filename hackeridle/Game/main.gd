extends Node


@export var force_new_game: bool = false
const INTERFACE = preload("res://Game/Interface/Interface.tscn")
const SCENARIO = preload("res://Game/Interface/Introduction/Scenario.tscn")
const TRANSLATION_KEYS = ["fr", "en"]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !OS.has_feature("editor"):
		force_new_game = false
	
	if force_new_game or !Save.check_has_save():
		self.call_thread_safe('new_game')

	else:
		####### CHARGEMENT ###############
		self.call_thread_safe('load_game')
		
	 # Récupère le code de la langue (par exemple, "en", "fr", "de")
	set_starting_language()

	pass # Replace with function body.
	
func set_starting_language():
	var user_locale:String = OS.get_locale()
	var splited = user_locale.get_slice("_", 0)
	if TRANSLATION_KEYS.has(splited):
		TranslationServer.set_locale(splited)
	else:
		TranslationServer.set_locale("en")
	

func load_game():
	fill_player_stats()
	var interface = load_interface()
	Save.s_data_loaded.connect(_on_s_data_loaded.bind(interface))
	Save.load_data()
	
func new_game():
	fill_player_stats()
	var interface = load_interface()
	call_deferred_thread_group("launch_introduction", interface)


func launch_introduction(interface):
	var introduction = SCENARIO.instantiate()
	introduction.count = 12 #nombre de phrases dans l'introduction
	introduction.key_prefix = "introduction_"
	self.add_child(introduction)
	introduction.s_scenario_finished.connect(_on_s_introduction_finished.bind(introduction))
	introduction.s_last_before_finished.connect(_on_s_last_before_finished.bind(interface))
	introduction.launch()
	
	

func load_interface():
	if self.has_node("Interface"):
		self.get_node('Interface').name = "OldInterface"
		self.get_node('OldInterface').queue_free()
	
	var interface = INTERFACE.instantiate()
	self.add_child(interface)
	
	return interface
	
	
func _on_s_last_before_finished(interface):
	"""Utilisé pour le jeu pdt l'intro"""
	interface.inits_shops()
	
func _on_s_introduction_finished(introduction_node):
	introduction_node.hide()
	self.get_node("Interface").show()
	TimeManager.reset()
	introduction_node.queue_free()

func _on_s_data_loaded(interface):
	#On doit voir comment éventuellement charger le jeu de manière asynchrone pdt
	# un chargement
	interface.show()
	#await get_tree().create_timer(0.01).timeout
	#interface.call_deferred("inits_shops")
	
	

func fill_player_stats():
	"""On initialise les stats du joueur. OBLIGATOIRE """
	#tous les dictionnaires sont à mettre à vide
	for prop in Player.get_property_list():
		var p_name  : String = prop.name
		var usage : int    = int(prop.usage)
		var type : int = int(prop.type)
		if (usage == PROPERTY_USAGE_SCRIPT_VARIABLE and type == TYPE_DICTIONARY ):
			Player.set(p_name, {})
	
	#cas où l'on veut PAS tricher
	if !OS.has_feature("editor"):
		Player.gold = 0
		Player.knowledge_point = 0
		Player.brain_level = 1
		Player.skill_point = 0
		Player.brain_xp = 0
		
	else: # ICI POUR CHEAT 
		Player.gold = 1000000000
		Player.knowledge_point = 100000000
		Player.brain_level = 1
		Player.skill_point = 42
		Player.brain_xp = 0
	
	#Initialisation de toutes les DB et singletons
	HackingItemsDb.init_hacking_items_db()
	HackingItemsDb.init_for_player()
	LearningItemsDB.init_learning_items_db()
	LearningItemsDB.init_for_player()
	SourcesDb.init_sources_db()
	Player._init()
	StatsManager._init()

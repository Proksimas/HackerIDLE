extends Node

@onready var scenarios_manager: Node = %ScenariosManager

@export var force_new_game: bool = false
@export var active_tutorial: bool = false
@export var has_full_stats: bool = true
const INTERFACE = preload("res://Game/Interface/Interface.tscn")

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
	set_starting_language() # le chargement prend ce qui est save
	fill_player_stats()
	var interface = load_interface()
	TutorialManager.reset_tutorial()
	scenarios_manager.call_deferred_thread_group("launch_introduction", interface)
	
	
func introduction_finished():
	"""L'introduction est terminée. L'interface a été chargée"""
	get_node("Interface").show()
	TimeManager.adjust_session_minutes()
	TimeManager.reset()
	if !OS.has_feature("editor") and Player.nb_of_rebirth == 0:
		TutorialManager.start_tutorial()
	elif active_tutorial:
		TutorialManager.start_tutorial()
	EventsManager.launch_timer() #On lance les events

func rebirth():
	"""on ne garde que:
		l'experience, niveau du cerveau, skills
		"""
	Player.nb_of_rebirth += 1
	

	var save_stats_for_rebirth = {"skills_owned": Player.skills_owned,
									"brain_xp": Player.brain_xp,
									"brain_level": Player.brain_level,
									"skill_point": Player.skill_point,
									"nb_of_rebirth": Player.nb_of_rebirth}
	
	fill_player_stats()
	Player.skills_owned = save_stats_for_rebirth["skills_owned"]
	Player.brain_xp = save_stats_for_rebirth["brain_xp"]
	Player.brain_level = save_stats_for_rebirth["brain_level"]
	Player.skill_point = save_stats_for_rebirth["skill_point"]
	Player.nb_of_rebirth = save_stats_for_rebirth["nb_of_rebirth"]
	var interface = load_interface()
	#var interface = get_tree().get_root().get_node("Main/Interface")
	scenarios_manager.call_deferred_thread_group("launch_introduction", interface)

	#On ajoute le nombre de rebirth à l'exp de maniere factorielle
	var exp = Global.factorial_iterative(Player.nb_of_rebirth + 1)
	StatsManager.add_modifier(StatsManager.TargetModifier.BRAIN_CLICK, StatsManager.Stats.BRAIN_XP, \
								StatsManager.ModifierType.BASE, exp, "rebirth")
	

	
	pass

func load_interface():
	if self.has_node("Interface"):
		self.get_node('Interface').name = "OldInterface"
		self.get_node('OldInterface').queue_free()
	
	var interface = INTERFACE.instantiate()
	self.add_child(interface)
	
	return interface
	

func _on_s_data_loaded(interface):
	#On doit voir comment éventuellement charger le jeu de manière asynchrone pdt
	# un chargement
	interface.show()
	interface.learning.refresh_brain_xp_bar()
	#await get_tree().create_timer(0.01).timeout
	#interface.call_deferred("inits_shops")
	

func fill_player_stats(_rebirthing: bool = false):
	"""On initialise les stats du joueur. OBLIGATOIRE """
	#tous les dictionnaires sont à mettre à vide
	for prop in Player.get_property_list():
		var p_name  : String = prop.name
		var usage : int    = int(prop.usage)
		var type : int = int(prop.type)
		if (usage == PROPERTY_USAGE_SCRIPT_VARIABLE and type == TYPE_DICTIONARY):
			Player.set(p_name, {})
	
	#cas où l'on veut PAS tricher
	if !OS.has_feature("editor"):
		Player.gold = 0
		Player.knowledge_point = 0
		Player.brain_level = 1
		Player.skill_point = 0
		Player.brain_xp = 0
		Player.nb_of_rebirth = 0
		
	else: # ICI POUR CHEAT 
		if has_full_stats:
			Player.gold = 100000000000
			Player.knowledge_point = 10000000000
			Player.brain_level = 1
			Player.skill_point = 42
			Player.brain_xp = 0
			Player.nb_of_rebirth = 0
		else:
			Player.gold = 1000
			Player.knowledge_point = 1000
			Player.brain_level = 1
			Player.skill_point = 4
			Player.brain_xp = 0
			Player.nb_of_rebirth = 0
			
	#Initialisation de toutes les DB et singletons
	HackingItemsDb.init_hacking_items_db()
	HackingItemsDb.init_for_player()
	LearningItemsDB.init_learning_items_db()
	LearningItemsDB.init_for_player()
	SourcesDb.init_sources_db()
	Player._init()
	StatsManager._init()
	EventsManager.events_initialisation()

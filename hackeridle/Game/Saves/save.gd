@tool
extends Node

var user_path = "user://"
var editor_path = "res://Game/Saves/Data/"
var save_file_name = "save.save"
# Called when the node enters the scene tree for the first time.
var singleton_to_save = [Player, StatsManager]

func _ready() -> void:
	var nodes_savable = get_tree().get_nodes_in_group("savable")
	print("Nodes à sauvergarder: ", nodes_savable)
	pass # Replace with function body.

func save_game():
	var content = {}
	for singleton in singleton_to_save:
		#print(singleton)
		#save_the_data(singleton._save_data())
		content[singleton.name] = singleton._save_data()
	
	save_the_data(content)
	
func save_the_data(content):
	var save_path = get_save_path()
	var file_path = save_path + save_file_name
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_var(content)
		file.close()
		print("✅ Sauvegarde réussie : %s" % file_path)
		#print("-> ", content)
	else:
		print("❌ Impossible d'ouvrir le fichier : %s" % file_path)

func load_data():
	var save_path = get_save_path()
	var file_path = save_path + save_file_name
	var f = FileAccess.open(file_path, FileAccess.READ)
	var data = f.get_var()
	f.close()
	
	player_load_data(data["Player"])
	stats_manager_load_data(data["StatsManager"])
	#CHargement au niveau de l'interface
	get_tree().get_root().get_node("Main/Interface")._load_data(data["Player"])
	#Maintenant des Stats
	
	pass

func player_load_data(content: Dictionary) -> void:
	"""Nous settons les variables du Player (gold, skill_point ...)"""
	# 1.  Parcourt les propriétés de l’INSTANCE, pas de la ressource script
	for prop in Player.get_property_list():
		var p_name  : String = prop.name
		var usage : int    = int(prop.usage)

		# 2.  On ne touche qu’aux variables déclarées dans le script,
		#     qui ne sont PAS en lecture seule, et qui existent dans le save.
		if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
			Player.set(p_name, content[p_name])
	print("Chargement:")
	print(content)
	#Il faut reassocier les compétences
	var skills_owned = content["skills_owned"]
	Player._init_skills_owned()
	for as_skill_data in skills_owned["active"]:
		SkillsManager.learn_as(as_skill_data["as_name"], as_skill_data)
		
	for ps_skill_data in skills_owned["passive"]:
		SkillsManager.learn_ps(ps_skill_data["ps_name"], ps_skill_data)
		
	#Je force le brain_xp pour actualiser la bar de prorgession
	Player.brain_xp = content["brain_xp"]

func stats_manager_load_data(content: Dictionary) -> void:
	for prop in StatsManager.get_property_list():
		var p_name  : String = prop.name
		var usage : int    = int(prop.usage)

		# 2.  On ne touche qu’aux variables déclarées dans le script,
		#     qui ne sont PAS en lecture seule, et qui existent dans le save.
		if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
			StatsManager.set(p_name, content[p_name])
	
func get_save_path():
	"""renvoie le path user ou editeur"""
	var save_path
	if OS.has_feature("editor"):save_path = editor_path 
	else: save_path = user_path
	return save_path
	
func check_has_save():
	var save_path = get_save_path()
	var file = FileAccess
	
	if file.file_exists(save_path + save_file_name): return true
	else: return false

func clean_save():
	var save_path = get_save_path()
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_var({})
	file.close()

	
func _notification(what):
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			print("Fermeture du jeu détectée ! Sauvegarde...")
			self.save_game()  # Ou ton code perso
		NOTIFICATION_APPLICATION_PAUSED:
			print("Application mise en pause. Utile pour téléphone")
			save_game()

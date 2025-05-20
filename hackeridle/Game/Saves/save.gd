@tool
extends Node

var user_path = "user://Saves/"
var editor_path = "res://Game/Saves/Data/"
var save_file_name = "data.dat"
# Called when the node enters the scene tree for the first time.
var singleton_to_save = [Player]

func _ready() -> void:
	var nodes_savable = get_tree().get_nodes_in_group("savable")
	print("Nodes à sauvergarder: ", nodes_savable)
	pass # Replace with function body.

func save_game():
	for singleton in singleton_to_save:
		save_the_data(singleton._save_data())
	
	
func save_the_data(content):
	var data = {}
	var save_path = get_save_path()
	var file_path = save_path + save_file_name
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_var(content)
		file.close()
		print("✅ Sauvegarde réussie : %s" % file_path)
		print("-> ", content)
	else:
		print("❌ Impossible d'ouvrir le fichier : %s" % file_path)

func load_data():
	var save_path = get_save_path()
	var file_path = save_path + save_file_name
	var f = FileAccess.open(file_path, FileAccess.READ)
	var data = f.get_var()
	f.close()
	await player_load_data(data)
	#CHargement au niveau de l'interface
	get_tree().get_root().get_node("Main/Interface")._load_data(data)
	pass

func player_load_data(content):
	Player.gold = content["gold"]
	Player.knowledge_point = content["knowledge_point"]
	Player.hacking_point = content["hacking_point"]
	Player.learning_item_bought = content["learning_item_bought"]
	Player.learning_item_statut = content["learning_item_statut"]
	Player.hacking_item_bought =content["hacking_item_bought"]
	Player.hacking_item_statut = content["hacking_item_statut"]
	pass
	
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
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("Fermeture du jeu détectée ! Sauvegarde...")
		self.save_game()  # Ou ton code perso

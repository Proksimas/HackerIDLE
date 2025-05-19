extends Node

var user_path = "user://Saves/"
var editor_path = "res://Game/Saves/Data/"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func save_game():
	save_the_data(Player._save_data())
	load_date()

func save_the_data(content):
	var data = {}
	var save_path
	if OS.has_feature("editor"):save_path = editor_path 
	else: save_path = user_path
	
	var file_path = save_path + "data.dat"
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_var(content)
		file.close()
		print("✅ Sauvegarde réussie : %s" % file_path)
	else:
		print("❌ Impossible d'ouvrir le fichier : %s" % file_path)

func load_date():
	var save_path
	if OS.has_feature("editor"):save_path = editor_path 
	else: save_path = user_path
	var file_path = save_path + "data.dat"
	var f = FileAccess.open(file_path, FileAccess.READ)
	var data = f.get_var()
	print(data)
	f.close()
	pass

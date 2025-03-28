extends Control

const LEARNING_CLICKER = preload("res://Game/Clickers/learning_clicker.tscn")



func set_learning_clicker():
	_clear()
	var new_lc = LEARNING_CLICKER.instantiate()
	self.add_child(new_lc)
	#On affiche l'item de learning le plus récent
	var last_item_name = Player.learning_item_bought.keys()[-1]
	var last_item = LearningItemsDB.get_item_cara(last_item_name)
	new_lc.set_learning_clicker(last_item)  #mettre les cara de l'ite
	pass

func resize_viewxport(clicker_size):
	pass


func _clear():
	for elmt in self.get_children():
		elmt.queue_free()

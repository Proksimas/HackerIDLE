extends Control


@onready var passif_clickers: HFlowContainer = %PassifClickers
@onready var clicker_arc: AspectRatioContainer = $VBoxContainer/CenterContainer/ClickerARC

const LEARNING_CLICKER = preload("res://Game/Clickers/learning_clicker.tscn")

func set_learning_clicker():
	return # obsolète donc return
	_clear()
	var new_lc = LEARNING_CLICKER.instantiate()
	self.add_child(new_lc)
	#On affiche l'item de learning le plus récent
	var last_item_name = Player.learning_item_bought.keys()[-1]
	var last_item = LearningItemsDB.get_item_cara(last_item_name)
	new_lc.set_learning_clicker(last_item)  #mettre les cara de l'ite
	
	new_lc.position = Vector2(self.size)  / 2
	
	
	pass


func _clear():
	for elmt in self.get_children():
		elmt.queue_free()


func _on_clicker_button_pressed() -> void:
	Player.brain_level += 1
	Player.knowledge_point += 1 # A CHANGER
	pass # Replace with function body.

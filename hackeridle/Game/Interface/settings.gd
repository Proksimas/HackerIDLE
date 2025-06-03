extends Control

@onready var new_game_button: Button = %NewGameButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _on_new_game_button_pressed() -> void:
	print(get_tree().get_root().get_node("main"))
	get_tree().get_root()
	pass # Replace with function body.

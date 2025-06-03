extends Control

@onready var new_game_button: Button = %NewGameButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _on_new_game_button_pressed() -> void:
	var main = get_tree().get_root().get_node("Main")
	main.call_thread_safe('new_game')
	pass # Replace with function body.

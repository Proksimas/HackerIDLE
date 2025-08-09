extends Panel

@onready var choice_a_button: Button = %ChoiceAButton
@onready var choice_a_name: Label = %ChoiceAName
@onready var choice_b_button: Button = %ChoiceBButton
@onready var choice_b_name: Label = %ChoiceBName

const BULLET_POINT = preload("res://Game/Interface/Specials/bullet_point.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	choice_a_button.pressed.connect(self._on_choice_pressed.bind("choice_a"))
	choice_b_button.pressed.connect(self._on_choice_pressed.bind("choice_b"))
	pass # Replace with function body.




func _on_choice_pressed(choice: String):
	""" choice = choice_a ou choice_b"""
	
	pass

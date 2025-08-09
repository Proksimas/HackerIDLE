extends Panel

@onready var choice_a_button: Button = %ChoiceAButton
@onready var choice_a_name: Label = %ChoiceAName
@onready var choice_b_button: Button = %ChoiceBButton
@onready var choice_b_name: Label = %ChoiceBName
@onready var name_of_event_label: Label = %NameOfEventLabel
@onready var event_description_label: RichTextLabel = %EventDescriptionLabel

const BULLET_POINT = preload("res://Game/Interface/Specials/bullet_point.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	choice_a_button.pressed.connect(self._on_choice_pressed.bind("choice_a"))
	choice_b_button.pressed.connect(self._on_choice_pressed.bind("choice_b"))
	event_ui_setup()
	pass # Replace with function body.


func event_ui_setup():
	var event:Event = EventsManager.get_random_event()
	name_of_event_label.text = tr(event.event_titre_id)
	event_description_label.text = tr(event.event_description_id)
	choice_a_name.text = tr(event.event_choice_1["texte_id"])
	choice_b_name.text = tr(event.event_choice_2["texte_id"])
	
func _on_choice_pressed(choice: String):
	""" choice = choice_a ou choice_b"""
	
	pass

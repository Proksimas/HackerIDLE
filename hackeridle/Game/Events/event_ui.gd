extends Panel

@onready var choice_a_button: Button = %ChoiceAButton
@onready var choice_a_name: Label = %ChoiceAName
@onready var choice_b_button: Button = %ChoiceBButton
@onready var choice_b_name: Label = %ChoiceBName
@onready var name_of_event_label: Label = %NameOfEventLabel
@onready var event_description_label: RichTextLabel = %EventDescriptionLabel
@onready var choice_a_container: VBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer/ChoiceAButton/ChoiceAContainer
@onready var choice_b_container: VBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer/ChoiceBButton/ChoiceBContainer

const BULLET_POINT = preload("res://Game/Interface/Specials/bullet_point.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	event_ui_setup()
	#Au bout de x seconde l'event se termine et un choix est fait au hasard
	get_tree().create_timer(20).timeout.connect(_on_timout)
	
	pass # Replace with function body.


func event_ui_setup():
	_clear_choices_container()
	var event:Event = EventsManager.get_random_event()
	name_of_event_label.text = tr(event.event_titre_id)
	event_description_label.text = tr(event.event_description_id)
	
	choice_a_name.text = tr(event.event_choice_1["texte_id"])
	for event_stat_name in event.event_choice_1["effects"]:
		var new_bullet = BULLET_POINT.instantiate()
		choice_a_container.add_child(new_bullet)
		var choice_text:String = tr("$" + event_stat_name) + ": "
		var value = event.event_choice_1["effects"][event_stat_name]
		if value < 0:
			choice_text += "- %s" % value
		else:
			choice_text += "+ %s" % value
		new_bullet.set_bullet_point(choice_text)
	choice_b_name.text = tr(event.event_choice_2["texte_id"])
	for event_stat_name in event.event_choice_2["effects"]:
		var new_bullet = BULLET_POINT.instantiate()
		choice_b_container.add_child(new_bullet)
		var choice_text:String = tr("$" + event_stat_name) + ": "
		var value = event.event_choice_2["effects"][event_stat_name]
		if value < 0:
			choice_text += "- %s" % value
		else:
			choice_text += "+ %s" % value
		new_bullet.set_bullet_point(choice_text)

	choice_a_button.pressed.connect(self._on_choice_pressed.bind("choice_a", event.event_choice_1["effects"]))
	choice_b_button.pressed.connect(self._on_choice_pressed.bind("choice_b", event.event_choice_2["effects"]))
	
func _on_choice_pressed(choice: String, modifiers: Dictionary):
	""" choice = choice_a ou choice_b"""
	if choice_a_button.pressed.is_connected(_on_choice_pressed):
		choice_a_button.pressed.disconnect(_on_choice_pressed)
	if choice_b_button.pressed.is_connected(_on_choice_pressed):
		choice_b_button.pressed.disconnect(_on_choice_pressed)
	#Apply les modifications, puis remove le bouton
	
	
	self.queue_free()
		
	pass

func _on_timout():
	""" On supprime l'event apres x secondes """
	var rand = randi_range(0, 1)
	if rand == 0:
		choice_a_button.pressed
	else:
		choice_b_button.pressed
	self.queue_free()
func _clear_choices_container():
	for elmt in choice_a_container.get_children():
		elmt.queue_free()
	for elmt2 in choice_b_container.get_children():
		elmt2.queue_free()

extends Panel

@onready var choice_a_button: Button = %ChoiceAButton
@onready var choice_a_name: Label = %ChoiceAName
@onready var choice_b_button: Button = %ChoiceBButton
@onready var choice_b_name: Label = %ChoiceBName
@onready var name_of_event_label: Label = %NameOfEventLabel
@onready var event_description_label: RichTextLabel = %EventDescriptionLabel
@onready var choice_b_container: VBoxContainer = %ChoiceBContainer
@onready var choice_a_container: VBoxContainer = %ChoiceAContainer

@export var event_during_time:int 
const BULLET_POINT = preload("res://Game/Interface/Specials/bullet_point.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# event_ui_setup() --> pour choisir un évenement
	#Au bout de x seconde l'event se termine et un choix est fait au hasard
	get_tree().create_timer(event_during_time).timeout.connect(_on_timout)
	get_tree().create_timer(2).timeout.connect(_on_disabled_button_timout)
	choice_a_button.disabled = true
	choice_b_button.disabled = true
	#Global.center(self)
	pass # Replace with function body.


func event_ui_setup(scenario_specific: int = -1):
	self.show()
	_clear_choices_container()
	var event:Event 
	if scenario_specific <= 0:
		event = EventsManager.get_random_event()
	else:
		event = EventsManager.get_specific_scenario(scenario_specific)
		
	name_of_event_label.text = tr(event.event_titre_id)
	event_description_label.text = tr(event.event_description_id)
	
	
	var choice_text: String
	choice_a_name.text = tr(event.event_choice_1["texte_id"])
	for event_stat_name in event.event_choice_1["effects"]:
		var new_bullet = BULLET_POINT.instantiate()
		choice_a_container.add_child(new_bullet)
		
		var value: float
		if event_stat_name == "perc_from_gold":
			#On doit mesurer lepercentage du total
			value = Player.gold * (1 + event.event_choice_1["effects"][event_stat_name])
			choice_text = tr("$gold") + ": "
		elif event_stat_name == "perc_from_knowledge":
			value = Player.knowledge_point * (1 + event.event_choice_1["effects"][event_stat_name])
			choice_text = tr("$knowledge") + ": "
		else:
			choice_text = tr("$" + event_stat_name) + ": "
			value = event.event_choice_1["effects"][event_stat_name]
			
		if value < 0:
			choice_text += "- %s" % Global.number_to_string(abs(value))
		else:
			choice_text += "+ %s" % Global.number_to_string(value)
		new_bullet.set_bullet_point(choice_text)
		
	if event.event_choice_1["effects"] == {}:
		choice_text = tr("$nothing")
		var new_bullet3 = BULLET_POINT.instantiate()
		choice_a_container.add_child(new_bullet3)
		new_bullet3.set_bullet_point(choice_text)
	

	choice_b_name.text = tr(event.event_choice_2["texte_id"])
	for event_stat_name in event.event_choice_2["effects"]:
		var new_bullet = BULLET_POINT.instantiate()
		choice_b_container.add_child(new_bullet)
		
		var value: float
		if event_stat_name == "perc_from_gold":
			#On doit mesurer lepercentage du total
			value = Player.gold * (1 + event.event_choice_2["effects"][event_stat_name])
			choice_text = tr("$gold") + ": "
		elif event_stat_name == "perc_from_knowledge":
			value = Player.knowledge_point * (1 + event.event_choice_2["effects"][event_stat_name])
			choice_text = tr("$knowledge") + ": "
		else:
			choice_text = tr("$" + event_stat_name) + ": "
			value = event.event_choice_2["effects"][event_stat_name]
		
		
		value = event.event_choice_2["effects"][event_stat_name]
		if value < 0:
			choice_text += "- %s" % value
		else:
			choice_text += "+ %s" % value
		new_bullet.set_bullet_point(choice_text)
		
	if event.event_choice_2["effects"] == {}:
		choice_text = tr("$nothing")
		var new_bullet2 = BULLET_POINT.instantiate()
		choice_b_container.add_child(new_bullet2)
		new_bullet2.set_bullet_point(choice_text)
		
	choice_a_button.pressed.connect(self._on_choice_pressed.bind("choice_a", event.event_choice_1["effects"], event.event_id))
	choice_b_button.pressed.connect(self._on_choice_pressed.bind("choice_b", event.event_choice_2["effects"], event.event_id))
	
func _on_choice_pressed(_choice: String, _modifiers: Dictionary, event_id):
	""" choice = choice_a ou choice_b"""
	if choice_a_button.pressed.is_connected(_on_choice_pressed):
		choice_a_button.pressed.disconnect(_on_choice_pressed)
	if choice_b_button.pressed.is_connected(_on_choice_pressed):
		choice_b_button.pressed.disconnect(_on_choice_pressed)
	#Apply les modifications, puis remove le bouton
	# TODO
	for stat_name in _modifiers:
		match stat_name:
			"infamy":
				StatsManager.add_infamy(_modifiers["infamy"])
			"xp_click_flat": 
				StatsManager.add_modifier(StatsManager.TargetModifier.BRAIN_CLICK,
										StatsManager.Stats.BRAIN_XP,
										StatsManager.ModifierType.FLAT,
										_modifiers[stat_name],
										"event_{id}".format({"id":event_id }))
										
			"perc_from_gold":
				var value = Player.gold * (1 + _modifiers[stat_name])
				Player.earn_gold(value)
				
			"perc_from_knowledge":
				var value = Player.knowledge_point * (1 + _modifiers[stat_name])
				Player.earn_knowledge_point(value)
	
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
	
func _on_disabled_button_timout():
	choice_a_button.disabled = false
	choice_b_button.disabled = false
	
func _clear_choices_container():
	for elmt in choice_a_container.get_children():
		elmt.queue_free()
	for elmt2 in choice_b_container.get_children():
		elmt2.queue_free()

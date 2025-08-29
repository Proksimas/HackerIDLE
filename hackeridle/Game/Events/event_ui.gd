extends Panel

@onready var choice_a_button: Button = %ChoiceAButton
@onready var choice_a_name: Label = %ChoiceAName
@onready var choice_b_button: Button = %ChoiceBButton
@onready var choice_b_name: Label = %ChoiceBName
@onready var name_of_event_label: Label = %NameOfEventLabel
@onready var event_description_label: RichTextLabel = %EventDescriptionLabel
@onready var choice_b_container: VBoxContainer = %ChoiceBContainer
@onready var choice_a_container: VBoxContainer = %ChoiceAContainer
@onready var time_progress_bar: ProgressBar = %TimeProgressBar

@export var event_during_time:int 
const BULLET_POINT = preload("res://Game/Interface/Specials/bullet_point.tscn")

var time_process: float = 0

signal s_event_finished()
func _ready() -> void:
	# event_ui_setup() --> pour choisir un évenement
	#Au bout de x seconde l'event se termine et un choix est fait au hasard
	get_tree().create_timer(event_during_time).timeout.connect(_on_timout)
	time_progress_bar.max_value = event_during_time
	time_progress_bar.min_value = 0
	time_progress_bar.value = event_during_time
	get_tree().create_timer(2).timeout.connect(_on_disabled_button_timout)
	choice_a_button.disabled = true
	choice_b_button.disabled = true
	#Global.center(self)
	pass # Replace with function body.

func _process(delta: float) -> void:
	time_process += delta
	time_progress_bar.value = event_during_time - time_process

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
	var choices_name_lst = [choice_a_name, choice_b_name]
	var choices_id = [event.event_choice_1, event.event_choice_2]
	var choices_container =[choice_a_container, choice_b_container]
	var choices_buttons = [choice_a_button, choice_b_button]
	var choices_str = ["choix_a", "choix_b"]
	
	var choice_text: String
	var index = 0
	for choice_name in choices_name_lst:
		choice_name.text = tr(choices_id[index]["texte_id"])

		if choices_id[index]["effects"] == {}:
			choice_text = tr("$nothing")
			var new_bullet3 = BULLET_POINT.instantiate()
			choices_container[index].add_child(new_bullet3)
			new_bullet3.set_bullet_point(choice_text)
		
		else:
			for event_effect_name:String in choices_id[index]["effects"]:
				var new_bullet = BULLET_POINT.instantiate()
				choices_container[index].add_child(new_bullet)
				var effect_value = choices_id[index]["effects"][event_effect_name]
				var is_perc: bool = false
				if event_effect_name.ends_with("_perc"):
					is_perc = true
				var value: float
				
				# ATTENTION Ne pas oublier de changer au niveau du click du boutton
				# pour les gains
				if event_effect_name == "perc_from_gold":
					#On doit mesurer lepercentage du total
					value = Calculs.get_tot_gold() * effect_value
					choice_text = tr("$gold") + ": "
				elif event_effect_name == "perc_from_knowledge":
					value = Calculs.get_tot_knowledge() * effect_value
					choice_text = tr("$knowledge") + ": "
				elif event_effect_name == "perc_from_brain_xp":
					#donne x% de l'exp qu'il faut pouir le prochain level
					value = Player.brain_xp_next * effect_value
					choice_text = tr("$brain_xp") + ": "
					
				else:
					value = effect_value
					if is_perc:
						value *= 100
					choice_text = tr("$" + event_effect_name) + ": "
		
				if effect_value < 0:
					choice_text += "- %s" % Global.number_to_string(abs(value))
				else:
					choice_text += "+ %s" % Global.number_to_string(value)
				
				if is_perc:
					choice_text += " %"
				new_bullet.set_bullet_point(choice_text)
		
		choices_buttons[index].pressed.connect(self._on_choice_pressed.bind(
			choices_str[index], choices_id[index]["effects"], choices_id[index]["texte_id"]))
		index += 1
	
	return
func _on_choice_pressed(_choice: String, _modifiers: Dictionary, event_id):
	""" choice = choice_a ou choice_b"""

	if choice_a_button.pressed.is_connected(_on_choice_pressed):
		choice_a_button.pressed.disconnect(_on_choice_pressed)
	if choice_b_button.pressed.is_connected(_on_choice_pressed):
		choice_b_button.pressed.disconnect(_on_choice_pressed)
		
	apply_modifiers(_modifiers, event_id)
	s_event_finished.emit()
	#self.queue_free()
		

func apply_modifiers(_modifiers: Dictionary, event_id):
	"""On aplpique les modificateurs et ajoute les différentes Stats
	perc_from_stat: donne un gain à cette stat, selon % total de cette stat
	"""
	# TODO
	
	# ATTENTION Ne pas oublier de changer au niveau de l'affichage de l'ui 
	for stat_name in _modifiers:
		match stat_name:
			"infamy":
				StatsManager.add_infamy(_modifiers["infamy"])
				
			"xp_click_flat": 
				StatsManager.add_modifier(StatsManager.TargetModifier.BRAIN_CLICK,
										StatsManager.Stats.BRAIN_XP,
										StatsManager.ModifierType.FLAT,
										_modifiers[stat_name],
										event_id)
			"xp_click_perc":
				StatsManager.add_modifier(StatsManager.TargetModifier.BRAIN_CLICK,
										StatsManager.Stats.BRAIN_XP,
										StatsManager.ModifierType.PERCENTAGE,
										_modifiers[stat_name],
										event_id)
										
			"knowledge_click_bonus":
				StatsManager.add_modifier(StatsManager.TargetModifier.BRAIN_CLICK,
										StatsManager.Stats.KNOWLEDGE,
										StatsManager.ModifierType.BASE,
										_modifiers[stat_name],
										event_id)
			"knowledge_click_perc":
				StatsManager.add_modifier(StatsManager.TargetModifier.BRAIN_CLICK,
										StatsManager.Stats.KNOWLEDGE,
										StatsManager.ModifierType.PERCENTAGE,
										_modifiers[stat_name],
										event_id)
			"hack_time_perc":
				StatsManager.add_modifier(StatsManager.TargetModifier.HACK,
										StatsManager.Stats.TIME,
										StatsManager.ModifierType.PERCENTAGE, 
										_modifiers[stat_name], 
										event_id)
			"hack_gold_perc":
				StatsManager.add_modifier(StatsManager.TargetModifier.HACK,
										StatsManager.Stats.GOLD,
										StatsManager.ModifierType.PERCENTAGE, 
										_modifiers[stat_name], 
										event_id)
				
				
			"perc_from_gold":
				var value = Calculs.get_tot_gold() * _modifiers[stat_name]
				Player.earn_gold(value)
			"perc_from_knowledge":
				var value = Calculs.get_tot_knowledge() * _modifiers[stat_name]
				Player.earn_knowledge_point(value)
			"perc_from_brain_xp":
				var value = Player.brain_xp_next * _modifiers[stat_name]
				Player.earn_brain_xp(value)
				
			
	
	#print(StatsManager._show_stats_modifiers(StatsManager.Stats.BRAIN_XP))

func _on_timout():
	""" On supprime l'event apres x secondes """
	var rand = randi_range(0, 1)
	if rand == 0:
		choice_a_button.pressed.emit()
	else:
		choice_b_button.pressed.emit()
	s_event_finished.emit()
	#self.queue_free()
	
func _on_disabled_button_timout():
	choice_a_button.disabled = false
	choice_b_button.disabled = false
	
func _clear_choices_container():
	for elmt in choice_a_container.get_children():
		elmt.queue_free()
	for elmt2 in choice_b_container.get_children():
		elmt2.queue_free()

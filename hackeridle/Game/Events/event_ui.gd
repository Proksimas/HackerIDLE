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
@onready var confirm_button: Button = %ConfirmButton

@export var event_during_time:int 
const BULLET_POINT = preload("res://Game/Interface/Specials/bullet_point.tscn")

const ARGON = preload("res://Game/Graphics/Background/Crypte Argon/argon.png")
const GALERIES = preload("res://Game/Graphics/Background/Galeries/galeries_01.png")
const OPALINE_FROM_VALMONT = preload("res://Game/Graphics/Background/Opaline/opaline_from_valmont.png")
const PONT = preload("res://Game/Graphics/Background/Pont/pont.png")
const VALMONT = preload("res://Game/Graphics/Background/Valmont/valmont_1.png")

var background_texture = [ARGON, GALERIES, OPALINE_FROM_VALMONT, PONT, VALMONT]
var choices_modifiers = []
var choice_selected: String
var time_process: float = 0

signal s_event_finished()
func _ready() -> void:
	# event_ui_setup() --> pour choisir un évenement
	#Au bout de x seconde l'event se termine et un choix est fait au hasard
	
	time_progress_bar.max_value = event_during_time
	time_progress_bar.min_value = 0
	time_progress_bar.value = event_during_time
	#get_tree().create_timer(2).timeout.connect(_on_disabled_button_timout)
	#choice_a_button.disabled = true
	#choice_b_button.disabled = true
	choice_a_button.disabled = false
	choice_b_button.disabled = false
	confirm_button.disabled = true
	choice_a_button.pressed.connect(_on_choice_pressed.bind("choice_a"))
	choice_b_button.pressed.connect(_on_choice_pressed.bind("choice_b"))
	#POur la progress_bar
	#get_tree().create_timer(event_during_time).timeout.connect(_on_timout)
	#Global.center(self)
	pass # Replace with function body.

#func _process(delta: float) -> void:
	#time_process += delta
	#time_progress_bar.value = event_during_time - time_process
	#
	
func event_ui_setup(scenario_specific: int = -1):
	apply_background()
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
	var _choices_buttons = [choice_a_button, choice_b_button]
	var choices_str = ["choice_a", "choice_b"]
	
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
		
				value = floor(value)
				
				if value == 0:
					continue
				elif effect_value < 0:
					choice_text += Global.number_to_string(value)
				else:
					choice_text += Global.number_to_string(value)
				
				if is_perc:
					choice_text += " %"
					
				var new_bullet = BULLET_POINT.instantiate()
				choices_container[index].add_child(new_bullet)
				
			
				if EventsManager.malus_effects.has(event_effect_name):
					new_bullet.set_bullet_point(choice_text, false, 150, true)
					
				else:
					new_bullet.set_bullet_point(choice_text)
		
		choices_modifiers.append({"choice_name": choices_str[index],
									"effects": choices_id[index]["effects"],
									"choice_id": choices_id[index]["texte_id"]})
		index += 1
		
	#On met le jeu en pause
	get_tree().paused = true
	
	
func apply_background():
	
	var stylebox = StyleBoxTexture.new()
	var rnd = randi_range(0, len(background_texture) -1)
	stylebox.texture = background_texture[rnd]

	self.add_theme_stylebox_override("panel", stylebox)
	
func _on_choice_pressed(_choice: String): #_choice: String, _modifiers: Dictionary, event_id):
	""" choice = choice_a ou choice_b"""

	choice_selected = _choice
	confirm_button.enable()
	
func _on_confirm_button_s_pressed():
	if choice_selected == "choice_a":
		apply_modifiers(choices_modifiers[0]["effects"], choices_modifiers[0]["choice_id"])
	elif choice_selected == "choice_b":
		apply_modifiers(choices_modifiers[1]["effects"], choices_modifiers[1]["choice_id"])
	else:
		push_error("Probleme dans les choix")
		
	var interface = Global.get_interface()
	if !interface.jail.is_in_jail:
		get_tree().paused = false
	else:
		interface.app_button_pressed('jail')
	s_event_finished.emit() 
		

func apply_modifiers(_modifiers: Dictionary, event_id):
	"""On aplpique les modificateurs et ajoute les différentes Stats
	perc_from_stat: donne un gain à cette stat, selon % total de cette stat
	"""
	# TODO
	
	# ATTENTION Ne pas oublier de changer au niveau de l'affichage de l'ui 
	# ATTENTION Tous les _modifiers correspondent aux effetcs dans Event.gd
	for stat_name in _modifiers:
		match stat_name:
			"infamy":
				StatsManager.add_infamy(_modifiers["infamy"])
				
			"xp_click_base": 
				StatsManager.add_modifier(StatsManager.TargetModifier.BRAIN_CLICK,
										StatsManager.Stats.BRAIN_XP,
										StatsManager.ModifierType.BASE,
										_modifiers[stat_name],
										event_id)
			"xp_click_perc":
				StatsManager.add_modifier(StatsManager.TargetModifier.BRAIN_CLICK,
										StatsManager.Stats.BRAIN_XP,
										StatsManager.ModifierType.PERCENTAGE,
										_modifiers[stat_name],
										event_id)
										
			"knowledge_click_base":
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
			"hack_cost_perc":
				StatsManager.add_modifier(StatsManager.TargetModifier.HACK,
										StatsManager.Stats.COST,
										StatsManager.ModifierType.PERCENTAGE, 
										_modifiers[stat_name], 
										event_id)
			"learning_items_cost_perc":
				StatsManager.add_modifier(StatsManager.TargetModifier.LEARNING_ITEM,
										StatsManager.Stats.COST,
										StatsManager.ModifierType.PERCENTAGE, 
										_modifiers[stat_name], 
										event_id)
			"learning_items_knowledge_perc":
				StatsManager.add_modifier(StatsManager.TargetModifier.LEARNING_ITEM,
										StatsManager.Stats.KNOWLEDGE,
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
	var interface = Global.get_interface()
	if !interface.jail.is_in_jail:
		get_tree().paused = false
	else:
		interface.app_button_pressed('jail')
	s_event_finished.emit()
	
	
func _on_disabled_button_timout():
	choice_a_button.disabled = false
	choice_b_button.disabled = false
	
func _clear_choices_container():
	for elmt in choice_a_container.get_children():
		elmt.queue_free()
	for elmt2 in choice_b_container.get_children():
		elmt2.queue_free()

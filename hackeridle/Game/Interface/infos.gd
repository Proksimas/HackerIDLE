extends Control

@onready var new_game_button: Button = %NewGameButton
@onready var infamy_value: Label = %InfamyValue
@onready var infamy_stats: Panel = %InfamyStats
@onready var infamy_effects: GridContainer = %InfamyEffects
@onready var treshold_name_label: Label = %TresholdNameLabel
@onready var treshold_infamy_label: Label = %TresholdInfamyLabel
@onready var settings_button: Button = %SettingsButton
@onready var settings_panel: Panel = %SettingsPanel
@onready var country_container: HBoxContainer = %CountryContainer
@onready var modificators_label: Label = %ModificatorsLabel
@onready var modifiers_container: VBoxContainer = $MarginContainer/ModifiersContainer



@onready var safe_zone_label: Label = %SafeZoneLabel
@onready var safe_zone_check_box: CheckButton = %SafeZoneCheckBox

const BULLET_POINT = preload("res://Game/Interface/Specials/bullet_point.tscn")



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#match_performance_profile(get_performance_profile()) 
	
	settings_panel.hide()
	StatsManager.s_add_infamy.connect(_on_s_add_infamy)
	StatsManager.s_infamy_effect_added.connect(draw_infamy_stats)

	_on_s_add_infamy(StatsManager.infamy["current_value"])
	
	for country in country_container.get_children():
		country.pressed.connect(_on_language_button_pressed.bind(country.name))

	pass # Replace with function body.

func draw_infamy_stats():
	_on_s_add_infamy(StatsManager.infamy["current_value"])
	for effect in infamy_effects.get_children():
		effect.queue_free()
	
	treshold_infamy_label.text = tr("$infamy")
	treshold_name_label.text = tr("$" + StatsManager.INFAMY_NAMES.get(StatsManager.get_infamy_treshold()))
	var _hack_modifiers = StatsManager.hack_modifiers
	var _translations: Array = []
	
	for stat: StatsManager.Stats in _hack_modifiers:
		if _hack_modifiers[stat].is_empty():
			continue
		
		var hack_dicts = _hack_modifiers[stat]
		var value: float
		var has_value: bool = false
		for dict in hack_dicts:
			if dict["source"].begins_with("infamy_"):
				value = dict["value"] * 100
				has_value = true
		
		if not has_value:
			#la valeur n'est pas utile pour le seuil d'infamy
			
			continue
		
		var value_str: String
		if value > 0:
			value_str = "%s" % str(value)
		elif value < 0:
			value_str = "%s" % str(value)
		else:
			value_str = ""
		

		_translations.append([stat,tr("hack_" + StatsManager.STATS_NAMES.get(stat)).format({"hack_" + StatsManager.STATS_NAMES.get(stat) + "_value": value_str})])
	
	for trad in _translations:
		var bullet_label = BULLET_POINT.instantiate()
		infamy_effects.add_child(bullet_label)
		if trad[0] == StatsManager.Stats.TIME or trad[0] == StatsManager.Stats.COST or\
		trad[0] == StatsManager.Stats.JAIL:
			bullet_label.set_bullet_point(trad[1], false, 150, true)
				
		else:
			bullet_label.set_bullet_point(trad[1])
		
@onready var brain_xp_title: Label = %BrainXpTitle
@onready var brain_title: Label = %BrainTitle
@onready var brain_knowledge_title: Label = %BrainKnowledgeTitle
@onready var hack_title: Label = %HackTitle
@onready var hack_time_label: Label = %HackTimeLabel
@onready var hack_gold_label: Label = %HackGoldLabel
@onready var hack_cost_label: Label = %HackCostLabel
@onready var learning_item_title: Label = %LearningItemTitle
@onready var learning_item_cost_label: Label = %LearningItemCostLabel
@onready var learning_item_knowledge_label: Label = %LearningItemKnowledgeLabel
var brain_bullets_container: VBoxContainer
var hack_bullets_container: VBoxContainer
var learning_bullets_container: VBoxContainer

func draw_modififiers():
	_ensure_modifiers_bullets_containers()
	_clear_modifiers_bullets()

	# BRAIN
	brain_title.show()
	brain_title.text = tr("$Brain")
	var xp_cara = StatsManager.get_modifier_type_by_stats(
		StatsManager.TargetModifier.BRAIN_CLICK, StatsManager.Stats.BRAIN_XP
	)
	var xp_text = tr("$Xp_per_click") + ": " + Global.number_to_string(
		StatsManager.current_stat_calcul(StatsManager.TargetModifier.BRAIN_CLICK, StatsManager.Stats.BRAIN_XP), 0.1
	) + "  <---  ( " + Global.number_to_string(xp_cara["base"]) + " + " + \
		Global.number_to_string(xp_cara["perc"]) + "% ) + " + Global.number_to_string(xp_cara["flat"])
	_add_modifier_bullet(brain_bullets_container, xp_text, false)

	var knowledge_cara = StatsManager.get_modifier_type_by_stats(
		StatsManager.TargetModifier.BRAIN_CLICK, StatsManager.Stats.KNOWLEDGE
	)
	var knowledge_text = tr("$knowledge_click_perc") + ": " + Global.number_to_string(
		StatsManager.current_stat_calcul(StatsManager.TargetModifier.BRAIN_CLICK, StatsManager.Stats.KNOWLEDGE), 0.1
	) + "  <---  ( " + Global.number_to_string(knowledge_cara["base"]) + " + " + \
		Global.number_to_string(knowledge_cara["perc"]) + "% ) + " + Global.number_to_string(knowledge_cara["flat"])
	_add_modifier_bullet(brain_bullets_container, knowledge_text, false)

	# HACK
	hack_title.show()
	hack_title.text = tr("$Hack")
	var hack_time_cara = StatsManager.get_modifier_type_by_stats(
		StatsManager.TargetModifier.HACK, StatsManager.Stats.TIME
	)
	_add_modifier_bullet(
		hack_bullets_container,
		tr("$hack_time_perc") + ": " + Global.number_to_string(hack_time_cara["perc"]) + " %",
		true
	)

	var hack_gold_cara = StatsManager.get_modifier_type_by_stats(
		StatsManager.TargetModifier.HACK, StatsManager.Stats.GOLD
	)
	_add_modifier_bullet(
		hack_bullets_container,
		tr("$hack_gold_perc") + ": " + Global.number_to_string(hack_gold_cara["perc"]) + " %",
		false
	)

	var hack_cost_cara = StatsManager.get_modifier_type_by_stats(
		StatsManager.TargetModifier.HACK, StatsManager.Stats.COST
	)
	_add_modifier_bullet(
		hack_bullets_container,
		tr("$hack_cost_perc") + ": " + Global.number_to_string(hack_cost_cara["perc"]) + " %",
		true
	)

	# LEARNING ITEMS
	learning_item_title.show()
	learning_item_title.text = tr("$LearningItems")
	var learning_items_cost_cara = StatsManager.get_modifier_type_by_stats(
		StatsManager.TargetModifier.LEARNING_ITEM, StatsManager.Stats.COST
	)
	_add_modifier_bullet(
		learning_bullets_container,
		tr("$learning_items_cost_perc") + ": " + Global.number_to_string(learning_items_cost_cara["perc"]) + " %",
		true
	)

	var learning_items_knowledge_cara = StatsManager.get_modifier_type_by_stats(
		StatsManager.TargetModifier.LEARNING_ITEM, StatsManager.Stats.KNOWLEDGE
	)
	_add_modifier_bullet(
		learning_bullets_container,
		tr("$short_learning_items_knowledge_perc") + ": " + Global.number_to_string(learning_items_knowledge_cara["perc"]) + " %",
		false
	)


func _ensure_modifiers_bullets_containers() -> void:
	if brain_bullets_container != null and is_instance_valid(brain_bullets_container) \
		and hack_bullets_container != null and is_instance_valid(hack_bullets_container) \
		and learning_bullets_container != null and is_instance_valid(learning_bullets_container):
		return

	brain_bullets_container = _get_or_create_section_container("BrainBullets")
	hack_bullets_container = _get_or_create_section_container("HackBullets")
	learning_bullets_container = _get_or_create_section_container("LearningBullets")

	modifiers_container.move_child(brain_bullets_container, brain_title.get_index() + 1)
	modifiers_container.move_child(hack_bullets_container, hack_title.get_index() + 1)
	modifiers_container.move_child(learning_bullets_container, learning_item_title.get_index() + 1)

	var old_nodes: Array[Node] = [
		brain_title, brain_xp_title, brain_knowledge_title,
		hack_title, hack_time_label, hack_gold_label, hack_cost_label,
		learning_item_title, learning_item_cost_label, learning_item_knowledge_label
	]
	for node in old_nodes:
		if node != null:
			node.hide()


func _clear_modifiers_bullets() -> void:
	for child in brain_bullets_container.get_children():
		child.queue_free()
	for child in hack_bullets_container.get_children():
		child.queue_free()
	for child in learning_bullets_container.get_children():
		child.queue_free()

func _add_modifier_bullet(target_container: VBoxContainer, text_value: String, inverse_color: bool) -> void:
	var bullet_label = BULLET_POINT.instantiate()
	target_container.add_child(bullet_label)
	bullet_label.set_bullet_point(text_value, false, 150, inverse_color)


func _get_or_create_section_container(name_value: String) -> VBoxContainer:
	var section := modifiers_container.get_node_or_null(name_value) as VBoxContainer
	if section == null:
		section = VBoxContainer.new()
		section.name = name_value
		modifiers_container.add_child(section)
	return section
	


func _on_s_add_infamy(_infamy_value):
	if _infamy_value >= 99 and _infamy_value < 100:
		infamy_value.text = "99"
	else:
		infamy_value.text = str(ceil(_infamy_value)) #l'affichage est arrondi au supérieur
	
func _on_new_game_button_pressed() -> void:
	var main = get_tree().get_root().get_node("Main")
	main.call_thread_safe('new_game')
	pass # Replace with function body.

func _draw() -> void:
	draw_infamy_stats()
	draw_modififiers()
	settings_button.text = tr("$Settings")
	modificators_label.text = tr("$Modifiers")
	


################### SETTINGS ############################

			
	

func get_performance_profile() -> String:
	var _cpu_name = OS.get_processor_name().to_lower()
	var cores = OS.get_processor_count()

	# Cas simple par nombre de coeurs
	if cores <= 4:
		return "LOW"
	elif cores <= 8:
		return "MEDIUM"
	else:
		return "HIGH"


func _on_settings_button_pressed() -> void:
	
	settings_panel.visible = !settings_panel.visible
	pass # Replace with function body.


func _on_language_button_pressed(language: String) -> void:
	var country_name:String = language.trim_suffix("Button")
	TranslationServer.set_locale(country_name)

	pass # Replace with function body.


func _on_safe_zone_check_box_pressed() -> void:
	var interface = get_tree().get_root().get_node("Main/Interface")
	if safe_zone_check_box.button_pressed:
		Global.apply_safe_area_to_ui(interface.main_zone, true)
	else:
		Global.apply_safe_area_to_ui(interface.main_zone, false)
	pass # Replace with function body.



func _save_data():
	var dict = {"language": TranslationServer.get_locale(),
				"safe_area_enable": safe_zone_check_box.button_pressed}
	
	return dict

func _load_data(content: Dictionary):
	TranslationServer.set_locale(content["language"])
	var interface = get_tree().get_root().get_node("Main/Interface")
	Global.apply_safe_area_to_ui(interface.main_zone, content["safe_area_enable"])

		

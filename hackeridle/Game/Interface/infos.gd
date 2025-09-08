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
@onready var brain_halo_label: Label = %BrainHaloLabel
@onready var brain_halo_check_box: CheckButton = %BrainHaloCheckBox
@onready var brain_halo_container: HBoxContainer = %BrainHaloContainer
@onready var modificators_label: Label = %ModificatorsLabel



@onready var safe_zone_label: Label = %SafeZoneLabel
@onready var safe_zone_check_box: CheckButton = %SafeZoneCheckBox

const BULLET_POINT = preload("res://Game/Interface/Specials/bullet_point.tscn")
const LEARNIN_BRAIN_HALO_MATERIAL = preload("res://Game/Themes/LearninBrainHaloMaterial.tres")


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
			value_str = "+%s" % str(value)
		elif value < 0:
			value_str = "-%s" % str(abs(value))
		else:
			value_str = ""
		
		_translations.append(tr("hack_" + StatsManager.STATS_NAMES.get(stat)).format({"hack_" + StatsManager.STATS_NAMES.get(stat) + "_value": value_str}))
	
	for trad in _translations:
		var bullet_label = BULLET_POINT.instantiate()
		infamy_effects.add_child(bullet_label)
		bullet_label.set_bullet_point(trad)
		
		
func draw_modififiers():
	
	pass
	


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

func match_performance_profile(performance: String):
	print("Performance: %s" % performance)
	match performance: 
		"LOW":
			enable_brain_halo(false)
		_:
			enable_brain_halo(true)
			
	

func get_performance_profile() -> String:
	var cpu_name = OS.get_processor_name().to_lower()
	var cores = OS.get_processor_count()

	# Cas simple par nombre de coeurs
	if cores <= 4:
		return "LOW"
	elif cores <= 8:
		return "MEDIUM"
	else:
		return "HIGH"

	# (Optionnel) Ajustement par nom du CPU
	if "snapdragon 8" in cpu_name or "apple a1" in cpu_name or "m1" in cpu_name:
		return "HIGH"
	elif "snapdragon 6" in cpu_name or "mediatek dimensity 800" in cpu_name:
		return "MEDIUM"
	elif "snapdragon 4" in cpu_name or "mediatek helio" in cpu_name:
		return "LOW"

	# fallback
	return "MEDIUM"


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


func _on_brain_halo_check_box_pressed() -> void:
	enable_brain_halo(brain_halo_check_box.button_pressed)
	
	pass # Replace with function body.
func enable_brain_halo(enable: bool = true):
	var learning = get_tree().get_root().get_node("Main/Interface").learning
	var clicker: TextureButton = learning.clicker_button
	if enable:
		clicker.material = LEARNIN_BRAIN_HALO_MATERIAL.duplicate()
		brain_halo_check_box.button_pressed = true
	else:
		brain_halo_check_box.button_pressed = false
		clicker.material = null
		

func _save_data():
	var dict = {"language": TranslationServer.get_locale(),
				"safe_area_enable": safe_zone_check_box.button_pressed,
				"brain_halo_enable": brain_halo_check_box.button_pressed}
	
	return dict

func _load_data(content: Dictionary):
	TranslationServer.set_locale(content["language"])
	var interface = get_tree().get_root().get_node("Main/Interface")
	Global.apply_safe_area_to_ui(interface.main_zone, content["safe_area_enable"])
	enable_brain_halo(content["brain_halo_enable"])
		

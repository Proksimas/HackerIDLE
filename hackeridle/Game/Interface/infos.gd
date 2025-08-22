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


@onready var safe_zone_label: Label = %SafeZoneLabel
@onready var safe_zone_check_box: CheckBox = %SafeZoneCheckBox

const BULLET_POINT = preload("res://Game/Interface/Specials/bullet_point.tscn")



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
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
			push_warning("Pas de valeur trouvée, pas normal ")
			return
		
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
		
		


func _on_s_add_infamy(_infamy_value):
	infamy_value.text = str(_infamy_value)
	
func _on_new_game_button_pressed() -> void:
	var main = get_tree().get_root().get_node("Main")
	main.call_thread_safe('new_game')
	pass # Replace with function body.

func _draw() -> void:
	draw_infamy_stats()
	settings_button.text = tr("$Settings")
	


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
	if content["safe_area_enable"]:
		Global.apply_safe_area_to_ui(interface.main_zone, true)
	else:
		Global.apply_safe_area_to_ui(interface.main_zone, false)

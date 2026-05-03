extends VBoxContainer

@onready var settings_button: Button = %SettingsButton
@onready var settings_panel: Panel = %SettingsPanel


func _ready() -> void:
	settings_panel.hide()
	settings_button.pressed.connect(_on_settings_button_pressed)
	if settings_panel.has_signal("s_new_game_requested"):
		settings_panel.s_new_game_requested.connect(_on_new_game_requested)
	if settings_panel.has_signal("s_safe_zone_toggled"):
		settings_panel.s_safe_zone_toggled.connect(_on_safe_zone_toggled)
	if settings_panel.has_signal("s_language_selected"):
		settings_panel.s_language_selected.connect(_on_language_selected)


func apply_translations() -> void:
	settings_button.text = tr("$Settings")
	if settings_panel.has_method("apply_translations"):
		settings_panel.apply_translations()


func get_settings_data() -> Dictionary:
	return {
		"language": TranslationServer.get_locale(),
		"safe_area_enable": settings_panel.is_safe_zone_enabled()
	}


func load_settings_data(content: Dictionary) -> void:
	TranslationServer.set_locale(content["language"])
	if settings_panel.has_method("set_safe_zone_enabled"):
		settings_panel.set_safe_zone_enabled(content["safe_area_enable"])
	_apply_safe_zone(content["safe_area_enable"])


func _on_settings_button_pressed() -> void:
	settings_panel.visible = !settings_panel.visible

func hide_panel() -> void:
	settings_panel.hide()


func _on_new_game_requested() -> void:
	var main = get_tree().get_root().get_node("Main")
	main.call_thread_safe("new_game")


func _on_safe_zone_toggled(enabled: bool) -> void:
	_apply_safe_zone(enabled)


func _on_language_selected(country_name: String) -> void:
	TranslationServer.set_locale(country_name)


func _apply_safe_zone(enabled: bool) -> void:
	var interface = get_tree().get_root().get_node("Main/Interface")
	if enabled:
		Global.apply_safe_area_to_ui(interface.main_zone, true)
	else:
		Global.apply_safe_area_to_ui(interface.main_zone, false)

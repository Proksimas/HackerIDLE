extends Panel

signal s_new_game_requested()
signal s_safe_zone_toggled(enabled: bool)
signal s_language_selected(locale: String)

@onready var new_game_button: Button = %NewGameButton
@onready var safe_zone_label: Label = %SafeZoneLabel
@onready var safe_zone_check_box: CheckButton = %SafeZoneCheckBox
@onready var country_container: HBoxContainer = %CountryContainer


func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_button_pressed)
	safe_zone_check_box.pressed.connect(_on_safe_zone_check_box_pressed)
	for country in country_container.get_children():
		country.pressed.connect(_on_language_button_pressed.bind(country.name))


func apply_translations() -> void:
	var locale := TranslationServer.get_locale().to_lower()
	var is_french := locale.begins_with("fr")
	if is_french:
		new_game_button.text = "Nouvelle partie"
		safe_zone_label.text = "Safe zone: "
	else:
		new_game_button.text = "New game"
		safe_zone_label.text = "Safe zone: "


func set_safe_zone_enabled(enabled: bool) -> void:
	safe_zone_check_box.button_pressed = enabled


func is_safe_zone_enabled() -> bool:
	return safe_zone_check_box.button_pressed


func _on_new_game_button_pressed() -> void:
	s_new_game_requested.emit()


func _on_safe_zone_check_box_pressed() -> void:
	s_safe_zone_toggled.emit(safe_zone_check_box.button_pressed)


func _on_language_button_pressed(language: String) -> void:
	var country_name: String = language.trim_suffix("Button")
	s_language_selected.emit(country_name)

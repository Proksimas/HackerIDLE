extends Panel

signal s_new_game_requested()
signal s_safe_zone_toggled(enabled: bool)
signal s_language_selected(locale: String)

@onready var new_game_button: Button = %NewGameButton
@onready var game_section_title: Label = %GameSectionTitle
@onready var new_game_warning_label: Label = %NewGameWarningLabel
@onready var display_section_title: Label = %DisplaySectionTitle
@onready var safe_zone_label: Label = %SafeZoneLabel
@onready var safe_zone_hint_label: Label = %SafeZoneHintLabel
@onready var language_section_title: Label = %LanguageSectionTitle
@onready var safe_zone_check_box: CheckButton = %SafeZoneCheckBox
@onready var country_container: HBoxContainer = %CountryContainer
@onready var new_game_confirm_dialog: ConfirmationDialog = %NewGameConfirmDialog
@onready var fr_button: TextureButton = %frButton
@onready var en_button: TextureButton = %enButton


func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_button_pressed)
	safe_zone_check_box.pressed.connect(_on_safe_zone_check_box_pressed)
	new_game_confirm_dialog.confirmed.connect(_on_new_game_confirmed)
	for country in country_container.get_children():
		country.pressed.connect(_on_language_button_pressed.bind(country.name))
	_update_language_buttons()


func apply_translations() -> void:
	var locale := TranslationServer.get_locale().to_lower()
	var is_french := locale.begins_with("fr")
	if is_french:
		game_section_title.text = "Partie"
		display_section_title.text = "Affichage"
		language_section_title.text = "Langue"
		new_game_warning_label.text = "Action irreversible."
		new_game_button.text = "Nouvelle partie"
		safe_zone_label.text = "Safe zone"
		safe_zone_hint_label.text = "Adapte l'interface pour les ecrans avec encoche."
		new_game_confirm_dialog.dialog_text = "Es-tu sur de recommencer une nouvelle partie ?"
		new_game_confirm_dialog.ok_button_text = "Confirmer"
		new_game_confirm_dialog.cancel_button_text = "Annuler"
	else:
		game_section_title.text = "Game"
		display_section_title.text = "Display"
		language_section_title.text = "Language"
		new_game_warning_label.text = "This action cannot be undone."
		new_game_button.text = "New game"
		safe_zone_label.text = "Safe zone"
		safe_zone_hint_label.text = "Adjusts UI for notched screens."
		new_game_confirm_dialog.dialog_text = "Are you sure you want to start a new game?"
		new_game_confirm_dialog.ok_button_text = "Confirm"
		new_game_confirm_dialog.cancel_button_text = "Cancel"
	_update_language_buttons()


func set_safe_zone_enabled(enabled: bool) -> void:
	safe_zone_check_box.button_pressed = enabled


func is_safe_zone_enabled() -> bool:
	return safe_zone_check_box.button_pressed


func _on_new_game_button_pressed() -> void:
	new_game_confirm_dialog.popup_centered()


func _on_new_game_confirmed() -> void:
	s_new_game_requested.emit()


func _on_safe_zone_check_box_pressed() -> void:
	s_safe_zone_toggled.emit(safe_zone_check_box.button_pressed)


func _on_language_button_pressed(language: String) -> void:
	var country_name: String = language.trim_suffix("Button")
	_set_language_button_active(country_name)
	s_language_selected.emit(country_name)


func _update_language_buttons() -> void:
	_set_language_button_active(TranslationServer.get_locale())


func _set_language_button_active(locale: String) -> void:
	var lower_locale := locale.to_lower()
	var is_french := lower_locale.begins_with("fr")
	fr_button.modulate = Color(1, 1, 1, 1) if is_french else Color(0.6, 0.6, 0.6, 1)
	en_button.modulate = Color(1, 1, 1, 1) if not is_french else Color(0.6, 0.6, 0.6, 1)

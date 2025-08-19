# File: IntroTypewriterLocalized.gd (Godot 4.3)
extends Control
class_name IntroTypewriterLocalized

signal finished  # émis quand toutes les lignes sont affichées

@export var keys: PackedStringArray = []         # Laisse vide pour auto-générer
@export var key_prefix: String = "introduction_" # Utilisé si keys est vide
@export var count: int = 12                     # Nombre de lignes si auto-génération
@export var chars_per_sec: float = 45.0          # Vitesse de "machine à écrire"
@export var set_locale_on_ready: String = ""     # "fr" ou "en" si tu veux forcer la langue

@onready var label: Label = %TextLabel

var _i: int = 0
var _typing: bool = false
var _acc: float = 0.0
var _visible: int = 0
var _current_text: String = ""

func _ready() -> void:
	if set_locale_on_ready != "":
		TranslationServer.set_locale(set_locale_on_ready)
	if keys.is_empty():
		for n in count:
			keys.append("%s%d" % [key_prefix, n + 1])
	set_process(true)
	_show_current()

func _process(delta: float) -> void:
	if not _typing:
		return
	_acc += delta * chars_per_sec
	var target := int(_acc)
	if target > _visible:
		_visible = target
		label.visible_characters = min(_visible, _current_text.length())
		if _visible >= _current_text.length():
			_typing = false  # ligne terminée



func _on_gui_input(event: InputEvent) -> void:
		# Tap écran / clic souris pour avancer

	if event is InputEventScreenTouch and event.pressed:
		_advance()
	elif event is InputEventMouseButton and \
	event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_advance()

	pass # Replace with function body.


func _advance() -> void:
	if _typing:
		# Si on tap pendant l'écriture : on termine instantanément la ligne
		_typing = false
		label.visible_characters = -1
	else:
		# Sinon on passe à la ligne suivante
		_i += 1
		_show_current()

func _show_current() -> void:
	if _i >= keys.size():
		finished.emit()
		return
	var key := keys[_i]
	_current_text = tr(key)        # <-- récupère le texte via la clé
	label.text = _current_text
	_acc = 0.0
	_visible = 0
	label.visible_characters = 0
	_typing = true

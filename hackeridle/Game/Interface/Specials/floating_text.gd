extends Node2D

var initial_position: Vector2
var fade_speed: float = 1.0
var move_speed: float = 50.0

@onready var label: Label = %Label


func _ready():
	# Définir la position initiale pour que le mouvement soit relatif
	initial_position = Vector2(0,0)

func _process(delta):
	# Fait monter le texte
	global_position.y -= move_speed * delta

	# Diminue la transparence du texte
	var alpha = label.modulate.a - fade_speed * delta
	label.modulate.a = alpha

	# Si le texte est invisible, le détruire
	if alpha <= 0.0:
		queue_free()

# Fonction pour initialiser le texte et le faire apparaître
func setup(text_to_display: String, start_position: Vector2, color: Color = Color(1, 1, 1)):
	label.text = text_to_display
	global_position = start_position
	label.modulate = color
	label.modulate.a = 1.0 # Assurer qu'il est visible au début

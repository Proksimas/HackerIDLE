extends Resource
class_name TutorialStep

## Une ressource complète qui encapsule toutes les données d'une étape de tutoriel.
## Elle gère l'affichage, la logique et la validation.

enum ValidationType {
	INPUT,       # Validation par une touche ou un clic
	SCORE,       # Validation par un nombre de points (ex: or, XP)
	SIGNAL,      # Validation par l'émission d'un signal (ex: saut, ennemi vaincu)
	CUSTOM_CHECK # Validation via une fonction personnalisée (pour plus de flexibilité)
}

# --- Section Affichage (pour l'UI) ---
@export var text_translation_key: String = ""          # Clé de traduction pour le texte principal
@export var pos: Vector2 = DisplayServer.window_get_size() / 2
@export var pause_game: bool = false                    # Met en pause le jeu quand cette étape est active

# --- Section Validation (pour le TutorialManager) ---
@export var validation_type: ValidationType

# Paramètres pour ValidationType.INPUT
#@export var input_action: String = "ui_accept"         # Ex: "ui_accept", "jump"

# Paramètres pour ValidationType.SCORE
@export var required_score_value: int = 0              # Valeur à atteindre
@export var score_variable_name: String = ""           # Nom de la variable à surveiller (ex: "gold", "experience")

@export var target_node_path: String = ""
@export var target_signal_name: String = ""            # Nom du signal à écouter (ex: "jumped", "enemy_killed")

# Paramètres pour ValidationType.CUSTOM_CHECK
@export var custom_check_function: String = ""         # Nom de la fonction à appeler pour la validation

@export_category("Arrows")
@export var no_arrow: bool = true
@export var center_down: bool = false
@export var right_down: bool = false
@export var left_down: bool = false

func get_show_arrows() -> String:
	if no_arrow:
		return "no_arrow"
	elif center_down:
		return "center_down"
	elif right_down:
		return "right_down"
	elif left_down:
		return "left_down"
	else:
		return "error_arrows"

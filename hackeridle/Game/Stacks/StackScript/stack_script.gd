extends Resource
class_name StackScript


# Propriétés de base du Script
@export var stack_script_name: String = "Script Inconnu"
@export var cooldown_base: float = 5.0 # Temps de rechargement de base
@export var type: String = "Utility" # "Attack", "Defense", "Utility"

enum TYPE {PENETRATION, ENCRYPTION, UTILITY}

const TYPE_NAME = {TYPE.PENETRATION: "penetration",
					TYPE.ENCRYPTION: "encryption",
					TYPE.UTILITY: "utility"}
# Propriétés dynamiques pour l'état
var time_remaining: float = 0.0 # Cooldown restant après exécution

# Méthode abstraite à implémenter par chaque type de Script
func execute(caster: Entity, target: Entity) -> void:
	# Logic spécifique au Script (dégâts, bouclier, etc.)
	pass

# Méthode appelée après l'exécution pour gérer le cooldown
func start_cooldown(caster: Entity) -> void:
	# La Latence du Hacker réduit le temps réel de rechargement
	var effective_cooldown = cooldown_base * (1.0 - caster.latency_multiplier)
	time_remaining = max(0.1, effective_cooldown)

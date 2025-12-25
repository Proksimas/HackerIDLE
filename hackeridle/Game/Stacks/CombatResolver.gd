extends Node
class_name CombatResolver

static func resolve(action: Dictionary) -> Dictionary:

	if not action.has("targets") or not action.has("effects"):
		return action
	
	var targets: Array = action.get("targets", [])
	var effects: Array = action.get("effects", [])
	
	for target in targets:
		if target == null:
			continue
		
		for effect in effects:
			_apply_effect(action.get("caster", null), target, effect)
	
	return action


static func _apply_effect(_caster: Entity, target: Entity, effect: Dictionary) -> void:
	var effect_type: String = str(effect.get("type", ""))
	var value: float = float(effect.get("value", 0))
	
	match effect_type:
		"HP":
			# Damage direct : ton take_damage gère déjà le shield.
			target.take_damage(value)
		
		"Shield":
			# Exemple si tu as / ajoutes add_shield()
			if target.has_method("add_shield"):
				target.add_shield(value)
			else:
				# fallback simple si tu veux
				target.current_shield += value
		
		_:
			# Effet inconnu: ignore pour l’instant
			pass

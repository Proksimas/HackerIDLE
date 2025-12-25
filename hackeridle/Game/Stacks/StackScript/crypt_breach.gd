extends StackScript

func execute() -> Dictionary:
	if targets.is_empty():
		return {
			"caster": caster,
			"targets": [],
			"action_type": "Damage",
			"effects": []
		}

	var target: Entity = targets[0]
	var damages: int = int(calcul_effect_value(caster))

	return {
		"caster": caster,
		"targets": [target],
		"action_type": "Damage",
		"effects": [
			{"value": damages, "type": "HP"},        # Hit 1 : normal
			{"value": damages, "type": "PierceHP"}   # Hit 2 : brut (ignore shield)
		]
	}

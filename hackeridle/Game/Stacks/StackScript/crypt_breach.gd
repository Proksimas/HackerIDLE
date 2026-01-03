extends StackScript

func execute() -> Dictionary:
	if targets.is_empty():
		return {
			"caster": caster,
			"action_type": "Damage",
			"targetEffects": []
		}

	var target: Entity = targets[0]
	var damages: int = int(calcul_effect_value(caster))

	return {
		"caster": caster,
		"action_type": "Damage",
		"targetEffects": [
			{
				"target": target,
				"effects": [
					{"value": damages, "type": "HP"},        # Hit 1 : normal
					{"value": damages / 2, "type": "PierceHP"}   # Hit 2 : brut (ignore shield)
				]
			}
		]
	}

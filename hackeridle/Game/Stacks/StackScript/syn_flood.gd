extends StackScript

func execute() -> Dictionary:
	if targets.is_empty():
		push_warning("Targets empty pour syn_flood")
		return {
			"caster": caster,
			"action_type": "Damage",
			"targetEffects": []
		}

	var damages = calcul_effect_value(caster)
	var target: Entity = targets[0]

	return {
		"caster": caster,
		"action_type": "Damage",
		"targets": [target],
		"targetEffects": [
			{
				"target": target,
				"effects": [
					{
						"value": damages,
						"type": "HP"
					}
				]
			}
		]
	}

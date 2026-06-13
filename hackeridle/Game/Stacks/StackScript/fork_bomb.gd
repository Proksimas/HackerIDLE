extends StackScript

const EXECUTE_THRESHOLD: float = 0.30
const EXECUTE_MULTIPLIER: float = 2.0


func execute() -> Dictionary:
	if targets.is_empty():
		return {
			"caster": caster,
			"action_type": "Damage",
			"targetEffects": []
		}

	var target: Entity = targets[0]
	var execute_bonus := false
	if target.max_hp > 0:
		execute_bonus = float(target.current_hp) / float(target.max_hp) <= EXECUTE_THRESHOLD

	var damage_multiplier := EXECUTE_MULTIPLIER if execute_bonus else 1.0
	var damages: int = int(round(float(calcul_effect_value(caster)) * damage_multiplier))

	return {
		"caster": caster,
		"action_type": "Damage",
		"meta": {
			"execute_bonus": execute_bonus,
			"execute_threshold": EXECUTE_THRESHOLD,
			"damage_multiplier": damage_multiplier
		},
		"targetEffects": [
			{
				"target": target,
				"effects": [
					{"type": "HP", "value": damages}
				]
			}
		]
	}

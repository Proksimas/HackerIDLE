extends StackScript

func execute() -> Dictionary:
	if targets.is_empty():
		return {"caster": caster, "action_type": "Damage", "targetEffects": []}

	var enemy: Entity = targets[0]
	var damages: int = int(calcul_effect_value(caster))

	# Shield = Encryption brute
	var encryption_value: int = 0
	if caster.entity_is_hacker:
		encryption_value = int(StackManager.stack_script_stats.get("encryption", 0))
	else:
		encryption_value = int(caster.stats.get("encryption", 0))

	return {
		"caster": caster,
		"action_type": "Damage",
		"targets": [enemy, caster],
		"targetEffects": [
			{
				"target": enemy,
				"effects": [
					{"type": "HP", "value": damages}
				]
			},
			{
				"target": caster,
				"effects": [
					{"type": "Shield", "value": encryption_value}
				]
			}
		]
	}

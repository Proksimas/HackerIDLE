extends StackScript


func execute() -> Dictionary:
	# Logic spécifique au Script (dégâts, bouclier, etc.)
	var damages = calcul_effect_value(caster)
	targets[0].take_damage(damages)
	return {"damages": damages,
			"targets": targets[0].entity_name}
	

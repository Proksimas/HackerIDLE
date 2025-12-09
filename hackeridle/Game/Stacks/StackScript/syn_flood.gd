extends StackScript


func execute() -> Dictionary:
	# Logic spécifique au Script (dégâts, bouclier, etc.)
	var dict = {}
	var damages = calcul_effect_value(caster)
	dict = {"damages": damages,
			"targets": targets[0].entity_name}
	targets[0].take_damage(damages)
	return dict
	

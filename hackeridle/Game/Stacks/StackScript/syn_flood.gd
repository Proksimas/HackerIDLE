extends StackScript


func execute() -> void:
	# Logic spécifique au Script (dégâts, bouclier, etc.)
	var damages = calcul_effect_value(caster)
	targets[0].take_damage(damages)
	pass

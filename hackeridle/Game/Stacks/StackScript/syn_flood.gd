extends StackScript


func execute(caster: Entity, targets: Array[Entity]) -> void:
	# Logic spécifique au Script (dégâts, bouclier, etc.)
	print("inflige 5 degats")
	targets[0].take_damage(5)
	pass

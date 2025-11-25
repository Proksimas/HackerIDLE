extends StackScript


func execute(caster: Entity, target: Entity) -> void:
	# Logic spécifique au Script (dégâts, bouclier, etc.)
	print("inflige 5 degats")
	target.take_damage(5)
	pass

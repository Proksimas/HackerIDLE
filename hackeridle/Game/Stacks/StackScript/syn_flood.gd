extends StackScript


func execute(caster: Entity, target: Entity) -> void:
	# Logic spécifique au Script (dégâts, bouclier, etc.)
	print("inflige 5 degats")
	target.current_hp -= 5
	pass

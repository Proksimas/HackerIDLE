extends PassiveSkill


func attach(_caster: Node, level) -> void:
	super.attach(_caster, level)
	var extra_slots: int = int(data_bonus_1[ps_level - 1])
	StackManager.set_hacker_extra_slots(ps_name, extra_slots)


func detach(_caster: Node) -> void:
	super.detach(_caster)
	StackManager.set_hacker_extra_slots(ps_name, 0)

extends PassiveSkill


func attach(_caster: Node, level) -> void:
	super.attach(_caster, level)
	var total_bonus = 0
	for i in range(0, ps_level):
		total_bonus += data_bonus_1[i]
		
	NovaNetManager.coef_farming_xp[self.ps_name] = total_bonus
	

	
func detach(_caster: Node)-> void:
	"""dettache les ajouts que donne le sill"""
	super.detach(_caster)
	NovaNetManager.coef_farming_xp.erase(self.ps_name)
	
	pass

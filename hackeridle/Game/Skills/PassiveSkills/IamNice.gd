extends PassiveSkill

func attach(_caster: Node, level) -> void:
	super.attach(_caster, level)
	StatsManager.add_modifier(StatsManager.TargetModifier.DECREASE_INFAMY, 
				StatsManager.Stats.DECREASE_INFAMY, 
				StatsManager.ModifierType.BASE,
				data_bonus_1[ps_level - 1], 
				self.ps_name)
	
func detach(_caster: Node)-> void:
	"""dettache les ajouts que donne le sill
	
	A SURCHARGER """
	super.detach(_caster)
	var dict_to_remove = StatsManager.get_modifier_by_source_name(StatsManager.TargetModifier.DECREASE_INFAMY, 
					StatsManager.Stats.DECREASE_INFAMY, self.ps_name)
					
	if !dict_to_remove.is_empty():
		StatsManager.remove_modifier(StatsManager.TargetModifier.DECREASE_INFAMY, 
					StatsManager.Stats.DECREASE_INFAMY, dict_to_remove)
	pass

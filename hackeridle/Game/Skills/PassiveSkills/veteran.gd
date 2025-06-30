extends PassiveSkill

var aug_xp = [0.1,0.2,0.3]


func attach(_caster: Node, level) -> void:
	super.attach(_caster, level)
	StatsManager.add_modifier(StatsManager.TargetModifier.BRAIN_CLICK, 
					StatsManager.Stats.BRAIN_XP, 
					StatsManager.ModifierType.PERCENTAGE, 
					aug_xp[ps_level - 1], self.ps_name)
	
func detach(_caster: Node)-> void:
	"""dettache les ajouts que donne le sill
	
	A SURCHARGER """
	super.detach(_caster)
	var dict_to_remove = StatsManager.get_modifier_by_source_name(StatsManager.TargetModifier.BRAIN_CLICK, 
					StatsManager.Stats.BRAIN_XP, self.ps_name)
	if !dict_to_remove.is_empty():
		StatsManager.remove_modifier(StatsManager.TargetModifier.BRAIN_CLICK, 
					StatsManager.Stats.BRAIN_XP, dict_to_remove)
	pass

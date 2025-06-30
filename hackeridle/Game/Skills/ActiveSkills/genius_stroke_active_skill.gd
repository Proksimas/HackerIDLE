extends ActiveSkill

   #100%,200%,400%

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	
func launch_as(surcharge_during_time: float = 0):
	StatsManager.add_modifier(StatsManager.TargetModifier.BRAIN_CLICK, 
					StatsManager.Stats.KNOWLEDGE, 
					StatsManager.ModifierType.PERCENTAGE, 
					data_bonus_1[as_level - 1]/100, self.as_name)
	super.launch_as(surcharge_during_time)

func as_finished(surcharge_cd:float = 0):
	var dict_to_remove = StatsManager.get_modifier_by_source_name(StatsManager.TargetModifier.BRAIN_CLICK, 
					StatsManager.Stats.KNOWLEDGE, self.as_name)
	if !dict_to_remove.is_empty():
		StatsManager.remove_modifier(StatsManager.TargetModifier.BRAIN_CLICK, 
					StatsManager.Stats.KNOWLEDGE, dict_to_remove)
					
	super.as_finished(surcharge_cd)

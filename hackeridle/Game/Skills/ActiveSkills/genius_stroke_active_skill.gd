extends ActiveSkill

var increase_knowledge_and_xp = [1,2,4]   #100%,200%,400%

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func attach(caster: Node, level) -> void:
	""" OBLIGATOIRE lors de l'instantiation d'un skill
	Appeler lorsqu'on add le skill, cela permet de gérer ce que fait le skill:
		- les connexions à appeler
		- l'ajout des stats brut
		
		A SURCHARGER EVENTUELLEMENT"""
		
	tree = caster.get_tree()   # on récupère la référence de l'arbre
	self.as_level = level
	
	
func launch_as(surcharge_during_time: float = 0):
	StatsManager.add_modifier(StatsManager.TargetModifier.BRAIN_CLICK, 
					StatsManager.Stats.KNOWLEDGE, 
					StatsManager.ModifierType.BASE, 1, self.as_name)
	super.launch_as(surcharge_during_time)

func as_finished(surcharge_cd = 0):
	var dict_to_remove = StatsManager.get_modifier_by_source_name(StatsManager.TargetModifier.BRAIN_CLICK, 
					StatsManager.Stats.KNOWLEDGE, self.as_name)
	if dict_to_remove.is_empty():
		return
	StatsManager.remove_modifier(StatsManager.TargetModifier.BRAIN_CLICK, 
					StatsManager.Stats.KNOWLEDGE, dict_to_remove)
					
	super.as_finished(surcharge_cd)

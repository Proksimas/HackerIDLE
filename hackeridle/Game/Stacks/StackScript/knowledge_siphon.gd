extends StackScript

const BASE_KNOWLEDGE_PERCENT: float = 3.0
const KNOWLEDGE_PERCENT_PER_FLUX: float = 0.05


func execute() -> Dictionary:
	var knowledge_percent := calculate_knowledge_percent(_get_caster_flux())
	var knowledge_gain := 0.0
	if caster != null and caster.entity_is_hacker:
		knowledge_gain = maxf(0.0, Calculs.get_tot_knowledge()) * knowledge_percent / 100.0

	return {
		"caster": caster,
		"action_type": "Knowledge",
		"meta": {
			"knowledge_percent": knowledge_percent,
			"knowledge_gain": knowledge_gain
		},
		"targetEffects": [
			{
				"target": caster,
				"effects": [
					{"type": "Knowledge", "value": knowledge_gain}
				]
			}
		]
	}


func calculate_knowledge_percent(flux: float) -> float:
	return BASE_KNOWLEDGE_PERCENT + maxf(0.0, flux) * KNOWLEDGE_PERCENT_PER_FLUX


func get_description() -> String:
	var knowledge_percent := calculate_knowledge_percent(float(StackManager.stack_script_stats.get("flux", 0.0)))
	return TranslationServer.translate("%s_desc" % stack_script_name) \
		.replace("{knowledge_percent}", _format_percent(knowledge_percent))


func get_preview_value(stats: Dictionary) -> float:
	return calculate_knowledge_percent(float(stats.get("flux", 0.0)))


func get_preview_suffix() -> String:
	return "%"


func _get_caster_flux() -> float:
	if caster == null:
		return 0.0
	if caster.entity_is_hacker:
		return float(StackManager.stack_script_stats.get("flux", 0.0))
	return float(caster.stats.get("flux", 0.0))


func _format_percent(value: float) -> String:
	if is_equal_approx(value, round(value)):
		return str(int(round(value)))
	return "%.2f" % value

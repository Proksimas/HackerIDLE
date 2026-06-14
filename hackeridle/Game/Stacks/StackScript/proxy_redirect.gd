extends StackScript

@export_category("Proxy Redirect")
@export_range(0.0, 1.0, 0.01) var redirect_min: float = 0.20
@export_range(0.0, 1.0, 0.01) var redirect_max: float = 0.60
@export_range(1.0, 100000.0, 1.0) var redirect_score_at_max: float = 500.0
@export_range(0.1, 2.0, 0.05) var redirect_alpha: float = 0.70
@export_range(1, 20, 1) var status_turn_duration: int = 2


func execute() -> Dictionary:
	var redirect_ratio := calculate_redirect_ratio(_get_caster_stats())
	var status := {
		"id": "ProxyRedirect",
		"display_name": "proxy_redirect_status",
		"type": "ProxyRedirect",
		"value": redirect_ratio,
		"turns": status_turn_duration,
		"stackMode": "NoStack",
		"refreshMode": "Refresh",
		"maxStacks": 1,
		"source": caster
	}

	return {
		"caster": caster,
		"action_type": "Status",
		"meta": {
			"status_name": "proxy_redirect_status",
			"turn_duration": status_turn_duration,
			"redirect_percent": redirect_ratio * 100.0
		},
		"targetEffects": [
			{
				"target": caster,
				"effects": [
					{"type": "ApplyStatus", "status": status}
				]
			}
		]
	}


func calculate_redirect_ratio(stats: Dictionary) -> float:
	var scaling_score := 0.0
	for stat_name_variant in type_and_coef.keys():
		var stat_name := str(stat_name_variant)
		var coefficient: float = maxf(0.0, float(type_and_coef.get(stat_name_variant, 0.0)))
		scaling_score += maxf(0.0, float(stats.get(stat_name, 0.0))) * coefficient

	var safe_score_at_max: float = maxf(1.0, redirect_score_at_max)
	var normalized_score: float = clampf(scaling_score / safe_score_at_max, 0.0, 1.0)
	var safe_min: float = clampf(redirect_min, 0.0, 1.0)
	var safe_max: float = clampf(maxf(redirect_max, safe_min), safe_min, 1.0)
	return safe_min + (safe_max - safe_min) * pow(normalized_score, redirect_alpha)


func get_description() -> String:
	var redirect_percent: int = int(round(calculate_redirect_ratio(StackManager.stack_script_stats) * 100.0))
	return TranslationServer.translate("%s_desc" % stack_script_name) \
		.replace("{redirect_percent}", str(redirect_percent)) \
		.replace("{turn_duration}", str(status_turn_duration))


func _get_caster_stats() -> Dictionary:
	if caster == null:
		return {}
	if caster.entity_is_hacker:
		return StackManager.stack_script_stats
	return caster.stats

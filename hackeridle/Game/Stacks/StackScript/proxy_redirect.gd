extends StackScript

const REDIRECT_MIN: float = 0.20
const REDIRECT_MAX: float = 0.60
const REDIRECT_MAX_ENCRYPTION: float = 500.0
const REDIRECT_ALPHA: float = 0.7
const STATUS_TURN_DURATION: int = 2


func execute() -> Dictionary:
	var redirect_ratio := calculate_redirect_ratio(_get_caster_encryption())
	var status := {
		"id": "ProxyRedirect",
		"display_name": "proxy_redirect_status",
		"type": "ProxyRedirect",
		"value": redirect_ratio,
		"turns": STATUS_TURN_DURATION,
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
			"turn_duration": STATUS_TURN_DURATION,
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


func calculate_redirect_ratio(encryption: float) -> float:
	var normalized_encryption: float = clampf(encryption / REDIRECT_MAX_ENCRYPTION, 0.0, 1.0)
	return REDIRECT_MIN + (REDIRECT_MAX - REDIRECT_MIN) * pow(normalized_encryption, REDIRECT_ALPHA)


func get_description() -> String:
	var encryption: float = float(StackManager.stack_script_stats.get("encryption", 0.0))
	var redirect_percent: int = int(round(calculate_redirect_ratio(encryption) * 100.0))
	return TranslationServer.translate("%s_desc" % stack_script_name) \
		.replace("{redirect_percent}", str(redirect_percent)) \
		.replace("{turn_duration}", str(STATUS_TURN_DURATION))


func _get_caster_encryption() -> float:
	if caster == null:
		return 0.0
	if caster.entity_is_hacker:
		return float(StackManager.stack_script_stats.get("encryption", 0.0))
	return float(caster.stats.get("encryption", 0.0))

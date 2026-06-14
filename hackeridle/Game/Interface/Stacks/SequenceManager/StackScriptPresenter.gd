class_name StackScriptPresenter
extends RefCounted


func format_script_name(raw_name: String) -> String:
	var pretty := raw_name.replace("_", " ")
	if pretty.length() == 0:
		return pretty
	if pretty.length() == 1:
		return pretty.to_upper()
	return pretty[0].to_upper() + pretty.substr(1, pretty.length() - 1)


func script_kind_to_string(kind: int) -> String:
	match kind:
		StackScript.ScriptKind.DAMAGE:
			return "Degats"
		StackScript.ScriptKind.SHIELD:
			return "Bouclier"
		StackScript.ScriptKind.UTILITY:
			return "Utilitaire"
		_:
			return "Inconnu"


func format_scaling(coeffs: Dictionary, base_value: float = 0.0) -> String:
	var parts: Array[String] = []
	if abs(base_value) > 0.0001:
		parts.append(format_number(base_value))
	var ordered := ["penetration", "encryption", "flux"]
	for key in ordered:
		var coef := float(coeffs.get(key, 0.0))
		if abs(coef) < 0.0001:
			continue
		parts.append("%s x%s" % [format_stat_name(key), format_number(coef)])
	return " + ".join(parts) if not parts.is_empty() else "Aucun bonus"


func format_stat_name(key: String) -> String:
	match key:
		"penetration":
			return tr("stat_penetration")
		"encryption":
			return tr("stat_encryption")
		"flux":
			return tr("stat_flux")
		_:
			return key


func format_number(value: float) -> String:
	if int(value) == value:
		return str(int(value))
	return "%.2f" % value


func build_value_preview(script: StackScript, stats: Dictionary) -> String:
	if script == null:
		return ""

	var preview_value: float = script.get_preview_value(stats)
	return format_number(preview_value) + script.get_preview_suffix()

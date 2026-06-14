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


func format_scaling(coeffs: Dictionary) -> String:
	if coeffs.is_empty():
		return "Aucun bonus"
	var parts: Array[String] = []
	var ordered := ["penetration", "encryption", "flux"]
	for key in ordered:
		var coef := float(coeffs.get(key, 0.0))
		if abs(coef) < 0.0001:
			continue
		parts.append("%s x%s" % [format_stat_name(key), format_number(coef)])
	return " / ".join(parts) if not parts.is_empty() else "Aucun bonus"


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

	var base := float(script.base_value_hacker)
	var terms: Array[String] = []

	if abs(base) > 0.0001:
		terms.append("Base %s" % format_number(base))

	var ordered := ["penetration", "encryption", "flux"]
	for key in ordered:
		var coef := float(script.type_and_coef.get(key, 0.0))
		if abs(coef) < 0.0001:
			continue
		var ratio_percent := format_number(abs(coef) * 100.0)
		var sign_prefix := "+" if coef >= 0.0 else "-"
		terms.append("%s %s (%s%%)" % [sign_prefix, format_stat_name(key), ratio_percent])

	var preview_value: float = script.get_preview_value(stats)
	var formatted_value := format_number(preview_value) + script.get_preview_suffix()
	if terms.is_empty():
		return "%s: %s" % [tr("$Valeur"), formatted_value]
	return "%s: %s\n --> %s" % [tr("$Valeur"), formatted_value, " ".join(terms)]

class_name StackScriptPresenter
extends RefCounted


static func format_script_name(raw_name: String) -> String:
	var pretty := raw_name.replace("_", " ")
	if pretty.length() == 0:
		return pretty
	if pretty.length() == 1:
		return pretty.to_upper()
	return pretty[0].to_upper() + pretty.substr(1, pretty.length() - 1)


static func script_kind_to_string(kind: int) -> String:
	match kind:
		StackScript.ScriptKind.DAMAGE:
			return "Degats"
		StackScript.ScriptKind.SHIELD:
			return "Bouclier"
		StackScript.ScriptKind.UTILITY:
			return "Utilitaire"
		_:
			return "Inconnu"


static func format_scaling(coeffs: Dictionary) -> String:
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


static func format_stat_name(key: String) -> String:
	match key:
		"penetration":
			return "Penetration"
		"encryption":
			return "Encryption"
		"flux":
			return "Flux"
		_:
			return key


static func format_number(value: float) -> String:
	if int(value) == value:
		return str(int(value))
	return "%.2f" % value

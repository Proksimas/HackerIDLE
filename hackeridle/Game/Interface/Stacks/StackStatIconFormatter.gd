class_name StackStatIconFormatter
extends RefCounted

const ICON_SIZE: int = 35
const PENETRATION_ICON_PATH := "res://Game/Graphics/NovaNet/penetration_2.png"
const ENCRYPTION_ICON_PATH := "res://Game/Graphics/NovaNet/encryption_2.png"
const FLUX_ICON_PATH := "res://Game/Graphics/NovaNet/flux_2.png"


static func format(text: String) -> String:
	var formatted := text
	formatted = _replace_terms(formatted, ["Penetration", "penetration"], "{STAT_PENETRATION_ICON}")
	formatted = _replace_terms(formatted, ["Encryption", "encryption", "Chiffrement", "chiffrement"], "{STAT_ENCRYPTION_ICON}")
	formatted = _replace_terms(formatted, ["Flux", "flux"], "{STAT_FLUX_ICON}")

	return formatted \
		.replace("{STAT_PENETRATION_ICON}", _icon_tag(PENETRATION_ICON_PATH)) \
		.replace("{STAT_ENCRYPTION_ICON}", _icon_tag(ENCRYPTION_ICON_PATH)) \
		.replace("{STAT_FLUX_ICON}", _icon_tag(FLUX_ICON_PATH))


static func _replace_terms(text: String, terms: Array[String], placeholder: String) -> String:
	var formatted := text
	for term in terms:
		formatted = formatted.replace(term, placeholder)
	return formatted


static func _icon_tag(texture_path: String) -> String:
	return "[img=%dx%d]%s[/img]" % [ICON_SIZE, ICON_SIZE, texture_path]

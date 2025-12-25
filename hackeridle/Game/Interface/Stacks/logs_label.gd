extends RichTextLabel # Assurez-vous que le script est attaché à un RichTextLabel

# Définition des couleurs (constantes)
const COLOR_HP = "#FF0000"     # Rouge
const COLOR_SHIELD = "#8A2BE2"  # Violet
const COLOR_TARGET = "#00BFFF"  # Bleu Ciel
const COLOR_CASTER = "#FFD700"  # Jaune
const COLOR_DOT = "#008000"    # Vert

## Fonction utilitaire pour formater un tableau de noms de cibles (avec le type Array pour flexibilité)
func format_target_names(targets: Array) -> String:
	var formatted_targets = []
	for target: Entity in targets:
		formatted_targets.append("[color=%s]%s[/color]" % [COLOR_TARGET, target.entity_name.capitalize()])
	return ", ".join(formatted_targets)

## Fonction utilitaire pour formater un SEUL effet {value: int, type: String}
func format_single_effect(effect: Dictionary) -> String:
	var value = effect.get("value", 0)
	var type = effect.get("type", "HP")
	var damage_color = ""
	var damage_tag = ""
	
	match type:
		"HP":
			damage_color = COLOR_HP
			damage_tag = "HP"
		"Shield":
			damage_color = COLOR_SHIELD
			damage_tag = "Shield"
		"DoT":
			damage_color = COLOR_DOT
			damage_tag = "DoT"
		_:
			damage_color = "#FFFFFF"
			damage_tag = "Effet"

	var formatted_value = "[color=%s]%d[/color]" % [damage_color, value]
	
	return "%s %s" % [formatted_value, damage_tag]

# ----------------------------------------------------------------------
# NOUVELLE LOGIQUE POUR LA CONSTRUCTION DE LA PHRASE
# ----------------------------------------------------------------------

## Construit le message de log final basé sur l'action_type
func build_log_message(event_data: Dictionary) -> String:
	var action_type = event_data.get("action_type", "Action Unknown")

	# Extraction et formatage des entités (communes à toutes les actions)
	var caster_name = event_data["caster"].entity_name
	var targets: Array = event_data.get("targets", [])

	var formatted_caster = "[color=%s]%s[/color]" % [COLOR_CASTER, caster_name.capitalize()]
	var formatted_targets = format_target_names(targets)

	# --- Suffixe de kill basé sur la résolution ---
	var kill_suffix := ""
	if event_data.has("resolution"):
		var killed: Array = event_data["resolution"].get("killed", [])
		if killed.size() > 0:
			var killed_names: Array = []
			for t in killed:
				if t != null:
					killed_names.append(t.entity_name.capitalize())
			if killed_names.size() > 0:
				kill_suffix = " [color=#FFFFFF](%s meurt)[/color]" % ", ".join(killed_names)

	match action_type:
		"Damage":
			# Effets réels si résolution présente, sinon intention
			var effects = build_effects_from_resolution(event_data)

			var formatted_effects_list: Array = []
			for effect in effects:
				# Petit garde-fou si jamais un élément n'est pas un dict
				if effect is Dictionary:
					formatted_effects_list.append(format_single_effect(effect))
				else:
					formatted_effects_list.append(str(effect))

			var formatted_effects_str = ", ".join(formatted_effects_list)

			# Phrase : [Caster] inflige [Effets] à [Targets]
			if targets.size() > 1:
				return "%s inflige les dégâts suivants à ses cibles : %s (%s).%s" % [
					formatted_caster,
					formatted_effects_str,
					formatted_targets,
					kill_suffix
				]
			else:
				return "%s inflige %s de dégâts à %s.%s" % [
					formatted_caster,
					formatted_effects_str,
					formatted_targets,
					kill_suffix
				]

		"Death":
			return "%s est mort." % formatted_caster
			
		"Shield":
			var effects = build_effects_from_resolution(event_data)
			var formatted_effects_list: Array = []
			for effect in effects:
				formatted_effects_list.append(format_single_effect(effect))
			var formatted_effects_str = ", ".join(formatted_effects_list)
			return "%s renforce %s avec %s." % [formatted_caster, formatted_targets, formatted_effects_str]


		"Heal":
			var effects = event_data.get("effects", [])
			var formatted_effects_list: Array = []
			for effect in effects:
				if effect is Dictionary:
					formatted_effects_list.append(format_single_effect(effect))
				else:
					formatted_effects_list.append(str(effect))

			var formatted_effects_str = ", ".join(formatted_effects_list)
			return "%s soigne %s pour %s points." % [formatted_caster, formatted_targets, formatted_effects_str]

		_:
			return "Événement de log non reconnu: %s" % str(event_data)


func build_effects_from_resolution(event_data: Dictionary) -> Array:
	var res = event_data.get("resolution", null)
	if res == null:
		return event_data.get("effects", [])

	var per_target: Array = res.get("perTarget", [])
	var total_hp_lost := 0.0
	var total_shield_lost := 0.0

	for entry in per_target:
		var delta: Dictionary = entry.get("delta", {})
		total_hp_lost += float(delta.get("hpLost", 0))
		total_shield_lost += float(delta.get("shieldLost", 0))

	var effects_for_log: Array = []
	# On affiche d'abord le shield absorbé (si tu veux), puis la perte HP
	if total_shield_lost > 0:
		effects_for_log.append({"value": int(round(total_shield_lost)), "type": "Shield"})
	if total_hp_lost > 0:
		effects_for_log.append({"value": int(round(total_hp_lost)), "type": "HP"})

	# fallback si jamais rien n'a bougé
	if effects_for_log.is_empty():
		return event_data.get("effects", [])

	return effects_for_log


## Fonction principale pour formater et afficher le texte de l'événement
func log_event(event_data: Dictionary):
	var text_log = build_log_message(event_data)
	self.bbcode_text = text_log

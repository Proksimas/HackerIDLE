extends RichTextLabel # Assurez-vous que le script est attaché à un RichTextLabel

# Définition des couleurs (constantes)
const COLOR_HP = "#FF0000"      # Rouge
const COLOR_SHIELD = "#8A2BE2"  # Violet
const COLOR_TARGET = "#00BFFF"  # Bleu Ciel
const COLOR_CASTER = "#FFD700"  # Jaune
const COLOR_DOT = "#008000"     # Vert

## Fonction utilitaire pour formater un tableau de noms de cibles
func format_target_names(targets: Array) -> String:
	var formatted_targets: Array = []
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
		"PierceHP":
			damage_color = COLOR_HP
			damage_tag = "Brut"
		"HealHP":
			damage_color = COLOR_HP
			damage_tag = "HP"
		_:
			damage_color = "#FFFFFF"
			damage_tag = "Effet"

	var formatted_value = "[color=%s]%d[/color]" % [damage_color, int(value)]
	return "%s %s" % [formatted_value, damage_tag]


func _format_effects_list(effects: Array) -> String:
	var parts: Array = []
	for effect in effects:
		if effect is Dictionary:
			parts.append(format_single_effect(effect))
		else:
			parts.append(str(effect))
	return ", ".join(parts)


func _kill_suffix(event_data: Dictionary) -> String:
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
	return kill_suffix


func _get_resolution_entry_for_target(event_data: Dictionary, target: Entity) -> Dictionary:
	if not event_data.has("resolution"):
		return {}
	var per_target: Array = event_data["resolution"].get("perTarget", [])
	for entry in per_target:
		if entry.get("target", null) == target:
			return entry
	return {}


func _build_effects_from_resolution_for_target(event_data: Dictionary, target: Entity) -> Array:
	# Si on a une résolution, on reconstruit des effets "réels" pour CETTE cible.
	var entry := _get_resolution_entry_for_target(event_data, target)
	if entry.is_empty():
		# Pas de résolution ciblée : fallback sur les effets "déclarés" (intention)
		return []

	var delta: Dictionary = entry.get("delta", {})
	var hp_lost: float = float(delta.get("hpLost", 0))
	var shield_lost: float = float(delta.get("shieldLost", 0))
	var hp_gained: float = float(delta.get("hpGained", 0))
	var shield_gained: float = float(delta.get("shieldGained", 0))

	var effects_for_log: Array = []

	# Dégâts (on affiche d'abord le shield absorbé, puis HP)
	if shield_lost > 0:
		effects_for_log.append({"value": int(round(shield_lost)), "type": "Shield"})
	if hp_lost > 0:
		effects_for_log.append({"value": int(round(hp_lost)), "type": "HP"})

	# Soin / gain de shield
	if hp_gained > 0:
		effects_for_log.append({"value": int(round(hp_gained)), "type": "HealHP"})
	if shield_gained > 0:
		effects_for_log.append({"value": int(round(shield_gained)), "type": "Shield"})

	return effects_for_log


func _is_only_type(effects: Array, type_name: String) -> bool:
	if effects.size() != 1:
		return false
	if not (effects[0] is Dictionary):
		return false
	return str(effects[0].get("type", "")) == type_name
## Construit le message de log final basé sur l'action_type
func build_log_message(event_data: Dictionary) -> String:
	var action_type = event_data.get("action_type", "Action Unknown")

	# --- Caster (normal) ---
	var caster_name = event_data["caster"].entity_name
	var formatted_caster = "[color=%s]%s[/color]" % [COLOR_CASTER, caster_name.capitalize()]

	# --- Si c'est un tick de statut, on affiche le statut comme "caster" + stacks ---
	var meta: Dictionary = event_data.get("meta", {})
	if bool(meta.get("tick", false)):
		var status_id: String = str(meta.get("statusId", "Status"))
		var stacks_tick: int = int(meta.get("stacks", 1))

		var stack_txt := ""
		if stacks_tick > 1:
			stack_txt = " x%d" % stacks_tick

		formatted_caster = "[color=%s]%s%s[/color]" % [COLOR_DOT, tr(status_id.capitalize()), stack_txt]

	var kill_suffix := _kill_suffix(event_data)

	match action_type:
		"Damage", "Shield", "Heal":
			# ✅ Nouveau monde : on ne dépend plus de `targets`, on lit `targetEffects`
			if event_data.has("targetEffects"):
				var te_list: Array = event_data.get("targetEffects", [])
				var lines: Array = []

				for te in te_list:
					if not (te is Dictionary):
						continue
					var target: Entity = te.get("target", null)
					if target == null:
						continue

					# Effets "réels" si possible (résolution), sinon intention sur cette cible
					var resolved_effects: Array = _build_effects_from_resolution_for_target(event_data, target)
					var effects_for_phrase: Array = resolved_effects
					if effects_for_phrase.is_empty():
						effects_for_phrase = te.get("effects", [])

					var formatted_target = format_target_names([target])

					# --- Construire un suffixe "applique statut" si ApplyStatus présent (avec stacks) ---
					var extra_parts: Array = []
					for eff in te.get("effects", []):
						if eff is Dictionary and str(eff.get("type", "")) == "ApplyStatus":
							var status: Dictionary = eff.get("status", {})
							var status_name: String = str(status.get("display_name", status.get("id", "Status")))
							var turns: int = int(status.get("turns", status.get("turnsRemaining", 0)))
							var stacks_apply: int = int(status.get("stacks", 1))

							var stack_txt_apply := ""
							if stacks_apply > 1:
								stack_txt_apply = " x%d" % stacks_apply

							if turns > 0:
								extra_parts.append("applique [color=%s]%s%s[/color] (%d tours)" % [
									COLOR_DOT,
									tr(status_name),
									stack_txt_apply,
									turns
								])
							else:
								extra_parts.append("applique [color=%s]%s%s[/color]" % [
									COLOR_DOT,
									tr(status_name),
									stack_txt_apply
								])

					var extra_suffix := ""
					if extra_parts.size() > 0:
						extra_suffix = " et " + " et ".join(extra_parts)

					# --- Format des effets affichés ---
					var formatted_effects_str = _format_effects_list(effects_for_phrase)

					# --- Choix de la phrase ---
					if _is_only_type(effects_for_phrase, "Shield"):
						lines.append("%s renforce %s avec %s.%s" % [
							formatted_caster, formatted_target, formatted_effects_str, kill_suffix
						])
					elif _is_only_type(effects_for_phrase, "HealHP"):
						lines.append("%s soigne %s pour %s points.%s" % [
							formatted_caster, formatted_target, formatted_effects_str, kill_suffix
						])
					else:
						lines.append("%s inflige %s à %s%s.%s" % [
							formatted_caster, formatted_effects_str, formatted_target, extra_suffix, kill_suffix
						])

				if lines.size() > 0:
					return "\n".join(lines)

			# Fallback si jamais on reçoit un ancien event sans targetEffects
			var effects_fallback: Array = event_data.get("effects", [])
			var formatted_effects_str_fb = _format_effects_list(effects_fallback)
			return "%s exécute une action : %s.%s" % [formatted_caster, formatted_effects_str_fb, kill_suffix]

		"Death":
			return "%s est mort." % formatted_caster

		_:
			return "Événement de log non reconnu: %s" % str(event_data)

## Fonction principale pour formater et afficher le texte de l'événement
func log_event(event_data: Dictionary) -> void:
	var text_log = build_log_message(event_data)
	self.bbcode_text = text_log

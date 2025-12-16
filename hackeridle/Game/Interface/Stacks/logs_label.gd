extends RichTextLabel # Assurez-vous que le script est attaché à un RichTextLabel

# Définition des couleurs (constantes)
const COLOR_HP = "#FF0000"     # Rouge
const COLOR_SHIELD = "#8A2BE2"  # Violet
const COLOR_TARGET = "#00BFFF"  # Bleu Ciel
const COLOR_CASTER = "#FFD700"  # Jaune
const COLOR_DOT = "#008000"    # Vert

## Fonction utilitaire pour formater un tableau de noms de cibles
func format_target_names(targets: Array) -> String:
	var formatted_targets = []
	# Assurez-vous d'utiliser Array au lieu de Array[String] pour éviter les erreurs de typage
	for name in targets:
		if typeof(name) == TYPE_STRING:
			formatted_targets.append("[color=%s]%s[/color]" % [COLOR_TARGET, name])
	return ", ".join(formatted_targets)

## Fonction utilitaire pour formater un SEUL effet {value: int, type: String}
func format_single_effect(effect: Dictionary) -> String:
	var value = effect.get("damage", 0)
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
		_: # Type inconnu
			damage_color = "#FFFFFF"
			damage_tag = "Effet"

	# Format: [couleur_valeur]VALEUR[/couleur] ([couleur_tag]TAG[/couleur])
	# J'ai ajouté le tag de couleur pour le DoT, comme demandé initialement
	var formatted_value = "[color=%s]%d[/color]" % [damage_color, value]
	
	# Retourne la chaîne formatée pour cet effet : "20 HP (Rouge)" ou "5 DoT (Vert)"
	return "%s %s" % [formatted_value, damage_tag]

## Fonction principale pour formater le texte de l'événement
func log_event(event_data: Dictionary):
	
	# 1. Extraction des données
	var caster_name = event_data.get("caster_name", "Inconnu")
	var target_names = event_data.get("target_names", [])
	var effects = event_data.get("effects", []) # <-- Extraction du tableau d'effets

	# 2. Formatage du Caster et des Targets
	var formatted_caster = "[color=%s]%s[/color]" % [COLOR_CASTER, caster_name]
	var formatted_targets = format_target_names(target_names)
	var target_str = formatted_targets
	
	# 3. Formatage de TOUS les effets
	var formatted_effects_list = []
	for effect in effects:
		formatted_effects_list.append(format_single_effect(effect))
		
	# Jointure des effets avec une virgule pour la lisibilité
	var formatted_effects_str = ", ".join(formatted_effects_list)
	
	# 4. Construction de la phrase finale
	var action = ""
	var verb = "inflige"
	
	if effects.size() > 1:
		action = "effets"
	else:
		action = "effet"

	var targets_phrase = " à %s" % target_str

	if target_names.size() > 1:
		targets_phrase = " à ses cibles : %s" % target_str
		
	# Phrase : Caster inflige [Effet 1, Effet 2, ...] aux Targets
	var text_log = "%s %s les %s suivants %s: %s." % [
		formatted_caster,
		verb,
		action,
		targets_phrase,
		formatted_effects_str
	]

	# 5. Affichage du texte
	# Note: Dans ce cas, 'log_event' est appelée sur le RichTextLabel lui-même.
	self.bbcode_text = text_log

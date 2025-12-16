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
	for name in targets:
		if typeof(name) == TYPE_STRING:
			formatted_targets.append("[color=%s]%s[/color]" % [COLOR_TARGET, name.capitalize()])
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
	var action_type = event_data.get("action_type", " Action Unknown")
	# Extraction et formatage des entités (qui sont communes à toutes les actions)
	var caster_name = event_data.get("caster_name", "Catser Unkown")
	var target_names = event_data.get("target_names", [])
	
	var formatted_caster = "[color=%s]%s[/color]" % [COLOR_CASTER, caster_name.capitalize()]
	var formatted_targets = format_target_names(target_names)
	
	match action_type:
		"Damage":
			# Demande de l'utilisateur : "x inflige y degats à z"
			var effects = event_data.get("effects", [])
			
			var formatted_effects_list = []
			for effect in effects:
				formatted_effects_list.append(format_single_effect(effect))
			
			var formatted_effects_str = ", ".join(formatted_effects_list)
			
			# Phrase : [Caster] inflige [Effets (valeur + type)] à [Targets]
			if target_names.size() > 1:
				return "%s inflige les dégâts suivants à ses cibles : %s (%s)." % [formatted_caster, formatted_effects_str, formatted_targets]
			else:
				return "%s inflige %s de dégâts à %s." % [formatted_caster, formatted_effects_str, formatted_targets]

		"Death":
			
			# Nous utiliserons le premier target comme celui qui est mort.
			if target_names.size() > 0:
				return "%s est mort." % formatted_targets
			else:
				return "Une entité inconnue est morte."

		"Heal":
			# Exemple pour un futur type d'action (vous pouvez ajouter une couleur pour les soins ici)
			var effects = event_data.get("effects", [])
			var formatted_effects_list = []
			for effect in effects:
				# Si vous voulez une couleur spécifique pour les soins (ex: Bleu clair)
				# Vous devriez modifier format_single_effect pour gérer un type "Heal"
				formatted_effects_list.append(format_single_effect(effect))
			
			var formatted_effects_str = ", ".join(formatted_effects_list)
			
			return "%s soigne %s pour %s points." % [formatted_caster, formatted_targets, formatted_effects_str]
			
		_:
			return "Événement de log non reconnu: %s" % str(event_data)

## Fonction principale pour formater et afficher le texte de l'événement
func log_event(event_data: Dictionary):
	var text_log = build_log_message(event_data)
	self.bbcode_text = text_log

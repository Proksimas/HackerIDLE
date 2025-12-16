# Remplacez "RichTextLabel" par le chemin d'accès à votre nœud RichTextLabel
extends RichTextLabel

# Définition des couleurs (constantes)
const COLOR_HP = "#FF0000"     # Rouge
const COLOR_SHIELD = "#8A2BE2"  # Violet
const COLOR_TARGET = "#00BFFF"  # Bleu Ciel
const COLOR_CASTER = "#FFD700"  # Jaune
const COLOR_DOT = "#008000"    # Vert (Pour le type de dégât DoT)

## Fonction utilitaire pour formater un tableau de noms avec la couleur cible
func format_target_names(targets: Array) -> String:
	var formatted_targets = []
	# Applique la balise de couleur à chaque nom
	for name in targets:
		formatted_targets.append("[color=%s]%s[/color]" % [COLOR_TARGET, name])
	
	# Joint les noms
	return ", ".join(formatted_targets)

## Fonction principale pour formater le texte de l'événement à partir d'un dictionnaire
func log_event(event_data: Dictionary):
	var text_log = ""
	
	# 1. Extraction des données (avec valeurs par défaut si certaines clés sont manquantes)
	var caster_name = event_data.get("caster_name", "Inconnu")
	var target_names = event_data.get("target_names", [])
	var damage = event_data.get("damage", 0)
	var damage_type = event_data.get("damage_type", "HP") # HP par défaut

	# 2. Formatage du Caster
	var formatted_caster = "[color=%s]%s[/color]" % [COLOR_CASTER, caster_name]
	
	# 3. Formatage de la valeur et du type de dégât (Gestion des couleurs selon damage_type)
	var damage_color = ""
	var damage_tag = ""
	
	match damage_type:
		"HP":
			damage_color = COLOR_HP
			damage_tag = "dégâts HP"
		"Shield":
			damage_color = COLOR_SHIELD
			damage_tag = "points de Shield"
		"DoT":
			damage_color = COLOR_DOT
			damage_tag = "dégâts DoT"
		_: # Type inconnu
			damage_color = "#FFFFFF" # Blanc par défaut
			damage_tag = "effet(s)"

	var formatted_damage = "[color=%s]%d[/color]" % [damage_color, damage]

	# 4. Formatage du(des) Target(s)
	var formatted_targets = format_target_names(target_names)
	
	# TODO
	# 5. Construction de la phrase
	var verb = "inflige"
	var target_str = formatted_targets
	
	if target_names.size() > 1:
		# Ajout d'une marque de pluriel ou ajustement pour les cibles multiples
		verb = "inflige" # Reste le même car le sujet est au singulier (caster)
		text_log = "%s %s %s de %s à ses cibles : %s" % [formatted_caster, verb, formatted_damage, damage_tag, target_str]
	else:
		text_log = "%s %s %s de %s à %s" % [formatted_caster, verb, formatted_damage, damage_tag, target_str]

	# 6. Ajouter le texte au RichTextLabel
	self.text = text_log



var event_hp = {
	"caster_name": "Mage de Feu",
	"target_names": ["Guerrier", "Archer"],
	"damage": 15,
	"damage_type": "HP"
}

var event_dot = {
	"caster_name": "Poison",
	"target_names": ["Guerrier"],
	"damage": 3,
	"damage_type": "DoT"
}

var event_shield = {
	"caster_name": "Prêtre",
	"target_names": ["Tank"],
	"damage": 10,
	"damage_type": "Shield"
}

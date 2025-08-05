# TimeManager.gd
extends Node


# Durée totale de la simulation en années
@export var total_years: int = 62
# Durée réelle d'une session de jeu en minutes
@export var session_minutes: float = 52.0
# Année de départ dans la simulation
@export var start_year: int = 1980

## VALEURS CALCULÉES (internes au script)
# Facteur de mise à l'échelle du temps (temps de jeu / temps réel)
var time_scale: float
# Temps de jeu écoulé en secondes
var game_seconds: int = 0
var yesterday: int

## CONSTANTES (pour améliorer la lisibilité et la maintenance)
const SECONDS_PER_DAY: int = 86400 # 24 * 60 * 60
const DAYS_PER_YEAR: int = 365
const SECONDS_PER_HOUR: int = 3600 # 60 * 60
const SECONDS_PER_MINUTE: int = 60
const MONTH_LENGTHS: Array[int] = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

## SIGNAUX
# Émis à chaque mise à jour de la date, avec les composants de la date [année, mois, jour, heure, minute]
signal s_date(date_array: Array)

## Initialisation et Boucle Principale

func _ready() -> void:
	"""Initialise l'échelle de temps et l'affichage de la date au démarrage."""
	# Calcul du temps réel total en secondes pour une session
	var real_seconds_total: float = session_minutes * SECONDS_PER_MINUTE
	# Calcul du temps de jeu total en secondes sur la durée des `total_years`
	var game_seconds_full: float = float(total_years) * DAYS_PER_YEAR * SECONDS_PER_DAY
	
	# La `time_scale` est le rapport entre le temps de jeu et le temps réel.
	# Utilisation de `float()` pour assurer une division flottante précise.
	time_scale = game_seconds_full / real_seconds_total
	
	# Initialise l'affichage de la date dès le début du jeu
	_update_date_display()

func _process(delta: float) -> void:
	"""Fait avancer le temps de jeu à chaque frame et met à jour l'affichage."""
	# Avance le temps de jeu de manière fluide, basé sur le temps réel (`delta`) et l'échelle de temps
	game_seconds += int(delta * time_scale)
	
	# Met à jour l'affichage de la date
	_update_date_display()
	
	# Vérifie si la session est terminée
	if float(game_seconds) >= float(total_years) * DAYS_PER_YEAR * SECONDS_PER_DAY:
		end_session()


## Fonctions de Calcul et d'Affichage

func _update_date_display() -> void:
	"""Calcule la date et l'heure actuelles et émet le signal `s_date`."""
	# Nombre de jours écoulés depuis le début de la simulation
	var days_since_start: int = int(game_seconds / float(SECONDS_PER_DAY))
	
	# Année actuelle (peut inclure une partie décimale pour la précision avant l'arrondi final)
	var current_year_float: float = float(start_year) + float(days_since_start) / DAYS_PER_YEAR
	# L'année affichée est un entier
	var current_year: int = int(current_year_float)
	
	# Jour dans l'année (1 à 365)
	var day_of_current_year: int = days_since_start % DAYS_PER_YEAR + 1
	
	# Conversion du jour de l'année en mois et jour
	var month_day_array: Array = _day_to_month_day(day_of_current_year)
	var current_month: int = month_day_array[0]
	var current_day: int
	var another_day: bool
	if month_day_array[1] != yesterday:
		current_day = month_day_array[1]
		yesterday = current_day
		another_day = true
	else:
		another_day = false
	# Calcul de l'heure et des minutes dans la journée actuelle
	var seconds_today: int = game_seconds % SECONDS_PER_DAY
	var _current_hour: int = int(seconds_today / float(SECONDS_PER_HOUR))
	var _current_minute: int = int(seconds_today % SECONDS_PER_HOUR / float(SECONDS_PER_MINUTE))
	
	# Émission du signal, si changement de jour
	if another_day:
		s_date.emit([current_year, current_month, current_day]) #, _current_hour, _current_minute])

func _day_to_month_day(doy: int) -> Array:
	"""Convertit un jour de l'année (1-365) en un couple [mois, jour]."""
	var current_doy: int = doy # Utilise une copie pour ne pas modifier l'original
	for m_idx in range(MONTH_LENGTHS.size()):
		if current_doy <= MONTH_LENGTHS[m_idx]:
			return [m_idx + 1, current_doy] # m_idx + 1 pour un mois basé sur 1
		current_doy -= MONTH_LENGTHS[m_idx]
	
	# Cas limite : Si `doy` est supérieur à 365 ou une valeur inattendue,
	# ce qui ne devrait normalement pas arriver avec `days_since_start % DAYS_PER_YEAR + 1`.
	printerr("Erreur: Jour de l'année invalide ou hors limites: ", doy)
	return [12, MONTH_LENGTHS[11]] # Retourne le 31 décembre comme valeur par défaut de sécurité

## Fonctions de Contrôle de Session

func get_formatted_date_string(date_array: Array) -> String:
	""" formate une date qui est en style [année, mois, jour] """
	if date_array.size() != 3:
		push_warning("Taille du tableau de la date incorrect")
		# Gère le cas où le tableau n'a pas la bonne taille pour éviter les erreurs.
		return ""
	var year = str(date_array[0])
	var month = "%02d" % date_array[1]
	var day = "%02d" % date_array[2]

	return year + "-" + month + "-" + day

func end_session() -> void:
	"""Appelée lorsque le temps de jeu atteint la fin de la durée totale."""
	# Arrête le traitement du processus pour éviter les calculs inutiles
	set_process(false)
	
	print("SESSION TERMINÉE")
	# TODO: Implémente ici la logique de fin de session (ex: écran de score, options de rebirth, etc.)
	pass

func reset(_session_minutes: float = -1.0) -> void:
	"""
	Réinitialise le temps de jeu à zéro.
	Si `_session_minutes` est fourni et > 0, la durée de session est mise à jour et la `time_scale` recalculée.
	"""
	if _session_minutes > 0:
		session_minutes = _session_minutes
		# Si la durée de session change, il faut recalculer la `time_scale`
		_ready() # Appel `_ready()` pour re-calculer `time_scale` avec la nouvelle `session_minutes`
	else:
		# Si la durée ne change pas, juste réinitialiser les secondes et mettre à jour l'affichage
		game_seconds = 0
		_update_date_display()
	
	# S'assure que le processus est actif après un reset
	set_process(true)

func _save_data() -> Dictionary:
	"""Retourne un dictionnaire des variables importantes pour la sauvegarde et le chargement."""
	# Vous devrez implémenter la logique de sauvegarde manuellement ici
	# ou intégrer un système de sérialisation comme celui de `Global.get_serialisable_vars(self)`
	# si vous en avez un.
	
	return {
		"game_seconds": game_seconds,
		"total_years": total_years,
		"session_minutes": session_minutes,
		"start_year": start_year
	}

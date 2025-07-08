# TimeManager.gd
extends Node

# paramètres exportés pour ajuster en éditeur
@export var total_years        : float = 62.0
@export var session_minutes   : float = 52  # remplacez 30 par votre x
@export var start_year        : int   = 1980      # année de départ dans la partie

# valeurs calculées
var time_scale   : float
var game_seconds : float = 0.0

signal s_date(array)

func _ready():
	var real_seconds    = session_minutes * 60.0
	var game_seconds_full = total_years * 365 * 86400.0
	time_scale = game_seconds_full / real_seconds

func _process(delta):
	# avancer le temps de jeu
	game_seconds += delta * time_scale
	# mettre à jour l’affichage
	_update_date_display()

func _update_date_display():
	var days       = int(game_seconds / 86400)        # nb de jours écoulés
	var year       = start_year + days / 365          # année (float)
	var day_of_year= days % 365 + 1                    # jour dans l’année [1…365]

	var md = _day_to_month_day(day_of_year)
	# extraction manuelle
	var month = md[0]
	var day   = md[1]
	var sec_today = int(game_seconds) % 86400
	var hour       = sec_today / 3600
	var minute     = sec_today % 3600 / 60

	# formatez comme vous voulez
	var date_text = "%04d-%02d-%02d %02d:%02d" % [
		year, month, day, hour, minute
	]
	s_date.emit([year, month, day, hour, minute])

# conversion d’un jour de l’année en mois/jour
func _day_to_month_day(doy:int) -> Array:
	var month_lengths = [31,28,31,30,31,30,31,31,30,31,30,31]
	var m = 0
	while m < 12:
		if doy <= month_lengths[m]:
			return [m+1, doy]
		doy -= month_lengths[m]
		m += 1
	return [12, month_lengths[11]]  # cas limite
	
func end_session():
	"""on a atteind la fin de la session. Envoyons l'écran de fin de sessions.
	Il faut check si la force de hacking est suffisante, et voir pour le rebirth"""
	
	pass
	
func _save_data():
	var all_vars = Global.get_serialisable_vars(self)
	return all_vars

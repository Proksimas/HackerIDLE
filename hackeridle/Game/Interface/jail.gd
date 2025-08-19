extends Control

var min_time_in_jail: float = 300 #en seconde
var max_time_in_jail: float = 6000 

var min_year_in_jail: int = 2
var max_year_i_jail: int = 5
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func enter_jail():
	
	var wait_time_in_jail = randi_range(min_time_in_jail, max_time_in_jail)
	var years_in_jail = randi_range(min_year_in_jail, max_year_i_jail)
	
	var real_seconds_total: float = wait_time_in_jail * TimeManager.SECONDS_PER_MINUTE
	# Calcul du temps de jeu total en secondes sur la durée des `total_years`
	var game_seconds_full: float = float(years_in_jail) * TimeManager.DAYS_PER_YEAR * TimeManager.SECONDS_PER_DAY
	
	# La `time_scale` est le rapport entre le temps de jeu et le temps réel.
	# Utilisation de `float()` pour assurer une division flottante précise.
	var time_scale = game_seconds_full / real_seconds_total

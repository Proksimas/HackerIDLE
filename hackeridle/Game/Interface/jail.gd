extends Control

#le temps réel pour le joueur en prison
var min_time_in_jail: float = 5 #en MIN
var max_time_in_jail: float = 10

#la correspondance en minute
var min_year_in_jail: int = 2
var max_year_i_jail: int = 5

var old_time_scale

var is_in_jail: bool = false

@onready var in_jail_label: Label = %InJailLabel
@onready var purge_title: Label = %PurgeTitle
@onready var purge_years: Label = %PurgeYears
@onready var jail_timer: Timer = %JailTimer

var years_in_jail: int = 0


func enter_jail():
	if is_in_jail:
		return
	print("entre dans la prison")
	self.show()
	#self.set_process_mode(Node.ProcessMode.PROCESS_MODE_INHERIT)
	is_in_jail = true

	years_in_jail = randi_range(min_year_in_jail, max_year_i_jail)
	in_jail_label.text = tr("$were_in_jail")
	purge_title.text = str(years_in_jail) + " " + tr("$years_left")
	
	TimeManager.game_seconds += years_in_jail *\
		TimeManager.SECONDS_PER_DAY * TimeManager.DAYS_PER_YEAR
	#on réinitialise l'infamy à 0
	StatsManager.add_infamy(0-StatsManager.infamy["current_value"])
	# on met le jeu en pause juste pour que le joueur ne clic pas ailleurs sas faire exprès
	# mais le node actuel ne doit pas!
	#self.set_process_mode(Node.ProcessMode.PROCESS_MODE_ALWAYS)
	
	# ATTENTION En cas de bug avec la prison, on peut arreter de mettre le jeu en pause.
	get_tree().paused = true
	jail_timer.start()


	

func _on_jail_timer_timeout() -> void:
	get_tree().paused = false
	is_in_jail = false
	print("on sort de la prison")
	pass # Replace with function body.

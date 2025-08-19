extends Control
@onready var jail_timer: Timer = %JailTimer

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

var years_in_jail: int = 0


func enter_jail():
	self.show()

	is_in_jail = true

	years_in_jail = randi_range(min_year_in_jail, max_year_i_jail)
	in_jail_label.text = tr("$were_in_jail")
	purge_title.text = str(years_in_jail) + " " + tr("$years_left")
	
	TimeManager.game_seconds += years_in_jail *\
		TimeManager.SECONDS_PER_DAY * TimeManager.DAYS_PER_YEAR
	StatsManager.add_infamy(0-StatsManager.infamy["current_value"])
	
	# ICI ON AVAIT UN CODE QUI FIT ATTENDRE LE JOUEUR
	#var wait_time_in_jail = randf_range(min_time_in_jail, max_time_in_jail)
	#var years_in_jail = randi_range(min_year_in_jail, max_year_i_jail)
	#
	##On doit changer les reelles secondes, qui sont maintenant celles en prison
	#var real_seconds_total: float = snapped(wait_time_in_jail * TimeManager.SECONDS_PER_MINUTE, 1)
	#
	#var game_seconds_in_jail: float = years_in_jail * TimeManager.DAYS_PER_YEAR * TimeManager.SECONDS_PER_DAY
#
	##acceleration grace aux nouvelles secondes. Il faut anticiper la fin, qui correspond
	## au hears in jail
#
	#var time_scale = game_seconds_in_jail / real_seconds_total
	##var during_time = 
	#old_time_scale = TimeManager.time_scale 
	#TimeManager.time_scale = time_scale
	#jail_timer.wait_time = real_seconds_total
	#if !jail_timer.timeout.is_connected(_on_jail_timeout):
		#jail_timer.timeout.connect(_on_jail_timeout.bind(old_time_scale))
	
	#
#func _on_jail_timeout(old_time_scale):
	#"""La prison est finie"""
	#print("Jail finito")


	

extends Control

#le temps réel pour le joueur en prison
var min_time_in_jail: float = 5 #en MIN
var max_time_in_jail: float = 10

#la correspondance en minute
var min_year_in_jail: int = 2
var max_year_i_jail: int = 5
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#enter_jail()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func enter_jail():
	print("enter_jail")
	
	var wait_time_in_jail = randf_range(min_time_in_jail, max_time_in_jail)
	var years_in_jail = randi_range(min_year_in_jail, max_year_i_jail)
	
	#On doit changer les reelles secondes, qui sont maintenant celles en prison
	var real_seconds_total: float = snapped(wait_time_in_jail * TimeManager.SECONDS_PER_MINUTE, 1)
	
	var game_seconds_in_jail: float = years_in_jail * TimeManager.DAYS_PER_YEAR * TimeManager.SECONDS_PER_DAY

	#acceleration grace aux nouvelles secondes. Il faut anticiper la fin, qui correspond
	# au hears in jail

	var time_scale = game_seconds_in_jail / real_seconds_total
	#var during_time = 
	var old_time_scale = TimeManager.time_scale 
	TimeManager.time_scale = time_scale
	get_tree().create_timer(real_seconds_total).timeout.connect(_on_jail_timeout.bind(old_time_scale))
	
	
func _on_jail_timeout(old_time_scale):
	"""La prison est finie"""
	print("Jail finito")
	TimeManager.time_scale = old_time_scale
	
	
	
	

	

extends PanelContainer

@onready var text_label: Label = %TextLabel
@onready var infamy_value: Label = %InfamyValue
@onready var infamy_stats: Panel = %InfamyStats
@onready var infamy_effects: GridContainer = %InfamyEffects
@onready var treshold_name_label: Label = %TresholdNameLabel

@export var scroll_speed_pixels_per_second: float = 100.0 
@export var scrolling_time: int = 2

const GENERIC = "res://Game/News/TextFiles/generic.csv"
const BULLET_POINT = preload("res://Game/Interface/Specials/bullet_point.tscn")

var scroll_starting: bool = false
var news_size
var breaking_news = null

var nb_of_msg = {"introduction": 2,   # key_de_la_traduction : nb of message associés
				"random": 1
}

signal news_finished

func _ready() -> void:	
	news_size = text_label.size.x
	new_news(pick_random_sentence("introduction"))
	StatsManager.s_add_infamy.connect(_on_s_add_infamy)
	StatsManager.s_infamy_effect_added.connect(draw_infamy_stats)
	TimeManager.s_date.connect(_on_s_date)  
	_on_s_add_infamy(StatsManager.infamy["current_value"])
	infamy_stats.hide()
	pass # Replace with function body.


func _process(_delta: float) -> void:
	if scroll_starting:
		# Calculer le déplacement basé sur le temps écoulé (delta)
		var move_amount = scroll_speed_pixels_per_second * _delta
		# Déplacer le texte vers la gauche
		text_label.position.x -= move_amount

		if text_label.position.x <= 0 - text_label.get_minimum_size().x:
			scroll_starting = false
			news_finished.emit()
			text_label.position.x = get_viewport_rect().size.x
	
func new_news(news_key: String):
	text_label.text = tr(news_key)
	text_label.position.x = get_viewport_rect().size.x
	text_label.position = Vector2(news_size, text_label.position.y)
	self.news_finished.connect(_on_news_finished.bind(news_key))
	scroll_starting = true
	
	pass
	
func pick_random_sentence(key: String):
	if !nb_of_msg.has(key):
		push_error("La clé de traduction n'est pas valide.")
	var random =randi_range(1, nb_of_msg[key])
	
	return (key + "_" + str(random))
	
func _on_news_finished(news_key):
	self.news_finished.disconnect(_on_news_finished)
	change_state(news_key)
	
	pass

func _on_s_date(date):
	var formatted_date_1: String = "%s-%s-%s" % [date[0], date[1], date[2]]
	var has_trad = tr(formatted_date_1)
	if has_trad != formatted_date_1: # il y a une traduction
		# TODO
		print(tr(formatted_date_1))


func change_state(current_state: String):
	if breaking_news != null:
		breaking_news = null
		return breaking_news  #c'est le moment de la breaking news
		
	var splitted = current_state.split("_")[0]
	match splitted:
		"introduction":
			new_news(pick_random_sentence("random"))
		"random":
			new_news(pick_random_sentence("random"))
			
#region INFAMY


## On gère l'infamie

	
func _on_s_add_infamy(_infamy_value):
	infamy_value.text = str(_infamy_value)
	

func _on_infamy_icon_pressed() -> void:
	infamy_stats.visible = !infamy_stats.visible
	pass # Replace with function body.

func draw_infamy_stats():
	"""Dessine les caractéristiques liées à l'infamie actuelle"""
	for effect in infamy_effects.get_children():
		effect.queue_free()
		
	treshold_name_label.text = tr("$" + StatsManager.INFAMY_NAMES.get(StatsManager.get_infamy_treshold()))
	var _hack_modifiers = StatsManager.hack_modifiers
	var _translations:Array = []
	for stat: StatsManager.Stats in _hack_modifiers:
		if _hack_modifiers[stat].is_empty():
			continue
			
		var hack_dicts = _hack_modifiers[stat]
		var value: float
		var has_value: bool = false
		for dict in hack_dicts:
			if dict["source"].begins_with("infamy_"):
				value = dict["value"] * 100
				has_value = true
				
		if has_value == false:
			push_warning("Pas valeur trouvée, pas normal ")
			return
		
		var value_str: String
		if value > 0:
			value_str = "+%s" % str(value)
		elif value < 0:
			value_str = "-%s" % str(abs(value))
		else:
			value_str = ""
		_translations.append(tr("hack_" + StatsManager.STATS_NAMES.get(stat)).\
				format({"hack_" + StatsManager.STATS_NAMES.get(stat) + "_value": value_str}))
	
	for trad in _translations:
		var bullet_label = BULLET_POINT.instantiate()
		infamy_effects.add_child(bullet_label)
		bullet_label.set_bullet_point(trad)

	#

func _draw():
	infamy_value.text = str(StatsManager.infamy["current_value"])
	treshold_name_label.text = tr("$" + StatsManager.INFAMY_NAMES.get(StatsManager.get_infamy_treshold()))

func _on_cheat_infamy_pressed() -> void:
	StatsManager.add_infamy(5)
	pass # Replace with function body.


func _on_cheat_infamy_2_pressed() -> void:
	StatsManager.add_infamy(-5)
	pass # Replace with function body.
#endregion

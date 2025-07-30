extends Panel

@onready var text_label: Label = %TextLabel
@onready var infamy_value: Label = %InfamyValue
@onready var infamy_stats: Panel = %InfamyStats
@onready var infamy_effects: GridContainer = %InfamyEffects

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
	#TimeManager.s_date.connect(_on_s_date)  # -> Interface
	_on_s_add_infamy(StatsManager.infamy["current_value"])
	infamy_stats.hide()
	pass # Replace with function body.


func _process(_delta: float) -> void:
	if scroll_starting and text_label.position.x > 0 - text_label.size.x:
		text_label.position -= Vector2(scrolling_time, 0)
		
	elif scroll_starting and text_label.position.x <= 0 - text_label.size.x: 
		scroll_starting = false
		news_finished.emit()
		
	pass
	
func new_news(news_key: String):
	text_label.text = tr(news_key)
	text_label.position.x = self.size.x
		
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
	
func _on_s_add_infamy(_infamy_value):
	infamy_value.text = str(_infamy_value)
	draw_infamy_stats()

func _on_infamy_icon_pressed() -> void:
	infamy_stats.visible = !infamy_stats.visible
	pass # Replace with function body.

func draw_infamy_stats():
	for effect in infamy_effects.get_children():
		effect.queue_free()


func _on_cheat_infamy_pressed() -> void:
	StatsManager.add_infamy(1)
	pass # Replace with function body.


func _on_cheat_infamy_2_pressed() -> void:
	StatsManager.add_infamy(-1)
	pass # Replace with function body.

func _draw():
	_on_s_add_infamy(StatsManager.infamy["current_value"])

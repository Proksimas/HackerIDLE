extends Panel

@onready var text_label: Label = %TextLabel

@export var scrolling_time: int = 10
var news_size
const GENERIC = "res://Game/News/TextFiles/generic.csv"

var nb_of_msg = {"introduction": 2,   # key_de_la_traduction : nb of message associés
				"random": 1
}

func _ready() -> void:
	news_size = text_label.size.x
	new_news(pick_random_sentence("random"))
	pass # Replace with function body.



func new_news(_text: String):
	text_label.text = _text
	text_label.position.x = self.size.x
	start_scrolling()
	pass
	
func pick_random_sentence(key: String):
	if !nb_of_msg.has(key):
		push_error("La clé de traduction n'est pas valide.")
	var random =randi_range(1, nb_of_msg[key])
	
	return tr(key + "_" + str(random))
	
	pass
	

func start_scrolling():
	var tween = get_tree().create_tween()
	tween.tween_property(text_label, "position", 
						Vector2(0 - text_label.size.x, text_label.position.y), 
						scrolling_time).from(Vector2(news_size, text_label.position.y))
	tween.set_loops() #pas d'arugument = infini
	tween.finished.connect(_on_tween_finished)
	
func _on_tween_finished():
	
	pass

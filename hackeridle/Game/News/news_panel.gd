extends Panel

@onready var text_label: Label = %TextLabel

@export var scrolling_time: int = 10
var news_size: int
func _ready() -> void:
	news_size = self.size.x
	new_news("Aujourd'hui j'aime pas Stephen")
	pass # Replace with function body.


func new_news(_text: String):
	text_label.text = _text
	text_label.position.x = news_size
	start_scrolling()
	pass
	
	
	
	
func start_scrolling():
	var tween = get_tree().create_tween()
	tween.tween_property(text_label, "position", 
						Vector2(0 - news_size, text_label.position.y), 
						scrolling_time).from(Vector2(news_size, text_label.position.y))
	tween.set_loops() #pas d'arugument = infini
	tween.finished.connect(_on_tween_finished)
	
func _on_tween_finished():
	
	pass

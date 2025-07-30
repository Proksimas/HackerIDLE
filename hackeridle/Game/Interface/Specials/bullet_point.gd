extends HBoxContainer

@onready var text_label: Label = %TextLabel


func set_bullet_point(_text: String, has_autowrap: bool = false, _width:float = 150):
	if has_autowrap:
		text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		self.size.x = _width
	else:
		text_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	text_label.text = _text

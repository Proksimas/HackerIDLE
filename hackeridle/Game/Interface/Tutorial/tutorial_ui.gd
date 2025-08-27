extends PanelContainer
class_name TutorialUI


@onready var text_label: Label = %TextLabel
@onready var arrows: Control = %Arrows
@onready var arrow_center_down: TextureRect = %ArrowCenterDown
@onready var arrow_right_down: TextureRect = %ArrowRightDown
@onready var arrow_left_down: TextureRect = %ArrowLeftDown


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func set_tutorial_ui(_text: String, _pos: Vector2, arrow_show: String = "no_arrow"):
	hide_arrows()
	text_label.text = tr(_text)
	global_position = _pos
	if arrow_show == "no_arrow":
		arrows.hide()
		return
	arrows.show()
	match arrow_show:
		"center_down":
			arrow_center_down.show()
		"right_down":
			arrow_right_down.show()
		"left_down":
			arrow_left_down.show()
	
func hide_arrows():
	for arrow in arrows.get_children():
		arrow.hide()
	
func tutorial_step_finished():
	self.hide()
	self.queue_free()
	pass

extends Control

@onready var reward_title: Label = %RewardTitle
@onready var watching_video: Label = %WatchingVideo

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.




func _on_draw() -> void:
	reward_title.text = tr("watching_video")
	watching_video.text = tr("watching_video_des")
	pass # Replace with function body.

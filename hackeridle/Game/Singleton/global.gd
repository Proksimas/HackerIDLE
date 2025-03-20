extends Node

var knowledge_point: float:
	set(value):
		return clamp(value, 0, INF)
		
var hacking_point: float:
	set(value):
		return clamp(value, 0, INF)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

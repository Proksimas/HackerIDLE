extends TextureButton

class_name RewardPresentTexture

signal reward_present_deleted(was_clicked: bool)

const WATCHING_VIDEO = preload("res://Game/Publicity/WatchingVideoPanel.tscn")

const MIN_PULSE_SCALE := Vector2(0.92, 0.92)
const MAX_PULSE_SCALE := Vector2(1.12, 1.12)
const PULSE_DURATION := 0.55
const ROTATION_SWAY_DEGREES := 6.0
const ROTATION_SWAY_DURATION := 0.85
const FALL_DURATION := 18.0
const FALL_DURATION_VARIATION := 0.2

var time_to_move: float
var _opened := false
var _deleted := false
var _pulse_tween: Tween = null
var _rotation_tween: Tween = null


func _ready() -> void:
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)
	pivot_offset = size * 0.5


func item_moving(_pos: Vector2, _size: Vector2) -> void:
	var min_x := int(_pos.x)
	var max_x := int(_pos.x + _size.x - size.x)
	var random_x := randi_range(min_x, max_x)
	var start_y := _pos.y - size.y

	global_position = Vector2(random_x, start_y)
	rotation_degrees = randf_range(-20.0, 20.0)
	time_to_move = FALL_DURATION * randf_range(1.0 - FALL_DURATION_VARIATION, 1.0 + FALL_DURATION_VARIATION)
	_start_attention_pulse()
	_start_rotation_sway()

	var end_y := _pos.y + _size.y
	var end_pos := Vector2(random_x, end_y)

	get_tree().create_timer(time_to_move - 2).timeout.connect(_on_timeout)

	var fade_in := get_tree().create_tween()
	fade_in.tween_property(self, "modulate", Color(1, 1, 1, 0.9), 2).from(Color(1, 1, 1, 0))

	var tween := get_tree().create_tween()
	tween.finished.connect(_on_tween_finished)
	tween.tween_property(self, "global_position", end_pos, time_to_move).from(global_position)


func _on_pressed() -> void:
	if _opened:
		return
	_opened = true
	_open_watching_video_panel()
	_delete_present(true)


func _open_watching_video_panel() -> void:
	var new_reward := WATCHING_VIDEO.instantiate()
	var interface := get_tree().get_root().get_node_or_null("Main/Interface")
	if interface != null:
		interface.add_child(new_reward)
	elif get_tree().current_scene != null:
		get_tree().current_scene.add_child(new_reward)
	else:
		get_tree().root.add_child(new_reward)
	new_reward.show()


func _on_tween_finished() -> void:
	_delete_present(false)


func _on_timeout() -> void:
	var tween := get_tree().create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 2).from(modulate)


func _delete_present(was_clicked: bool) -> void:
	if _deleted:
		return
	_deleted = true
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	if _rotation_tween != null and _rotation_tween.is_valid():
		_rotation_tween.kill()
	reward_present_deleted.emit(was_clicked)
	queue_free()


func _start_attention_pulse() -> void:
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	scale = Vector2.ONE
	_pulse_tween = create_tween()
	_pulse_tween.set_loops()
	_pulse_tween.tween_property(self, "scale", MAX_PULSE_SCALE, PULSE_DURATION)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(self, "scale", MIN_PULSE_SCALE, PULSE_DURATION)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_IN_OUT)


func _start_rotation_sway() -> void:
	if _rotation_tween != null and _rotation_tween.is_valid():
		_rotation_tween.kill()
	var base_rotation := rotation_degrees
	_rotation_tween = create_tween()
	_rotation_tween.set_loops()
	_rotation_tween.tween_property(self, "rotation_degrees", base_rotation + ROTATION_SWAY_DEGREES, ROTATION_SWAY_DURATION)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_IN_OUT)
	_rotation_tween.tween_property(self, "rotation_degrees", base_rotation - ROTATION_SWAY_DEGREES, ROTATION_SWAY_DURATION)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_IN_OUT)

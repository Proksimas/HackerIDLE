extends Control

const REWARD_PRESENT_SCENE = preload("res://Game/Interface/Items/reward_present_texture.tscn")

var active_reward_present: RewardPresentTexture = null
var shorten_next_interval := false


func _ready() -> void:
	_schedule_next_reward_present()


func _schedule_next_reward_present() -> void:
	var interval_base := AdsManager.TIME_BETWEEN_PUBLICITY
	if shorten_next_interval:
		interval_base /= 2.0
		shorten_next_interval = false
	var interval := interval_base * randf_range(0.8, 1.2)
	get_tree().create_timer(interval).timeout.connect(_on_reward_present_timer_timeout)


func _on_reward_present_timer_timeout() -> void:
	if active_reward_present != null and is_instance_valid(active_reward_present):
		_schedule_next_reward_present()
		return
	_spawn_reward_present()


func _spawn_reward_present() -> void:
	var new_present: RewardPresentTexture = REWARD_PRESENT_SCENE.instantiate()
	add_child(new_present)
	active_reward_present = new_present
	new_present.reward_present_deleted.connect(_on_reward_present_deleted)
	new_present.item_moving(global_position, size)


func _on_reward_present_deleted(was_clicked: bool) -> void:
	active_reward_present = null
	shorten_next_interval = not was_clicked
	_schedule_next_reward_present()

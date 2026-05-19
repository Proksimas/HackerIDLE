extends Control

const REWARD_PRESENT_SCENE = preload("res://Game/Interface/Items/reward_present_texture.tscn")

@onready var all_container: VBoxContainer = %AllContainer

var active_reward_present: RewardPresentTexture = null
var next_interval_base := AdsManager.TIME_BETWEEN_PUBLICITY


func _ready() -> void:
	_schedule_next_reward_present()


func _schedule_next_reward_present() -> void:
	var interval := next_interval_base * randf_range(0.8, 1.2)
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
	new_present.item_moving(all_container.global_position, all_container.size)


func _on_reward_present_deleted(was_clicked: bool) -> void:
	active_reward_present = null
	if was_clicked:
		next_interval_base = AdsManager.TIME_BETWEEN_PUBLICITY
	else:
		next_interval_base = AdsManager.TIME_BETWEEN_PUBLICITY / 2.0
	_schedule_next_reward_present()

extends Control

const REWARD_PRESENT_SCENE = preload("res://Game/Interface/Items/reward_present_texture.tscn")

@onready var all_container: VBoxContainer = %AllContainer

var active_reward_present: RewardPresentTexture = null


func _ready() -> void:
	_schedule_next_reward_present()


func _schedule_next_reward_present() -> void:
	var interval := AdsManager.TIME_BETWEEN_PUBLICITY * randf_range(0.8, 1.2)
	get_tree().create_timer(interval).timeout.connect(_on_reward_present_timer_timeout)


func _on_reward_present_timer_timeout() -> void:
	if active_reward_present == null or not is_instance_valid(active_reward_present):
		_spawn_reward_present()
	_schedule_next_reward_present()


func _spawn_reward_present() -> void:
	var new_present: RewardPresentTexture = REWARD_PRESENT_SCENE.instantiate()
	add_child(new_present)
	active_reward_present = new_present
	new_present.reward_present_deleted.connect(_on_reward_present_deleted)
	new_present.item_moving(all_container.global_position, all_container.size)


func _on_reward_present_deleted() -> void:
	active_reward_present = null

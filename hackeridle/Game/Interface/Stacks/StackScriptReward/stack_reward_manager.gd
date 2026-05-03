extends RefCounted
class_name StackRewardManager

const BOSS_REWARD_GENERATOR_SCRIPT = preload("res://Game/Interface/Stacks/StackScriptReward/boss_reward_generator.gd")

const REWARD_PER_ENEMY_MIN: int = 1
const REWARD_PER_ENEMY_MAX: int = 3
const ELITE_MULTIPLIER: float = 2.0
const BOSS_MULTIPLIER: float = 3.0
const DEPTH_SCALE_K: float = 0.12

var _rng := RandomNumberGenerator.new()
var _boss_reward_generator


func _init() -> void:
	_rng.randomize()
	_boss_reward_generator = BOSS_REWARD_GENERATOR_SCRIPT.new()


func build_post_fight_rewards(victory: bool, encounter_type: String, enemy_count: int, depth: int, is_boss: bool) -> Dictionary:
	var combat_reward := 0
	var boss_rewards: Array[Dictionary] = []

	if victory and enemy_count > 0:
		combat_reward = compute_encounter_reward(encounter_type, enemy_count, depth)

	if victory and is_boss:
		boss_rewards = build_boss_rewards()

	return {
		"combat_reward": combat_reward,
		"boss_rewards": boss_rewards
	}


func compute_encounter_reward(encounter_type: String, enemy_count: int, depth: int) -> int:
	if enemy_count <= 0:
		return 0

	var base_reward := 0
	for _i in range(enemy_count):
		base_reward += _rng.randi_range(REWARD_PER_ENEMY_MIN, REWARD_PER_ENEMY_MAX)

	var type_multiplier := _type_multiplier(encounter_type)
	var depth_multiplier := 1.0 + DEPTH_SCALE_K * sqrt(float(max(1, depth)))
	var total := int(round(float(base_reward) * type_multiplier * depth_multiplier))
	return max(0, total)


func build_boss_rewards() -> Array[Dictionary]:
	if _boss_reward_generator == null:
		_boss_reward_generator = BOSS_REWARD_GENERATOR_SCRIPT.new()
	return _boss_reward_generator.build_rewards()


func _type_multiplier(encounter_type: String) -> float:
	if encounter_type == "ELITE":
		return ELITE_MULTIPLIER
	if encounter_type == "BOSS":
		return BOSS_MULTIPLIER
	return 1.0

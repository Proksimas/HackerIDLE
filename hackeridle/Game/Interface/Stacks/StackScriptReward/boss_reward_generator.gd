extends RefCounted

# Flexible reward generator for boss encounters.
# For now it builds script rewards, but the class is isolated so other
# reward families (stats, slots, currencies, relics) can be added cleanly.

const DEFAULT_MAX_REWARDS: int = 3

var max_rewards: int = DEFAULT_MAX_REWARDS
var shuffle_candidates: bool = true


func build_rewards() -> Array[Dictionary]:
	if typeof(StackManager.stack_script_pool) != TYPE_DICTIONARY or StackManager.stack_script_pool.is_empty():
		StackManager.initialize_pool()

	var candidates := _build_script_candidates()
	if shuffle_candidates:
		candidates.shuffle()

	var rewards: Array[Dictionary] = []
	var selected_script_names: Dictionary = {}
	for script_name in candidates:
		if rewards.size() >= max_rewards:
			break
		if selected_script_names.has(script_name):
			continue
		var reward := _build_script_reward(script_name)
		if reward.is_empty():
			continue
		selected_script_names[script_name] = true
		rewards.append(reward)

	return rewards


func _build_script_candidates() -> Array[String]:
	var candidates: Array[String] = []
	for script_name_variant in StackManager.stack_script_pool.keys():
		var script_name := str(script_name_variant)
		if not StackManager.can_receive_script_copy(script_name):
			continue
		candidates.append(script_name)
	return candidates


func _build_script_reward(script_name: String) -> Dictionary:
	var script_path := str(StackManager.stack_script_pool.get(script_name, ""))
	if script_path == "":
		return {}

	var script_resource = load(script_path)
	if not (script_resource is StackScript):
		return {}

	var title := script_name
	if str(script_resource.stack_script_name).strip_edges() != "" and script_resource.stack_script_name != "Script Inconnu":
		title = script_resource.stack_script_name

	return {
		"id": "%s_reward" % script_name,
		"kind": "script",
		"title": title,
		"description": TranslationServer.translate("%s_desc" % script_name),
		"script_resource": script_resource,
		"custom_payload": {
			"script_name": script_name
		}
	}

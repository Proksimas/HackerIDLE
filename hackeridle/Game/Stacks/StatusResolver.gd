extends Node
class_name StatusResolver


static func TickStartOfTurn(entity: Entity) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if entity == null or entity.self_is_dead:
		return events

	for status in entity.active_statuses:
		if not (status is Dictionary):
			continue
		var status_type := str(status.get("type", ""))
		if status_type != "DoT" and status_type != "Regen":
			continue

		var stacks: int = maxi(1, int(status.get("stacks", 1)))
		var value: float = float(status.get("value", 0.0)) * float(stacks)
		if value <= 0:
			continue

		var effect_type := "HP" if status_type == "DoT" else "HealHP"
		var action_type := "Damage" if status_type == "DoT" else "Heal"
		events.append({
			"caster": entity,
			"action_type": action_type,
			"meta": {
				"tick": true,
				"statusId": str(status.get("display_name", status.get("id", "Status"))),
				"stacks": stacks
			},
			"targetEffects": [
				{
					"target": entity,
					"effects": [
						{"type": effect_type, "value": value}
					]
				}
			]
		})

	return events


static func AdvanceDurations(entity: Entity) -> void:
	if entity == null:
		return

	for index in range(entity.active_statuses.size() - 1, -1, -1):
		var status = entity.active_statuses[index]
		if not (status is Dictionary):
			entity.active_statuses.remove_at(index)
			continue
		var turns_remaining := int(status.get("turnsRemaining", status.get("turns", 0))) - 1
		if turns_remaining <= 0:
			entity.active_statuses.remove_at(index)
		else:
			status["turnsRemaining"] = turns_remaining
			entity.active_statuses[index] = status

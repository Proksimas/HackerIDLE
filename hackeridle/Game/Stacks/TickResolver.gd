extends Node
class_name StatusResolver

static func TickStartOfTurn(entity: Entity) -> Array[Dictionary]:
	var events: Array[Dictionary] = []

	if entity == null:
		return events


	# On itère à l’envers pour pouvoir remove sans soucis
	for i in range(entity.active_statuses.size() - 1, -1, -1):
		var status: Dictionary = entity.active_statuses[i]
		var stype: String = str(status.get("type", ""))

		if stype == "DoT": #dégats classiques sur la durée
			var value: int = int(status.get("value", 0))
			var source: Entity = status.get("source", null)
			entity.take_damage(value)

			# Event compatible UI/logs
			events.append({
				"caster": source if source != null else entity,
				"action_type": "Damage",
				"targetEffects": [
					{
						"target": entity,
						"effects": [
							{"type": "HP", "value": value}
						]
					}
				],
				"meta": {
					"tick": true,
					"statusId": status.get("id", ""),
					"statusType": "DoT"
				}
			})

			# Décrémente et expire
			status["turnsRemaining"] = int(status.get("turnsRemaining", 0)) - 1
			entity.active_statuses[i] = status

			if int(status["turnsRemaining"]) <= 0:
				entity.active_statuses.remove_at(i)

		# (plus tard) else if Regen/Buff etc.

	return events

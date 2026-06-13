extends Node
class_name CombatResolver

static func resolve(action: Dictionary) -> Dictionary:
	var resolution := {
		"perTarget": [],
		"killed": []
	}

	if action.has("targetEffects"):
		var te_list: Array = action.get("targetEffects", [])
		for te in te_list:
			if not (te is Dictionary):
				continue

			var target: Entity = te.get("target", null)
			if target == null:
				continue

			var effects: Array = te.get("effects", [])
			_apply_effects_and_snapshot(action.get("caster", null), target, effects, resolution)

		action["resolution"] = resolution
		return action
	push_error("ne doit pas arriver la, carr il n'y a pas de targetEffects dans le spell. Peut etre ancien script ?")
	
	return {}
	## --- Ancien format (compatibilité) ---
	#var targets: Array = action.get("targets", [])
	#var effects: Array = action.get("effects", [])
#
	#for target in targets:
		#if target == null:
			#continue
		#_apply_effects_and_snapshot(action.get("caster", null), target, effects, resolution)
#
	#action["resolution"] = resolution
	#return action

static func _apply_effects_and_snapshot(caster: Entity, target: Entity, effects: Array, resolution: Dictionary) -> void:
	var before := {
		"hp": float(target.current_hp),
		"shield": float(target.current_shield),
		"isDead": bool(target.self_is_dead)
	}

	for effect in effects:
		if effect is Dictionary:
			_apply_effect(caster, target, effect)

	var after := {
		"hp": float(target.current_hp),
		"shield": float(target.current_shield),
		"isDead": bool(target.self_is_dead)
	}

	var delta := {
		"hpLost": max(0.0, before.hp - after.hp),
		"shieldLost": max(0.0, before.shield - after.shield),
		"hpGained": max(0.0, after.hp - before.hp),
		"shieldGained": max(0.0, after.shield - before.shield)
	}
	var reflection := _apply_proxy_redirect(caster, target, float(delta.hpLost))

	var target_resolution := {
		"target": target,
		"before": before,
		"after": after,
		"delta": delta
	}
	if not reflection.is_empty():
		target_resolution["reflection"] = reflection
	resolution["perTarget"].append(target_resolution)
	if not reflection.is_empty():
		resolution["perTarget"].append({
			"target": reflection.get("target", null),
			"before": reflection.get("before", {}),
			"after": reflection.get("after", {}),
			"delta": reflection.get("delta", {})
		})

	if (not before.isDead) and after.isDead:
		resolution["killed"].append(target)
	if not reflection.is_empty() and bool(reflection.get("killed", false)):
		resolution["killed"].append(caster)


static func _apply_proxy_redirect(attacker: Entity, defender: Entity, hp_lost: float) -> Dictionary:
	if attacker == null or defender == null or attacker == defender or hp_lost <= 0.0:
		return {}
	if attacker.self_is_dead:
		return {}

	for index in range(defender.active_statuses.size()):
		var status = defender.active_statuses[index]
		if not (status is Dictionary):
			continue
		if str(status.get("type", "")) != "ProxyRedirect":
			continue

		var redirect_ratio: float = clampf(float(status.get("value", 0.0)), 0.0, 1.0)
		var reflected_damage: float = hp_lost * redirect_ratio
		defender.active_statuses.remove_at(index)
		if reflected_damage <= 0.0:
			return {}

		var before := {
			"hp": float(attacker.current_hp),
			"shield": float(attacker.current_shield),
			"isDead": bool(attacker.self_is_dead)
		}
		var was_dead: bool = attacker.self_is_dead
		attacker.take_damage(reflected_damage)
		var after := {
			"hp": float(attacker.current_hp),
			"shield": float(attacker.current_shield),
			"isDead": bool(attacker.self_is_dead)
		}
		var delta := {
			"hpLost": maxf(0.0, float(before.hp) - float(after.hp)),
			"shieldLost": maxf(0.0, float(before.shield) - float(after.shield)),
			"hpGained": 0.0,
			"shieldGained": 0.0
		}
		return {
			"target": attacker,
			"value": reflected_damage,
			"hpLost": delta.hpLost,
			"shieldLost": delta.shieldLost,
			"before": before,
			"after": after,
			"delta": delta,
			"killed": not was_dead and attacker.self_is_dead
		}

	return {}
		
static func _apply_effect(_caster: Entity, target: Entity, effect: Dictionary) -> void:
	var effect_type: String = str(effect.get("type", ""))
	var value: float = float(effect.get("value", 0))
	if effect_type == "HP" or effect_type == "PierceHP":
		value *= _get_damage_taken_multiplier(target)

	match effect_type:
		"HP":
			if target.has_method("take_damage"):
				target.take_damage(value)
			else:
				push_error("L'entité est censé avoir le take_damage")
			
		"Shield":
			if target.has_method("add_shield"):
				target.add_shield(value)
			else:
				# fallback si tu n'as pas encore add_shield()
				push_error("L'entité est censé avoir le add_shield")
		"PierceHP":
			if target.has_method("take_pierce_damage"):
				target.take_pierce_damage(value)
			else:
				push_error("L'entité est censé avoir le take_pierce_damage")
		"HealHP":
			if target.has_method("heal"):
				target.heal(value)
			else:
				push_error("L'entité est censé avoir le heal")
		"ApplyStatus":
			var status: Dictionary = effect.get("status", {})
			if target.has_method("add_status"):
				target.add_status(status)
			else:
				push_error("L'entité est censé avoir le add_status")
		"Knowledge":
			if _caster != null and _caster.entity_is_hacker and value > 0.0:
				Player.earn_knowledge_point(value)
		_:
			pass

static func _get_damage_taken_multiplier(target: Entity) -> float:
	var multiplier := 1.0
	if target == null:
		return multiplier
	for status in target.active_statuses:
		if not (status is Dictionary):
			continue
		if str(status.get("type", "")) != "Vulnerability":
			continue
		multiplier = max(multiplier, 1.0 + max(0.0, float(status.get("value", 0.0))))
	return multiplier

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

	resolution["perTarget"].append({
		"target": target,
		"before": before,
		"after": after,
		"delta": delta
	})

	if (not before.isDead) and after.isDead:
		resolution["killed"].append(target)
		
static func _apply_effect(caster: Entity, target: Entity, effect: Dictionary) -> void:
	var effect_type: String = str(effect.get("type", ""))
	var value: float = float(effect.get("value", 0))

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
		_:
			pass

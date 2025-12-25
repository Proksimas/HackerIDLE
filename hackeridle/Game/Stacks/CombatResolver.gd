extends Node
class_name CombatResolver

static func resolve(action: Dictionary) -> Dictionary:
	var targets: Array = action.get("targets", [])
	var effects: Array = action.get("effects", [])

	# --- SNAPSHOT STRUCTURE ---
	var resolution := {
		"perTarget": [], # Array of dicts
		"killed": []     # Array[Entity] ou Array[String] selon ton choix
	}

	for target in targets:
		if target == null:
			continue

		# Snapshot "avant"
		var before := {
			"hp": float(target.current_hp),
			"shield": float(target.current_shield),
			"isDead": bool(target.self_is_dead)
		}

		# Apply all effects to this target
		for effect in effects:
			if effect is Dictionary:
				_apply_effect(action.get("caster", null), target, effect)

		# Snapshot "après"
		var after := {
			"hp": float(target.current_hp),
			"shield": float(target.current_shield),
			"isDead": bool(target.self_is_dead)
		}

		# Delta utiles UI/logs
		var delta := {
			"hpLost": max(0.0, before.hp - after.hp),
			"shieldLost": max(0.0, before.shield - after.shield),
			"hpGained": max(0.0, after.hp - before.hp),
			"shieldGained": max(0.0, after.shield - before.shield)
		}

		# Enregistrement par target
		resolution.perTarget.append({
			"target": target,
			"before": before,
			"after": after,
			"delta": delta
		})

		# Kills détectés (si passage vivant -> mort)
		if (not before.isDead) and after.isDead:
			resolution.killed.append(target)

	action["resolution"] = resolution
	return action


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

		_:
			pass

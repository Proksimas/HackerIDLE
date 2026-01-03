extends Node
class_name StatusRules

# ------------------------------------------------------------
# API publique
# ------------------------------------------------------------

static func Init(incoming: Dictionary) -> Dictionary:
	# Normalise + defaults + prépare une instance "live"
	var status := incoming.duplicate(true)

	var id := str(status.get("id", ""))
	if id == "":
		return {}

	var turns: int = int(status.get("turns", 0))
	if turns <= 0:
		return {}

	status["turnsRemaining"] = int(status.get("turnsRemaining", turns))

	# Stacks
	var max_stacks: int = _read_int(status, "maxStacks", 1)
	if max_stacks < 1:
		max_stacks = 1
	status["maxStacks"] = max_stacks

	var stacks: int = _read_int(status, "stacks", 1)
	stacks = clamp(stacks, 1, max_stacks)
	status["stacks"] = stacks

	# Stack & refresh modes
	status["stackMode"] = str(status.get("stackMode", "AddStack"))
	status["refreshMode"] = str(status.get("refreshMode", "Refresh"))

	# AddStacks (combien de stacks ajoutés par ré-application)
	var add_stacks: int = _read_int(status, "addStacks", 1)
	if add_stacks < 1:
		add_stacks = 1
	status["addStacks"] = add_stacks

	# Optionnel: cap de value (si stackMode=AddValue plus tard)
	if status.has("maxValue"):
		status["maxValue"] = float(status.get("maxValue", 0))

	return status


static func Merge(existing_in: Dictionary, incoming_in: Dictionary) -> Dictionary:
	# Fusionne un status entrant dans un status déjà actif.
	# Règles déterminées par stackMode/refreshMode/maxStacks etc.
	var existing := existing_in.duplicate(true)
	var incoming := Init(incoming_in)
	if incoming.is_empty():
		return existing

	# On merge par id (supposé déjà matché par l'appelant)
	var stack_mode: String = str(incoming.get("stackMode", existing.get("stackMode", "AddStack")))
	var refresh_mode: String = str(incoming.get("refreshMode", existing.get("refreshMode", "Refresh")))

	var max_stacks: int = int(incoming.get("maxStacks", existing.get("maxStacks", 1)))
	if max_stacks < 1:
		max_stacks = 1

	var add_stacks: int = int(incoming.get("addStacks", 1))
	if add_stacks < 1:
		add_stacks = 1

	# -------------------------
	# 1) Gestion stacks/value
	# -------------------------
	match stack_mode:
		"AddStack":
			var current_stacks: int = int(existing.get("stacks", 1))
			current_stacks = min(max_stacks, current_stacks + add_stacks)
			existing["stacks"] = current_stacks

			# On met à jour la value (souvent tu veux la value du caster le plus récent)
			if incoming.has("value"):
				existing["value"] = incoming["value"]

		"AddValue":
			var current_value: float = float(existing.get("value", 0))
			var inc_value: float = float(incoming.get("value", 0))
			var new_value: float = current_value + inc_value

			# Cap optionnel
			if incoming.has("maxValue"):
				var max_value: float = float(incoming.get("maxValue", 0))
				if max_value > 0:
					new_value = min(new_value, max_value)

			existing["value"] = new_value

			# stacks restent (optionnel) ; on les force à 1 par défaut
			if not existing.has("stacks"):
				existing["stacks"] = 1
		"NoStack":
			# On ne change ni stacks ni value
			pass
		_:
			# Fallback raisonnable : AddStack
			var cs: int = int(existing.get("stacks", 1))
			existing["stacks"] = min(max_stacks, cs + add_stacks)
			if incoming.has("value"):
				existing["value"] = incoming["value"]

	# -------------------------
	# 2) Gestion durée
	# -------------------------
	var incoming_turns: int = int(incoming.get("turns", 0))
	if incoming_turns <= 0:
		incoming_turns = int(existing.get("turns", 0))

	match refresh_mode:
		"Refresh":
			existing["turnsRemaining"] = incoming_turns
		"Extend":
			existing["turnsRemaining"] = int(existing.get("turnsRemaining", 0)) + incoming_turns
		"NoRefresh":
			pass
		_:
			existing["turnsRemaining"] = incoming_turns
	# -------------------------
	# 3) Merge métadonnées utiles
	# -------------------------
	existing["maxStacks"] = max_stacks
	existing["stackMode"] = stack_mode
	existing["refreshMode"] = refresh_mode
	existing["addStacks"] = add_stacks

	# Source (par défaut: le plus récent)
	if incoming.has("source"):
		existing["source"] = incoming["source"]

	# Display name (si présent)
	if incoming.has("display_name"):
		existing["display_name"] = incoming["display_name"]

	# Type (DoT, Regen, Buff, etc.)
	if incoming.has("type"):
		existing["type"] = incoming["type"]

	# Valeur turns (base)
	if incoming.has("turns"):
		existing["turns"] = incoming["turns"]

	return existing
# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------
static func _read_int(d: Dictionary, key: String, default_value: int) -> int:
	if not d.has(key):
		return default_value
	var v = d[key]
	if v is int:
		return v
	if v is float:
		return int(v)
	return int(default_value)

extends Node
# STRUCTURE : Secteurs -> Niveaux -> Vagues
#
# RÈGLES :
# - Chaque niveau contient X vagues (X dynamique, plafonné).
# - La DERNIÈRE vague de CHAQUE niveau est "spéciale" :
#     - ELITE si ce n’est PAS le dernier niveau du secteur
#     - BOSS si c’est le dernier niveau du secteur
#
# IMPORTANT (correction affichage) :
# - L'UI / le log ne doit PAS lire les variables globales après next_encounter(),
#   car next_encounter() avance la progression.
# - On affiche donc à partir du "snapshot" contenu dans l'encounter (wave_index, level_index, etc.)

# -------------------------
# CONFIG (dynamique + plafonds)
# -------------------------
const WAVES_BASE := 6
const WAVES_MAX := 10

const LEVELS_BASE := 5
const LEVELS_MAX := 9

# -------------------------
# ENNEMIS / ARCHÉTYPES
# -------------------------
enum EnemyRole { DPS, TANK, SUPPORT, ELITE, BOSS }

const ENEMY_BASE: Dictionary = {"hp": 40.0, "p": 6.0, "e": 5.0, "f": 3.0}

const STAT_VARIATION_MIN := 0.90
const STAT_VARIATION_MAX := 1.10

const ROLE_MULT := {
	EnemyRole.DPS:     {"p": 1.3, "e": 0.8, "f": 0.9, "hp": 0.9},
	EnemyRole.TANK:    {"p": 0.7, "e": 1.5, "f": 0.8, "hp": 1.4},
	EnemyRole.SUPPORT: {"p": 0.9, "e": 0.9, "f": 1.4, "hp": 0.8},
	EnemyRole.ELITE:   {"p": 1.3, "e": 1.3, "f": 1.5, "hp": 1.6},
	EnemyRole.BOSS:    {"p": 1.6, "e": 1.6, "f": 2.0, "hp": 2.2},
}

# Pools simples (remplace par tes IDs de scènes/ressources)
const POOL_DPS := ["DPS_A", "DPS_B", "DPS_C"]
const POOL_TANK := ["TANK_A", "TANK_B"]
const POOL_SUPPORT := ["SUPPORT_A", "SUPPORT_B", "SUPPORT_C"]
const POOL_ELITE := ["ELITE_A", "ELITE_B"]
const POOL_BOSS := ["BOSS_A", "BOSS_B"]

# -------------------------
# PROGRESSION
# -------------------------
var sector_index: int = 0          # 0 -> Secteur -1
var level_index: int = 1           # 1 -> Niveau -1 (affiché négativement)
var wave_index: int = 1            # IMPORTANT: commence à 1

# RNG
var rng := RandomNumberGenerator.new()

# ======================= TEST =======================
func _ready():
	var encounters_to_simulate := 120
	rng.randomize() # ou fixe : rng.seed = 42

	print("\n===== START TEST RUN =====")
	for i in range(encounters_to_simulate):
		var encounter := next_encounter()
		_print_encounter(i + 1, encounter)
	print("===== END TEST RUN =====\n")

func _print_encounter(idx: int, encounter: Dictionary) -> void:
	var label := _encounter_label(encounter) # <-- CORRECTION: label = snapshot de l'encounter
	var t := str(encounter.type)

	print("\n%03d | %-6s | %s" % [idx, t, label])

	if t == "ELITE":
		print("  -> FIN DE NIVEAU (ELITE)")
	if t == "BOSS":
		print("  -> FIN DE SECTEUR (BOSS)")

	if t == "BOSS":
		var boss: Dictionary = encounter.boss
		print("  Gimmick: %s" % str(encounter.gimmick_id))
		_print_enemy_line(0, boss)
		return

	var enemies: Array = encounter.enemies
	for j in range(enemies.size()):
		_print_enemy_line(j, enemies[j])

func _print_enemy_line(index: int, enemy: Dictionary) -> void:
	var role_name := _role_to_string(int(enemy.role))
	var variant := str(enemy.variant)

	var hp := float(enemy.hp)
	var p := float(enemy.penetration)
	var e := float(enemy.encryption)
	var f := float(enemy.flux)

	print("  - #%d | %-7s | %-10s | HP=%7.1f | P=%6.1f | E=%6.1f | F=%6.1f"
		% [index + 1, role_name, variant, hp, p, e, f])

func _encounter_label(encounter: Dictionary) -> String:
	# On affiche depuis les champs stockés dans encounter (snapshot)
	var sector_label := -(int(encounter.sector_index) + 1)
	var level_label := -int(encounter.level_index)
	var max_level_label := -int(encounter.levels_per_sector)
	var wave_label := int(encounter.wave_index)
	var max_wave_label := int(encounter.waves_per_level)
	return "Secteur %d | Niveau %d/%d | Vague %d/%d" % [
		sector_label, level_label, max_level_label, wave_label, max_wave_label
	]
# ===================== END TEST =====================


# -------------------------
# DYNAMIQUE: vagues/niveaux qui augmentent avec la progression
# -------------------------
func levels_per_sector() -> int:
	# +1 niveau tous les 2 secteurs, plafonné
	var inc := sector_index / 2
	var v := LEVELS_BASE + inc
	if v > LEVELS_MAX:
		v = LEVELS_MAX
	return v

func waves_per_level() -> int:
	# +1 vague tous les 3 secteurs, +1 si on dépasse la moitié des niveaux du secteur
	var inc_sector := sector_index / 3
	var half := levels_per_sector() / 2
	var inc_level := 0
	if level_index > half:
		inc_level = 1

	var v := WAVES_BASE + inc_sector + inc_level
	if v > WAVES_MAX:
		v = WAVES_MAX
	return v

# -------------------------
# SCALE INFINI (stable)
# -------------------------
func _depth() -> int:
	# scaling lisse (évite des sauts si levels_per_sector varie)
	return sector_index * LEVELS_BASE + level_index

func _scale(depth: int) -> float:
	var d := float(depth)
	return 1.0 + 0.25 * sqrt(d) + 0.15 * log(1.0 + d)

func _flux_scale(depth: int) -> float:
	return 1.0 + 0.2 * log(1.0 + float(depth))

func _roll_variation() -> float:
	return rng.randf_range(STAT_VARIATION_MIN, STAT_VARIATION_MAX)

# -------------------------
# PUBLIC API
# -------------------------
func next_encounter() -> Dictionary:
	var lps := levels_per_sector()
	var wpl := waves_per_level()

	var is_last_wave_of_level := (wave_index == wpl)
	var is_last_level_of_sector := (level_index == lps)

	# Dernière vague du niveau => ELITE ou BOSS
	if is_last_wave_of_level:
		if is_last_level_of_sector:
			var boss_encounter := _generate_boss()
			_advance_after_boss()
			return boss_encounter
		else:
			var elite_encounter := _generate_elite_wave()
			_advance_after_elite()
			return elite_encounter

	# Sinon vague normale
	var wave := _generate_normal_wave()
	_advance_wave()
	return wave

# Timeline anticipable : types fixes, mais longueur variable
func get_level_wave_blueprint() -> Array:
	var wpl := waves_per_level()
	var blueprint: Array = []

	var fixed := ["DPS", "TANK", "SUPPORT", "MIX_DPS_TANK", "MIX_TANK_SUPPORT"]

	var i := 0
	while i < wpl:
		var kind := ""
		if i < fixed.size():
			kind = fixed[i]
		else:
			if (i % 2) == 0:
				kind = "MIX_DPS_SUPPORT"
			else:
				kind = "TEST"

		blueprint.append({"slot": i + 1, "kind": kind})
		i += 1

	# La dernière vague est spéciale (Elite/Boss géré dans next_encounter)
	blueprint[wpl - 1].kind = "SPECIAL"
	return blueprint

# -------------------------
# GENERATION
# -------------------------
func _pick_from(pool: Array) -> String:
	return pool[rng.randi_range(0, pool.size() - 1)]

func _make_enemy(role: int, variant_id: String) -> Dictionary:
	var depth := _depth()
	var s := _scale(depth)
	var fs := _flux_scale(depth)
	var mult = ROLE_MULT[role]
	var v := _roll_variation()

	return {
		"role": role,
		"variant": variant_id,
		"hp": ENEMY_BASE.hp * s * mult.hp * v,
		"penetration": ENEMY_BASE.p * s * mult.p * v,
		"encryption": ENEMY_BASE.e * s * mult.e * v,
		"flux": ENEMY_BASE.f * fs * mult.f * v,
	}

func _wave_pack(enemies: Array, wave_type: String) -> Dictionary:
	# Snapshot complet pour affichage/analytics/debug
	return {
		"type": wave_type,
		"sector_index": sector_index,
		"level_index": level_index,
		"wave_index": wave_index,
		"waves_per_level": waves_per_level(),
		"levels_per_sector": levels_per_sector(),
		"depth": _depth(),
		"enemies": enemies,
	}

func _generate_normal_wave() -> Dictionary:
	var wpl := waves_per_level()
	if wave_index == wpl:
		# Sécurité: normalement cette vague est gérée comme ELITE/BOSS ailleurs
		return _wave_pack([_make_enemy(EnemyRole.DPS, _pick_from(POOL_DPS))], "NORMAL")

	var bp := get_level_wave_blueprint()
	var kind := str(bp[wave_index - 1].kind)

	if kind == "DPS":
		return _wave_pack([
			_make_enemy(EnemyRole.DPS, _pick_from(POOL_DPS)),
			_make_enemy(EnemyRole.DPS, _pick_from(POOL_DPS)),
		], "NORMAL")

	if kind == "TANK":
		return _wave_pack([
			_make_enemy(EnemyRole.TANK, _pick_from(POOL_TANK)),
		], "NORMAL")

	if kind == "SUPPORT":
		return _wave_pack([
			_make_enemy(EnemyRole.SUPPORT, _pick_from(POOL_SUPPORT)),
		], "NORMAL")

	if kind == "MIX_DPS_TANK":
		return _wave_pack([
			_make_enemy(EnemyRole.DPS, _pick_from(POOL_DPS)),
			_make_enemy(EnemyRole.TANK, _pick_from(POOL_TANK)),
		], "NORMAL")

	if kind == "MIX_TANK_SUPPORT":
		return _wave_pack([
			_make_enemy(EnemyRole.TANK, _pick_from(POOL_TANK)),
			_make_enemy(EnemyRole.SUPPORT, _pick_from(POOL_SUPPORT)),
		], "NORMAL")

	if kind == "MIX_DPS_SUPPORT":
		return _wave_pack([
			_make_enemy(EnemyRole.DPS, _pick_from(POOL_DPS)),
			_make_enemy(EnemyRole.SUPPORT, _pick_from(POOL_SUPPORT)),
		], "NORMAL")

	# TEST
	var r := rng.randi_range(0, 2)
	if r == 0:
		return _wave_pack([
			_make_enemy(EnemyRole.DPS, _pick_from(POOL_DPS)),
			_make_enemy(EnemyRole.SUPPORT, _pick_from(POOL_SUPPORT)),
		], "TEST")
	if r == 1:
		return _wave_pack([
			_make_enemy(EnemyRole.TANK, _pick_from(POOL_TANK)),
			_make_enemy(EnemyRole.DPS, _pick_from(POOL_DPS)),
		], "TEST")
	return _wave_pack([
		_make_enemy(EnemyRole.TANK, _pick_from(POOL_TANK)),
		_make_enemy(EnemyRole.SUPPORT, _pick_from(POOL_SUPPORT)),
	], "TEST")

func _generate_elite_wave() -> Dictionary:
	var elite := _make_enemy(EnemyRole.ELITE, _pick_from(POOL_ELITE))
	return _wave_pack([elite], "ELITE")

func _generate_boss() -> Dictionary:
	var boss := _make_enemy(EnemyRole.BOSS, _pick_from(POOL_BOSS))
	# Snapshot inclus (très important pour affichage correct)
	return {
		"type": "BOSS",
		"sector_index": sector_index,
		"level_index": level_index,
		"wave_index": wave_index,
		"waves_per_level": waves_per_level(),
		"levels_per_sector": levels_per_sector(),
		"depth": _depth(),
		"boss": boss,
		"gimmick_id": _pick_boss_gimmick(),
	}

func _pick_boss_gimmick() -> String:
	var gimmicks := ["MIRROR", "FIREWALL_REGEN", "PROXY_REFLECT", "SCRIPT_COPY", "SHIELD_INVERSION"]
	return gimmicks[rng.randi_range(0, gimmicks.size() - 1)]

# -------------------------
# ADVANCE
# -------------------------
func _advance_wave() -> void:
	wave_index += 1

func _advance_after_elite() -> void:
	level_index += 1
	wave_index = 1

func _advance_after_boss() -> void:
	sector_index += 1
	level_index = 1
	wave_index = 1

# -------------------------
# UTIL
# -------------------------
func _role_to_string(role: int) -> String:
	if role == EnemyRole.DPS:
		return "DPS"
	if role == EnemyRole.TANK:
		return "TANK"
	if role == EnemyRole.SUPPORT:
		return "SUPPORT"
	if role == EnemyRole.ELITE:
		return "ELITE"
	if role == EnemyRole.BOSS:
		return "BOSS"
	return "UNKNOWN"

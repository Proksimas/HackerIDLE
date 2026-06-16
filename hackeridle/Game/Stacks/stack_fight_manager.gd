extends Node
class_name StackFightManager
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
const WAVES_BASE = 3
const WAVES_MAX = 10

const LEVELS_BASE := 3
const LEVELS_MAX := 9

const LEVELS_INC_EVERY_SECTORS := 4
const WAVES_INC_EVERY_SECTORS := 6
const LEVEL_DIFFICULTY_PER_STEP := 0.04
const LEVEL_DIFFICULTY_MAX := 1.80
const MIX_START_SECTOR := 8
const ONBOARDING_SECTOR_MAX := 1
const ONBOARDING_LEVELS_PER_SECTOR := 3
const EARLY_INC_LEVEL_START_SECTOR := 4
const ELITE_EXTRA_START_SECTOR := 8
const ELITE_THIRD_ENEMY_START_SECTOR := 14
const DEBUG_PREVIEW_ENCOUNTERS := 0

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

# Pools, avec des variantes si besoin
const POOL_DPS := ["RAPTOR", "RAPTOR_SWARM", "RAPTOR_BLADE", "RAPTOR_VIPER", "RAPTOR_STRIKER", "RAPTOR_HUNTER"]
const POOL_TANK := ["GOLIATH", "GOLIATH_SIEGE", "GOLIATH_SHIELD", "GOLIATH_BASTION", "GOLIATH_COLOSSUS", "GOLIATH_BULWARK"]
const POOL_SUPPORT := ["OPERATOR", "OPERATOR_RELAY", "OPERATOR_HACK", "OPERATOR_ENGINEER", "OPERATOR_TECHNODE", "OPERATOR_COORDINATOR"]
const POOL_ELITE := ["WARDEN_MK1", "WARDEN_MK2", "WARDEN_MK3", "WARDEN_MK4", "WARDEN_MK5"]
const POOL_BOSS := ["TITAN", "TITAN_OMEGA", "TITAN_CORE", "TITAN_SOVEREIGN", "OBLIVION", "ATLAS_CORE"]

const SCRIPT_POOL:Dictionary = {
	"DPS": ["syn_flood", "fork_bomb"],
	"TANK": ["firewall_patch", "cipher_strike"],
	"SUPPORT": ["data_healing", "zero_day_exploit"],
	"ELITE": ["syn_flood", "fork_bomb", "firewall_patch", "cipher_strike"],
	"BOSS": ["syn_flood", "fork_bomb", "firewall_patch", "cipher_strike", "data_healing", "zero_day_exploit"]
}

const ONBOARDING_SCRIPT_POOL_BY_SECTOR: Dictionary = {
	0: {
		"DPS": ["syn_flood"],
		"TANK": ["firewall_patch"],
		"SUPPORT": ["data_healing"],
		"ELITE": ["syn_flood", "firewall_patch"],
		"BOSS": ["syn_flood", "firewall_patch"]
	},
	1: {
		"DPS": ["syn_flood", "fork_bomb"],
		"TANK": ["firewall_patch"],
		"SUPPORT": ["data_healing"],
		"ELITE": ["syn_flood", "cipher_strike"],
		"BOSS": ["firewall_patch", "cipher_strike", "syn_flood"]
	},
	2: {
		"DPS": ["syn_flood", "fork_bomb"],
		"TANK": ["firewall_patch", "cipher_strike"],
		"SUPPORT": ["data_healing", "zero_day_exploit"],
		"ELITE": ["zero_day_exploit", "syn_flood", "fork_bomb"],
		"BOSS": ["zero_day_exploit", "syn_flood", "fork_bomb"]
	},
	3: {
		"DPS": ["syn_flood", "fork_bomb"],
		"TANK": ["firewall_patch", "cipher_strike"],
		"SUPPORT": ["data_healing", "zero_day_exploit"],
		"ELITE": ["syn_flood", "fork_bomb", "firewall_patch"],
		"BOSS": ["firewall_patch", "zero_day_exploit", "syn_flood", "fork_bomb"]
	}
}

const BOSS_SCRIPT_POOL: Dictionary = {
	"TITAN": ["firewall_patch", "cipher_strike", "syn_flood"],
	"TITAN_OMEGA": ["zero_day_exploit", "syn_flood", "fork_bomb"],
	"TITAN_CORE": ["data_healing", "firewall_patch", "cipher_strike"],
	"TITAN_SOVEREIGN": ["proxy_redirect", "cipher_strike", "fork_bomb"],
	"OBLIVION": ["malware_apt", "zero_day_exploit", "fork_bomb"],
	"ATLAS_CORE": ["firewall_patch", "proxy_redirect", "data_healing", "syn_flood"]
}

# -------------------------
# PROGRESSION
# -------------------------
var sector_index: int = 0          # 0 -> Secteur -1
var level_index: int = 1           # 1 -> Niveau -1 (affiché négativement)
var wave_index: int = 1            # IMPORTANT: commence à 1
var current_encounter: Dictionary = {}
var encounter_active: bool = false

# RNG
var rng := RandomNumberGenerator.new()
var run_seed: int = 0
#Fixer à une seed permet de s'assurer qu'on aura TOUJOURS la meme suite d'élément.
#cela permet d'empecher de devoir stocker des datas
# ======================= TEST =======================
func _ready():
	rng.randomize()
	run_seed = randi() # SI CHARGEMENT, METTRE LA BONNE SEED
	rng.seed = _sector_seed(sector_index)
	if DEBUG_PREVIEW_ENCOUNTERS <= 0:
		return

	_debug_preview_encounters(DEBUG_PREVIEW_ENCOUNTERS)

func _debug_preview_encounters(encounters_to_simulate: int) -> void:
	for i in range(encounters_to_simulate):
		var encounter := next_encounter() # renvoie le snapshot de la wave, de _wave_pack
		_print_encounter(i + 1, encounter)

func _print_encounter(_idx: int, encounter: Dictionary) -> void:
	var _label := _encounter_label(encounter) # <-- CORRECTION: label = snapshot de l'encounter
	var t := str(encounter.type)

	if t == "BOSS":
		var boss: Dictionary = encounter.boss
		_print_enemy_line(0, boss)
		return

	var enemies: Array = encounter.enemies
	for j in range(enemies.size()):
		_print_enemy_line(j, enemies[j])

func _print_enemy_line(_index: int, enemy: Dictionary) -> void:
	var _role_name := _role_to_string(int(enemy.role))
	var _variant := str(enemy.variant)

	var _hp := float(enemy.hp)
	var _p := float(enemy.penetration)
	var _e := float(enemy.encryption)
	var _f := float(enemy.flux)

func _encounter_label(encounter: Dictionary) -> String:
	# On affiche depuis les champs stockés dans encounter (snapshot)
	var sector_label := -(int(encounter.get("sector_index", sector_index)) + 1)
	var level_label := -int(encounter.get("level_index", level_index))
	var max_level_label := -int(encounter.get("levels_per_sector", levels_per_sector()))
	var wave_label := int(encounter.get("wave_index", wave_index))
	var max_wave_label := int(encounter.get("waves_per_level", waves_per_level()))
	return "Secteur %d | Niveau %d/%d | Vague %d/%d" % [
		sector_label, level_label, max_level_label, wave_label, max_wave_label
	]
# ===================== END TEST =====================


# -------------------------
# DYNAMIQUE: vagues/niveaux qui augmentent avec la progression
# -------------------------
func levels_per_sector() -> int:
	return _levels_for_sector(sector_index)

func _levels_for_sector(target_sector: int) -> int:
	# Early onboarding: secteurs 0 et 1 = 3 niveaux (2 normaux puis boss).
	if target_sector <= ONBOARDING_SECTOR_MAX:
		return ONBOARDING_LEVELS_PER_SECTOR
	# +1 niveau tous les 4 secteurs, plafonné
	var inc := target_sector / float(LEVELS_INC_EVERY_SECTORS)
	var v := LEVELS_BASE + inc
	if v > LEVELS_MAX:
		v = LEVELS_MAX
	return int(v)

func waves_per_level() -> int:
	# +1 vague tous les 6 secteurs, +1 si on dépasse la moitié des niveaux du secteur
	var inc_sector := sector_index / float(WAVES_INC_EVERY_SECTORS)
	var half := levels_per_sector() / 2.0
	var inc_level := 0
	# Early game: on évite le +1 "seconde moitié" pour ne pas rallonger trop vite les niveaux.
	if sector_index >= EARLY_INC_LEVEL_START_SECTOR and level_index > half:
		inc_level = 1

	var v := WAVES_BASE + inc_sector + inc_level
	if v > WAVES_MAX:
		v = WAVES_MAX
	return int(v)

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

func _global_level_index() -> int:
	var completed_levels := 0
	for previous_sector in range(sector_index):
		completed_levels += _levels_for_sector(previous_sector)
	return completed_levels + level_index

func _level_difficulty_mult() -> float:
	var completed_level_steps = max(0, _global_level_index() - 1)
	return min(LEVEL_DIFFICULTY_MAX, 1.0 + float(completed_level_steps) * LEVEL_DIFFICULTY_PER_STEP)

func _roll_variation() -> float:
	return rng.randf_range(STAT_VARIATION_MIN, STAT_VARIATION_MAX)

func _early_difficulty_mult() -> float:
	# Ramp douce: secteurs 0-2 nettement plus faciles, retour progressif à 1.0 jusqu'au secteur 8.
	if sector_index <= 2:
		return 0.78
	if sector_index >= 8:
		return 1.0
	return lerpf(0.78, 1.0, float(sector_index - 2) / 6.0)

# -------------------------
# PUBLIC API
# -------------------------
func start_encounter() -> Dictionary:
	"""Renvoie les stats de la prochaine vague à prendre
	La fonction prend en compte tout le paradigme existant:
		setceur, niveau, type de vague etc
	La fonction resolve_encouter doit etre appelée à la fin du combat pour faire
	avancée la prorgession"""
	# Si un encounter est déjà en cours, on le renvoie (évite double génération)
	if encounter_active and not current_encounter.is_empty():
		return current_encounter

	var lps := levels_per_sector()
	var wpl := waves_per_level()

	var is_last_wave_of_level := (wave_index == wpl)
	var is_last_level_of_sector := (level_index == lps)

	# Dernière vague => ELITE ou BOSS (mais on N'AVANCE PAS ici)
	if is_last_wave_of_level:
		if is_last_level_of_sector:
			current_encounter = _generate_boss()
		else:
			current_encounter = _generate_elite_wave()
	else:
		current_encounter = _generate_normal_wave()

	encounter_active = true
	return current_encounter

func reset_run() -> void:
	"""Reinitialise la progression roguelike au tout premier combat."""
	sector_index = 0
	level_index = 1
	wave_index = 1
	current_encounter = {}
	encounter_active = false
	rng.randomize()
	run_seed = randi()
	rng.seed = _sector_seed(sector_index)
	
func resolve_encounter(victory: bool) -> void:
	"""appelée à la fin du combat pour faire
	avancée la prorgession"""
	
	if not encounter_active:
		return

	if not victory:
		_apply_defeat_penalty()
		_end_encounter()
		return

	# Victoire : on avance selon le type réellement joué
	var t := str(current_encounter.type)

	if t == "NORMAL" or t == "TEST":
		_advance_wave()
	elif t == "ELITE":
		_advance_after_elite()
	elif t == "BOSS":
		_advance_after_boss()
	else:
		# fallback : comportement NORMAL
		_advance_wave()

	_end_encounter()


func next_encounter() -> Dictionary:
	"""Utilisé dans le DEBUG"""
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
func get_level_wave_blueprint() -> Array:
	var wpl := waves_per_level()
	var blueprint: Array = []

	# Pattern de base
	var fixed := ["DPS", "TANK", "SUPPORT", "MIX_DPS_TANK", "MIX_TANK_SUPPORT"]

	var i := 0
	while i < wpl:
		var kind := ""
		if i < fixed.size():
			kind = fixed[i]
		else:
			# Remplissage stable : alterne MIX puis TEST
			if (i % 2) == 0:
				kind = "MIX_DPS_SUPPORT"
			else:
				kind = "TEST"

		blueprint.append({"slot": i + 1, "kind": kind})
		i += 1

	# La dernière vague est spéciale (Elite/Boss géré dans next_encounter)
	blueprint[wpl - 1].kind = "SPECIAL"

	# --------- Verrou MIX avant MIX_START_SECTOR ----------
	if sector_index < MIX_START_SECTOR:
		for j in range(wpl):
			var k := str(blueprint[j].kind)
			if k.begins_with("MIX_"):
				# On remplace les MIX par quelque chose de lisible
				# Option simple : alternance DPS / TANK
				if (j % 2) == 0:
					blueprint[j].kind = "DPS"
				else:
					blueprint[j].kind = "TANK"
	# --------------------------------------------------------

	return blueprint

func _end_encounter() -> void:
	current_encounter = {}
	encounter_active = false

func _apply_defeat_penalty() -> void:
	# Pénalité douce :
	# - Revenir au début du niveau
	# - Reculer d'1 niveau (si possible)
	# - Si déjà au niveau 1, reculer d'1 secteur (option)
	var penalty_levels := 1

	level_index = max(1, level_index - penalty_levels)
	wave_index = 1

# -------------------------
# GENERATION
# -------------------------
func _pick_from(pool: Array) -> String:
	return pool[rng.randi_range(0, pool.size() - 1)]

func _make_enemy(role: int, variant_id: String) -> Dictionary:
	"""on va crééer et renvoyer un dict de stats de l'entité choisie"""
	var depth := _depth()
	var s := _scale(depth)
	var fs := _flux_scale(depth)
	var mult = ROLE_MULT[role]
	var v := _roll_variation()
	var early_mult := _early_difficulty_mult()
	var level_mult := _level_difficulty_mult()

	return {
		"role": role,
		"variant": variant_id,
		"hp": round(ENEMY_BASE.hp * s * mult.hp * v * early_mult * level_mult),
		"penetration": round(ENEMY_BASE.p * s * mult.p * v * early_mult * level_mult),
		"encryption": round(ENEMY_BASE.e * s * mult.e * v * early_mult * level_mult),
		"flux": round(ENEMY_BASE.f * fs * mult.f * v * early_mult * level_mult)
	}

func _wave_pack(enemies: Array, wave_type: String) -> Dictionary:
	var pack := _encounter_snapshot()
	pack["type"] = wave_type
	pack["enemies"] = enemies
	return pack

func _generate_normal_wave() -> Dictionary:
	var bp := get_level_wave_blueprint()
	var kind := str(bp[wave_index - 1].kind)

	var enemy_count := _roll_enemy_count()
	var enemies: Array = []

	match kind:
		"DPS":
			for i in range(enemy_count):
				enemies.append(
					_make_enemy(EnemyRole.DPS, _pick_from(POOL_DPS))
				)

		"TANK":
			# 1 tank obligatoire
			enemies.append(
				_make_enemy(EnemyRole.TANK, _pick_from(POOL_TANK))
			)
			while enemies.size() < enemy_count:
				if rng.randf() < 0.5:
					enemies.append(
						_make_enemy(EnemyRole.SUPPORT, _pick_from(POOL_SUPPORT))
					)
				else:
					enemies.append(
						_make_enemy(EnemyRole.DPS, _pick_from(POOL_DPS))
					)

		"SUPPORT":
			enemies.append(
				_make_enemy(EnemyRole.SUPPORT, _pick_from(POOL_SUPPORT))
			)
			while enemies.size() < enemy_count:
				enemies.append(
					_make_enemy(EnemyRole.DPS, _pick_from(POOL_DPS))
				)

		"MIX_DPS_TANK":
			enemies.append(
				_make_enemy(EnemyRole.DPS, _pick_from(POOL_DPS))
			)
			enemies.append(
				_make_enemy(EnemyRole.TANK, _pick_from(POOL_TANK))
			)
			while enemies.size() < enemy_count:
				enemies.append(
					_make_enemy(EnemyRole.DPS, _pick_from(POOL_DPS))
				)

		"MIX_TANK_SUPPORT":
			enemies.append(
				_make_enemy(EnemyRole.TANK, _pick_from(POOL_TANK))
			)
			enemies.append(
				_make_enemy(EnemyRole.SUPPORT, _pick_from(POOL_SUPPORT))
			)
			while enemies.size() < enemy_count:
				enemies.append(
					_make_enemy(EnemyRole.DPS, _pick_from(POOL_DPS))
				)

		"MIX_DPS_SUPPORT":
			enemies.append(
				_make_enemy(EnemyRole.DPS, _pick_from(POOL_DPS))
			)
			enemies.append(
				_make_enemy(EnemyRole.SUPPORT, _pick_from(POOL_SUPPORT))
			)
			while enemies.size() < enemy_count:
				enemies.append(
					_make_enemy(EnemyRole.DPS, _pick_from(POOL_DPS))
				)

		"TEST":
			# TEST = mélange pénible mais lisible
			enemies.append(
				_make_enemy(EnemyRole.TANK, _pick_from(POOL_TANK))
			)
			enemies.append(
				_make_enemy(EnemyRole.SUPPORT, _pick_from(POOL_SUPPORT))
			)
			while enemies.size() < enemy_count:
				enemies.append(
					_make_enemy(EnemyRole.DPS, _pick_from(POOL_DPS))
				)

		_:
			# fallback sécurité
			enemies.append(
				_make_enemy(EnemyRole.DPS, _pick_from(POOL_DPS))
			)

	return _wave_pack(enemies, "NORMAL")

func _generate_elite_wave() -> Dictionary:
	var enemies: Array = []

	# Elite principale
	enemies.append(
		_make_enemy(EnemyRole.ELITE, _pick_from(POOL_ELITE))
	)

	# À partir d’un certain secteur, on ajoute de la pression
	if sector_index >= ELITE_EXTRA_START_SECTOR:
		if rng.randf() < 0.6:
			enemies.append(
				_make_enemy(EnemyRole.SUPPORT, _pick_from(POOL_SUPPORT))
			)
		else:
			enemies.append(
				_make_enemy(EnemyRole.DPS, _pick_from(POOL_DPS))
			)

	# Très tard : parfois un 3e ennemi
	if sector_index >= ELITE_THIRD_ENEMY_START_SECTOR and rng.randf() < 0.3:
		enemies.append(
			_make_enemy(EnemyRole.DPS, _pick_from(POOL_DPS))
		)

	return _wave_pack(enemies, "ELITE")


func _generate_boss() -> Dictionary:
	var boss := _make_enemy(EnemyRole.BOSS, _pick_from(POOL_BOSS))
	var pack := _encounter_snapshot()
	pack["type"] = "BOSS"
	pack["boss"] = boss
	pack["gimmick_id"] = _pick_boss_gimmick()
	return pack

func _encounter_snapshot() -> Dictionary:
	return {
		"sector_index": sector_index,
		"level_index": level_index,
		"wave_index": wave_index,
		"waves_per_level": waves_per_level(),
		"levels_per_sector": levels_per_sector(),
		"depth": _depth(),
		"global_level_index": _global_level_index(),
		"level_difficulty_mult": _level_difficulty_mult(),
	}
func _enemy_count_distribution_for_sector(s: int) -> Array:
	# Paires [count, weight]
	# Progression très douce, pensée pour runs plus longs.
	if s <= 2:
		# Ultra early: apprentissage, lecture des scripts
		return [[1, 100]]
	if s <= 6:
		# Early: 1 encore dominant, 2 commence à apparaître
		return [[1, 80], [2, 15], [3, 5]]
	if s <= 12:
		# Secteurs affiches 8-13: minimum 2 ennemis.
		return [[2, 85], [3, 15]]
	if s <= 18:
		# Secteurs affiches 14-19: 2 ennemis minimum, 3 deviennent frequents.
		return [[2, 65], [3, 32], [4, 3]]
	if s <= 26:
		# Secteurs affiches 20-27: minimum 3 ennemis.
		return [[3, 85], [4, 15]]
	if s <= 34:
		# Secteurs affiches 28-35: 4 ennemis deviennent plus frequents.
		return [[3, 75], [4, 25]]
	# Secteur affiche 36+: minimum 3, maximum 4.
	return [[3, 65], [4, 35]]



func _roll_enemy_count() -> int:
	var dist := _enemy_count_distribution_for_sector(sector_index)
	var total := 0
	for pair in dist:
		total += int(pair[1])

	var r := rng.randi_range(1, total)
	var acc := 0
	for pair in dist:
		acc += int(pair[1])
		if r <= acc:
			return int(pair[0])
	return int(dist[0][0]) if not dist.is_empty() else 1
	
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
	#On définit une nouvelle seed, qui est enregistrée pour geler les stats
	#des robots dans ce secteur
	rng.seed = _sector_seed(sector_index)

func setup_robot_scripts(entity: Entity, _robot_name: String, role: int = EnemyRole.DPS) -> void:
	if entity == null:
		return

	var role_key := _role_to_string(role)
	var script_names: Array = _get_scripts_for_enemy(role_key, _robot_name)
	var learned_scripts: Array[String] = []

	for script_name_variant in script_names:
		var script_name := str(script_name_variant)
		if StackManager.learn_stack_script(entity, script_name):
			learned_scripts.append(script_name)
		else:
			push_error("StackFightManager | impossible d'apprendre %s au robot %s" % [script_name, _robot_name])

	if learned_scripts.is_empty():
		entity.save_sequence([])
		return

	entity.save_sequence(learned_scripts)

func _get_scripts_for_enemy(role_key: String, robot_name: String) -> Array:
	var onboarding_scripts := _get_onboarding_scripts(role_key)
	if not onboarding_scripts.is_empty():
		return onboarding_scripts

	if role_key == "BOSS":
		var boss_key := robot_name.strip_edges().to_upper()
		if BOSS_SCRIPT_POOL.has(boss_key):
			var boss_scripts = BOSS_SCRIPT_POOL[boss_key]
			if boss_scripts is Array:
				return boss_scripts

	var role_scripts = SCRIPT_POOL.get(role_key, SCRIPT_POOL["DPS"])
	return role_scripts if role_scripts is Array else []


func _get_onboarding_scripts(role_key: String) -> Array:
	if not ONBOARDING_SCRIPT_POOL_BY_SECTOR.has(sector_index):
		return []

	var sector_pool = ONBOARDING_SCRIPT_POOL_BY_SECTOR[sector_index]
	if not (sector_pool is Dictionary):
		return []
	if not sector_pool.has(role_key):
		return []

	var script_names = sector_pool[role_key]
	if script_names is Array:
		return script_names
	return []

func _save_data() -> Dictionary:
	return {
		"sector_index": sector_index,
		"level_index": level_index,
		"wave_index": wave_index,
		"current_encounter": current_encounter.duplicate(true),
		"encounter_active": encounter_active,
		"run_seed": run_seed
	}

func _load_data(content: Dictionary) -> void:
	if typeof(content) != TYPE_DICTIONARY:
		return

	sector_index = max(0, int(content.get("sector_index", 0)))
	level_index = max(1, int(content.get("level_index", 1)))
	wave_index = max(1, int(content.get("wave_index", 1)))

	var loaded_encounter = content.get("current_encounter", {})
	current_encounter = loaded_encounter.duplicate(true) if loaded_encounter is Dictionary else {}
	encounter_active = bool(content.get("encounter_active", false)) and not current_encounter.is_empty()

	run_seed = int(content.get("run_seed", 0))
	if run_seed == 0:
		rng.randomize()
		run_seed = randi()

	rng.seed = _sector_seed(sector_index)

	var max_level := levels_per_sector()
	level_index = clampi(level_index, 1, max_level)

	var max_wave := waves_per_level()
	wave_index = clampi(wave_index, 1, max_wave)
# -------------------------
# UTIL
# -------------------------
func _sector_seed(s: int) -> int:
	# hash() renvoie un int stable.
	# On mélange run_seed + s pour éviter corrélation.
	return int(hash("%d|SECTOR|%d" % [run_seed, s]))

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

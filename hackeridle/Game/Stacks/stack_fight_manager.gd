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
const WAVES_BASE := 3
const WAVES_MAX := 10

const LEVELS_BASE := 3
const LEVELS_MAX := 9

const MIX_START_SECTOR := 4

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
	"DPS": ["syn_flood"],
	"TANK": ["syn_flood"],
	"SUPPORT": ["syn_flood"],
	"ELITE": ["syn_flood"],
	"BOSS": ["syn_flood"]
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
	var encounters_to_simulate := 120
	rng.randomize() 
	run_seed = randi() #SI CHAREGEMENT, METTRE LA BONNE SEED
	rng.seed = _sector_seed(sector_index)
	return
	print("\n===== START TEST RUN =====")
	for i in range(encounters_to_simulate):
		var encounter := next_encounter() # renvoie le snapshot de la wave, de _wave_pack
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
	var inc := sector_index / 2.0
	var v := LEVELS_BASE + inc
	if v > LEVELS_MAX:
		v = LEVELS_MAX
	return int(v)

func waves_per_level() -> int:
	# +1 vague tous les 3 secteurs, +1 si on dépasse la moitié des niveaux du secteur
	var inc_sector := sector_index / 3.0
	var half := levels_per_sector() / 2.0
	var inc_level := 0
	if level_index > half:
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

func _roll_variation() -> float:
	return rng.randf_range(STAT_VARIATION_MIN, STAT_VARIATION_MAX)

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

	# --------- NOUVEAU : verrou MIX avant secteur 4 ----------
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

	return {
		"role": role,
		"variant": variant_id,
		"hp": round(ENEMY_BASE.hp * s * mult.hp * v),
		"penetration": round(ENEMY_BASE.p * s * mult.p * v),
		"encryption": round(ENEMY_BASE.e * s * mult.e * v),
		"flux": round(ENEMY_BASE.f * fs * mult.f * v)
	}

func _wave_pack(enemies: Array, wave_type: String) -> Dictionary:
	# Snapshot complet de la wave
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
	if sector_index >= 3:
		if rng.randf() < 0.6:
			enemies.append(
				_make_enemy(EnemyRole.SUPPORT, _pick_from(POOL_SUPPORT))
			)
		else:
			enemies.append(
				_make_enemy(EnemyRole.DPS, _pick_from(POOL_DPS))
			)

	# Très tard : parfois un 3e ennemi
	if sector_index >= 7 and rng.randf() < 0.3:
		enemies.append(
			_make_enemy(EnemyRole.DPS, _pick_from(POOL_DPS))
		)

	return _wave_pack(enemies, "ELITE")


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
func _enemy_count_distribution_for_sector(s: int) -> Array:
	# Paires [count, weight]
	# Progression très douce, pensée pour 20+ secteurs.
	if s <= 1:
		# Ultra early: apprentissage, lecture des scripts
		return [[1, 100], [2, 0], [3, 0]]
	if s <= 3:
		# Early: 1 encore dominant, 2 commence à apparaître
		return [[1, 80], [2, 15], [3, 5]]
	if s <= 6:
		# Transition: 2 devient fréquent, 1 encore présent
		return [[1, 45], [2, 45], [3, 10]]
	if s <= 9:
		# Mid early: 2 devient la norme
		return [[1, 25], [2, 55], [3, 18], [4, 2]]
	if s <= 13:
		# Mid: 3 apparaît souvent, 4 reste rare
		return [[1, 12], [2, 50], [3, 33], [4, 5]]
	if s <= 17:
		# Mid-late: 3 fréquent, 4 possible
		return [[1, 6], [2, 44], [3, 38], [4, 12]]
	# s >= 18 (late game stable)
	# 4 ennemis acceptés, 1 devient exceptionnel
	return [[1, 3], [2, 40], [3, 40], [4, 17]]



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
	return 2
	
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

func setup_robot_scripts(entity: Entity, _robot_name: String, _all_scripts_db: Dictionary) -> void:
	# TODO SELON LE ROBOT_NAME
	#entity.available_scripts = {}
	#for s_name in SCRIPT_POOL[robot_name]:
		#entity.available_scripts[s_name] = all_scripts_db[s_name]
		
	#pour le moment on ne donne que le SYN_FLOOD
	StackManager.learn_stack_script(entity, "syn_flood")
	entity.save_sequence(["syn_flood"])
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

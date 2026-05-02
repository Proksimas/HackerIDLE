extends Node

# --- Parametres ajustables pour l'achat des bots---
var base_cost := 5000.0    # cout en connaissance du premier bot
var alpha := 0.18          # progression lineaire
var beta := 1.3            # progression exponentielle
var base_click := 1.0      # connaissance de base par clic
var k := 5.0               # puissance de l'or investi (rendement decroissant). Impacte grandement sur l'investissement
var next_bot_kwoledge_acquired: float = 0
var gold_to_invest: int = 100 # Investissement du joueur par click
var gold_invest_in_bots: float = 0 # correspond a l'argent que le joueur a investi pour les bots
var coef_nerf_bots: float = 0.7
# ------------- Parametres pour les SALES ---------------------------------------------
var gold_invest_in_sales: float = 0 # correspond a l'argent que le joueur a investi.
var knowledge_invest_in_sales: float = 0
var gold_to_invest_perc: float = 0.10 # le joueur doit investir x% de son argent max
var knowledge_to_invest_perc: float = 0.10
var _R: float = 0.02 / 60  # revenu moyen par bot / s -> doit etre un % de l'investissement
var sigma_base: float = 0.30       # volatilite globale
var mean_rev: float = 0.10         # retour a la moyenne (0..1)
var _v: float = 0.0                # etat de volatilite
var clamp_abs: float = 0.5         # borne douce sur v (evite extremes)

# ------------- Parametres pour le farming XP---------------------------------------------
var coef_farming_xp: Dictionary # voir _init
var coef_exploit_xp: float # voir _init

# Nombres d'implants affectes aux taches
var active_tasks = {
	"farming_xp": 0,
	"research": 0,
	"sales_task": 0
}


var time_ia_click: int = -1 # si -1, alors le skill n'est pas debloque
var ia_is_enable: bool = false # si true, les bots sont automatises
var has_unlocked_syn_flood_from_novanet: bool = false

signal s_bot_bought() # indique qu'on a achete 1 bot
signal s_bots_bought()  # indique qu'on a achete des bots, independamment de leur nombre
signal s_bot_knowledge_gain(number)
signal s_gain_sales(number)
signal s_not_enough(type)

func _process(delta: float) -> void:
	update_farming_task(delta)
	update_research_task(delta)
	update_sales_task(delta)

func _init():
	for key in active_tasks:
		active_tasks[key] = 0
	knowledge_invest_in_sales = 0
	next_bot_kwoledge_acquired = 0
	coef_exploit_xp = 1
	coef_farming_xp = {"base": 0.5}
	has_unlocked_syn_flood_from_novanet = false

func on_novanet_entered() -> void:
	"""Premier acces NovaNet: debloque syn_flood pour le hacker."""
	if Player.nb_of_rebirth <= 0:
		return
	if not has_unlocked_syn_flood_from_novanet:
		has_unlocked_syn_flood_from_novanet = true
		StackManager.apply_first_novanet_grant()
	else:
		StackManager.unlock_hacker_script("syn_flood")

func assign_bots(task_name, number_of_bots):
	assign_implants(task_name, number_of_bots)

func assign_implants(task_name: String, number_of_implants: int) -> void:
	active_tasks[task_name] = number_of_implants

func earn_cyber_implants(amount: int) -> void:
	Player.earn_cyber_implants(amount)

var farming_time = 0
func update_farming_task(delta):
	farming_time += delta
	var bots = active_tasks["farming_xp"]
	if bots > 0 and farming_time >= 1:
		var xp = gain_farming_xp()
		Player.earn_brain_xp(xp)
		farming_time = 0

func gain_farming_xp() -> int:
	var bots = active_tasks["farming_xp"]
	var sum_coef = 0
	for coef in coef_farming_xp:
		sum_coef += coef_farming_xp[coef]
	return bots * sum_coef

var research_time = 0
func update_research_task(_delta):
	research_time += _delta
	var bots = active_tasks["research"]
	if bots > 0 and research_time >= 1:
		var xp = gain_research()
		Player.earn_exploit_xp(xp)
		research_time = 0

func gain_research() -> float:
	var bots = active_tasks["research"]
	return bots * coef_exploit_xp

#region Sales
var sales_time = 0
func update_sales_task(_delta):
	sales_time += _delta
	var bots = active_tasks["sales_task"]
	if bots > 0 and sales_time >= 1:
		var sigma_eff := sigma_base / sqrt(float(max(1, bots)))
		var eps := _randn()
		_v = (1.0 - mean_rev) * _v + sigma_eff * eps
		_v = clampf(_v, -clamp_abs, clamp_abs)
		var _M := maxf(0.0, 1.0 + _v)
		var gain := int(float(bots) * _R * knowledge_invest_in_sales * _M)
		s_gain_sales.emit(gain)
		Player.earn_gold(gain)
		sales_time = 0

func _randn() -> float:
	var u1 := clampf(randf(), 1e-6, 1.0)
	var u2 := randf()
	return sqrt(-2.0 * log(u1)) * cos(2.0 * PI * u2)

func expected_income_per_sec() -> float:
	return float(active_tasks["sales_task"] * coef_nerf_bots) * _R * knowledge_invest_in_sales

func current_income_per_sec_estimate() -> float:
	var M := maxf(0.0, 1.0 + _v)
	return float(active_tasks["sales_task"] * coef_nerf_bots) * _R * knowledge_invest_in_sales * M
#endregion

func get_bot_cost(n: int) -> float:
	return snapped(base_cost * pow(1 + alpha * n, beta), 1)

func knowledge_per_click(or_investi: float) -> float:
	return snapped(lineaire_and_log(or_investi), 1)

func nb_click_required(or_investi) -> int:
	return ceil(get_bot_cost(Player.bots) / knowledge_per_click(or_investi))

func nb_click_left(or_investi) -> int:
	var knowledge_left = get_bot_cost(Player.bots) - next_bot_kwoledge_acquired
	var click_left = ceil(knowledge_left / knowledge_per_click(or_investi))
	return click_left

func click(or_investi: float) -> bool:
	var knowledge_gain := knowledge_per_click(or_investi)
	if Player.knowledge_point < knowledge_gain:
		s_not_enough.emit("knowledge")
		return false
	next_bot_kwoledge_acquired += knowledge_gain
	Player.earn_knowledge_point(0 - knowledge_gain)
	#Player.earn_gold(0 - or_investi) l'or investi est dépensé au début
	s_bot_knowledge_gain.emit(knowledge_gain)
	check_buy_bot()
	return true

func check_buy_bot():
	var bots_bought: bool = false
	for _loop in range(1000):
		if next_bot_kwoledge_acquired >= get_bot_cost(Player.bots):
			buy_bot()
			bots_bought = true
		else:
			break
	if bots_bought:
		s_bots_bought.emit()

func buy_bot() -> void:
	next_bot_kwoledge_acquired = next_bot_kwoledge_acquired - get_bot_cost(Player.bots)
	Player.bots += 1
	s_bot_bought.emit()

func michaelis_menten(or_investi):
	var _B := 1.0
	var _Vmax := get_bot_cost(Player.bots) * 0.35
	var _Km := _Vmax * 0.75
	return _B + _Vmax * (or_investi / (_Km + or_investi))

func lineaire_and_log(or_investi):
	var _B := 1.0
	var _p := 0.45
	var _k := 4.0
	return _B + _p * or_investi + _k * log(1.0 + or_investi)

func _save_data():
	var all_vars = Global.get_serialisable_vars(self)
	return all_vars

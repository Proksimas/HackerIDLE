extends Node

# --- Paramètres ajustables pour l'achat des bots---
var base_cost := 50000.0    # coût en connaissance du premier bot
var alpha := 0.18          # progression linéaire
var beta := 1.3            # progression exponentielle
var base_click := 1.0      # connaissance de base par clic
var k := 5.0               # puissance de l’or investi (rendement décroissant). Impacte grandement sur l'investissement
var next_bot_kwoledge_acquired: float = 0
var gold_to_invest: int = 100 # Investissement du joueur par click
var gold_invest_in_bots: float= 0 # correspond à l'argent que le joueur a investi pour les bots
# ------------- ¨Paramètres pour les SALES ---------------------------------------------

var gold_invest_in_sales: float= 0 # correspond à l'argent que le joueur a investi.
var knowledge_invest_in_sales: float = 0
var gold_to_invest_perc: float = 0.10 # le joueur doit investir x% de son argent max
var knowledge_to_invest_perc: float = 0.10
var _R: float = 0.02 / 60  # revenu moyen par bot / s -> doit etre un % de l'investissement
var sigma_base: float = 0.30       # volatilité globale
var mean_rev: float = 0.10         # retour à la moyenne (0..1)
var _v: float = 0.0                        # état de volatilité
var clamp_abs: float = 0.5   # borne douce sur v (evite extrêmes)
# ------------- ¨Paramètres pour le farming XP---------------------------------------------
var coef_farming_xp = {"base": 3}
var coef_exploit_xp: float
# Nombres de bots affectés aux taches
var active_tasks = {
	"farming_xp": 0,
	"research": 0,
	"sales_task": 0
}
var time_ia_click: int = -1 #si -1, alors le skill n'est pas débloqué
var ia_is_enable: bool = false # si true, les bots sont automatisés (sous entend aussi que ia_enabled_skill == true
signal s_bot_bought() #indique qu'on  acheté 1 bot
signal s_bots_bought()  #indique qu'on  acheté des bots, indépendamment de leur nombre
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
	#gold_invest_in_sales = 0
	knowledge_invest_in_sales = 0
	next_bot_kwoledge_acquired = 0
	coef_exploit_xp = 10
	coef_farming_xp = {"base": 3}
	
func assign_bots(task_name, number_of_bots):
	active_tasks[task_name] = number_of_bots
	pass

var farming_time = 0
func update_farming_task(delta):
	farming_time += delta
	var bots = active_tasks["farming_xp"]
	if bots > 0 and farming_time >= 1:
		var xp = gain_farming_xp()
		Player.earn_brain_xp(xp)
		farming_time = 0
		pass

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
		pass

func gain_research()->float:
	var bots = active_tasks["research"]
	return bots * coef_exploit_xp
	
#region Sales
var sales_time = 0
func update_sales_task(_delta):
	sales_time += _delta
	var bots = active_tasks["sales_task"]
	if bots > 0 and sales_time >= 1:
			# volatilite reduite par diversification
		var sigma_eff := sigma_base / sqrt(float(max(1, bots)))

		# bruit normal ~ N(0,1)
		var eps :=  _randn()

		# dynamique mean-reverting
		_v = (1.0 - mean_rev) * _v + sigma_eff * eps
		_v = clampf(_v, -clamp_abs, clamp_abs)

		 # marche autour de 1, jamais negatif
		var _M := maxf(0.0, 1.0 + _v)
		
		#
		var gain := int(float(bots) * _R * knowledge_invest_in_sales * _M)
		# 	TODO EARN
		
		s_gain_sales.emit(gain)
		#print("gain: %s" % Global.number_to_string(gain))
		Player.earn_gold(gain)
		sales_time = 0
		pass

# Box-Muller pour N(0,1)
func _randn() -> float:
	var u1 := clampf(randf(), 1e-6, 1.0)
	var u2 := randf()
	return sqrt(-2.0 * log(u1)) * cos(2.0 * PI * u2)
	
func expected_income_per_sec() -> float:
	# espérance ≈ bots * _R (car E[M]≈1)
	return float(active_tasks["sales_task"]) * _R * knowledge_invest_in_sales

func current_income_per_sec_estimate() -> float:
	# estimation instantanée avec le M courant
	var M := maxf(0.0, 1.0 + _v)
	return float(active_tasks["sales_task"]) * _R * knowledge_invest_in_sales * M
	

#endregion




# --- Calcule le coût en connaissance du prochain bot ---
func get_bot_cost(n: int) -> float:
	return snapped(base_cost * pow(1 + alpha * n, beta), 1)

# --- Calcule la connaissance gagnée par clic en fonction de l’or investi ---
func knowledge_per_click(or_investi: float) -> float:
	"""Il y a un coef k qui evite un snowball si l'or investi est bien trop important"""
	#return snapped(michaelis_menten(or_investi), 1)
	return snapped(lineaire_and_log(or_investi), 1)
	#return snapped(base_click + k * log(1 + or_investi), 1)

func nb_click_required(or_investi) -> int:
	return ceil(get_bot_cost(Player.bots) / knowledge_per_click(or_investi))
	
func nb_click_left(or_investi) ->int:
	"""Nombre de click restant par rapport à la connaissance accumulée"""
	var knowledge_left = get_bot_cost(Player.bots) - next_bot_kwoledge_acquired
	
	var click_left = ceil(knowledge_left / knowledge_per_click(or_investi))
	#var click_left = ceil(knowledge_left / knowledge_per_click(or_investi))
	return click_left



func click(or_investi: float) -> bool:

	#if Player.gold < or_investi:
		#print("Pas assez d’or pour investir ", or_investi)
		#s_not_enough.emit("gold")
		#return false
	var knowledge_gain := knowledge_per_click(or_investi)
	if Player.knowledge_point < knowledge_gain:
		s_not_enough.emit("knowledge")
		return false
	next_bot_kwoledge_acquired += knowledge_gain
	Player.earn_knowledge_point(0 - knowledge_gain)
	Player.earn_gold(0 - or_investi)
	s_bot_knowledge_gain.emit(knowledge_gain)
	check_buy_bot()
	return true
	#print("Clic ! + %s connaissance (total = %s/%s)" % \
	#	[knowledge_gain, next_bot_kwoledge_acquired, get_bot_cost(Player.bots)])


func check_buy_bot():
	"""On check si on peut acheter le bot, cad si toute la connaissance acquise est suffisante"""
	 #on part du principe que le joueur n'achetera jamais plus de 1000 bots d'un coup
	#pour éviter de faire un while
	var bots_bought:bool = false
	for loop in range(1000):
		if next_bot_kwoledge_acquired >= get_bot_cost(Player.bots):
			buy_bot()
			bots_bought = true
		else:
			break
	if bots_bought:
		s_bots_bought.emit()
# --- Achat d’un bot si assez de connaissance ---
func buy_bot() -> void:
	next_bot_kwoledge_acquired =  next_bot_kwoledge_acquired - get_bot_cost(Player.bots)
	Player.bots += 1
	s_bot_bought.emit()



func michaelis_menten(or_investi):
	"""algo renforçant le gain à bas coût pour ensuite etre tres loga"""
	var _B := 1.0
	var _Vmax := get_bot_cost(Player.bots) * 0.35   # plafond d'appoint = connaissance max par click
	var _Km := _Vmax * 0.75   # point de demi-saturation
	#print("Plafond d'appoint: %s   Demi saturation à : %s" % [Vmax, Km])
	return _B + _Vmax * (or_investi / (_Km + or_investi))

func lineaire_and_log(or_investi):
	"""algo lineaire avec une legere log"""
	var _B := 1.0
	var _p := 0.45
	var _k := 4.0
	return _B + _p * or_investi + _k * log(1.0 + or_investi)


func _save_data():
	var all_vars = Global.get_serialisable_vars(self)
	return all_vars

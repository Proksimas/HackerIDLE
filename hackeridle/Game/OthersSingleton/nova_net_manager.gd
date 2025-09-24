extends Node

# --- Paramètres ajustables pour l'achat des bots---
var base_cost := 100000.0      # coût en connaissance du premier bot
var alpha := 0.15          # progression linéaire
var beta := 1.3            # progression exponentielle
var base_click := 1.0      # connaissance de base par clic
var k := 5.0               # puissance de l’or investi (rendement décroissant). Impacte grandement sur l'investissement
var knowledge_required_factor
var next_bot_kwoledge_acquired: float = 0
var gold_to_invest: int = 100 # Investissement du joueur par click
# ---------------------------------------------------------------------------

var coef_farming_xp = 1

# Nombres de bots affectés aux taches
var active_tasks = {
	"farming_xp": 0,
	"research": 0,
	"sales_task": 0
}
signal s_bot_bought()
signal s_bot_knowledge_gain(number)

func _process(delta: float) -> void:
	
	update_farming_task(delta)
	update_research_task(delta)
	update_sales_task(delta)
	
func assign_bots(task_name, number_of_bots):
	active_tasks[task_name] = number_of_bots
	pass

var farming_time = 0
func update_farming_task(delta):
	farming_time += delta
	var bots = active_tasks["farming_xp"]
	if bots > 0 and farming_time >= 1:
		var xp = bots * coef_farming_xp
		Player.earn_brain_xp(xp)
		farming_time = 0
		pass

func update_research_task(delta):
	var bots = active_tasks["research"]
	if bots > 0:
		pass
		
func update_sales_task(delta):
	var bots = active_tasks["sales_task"]
	if bots > 0:
		pass


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
	return click_left



func click(or_investi: float) -> void:

	if Player.gold < or_investi:
		print("Pas assez d’or pour investir ", or_investi)
		return
	Player.gold -= or_investi
	var knowledge_gain := knowledge_per_click(or_investi)
	if Player.knowledge_point < knowledge_gain:
		print("Pas assez de knowledge pour investir ", knowledge_gain)
		return
	
	next_bot_kwoledge_acquired += knowledge_gain
	Player.knowledge_point -= knowledge_gain
	s_bot_knowledge_gain.emit(knowledge_gain)
	check_buy_bot()
	print("Clic ! + %s connaissance (total = %s/%s)" % \
		[knowledge_gain, next_bot_kwoledge_acquired, get_bot_cost(Player.bots)])


func check_buy_bot():
	"""On check si on peut acheter le bot, cad si toute la connaissance acquise est suffisante"""
	if next_bot_kwoledge_acquired >= get_bot_cost(Player.bots):
		buy_bot()

# --- Achat d’un bot si assez de connaissance ---
func buy_bot() -> void:
	Player.bots += 1
	next_bot_kwoledge_acquired = 0
	s_bot_bought.emit()



func michaelis_menten(or_investi):
	"""algo renforçant le gain à bas coût pour ensuite etre tres loga"""
	var B := 1.0
	var Vmax := get_bot_cost(Player.bots) * 0.35   # plafond d'appoint = connaissance max par click
	var Km := Vmax * 0.75   # point de demi-saturation
	#print("Plafond d'appoint: %s   Demi saturation à : %s" % [Vmax, Km])
	return B + Vmax * (or_investi / (Km + or_investi))

func lineaire_and_log(or_investi):
	"""algo lineaire avec une legere log"""
	var B := 1.0
	var p := 0.45
	var k := 4.0
	return B + p * or_investi + k * log(1.0 + or_investi)

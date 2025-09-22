extends Node

# --- Paramètres ajustables pour l'achat des bots---
var base_cost := 20.0      # coût en connaissance du premier bot
var alpha := 0.15          # progression linéaire
var beta := 1.3            # progression exponentielle
var base_click := 1.0      # connaissance de base par clic
var k := 5.0               # puissance de l’or investi (rendement décroissant)
var next_bot_kwoledge_acquired: float = 0
var gold_per_click: int = 0 # Investissement du joueur par click
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
	return snapped(base_click + k * log(1 + or_investi), 1)

func nb_click_required(or_investi) -> int:
	return ceil(get_bot_cost(Player.bots) / knowledge_per_click(or_investi))

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
	print("Clic ! + %s connaissance (total=%s/%s)" % \
		[knowledge_gain, next_bot_kwoledge_acquired, nb_click_required(gold_per_click)])


func check_buy_bot():
	"""On check si on peut acheter le bot, cad si toute la connaissance acquise est suffisante"""
	if next_bot_kwoledge_acquired >= get_bot_cost(Player.bots):
		buy_bot()

# --- Achat d’un bot si assez de connaissance ---
func buy_bot() -> void:
	Player.bots += 1
	next_bot_kwoledge_acquired = 0
	s_bot_bought.emit()

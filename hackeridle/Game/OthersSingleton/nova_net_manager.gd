extends Node

# --- Paramètres ajustables pour l'achat des bots---
var base_cost := 20.0      # coût en connaissance du premier bot
var alpha := 0.15          # progression linéaire
var beta := 1.3            # progression exponentielle
var base_click := 1.0      # connaissance de base par clic
var k := 5.0               # puissance de l’or investi (rendement décroissant)
# ---------------------------------------------------------------------------

var coef_farming_xp = 1

# Nombres de bots affectés aux taches
var active_tasks = {
	"farming_xp": 0,
	"research": 0,
	"sales_task": 0
}


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
	return base_cost * pow(1 + alpha * n, beta)

# --- Calcule la connaissance gagnée par clic en fonction de l’or investi ---
func knowledge_per_click(or_investi: float) -> float:
	return base_click + k * log(1 + or_investi)

# --- Simule un clic du joueur ---
func click(or_investi: float) -> void:

	if Player.gold < or_investi:
		print("Pas assez d’or pour investir ", or_investi)
		return
	Player.gold -= or_investi
	var gain := knowledge_per_click(or_investi)
	Player.knowledge_point += gain
	print("Clic ! +" , gain, " connaissance (total=", Player.knowledge_point, ")")

# --- Achat d’un bot si assez de connaissance ---
func buy_bot() -> void:
	var cost := get_bot_cost(Player.bots)
	if Player.knowledge_poin >= cost:
		Player.knowledge_poin -= cost
		Player.bots += 1
		print("Bot acheté ! Nombre total de bots =", Player.bots)
	else:
		print("Pas assez de connaissance (", Player.knowledge_poin, "/", cost, ")")

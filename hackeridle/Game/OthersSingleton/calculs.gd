extends Node

func calcul_learning_item_price(level)-> int:
	"""Fonction qui renvoie le prix de l'item"""
	# ATTENTION TODO faut que l'item price correspond au prix actuel
	
	# on part des paramètres donnés pour calculer le prix de l'item
	
	var calcul = level +1   # TODO

	return int(calcul)


func total_learning_prices(base_level, quantity):
	var total_price = 0
	for i in range(quantity):
		total_price += calcul_learning_item_price(base_level + i) 
		
	return total_price


func calcul_hacking_item_price(level)-> int:
	"""Fonction qui renvoie le prix de l'item"""
	# ATTENTION TODO faut que l'item price correspond au prix actuel
	
	# on part des paramètres donnés pour calculer le prix de l'item
	
	var calcul = level  + 1 # TODO

	return int(calcul)

func total_hacking_prices(base_level, quantity):
	var total_price = 0
	for i in range(quantity):
		total_price += calcul_hacking_item_price(base_level + i) 
		
	return total_price

func gain_knowledge_point(learning_item_name) -> int:
	"""combien tu gagnes de points de connaissance selon l'item actuel présent dans l'inventaire"""
	if !Player.has_learning_item(learning_item_name): # item pas présent. 
		
		push_warning("L'item n'est pas présent !")
	
	var item = Player.learning_item_bought[learning_item_name]
	
	#faire le calcul
	return item["cost"] * item["level"]
	
func passif_learning_gain(level, delay, base_point) -> float:
	"""Le gain passif selon le delais de l'item, son niveau et son gain de base par seconde"""
	var calcul = (base_point * level) / delay
	
	return calcul


func gain_gold(hacking_item_name):
	if !Player.has_hacking_item(hacking_item_name): # item pas présent. 
		
		push_warning("L'item n'est pas présent !")
	
	var item = Player.hacking_item_bought[hacking_item_name]
	
	#faire le calcul
	return item["cost"] * item["level"]
	

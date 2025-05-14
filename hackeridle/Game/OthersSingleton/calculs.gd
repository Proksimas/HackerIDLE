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
	
	var calcul = level + 1

	return int(calcul)

#func total_hacking_prices(base_level, quantity):
	#
#
	#var total_price = 0
	#for i in range(quantity):
		#total_price += calcul_hacking_item_price(base_level + i) 
		#
	#return int(total_price)

func total_hacking_prices(current_item_cara, quantity):
	var calcul
	var current_level = current_item_cara["level"]
	
	if item_cara["formule_type"] == "polymoniale":
	
	else: #exponentiel
		calcul = current_item_cara["cost"] *
	
func passif_learning_gain(item_cara) -> float:
	"""Le gain passif selon le delais de l'item, son niveau et son gain de base par seconde"""
	
	if item_cara["formule_type"] == "polymoniale":
		return snapped(item_cara["gain"] * pow(item_cara["level"],item_cara["gain_factor"]), 0.1)
	
	else:
		return snapped(item_cara["gain"] * pow(1 + item_cara["gain_factor"], item_cara["level"] -1),0.1)

func gain_gold(hacking_item_name):
	if !Player.has_hacking_item(hacking_item_name): # item pas présent. 
		
		push_warning("L'item n'est pas présent !")
	
	var item = Player.hacking_item_bought[hacking_item_name]
	if item["formule_type"] == "polymoniale":
		return int(item["gain"] * pow(item["level"],item["gain_factor"]))
	else:
		return int(item["gain"] * pow(1 + item["gain_factor"], item["level"] -1))
	

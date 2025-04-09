extends Node

func calcul_learning_item_price(level)-> int:
	"""Fonction qui renvoie le prix de l'item"""
	# ATTENTION TODO faut que l'item price correspond au prix actuel
	
	# on part des paramètres donnés pour calculer le prix de l'item
	
	var calcul = level    # TODO

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
	
	var calcul = level    # TODO

	return int(calcul)


func total_hacking_prices(base_level, quantity):
	var total_price = 0
	for i in range(quantity):
		total_price += calcul_hacking_item_price(base_level + i) 
		
	return total_price

extends Node

func quantity_learning_item_to_buy(current_item_cara):
	var quantity = 0
	var c = current_item_cara["cost"]
	var n = current_item_cara["level"]
	var r = current_item_cara["cost_factor"]

	var p_next = (c * pow(r, n-1))
	
	if Player.gold < p_next:
		return 0 #on ne peut rien acheter
	
	var a = (r - 1) * Player.gold / p_next + 1
	quantity = floor( log(a) / log(r))
	return quantity
	
func quantity_hacking_item_to_buy(current_item_cara):
	var quantity = 0
	var c = current_item_cara["cost"]
	var n = current_item_cara["level"]
	var r = current_item_cara["cost_factor"]
	var p_next = (c * pow(r, n-1))

	
	if Player.knowledge_point < p_next:
		return 0 #on ne peut rien acheter
	
	var a = (r - 1) * Player.knowledge_point / p_next + 1
	quantity = floor( log(a) / log(r))
	return quantity


func total_learning_prices(current_item_cara, quantity):
	var calcul
	var c = current_item_cara["cost"]
	var n = current_item_cara["level"]
	var k = quantity
	var r = current_item_cara["cost_factor"]
	
#	if current_item_cara["formule_type"] == "polymoniale":
	#calcul = c * (( pow(n + k, lambda + 1) - pow(n, lambda + 1)) / (lambda + 1) )
	#ATTENTION on est dans une forme exponentielle simple POUR LE MOMENT  
	calcul = (c * pow(r,n-1)) * ( (pow(r,k) -1 ) / (r -1) )
	
	#TODO GERER LE CAS OU L ITEM EST AU NIVEAU 0
	
	return round(calcul)
	

func total_hacking_prices(current_item_cara, quantity):
	var calcul
	var c = current_item_cara["cost"]
	var n = current_item_cara["level"]
	var k = quantity
	var r = current_item_cara["cost_factor"]
	
#	if current_item_cara["formule_type"] == "polymoniale":
	#calcul = c * (( pow(n + k, lambda + 1) - pow(n, lambda + 1)) / (lambda + 1) )
	#ATTENTION on est dans une forme exponentielle simple POUR LE MOMENT  
	calcul = (c * pow(r,n-1)) * ( (pow(r,k) -1 ) / (r -1) )
	
	#TODO GERER LE CAS OU L ITEM EST AU NIVEAU 0
	
	return round(calcul)
	
	
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
		return round(item["gain"] * pow(item["level"],item["gain_factor"]))
	else:
		return round(item["gain"] * pow(1 + item["gain_factor"], item["level"] -1))
	

func get_next_source_level(source_cara):
	if source_cara == null:
		push_error("La source demandée n'existe pas")
	var level = source_cara["level"] 
	var c = source_cara["up_level"]
	var r = source_cara["up_factor"]

	#On est dans un calcl exponentiel
	#var calcul_expo = c * pow(1+r,level -1)
	#coef linear avec legere augmentation
	if level == 1:
		return c
	else:
		var linear_calcul = c * (level * r)
		return linear_calcul 
		

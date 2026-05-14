extends Node

var admob = null

const BANNER_ID := "ca-app-pub-3940256099942544/6300978111"
const INTERSTITIAL_ID := "ca-app-pub-3940256099942544/1033173712"
const REWARDED_ID := "ca-app-pub-3940256099942544/5224354917"

var interstitial_loaded := false
var rewarded_loaded := false


func _ready() -> void:
	if Engine.has_singleton("AdMob"):
		admob = Engine.get_singleton("AdMob")
		print("AdMob trouvé")

		_connect_signals()
		admob.initialize()

		load_interstitial()
		load_rewarded()
	else:
		print("AdMob non disponible. Normal dans l’éditeur Godot.")


func _connect_signals() -> void:
	if admob == null:
		return

	if admob.has_signal("interstitial_ad_loaded"):
		admob.interstitial_ad_loaded.connect(_on_interstitial_loaded)

	if admob.has_signal("interstitial_ad_failed_to_load"):
		admob.interstitial_ad_failed_to_load.connect(_on_interstitial_failed)

	if admob.has_signal("rewarded_ad_loaded"):
		admob.rewarded_ad_loaded.connect(_on_rewarded_loaded)

	if admob.has_signal("rewarded_ad_failed_to_load"):
		admob.rewarded_ad_failed_to_load.connect(_on_rewarded_failed)

	if admob.has_signal("rewarded_ad_user_earned_reward"):
		admob.rewarded_ad_user_earned_reward.connect(_on_reward_earned)


# -------------------------
# Banner
# -------------------------

func show_banner() -> void:
	if admob == null:
		return

	admob.load_banner(BANNER_ID)
	admob.show_banner()


func hide_banner() -> void:
	if admob == null:
		return

	admob.hide_banner()


# -------------------------
# Interstitial
# -------------------------

func load_interstitial() -> void:
	if admob == null:
		return

	interstitial_loaded = false
	admob.load_interstitial(INTERSTITIAL_ID)


func show_interstitial() -> void:
	if admob == null:
		return

	if interstitial_loaded:
		admob.show_interstitial()
		interstitial_loaded = false
		load_interstitial()
	else:
		print("Interstitial pas encore chargée")


func _on_interstitial_loaded() -> void:
	print("Interstitial chargée")
	interstitial_loaded = true


func _on_interstitial_failed(error = null) -> void:
	print("Erreur chargement interstitial : ", error)
	interstitial_loaded = false


# -------------------------
# Rewarded
# -------------------------

func load_rewarded() -> void:
	if admob == null:
		return

	rewarded_loaded = false
	admob.load_rewarded_ad(REWARDED_ID)


func show_rewarded() -> void:
	if admob == null:
		return

	if rewarded_loaded:
		admob.show_rewarded_ad()
		rewarded_loaded = false
		load_rewarded()
	else:
		print("Rewarded ad pas encore chargée")


func _on_rewarded_loaded() -> void:
	print("Rewarded chargée")
	rewarded_loaded = true


func _on_rewarded_failed(error = null) -> void:
	print("Erreur chargement rewarded : ", error)
	rewarded_loaded = false


func _on_reward_earned(reward = null) -> void:
	print("Récompense obtenue : ", reward)

	# Exemple :
	# GameManager.add_coins(100)
	# PlayerData.double_reward()

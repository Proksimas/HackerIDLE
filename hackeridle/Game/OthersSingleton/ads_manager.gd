extends Node

var debug_label_layer: CanvasLayer = null
var debug_label: Label = null
var pending_debug_text := ""

var banner_view: AdView = null
var rewarded_ad: RewardedAd = null
var pending_rewarded_show := false
var mobile_ads_available := false

const BANNER_ID_ANDROID := "ca-app-pub-3940256099942544/6300978111"
const INTERSTITIAL_ID_ANDROID := "ca-app-pub-3940256099942544/1033173712"
const REWARDED_ID_ANDROID := "ca-app-pub-3940256099942544/5224354917"

const BANNER_ID_IOS := "ca-app-pub-3940256099942544/2934735716"
const REWARDED_ID_IOS := "ca-app-pub-3940256099942544/1712485313"


func _ready() -> void:
	mobile_ads_available = Engine.has_singleton("PoingGodotAdMob")
	if not mobile_ads_available:
		print("Poing AdMob non disponible.")
		_show_debug_text("Ads: plugin indisponible")
		return

	_show_debug_text("Ads: init mobile ads")
	var on_init_listener := OnInitializationCompleteListener.new()
	on_init_listener.on_initialization_complete = _on_mobile_ads_initialized
	MobileAds.initialize(on_init_listener)


func show_banner() -> void:
	if not mobile_ads_available:
		_show_debug_text("Ads: banner impossible")
		return

	if banner_view != null:
		banner_view.destroy()
		banner_view = null

	_show_debug_text("Ads: load banner")
	var ad_size := AdSize.get_current_orientation_anchored_adaptive_banner_ad_size(AdSize.FULL_WIDTH)
	banner_view = AdView.new(_get_banner_ad_unit_id(), ad_size, AdPosition.Values.BOTTOM)
	banner_view.ad_listener = AdListener.new()
	banner_view.ad_listener.on_ad_loaded = func() -> void:
		_show_debug_text("Ads: banner chargee")
		if banner_view != null:
			banner_view.show()
			_show_debug_text("Ads: banner affichee")
	banner_view.ad_listener.on_ad_failed_to_load = func(load_ad_error: LoadAdError) -> void:
		var error_message := "Ads: echec banner"
		if load_ad_error != null and not load_ad_error.message.is_empty():
			error_message += " - " + load_ad_error.message
		_show_debug_text(error_message)
	banner_view.ad_listener.on_ad_opened = func() -> void:
		_show_debug_text("Ads: banner ouverte")
	banner_view.ad_listener.on_ad_impression = func() -> void:
		_show_debug_text("Ads: impression banner")
	banner_view.load_ad(AdRequest.new())


func hide_banner() -> void:
	if banner_view == null:
		return
	banner_view.hide()
	banner_view.destroy()
	banner_view = null
	_show_debug_text("Ads: banner retiree")


func load_interstitial() -> void:
	_show_debug_text("Ads: interstitial non migree")


func show_interstitial() -> void:
	_show_debug_text("Ads: interstitial non migree")


func load_rewarded() -> void:
	if not mobile_ads_available:
		_show_debug_text("Ads: rewarded impossible")
		return

	_show_debug_text("Ads: load rewarded")
	var load_callback := RewardedAdLoadCallback.new()
	load_callback.on_ad_loaded = func(ad: RewardedAd) -> void:
		rewarded_ad = ad
		_show_debug_text("Ads: rewarded chargee")
		rewarded_ad.full_screen_content_callback = FullScreenContentCallback.new()
		rewarded_ad.full_screen_content_callback.on_ad_showed_full_screen_content = func() -> void:
			_show_debug_text("Ads: rewarded ouverte")
		rewarded_ad.full_screen_content_callback.on_ad_dismissed_full_screen_content = func() -> void:
			_show_debug_text("Ads: rewarded fermee")
			if rewarded_ad != null:
				rewarded_ad.destroy()
				rewarded_ad = null
			load_rewarded()
		rewarded_ad.full_screen_content_callback.on_ad_failed_to_show_full_screen_content = func(ad_error: AdError) -> void:
			var error_message := "Ads: echec ouverture rewarded"
			if ad_error != null and not ad_error.message.is_empty():
				error_message += " - " + ad_error.message
			_show_debug_text(error_message)
		if pending_rewarded_show:
			pending_rewarded_show = false
			show_rewarded()
	load_callback.on_ad_failed_to_load = func(load_ad_error: LoadAdError) -> void:
		var error_message := "Ads: echec rewarded"
		if load_ad_error != null and not load_ad_error.message.is_empty():
			error_message += " - " + load_ad_error.message
		_show_debug_text(error_message)
	var loader := RewardedAdLoader.new()
	loader.load(_get_rewarded_ad_unit_id(), AdRequest.new(), load_callback)


func show_rewarded() -> void:
	if not mobile_ads_available:
		_show_debug_text("Ads: rewarded impossible")
		return

	if rewarded_ad == null:
		pending_rewarded_show = true
		_show_debug_text("Ads: rewarded en attente")
		load_rewarded()
		return

	var reward_listener := OnUserEarnedRewardListener.new()
	reward_listener.on_user_earned_reward = func(rewarded_item: RewardedItem) -> void:
		var reward_text := "Ads: recompense recue"
		if rewarded_item != null:
			reward_text += " %s %s" % [str(rewarded_item.amount), str(rewarded_item.type)]
		_show_debug_text(reward_text)
	rewarded_ad.show(reward_listener)


func _on_mobile_ads_initialized(_status: InitializationStatus) -> void:
	_show_debug_text("Ads: init ok")
	load_rewarded()


func _get_banner_ad_unit_id() -> String:
	if OS.get_name() == "iOS":
		return BANNER_ID_IOS
	return BANNER_ID_ANDROID


func _get_rewarded_ad_unit_id() -> String:
	if OS.get_name() == "iOS":
		return REWARDED_ID_IOS
	return REWARDED_ID_ANDROID


func _show_debug_text(text: String) -> void:
	_ensure_debug_label()
	if debug_label == null or not is_instance_valid(debug_label):
		pending_debug_text = text
		return
	debug_label.text = text
	debug_label.visible = true


func _ensure_debug_label() -> void:
	if debug_label != null and is_instance_valid(debug_label):
		return
	call_deferred("_create_debug_label")


func _create_debug_label() -> void:
	if debug_label != null and is_instance_valid(debug_label):
		return
	debug_label_layer = CanvasLayer.new()
	debug_label_layer.name = "AdsDebugLine"
	debug_label_layer.layer = 100
	get_tree().root.add_child(debug_label_layer)

	debug_label = Label.new()
	debug_label.name = "AdsDebugLabel"
	debug_label.offset_left = 12.0
	debug_label.offset_top = 12.0
	debug_label.offset_right = 1000.0
	debug_label.offset_bottom = 44.0
	debug_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	debug_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	debug_label.add_theme_constant_override("shadow_offset_x", 2)
	debug_label.add_theme_constant_override("shadow_offset_y", 2)
	debug_label_layer.add_child(debug_label)

	if pending_debug_text != "":
		var text := pending_debug_text
		pending_debug_text = ""
		_show_debug_text(text)

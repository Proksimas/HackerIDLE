# MarketGraph.gd
extends Control
class_name MarketGraph

@export var manager_path: NodePath
@export var history_len: int = 240            # nb de points affichés (~4 min si 1 point/s)
@export var padding_pct: float = 0.05         # marge haut/bas autour des min/max
@export var line_width: float = 2.0
@export var fill_under_curve: bool = true
@export var show_grid: bool = true
@export var grid_rows: int = 4

@export var background_color: Color = Color(0, 0, 0, 0.10)
@export var grid_color: Color = Color(1, 1, 1, 0.08)
@export var baseline_color: Color = Color(1, 1, 1, 0.25)
@export var line_color: Color = Color(0.6, 1.0, 0.6, 1.0)
@export var fill_color: Color = Color(0.6, 1.0, 0.6, 0.20)

var _history: Array[float] = []
var _min_seen: float = 1.0
var _max_seen: float = 1.0

func _ready() -> void:
	var mgr := get_node_or_null(manager_path)
	#if mgr and mgr.has_signal("market_updated"):
		#mgr.connect("market_updated", Callable(self, "_on_market_updated"))
	set_process(false) # on redessine seulement à la réception du signal

func _on_market_updated(M: float) -> void:
	print('market_updated')
	_history.append(M)
	if _history.size() > history_len:
		_history.remove_at(0)

	# Recalcule min/max dans la fenêtre courante
	var mn := 1e20
	var mx := -1e20
	for v in _history:
		mn = min(mn, v)
		mx = max(mx, v)

	if _history.size() > 0:
		_min_seen = mn
		_max_seen = mx
	else:
		_min_seen = 1.0
		_max_seen = 1.0

	queue_redraw()

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)

	# Fond
	draw_rect(r, background_color, true)

	# Grille horizontale
	if show_grid and grid_rows > 0:
		for i in range(grid_rows + 1):
			var y := float(i) * r.size.y / float(grid_rows)
			draw_line(Vector2(0.0, y), Vector2(r.size.x, y), grid_color, 1.0)

	if _history.size() < 2:
		var y1 := _map_value_to_y(1.0, 0.9, 1.1, r)
		draw_line(Vector2(0.0, y1), Vector2(r.size.x, y1), baseline_color, 1.0)
		return

	# Échelle Y (inclut baseline 1.0) + padding
	var mn = min(_min_seen, 1.0)
	var mx = max(_max_seen, 1.0)
	var pad = max(1e-6, (mx - mn) * padding_pct)
	mn -= pad
	mx += pad
	if abs(mx - mn) < 1e-6:
		mx = mn + 1e-6

	# Baseline M=1
	var y_base := _map_value_to_y(1.0, mn, mx, r)
	draw_line(Vector2(0.0, y_base), Vector2(r.size.x, y_base), baseline_color, 1.0)

	# Points 2D de la courbe
	var n := _history.size()
	var pts := PackedVector2Array()
	pts.resize(n)
	for i in range(n):
		var x := float(i) * (r.size.x / float(n - 1))
		var y := _map_value_to_y(_history[i], mn, mx, r)
		pts[i] = Vector2(x, y)

	# Remplissage sous la courbe
	if fill_under_curve:
		var poly := PackedVector2Array(pts)
		poly.append(Vector2(r.size.x, r.size.y))
		poly.append(Vector2(0.0, r.size.y))
		draw_colored_polygon(poly, fill_color)

	# Courbe
	draw_polyline(pts, line_color, line_width, true)

func _map_value_to_y(v: float, mn: float, mx: float, rect: Rect2) -> float:
	var t := (v - mn) / (mx - mn)
	t = clampf(t, 0.0, 1.0)
	return (1.0 - t) * rect.size.y

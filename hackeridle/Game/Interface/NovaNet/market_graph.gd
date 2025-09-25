# MarketGraph.gd
extends Control
class_name MarketGraph

@export var manager_path: NodePath
@export var history_len: int = 240
@export var padding_pct: float = 0.05
@export var line_width: float = 2.0
@export var fill_under_curve: bool = true
@export var show_grid: bool = true
@export var grid_rows: int = 4

@export var background_color: Color = Color(0, 0, 0, 0.10)
@export var grid_color: Color = Color(1, 1, 1, 0.08)
@export var baseline_color: Color = Color(1, 1, 1, 0.25)
@export var line_color: Color = Color(0.6, 1.0, 0.6, 1.0)
@export var fill_color: Color = Color(0.6, 1.0, 0.6, 0.20)

# Axe à gauche
@export var show_y_axis: bool = true
@export var axis_width_px: int = 56
@export var axis_tick_len: int = 6

var _history: Array[float] = []
var _min_seen: float = 1.0
var _max_seen: float = 1.0

func _ready() -> void:
	var mgr := get_node_or_null(manager_path)
	if mgr and mgr.has_signal("market_updated"):
		mgr.connect("market_updated", Callable(self, "_on_market_updated"))
	set_process(false)

func _on_market_updated(M: float) -> void:
	_history.append(M)
	if _history.size() > history_len:
		_history.remove_at(0)

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
	var full_rect := Rect2(Vector2.ZERO, size)

	# Zone de tracé (on réserve une marge pour l'axe à gauche si demandé)
	var plot_x := 0.0
	if show_y_axis:
		plot_x = float(axis_width_px)
	var plot_rect := Rect2(Vector2(plot_x, 0.0), Vector2(max(0.0, size.x - plot_x), size.y))

	# Fond
	draw_rect(full_rect, background_color, true)

	# Échelle Y (inclut baseline 1.0) + padding
	var have_series := _history.size() >= 2
	var mn: float
	var mx: float
	if have_series:
		mn = min(_min_seen, 1.0)
		mx = max(_max_seen, 1.0)
	else:
		mn = 0.95
		mx = 1.05

	var pad = max(1e-6, (mx - mn) * padding_pct)
	mn -= pad
	mx += pad
	if abs(mx - mn) < 1e-6:
		mx = mn + 1e-6

	# Grille horizontale
	if show_grid and grid_rows > 0:
		var rows := grid_rows
		var i := 0
		while i <= rows:
			var y := float(i) * plot_rect.size.y / float(rows)
			var y_abs := plot_rect.position.y + y
			draw_line(Vector2(plot_rect.position.x, y_abs),
					  Vector2(plot_rect.position.x + plot_rect.size.x, y_abs),
					  grid_color, 1.0)
			i += 1

	# Axe Y (labels à gauche)
	if show_y_axis:
		_draw_y_axis_labels(mn, mx, plot_rect)

	# Baseline M=1
	var y_base := _map_value_to_y(1.0, mn, mx, plot_rect)
	draw_line(Vector2(plot_rect.position.x, y_base),
			  Vector2(plot_rect.position.x + plot_rect.size.x, y_base),
			  baseline_color, 1.0)

	# Si pas assez de points : on s'arrête après baseline/axe
	if not have_series:
		return

	# Courbe
	var n := _history.size()
	var pts := PackedVector2Array()
	pts.resize(n)
	var j := 0
	while j < n:
		var x := plot_rect.position.x + float(j) * (plot_rect.size.x / float(n - 1))
		var y := _map_value_to_y(_history[j], mn, mx, plot_rect)
		pts[j] = Vector2(x, y)
		j += 1

	# Remplissage sous la courbe
	if fill_under_curve:
		var poly := PackedVector2Array(pts)
		poly.append(Vector2(plot_rect.position.x + plot_rect.size.x, plot_rect.position.y + plot_rect.size.y))
		poly.append(Vector2(plot_rect.position.x, plot_rect.position.y + plot_rect.size.y))
		draw_colored_polygon(poly, fill_color)

	# Ligne
	draw_polyline(pts, line_color, line_width, true)

func _draw_y_axis_labels(mn: float, mx: float, plot_rect: Rect2) -> void:
	"""Cette fonction ne sert qu'à gérer l'axe y"""
	var f := get_theme_default_font()
	if f == null:
		return
	var fs := get_theme_default_font_size()

	var ax_right := float(axis_width_px)

	# Axe vertical
	draw_line(Vector2(ax_right - 1.0, 0.0), Vector2(ax_right - 1.0, size.y), baseline_color, 1.0)

	var rows := grid_rows
	if rows < 1:
		rows = 1

	var i := 0
	while i <= rows:
		var y := float(i) * plot_rect.size.y / float(rows)
		var y_abs := plot_rect.position.y + y

		# Encoche
		draw_line(Vector2(ax_right - float(axis_tick_len), y_abs),
				  Vector2(ax_right - 1.0, y_abs),
				  baseline_color, 1.0)

		# Valeur correspondante
		var t := float(i) / float(rows)  # 0 en haut, 1 en bas
		var v := _lerp_inv_y_to_value(t, mn, mx)

		var label := ""
		# On affiche M (le facteur de gain), ex: ×1.03
		var m_val := v  # v est la valeur M à cette hauteur
		label = "+ " + Global.number_to_string(m_val)

		
		var text_size := f.get_string_size(label, fs)
		var tx := ax_right - float(axis_tick_len) - 4.0 - text_size.x
		var ty := y_abs + fs * 0.35
		draw_string(f, Vector2(tx, ty), label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs, baseline_color)

		i += 1

func _map_value_to_y(v: float, mn: float, mx: float, rect: Rect2) -> float:
	var t := (v - mn) / (mx - mn)
	t = clampf(t, 0.0, 1.0)
	return rect.position.y + (1.0 - t) * rect.size.y

func _lerp_inv_y_to_value(t_norm: float, mn: float, mx: float) -> float:
	var t := clampf(t_norm, 0.0, 1.0)
	return mn + (1.0 - t) * (mx - mn)

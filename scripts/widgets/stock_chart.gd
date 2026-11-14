extends Control
# Price chart: a line with a soft fill under it, grid lines with prices on the right, and a dot on the last
# price. With spark = true it is a bare sparkline for table rows.

var data: Array = []
var col := Color("2ee59d")
var spark := false
var base := -1.0          # dashed reference line (e.g. what you paid), -1 = none


func set_data(d: Array, c: Color, b := -1.0):
	data = d
	col = c
	base = b
	queue_redraw()


func _draw():
	if data.size() < 2:
		return
	var lo = INF
	var hi = -INF
	for v in data:
		lo = min(lo, float(v))
		hi = max(hi, float(v))
	if base > 0 and not spark:
		lo = min(lo, base)
		hi = max(hi, base)
	if hi - lo < 0.0001:
		hi = lo + 1.0
	var pad = (hi - lo) * 0.08
	lo -= pad
	hi += pad
	var axis = 0.0 if spark else 58.0
	var w = size.x - axis
	var h = size.y - (0.0 if spark else 6.0)
	var top = 0.0 if spark else 4.0
	var f = UI.fonts.get("cond")
	if not spark:
		for g in 5:
			var gy = top + h * g / 4.0
			draw_line(Vector2(0, gy), Vector2(w, gy), Color(1, 1, 1, 0.06), 1.0)
			var pv = hi - (hi - lo) * g / 4.0
			draw_string(f, Vector2(w + 8, gy + 6), _fmt(pv), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 1, 1, 0.42))
	var pts = PackedVector2Array()
	var n = data.size()
	for i in n:
		pts.append(Vector2(w * i / float(n - 1), top + h * (1.0 - (float(data[i]) - lo) / (hi - lo))))
	# soft fill under the line
	var poly = PackedVector2Array(pts)
	poly.append(Vector2(w, top + h))
	poly.append(Vector2(0, top + h))
	var cols = PackedColorArray()
	for i in n:
		cols.append(Color(col, 0.22 if not spark else 0.16))
	cols.append(Color(col, 0.0))
	cols.append(Color(col, 0.0))
	draw_polygon(poly, cols)
	if base > 0 and not spark:
		var by = top + h * (1.0 - (base - lo) / (hi - lo))
		var x = 0.0
		while x < w:
			draw_line(Vector2(x, by), Vector2(min(x + 7, w), by), Color(UI.GOLD, 0.7), 1.5)
			x += 13
		draw_string(f, Vector2(4, by - 5), "YOUR PRICE", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(UI.GOLD, 0.85))
	draw_polyline(pts, col, 1.6 if spark else 2.4, true)
	if not spark:
		var lp = pts[n - 1]
		draw_circle(lp, 7.0, Color(col, 0.25))
		draw_circle(lp, 4.0, col)


func _fmt(v: float) -> String:
	var k = G.CUR_RATE.get(G.settings.get("cur", "€"), 1.0)
	return "%.2f" % (v * k) if v * k < 100 else "%.1f" % (v * k)

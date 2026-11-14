extends Control
# Small up/down bar chart: green bars above the line for weeks in profit, red below for losses.
# values: newest first (as the bank log stores them); drawn oldest on the left.

var values: Array = []


func set_values(v: Array):
	values = v
	queue_redraw()


func _draw():
	if values.is_empty():
		return
	var top = 1.0
	for x in values:
		top = max(top, absf(float(x)))
	var n = values.size()
	var f = UI.fonts.get("cond")
	var lab_h = 16.0
	var h = size.y - lab_h
	var mid = h / 2.0
	var bw = size.x / n
	draw_line(Vector2(0, mid), Vector2(size.x, mid), Color(1, 1, 1, 0.18), 1.0)
	for k in n:
		var x = float(values[n - 1 - k])
		var bh = (mid - 4) * absf(x) / top
		var c = UI.GREEN if x >= 0 else UI.RED
		var r = Rect2(k * bw + bw * 0.18, mid - bh if x >= 0 else mid, bw * 0.64, max(bh, 1.5))
		draw_rect(r, Color(c, 0.85))
		var lab = "now" if k == n - 1 else "-%d" % (n - 1 - k)
		draw_string(f, Vector2(k * bw, size.y - 2), lab, HORIZONTAL_ALIGNMENT_CENTER, bw, 14, Color(1, 1, 1, 0.42))
	draw_string(f, Vector2(0, 14), G.money(top), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(UI.GREEN, 0.7))
	draw_string(f, Vector2(0, h - 4), "-" + G.money(top), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(UI.RED, 0.7))

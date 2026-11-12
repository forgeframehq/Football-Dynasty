extends Control
# Momentum graph: bars above the line for the home side, below for the away side.

var data: Array = []
var ch := Color.WHITE
var ca := Color.RED
var goals: Array = []   # [minute, side]


func _draw():
	var w = size.x
	var h = size.y
	var mid = h / 2.0
	draw_line(Vector2(0, mid), Vector2(w, mid), Color(1, 1, 1, 0.18), 1)
	draw_line(Vector2(w * 45.0 / 95.0, 4), Vector2(w * 45.0 / 95.0, h - 4), Color(1, 1, 1, 0.1), 1)
	var bw = w / 95.0
	for i in data.size():
		var a = 0.0
		var n = 0
		for j in range(max(0, i - 2), min(data.size(), i + 3)):
			a += data[j]
			n += 1
		a /= n
		var bh = abs(a) / 3.0 * (mid - 6)
		var x = i * bw
		if a > 0:
			draw_rect(Rect2(x, mid - bh, bw - 1, bh), ch)
		elif a < 0:
			draw_rect(Rect2(x, mid, bw - 1, bh), ca)
	for g in goals:
		var x = min(g[0], 94) * bw
		draw_circle(Vector2(x, 8 if g[1] == 0 else h - 8), 6, UI.GOLD)

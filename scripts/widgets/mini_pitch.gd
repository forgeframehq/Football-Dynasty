extends Control
# A small pitch card: the formation as dots, in the club's colours. Used by the tactical plans carousel.

var slots: Array = []
var col := Color.WHITE
var rim := Color.BLACK


func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw():
	var r = Rect2(Vector2.ZERO, size)
	draw_rect(r, Color("1f6b3c"))
	var n = 6
	for i in n:
		if i % 2 == 0:
			draw_rect(Rect2(0, size.y * i / n, size.x, size.y / n), Color("237843"))
	var w = Color(1, 1, 1, 0.45)
	draw_rect(r.grow(-3), w, false, 1.5)
	draw_line(Vector2(3, size.y / 2), Vector2(size.x - 3, size.y / 2), w, 1.5)
	draw_arc(size / 2, size.x * 0.13, 0, TAU, 32, w, 1.5)
	for yy in [0.0, 1.0]:
		var bw = size.x * 0.5
		var bh = size.y * 0.14
		draw_rect(Rect2((size.x - bw) / 2, 3 if yy == 0.0 else size.y - bh - 3, bw, bh), w, false, 1.5)
	for sl in slots:
		var y = 0.05 if sl[0] == "GK" else 0.12 + float(sl[2]) * 0.82
		var p = Vector2(size.x * (0.08 + float(sl[1]) * 0.84), size.y * (1.0 - y))
		draw_circle(p, 9.0, rim)
		draw_circle(p, 7.0, Color("f6c945") if sl[0] == "GK" else col)

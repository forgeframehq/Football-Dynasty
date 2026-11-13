extends Control
# A football shirt drawn in code: body colour, pattern, trim and the sponsor across the chest.

const PATTERNS = ["Plain", "Stripes", "Hoops", "Halves", "Sash", "Sleeves"]

var c1 := Color.WHITE
var c2 := Color.BLACK
var pat := 0
var logo: Texture2D = null
var sponsor := ""
var back := Color(0, 0, 0, 0)     # colour behind the shirt, used for the neck opening


func setup(col1: Color, col2: Color, pattern: int, sponsor_name := "", logo_tex: Texture2D = null, behind := Color("17132b")):
	c1 = col1
	c2 = col2
	pat = pattern
	sponsor = sponsor_name
	logo = logo_tex
	back = behind
	queue_redraw()


func _draw():
	var s = min(size.x, size.y / 1.08)
	var o = Vector2((size.x - s) * 0.5, (size.y - s * 1.08) * 0.5)
	var P = func(x: float, y: float) -> Vector2: return o + Vector2(x, y) * s
	var edge = Color(0, 0, 0, 0.35) if c1.get_luminance() > 0.5 else Color(1, 1, 1, 0.28)
	var sleeve = c2 if pat == 5 else c1
	# sleeves
	for sx in [-1.0, 1.0]:
		var m = func(x: float) -> float: return 0.5 + (x - 0.5) * sx
		var pts = PackedVector2Array([P.call(m.call(0.27), 0.085), P.call(m.call(0.02), 0.27), P.call(m.call(0.11), 0.43), P.call(m.call(0.27), 0.35)])
		draw_colored_polygon(pts, sleeve)
		var cuff = PackedVector2Array([P.call(m.call(0.02), 0.27), P.call(m.call(0.11), 0.43), P.call(m.call(0.135), 0.415), P.call(m.call(0.045), 0.255)])
		draw_colored_polygon(cuff, c1 if pat == 5 else c2)
		pts.append(pts[0])
		draw_polyline(pts, edge, 1.5, true)
	# body
	var x0 = 0.26
	var x1 = 0.74
	var y0 = 0.085
	var y1 = 1.04
	var body = Rect2(P.call(x0, y0), Vector2(x1 - x0, y1 - y0) * s)
	draw_rect(body, c1)
	if pat == 1:
		var n = 7
		var w = (x1 - x0) / n
		for i in range(1, n, 2):
			draw_rect(Rect2(P.call(x0 + w * i, y0), Vector2(w, y1 - y0) * s), c2)
	elif pat == 2:
		var n2 = 9
		var h = (y1 - y0) / n2
		for i in range(1, n2, 2):
			draw_rect(Rect2(P.call(x0, y0 + h * i), Vector2(x1 - x0, h) * s), c2)
	elif pat == 3:
		draw_rect(Rect2(P.call(0.5, y0), Vector2(x1 - 0.5, y1 - y0) * s), c2)
	elif pat == 4:
		draw_colored_polygon(PackedVector2Array([P.call(x0, y0), P.call(x0 + 0.15, y0), P.call(x1, y1 - 0.2), P.call(x1, y1), P.call(x1 - 0.15, y1), P.call(x0, y0 + 0.2)]), c2)
	draw_rect(body, edge, false, 1.5)
	# hem trim and collar
	draw_rect(Rect2(P.call(x0, y1 - 0.025), Vector2(x1 - x0, 0.025) * s), c2)
	var neck = PackedVector2Array()
	var ring = PackedVector2Array()
	for i in 13:
		var a = PI * i / 12.0
		neck.append(P.call(0.5 - cos(a) * 0.085, y0 - 0.004 + sin(a) * 0.075))
		ring.append(P.call(0.5 - cos(a) * 0.11, y0 - 0.004 + sin(a) * 0.1))
	draw_colored_polygon(ring, c2)
	draw_colored_polygon(neck, back)
	# sponsor across the chest, on a plate so it reads on any pattern
	if sponsor != "" or logo != null:
		var plate = Rect2(P.call(0.29, 0.4), Vector2(0.42, 0.13) * s)
		# the logos are white artwork, so they sit on a dark plate unless the shirt itself is plain and dark
		var dark = c1.get_luminance() < 0.3 and pat in [0, 5]
		if not dark:
			draw_rect(plate, Color("12121a") if logo != null else Color(1, 1, 1, 0.92))
		if logo != null:
			var ts = logo.get_size()
			var k = min(plate.size.x * 0.94 / ts.x, plate.size.y * 0.9 / ts.y)
			var r = Rect2(plate.get_center() - ts * k * 0.5, ts * k)
			draw_texture_rect(logo, r, false, Color.WHITE if not dark else Color(1, 1, 1, 1))
		else:
			var f = UI.fonts["xbold"]
			var fs = int(plate.size.y * 0.6)
			var tw = f.get_string_size(sponsor.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			if tw > plate.size.x * 0.94:
				fs = int(fs * plate.size.x * 0.94 / tw)
				tw = f.get_string_size(sponsor.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			draw_string(f, Vector2(plate.get_center().x - tw * 0.5, plate.get_center().y + fs * 0.34), sponsor.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("14141a") if not dark else Color.WHITE)

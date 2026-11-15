extends Control
# The manager's face, drawn in code in a flat illustrated style (Sudhi, 15 Nov: a face creator that works offline).
# A face is a small dictionary of option indexes (see OPTS); random(seed) makes one for AI managers.

const SKIN = ["f6dcc6", "eec3a0", "dba57c", "c08657", "9b6339", "6f4325", "4a2c18"]
const HAIRC = ["16110e", "3b2416", "6b4423", "a8743f", "d9b26a", "b3402a", "8d8d8d", "e8e4dc"]
const OUTC = ["171a24", "1f2c4f", "3a3f4a", "5b2a86", "7a1f2b", "1e5631", "c8cdd6", "8a6a3b"]
const BGC = ["2a1d48", "1b2a44", "3a1a24", "1d3a2c", "2b2b30", "4a3410"]
const OPTS = {
	"shape": ["Oval", "Round", "Square", "Long"],
	"skin": SKIN,
	"hair": ["Short", "Buzz", "Side part", "Quiff", "Slick back", "Curly", "Long", "Receding", "Bald", "Man bun"],
	"hcol": HAIRC,
	"beard": ["None", "Stubble", "Short beard", "Full beard", "Goatee", "Moustache"],
	"brow": ["Straight", "Arched", "Thick", "Angled"],
	"eyes": ["Calm", "Narrow", "Wide", "Tired"],
	"glasses": ["None", "Round", "Square", "Sunglasses"],
	"outfit": ["Suit and tie", "Open collar", "Tracksuit", "Coat and scarf", "Quarter-zip", "Polo"],
	"ocol": OUTC,
	"bg": BGC,
}
const LABELS = {"shape": "Face", "skin": "Skin", "hair": "Hair", "hcol": "Hair colour", "beard": "Beard", "brow": "Eyebrows",
	"eyes": "Eyes", "glasses": "Glasses", "outfit": "Outfit", "ocol": "Outfit colour", "bg": "Background"}

var f := {}


static func default_face() -> Dictionary:
	return {"shape": 0, "skin": 1, "hair": 2, "hcol": 1, "beard": 1, "brow": 0, "eyes": 0, "glasses": 0, "outfit": 0, "ocol": 1, "bg": 0}


static func random(sd: int) -> Dictionary:
	var r = RandomNumberGenerator.new()
	r.seed = sd
	var d = {}
	for k in OPTS:
		d[k] = r.randi() % OPTS[k].size()
	if r.randf() < 0.55:
		d.glasses = 0
	if r.randf() < 0.3:
		d.beard = 0
	if d.hair in [7, 8] and d.hcol in [4, 5]:
		d.hcol = 6
	return d


func setup(face: Dictionary) -> Control:
	f = default_face()
	for k in face:
		f[k] = face[k]
	queue_redraw()
	return self


func _c(k: String) -> Color:
	return Color.html(OPTS[k][clampi(int(f.get(k, 0)), 0, OPTS[k].size() - 1)])


func _ell(c: Vector2, rx: float, ry: float, from := 0.0, to := TAU, n := 40) -> PackedVector2Array:
	var pts = PackedVector2Array()
	for i in n + 1:
		var a = from + (to - from) * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


func _draw():
	var w = min(size.x, size.y)
	var o = Vector2((size.x - w) * 0.5, (size.y - w) * 0.5)
	var P = func(x, y): return o + Vector2(x, y) * w
	var u = w / 100.0
	var skin = _c("skin")
	var shade = skin.darkened(0.16)
	var hc = _c("hcol")
	var oc = _c("ocol")
	# background disc with a soft lighter centre
	draw_circle(P.call(0.5, 0.5), w * 0.5, _c("bg"))
	draw_circle(P.call(0.5, 0.42), w * 0.36, _c("bg").lightened(0.08))
	# everything below is clipped to the disc by drawing the torso inside it
	var cx = 0.5
	var shape = int(f.shape)
	var hw = [0.205, 0.225, 0.22, 0.19][shape]
	var hh = [0.26, 0.24, 0.245, 0.285][shape]
	var hy = 0.43
	# hair at the back (long, bun)
	var hair = int(f.hair)
	if hair == 6:
		draw_colored_polygon(_poly_rect(P, cx - hw - 0.035, hy - 0.05, cx + hw + 0.035, hy + 0.26, 0.06), hc.darkened(0.1))
	# torso / outfit
	var outfit = int(f.outfit)
	var torso = PackedVector2Array([P.call(0.14, 1.02), P.call(0.18, 0.82), P.call(0.33, 0.74), P.call(0.67, 0.74), P.call(0.82, 0.82), P.call(0.86, 1.02)])
	draw_colored_polygon(_clip(torso, P, w), oc)
	# neck
	draw_colored_polygon(PackedVector2Array([P.call(0.44, 0.6), P.call(0.56, 0.6), P.call(0.575, 0.77), P.call(0.425, 0.77)]), shade)
	match outfit:
		0, 1:   # suit: shirt V, lapels, tie for 0
			draw_colored_polygon(PackedVector2Array([P.call(0.41, 0.745), P.call(0.59, 0.745), P.call(0.5, 0.9)]), Color("eef0f4"))
			if outfit == 0:
				draw_colored_polygon(PackedVector2Array([P.call(0.485, 0.765), P.call(0.515, 0.765), P.call(0.525, 0.79), P.call(0.512, 0.9), P.call(0.488, 0.9), P.call(0.475, 0.79)]), Color("8b1e2e") if oc.get_luminance() < 0.5 else Color("1b2440"))
			else:
				draw_colored_polygon(PackedVector2Array([P.call(0.43, 0.75), P.call(0.57, 0.75), P.call(0.5, 0.83)]), skin)
			var lap = oc.lightened(0.12)
			draw_colored_polygon(PackedVector2Array([P.call(0.4, 0.745), P.call(0.47, 0.76), P.call(0.5, 0.92), P.call(0.36, 0.8)]), lap)
			draw_colored_polygon(PackedVector2Array([P.call(0.6, 0.745), P.call(0.53, 0.76), P.call(0.5, 0.92), P.call(0.64, 0.8)]), lap)
		2:      # tracksuit: zip and collar stripes
			draw_colored_polygon(PackedVector2Array([P.call(0.42, 0.74), P.call(0.58, 0.74), P.call(0.56, 0.79), P.call(0.44, 0.79)]), oc.lightened(0.18))
			draw_line(P.call(0.5, 0.79), P.call(0.5, 1.0), Color(1, 1, 1, 0.75), u * 0.9)
			draw_line(P.call(0.27, 0.79), P.call(0.2, 1.0), Color(1, 1, 1, 0.6), u * 1.4)
			draw_line(P.call(0.73, 0.79), P.call(0.8, 1.0), Color(1, 1, 1, 0.6), u * 1.4)
		3:      # coat and scarf
			draw_colored_polygon(PackedVector2Array([P.call(0.38, 0.73), P.call(0.62, 0.73), P.call(0.64, 0.8), P.call(0.36, 0.8)]), Color("c9a24a") if oc.get_luminance() < 0.4 else Color("7a1f2b"))
			draw_colored_polygon(PackedVector2Array([P.call(0.55, 0.78), P.call(0.62, 0.79), P.call(0.6, 0.98), P.call(0.53, 0.97)]), Color("c9a24a") if oc.get_luminance() < 0.4 else Color("7a1f2b"))
			draw_line(P.call(0.4, 0.8), P.call(0.47, 1.0), oc.darkened(0.3), u * 1.2)
		4:      # quarter-zip with a collar
			draw_colored_polygon(PackedVector2Array([P.call(0.41, 0.72), P.call(0.59, 0.72), P.call(0.6, 0.79), P.call(0.4, 0.79)]), oc.darkened(0.15))
			draw_line(P.call(0.5, 0.74), P.call(0.5, 0.86), Color(1, 1, 1, 0.7), u * 0.8)
		5:      # polo: collar points and buttons
			draw_colored_polygon(PackedVector2Array([P.call(0.42, 0.74), P.call(0.5, 0.79), P.call(0.45, 0.82)]), oc.lightened(0.2))
			draw_colored_polygon(PackedVector2Array([P.call(0.58, 0.74), P.call(0.5, 0.79), P.call(0.55, 0.82)]), oc.lightened(0.2))
			draw_circle(P.call(0.5, 0.83), u * 0.8, Color(1, 1, 1, 0.8))
	# ears
	draw_circle(P.call(cx - hw + 0.005, hy + 0.02), w * 0.035, shade)
	draw_circle(P.call(cx + hw - 0.005, hy + 0.02), w * 0.035, shade)
	# head
	var head = _head(P, cx, hy, hw, hh, shape)
	draw_colored_polygon(head, skin)
	# cheek shade on one side
	draw_colored_polygon(_ell(P.call(cx + hw * 0.55, hy + 0.06), w * hw * 0.35, w * hh * 0.45, -1.2, 1.4, 16), Color(shade, 0.35))
	# beard (under the hair, over the skin)
	var beard = int(f.beard)
	if beard > 0:
		var bc = hc if beard != 1 else Color(hc, 0.35)
		match beard:
			1, 2, 3:
				var depth = [0, 0.02, 0.045, 0.075][beard]
				var pts = PackedVector2Array()
				for i in 25:
					var a = PI * i / 24.0
					pts.append(P.call(cx + cos(a) * hw * 0.98, hy + 0.05 + sin(a) * (hh * 0.86 + depth)))
				for i in range(24, -1, -1):
					var a = PI * i / 24.0
					pts.append(P.call(cx + cos(a) * hw * 0.62, hy + 0.11 + sin(a) * hh * 0.42))
				draw_colored_polygon(pts, bc)
			4:
				draw_colored_polygon(_ell(P.call(cx, hy + 0.205), w * 0.05, w * 0.045), hc)
				draw_colored_polygon(_ell(P.call(cx, hy + 0.125), w * 0.07, w * 0.017), hc)
			5:
				draw_colored_polygon(_ell(P.call(cx, hy + 0.122), w * 0.075, w * 0.02), hc)
	# hair on top
	_hair(P, cx, hy, hw, hh, hair, hc, u)
	# eyebrows
	var brow = int(f.brow)
	var bw = [1.6, 1.5, 2.4, 1.8][brow] * u
	for sg in [-1.0, 1.0]:
		var a = P.call(cx + sg * 0.035, hy - 0.035 - (0.006 if brow == 1 else 0.0))
		var b = P.call(cx + sg * 0.11, hy - 0.04 + (0.012 if brow == 3 else -0.004 if brow == 1 else 0.0))
		if brow == 1:
			draw_polyline(PackedVector2Array([a, (a + b) * 0.5 + Vector2(0, -u * 1.6), b]), hc.darkened(0.2), bw)
		else:
			draw_line(a, b, hc.darkened(0.2), bw)
	# eyes
	var eyes = int(f.eyes)
	var er = [1.7, 1.2, 2.1, 1.6][eyes] * u
	for sg in [-1.0, 1.0]:
		var e = P.call(cx + sg * 0.072, hy + 0.0)
		draw_colored_polygon(_ell(e, er * 1.7, er * (0.75 if eyes == 1 else 1.05)), Color("f7f7f4"))
		draw_circle(e, er * 0.85, Color("3a2a1e"))
		draw_circle(e + Vector2(-er * 0.25, -er * 0.25), er * 0.25, Color(1, 1, 1, 0.8))
		if eyes == 3:
			draw_line(e + Vector2(-er * 1.6, er * 1.5), e + Vector2(er * 1.4, er * 1.6), Color(shade, 0.9), u * 0.7)
	# nose and mouth
	draw_polyline(PackedVector2Array([P.call(cx + 0.005, hy + 0.02), P.call(cx + 0.02, hy + 0.08), P.call(cx - 0.01, hy + 0.085)]), shade.darkened(0.15), u * 0.9)
	var mc = skin.darkened(0.42)
	draw_polyline(PackedVector2Array([P.call(cx - 0.045, hy + 0.135), P.call(cx, hy + 0.145), P.call(cx + 0.045, hy + 0.133)]), mc, u * 1.1)
	# glasses
	var gl = int(f.glasses)
	if gl > 0:
		var gc = Color("1b1b1f") if gl != 3 else Color("101014")
		for sg in [-1.0, 1.0]:
			var e = P.call(cx + sg * 0.075, hy + 0.003)
			if gl == 1:
				draw_arc(e, w * 0.042, 0, TAU, 28, gc, u * 0.9)
			else:
				var rr = Rect2(e - Vector2(w * 0.05, w * 0.032), Vector2(w * 0.1, w * 0.064))
				if gl == 3:
					draw_rect(rr, Color(0.05, 0.05, 0.07, 0.92))
				draw_rect(rr, gc, false, u * 0.9)
		draw_line(P.call(cx - 0.03, hy - 0.002), P.call(cx + 0.03, hy - 0.002), gc, u * 0.9)
	# ring
	draw_arc(P.call(0.5, 0.5), w * 0.5 - u * 0.8, 0, TAU, 64, Color("d9a63e"), u * 1.6, true)


func _head(P: Callable, cx: float, hy: float, hw: float, hh: float, shape: int) -> PackedVector2Array:
	var pts = PackedVector2Array()
	for i in 48:
		var a = TAU * i / 48.0
		var x = cos(a)
		var y = sin(a)
		var sx = hw
		var sy = hh
		if shape == 2:   # squarer jaw
			x = sign(x) * pow(absf(x), 0.7)
			if y > 0:
				y = sign(y) * pow(absf(y), 0.75)
		elif y > 0:      # chin narrows
			x *= 1.0 - y * 0.18
		pts.append(P.call(cx + x * sx, hy + 0.02 + y * sy))
	return pts


func _hair(P: Callable, cx: float, hy: float, hw: float, hh: float, hair: int, hc: Color, u: float):
	var top = hy + 0.02 - hh
	match hair:
		8:   # bald: a little shine
			draw_arc(P.call(cx - 0.06, top + 0.08), u * 6, PI * 1.1, PI * 1.6, 8, Color(1, 1, 1, 0.25), u * 1.2)
			return
		7:   # receding: sides only
			for sg in [-1.0, 1.0]:
				draw_colored_polygon(_ell(P.call(cx + sg * (hw - 0.015), hy - 0.06), hw * 100 * u * 0.18, hh * 100 * u * 0.3, sg * 0.0 + PI * 0.5 - PI * 0.5, PI * 1.5 + PI * 0.5, 16), hc)
			return
	# a cap of hair: the band between an outer ellipse (the hair line on top) and an inner one (the forehead), so it never crosses itself
	var lift = [0.03, 0.01, 0.035, 0.07, 0.028, 0.05, 0.035, 0.0, 0.0, 0.025][hair]
	var depth = [0.07, 0.05, 0.075, 0.06, 0.05, 0.08, 0.09, 0.0, 0.0, 0.06][hair]
	var shift = 0.03 if hair == 2 else 0.0      # side part: the forehead line sits off-centre
	var pts = PackedVector2Array()
	for i in 33:
		var a = PI + PI * i / 32.0
		pts.append(P.call(cx + cos(a) * (hw + 0.014), hy + 0.02 + sin(a) * (hh + lift)))
	for i in range(32, -1, -1):
		var a = PI + PI * i / 32.0
		pts.append(P.call(cx + shift * 0.5 + cos(a) * (hw - 0.004 - shift * 0.6), hy + 0.035 + sin(a) * (hh - depth)))
	var col = hc if hair != 1 else Color(hc, 0.75)
	draw_colored_polygon(pts, col)
	if hair == 5:   # curly: bumps around the cap
		for i in 9:
			var a = PI + PI * i / 8.0
			draw_circle(P.call(cx + cos(a) * (hw + 0.02), hy + 0.02 + sin(a) * (hh + lift)), u * 4.2, col)
	if hair == 9:   # bun on top
		draw_circle(P.call(cx, top - 0.03), u * 6, col)
	if hair == 6:   # long: falls at the sides
		for sg in [-1.0, 1.0]:
			draw_colored_polygon(PackedVector2Array([P.call(cx + sg * (hw + 0.012), hy - 0.05), P.call(cx + sg * (hw + 0.03), hy + 0.2), P.call(cx + sg * (hw - 0.03), hy + 0.2), P.call(cx + sg * (hw - 0.02), hy - 0.02)]), col)
	if hair == 4:   # slick back: comb lines
		for k in 3:
			draw_line(P.call(cx - 0.08 + k * 0.08, top + 0.03), P.call(cx - 0.1 + k * 0.08, top + 0.09), col.lightened(0.15), u * 0.6)


func _poly_rect(P: Callable, x0: float, y0: float, x1: float, y1: float, r: float) -> PackedVector2Array:
	return PackedVector2Array([P.call(x0 + r, y0), P.call(x1 - r, y0), P.call(x1, y0 + r), P.call(x1, y1), P.call(x0, y1), P.call(x0, y0 + r)])


func _clip(poly: PackedVector2Array, P: Callable, w: float) -> PackedVector2Array:
	# keep the torso inside the background disc
	var disc = _ell(P.call(0.5, 0.5), w * 0.497, w * 0.497, 0, TAU, 64)
	var r = Geometry2D.intersect_polygons(poly, disc)
	return r[0] if r.size() > 0 else poly

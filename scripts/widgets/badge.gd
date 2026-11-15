extends Control
# Club badge built at runtime from original artwork (assets/badges: 80 emblems, 8 shapes): a white rim, the shape
# filled in the club's colours in one of three layouts, and an emblem. Shape, layout and emblem come from a hash of
# the club's name, so a club keeps its badge in every career. No real crests are used, and an emblem that is a
# famous club's signature (Wolves' wolf, Leicester's fox...) is never given to that club.

const N_EMB = 80
const N_SHAPE = 8
const CIRCLE = 2
const RING = 3
const DIAMOND = 4
# emblem index -> clubs that must not get it
const AVOID = {1: ["Chelsea", "Aston Villa"], 2: ["Crystal Palace", "Lazio", "Benfica", "Eintracht"], 3: ["Crystal Palace", "Lazio", "Benfica", "Eintracht"],
	4: ["Wolverhampton", "Roma"], 5: ["Torino"], 7: ["Stuttgart"], 8: ["Porto"], 11: ["Leicester"], 13: ["Sheffield Wednesday"], 14: ["Tottenham"], 15: ["Swansea"], 32: ["West Ham"],
	40: ["Hull City"], 43: ["Derby County"], 45: ["Coventry"], 52: ["Crystal Palace", "Lazio", "Benfica", "Eintracht"], 78: ["Brentford"]}

static var _tex := {}
# premium badges (big sizes only): 16 gold frames from Sudhi's ChatGPT sheets, assets/badges/frames/bf_NN_rim.png
# (gold, field cut out) and bf_NN_field.png (the field, shaded grey, tinted with the club colour).
# [centre x, centre y, field size] as fractions of the frame, for placing the emblem
const PREMIUM_MIN = 0
const PMETA = [[0.496, 0.506, 0.664], [0.496, 0.498, 0.695], [0.498, 0.496, 0.801], [0.498, 0.484, 0.707], [0.498, 0.5, 0.801], [0.494, 0.586, 0.621], [0.498, 0.504, 0.684], [0.498, 0.545, 0.637], [0.498, 0.5, 0.762], [0.498, 0.498, 0.574], [0.498, 0.514, 0.746], [0.498, 0.516, 0.637], [0.498, 0.496, 0.789], [0.494, 0.547, 0.734], [0.5, 0.5, 0.609], [0.5, 0.547, 0.641]]
# the flat badge's shape -> the gold frames that look like it (the club keeps its silhouette)
# one frame per shape, so a club's crest is the same everywhere (Sudhi, 15 Nov): pointed shield, rounded shield,
# circle (laurel ring), double ring, diamond, flat-top shield (crown), curved crest (laurels + star), hexagon
const PFRAMES = [0, 1, 3, 2, 4, 5, 7, 6]
const GOLD_RIM = Color("d9a63e")
const PSHIELD = [0, 1, 5, 6, 7, 10, 12, 14, 15]
var pf := 0

var c1 := Color.WHITE
var c2 := Color.BLACK
var em := 0
var sh := 0
var lay := 0


static func tex(name: String) -> Texture2D:
	if not _tex.has(name):
		var p = "res://assets/badges/%s.png" % name
		_tex[name] = load(p) if ResourceLoader.exists(p) else null
	return _tex[name]


static func pick(key: String) -> Array:
	# [shape, emblem, layout] for a club name
	var h = key.hash() & 0x7fffffff
	var s = h % N_SHAPE
	var e = (h / N_SHAPE) % N_EMB
	var l = (h / (N_SHAPE * N_EMB)) % 3
	var guard = 0
	while AVOID.has(e) and guard < 10:
		var bad = false
		for n in AVOID[e]:
			if key.contains(n):
				bad = true
		if not bad:
			break
		e = (e + 7) % N_EMB
		guard += 1
	return [s, e, l]


func setup(c: Dictionary, sz: int):
	c1 = Color(c.c1)
	c2 = Color(c.c2)
	var key = str(c.get("name", c.get("short", "")))
	var pk = pick(key)
	sh = pk[0]
	em = pk[1]
	lay = pk[2]
	pf = PFRAMES[sh]
	# two near-identical colours would hide the layout: use white as the second colour
	if absf(c1.get_luminance() - c2.get_luminance()) < 0.12 and c1.is_equal_approx(c2):
		c2 = Color.WHITE
	custom_minimum_size = Vector2(sz, sz)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ink(on: Color, want: Color) -> Color:
	# the emblem's colour: the wanted club colour unless it would vanish on the field behind it
	if absf(want.get_luminance() - on.get_luminance()) >= 0.22:
		return want
	return Color.WHITE if on.get_luminance() < 0.55 else Color("10141f")


func _draw():
	var w = size.x
	var h = size.y
	if w >= PREMIUM_MIN and tex("frames/bf_%02d_rim" % pf) != null:
		_draw_premium(w, h)
		return
	var fill_shape = CIRCLE if sh == RING else sh
	var st = tex("sh_%d" % fill_shape)
	var et = tex("em_%02d" % em)
	if st == null:
		draw_circle(Vector2(w, h) / 2.0, w / 2.0, c1)
		return
	var full = Rect2(Vector2.ZERO, Vector2(w, h))
	var rim = max(1.5, w * 0.06)
	var inner = full.grow(-rim)
	# white rim, then the club's colours
	draw_texture_rect(st, full, false, GOLD_RIM)
	var field = c1
	match lay:
		0:
			draw_texture_rect(st, inner, false, c1)
		1:
			draw_texture_rect(st, inner, false, c1)
			draw_texture_rect(st, inner.grow(-w * 0.1), false, c2)
			field = c2
		2:
			draw_texture_rect(st, inner, false, c2)
			field = c2
	if sh == RING:
		draw_texture_rect(tex("sh_%d" % RING), inner.grow(-w * 0.02), false, Color(_ink(field, c1 if field == c2 else c2), 0.9))
	if et != null:
		var k = 0.5 if sh == DIAMOND else (0.54 if sh == RING else 0.58)
		var es = w * k
		var er = Rect2(Vector2((w - es) / 2.0, (h - es) / 2.0 + (h * 0.02 if sh in [0, 1, 5, 6] else 0.0)), Vector2(es, es))
		var want = c2 if field == c1 else c1
		draw_texture_rect(et, er, false, _ink(field, want))


func _draw_premium(w: float, h: float):
	# gold frame, field in the club's colours (shaded grey texture tinted), emblem embossed, gold rim on top
	var full = Rect2(Vector2.ZERO, Vector2(w, h))
	var ft = tex("frames/bf_%02d_field" % pf)
	var rt = tex("frames/bf_%02d_rim" % pf)
	var m = PMETA[pf]
	var field = c1
	match lay:
		0:
			draw_texture_rect(ft, full, false, c1)
		1:
			draw_texture_rect(ft, full, false, c1)
			var c = Vector2(m[0] * w, m[1] * h)
			var k = 0.8
			draw_texture_rect(ft, Rect2(c - (c - Vector2.ZERO) * k, Vector2(w, h) * k), false, c2)
			field = c2
		2:
			draw_texture_rect(ft, full, false, c2)
			field = c2
	if sh == RING:
		# the flat badge's inner ring, in the same colour
		var rs = m[2] * w * 0.9
		draw_texture_rect(tex("sh_%d" % RING), Rect2(Vector2(m[0] * w - rs / 2.0, m[1] * h - rs / 2.0), Vector2(rs, rs)), false, Color(_ink(field, c1 if field == c2 else c2), 0.9))
	var et = tex("em_%02d" % em)
	if et != null:
		var es = m[2] * w * ((0.6 if pf in PSHIELD else 0.66) if sh != RING else 0.54)
		if w < 48:
			# small badges: the frame's laurels and crowns take room, so the emblem may run over the inner rim
			es = max(es, w * (0.5 if sh == RING else 0.58))
		var cy = m[1] * h - (h * 0.03 if pf in PSHIELD else 0.0)
		var er = Rect2(Vector2(m[0] * w - es / 2.0, cy - es / 2.0), Vector2(es, es))
		var ink = _ink(field, c2 if field == c1 else c1)
		if w >= 48:
			var d = max(1.0, w * 0.012)
			draw_texture_rect(et, Rect2(er.position + Vector2(d, d * 1.4), er.size), false, Color(0, 0, 0, 0.45))
			draw_texture_rect(et, Rect2(er.position - Vector2(d, d) * 0.6, er.size), false, Color(1, 1, 1, 0.3))
		draw_texture_rect(et, er, false, ink)
	draw_texture_rect(rt, full, false)

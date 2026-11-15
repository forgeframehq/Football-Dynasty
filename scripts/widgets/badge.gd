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
	draw_texture_rect(st, full, false, Color(1, 1, 1, 0.95))
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

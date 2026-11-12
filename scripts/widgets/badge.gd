extends Control
# Procedurally drawn club badge: a shield in the club colours with its short code.
# (Original artwork generated at runtime - no real crests are used.)

var c1 := Color.WHITE
var c2 := Color.BLACK
var code := ""
var style := 0


func setup(c: Dictionary, sz: int):
	c1 = Color(c.c1)
	c2 = Color(c.c2)
	code = c.short
	style = int(c.id) % 4
	custom_minimum_size = Vector2(sz, sz)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _shield(w: float, h: float, inset: float) -> PackedVector2Array:
	var pts = PackedVector2Array()
	var l = 0.1 * w + inset
	var r = 0.9 * w - inset
	var top = 0.06 * h + inset
	var mid = 0.56 * h
	var bot = 0.96 * h - inset * 1.3
	pts.append(Vector2(l, top))
	pts.append(Vector2(r, top))
	pts.append(Vector2(r, mid))
	for i in range(1, 9):
		var t = i / 9.0
		var a = Vector2(r, mid).lerp(Vector2(r, bot * 0.86), t)
		var b = Vector2(r, bot * 0.86).lerp(Vector2(w / 2.0, bot), t)
		pts.append(a.lerp(b, t))
	pts.append(Vector2(w / 2.0, bot))
	for i in range(8, 0, -1):
		var t = i / 9.0
		var a = Vector2(l, mid).lerp(Vector2(l, bot * 0.86), t)
		var b = Vector2(l, bot * 0.86).lerp(Vector2(w / 2.0, bot), t)
		pts.append(a.lerp(b, t))
	pts.append(Vector2(l, mid))
	return pts


func _draw():
	var w = size.x
	var h = size.y
	var outer = _shield(w, h, 0.0)
	var ring = Color(1, 1, 1, 0.92)
	draw_colored_polygon(outer, ring)
	var inset = max(1.5, w * 0.045)
	var inner = _shield(w, h, inset)
	draw_colored_polygon(inner, c1)
	var l = 0.1 * w + inset
	var r = 0.9 * w - inset
	var top = 0.06 * h + inset
	match style:
		1:
			draw_rect(Rect2(l, top, r - l, h * 0.2), c2)
		2:
			draw_rect(Rect2(l, h * 0.3, r - l, h * 0.2), c2)
		3:
			draw_rect(Rect2(w / 2.0, top, r - w / 2.0, 0.56 * h - top), c2)
			var half = PackedVector2Array()
			for p in inner:
				if p.x >= w / 2.0 - 0.01 and p.y >= 0.56 * h - 0.01:
					half.append(p)
			half.append(Vector2(w / 2.0, 0.56 * h))
			if half.size() >= 3:
				draw_colored_polygon(half, c2)
	var font = UI.fonts["xbold"]
	var fs = int(h * (0.36 if code.length() <= 3 else 0.28))
	var tw = font.get_string_size(code, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var tp = Vector2((w - tw) / 2.0, h * 0.5 + fs * 0.3)
	var tc = Color.WHITE
	var oc = Color(0, 0, 0, 0.55)
	if c1.get_luminance() > 0.6 and (style == 0 or c2.get_luminance() > 0.6):
		tc = Color("10141f")
		oc = Color(1, 1, 1, 0.5)
	draw_string_outline(font, tp, code, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, max(2, int(fs * 0.22)), oc)
	draw_string(font, tp, code, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, tc)

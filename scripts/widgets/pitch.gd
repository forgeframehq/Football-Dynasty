extends Control
# Football pitch drawn in the app's dark style. Vertical for tactics, horizontal for the live match view.

var vertical := true
var ball_on := false
var ball := Vector2(0.5, 0.5)       # normalised: x along the pitch (0 = home goal), y across
var ball_color := Color.WHITE
var label := ""
var label_color := Color.WHITE
var flash := 0.0


func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func pt(u: float, w: float) -> Vector2:
	# u: along the pitch 0..1, w: across 0..1
	var m = 14.0
	if vertical:
		return Vector2(m + w * (size.x - 2 * m), size.y - m - u * (size.y - 2 * m))
	return Vector2(m + u * (size.x - 2 * m), m + w * (size.y - 2 * m))


func _draw():
	var base = StyleBoxFlat.new()
	base.bg_color = Color("0e3b2c")
	base.set_corner_radius_all(26)
	base.border_color = Color(1, 1, 1, 0.08)
	base.set_border_width_all(1)
	draw_style_box(base, Rect2(Vector2.ZERO, size))
	var stripes = 9
	for i in range(1, stripes - 1, 2):
		var a = pt(i / float(stripes), 0.0)
		var b = pt((i + 1) / float(stripes), 1.0)
		var r = Rect2(Vector2(min(a.x, b.x), min(a.y, b.y)), Vector2(abs(b.x - a.x), abs(b.y - a.y)))
		if vertical:
			r.position.x = 1
			r.size.x = size.x - 2
		else:
			r.position.y = 1
			r.size.y = size.y - 2
		draw_rect(r, Color("124735"))
	var lc = Color(1, 1, 1, 0.3)
	var lw = 2.0
	_box(0.0, 0.0, 1.0, 1.0, lc, lw)
	draw_line(pt(0.5, 0.0), pt(0.5, 1.0), lc, lw)
	var rad = (pt(0.5, 0.5) - pt(0.5, 0.5 + 0.14)).length()
	draw_arc(pt(0.5, 0.5), rad, 0, TAU, 48, lc, lw, true)
	draw_circle(pt(0.5, 0.5), 4, lc)
	_box(0.0, 0.2, 0.16, 0.8, lc, lw)
	_box(0.0, 0.36, 0.055, 0.64, lc, lw)
	_box(0.84, 0.2, 1.0, 0.8, lc, lw)
	_box(0.945, 0.36, 1.0, 0.64, lc, lw)
	if flash > 0.0:
		draw_style_box(_flash_box(), Rect2(Vector2.ZERO, size))
	if ball_on:
		var p = pt(ball.x, ball.y)
		draw_circle(p, 26, Color(ball_color, 0.14))
		draw_circle(p, 15, Color(ball_color, 0.3))
		draw_circle(p, 8, Color.WHITE)
		if label != "":
			var font = UI.fonts["xbold"]
			var fs = 30
			var tw = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var tp = Vector2(clamp(p.x - tw / 2.0, 20, size.x - tw - 20), p.y - 34 if p.y > 70 else p.y + 56)
			draw_string_outline(font, tp, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 8, Color(0, 0, 0, 0.6))
			draw_string(font, tp, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, label_color)


func _flash_box() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(ball_color, 0.35 * flash)
	sb.set_corner_radius_all(26)
	return sb


func _box(u0: float, w0: float, u1: float, w1: float, c: Color, lw: float):
	var a = pt(u0, w0)
	var b = pt(u1, w0)
	var d = pt(u1, w1)
	var e = pt(u0, w1)
	draw_polyline(PackedVector2Array([a, b, d, e, a]), c, lw, true)


func set_ball(v: Vector2):
	ball = v
	queue_redraw()


func set_flash(v: float):
	flash = v
	queue_redraw()

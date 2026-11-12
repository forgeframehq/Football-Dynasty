extends Control
# Draws the current team instructions on the tactics pitch (shape, defence, attack).

var mode := 0      # 0 none, 1 shape, 2 defence, 3 attack
var c: Dictionary = {}
var pitch: Control


func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _chev(at: Vector2, dirv: Vector2, col: Color, s := 10.0, w := 4.0):
	var perp = Vector2(-dirv.y, dirv.x)
	draw_polyline(PackedVector2Array([at - perp * s - dirv * s * 0.6, at, at + perp * s - dirv * s * 0.6]), col, w, true)


func _draw():
	if mode == 0 or c.is_empty() or pitch == null:
		return
	var ins = c.instr
	var acc = UI.accent
	if mode == 1:
		var wd = [0.5, 0.72, 0.94][ins.width]
		var lo = [0.06, 0.1, 0.15, 0.22, 0.3][c.ment]
		var hi = [0.46, 0.56, 0.7, 0.82, 0.93][c.ment]
		var a = pitch.pt(hi, 0.5 - wd / 2.0)
		var b = pitch.pt(lo, 0.5 + wd / 2.0)
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(acc, 0.16)
		sb.border_color = Color(acc, 0.9)
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(16)
		draw_style_box(sb, Rect2(a, b - a))
		for sx in [-1.0, 1.0]:
			var m = pitch.pt((lo + hi) / 2.0, 0.5 + sx * wd / 2.0)
			_chev(m + Vector2(sx * 16, 0), Vector2(sx, 0), Color(acc, 0.9) if ins.width == 2 else Color(1, 1, 1, 0.35))
		for i in c.ment + 1:
			_chev(pitch.pt(hi + 0.03 + i * 0.025, 0.5), Vector2(0, -1), Color("f6c945"), 12)
	elif mode == 2:
		var ly = [0.2, 0.3, 0.42][ins.line]
		var top = [0.5, 0.68, 0.94][c.press]
		var red = Color("ff5c72")
		for col in [0.25, 0.5, 0.75]:
			var n = int((top - ly) / 0.035)
			for i in n:
				var t = float(i) / max(1, n - 1)
				_chev(pitch.pt(ly + 0.03 + i * 0.035, col), Vector2(0, -1), Color(red, 0.95 - t * 0.7), 16, 5)
		var l = pitch.pt(ly, 0.14)
		var r = pitch.pt(ly, 0.86)
		draw_dashed_line(l, r, Color(red, 0.95), 4.0, 14.0)
		for i in 7:
			var x = pitch.pt(ly, 0.17 + i * 0.11)
			draw_rect(Rect2(x - Vector2(13, 5), Vector2(26, 10)), Color(red, 0.9))
	elif mode == 3:
		var yel = Color("f6c945")
		var len = [0.1, 0.18, 0.34][ins["pass"]]
		var cnt = [5, 4, 3][ins["pass"]]
		for i in cnt:
			var w = 0.2 + 0.6 * i / float(cnt - 1)
			var a = pitch.pt(0.42, w)
			var b = pitch.pt(0.42 + len, w + (0.5 - w) * (0.5 if ins["pass"] == 2 else 0.15))
			draw_line(a, b, Color(yel, 0.85), 4.0, true)
			_chev(b, (b - a).normalized(), yel, 9)
		for i in c.tempo + 1:
			_chev(pitch.pt(0.84 + i * 0.03, 0.5), Vector2(0, -1), Color(acc, 0.95), 14, 5)
		if ins.counter:
			for sx in [0.12, 0.88]:
				var a = pitch.pt(0.3, sx)
				var b = pitch.pt(0.8, sx)
				draw_dashed_line(a, b, Color(1, 1, 1, 0.8), 3.0, 10.0)
				_chev(b, Vector2(0, -1), Color.WHITE, 10)

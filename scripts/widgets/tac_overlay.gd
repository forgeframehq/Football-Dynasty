extends Control
# Draws the current team instructions on the tactics pitch (shape, defence, attack).

var mode := 0      # 0 none, 1 shape, 2 defence, 3 attack
var c: Dictionary = {}
var pitch: Control
var show_links := false
var lines: Array = []   # [from, to, colour] for the link-ups that are switched on


func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _chev(at: Vector2, dirv: Vector2, col: Color, s := 10.0, w := 4.0):
	var perp = Vector2(-dirv.y, dirv.x)
	draw_polyline(PackedVector2Array([at - perp * s - dirv * s * 0.6, at, at + perp * s - dirv * s * 0.6]), col, w, true)


func _tag(at: Vector2, text: String, col: Color):
	var f = UI.fonts["semi"] if UI.fonts.has("semi") else ThemeDB.fallback_font
	var sz = f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
	draw_rect(Rect2(at - Vector2(5, 2), sz + Vector2(10, 4)), Color(0, 0, 0, 0.55))
	draw_string(f, at + Vector2(0, sz.y - 4), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col)


func _draw():
	if show_links:
		for l in lines:
			draw_line(l[0], l[1], Color(l[2], 0.22), 16.0, true)
			draw_line(l[0], l[1], Color(l[2], 0.95), 4.0, true)
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
		# line of engagement: where the forwards start to press
		var amber = Color("f6ad3c")
		var ey = [0.5, 0.64, 0.8][int(ins.get("eng", 1))]
		draw_dashed_line(pitch.pt(ey, 0.1), pitch.pt(ey, 0.9), Color(amber, 0.9), 3.0, 8.0)
		_tag(pitch.pt(ey, 0.1) + Vector2(4, -20), "PRESS FROM HERE", amber)
		# compactness: how narrow the block sits
		var cw = [0.2, 0.3, 0.4][int(ins.get("compact", 1))]
		for sx in [-1.0, 1.0]:
			var ta = pitch.pt(ly + 0.02, 0.5 + sx * cw)
			var tb = pitch.pt(ey - 0.02, 0.5 + sx * cw)
			draw_line(ta, tb, Color(1, 1, 1, 0.75), 3.0, true)
			_chev((ta + tb) / 2.0, Vector2(-sx, 0), Color(1, 1, 1, 0.9) if int(ins.get("compact", 1)) == 0 else Color(1, 1, 1, 0.3), 9)
		if ins.get("trap", false):
			for fx in [0.14, 0.86]:
				var fp = pitch.pt(ly, fx)
				draw_line(fp, fp + Vector2(0, -26), Color.WHITE, 3.0)
				draw_colored_polygon(PackedVector2Array([fp + Vector2(0, -26), fp + Vector2(16, -20), fp + Vector2(0, -14)]), Color("f6c945"))
			_tag(pitch.pt(ly, 0.5) + Vector2(-44, 10), "OFFSIDE TRAP", Color("f6c945"))
		var notes = []
		if int(ins.get("mark", 0)) == 1:
			notes.append("TIGHT MARKING")
		notes.append(["STAY ON FEET", "NORMAL TACKLING", "HARD TACKLING"][int(ins.get("tackle", 1))])
		_tag(pitch.pt(0.06, 0.5) + Vector2(-70, -8), " · ".join(notes), Color.WHITE)
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
		var grn = Color("2ee59d")
		var bld = int(ins.get("build", 0))
		if bld == 1:
			var a2 = pitch.pt(0.16, 0.5)
			var b2 = pitch.pt(0.4, 0.5)
			draw_line(a2, b2, Color(grn, 0.9), 7.0, true)
			_chev(b2, Vector2(0, -1), grn, 13, 6)
		elif bld == 2:
			for sx in [0.2, 0.8]:
				var a3 = pitch.pt(0.16, 0.5)
				var b3 = pitch.pt(0.38, sx)
				draw_line(a3, b3, Color(grn, 0.9), 6.0, true)
				_chev(b3, (b3 - a3).normalized(), grn, 12, 5)
		if ins.get("overlap", false):
			for sx in [0.05, 0.95]:
				var a4 = pitch.pt(0.32, sx)
				var b4 = pitch.pt(0.72, sx)
				draw_line(a4, b4, Color(grn, 0.85), 4.0, true)
				_chev(b4, Vector2(0, -1), grn, 10)
		var fin = int(ins.get("final", 0))
		var goal = pitch.pt(0.99, 0.5)
		if fin == 1:
			var pts = [pitch.pt(0.8, 0.38), pitch.pt(0.86, 0.56), pitch.pt(0.92, 0.46)]
			for i in 2:
				draw_line(pts[i], pts[i + 1], Color(yel, 0.9), 3.0, true)
			_chev(pts[2], (pts[2] - pts[1]).normalized(), yel, 8)
		elif fin == 2:
			for sx in [0.36, 0.64]:
				var a5 = pitch.pt(0.74, sx)
				draw_line(a5, goal, Color("ff5c72"), 4.0, true)
				_chev(goal, (goal - a5).normalized(), Color("ff5c72"), 10)
		var crs = int(ins.get("cross", 0))
		if fin == 3 or crs > 0:
			var from_y = 0.72 if fin == 3 else 0.9
			var tgt = [0.5, 0.46, 0.52, 0.66][crs]
			for sd in [0, 1]:
				var a6 = pitch.pt(from_y, 0.07 if sd == 0 else 0.93)
				var b6 = pitch.pt(0.93, tgt if sd == 0 else 1.0 - tgt)
				var mid = (a6 + b6) / 2.0 + Vector2(0, -34 if crs >= 2 else -6)
				var prev = a6
				for st in range(1, 9):
					var t2 = st / 8.0
					var q = a6.lerp(mid, t2).lerp(mid.lerp(b6, t2), t2)
					draw_line(prev, q, Color(1, 1, 1, 0.85), 3.0, true)
					prev = q
				_chev(b6, (b6 - mid).normalized(), Color.WHITE, 8)
		var lab = []
		if fin > 0:
			lab.append(["", "WORK IT IN", "SHOOT ON SIGHT", "CROSS EARLY"][fin])
		if crs > 0:
			lab.append(["", "LOW CROSSES", "HIGH CROSSES", "FAR POST"][crs])
		if int(ins.get("waste", 0)) > 0:
			lab.append(["", "WASTE TIME LATE ON", "WASTE TIME WHEN AHEAD"][int(ins.waste)])
		if lab.size() > 0:
			_tag(pitch.pt(0.06, 0.5) + Vector2(-90, -8), " · ".join(lab), Color.WHITE)

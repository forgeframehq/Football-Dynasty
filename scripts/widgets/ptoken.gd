extends Control
# Compact player marker for the landscape tactics pitch: role badge, name, movement arrows.

var p = null
var pos := ""
var abbr := ""
var c1 := Color.WHITE
var c2 := Color.BLACK
var selected := false
var cond := 100.0
var fitv := 1.0
var captain := false
var arrow := 0      # 0 none, 1 forward, 2 cuts inside to the right, 3 cuts inside to the left, 4 holds
var dim := false


func _init():
	custom_minimum_size = Vector2(112, 74)
	size = Vector2(112, 74)


func _draw():
	var cx = size.x / 2.0
	var cy = 30.0
	var a = 0.45 if dim else 1.0
	var r = Rect2(cx - 31, cy - 18, 62, 36)
	var sb = StyleBoxFlat.new()
	sb.set_corner_radius_all(9)
	if selected:
		var g = StyleBoxFlat.new()
		g.bg_color = Color(UI.accent, 0.35)
		g.set_corner_radius_all(14)
		draw_style_box(g, r.grow(7))
	sb.bg_color = Color(c1, a) if p != null else Color(1, 1, 1, 0.1)
	sb.border_color = UI.RED if (p != null and fitv < 0.9) else (Color(c2, a) if p != null else Color(1, 1, 1, 0.3))
	sb.set_border_width_all(2)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 4
	draw_style_box(sb, r)
	var font = UI.fonts["xbold"]
	if p == null:
		_text(font, pos, cx, cy + 8, 21, Color(1, 1, 1, 0.55))
		return
	_text(font, abbr, cx, cy + 8, 21, Color(UI.on_color(c1), a))
	draw_rect(Rect2(cx - 27, cy + 21, 54, 3), Color(0, 0, 0, 0.45))
	draw_rect(Rect2(cx - 27, cy + 21, 54 * cond / 100.0, 3), UI.cond_color(cond))
	if captain:
		draw_circle(Vector2(cx - 31, cy - 16), 9, UI.GOLD)
		_text(font, "C", cx - 31, cy - 10, 15, Color("0a0e17"))
	draw_circle(Vector2(cx + 31, cy - 16), 11, Color("0b111c"))
	_text(UI.fonts["disp"], str(p.ovr), cx + 31, cy - 11, 14, UI.ovr_color(p.ovr))
	var nm = p.ln if p.cn == "" else p.cn
	if nm.length() > 13:
		nm = nm.substr(0, 12) + "…"
	_text(UI.fonts["semi"], nm, cx, 70, 17, Color(1, 1, 1, a), true)
	if arrow > 0 and not dim:
		var col = Color("f6c945")
		for i in 3:
			var o = Vector2(0, -24 - i * 6)
			if arrow == 2:
				o = Vector2(34 + i * 5, -18 - i * 5)
			elif arrow == 3:
				o = Vector2(-34 - i * 5, -18 - i * 5)
			elif arrow == 4:
				if i > 0:
					break
				draw_line(Vector2(cx - 10, cy - 24), Vector2(cx + 10, cy - 24), Color(col, 0.9), 3)
				continue
			var c = Vector2(cx, cy) + o
			var dirv = Vector2(0, -1) if arrow == 1 else (Vector2(0.7, -0.7) if arrow == 2 else Vector2(-0.7, -0.7))
			var perp = Vector2(-dirv.y, dirv.x)
			var al = 1.0 - i * 0.25
			draw_polyline(PackedVector2Array([c - perp * 8 - dirv * 0, c + dirv * 5, c + perp * 8]), Color(col, al), 3.0, true)


func _text(font: Font, text: String, cx: float, y: float, fs: int, col: Color, shadow := false):
	var tw = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var at = Vector2(cx - tw / 2.0, y)
	if shadow:
		draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 6, Color(0, 0, 0, 0.6))
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)

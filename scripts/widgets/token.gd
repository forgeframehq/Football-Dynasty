extends Control
# Player marker used on the tactics pitch.

var p = null
var role := ""
var rname := ""
var c1 := Color.WHITE
var c2 := Color.BLACK
var selected := false
var cond := 100.0
var fitv := 1.0
var stars := 0
var captain := false


func _init():
	custom_minimum_size = Vector2(140, 128)
	size = Vector2(140, 128)


func _draw():
	var cx = size.x / 2.0
	var cy = 38.0
	var r = 32.0
	if selected:
		draw_circle(Vector2(cx, cy), r + 12, Color(UI.accent, 0.3))
		draw_arc(Vector2(cx, cy), r + 8, 0, TAU, 40, UI.accent, 4, true)
	draw_circle(Vector2(cx, cy), r + 3, Color(0, 0, 0, 0.35))
	draw_circle(Vector2(cx, cy), r, c1 if p != null else Color(1, 1, 1, 0.08))
	draw_arc(Vector2(cx, cy), r - 1.5, 0, TAU, 40, c2 if p != null else Color(1, 1, 1, 0.25), 3, true)
	var font = UI.fonts["xbold"]
	var semi = UI.fonts["cond"]
	if p == null:
		_text(font, role, cx, cy + 10, 26, Color(1, 1, 1, 0.5))
		return
	_text(font, str(p.ovr), cx, cy + 12, 34, UI.on_color(c1))
	draw_arc(Vector2(cx, cy), r + 5, -PI / 2, -PI / 2 + TAU * cond / 100.0, 40, UI.cond_color(cond), 3, true)
	if captain:
		draw_circle(Vector2(cx + r - 2, cy - r + 6), 11, UI.GOLD)
		_text(font, "C", cx + r - 2, cy - r + 13, 18, Color("0a0e17"))
	var rc = UI.LINE_COL[G.LINE.get(role, 2)]
	var warn = fitv < 0.9
	var tw = semi.get_string_size(role, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x + 14
	var tr = Rect2(cx - tw / 2.0, cy + r - 6, tw, 22)
	var sb = StyleBoxFlat.new()
	sb.bg_color = UI.RED if warn else Color("0b111c")
	sb.set_corner_radius_all(8)
	sb.border_color = rc
	sb.set_border_width_all(0 if warn else 1)
	draw_style_box(sb, tr)
	_text(semi, role, cx, tr.position.y + 17, 17, Color.WHITE if warn else rc)
	var nm = G.pname(p)
	if nm.length() > 13:
		nm = p.ln if p.cn == "" else p.cn
	if nm.length() > 13:
		nm = nm.substr(0, 12) + "…"
	_text(UI.fonts["semi"], nm, cx, 108, 19, Color.WHITE, true)
	if rname != "":
		var col = UI.GREEN if stars >= 4 else (UI.AMBER if stars == 3 else UI.RED)
		_text(semi, rname.to_upper(), cx, 125, 14, col, true)


func _text(font: Font, text: String, cx: float, y: float, fs: int, col: Color, shadow := false):
	var tw = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var pos = Vector2(cx - tw / 2.0, y)
	if shadow:
		draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 6, Color(0, 0, 0, 0.55))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)

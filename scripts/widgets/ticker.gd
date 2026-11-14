extends Control
# Scrolling ticker tape: every company's code, price and today's move, gliding right to left.
# items: [[code, price, change], ...]; tap calls on_tap with the index under the finger.

var items: Array = []
var off := 0.0
var speed := 46.0
var _widths: Array = []
var _total := 0.0
var on_tap: Callable


func _ready():
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP


func set_items(it: Array):
	items = it
	_measure()
	queue_redraw()


func _measure():
	var f = UI.fonts.get("disp")
	var g = UI.fonts.get("cond")
	_widths = []
	_total = 0.0
	for it in items:
		var w = f.get_string_size(str(it[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x + 10
		w += g.get_string_size(_price(it[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x + 22
		w += g.get_string_size(_pct(it[2]), HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x + 40
		_widths.append(w)
		_total += w


func _process(dt):
	if _total <= 0:
		return
	off = fmod(off + speed * dt, _total)
	queue_redraw()


func _price(v) -> String:
	var k = G.CUR_RATE.get(G.settings.get("cur", "€"), 1.0)
	return "%.2f" % (float(v) * k)


func _pct(v) -> String:
	return "%s%.2f%%" % ["+" if float(v) >= 0 else "", float(v) * 100.0]


func _draw():
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.28))
	if _total <= 0:
		return
	var f = UI.fonts.get("disp")
	var g = UI.fonts.get("cond")
	var y = size.y / 2.0 + 6.5
	var x = -off
	while x < size.x:
		for i in items.size():
			var w = _widths[i]
			if x + w > 0 and x < size.x:
				var it = items[i]
				var up = float(it[2]) >= 0
				var c = UI.GREEN if up else UI.RED
				var cx = x + 14
				draw_string(f, Vector2(cx, y), str(it[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, UI.TEXT)
				cx += f.get_string_size(str(it[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x + 10
				draw_string(g, Vector2(cx, y), _price(it[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.75))
				cx += g.get_string_size(_price(it[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x + 10
				var ty = size.y / 2.0
				if up:
					draw_colored_polygon(PackedVector2Array([Vector2(cx, ty + 4), Vector2(cx + 10, ty + 4), Vector2(cx + 5, ty - 4)]), c)
				else:
					draw_colored_polygon(PackedVector2Array([Vector2(cx, ty - 4), Vector2(cx + 10, ty - 4), Vector2(cx + 5, ty + 4)]), c)
				cx += 14
				draw_string(g, Vector2(cx, y), _pct(it[2]), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, c)
				draw_line(Vector2(x + w - 1, 8), Vector2(x + w - 1, size.y - 8), Color(1, 1, 1, 0.1), 1.0)
			x += w
		if _total <= 0:
			break


func _gui_input(ev):
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT and on_tap.is_valid():
		var x = fmod(ev.position.x + off, _total)
		for i in _widths.size():
			if x < _widths[i]:
				on_tap.call(i)
				return
			x -= _widths[i]

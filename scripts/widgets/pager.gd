extends Control
# Horizontal pages with swipe and dots (and vertical drag when a page is taller than the view).

var flow: Container
var page := 0
var sy := 0.0
var drag = null
var dots: Control
const DOTS_H = 18.0


func _ready():
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resized.connect(_fit)
	_fit.call_deferred()


func setup(f: Container):
	flow = f
	flow.paged = true
	add_child(flow)
	flow.minimum_size_changed.connect(_place)


func _fit():
	if flow == null:
		return
	flow.page_w = size.x
	flow.page_h = size.y - DOTS_H
	flow.size = Vector2(max(size.x, flow.get_combined_minimum_size().x), max(size.y, flow.get_combined_minimum_size().y))
	flow.queue_sort()
	_place()


func _place():
	if flow == null:
		return
	page = clampi(page, 0, max(0, flow.pages - 1))
	sy = clamp(sy, 0.0, max(0.0, flow.get_combined_minimum_size().y - (size.y - DOTS_H)))
	flow.size = Vector2(max(size.x, flow.get_combined_minimum_size().x), max(size.y, flow.get_combined_minimum_size().y))
	flow.position = Vector2(-page * size.x, -sy)
	queue_redraw()


func go(p: int):
	page = clampi(p, 0, max(0, flow.pages - 1))
	sy = 0.0
	var tw = create_tween()
	tw.tween_property(flow, "position", Vector2(-page * size.x, 0), 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	queue_redraw()


func _gui_input(e: InputEvent):
	if e is InputEventMouseButton:
		if e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				drag = {"start": e.position, "mode": 0, "sy": sy}
			elif drag != null:
				var d = e.position - drag.start
				var m = drag.mode
				drag = null
				if m == 1:
					if d.x < -50:
						go(page + 1)
					elif d.x > 50:
						go(page - 1)
					else:
						go(page)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN and e.pressed:
			sy += 60
			_place()
		elif e.button_index == MOUSE_BUTTON_WHEEL_UP and e.pressed:
			sy -= 60
			_place()
	elif e is InputEventMouseMotion and drag != null:
		var d = e.position - drag.start
		if drag.mode == 0 and d.length() > 16:
			drag.mode = 1 if absf(d.x) > absf(d.y) else 2
		if drag.mode == 1 and flow.pages > 1:
			flow.position.x = -page * size.x + d.x
		elif drag.mode == 2:
			sy = drag.sy - d.y
			_place()


func _draw():
	if flow == null or flow.pages <= 1:
		return
	var n = flow.pages
	var x0 = size.x / 2.0 - (n - 1) * 9.0
	for i in n:
		var on = i == page
		draw_rect(Rect2(x0 + i * 18.0 - (5 if on else 3), size.y - 12 - (5 if on else 3), 10 if on else 6, 10 if on else 6), Color(1, 1, 1, 0.95 if on else 0.35))

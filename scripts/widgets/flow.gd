extends Container
# Lays children out in balanced columns, keeping their order (newspaper style).
# Children with meta "glue" stay with the child that follows them.
# Children with meta "span" take the full width and start a new band.

var cols := 0
var sep := 14
var gap := 18
var min_col := 430.0
var max_w := 0.0
var _h := 0.0
var paged := false
var page_w := 0.0
var page_h := 0.0
var pages := 1
var pad := 20.0
var _w := 0.0


func _notification(what):
	if what == NOTIFICATION_SORT_CHILDREN:
		_layout()


func _get_minimum_size() -> Vector2:
	return Vector2(_w, _h)


func _count() -> int:
	if cols > 0:
		return cols
	return clampi(int(size.x / min_col), 1, 3)


func _layout_paged():
	if page_w <= 0 or page_h <= 0:
		return
	var inner = page_w - pad * 2.0
	if max_w > 0 and inner > max_w:
		inner = max_w
	var x_in = (page_w - inner) / 2.0
	var n = cols if cols > 0 else clampi(int(inner / min_col), 1, 3)
	var cw = (inner - gap * (n - 1)) / n
	var col = 0
	var y = 0.0
	var tops = {}
	var maxb = 0.0
	var cur: Array = []
	for c in get_children():
		if not (c is Control) or not c.visible:
			continue
		if c.has_meta("span"):
			if y > tops.get(col / n, 0.0) or col % n != 0:
				col = (col / n + 1) * n
			var pg = col / n
			c.size = Vector2(inner, 0)
			var h = c.get_combined_minimum_size().y
			fit_child_in_rect(c, Rect2(pg * page_w + x_in, tops.get(pg, 0.0), inner, h))
			tops[pg] = tops.get(pg, 0.0) + h + sep
			y = tops[pg]
			continue
		cur.append(c)
		if c.has_meta("glue"):
			continue
		var uh = 0.0
		for k in cur:
			if absf(k.size.x - cw) > 0.5:
				k.size = Vector2(cw, 0)
			uh += k.get_combined_minimum_size().y + sep
		var top = tops.get(col / n, 0.0)
		if y > top and y + uh - sep > page_h:
			col += 1
			y = tops.get(col / n, 0.0)
		for k in cur:
			var kh = k.get_combined_minimum_size().y
			fit_child_in_rect(k, Rect2((col / n) * page_w + x_in + (col % n) * (cw + gap), y, cw, kh))
			y += kh + sep
		maxb = max(maxb, y - sep)
		cur = []
	var np = col / n + 1
	var nw = np * page_w
	var nh = max(page_h, maxb)
	if np != pages or absf(nw - _w) > 0.5 or absf(nh - _h) > 0.5:
		pages = np
		_w = nw
		_h = nh
		update_minimum_size()


func _layout():
	if paged:
		_layout_paged()
		return
	var w = size.x
	var x0 = 0.0
	if max_w > 0 and w > max_w:
		x0 = (w - max_w) / 2.0
		w = max_w
	var n = _count()
	var cw = (w - gap * (n - 1)) / n
	var y = 0.0
	var band: Array = []
	for c in get_children():
		if not (c is Control) or not c.visible:
			continue
		if c.has_meta("span"):
			y = _band(band, n, cw, x0, y)
			band = []
			c.size = Vector2(w, 0)
			var h = c.get_combined_minimum_size().y
			fit_child_in_rect(c, Rect2(x0, y, w, h))
			y += h + sep
		else:
			band.append(c)
	y = _band(band, n, cw, x0, y)
	y = max(0.0, y - sep)
	if absf(y - _h) > 0.5:
		_h = y
		update_minimum_size()


func _band(kids: Array, n: int, cw: float, x0: float, y0: float) -> float:
	if kids.is_empty():
		return y0
	# units: glued headers travel with the next child
	var units: Array = []
	var cur: Array = []
	var total = 0.0
	for c in kids:
		cur.append(c)
		if c.has_meta("glue"):
			continue
		var h = 0.0
		for k in cur:
			k.size = Vector2(cw, 0) if absf(k.size.x - cw) > 0.5 else k.size
			h += k.get_combined_minimum_size().y + sep
		units.append([cur, h])
		total += h
		cur = []
	if not cur.is_empty():
		var h2 = 0.0
		for k in cur:
			h2 += k.get_combined_minimum_size().y + sep
		units.append([cur, h2])
		total += h2
	var target = total / n
	var col = 0
	var acc = 0.0
	var y = y0
	var maxy = y0
	for u in units:
		if col < n - 1 and acc > 0 and acc + u[1] * 0.5 > target:
			col += 1
			acc = 0.0
			y = y0
		for k in u[0]:
			var kh = k.get_combined_minimum_size().y
			fit_child_in_rect(k, Rect2(x0 + col * (cw + gap), y, cw, kh))
			y += kh + sep
		acc += u[1]
		maxy = max(maxy, y)
	return maxy

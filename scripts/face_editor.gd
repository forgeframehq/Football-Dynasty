extends RefCounted
# Face creator sheet: live preview on the left, every option on the right, Random and Done.
# open(face, on_done) edits a copy and hands it back through on_done(face) when Done is tapped.

const FACE = preload("res://scripts/widgets/face.gd")


static func make(face: Dictionary, size: float) -> Control:
	var c = FACE.new()
	c.custom_minimum_size = Vector2(size, size)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.setup(face if face != null else FACE.default_face())
	return c


static func open(face: Dictionary, on_done: Callable):
	var cur = FACE.default_face()
	if face != null:
		for k in face:
			cur[k] = face[k]
	_show(cur, on_done)


static func _show(cur: Dictionary, on_done: Callable):
	var build = func(v):
		var h = UI.hb(18)
		v.add_child(h)
		var left = UI.vb(10)
		var pv = make(cur, 230)
		left.add_child(pv)
		var rnd = UI.btn("Random", func():
			var r = FACE.random(randi())
			for k in r:
				cur[k] = r[k]
			UI.close_sheet()
			_show.call_deferred(cur, on_done), "secondary", "shuffle", 50)
		left.add_child(rnd)
		left.add_child(UI.btn("Done", func():
			UI.close_sheet()
			on_done.call(cur.duplicate()), "primary", "check", 54))
		h.add_child(left)
		var cols = UI.hb(14)
		cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(cols)
		var keys = FACE.OPTS.keys()
		var half = int(ceil(keys.size() / 2.0))
		for ci in 2:
			var cv = UI.vb(6)
			cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cols.add_child(cv)
			for k in keys.slice(ci * half, (ci + 1) * half):
				cv.add_child(UI.caps(FACE.LABELS[k], 13, UI.accent))
				var opts = FACE.OPTS[k]
				var items = []
				var row = HFlowContainer.new()
				row.add_theme_constant_override("h_separation", 5)
				row.add_theme_constant_override("v_separation", 5)
				for i in opts.size():
					var b: Control
					var s0 = str(opts[i])
					if s0.length() == 6 and s0.is_valid_hex_number():
						b = UI.panel(Color.html(s0), 8, 0, 0, Color(1, 1, 1, 0.25))
						b.custom_minimum_size = Vector2(30, 30)
					else:
						b = UI.panel(Color(UI.GOLD, 0.2), 8, 8, 4, Color(UI.GOLD, 0.6))
						b.add_child(UI.lbl(s0, 14, UI.TEXT, "semi"))
					items.append(b)
					var kk = k
					var ii = i
					var its = items
					UI.tap(b, func():
						# update in place: the preview redraws, the chosen option lights up, the rest dim
						cur[kk] = ii
						pv.setup(cur)
						for j in its.size():
							its[j].modulate = Color.WHITE if j == ii else Color(1, 1, 1, 0.4), true)
					row.add_child(b)
				for j in items.size():
					items[j].modulate = Color.WHITE if j == int(cur.get(k, 0)) else Color(1, 1, 1, 0.4)
				cv.add_child(row)
	UI.sheet("Your face", build)

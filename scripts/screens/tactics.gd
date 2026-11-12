extends "res://scripts/screens/screen.gd"
# Shape, roles, starting XI, bench, instructions, set pieces and presets.

const PITCH = preload("res://scripts/widgets/pitch.gd")
const TOKEN = preload("res://scripts/widgets/token.gd")
const MENT_SHORT = ["Bus", "Def", "Bal", "Att", "All out"]

var sel = null   # {"k": "xi"/"sub"/"res", "i": index or pid}
var pitch: Control
var drag = null  # {"t": token, "i": slot, "start": Vector2, "moved": bool}


func _init():
	show_nav = true


func build():
	var c = G.uc()
	G.fix_lineup()
	var tr = G.team_ratings(c.id)
	var chips = UI.hb(6)
	for k in [["ATT", tr.att], ["MID", tr.mid], ["DEF", tr.def]]:
		var ch = UI.vb(-4)
		var a = UI.lbl(str(k[1]), 30, UI.ovr_color(k[1]), "disp")
		a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var b = UI.caps(k[0], 15, UI.DIM)
		b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ch.add_child(a)
		ch.add_child(b)
		ch.custom_minimum_size = Vector2(52, 0)
		chips.add_child(ch)
	body.add_child(UI.topbar("Tactics", false, chips))
	var v = content(14)
	var top = UI.hb(10)
	var fb = UI.panel(UI.CARD2, 18, 18, 14, Color(1, 1, 1, 0.1))
	fb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fh = UI.hb(10)
	fh.add_child(UI.caps("Shape", 19, UI.MUTED))
	fh.add_child(UI.sp())
	fh.add_child(UI.lbl(c.formation, 30, UI.TEXT, "disp"))
	fh.add_child(UI.icon("chevron-right", 24, UI.MUTED))
	fb.add_child(fh)
	UI.tap(fb, _pick_formation, true)
	top.add_child(fb)
	top.add_child(UI.btn("Best XI", func():
		G.auto_pick(c)
		G.auto_roles(c)
		sel = null
		refresh(), "secondary", "sparkles", 66))
	top.add_child(UI.btn("Presets", _presets, "secondary", "save", 66))
	v.add_child(top)
	v.add_child(UI.caps("Tap to select · tap again for role · drag to move" if sel == null else "Tap another player to swap · tap again for his role", 19, UI.DIM if sel == null else UI.accent))
	pitch = PITCH.new()
	pitch.custom_minimum_size = Vector2(0, 900)
	v.add_child(pitch)
	var slots = G.slots_of(c)
	var c1 = Color(c.c1)
	var c2 = Color(c.c2)
	for i in 11:
		var t = TOKEN.new()
		t.role = slots[i][0]
		t.c1 = c1
		t.c2 = c2
		if c.xi[i] >= 0:
			t.p = G.s.players[c.xi[i]]
			t.cond = t.p.cond
			t.fitv = G.fit(t.p, t.role)
			t.rname = G.RL.ROLES[c.roles[i]].n
			t.stars = G.RL.stars(t.p, c.roles[i])
			t.captain = c.capt == c.xi[i]
		t.selected = sel != null and sel.k == "xi" and sel.i == i
		t.set_meta("slot", slots[i])
		t.mouse_filter = Control.MOUSE_FILTER_STOP
		var idx = i
		t.gui_input.connect(func(e): _token_input(e, t, idx))
		pitch.add_child(t)
	pitch.resized.connect(_place)
	_place.call_deferred()
	# instructions
	v.add_child(UI.section("Mentality", G.MENTALITY[c.ment]))
	v.add_child(UI.seg(MENT_SHORT, c.ment, func(i):
		c.ment = i
		refresh(), 20))
	var ins = c.instr
	for row in [["Pressing", G.PRESSING, "press", c], ["Tempo", G.TEMPO, "tempo", c], ["Width", ["Narrow", "Normal", "Wide"], "width", ins],
			["Defensive line", ["Deep", "Normal", "High"], "line", ins], ["Passing", ["Short", "Mixed", "Direct"], "pass", ins]]:
		var d = row[3]
		var key = row[2]
		v.add_child(UI.section(row[0], row[1][d[key]]))
		v.add_child(UI.seg(row[1], d[key], func(i):
			d[key] = i
			refresh(), 20))
	var ct = UI.panel(UI.CARD, 18, 18, 14, UI.accent if ins.counter else UI.LINE)
	var cth = UI.hb(10)
	cth.add_child(UI.icon("zap", 26, UI.accent if ins.counter else UI.DIM))
	var ctv = UI.vb(0)
	ctv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ctv.add_child(UI.lbl("Counter-attack", 25, UI.TEXT, "semi"))
	ctv.add_child(UI.lbl("More chances when the opposition has more of the ball", 19, UI.MUTED))
	cth.add_child(ctv)
	cth.add_child(UI.chip("ON" if ins.counter else "OFF", Color(UI.accent if ins.counter else UI.DIM, 0.16), UI.accent if ins.counter else UI.DIM, 20))
	ct.add_child(cth)
	UI.tap(ct, func():
		ins.counter = not ins.counter
		refresh())
	v.add_child(ct)
	# set pieces
	v.add_child(UI.section("Captain & set pieces"))
	var sp_card = UI.card(18, 10)
	var spv = UI.vb(0)
	for row in [["Captain", "capt", 13], ["Penalties", "pk", 17], ["Free kicks", "fk", 16], ["Corners", "ck", 3]]:
		var r = UI.panel(Color(0, 0, 0, 0), 0, 0, 10)
		var h = UI.hb(10)
		h.add_child(UI.lbl(row[0], 24, UI.MUTED))
		h.add_child(UI.sp())
		var pid = c[row[1]]
		h.add_child(UI.lbl(G.pname(G.s.players[pid]) if pid >= 0 and G.s.players.has(pid) and pid in c.players else "Auto", 24, UI.TEXT, "semi"))
		h.add_child(UI.icon("chevron-right", 22, UI.DIM))
		r.add_child(h)
		var key = row[1]
		var at = row[2]
		var title = row[0]
		UI.tap(r, func(): _pick_taker(title, key, at))
		spv.add_child(r)
	sp_card.add_child(spv)
	v.add_child(sp_card)
	# bench
	v.add_child(UI.section("Substitutes", "%d / 7" % c.bench.size()))
	for pid in c.bench:
		v.add_child(_row(G.s.players[pid], "sub"))
	var rest = []
	for pid in c.players:
		if not (pid in c.xi) and not (pid in c.bench) and not G.s.players[pid].get("youth", false):
			rest.append(G.s.players[pid])
	rest.sort_custom(func(a, b): return a.ovr > b.ovr)
	v.add_child(UI.section("Reserves", str(rest.size())))
	for p in rest:
		v.add_child(_row(p, "res"))


func _place():
	if pitch == null or not is_instance_valid(pitch):
		return
	for t in pitch.get_children():
		var sl = t.get_meta("slot")
		var p = pitch.pt(0.045 + sl[2] * 0.9, sl[1])
		t.position = p - Vector2(t.size.x / 2.0, 46)


func _token_input(e: InputEvent, t: Control, i: int):
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			drag = {"t": t, "i": i, "start": e.global_position, "moved": false, "orig": t.position}
			t.modulate = Color(1, 1, 1, 0.75)
		elif drag != null:
			var d = drag
			drag = null
			t.modulate = Color.WHITE
			if d.moved and i > 0:
				_drop(i, t.position + Vector2(t.size.x / 2.0, 46))
			else:
				t.position = d.orig
				_tap("xi", i)
	elif e is InputEventMouseMotion and drag != null and drag.t == t:
		var delta = e.global_position - drag.start
		if not drag.moved and delta.length() > 18 and i > 0:
			drag.moved = true
			t.z_index = 5
		if drag.moved:
			var np = drag.orig + delta
			np.x = clamp(np.x, -20, pitch.size.x - t.size.x + 20)
			np.y = clamp(np.y, 0, pitch.size.y - t.size.y)
			t.position = np


func _drop(i: int, centre: Vector2):
	var c = G.uc()
	var m = 14.0
	var w = clamp((centre.x - m) / (pitch.size.x - 2 * m), 0.06, 0.94)
	var u = clamp(1.0 - (centre.y - m) / (pitch.size.y - 2 * m), 0.0, 1.0)
	var y = clamp((u - 0.045) / 0.9, 0.17, 0.9)
	var pos = G.RL.zone_pos(w, y)
	c.slots[i] = [pos, snapped(w, 0.01), snapped(y, 0.01)]
	c.roles[i] = G.RL.best(G.s.players[c.xi[i]], pos) if c.xi[i] >= 0 else G.RL.BY_POS[pos][0]
	c.formation = _shape_name(c.slots)
	sel = null
	refresh()


func _shape_name(slots: Array) -> String:
	var n = [0, 0, 0, 0]
	for sl in slots:
		n[G.LINE[sl[0]]] += 1
	return "%d-%d-%d" % [n[1], n[2], n[3]]


func _row(p: Dictionary, kind: String) -> Control:
	var on = sel != null and sel.k == kind and sel.i == p.id
	var r = UI.panel(Color(UI.accent, 0.14) if on else UI.CARD, 18, 16, 10, UI.accent if on else UI.LINE)
	var h = UI.hb(12)
	h.add_child(UI.pos(p.pos))
	h.add_child(UI.lbl_fill(G.pname(p), 25, UI.TEXT if G.available(p) else UI.DIM, "semi"))
	if p.inj > 0:
		h.add_child(UI.chip("INJ", Color(UI.RED, 0.14), UI.RED, 16))
	elif p.susp > 0:
		h.add_child(UI.chip("BAN", Color(UI.RED, 0.14), UI.RED, 16))
	else:
		h.add_child(UI.caps("%d%%" % p.cond, 19, UI.cond_color(p.cond)))
	h.add_child(UI.ovr(p.ovr, 24))
	r.add_child(h)
	var pid = p.id
	UI.tap(r, func(): _tap(kind, pid))
	return r


func _tap(kind: String, i: int):
	var c = G.uc()
	if sel == null:
		if kind != "xi" and not G.available(G.s.players[i]):
			UI.toast("%s is unavailable" % G.pname(G.s.players[i]), UI.RED)
			return
		sel = {"k": kind, "i": i}
		refresh()
		return
	if sel.k == kind and sel.i == i:
		sel = null
		if kind == "xi" and c.xi[i] >= 0:
			_pick_role(i)
		refresh()
		return
	var a = sel
	var b = {"k": kind, "i": i}
	sel = null
	if a.k != "xi" and b.k == "xi":
		var tmp = a
		a = b
		b = tmp
	if a.k == "xi" and b.k == "xi":
		var x = c.xi[a.i]
		c.xi[a.i] = c.xi[b.i]
		c.xi[b.i] = x
		_fit_role(c, a.i)
		_fit_role(c, b.i)
	elif a.k == "xi":
		if not G.available(G.s.players[b.i]):
			UI.toast("%s is unavailable" % G.pname(G.s.players[b.i]), UI.RED)
			refresh()
			return
		var out = c.xi[a.i]
		c.xi[a.i] = b.i
		_fit_role(c, a.i)
		if b.k == "sub":
			var bi = c.bench.find(b.i)
			if out >= 0:
				c.bench[bi] = out
			else:
				c.bench.remove_at(bi)
	else:
		var sub_id = a.i if a.k == "sub" else b.i
		var res_id = b.i if a.k == "sub" else a.i
		if a.k == b.k:
			if a.k == "res" and c.bench.size() < 7:
				c.bench.append(a.i)
			refresh()
			return
		c.bench[c.bench.find(sub_id)] = res_id
	refresh()


func _fit_role(c: Dictionary, i: int):
	if c.xi[i] >= 0:
		c.roles[i] = G.RL.best(G.s.players[c.xi[i]], c.slots[i][0])


func _pick_role(i: int):
	var c = G.uc()
	var p = G.s.players[c.xi[i]]
	var pos = c.slots[i][0]
	var build_sheet = func(v):
		v.add_child(UI.caps("%s · playing %s" % [G.pname(p), pos], 20, UI.MUTED))
		for rid in G.RL.BY_POS[pos]:
			var rd = G.RL.ROLES[rid]
			var on = c.roles[i] == rid
			var r = UI.panel(Color(UI.accent, 0.14) if on else UI.CARD, 18, 18, 14, UI.accent if on else UI.LINE)
			var h = UI.hb(12)
			var tv = UI.vb(2)
			tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tv.add_child(UI.lbl(rd.n, 28, UI.TEXT, "disp"))
			tv.add_child(UI.wrap(rd.d, 20, UI.MUTED))
			if rd.k.size() > 0:
				var keys = []
				for k in rd.k:
					keys.append("%s %d" % [G.RL.ATTR[k], p.at[k]])
				tv.add_child(UI.wrap(" · ".join(keys), 18, UI.DIM))
			h.add_child(tv)
			h.add_child(UI.stars(50.0 + G.RL.stars(p, rid) * 7.0, 20))
			r.add_child(h)
			var id = rid
			UI.tap(r, func():
				c.roles[i] = id
				UI.close_sheet()
				refresh())
			v.add_child(r)
	UI.sheet("Player role", build_sheet)


func _pick_taker(title: String, key: String, at: int):
	var c = G.uc()
	var build_sheet = func(v):
		var auto = UI.panel(UI.CARD, 16, 18, 12, UI.accent if c[key] < 0 else UI.LINE)
		auto.add_child(UI.lbl("Auto (best available)", 24, UI.TEXT, "semi"))
		UI.tap(auto, func():
			c[key] = -1
			UI.close_sheet()
			refresh())
		v.add_child(auto)
		var list = []
		for pid in c.xi + c.bench:
			if pid >= 0 and G.s.players[pid].pos != "GK":
				list.append(G.s.players[pid])
		list.sort_custom(func(a, b): return a.at[at] > b.at[at])
		for p in list:
			var r = UI.panel(UI.CARD, 16, 18, 10, UI.accent if c[key] == p.id else UI.LINE)
			var h = UI.hb(12)
			h.add_child(UI.pos(p.pos))
			h.add_child(UI.lbl_fill(G.pname(p), 24, UI.TEXT, "semi"))
			h.add_child(UI.caps(G.RL.ATTR[at], 17, UI.DIM))
			h.add_child(UI.ovr(p.at[at], 22))
			r.add_child(h)
			var pid = p.id
			UI.tap(r, func():
				c[key] = pid
				UI.close_sheet()
				refresh())
			v.add_child(r)
	UI.sheet(title, build_sheet)


func _pick_formation():
	var c = G.uc()
	var build_sheet = func(v):
		v.add_child(UI.wrap("Pick a starting shape, then drag players on the pitch to make it your own.", 21, UI.MUTED))
		for f in G.FORMATIONS.keys():
			var on = f == c.formation
			var r = UI.panel(Color(UI.accent, 0.14) if on else UI.CARD, 18, 20, 16, UI.accent if on else UI.LINE)
			var h = UI.hb(10)
			h.add_child(UI.lbl(f, 32, UI.TEXT, "disp"))
			h.add_child(UI.sp())
			var roles = []
			for sl in G.FORMATIONS[f]:
				if sl[0] != "GK" and not (sl[0] in roles):
					roles.append(sl[0])
			h.add_child(UI.lbl(" ".join(roles), 18, UI.MUTED, "cond"))
			r.add_child(h)
			var name_f = f
			UI.tap(r, func():
				G.set_formation(c, name_f)
				G.auto_pick(c)
				G.auto_roles(c)
				UI.close_sheet()
				refresh())
			v.add_child(r)
	UI.sheet("Formation", build_sheet)


func _presets():
	var c = G.uc()
	var build_sheet = func(v):
		v.add_child(UI.wrap("Save the current shape, roles and instructions. Presets can be switched during a match from the Team menu.", 21, UI.MUTED))
		for i in 3:
			var pr = c.presets[i]
			var card = UI.card(18, 14)
			var cv = UI.vb(10)
			var h = UI.hb(10)
			h.add_child(UI.lbl("Preset %d" % (i + 1), 28, UI.TEXT, "disp"))
			h.add_child(UI.sp())
			h.add_child(UI.caps("%s · %s" % [pr.formation, G.MENTALITY[pr.ment]] if pr != null else "Empty", 19, UI.accent if pr != null else UI.DIM))
			cv.add_child(h)
			var bh = UI.hb(8)
			var idx = i
			var sb = UI.btn("Save current", func():
				c.presets[idx] = G.make_preset(c)
				UI.close_sheet()
				UI.toast("Saved to preset %d" % (idx + 1), UI.GREEN), "secondary", "", 62)
			sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			bh.add_child(sb)
			if pr != null:
				var lb = UI.btn("Load", func():
					G.apply_preset(c, c.presets[idx])
					UI.close_sheet()
					refresh(), "primary", "", 62)
				lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				bh.add_child(lb)
			cv.add_child(bh)
			card.add_child(cv)
			v.add_child(card)
	UI.sheet("Tactical presets", build_sheet)

extends "res://scripts/screens/screen.gd"
# Tactics: pitch on the left, squad list or instructions on the right, tabs across the top.

const PITCH = preload("res://scripts/widgets/pitch.gd")
const TOKEN = preload("res://scripts/widgets/ptoken.gd")
const OVERLAY = preload("res://scripts/widgets/tac_overlay.gd")
const TABS = ["Formation", "Shape", "Defence", "Attack", "Set Pieces", "Captain"]
# name, mentality, pressing, tempo, width, line, passing, counter, description
const STYLES = [
	["Gegenpress", 3, 2, 2, 1, 2, 1, false, "Win it back high and attack at once."],
	["Possession", 2, 1, 0, 1, 2, 0, false, "Short passes, patience, control."],
	["Counter", 1, 0, 2, 1, 0, 2, true, "Sit deep, then break at speed."],
	["Park the Bus", 0, 0, 0, 0, 0, 2, true, "Everyone behind the ball."],
	["Wing Play", 3, 1, 1, 2, 1, 1, false, "Stretch the pitch and cross."],
	["Route One", 2, 1, 2, 1, 1, 2, false, "Get it forward early."],
]

var tab := 0
var sel = null   # {"k": "xi"/"sub"/"res", "i": index or pid}
var pitch: Control
var drag = null  # token drag
var ldrag = null # list drag
var ghost: Control = null
var tokens: Array = []


func style_name(c: Dictionary) -> String:
	for st in STYLES:
		if c.ment == st[1] and c.press == st[2] and c.tempo == st[3] and c.instr.width == st[4] and c.instr.line == st[5] and c.instr["pass"] == st[6] and c.instr.counter == st[7]:
			return st[0]
	return "Custom"


func build():
	var c = G.uc()
	G.fix_lineup()
	var tr = G.team_ratings(c.id)
	var chips = UI.hb(6)
	for k in [["ATT", tr.att], ["MID", tr.mid], ["DEF", tr.def]]:
		var ch = UI.vb(-6)
		var a = UI.lbl(str(k[1]), 26, UI.ovr_color(k[1]), "disp")
		a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var b = UI.caps(k[0], 14, UI.DIM)
		b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ch.add_child(a)
		ch.add_child(b)
		ch.custom_minimum_size = Vector2(46, 0)
		chips.add_child(ch)
	body.add_child(UI.topbar("Tactics", false, chips))
	UI.main.t_sub = "%s · %s · %s" % [TABS[tab], c.formation, style_name(c)]
	# the pitch takes the whole height on the left; tabs and buttons sit above the list on the right
	var h = panes(12, 20)
	var left = UI.vb(8)
	left.custom_minimum_size = Vector2(clamp((UI.main.size.x - UI.main.rail_w()) * 0.44, 470, 620), 0)
	pitch = PITCH.new()
	pitch.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pitch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(pitch)
	var ov = OVERLAY.new()
	ov.mode = [0, 1, 2, 3, 0, 0][tab]
	ov.c = c
	ov.pitch = pitch
	pitch.add_child(ov)
	var slots = G.slots_of(c)
	tokens = []
	for i in 11:
		var t = TOKEN.new()
		t.pos = slots[i][0]
		t.c1 = Color(c.c1)
		t.c2 = Color(c.c2)
		t.dim = tab in [1, 2, 3]
		if c.xi[i] >= 0:
			t.p = G.s.players[c.xi[i]]
			t.cond = t.p.cond
			t.fitv = G.fit(t.p, t.pos)
			t.abbr = str(c.roles[i]).to_upper()
			t.captain = c.capt == c.xi[i]
			var rd = G.RL.ROLES[c.roles[i]]
			if c.roles[i] in ["if", "ifb"]:
				t.arrow = 2 if slots[i][1] < 0.5 else 3
			elif rd.m[0] >= 1.1:
				t.arrow = 1
			elif c.roles[i] == "anc":
				t.arrow = 4
		t.selected = sel != null and sel.k == "xi" and sel.i == i
		t.set_meta("slot", slots[i])
		t.mouse_filter = Control.MOUSE_FILTER_STOP
		var idx = i
		t.gui_input.connect(func(e): _token_input(e, t, idx))
		pitch.add_child(t)
		tokens.append(t)
	pitch.resized.connect(_place)
	_place.call_deferred()
	h.add_child(left)
	var right = UI.vb(8)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(right)
	right.add_child(UI.seg(TABS, tab, func(i):
		tab = i
		sel = null
		refresh(), 16))
	if tab == 0:
		var acts = UI.hb(6)
		for it in [["%s" % c.formation, _pick_formation], [style_name(c), _pick_style], ["Best XI", func():
				G.auto_pick(c)
				G.auto_roles(c)
				sel = null
				refresh()], ["Presets", _presets]]:
			var bt = UI.btn(it[0], it[1], "secondary", "", 42)
			bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			acts.add_child(bt)
		right.add_child(acts)
	var rp = pane(0, 6)
	rp[0].size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(rp[0])
	var v = rp[1]
	sc = rp[0].get_child(0)
	match tab:
		0: _squad_list(v, c)
		1:
			_instr(v, "Mentality", G.MENTALITY, c, "ment", "How many players commit forward. Attacking shapes create more and concede more.")
			_instr(v, "Width", ["Narrow", "Normal", "Wide"], c.instr, "width", "Narrow packs the middle of the pitch; wide stretches play out to the flanks.")
		2:
			_instr(v, "Defensive line", ["Deep", "Balanced", "High"], c.instr, "line", "A high line squeezes the pitch but leaves space in behind for quick forwards.")
			_instr(v, "Closing down", ["Sit back", "Own half", "All over"], c, "press", "Pressing all over wins the ball early and costs your players stamina.")
		3:
			_instr(v, "Passing", ["Short", "Mixed", "Direct"], c.instr, "pass", "Short passing keeps the ball; direct passing gets it forward quickly.")
			_instr(v, "Tempo", G.TEMPO, c, "tempo", "A fast tempo creates more chances and gives the ball away more often.")
			_instr(v, "Counter-attack", ["No", "Yes"], c.instr, "counter", "Break forward at speed when the opposition has more of the ball.")
		4:
			for row in [["Penalties", "pk", 17], ["Free kicks", "fk", 16], ["Corners", "ck", 3]]:
				_taker(v, c, row[0], row[1], row[2])
		5: _captain(v, c)


func _head(v: Control, text: String, right := ""):
	var hp = UI.panel(Color(UI.accent, 0.22), 8, 12, 4)
	var hh = UI.hb(8)
	hh.add_child(UI.caps(text, 20, UI.TEXT))
	hh.add_child(UI.sp())
	if right != "":
		hh.add_child(UI.caps(right, 17, UI.accent))
	hp.add_child(hh)
	v.add_child(hp)


func _instr(v: Control, title: String, options: Array, d: Dictionary, key: String, hint: String):
	var cur = int(d[key])
	_head(v, title, str(options[cur]))
	v.add_child(UI.seg(options, cur, func(i):
		d[key] = (i == 1) if typeof(d[key]) == TYPE_BOOL else i
		refresh(), 19))
	v.add_child(UI.wrap(hint, 18, UI.MUTED))
	v.add_child(UI.sp(0, 6))


func _taker(v: Control, c: Dictionary, title: String, key: String, at: int):
	var pid = c[key]
	var ok = pid >= 0 and G.s.players.has(pid) and pid in c.players
	_head(v, title, G.RL.ATTR[at])
	var r = UI.panel(UI.CARD2, 12, 14, 10, UI.LINE)
	var h = UI.hb(10)
	if ok:
		h.add_child(UI.pos(G.s.players[pid].pos, 18))
	h.add_child(UI.lbl_fill(G.pname(G.s.players[pid]) if ok else "Automatic (best available)", 23, UI.TEXT, "semi"))
	if ok:
		h.add_child(UI.ovr(G.s.players[pid].at[at], 20))
	h.add_child(UI.chip("CHANGE", Color(1, 1, 1, 0.08), UI.TEXT, 16))
	r.add_child(h)
	UI.tap(r, func(): _pick_taker(title, key, at))
	v.add_child(r)
	v.add_child(UI.sp(0, 6))


func _captain(v: Control, c: Dictionary):
	_head(v, "Captain", "Lifts morale when he plays")
	var list = []
	for pid in c.xi + c.bench:
		if pid >= 0:
			list.append(G.s.players[pid])
	list.sort_custom(func(a, b): return G.age(a) * 2 + a.ovr > G.age(b) * 2 + b.ovr)
	for p in list:
		var on = c.capt == p.id
		var r = UI.panel(Color(UI.accent, 0.16) if on else UI.CARD2, 10, 12, 6, UI.accent if on else UI.LINE)
		var h = UI.hb(10)
		h.add_child(UI.pos(p.pos, 18))
		h.add_child(UI.lbl_fill(G.pname(p), 22, UI.TEXT, "semi"))
		h.add_child(UI.lbl("%d yrs" % G.age(p), 18, UI.MUTED))
		h.add_child(UI.ovr(p.ovr, 20))
		if on:
			h.add_child(UI.chip("C", UI.GOLD, Color("0a0e17"), 16))
		r.add_child(h)
		var pid = p.id
		UI.tap(r, func():
			c.capt = pid
			refresh())
		v.add_child(r)


func _squad_list(v: Control, c: Dictionary):
	if sel != null:
		v.add_child(UI.lbl_fill("Now tap the player to swap with.", 16, UI.accent))
	_head(v, "Starting XI", "Role")
	for i in 11:
		if c.xi[i] >= 0:
			v.add_child(_row(G.s.players[c.xi[i]], "xi", i, c))
	_head(v, "Substitutes", "%d / 7" % c.bench.size())
	for pid in c.bench:
		v.add_child(_row(G.s.players[pid], "sub", -1, c))
	var rest = []
	for pid in c.players:
		if not (pid in c.xi) and not (pid in c.bench) and not G.s.players[pid].get("youth", false):
			rest.append(G.s.players[pid])
	rest.sort_custom(func(a, b): return a.ovr > b.ovr)
	_head(v, "Reserves", str(rest.size()))
	for p in rest:
		v.add_child(_row(p, "res", -1, c))


func _row(p: Dictionary, kind: String, slot: int, c: Dictionary) -> Control:
	var key = slot if kind == "xi" else p.id
	var on = sel != null and sel.k == kind and sel.i == key
	var r = UI.panel(Color(UI.accent, 0.16) if on else Color(1, 1, 1, 0.03), 10, 10, 4, UI.accent if on else Color(0, 0, 0, 0))
	var h = UI.hb(10)
	var tag = c.slots[slot][0] if kind == "xi" else ("SUB" if kind == "sub" else "RES")
	var lc = UI.LINE_COL[G.LINE.get(tag, 2)] if kind == "xi" else UI.MUTED
	h.add_child(UI.chip(tag, Color(lc, 0.16), lc, 17, 54))
	var okc = UI.GREEN if G.available(p) else UI.RED
	var dot = UI.panel(Color(0, 0, 0, 0), 9, 0, 0, okc)
	dot.get_theme_stylebox("panel").set_border_width_all(3)
	dot.custom_minimum_size = Vector2(18, 18)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(dot)
	var nv = UI.vb(-5)
	nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nv.add_child(UI.lbl_fill(G.pname(p), 21, UI.TEXT if G.available(p) else UI.DIM, "semi"))
	var alt = p.pos
	var al = p.get("alt", [])
	if typeof(al) == TYPE_ARRAY and al.size() > 0:
		alt += " / " + " / ".join(al)
	elif typeof(al) == TYPE_STRING and al != "":
		alt += " / " + al
	var state = "injured" if p.inj > 0 else ("suspended" if p.susp > 0 else "%d%% fit" % int(p.cond))
	nv.add_child(UI.lbl_fill("%s · %s" % [alt, state], 15, UI.RED if not G.available(p) else UI.MUTED))
	h.add_child(nv)
	h.add_child(UI.ovr(p.ovr, 19))
	if kind == "xi":
		var rid = c.roles[slot]
		var stars = G.RL.stars(p, rid)
		var col = UI.GREEN if stars >= 4 else (UI.AMBER if stars == 3 else UI.RED)
		var rc = UI.chip(str(rid).to_upper(), Color(col, 0.16), col, 17, 58)
		UI.tap(rc, func(): _pick_role(slot), true)
		h.add_child(rc)
	else:
		h.add_child(UI.sp(58, 0))
	r.add_child(h)
	r.mouse_filter = Control.MOUSE_FILTER_PASS
	r.gui_input.connect(func(e): _row_input(e, kind, key, G.pname(p)))
	return r


func _row_input(e: InputEvent, kind: String, key: int, nm: String):
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			ldrag = {"start": e.global_position, "kind": kind, "key": key, "on": false}
		elif ldrag != null:
			var d = ldrag
			ldrag = null
			if ghost != null:
				ghost.queue_free()
				ghost = null
			if d.on:
				for i in tokens.size():
					var t = tokens[i]
					if Rect2(t.global_position, t.size).grow(12).has_point(e.global_position):
						sel = {"k": d.kind, "i": d.key}
						_tap("xi", i)
						return
			elif d.start.distance_to(e.global_position) < 22:
				UI.sfx("click", -16.0)
				_tap(d.kind, d.key)
	elif e is InputEventMouseMotion and ldrag != null:
		var dv = e.global_position - ldrag.start
		if not ldrag.on and absf(dv.x) > 24 and absf(dv.x) > absf(dv.y) * 1.3:
			ldrag.on = true
			ghost = UI.chip(nm, UI.accent, UI.on_color(UI.accent), 20)
			ghost.z_index = 20
			ghost.top_level = true
			add_child(ghost)
		if ldrag.on and ghost != null:
			ghost.global_position = e.global_position - Vector2(50, 46)


func _pick_style():
	var c = G.uc()
	var build_sheet = func(v):
		v.add_child(UI.wrap("A style sets every team instruction in one tap. You can still change each one afterwards.", 20, UI.MUTED))
		for st in STYLES:
			var on = style_name(c) == st[0]
			var r = UI.panel(Color(UI.accent, 0.14) if on else UI.CARD, 14, 16, 10, UI.accent if on else UI.LINE)
			var h = UI.hb(10)
			var tv = UI.vb(-2)
			tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tv.add_child(UI.lbl(st[0], 26, UI.TEXT, "disp"))
			tv.add_child(UI.lbl(st[8], 18, UI.MUTED))
			h.add_child(tv)
			h.add_child(UI.caps("%s · %s" % [G.MENTALITY[st[1]], G.PRESSING[st[2]]], 16, UI.DIM))
			r.add_child(h)
			var x = st
			UI.tap(r, func():
				c.ment = x[1]
				c.press = x[2]
				c.tempo = x[3]
				c.instr.width = x[4]
				c.instr.line = x[5]
				c.instr["pass"] = x[6]
				c.instr.counter = x[7]
				UI.close_sheet()
				refresh())
			v.add_child(r)
	UI.sheet("Playing style", build_sheet)


func _place():
	if pitch == null or not is_instance_valid(pitch):
		return
	for t in tokens:
		var sl = t.get_meta("slot")
		var yy = 0.03 if sl[0] == "GK" else 0.1 + sl[2] * 0.83
		var p = pitch.pt(yy, sl[1])
		t.position = p - Vector2(t.size.x / 2.0, 30)
		# keep the whole marker, name included, inside the pitch
		t.position.y = clamp(t.position.y, 2.0, pitch.size.y - t.size.y - 6.0)


func _token_input(e: InputEvent, t: Control, i: int):
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			drag = {"t": t, "i": i, "start": e.global_position, "moved": false, "orig": t.position}
			t.modulate = Color(1, 1, 1, 0.75)
		elif drag != null:
			var d = drag
			drag = null
			t.modulate = Color.WHITE
			if d.moved:
				var centre = t.position + Vector2(t.size.x / 2.0, 30)
				for j in tokens.size():
					if j != i and (tokens[j].position + Vector2(tokens[j].size.x / 2.0, 30)).distance_to(centre) < 46:
						sel = {"k": "xi", "i": i}
						_tap("xi", j)
						return
				if i > 0 and tab == 0:
					_drop(i, centre)
				else:
					t.position = d.orig
			else:
				t.position = d.orig
				UI.sfx("click", -16.0)
				_tap("xi", i)
	elif e is InputEventMouseMotion and drag != null and drag.t == t:
		var delta = e.global_position - drag.start
		if not drag.moved and delta.length() > 18:
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
	var y = clamp((u - 0.1) / 0.83, 0.17, 0.9)
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


func _quick(kind: String, i: int):
	# quick card for a player: who he is and how he is doing, then what to do with him
	var c = G.uc()
	var p = G.s.players[c.xi[i]] if kind == "xi" else G.s.players[i]
	var build_sheet = func(v):
		var top = UI.hb(12)
		top.add_child(UI.ovr(p.ovr, 34))
		var tv = UI.vb(-3)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UI.lbl(G.pfull(p), 26, UI.TEXT, "bold"))
		var alts = p.get("alt", [])
		tv.add_child(UI.lbl("%s%s · %d yrs · %s · %s foot" % [p.pos, (" / " + " / ".join(alts)) if typeof(alts) == TYPE_ARRAY and alts.size() > 0 else "", G.age(p), p.nat, "Left" if str(p.foot).begins_with("L") else "Right"], 17, UI.MUTED))
		top.add_child(tv)
		top.add_child(UI.flag(p.nat, 44))
		v.add_child(top)
		var t1 = UI.hb(8)
		t1.add_child(UI.stat_tile("Fitness", "%d%%" % int(p.cond), UI.cond_color(p.cond)))
		t1.add_child(UI.stat_tile("Morale", str(int(p.mor)), UI.cond_color(p.mor + 10)))
		t1.add_child(UI.stat_tile("Form", "%.1f" % p.form if p.ss.ap > 0 else "-"))
		t1.add_child(UI.stat_tile("Apps / Goals", "%d / %d" % [p.ss.ap, p.ss.g]))
		v.add_child(t1)
		var g = GridContainer.new()
		g.columns = 3
		g.add_theme_constant_override("h_separation", 18)
		g.add_theme_constant_override("v_separation", 4)
		var names = ["Pace", "Shooting", "Passing", "Dribbling", "Defending", "Physical"]
		for k in 6:
			var r = UI.hb(8)
			r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			r.add_child(UI.lbl_fill(names[k], 19, UI.MUTED))
			r.add_child(UI.lbl(str(int(p.st[k])), 21, UI.ovr_color(int(p.st[k])), "disp"))
			g.add_child(r)
		v.add_child(g)
		v.add_child(UI.kv("Best role", G.RL.ROLES[G.RL.best(p, p.pos)].n))
		v.add_child(UI.kv("Wage · contract", "%s / wk · June %d" % [G.money(p.wage), p.cend]))
		if p.inj > 0:
			v.add_child(UI.kv("Injured", "back in %s" % G.inj_text(p.inj), UI.RED))
		var bh = UI.hb(8)
		var b1 = UI.btn("Swap", func():
			UI.close_sheet()
			sel = {"k": kind, "i": i}
			refresh(), "primary", "repeat", 54)
		b1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bh.add_child(b1)
		if kind == "xi":
			var b2 = UI.btn("Role", func():
				UI.close_sheet()
				_pick_role(i), "secondary", "target", 54)
			b2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			bh.add_child(b2)
		var pid = p.id
		var b3 = UI.btn("Full profile", func():
			UI.close_sheet()
			UI.main.open("player", {"pid": pid}), "secondary", "user", 54)
		b3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bh.add_child(b3)
		v.add_child(bh)
	UI.sheet(G.pname(p), build_sheet)


func _tap(kind: String, i: int):
	var c = G.uc()
	if sel == null and tab == 0 and (kind != "xi" or c.xi[i] >= 0):
		_quick(kind, i)
		return
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

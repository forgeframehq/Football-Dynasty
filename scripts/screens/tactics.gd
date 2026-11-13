extends "res://scripts/screens/screen.gd"
# Tactics: pitch on the left, squad list or instructions on the right, tabs across the top.

const PITCH = preload("res://scripts/widgets/pitch.gd")
const TOKEN = preload("res://scripts/widgets/ptoken.gd")
const OVERLAY = preload("res://scripts/widgets/tac_overlay.gd")
const TABS = ["Formation", "Playstyle", "Defence", "Attack", "Link-ups", "Set Pieces"]
const MENT_SHORT = ["Bus", "Defend", "Balance", "Attack", "All out"]

var tab := 0
var sel = null   # {"k": "xi"/"sub"/"res", "i": index or pid}
var pitch: Control
var drag = null  # token drag
var ldrag = null # list drag
var ghost: Control = null
var tokens: Array = []
var overlay: Control = null


func style_name(c: Dictionary) -> String:
	return G.TC.STYLES[G.TC.style_of(c)].n


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
	ov.show_links = tab in [0, 4]
	overlay = ov
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
		for it in [["%s" % c.formation, _pick_formation], [G.TC.STYLES[G.TC.style_of(c)].s + " style", func():
				tab = 1
				refresh()], ["Best XI", func():
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
		1: _playstyle(v, c)
		2:
			for o in G.TC.DEF_OPTS:
				_opt(v, c, o)
			_pins(v, c, "def")
		3:
			for o in G.TC.ATT_OPTS:
				_opt(v, c, o)
			_pins(v, c, "att")
		4: _links(v, c)
		5:
			for row in [["Penalties", "pk", 17], ["Free kicks", "fk", 16], ["Corners", "ck", 3]]:
				_taker(v, c, row[0], row[1], row[2])
			_captain(v, c)


func _head(v: Control, text: String, right := ""):
	var hp = UI.panel(Color(UI.accent, 0.22), 8, 12, 4)
	var hh = UI.hb(8)
	hh.add_child(UI.caps(text, 20, UI.TEXT))
	hh.add_child(UI.sp())
	if right != "":
		hh.add_child(UI.caps(right, 17, UI.accent))
	hp.add_child(hh)
	v.add_child(hp)


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
	var pid = c.capt
	var ok = pid >= 0 and G.s.players.has(pid) and pid in c.players
	_head(v, "Captain", "Composure")
	var r = UI.panel(UI.CARD2, 12, 14, 10, UI.LINE)
	var h = UI.hb(10)
	if ok:
		h.add_child(UI.pos(G.s.players[pid].pos, 18))
	h.add_child(UI.lbl_fill(G.pname(G.s.players[pid]) if ok else "Nobody chosen", 23, UI.TEXT, "semi"))
	if ok and G.TC.has(G.s.players[pid], "cap"):
		h.add_child(UI.chip("CAPTAINCY", Color(UI.GOLD, 0.16), UI.GOLD, 14))
	if ok:
		h.add_child(UI.ovr(G.s.players[pid].at[13], 20))
	h.add_child(UI.chip("CHANGE", Color(1, 1, 1, 0.08), UI.TEXT, 16))
	r.add_child(h)
	UI.tap(r, func(): _pick_captain())
	v.add_child(r)


func _pick_captain():
	var c = G.uc()
	var build_sheet = func(v):
		v.add_child(UI.wrap("A captain with composure lifts the whole team a little. One with the Captaincy skill lifts it more.", 20, UI.MUTED))
		var list = []
		for pid in c.xi + c.bench:
			if pid >= 0:
				list.append(G.s.players[pid])
		list.sort_custom(func(a, b): return (30 if G.TC.has(a, "cap") else 0) + a.at[13] > (30 if G.TC.has(b, "cap") else 0) + b.at[13])
		for p in list:
			var on = c.capt == p.id
			var r = UI.panel(Color(UI.accent, 0.16) if on else UI.CARD, 14, 16, 8, UI.accent if on else UI.LINE)
			var h = UI.hb(10)
			h.add_child(UI.pos(p.pos, 18))
			h.add_child(UI.lbl_fill(G.pname(p), 23, UI.TEXT, "semi"))
			if G.TC.has(p, "cap"):
				h.add_child(UI.chip("CAPTAINCY", Color(UI.GOLD, 0.16), UI.GOLD, 14))
			h.add_child(UI.lbl("%d yrs" % G.age(p), 18, UI.MUTED))
			h.add_child(UI.ovr(p.at[13], 20))
			r.add_child(h)
			var pid = p.id
			UI.tap(r, func():
				c.capt = pid
				UI.close_sheet()
				refresh())
			v.add_child(r)
	UI.sheet("Captain", build_sheet)


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
	var av = G.TC.arrow(p)
	h.add_child(UI.icon(G.TC.arrow_icon(av), 20, G.TC.arrow_col(av)))
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
	_link_lines()


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


# ---------------------------------------------------------------- playstyle, options, individual instructions, link-ups

func _link_lines():
	if overlay == null or not is_instance_valid(overlay):
		return
	var c = G.uc()
	var lines = []
	for l in G.TC.user_links(c):
		var a = null
		var b = null
		for t in tokens:
			if t.p != null and t.p.id == l.a:
				a = t
			elif t.p != null and t.p.id == l.b:
				b = t
		if a != null and b != null:
			lines.append([a.position + Vector2(a.size.x / 2.0, 30), b.position + Vector2(b.size.x / 2.0, 30), Color(G.TC.LEVEL_COL[l.lvl])])
	overlay.lines = lines
	overlay.queue_redraw()


func _opt(v: Control, c: Dictionary, o: Array):
	# one instruction on one line: what it is, what it costs, and the choices
	var d = c if o[4] == "c" else c.instr
	var key = o[0]
	var is_bool = typeof(d[key]) == TYPE_BOOL
	var cur = (1 if d[key] else 0) if is_bool else int(d[key])
	var r = UI.hb(10)
	var tv = UI.vb(-4)
	tv.custom_minimum_size = Vector2(232, 0)
	tv.add_child(UI.lbl(o[1], 17, UI.TEXT, "semi"))
	var dl = UI.lbl(o[3], 12, UI.DIM)
	dl.clip_text = true
	tv.add_child(dl)
	r.add_child(tv)
	var sg = UI.seg(o[2], cur, func(i):
		d[key] = (i == 1) if is_bool else i
		refresh(), 14, 5)
	sg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.add_child(sg)
	v.add_child(r)


func _playstyle(v: Control, c: Dictionary):
	var u = G.s.user
	var st = G.TC.style_of(c)
	var fit = G.TC.style_fit(c)
	var fam = int(G.TC.avg_fam(c))
	var top = UI.hb(8)
	for it in [["Style fit", str(fit), UI.cond_color(fit + 10)], ["Squad familiarity", "%d%%" % fam, UI.cond_color(fam + 10)], ["Your proficiency", str(int(u.prof[st])), UI.ovr_color(int(u.prof[st]))]]:
		var tl = UI.panel(Color(1, 1, 1, 0.04), 10, 10, 4)
		tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var th = UI.hb(6)
		th.add_child(UI.lbl_fill(it[0], 14, UI.MUTED))
		th.add_child(UI.lbl(it[1], 22, it[2], "disp"))
		tl.add_child(th)
		top.add_child(tl)
	v.add_child(top)
	for i in G.TC.STYLES.size():
		var sd = G.TC.STYLES[i]
		var on = i == st
		var r = UI.panel(Color(UI.accent, 0.16) if on else Color(1, 1, 1, 0.03), 10, 12, 5, UI.accent if on else Color(0, 0, 0, 0))
		var h = UI.hb(10)
		var tv = UI.vb(-4)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UI.lbl(sd.n, 19, UI.TEXT, "semi"))
		var dl = UI.lbl_fill(sd.d, 13, UI.MUTED if on else UI.DIM)
		tv.add_child(dl)
		h.add_child(tv)
		var bar = UI.bar(float(u.prof[i]) / 99.0, UI.ovr_color(int(u.prof[i])), 7)
		bar.custom_minimum_size = Vector2(70, 7)
		bar.size_flags_horizontal = Control.SIZE_SHRINK_END
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(bar)
		var pl = UI.lbl(str(int(u.prof[i])), 21, UI.ovr_color(int(u.prof[i])), "disp")
		pl.custom_minimum_size = Vector2(30, 0)
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		h.add_child(pl)
		r.add_child(h)
		var idx = i
		UI.tap(r, func():
			if idx == G.TC.style_of(c):
				return
			UI.confirm("Switch to %s?" % G.TC.STYLES[idx].n, "Your instructions will move to this style's defaults and the squad will need a few weeks of matches to learn it. Familiarity drops until they do.", "Switch style", func():
				G.TC.set_style(c, idx)
				refresh()), true)
		v.add_child(r)
	_opt(v, c, ["ment", "Mentality", MENT_SHORT, "How many players commit forward", "c"])
	_opt(v, c, ["width", "Width", ["Narrow", "Normal", "Wide"], "Narrow packs the middle, wide stretches play", "i"])
	# roles that do not suit the style, and a one-tap fix where the player can do a role that does
	var off = []
	var fixable = 0
	for i in range(1, 11):
		if c.xi[i] >= 0 and not G.TC.role_fits(c.roles[i], st):
			var p = G.s.players[c.xi[i]]
			var alt = G.TC.best_fit_role(p, c.slots[i][0], st)
			off.append("%s (%s%s)" % [G.pname(p), str(c.roles[i]).to_upper(), (" → " + alt.to_upper()) if alt != "" else ""])
			fixable += 1 if alt != "" else 0
	var fh = UI.hb(8)
	var ft = UI.lbl_fill(("Roles outside the style: " + ", ".join(off)) if off.size() > 0 else "Every outfield role suits this style.", 14, UI.MUTED if off.size() > 0 else UI.GREEN)
	fh.add_child(ft)
	if fixable > 0:
		fh.add_child(UI.btn("Fit %d role%s" % [fixable, "" if fixable == 1 else "s"], func():
			for i in range(1, 11):
				if c.xi[i] >= 0 and not G.TC.role_fits(c.roles[i], st):
					var alt = G.TC.best_fit_role(G.s.players[c.xi[i]], c.slots[i][0], st)
					if alt != "":
						c.roles[i] = alt
			refresh(), "secondary", "", 36))
	v.add_child(fh)


func _pins(v: Control, c: Dictionary, kind: String):
	G.TC.pins_valid(c)
	var used = G.TC.pin_count(c, kind)
	var hh = UI.hb(8)
	hh.add_child(UI.caps("Individual instructions · %d of 2" % used, 14, UI.accent))
	hh.add_child(UI.sp())
	v.add_child(UI.divider())
	v.add_child(hh)
	var row = UI.hb(6)
	for i in 11:
		var pn = c.pins[i]
		if pn == "" or G.TC.PINS[pn].k != kind:
			continue
		var p = G.s.players[c.xi[i]]
		var r = UI.panel(Color(UI.accent, 0.14), 8, 10, 5, Color(UI.accent, 0.5))
		r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var h = UI.hb(6)
		var tv = UI.vb(-4)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UI.lbl_fill(G.pname(p), 16, UI.TEXT, "semi"))
		var sub = G.TC.PINS[pn].n
		if pn == "tm":
			sub += " · " + (G.pname(G.s.players[c.tm_pid]) if c.tm_pid >= 0 and G.s.players.has(c.tm_pid) else "their best forward")
		tv.add_child(UI.lbl_fill(sub, 12, UI.accent))
		h.add_child(tv)
		var x = UI.panel(Color(1, 1, 1, 0.08), 8, 6, 4)
		x.add_child(UI.icon("x", 16, UI.MUTED))
		var idx = i
		UI.tap(x, func():
			c.pins[idx] = ""
			refresh(), true)
		h.add_child(x)
		r.add_child(h)
		if pn == "tm":
			UI.tap(r, func(): _pick_target())
		row.add_child(r)
	if used < 2:
		var add = UI.btn("Add instruction", func(): _pick_pin(kind), "ghost", "plus", 40)
		add.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(add)
	v.add_child(row)


func _pick_pin(kind: String):
	var c = G.uc()
	var build_sheet = func(v):
		v.add_child(UI.wrap("Give one player a job of his own. Tap a name to assign it.", 20, UI.MUTED))
		for id in G.TC.PINS:
			var pd = G.TC.PINS[id]
			if pd.k != kind:
				continue
			var card = UI.panel(UI.CARD, 14, 16, 10, UI.LINE)
			var cv = UI.vb(6)
			cv.add_child(UI.lbl(pd.n, 24, UI.TEXT, "disp"))
			cv.add_child(UI.wrap(pd.d, 17, UI.MUTED))
			var fl = UI.hb(6)
			var any = false
			for i in 11:
				if c.xi[i] >= 0 and c.slots[i][0] in pd.pos and c.pins[i] == "":
					any = true
					var p = G.s.players[c.xi[i]]
					var ch = UI.chip("%s  %s" % [c.slots[i][0], G.pname(p)], Color(UI.accent, 0.18), UI.TEXT, 17)
					var idx = i
					var pin = id
					UI.tap(ch, func():
						c.pins[idx] = pin
						UI.close_sheet()
						refresh(), true)
					fl.add_child(ch)
			if not any:
				fl.add_child(UI.lbl("Nobody in the XI plays %s." % " or ".join(pd.pos), 16, UI.DIM))
			cv.add_child(fl)
			card.add_child(cv)
			v.add_child(card)
	UI.sheet("Attacking instruction" if kind == "att" else "Defensive instruction", build_sheet)


func _pick_target():
	# who the tight marker follows: automatic, or a named player from the next opponents
	var c = G.uc()
	var f = G.next_user_fixture()
	var build_sheet = func(v):
		var auto = UI.panel(UI.CARD, 14, 16, 10, UI.accent if c.tm_pid < 0 else UI.LINE)
		auto.add_child(UI.lbl("Automatic: their best forward on the day", 22, UI.TEXT, "semi"))
		UI.tap(auto, func():
			c.tm_pid = -1
			UI.close_sheet()
			refresh())
		v.add_child(auto)
		if f == null:
			return
		var oc = G.s.clubs[f.a if f.h == c.id else f.h]
		v.add_child(UI.caps("Next opponents · %s" % oc.name, 17, UI.MUTED))
		var list = []
		for pid in oc.players:
			var p = G.s.players[pid]
			if p.pos in ["ST", "LW", "RW", "CAM", "LM", "RM"] and G.available(p):
				list.append(p)
		list.sort_custom(func(a, b): return a.ovr > b.ovr)
		for k in min(8, list.size()):
			var p = list[k]
			var r = UI.panel(UI.CARD, 14, 16, 8, UI.accent if c.tm_pid == p.id else UI.LINE)
			var h = UI.hb(10)
			h.add_child(UI.pos(p.pos, 18))
			h.add_child(UI.lbl_fill(G.pname(p), 22, UI.TEXT, "semi"))
			h.add_child(UI.lbl(", ".join(G.TC.skill_names(p).slice(0, 2)), 14, UI.DIM))
			h.add_child(UI.ovr(p.ovr, 20))
			r.add_child(h)
			var pid = p.id
			UI.tap(r, func():
				c.tm_pid = pid
				UI.close_sheet()
				refresh())
			v.add_child(r)
	UI.sheet("Who to mark", build_sheet)


func _slot_line(v: Control, sl: Dictionary, pid: int, c: Dictionary):
	var h = UI.hb(8)
	var tg = UI.caps(sl.t, 13, UI.DIM)
	tg.custom_minimum_size = Vector2(74, 0)
	h.add_child(tg)
	if pid >= 0:
		var p = G.s.players[pid]
		h.add_child(UI.pos(c.slots[c.xi.find(pid)][0], 14))
		h.add_child(UI.lbl_fill(G.pname(p), 18, UI.TEXT, "semi"))
	else:
		var fits = G.TC.slot_fits(sl, c)
		var names = []
		for k in min(3, fits.size()):
			names.append(G.pname(fits[k]))
		var txt = ("Could play it: " + ", ".join(names)) if names.size() > 0 else ("Nobody fits: needs " + G.TC.slot_need(sl))
		h.add_child(UI.lbl_fill("%s · %s" % ["/".join(sl.pos), txt], 14, UI.AMBER if names.size() > 0 else UI.RED))
	v.add_child(h)


func _links(v: Control, c: Dictionary):
	var u = G.s.user
	var slots = G.TC.link_slots()
	var act = {}
	for l in G.TC.user_links(c):
		act[l.id] = l
	var hh = UI.hb(8)
	hh.add_child(UI.caps("Your link-up plays · %d of %d" % [u.links.size(), slots], 15, UI.accent))
	hh.add_child(UI.sp())
	hh.add_child(UI.caps("%d goals from link-ups" % int(u.get("link_goals", 0)), 13, UI.DIM))
	v.add_child(hh)
	var st = G.TC.style_of(c)
	for id in u.links:
		if not G.TC.LINKS.has(id):
			continue
		var L = G.TC.LINKS[id]
		var l = act.get(id, null)
		var card = UI.panel(Color(UI.accent, 0.1) if l != null else Color(1, 1, 1, 0.03), 10, 12, 6, Color(G.TC.LEVEL_COL[l.lvl]) if l != null else Color(1, 1, 1, 0.08))
		var cv = UI.vb(2)
		var th = UI.hb(8)
		th.add_child(UI.lbl(L.n, 20, UI.TEXT, "disp"))
		if st in L.style:
			th.add_child(UI.chip("SUITS YOUR STYLE", Color(UI.GREEN, 0.14), UI.GREEN, 12))
		th.add_child(UI.sp())
		if l != null:
			var games = G.TC.pair_games(id, l.a, l.b)
			var nxt = "" if l.lvl >= 2 else " · %d to %s" % [G.TC.LEVEL_AT[l.lvl + 1] - games, G.TC.LEVELS[l.lvl + 1]]
			th.add_child(UI.caps("%d together%s" % [games, nxt], 12, UI.DIM))
			th.add_child(UI.chip(G.TC.LEVELS[l.lvl].to_upper(), Color(G.TC.LEVEL_COL[l.lvl]), Color("0a0e17"), 13))
		else:
			th.add_child(UI.chip("OFF", Color(1, 1, 1, 0.08), UI.MUTED, 13))
		cv.add_child(th)
		_slot_line(cv, L.a, l.a if l != null else -1, c)
		_slot_line(cv, L.b, l.b if l != null else -1, c)
		card.add_child(cv)
		var lid = id
		UI.tap(card, func(): _link_sheet(lid))
		v.add_child(card)
	if u.links.size() < slots:
		v.add_child(UI.btn("Choose a link-up play", func(): _pick_link(-1), "primary", "plus", 44))
	elif slots < 5:
		v.add_child(UI.lbl_fill("Your next coaching badge unlocks another link-up play.", 14, UI.DIM))


func _link_sheet(id: String):
	var L = G.TC.LINKS[id]
	var build_sheet = func(v):
		v.add_child(UI.wrap(L.d, 20, UI.MUTED))
		for sl in [L.a, L.b]:
			v.add_child(UI.kv("%s · %s" % [sl.t, " / ".join(sl.pos)], G.TC.slot_need(sl), UI.TEXT, 17))
		var names = []
		for i in L.style:
			names.append(G.TC.STYLES[i].n)
		v.add_child(UI.kv("Strongest in", ", ".join(names), UI.accent, 17))
		v.add_child(UI.wrap("The pair goes Bronze, Silver, Gold as they start matches together (10 and 25). Levels belong to the pair, so they are kept if you swap this play out and bring it back.", 16, UI.DIM))
		v.add_child(UI.btn("Replace with another link-up", func():
			UI.close_sheet()
			_pick_link(G.s.user.links.find(id)), "secondary", "repeat", 52))
	UI.sheet(L.n, build_sheet)


func _pick_link(replace: int):
	preload("res://scripts/screens/tac_sheets.gd").pick_link(replace, func(): refresh())

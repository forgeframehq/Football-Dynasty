extends "res://scripts/screens/screen.gd"
# Formation, starting XI, bench and team instructions.

const PITCH = preload("res://scripts/widgets/pitch.gd")
const TOKEN = preload("res://scripts/widgets/token.gd")
const MENT_SHORT = ["Bus", "Def", "Bal", "Att", "All out"]

var sel = null   # {"k": "xi"/"sub"/"res", "i": index or pid}
var pitch: Control


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
	fh.add_child(UI.caps("Formation", 19, UI.MUTED))
	fh.add_child(UI.sp())
	fh.add_child(UI.lbl(c.formation, 30, UI.TEXT, "disp"))
	fh.add_child(UI.icon("chevron-right", 24, UI.MUTED))
	fb.add_child(fh)
	UI.tap(fb, _pick_formation, true)
	top.add_child(fb)
	var ab = UI.btn("Best XI", func():
		G.auto_pick(c)
		sel = null
		refresh(), "secondary", "sparkles", 66)
	top.add_child(ab)
	v.add_child(top)
	if sel != null:
		v.add_child(UI.caps("Now tap another player to swap", 20, UI.accent))
	else:
		v.add_child(UI.caps("Tap a player, then tap another to swap them", 20, UI.DIM))
	# pitch
	pitch = PITCH.new()
	pitch.custom_minimum_size = Vector2(0, 880)
	v.add_child(pitch)
	var slots = G.FORMATIONS[c.formation]
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
		t.selected = sel != null and sel.k == "xi" and sel.i == i
		t.set_meta("slot", slots[i])
		var idx = i
		UI.tap(t, func(): _tap("xi", idx), true)
		pitch.add_child(t)
	pitch.resized.connect(_place)
	_place.call_deferred()
	# instructions
	v.add_child(UI.section("Mentality", G.MENTALITY[c.ment]))
	v.add_child(UI.seg(MENT_SHORT, c.ment, func(i):
		c.ment = i
		refresh(), 20))
	v.add_child(UI.section("Pressing", G.PRESSING[c.press]))
	v.add_child(UI.seg(G.PRESSING, c.press, func(i):
		c.press = i
		refresh(), 20))
	v.add_child(UI.section("Tempo", G.TEMPO[c.tempo]))
	v.add_child(UI.seg(G.TEMPO, c.tempo, func(i):
		c.tempo = i
		refresh(), 20))
	# bench
	v.add_child(UI.section("Substitutes", "%d / 7" % c.bench.size()))
	for pid in c.bench:
		v.add_child(_row(G.s.players[pid], "sub"))
	var rest = []
	for pid in c.players:
		if not (pid in c.xi) and not (pid in c.bench):
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
	elif a.k == "xi":
		if not G.available(G.s.players[b.i]):
			UI.toast("%s is unavailable" % G.pname(G.s.players[b.i]), UI.RED)
			refresh()
			return
		var out = c.xi[a.i]
		c.xi[a.i] = b.i
		if b.k == "sub":
			var bi = c.bench.find(b.i)
			if out >= 0:
				c.bench[bi] = out
			else:
				c.bench.remove_at(bi)
	else:
		# bench <-> reserves
		var sub_id = a.i if a.k == "sub" else b.i
		var res_id = b.i if a.k == "sub" else a.i
		if a.k == b.k:
			if a.k == "res" and c.bench.size() < 7:
				c.bench.append(a.i)
			refresh()
			return
		c.bench[c.bench.find(sub_id)] = res_id
	refresh()


func _pick_formation():
	var c = G.uc()
	var build_sheet = func(v):
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
				c.formation = name_f
				G.auto_pick(c)
				UI.close_sheet()
				refresh())
			v.add_child(r)
	UI.sheet("Formation", build_sheet)

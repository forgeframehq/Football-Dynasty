extends "res://scripts/screens/screen.gd"
# Cups and European competitions: overview list and per-competition detail.


var sel := ""


func build():
	var s = G.s
	body.add_child(UI.topbar("Cups & continental"))
	var mine = {}
	for x in G.CP.club_comps(s.user.club):
		mine[x[0].id] = x[1]
	if s.comps.size() == 0:
		var v0 = content(10)
		v0.add_child(UI.wrap("Cup competitions start with the new season.", 23, UI.MUTED))
		return
	var order = s.comps.duplicate()
	order.sort_custom(func(a, b): return (0 if mine.has(a.id) else 1) < (0 if mine.has(b.id) else 1))
	if sel == "":
		sel = args.get("id", order[0].id)
	var h = panes(10, 20)
	var a = pane(330, 4)
	h.add_child(a[0])
	var lv = a[1]
	for comp in order:
		var on = comp.id == sel
		var r = UI.panel(Color(UI.accent, 0.16) if on else Color(1, 1, 1, 0.03), 10, 10, 6, Color(UI.accent, 0.55) if on else Color(0, 0, 0, 0))
		var rh = UI.hb(10)
		rh.add_child(UI.icon("trophy" if comp.kind == "cup" else "star-f", 22, UI.GOLD))
		var tv = UI.vb(-4)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UI.lbl_fill(comp.name, 19, UI.TEXT, "semi"))
		var status = ""
		if comp.done:
			status = "Winners: %s" % s.clubs[comp.winner].name
		elif comp.kind == "euro" and comp.stage == 0:
			status = "Group stage"
		else:
			status = G.CP.round_name(comp.alive.size() + comp.byes.size(), comp.round) if comp.byes.size() == 0 else "Round 1"
		tv.add_child(UI.lbl_fill(status, 15, UI.MUTED))
		rh.add_child(tv)
		if mine.has(comp.id):
			rh.add_child(UI.chip("IN" if mine[comp.id] else "OUT", Color(UI.GREEN if mine[comp.id] else UI.RED, 0.14), UI.GREEN if mine[comp.id] else UI.RED, 14))
		r.add_child(rh)
		var id = comp.id
		UI.tap(r, func():
			sel = id
			refresh())
		lv.add_child(r)
	var b = pane(0, 5)
	h.add_child(b[0])
	_detail(G.CP.get_comp(sel), b[1])


func _detail(comp: Dictionary, v: Control):
	var s = G.s
	v.add_child(UI.lbl(comp.name.to_upper(), 24, UI.TEXT, "xbold"))
	if comp.done:
		var w = s.clubs[comp.winner]
		var wc = UI.panel(Color(UI.GOLD, 0.1), 22, 20, 16, Color(UI.GOLD, 0.4))
		var wh = UI.hb(14)
		wh.add_child(UI.badge(w, 64))
		var wv = UI.vb(0)
		wv.add_child(UI.caps("Winners %s" % G.season_name(), 19, UI.GOLD))
		wv.add_child(UI.lbl(w.name, 32, UI.TEXT, "disp"))
		wh.add_child(wv)
		wc.add_child(wh)
		v.add_child(wc)
	# current / upcoming ties
	var cur = []
	for id in comp.fx:
		var f = s.fixtures[id]
		if comp.kind == "cup" or comp.stage > 0:
			cur.append(f)
	if cur.size() > 0 and not comp.done:
		v.add_child(UI.section(cur[0].label.split(" · ")[1], G.fmt_date(cur[0].day)))
		for f in cur:
			v.add_child(_tie(f.h, f.a, f.hg if f.played else -1, f.ag, f.get("pens", null)))
	for ri in range(comp.rounds.size() - 1, -1, -1):
		var res = comp.rounds[ri]
		v.add_child(UI.section(G.CP.round_name(res.size() * 2, ri) if (comp.kind == "euro" or ri > 0 or res.size() * 2 in [2, 4, 8, 16, 32, 64]) else "Round 1"))
		for m in res:
			v.add_child(_tie(m[0], m[1], m[2], m[3], m[4]))
	if comp.kind == "euro":
		var order = range(8)
		var ug = -1
		for g in 8:
			if s.user.club in comp.groups[g]:
				ug = g
		if ug >= 0:
			order.erase(ug)
			order.push_front(ug)
		for g in order:
			v.add_child(UI.section("Group %s" % "ABCDEFGH"[g]))
			var card = UI.card(12, 8)
			var cv = UI.vb(3)
			var ids = G.CP.group_order(comp, g)
			for i in 4:
				var c = s.clubs[ids[i]]
				var t = comp.gt[c.id]
				var me = c.id == s.user.club
				var r = UI.hb(10)
				var zb = ColorRect.new()
				zb.color = UI.GREEN if i < 2 else Color(0, 0, 0, 0)
				zb.custom_minimum_size = Vector2(5, 22)
				zb.mouse_filter = Control.MOUSE_FILTER_IGNORE
				r.add_child(zb)
				r.add_child(UI.badge(c, 22))
				r.add_child(UI.lbl_fill(c.name, 18, UI.TEXT if me else UI.MUTED, "semi" if me else "body"))
				r.add_child(UI.lbl("%d  %d-%d-%d  %+d" % [t.p, t.w, t.d, t.l, t.gf - t.ga], 16, UI.DIM))
				var pl = UI.lbl(str(t.pts), 19, UI.TEXT, "disp")
				pl.custom_minimum_size = Vector2(40, 0)
				pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				r.add_child(pl)
				cv.add_child(r)
			card.add_child(cv)
			v.add_child(card)


func _tie(hid: int, aid: int, hg: int, ag: int, pens) -> Control:
	var s = G.s
	var hc = s.clubs[hid]
	var ac = s.clubs[aid]
	var me = hid == s.user.club or aid == s.user.club
	var r = UI.panel(Color(UI.accent, 0.14) if me else Color(1, 1, 1, 0.03), 6, 10, 3)
	var h = UI.hb(8)
	var win = 0
	if hg >= 0:
		win = 1 if hg > ag else (2 if ag > hg else (1 if pens != null and pens[0] > pens[1] else 2))
	var hn = UI.lbl_fill(hc.name, 18, UI.TEXT if win != 2 else UI.DIM, "semi" if win == 1 else "body")
	hn.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(hn)
	h.add_child(UI.badge(hc, 22))
	var txt = "v"
	if hg >= 0:
		txt = "%d – %d" % [hg, ag]
		if pens != null:
			txt += " p"
	h.add_child(UI.chip(txt, Color(1, 1, 1, 0.06), UI.TEXT, 17, 66))
	h.add_child(UI.badge(ac, 22))
	h.add_child(UI.lbl_fill(ac.name, 18, UI.TEXT if win != 1 else UI.DIM, "semi" if win == 2 else "body"))
	r.add_child(h)
	return r

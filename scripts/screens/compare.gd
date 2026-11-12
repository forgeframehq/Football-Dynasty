extends "res://scripts/screens/screen.gd"
# Side-by-side player comparison.


func build():
	var a = G.s.players[args.a]
	var b = G.s.players[args.b]
	body.add_child(UI.topbar("Compare"))
	var v = content(10)
	var head = UI.hb(10)
	for p in [a, b]:
		var c = UI.card(16, 14)
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cv = UI.vb(4)
		var t = UI.hb(8)
		t.add_child(UI.pos(p.pos))
		t.add_child(UI.sp())
		t.add_child(UI.ovr(p.ovr, 28))
		cv.add_child(t)
		cv.add_child(UI.lbl_fill(G.pname(p), 26, UI.TEXT, "disp"))
		cv.add_child(UI.lbl_fill("Free agent" if p.club < 0 else G.s.clubs[p.club].name, 19, UI.MUTED))
		c.add_child(cv)
		head.add_child(c)
	v.add_child(head)
	var rows = [["Age", G.age(a), G.age(b), -1], ["Potential", G.OPS.pot_text(a), G.OPS.pot_text(b), 0], ["Value", G.value(a), G.value(b), 0], ["Wage / wk", a.wage, b.wage, 0],
		["Apps", a.ss.ap, b.ss.ap, 1], ["Goals", a.ss.g, b.ss.g, 1], ["Assists", a.ss.a, b.ss.a, 1], ["Avg rating", G.avg_rating(a), G.avg_rating(b), 1]]
	v.add_child(_table("Overview", rows, true))
	var names = G.GK_STAT_NAMES if a.pos == "GK" and b.pos == "GK" else G.STAT_NAMES
	var srows = []
	for i in 6:
		srows.append([names[i], a.st[i], b.st[i], 1])
	v.add_child(_table("Headline", srows, false))
	if a.pos != "GK" and b.pos != "GK":
		for grp in G.RL.ATTR_GROUPS:
			var arows = []
			for k in grp[1]:
				arows.append([G.RL.ATTR[k], a.at[k], b.at[k], 1])
			v.add_child(_table(grp[0], arows, false))


func _table(title: String, rows: Array, money: bool) -> Control:
	var c = UI.card(18, 14)
	var cv = UI.vb(8)
	cv.add_child(UI.caps(title, 19, UI.accent))
	for r in rows:
		var h = UI.hb(8)
		var better = 0
		if r[3] != 0 and r[1] != r[2]:
			better = 1 if (r[1] > r[2]) == (r[3] > 0) else 2
		var l = UI.lbl(_fmt(r, 1, money), 25, UI.GREEN if better == 1 else UI.TEXT, "disp")
		l.custom_minimum_size = Vector2(110, 0)
		h.add_child(l)
		var m = UI.caps(r[0], 18, UI.MUTED)
		m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		m.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		h.add_child(m)
		var rr = UI.lbl(_fmt(r, 2, money), 25, UI.GREEN if better == 2 else UI.TEXT, "disp")
		rr.custom_minimum_size = Vector2(110, 0)
		rr.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		h.add_child(rr)
		cv.add_child(h)
	c.add_child(cv)
	return c


func _fmt(r: Array, i: int, money: bool) -> String:
	if money and (r[0] == "Value" or r[0] == "Wage / wk"):
		return G.money(r[i])
	if typeof(r[i]) == TYPE_FLOAT:
		return "%.2f" % r[i] if r[i] > 0 else "—"
	return str(r[i])

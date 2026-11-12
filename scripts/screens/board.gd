extends "res://scripts/screens/screen.gd"
# Board expectations, manager profile and career history.


func build():
	var s = G.s
	var u = s.user
	var c = G.uc()
	body.add_child(UI.topbar("Board room"))
	var v = content(14)
	var pos = G.LG.position(c.id)
	var oc = UI.panel(UI.CARD, 28, 24, 22, Color(UI.accent, 0.4))
	var ov = UI.vb(10)
	ov.add_child(UI.caps("Season objective", 22, UI.accent))
	ov.add_child(UI.lbl(u.obj.text, 44, UI.TEXT, "xbold"))
	ov.get_child(1).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ov.add_child(UI.lbl("Target: finish %s or better. You are currently %s." % [G.LG.ordinal(u.obj.target), G.LG.ordinal(pos)], 22, UI.MUTED))
	ov.get_child(2).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ov.add_child(UI.sp(0, 4))
	var ch = UI.hb(8)
	ch.add_child(UI.caps("Board confidence", 21, UI.MUTED))
	ch.add_child(UI.sp())
	ch.add_child(UI.lbl("%d%%" % int(u.conf), 30, UI.cond_color(u.conf + 20), "disp"))
	ov.add_child(ch)
	ov.add_child(UI.bar(u.conf / 100.0, UI.cond_color(u.conf + 20), 12))
	var mood = "The board is delighted with your work."
	if u.conf < 20: mood = "Your job is hanging by a thread. Results must improve immediately."
	elif u.conf < 40: mood = "The board is concerned about recent results."
	elif u.conf < 65: mood = "The board is satisfied with your progress."
	elif u.conf < 85: mood = "The board is pleased with how things are going."
	ov.add_child(UI.wrap(mood, 22, UI.MUTED))
	oc.add_child(ov)
	v.add_child(oc)
	v.add_child(UI.section("Manager profile"))
	var mc = UI.card()
	var mv = UI.vb(12)
	var mh = UI.hb(14)
	var av = UI.panel(Color(UI.accent, 0.14), 40, 18, 18)
	av.add_child(UI.icon("user", 40, UI.accent))
	mh.add_child(av)
	var nv = UI.vb(2)
	nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nv.add_child(UI.lbl_fill(u.name, 34, UI.TEXT, "disp"))
	nv.add_child(UI.lbl_fill("%s · %s licence" % [u.nat, G.OPS.BADGES[u.badge]], 21, UI.MUTED))
	nv.add_child(UI.stars(50.0 + u.rep * 0.4))
	mh.add_child(nv)
	mv.add_child(mh)
	var t = UI.hb(10)
	t.add_child(UI.stat_tile("Games", str(u.p)))
	t.add_child(UI.stat_tile("Won", str(u.w), UI.GREEN))
	t.add_child(UI.stat_tile("Drawn", str(u.d)))
	t.add_child(UI.stat_tile("Lost", str(u.l), UI.RED))
	mv.add_child(t)
	mv.add_child(UI.kv("Win rate", "%d%%" % int(100.0 * u.w / max(1, u.p))))
	mv.add_child(UI.kv("Reputation", "%d / 100" % int(u.rep)))
	mv.add_child(UI.kv("Playing career", G.OPS.BACKGROUNDS[u.bg]))
	mc.add_child(mv)
	v.add_child(mc)
	v.add_child(UI.section("Coaching attributes", "%d point%s to spend" % [u.points, "" if u.points == 1 else "s"] if u.points > 0 else ""))
	var atc = UI.card()
	var atv = UI.vb(12)
	for m in G.OPS.MATTR:
		var r = UI.hb(12)
		var tv = UI.vb(0)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UI.lbl(m[1], 24, UI.TEXT, "semi"))
		tv.add_child(UI.wrap(m[2], 18, UI.DIM))
		r.add_child(tv)
		r.add_child(UI.lbl(str(u.attr[m[0]]), 34, UI.ovr_color(50 + u.attr[m[0]] * 2), "xbold"))
		if u.points > 0 and u.attr[m[0]] < 20:
			var plus = UI.panel(UI.accent, 14, 12, 10)
			plus.add_child(UI.icon("plus", 24, UI.on_color(UI.accent)))
			var key = m[0]
			UI.tap(plus, func():
				u.attr[key] += 1
				u.points -= 1
				refresh(), true)
			r.add_child(plus)
		atv.add_child(r)
	atc.add_child(atv)
	v.add_child(atc)
	if u.badge < 4:
		if u.get("study", 0) > 0:
			v.add_child(UI.kv("Studying for", "%s · %d days left" % [G.OPS.BADGES[u.badge + 1], max(1, u.study - s.day)], UI.accent))
		else:
			v.add_child(UI.btn("Study for %s licence" % G.OPS.BADGES[u.badge + 1], func():
				u.study = s.day + 120 + u.badge * 30
				UI.toast("Course booked — %d days" % (120 + u.badge * 30), UI.GREEN)
				refresh(), "secondary", "graduation-cap", 72))
			var note = UI.caps("Takes %d days · earns 3 attribute points and reputation" % (120 + u.badge * 30), 18, UI.DIM)
			note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			v.add_child(note)
	if u.trophies.size() > 0:
		v.add_child(UI.section("Trophy cabinet"))
		for tr in u.trophies:
			var r = UI.panel(Color(UI.GOLD, 0.1), 18, 18, 14, Color(UI.GOLD, 0.35))
			var h = UI.hb(12)
			h.add_child(UI.icon("trophy", 30, UI.GOLD))
			h.add_child(UI.lbl_fill(tr, 26, UI.GOLD, "disp"))
			r.add_child(h)
			v.add_child(r)
	if s.history.size() > 0:
		v.add_child(UI.section("Career history"))
		for hrow in s.history:
			var r = UI.panel(UI.CARD, 18, 18, 12, UI.LINE)
			var h = UI.hb(12)
			var sl = UI.lbl(G.season_name(hrow.season), 26, UI.accent, "disp")
			sl.custom_minimum_size = Vector2(96, 0)
			h.add_child(sl)
			var tv = UI.vb(0)
			tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tv.add_child(UI.lbl_fill("%s · %s" % [hrow.club, hrow.lg], 24, UI.TEXT, "semi"))
			tv.add_child(UI.lbl_fill("%dW %dD %dL · %d pts%s" % [hrow.w, hrow.d, hrow.l, hrow.pts, (" · " + hrow.note) if hrow.note != "" else ""], 20, UI.MUTED))
			h.add_child(tv)
			h.add_child(UI.lbl(G.LG.ordinal(hrow.pos), 34, UI.GOLD if hrow.pos == 1 else UI.TEXT, "xbold"))
			r.add_child(h)
			v.add_child(r)
	if s.champs.size() > 0:
		v.add_child(UI.section("Past champions"))
		for ch2 in s.champs:
			var cc = UI.card()
			var cv = UI.vb(6)
			cv.add_child(UI.caps(G.season_name(ch2.season), 22, UI.accent))
			for l in s.leagues:
				if l.tier == 1 and ch2.c.has(l.id):
					cv.add_child(UI.kv(l.name, ch2.c[l.id]))
			cc.add_child(cv)
			v.add_child(cc)

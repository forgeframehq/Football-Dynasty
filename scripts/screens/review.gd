extends "res://scripts/screens/screen.gd"
# End-of-season review.


func build():
	var s = G.s
	var rv = s.review
	if rv == null:
		UI.main.call_deferred("root", "home")
		return
	var u = rv.user
	body.add_child(UI.topbar("Season review", false, UI.chip(G.season_name(rv.season), Color(1, 1, 1, 0.06), UI.MUTED, 22)))
	var v = content(14)
	var col = UI.GOLD if u.pos == 1 else (UI.GREEN if u.met else UI.RED)
	var hero = UI.panel(UI.CARD, 28, 24, 24, Color(col, 0.45))
	var hv = UI.vb(6)
	hv.add_child(UI.caps(s.leagues[u.lg].name, 22, UI.MUTED))
	var ph = UI.hb(16)
	ph.add_child(UI.lbl(G.LG.ordinal(u.pos), 120, col, "xbold"))
	var pv = UI.vb(2)
	pv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if u.note != "":
		pv.add_child(UI.lbl(u.note.to_upper(), 44, col, "xbold"))
	pv.add_child(UI.lbl("%d points" % u.t.pts, 28, UI.TEXT, "disp"))
	pv.add_child(UI.lbl("%dW %dD %dL · %d:%d" % [u.t.w, u.t.d, u.t.l, u.t.gf, u.t.ga], 22, UI.MUTED))
	ph.add_child(pv)
	hv.add_child(ph)
	hv.add_child(UI.divider())
	hv.add_child(UI.kv("Objective", u.obj))
	hv.add_child(UI.kv("Outcome", "Achieved" if u.met else "Missed", UI.GREEN if u.met else UI.RED))
	hv.add_child(UI.kv("Board confidence", "%d%%" % int(u.conf), UI.cond_color(u.conf + 20)))
	hero.add_child(hv)
	v.add_child(hero)
	v.add_child(UI.section("Champions & golden boots"))
	for l in rv.leagues:
		var c = s.clubs[l.champ]
		var r = UI.panel(UI.CARD, 18, 16, 12, UI.LINE)
		var h = UI.hb(14)
		h.add_child(UI.badge(c, 48))
		var tv = UI.vb(0)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UI.caps(s.leagues[l.lg].name, 18, UI.accent))
		tv.add_child(UI.lbl_fill(c.name, 26, UI.TEXT, "semi"))
		tv.add_child(UI.lbl_fill("Top scorer: %s (%s) · %d goals" % [l.scorer, l.scorer_club, l.goals], 19, UI.MUTED))
		h.add_child(tv)
		h.add_child(UI.icon("trophy", 28, UI.GOLD))
		r.add_child(h)
		v.add_child(r)
	if rv.get("cups", []).size() > 0:
		v.add_child(UI.section("Cup winners"))
		var cc = UI.card()
		var cv = UI.vb(8)
		for x in rv.cups:
			var wc = s.clubs[x[1]]
			var h = UI.hb(10)
			h.add_child(UI.badge(wc, 32))
			h.add_child(UI.lbl_fill(wc.name, 23, UI.TEXT if wc.id == s.user.club else UI.MUTED, "semi"))
			h.add_child(UI.caps(x[0], 18, UI.GOLD))
			cv.add_child(h)
		cc.add_child(cv)
		v.add_child(cc)
	v.add_child(UI.section("Promoted"))
	v.add_child(_moves(rv.ups, UI.GREEN))
	v.add_child(UI.section("Relegated"))
	v.add_child(_moves(rv.downs, UI.RED))
	v.add_child(UI.sp(0, 6))
	v.add_child(UI.btn("Start %s season" % G.season_name(), func():
		s.review = null
		G.save_game()
		UI.main.root("jobs" if s.user.sacked else "home", {"sacked": true} if s.user.sacked else {}), "gold", "play"))


func _moves(list: Array, col: Color) -> Control:
	var card = UI.card()
	var cv = UI.vb(8)
	for m in list:
		var c = G.s.clubs[m[0]]
		var h = UI.hb(10)
		h.add_child(UI.badge(c, 32))
		h.add_child(UI.lbl_fill(c.name, 23, UI.TEXT if c.id == G.s.user.club else UI.MUTED, "semi"))
		h.add_child(UI.caps("→ " + G.s.leagues[m[1]].name, 18, col))
		cv.add_child(h)
	card.add_child(cv)
	return card

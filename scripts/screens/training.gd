extends "res://scripts/screens/screen.gd"
# Team training focus and intensity, plus each player's individual programme.


func build():
	var c = G.uc()
	var s = G.s
	body.add_child(UI.topbar("Training"))
	var v = content(12)
	var card = UI.card()
	var cv = UI.vb(10)
	cv.add_child(UI.section("Team focus", G.OPS.FOCUS[c.train.focus]))
	cv.add_child(UI.seg(["Bal", "Att", "Def", "Poss", "Fit"], c.train.focus, func(i):
		c.train.focus = i
		refresh(), 20))
	var ft = "A bit of everything — a small boost to overall growth."
	if c.train.focus > 0:
		var names = []
		for a in G.OPS.FOCUS_ATTR[c.train.focus]:
			names.append(G.RL.ATTR[a])
		ft = "Extra monthly gains in " + ", ".join(names) + "."
	cv.add_child(UI.wrap(ft, 21, UI.MUTED))
	cv.add_child(UI.section("Intensity", G.OPS.INTENSITY[c.train.inten]))
	cv.add_child(UI.seg(G.OPS.INTENSITY, c.train.inten, func(i):
		c.train.inten = i
		refresh(), 20))
	cv.add_child(UI.wrap(["Players recover faster between matches but develop more slowly.", "A normal balance of work and rest.", "Faster development, but players recover more slowly between matches."][c.train.inten], 21, UI.MUTED))
	card.add_child(cv)
	v.add_child(card)
	var t = UI.hb(10)
	t.add_child(UI.stat_tile("Training ground", "Level %d" % c.fac.training))
	t.add_child(UI.stat_tile("Growth", "%+d%%" % int(round((G.OPS.growth_mult({"by": 1990, "bm": 1, "bd": 1}) - 1.0) * 100)), UI.GREEN))
	t.add_child(UI.stat_tile("Recovery / day", "+%d%%" % G.OPS.recover_rate({})))
	v.add_child(t)
	v.add_child(UI.section("Individual programmes", "tap a player to change"))
	var list = []
	for pid in c.players:
		list.append(s.players[pid])
	list.sort_custom(func(a, b): return (a.pot - a.ovr) * 10 - G.age(a) > (b.pot - b.ovr) * 10 - G.age(b))
	for p in list:
		var pid = p.id
		var tf = p.get("tr", "")
		var rt = p.get("rt", null)
		var extra = "%d yrs · %s%s" % [G.age(p), tf if tf != "" else "general training", (" · learning %s" % rt[0]) if rt != null else ""]
		v.add_child(UI.player_row(p, func(): UI.main.open("player", {"pid": pid}), extra))

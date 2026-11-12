extends "res://scripts/screens/screen.gd"
# Another club at a glance: profile, ratings, record and recent matches beside the full squad table.

const ORDER = ["GK", "CB", "LB", "RB", "LWB", "RWB", "CDM", "CM", "CAM", "LM", "RM", "LW", "RW", "CF", "ST"]

var sort := 0


func build():
	var s = G.s
	var c = s.clubs[args.cid]
	var lgd = s.leagues[c.lg]
	var roe = lgd.get("roe", false)
	body.add_child(UI.topbar(c.name))
	var list = []
	var val = 0
	var ages = 0
	for pid in c.players:
		var p = s.players[pid]
		list.append(p)
		val += G.value(p)
		ages += G.age(p)
	var n = max(1, list.size())
	UI.main.t_sub = lgd.name if roe else "%s · %s · %d pts" % [lgd.name, G.LG.ordinal(G.LG.position(c.id)), c.t.pts]
	var h = panes(10, 20)

	var a = pane(320, 4)
	h.add_child(a[0])
	var v = a[1]
	var hh = UI.hb(12)
	hh.add_child(UI.badge(c, 60))
	var hv = UI.vb(0)
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hv.add_child(UI.lbl_fill(c.name.to_upper(), 24, UI.TEXT, "disp"))
	hv.add_child(UI.lbl_fill("%s · %s" % [lgd.country, lgd.name], 15, UI.MUTED))
	hv.add_child(UI.stars(c.rep, 16))
	hh.add_child(hv)
	v.add_child(hh)
	var tr = G.team_ratings(c.id)
	var rw = [0, 0, 0, 0]
	v.add_child(UI.trow(["Attack", "Midfield", "Defence", "Overall"], rw, {"head": true}))
	v.add_child(UI.trow([UI.ovr(tr.att, 18), UI.ovr(tr.mid, 18), UI.ovr(tr.def, 18), UI.ovr(tr.ovr, 18)], rw, {"pad": 2}))
	if c.stadium != "":
		v.add_child(UI.kv("Stadium", c.stadium, UI.TEXT, 16))
	if c.has("fac"):
		v.add_child(UI.kv("Capacity", G.OPS._thousands(G.OPS.capacity(c)), UI.TEXT, 16))
	v.add_child(UI.kv("Formation", c.formation, UI.TEXT, 16))
	v.add_child(UI.kv("Transfer budget", G.money(c.budget), UI.GREEN, 16))
	v.add_child(UI.kv("Wage bill", "%s a week" % G.money(G.squad_wages(c)), UI.TEXT, 16))
	v.add_child(UI.kv("Squad", "%d players · average age %.1f" % [list.size(), ages / float(n)], UI.TEXT, 16))
	v.add_child(UI.kv("Squad value", G.money(val), UI.TEXT, 16))
	if not roe:
		var w0 = [0, 0, 0, 0, 0, 0, 0]
		v.add_child(UI.trow(["P", "W", "D", "L", "GF", "GA", "Pts"], w0, {"head": true}))
		v.add_child(UI.trow([c.t.p, c.t.w, c.t.d, c.t.l, c.t.gf, c.t.ga, c.t.pts], w0, {"size": 17, "alt": true, "pad": 2, "cols": {1: UI.GREEN, 3: UI.RED}}))
	var all = G.club_fixtures(c.id)
	var idx = all.size()
	for i in all.size():
		if not all[i].played:
			idx = i
			break
	if all.size() > 0:
		v.add_child(UI.caps("Results and fixtures", 15, UI.accent))
	for i in range(max(0, idx - 4), min(all.size(), idx + 3)):
		var f = all[i]
		var home = f.h == c.id
		var oc = s.clubs[f.a if home else f.h]
		var res = "-"
		var col = UI.DIM
		if f.played:
			var us = f.hg if home else f.ag
			var them = f.ag if home else f.hg
			res = "%d-%d" % [us, them]
			col = UI.GREEN if us > them else (UI.RED if us < them else UI.MUTED)
		v.add_child(UI.trow([G.fmt_date(f.day).substr(4), "H" if home else "A", oc.name, res], [62, 16, 0, -40], {"size": 16, "pad": 2, "alt": i % 2 == 0, "cols": {0: UI.MUTED, 1: UI.MUTED, 3: col}}))

	var b = pane(0, 2)
	h.add_child(b[0])
	sc = b[0].get_child(0)
	v = b[1]
	if sort == 0:
		list.sort_custom(func(x, y): return x.ovr > y.ovr)
	elif sort == 1:
		list.sort_custom(func(x, y): return ORDER.find(x.pos) * 100 - x.ovr < ORDER.find(y.pos) * 100 - y.ovr)
	elif sort == 2:
		list.sort_custom(func(x, y): return G.age(x) < G.age(y))
	else:
		list.sort_custom(func(x, y): return G.value(x) > G.value(y))
	var sh = UI.hb(10)
	var sg = UI.seg(["Rating", "Position", "Age", "Value"], sort, func(i):
		sort = i
		refresh(), 15)
	sg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sh.add_child(sg)
	sh.add_child(UI.caps("Red injured · amber for sale", 12, UI.DIM))
	v.add_child(sh)
	var w = [40, 28, 0, -30, 36, -52, -72, -64, -46]
	v.add_child(UI.trow(["Pos", "", "Player", "Age", "Ovr", "Pot", "Value", "Wage", "Until"], w, {"head": true}))
	for i in list.size():
		var p = list[i]
		var pid = p.id
		var known = G.OPS.knows(p)
		v.add_child(UI.trow([UI.pos(p.pos, 15), UI.flag(p.nat, 24), G.pname(p), G.age(p), UI.ovr(p.ovr, 16), G.OPS.pot_text(p), G.money(G.value(p)), G.money(p.wage), p.cend], w,
			{"size": 18, "alt": i % 2 == 0, "pad": 3,
			"cols": {2: UI.RED if p.inj > 0 else (UI.AMBER if p.listed else UI.TEXT), 3: UI.MUTED, 5: (UI.GREEN if p.pot >= p.ovr + 4 else UI.MUTED) if known else UI.DIM, 7: UI.MUTED, 8: UI.AMBER if p.cend <= s.season + 1 else UI.MUTED},
			"tap": func(): UI.main.open("player", {"pid": pid})}))

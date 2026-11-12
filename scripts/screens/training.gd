extends "res://scripts/screens/screen.gd"
# Training: team focus and intensity, the whole squad in one table, and the selected player's programme.

const ORDER = ["GK", "CB", "LB", "RB", "LWB", "RWB", "CDM", "CM", "CAM", "LM", "RM", "LW", "RW", "CF", "ST"]

var sel := -1
var sort := 0


func build():
	var c = G.uc()
	var s = G.s
	body.add_child(UI.topbar("Training"))
	var list = []
	var cond = 0.0
	var mor = 0.0
	var inj = 0
	var prog = 0
	var learn = 0
	for pid in c.players:
		var p = s.players[pid]
		list.append(p)
		cond += p.cond
		mor += p.mor
		inj += 1 if p.inj > 0 else 0
		prog += 1 if p.get("tr", "") != "" else 0
		learn += 1 if p.get("rt", null) != null else 0
	var n = max(1, list.size())
	if sort == 0:
		list.sort_custom(func(a, b): return (a.pot - a.ovr) * 10 - G.age(a) > (b.pot - b.ovr) * 10 - G.age(b))
	elif sort == 1:
		list.sort_custom(func(a, b): return a.cond < b.cond)
	elif sort == 2:
		list.sort_custom(func(a, b): return G.age(a) < G.age(b))
	else:
		list.sort_custom(func(a, b): return ORDER.find(a.pos) * 100 - a.ovr < ORDER.find(b.pos) * 100 - b.ovr)
	if not s.players.has(sel) or s.players[sel].club != c.id:
		sel = list[0].id if list.size() > 0 else -1
	var growth = int(round((G.OPS.growth_mult({"by": 1990, "bm": 1, "bd": 1}) - 1.0) * 100))
	UI.main.t_sub = "Level %d ground · growth %+d%% · recovery +%d%% a day · %d on a programme" % [c.fac.training, growth, G.OPS.recover_rate({}), prog]
	var h = panes(10, 20)

	# team settings
	var a = pane(300, 6)
	h.add_child(a[0])
	var v = a[1]
	v.add_child(UI.caps("Team focus · %s" % G.OPS.FOCUS[c.train.focus], 15, UI.accent))
	v.add_child(UI.seg(["Bal", "Att", "Def", "Poss", "Fit"], c.train.focus, func(i):
		c.train.focus = i
		refresh(), 16))
	var ft = "A bit of everything: a small boost to overall growth."
	if c.train.focus > 0:
		var names = []
		for at in G.OPS.FOCUS_ATTR[c.train.focus]:
			names.append(G.RL.ATTR[at])
		ft = "Extra monthly gains in " + ", ".join(names) + "."
	v.add_child(UI.wrap(ft, 16, UI.MUTED))
	v.add_child(UI.caps("Intensity · %s" % G.OPS.INTENSITY[c.train.inten], 15, UI.accent))
	v.add_child(UI.seg(G.OPS.INTENSITY, c.train.inten, func(i):
		c.train.inten = i
		refresh(), 16))
	v.add_child(UI.wrap(["Faster recovery between matches, slower development.", "A normal balance of work and rest.", "Faster development, slower recovery between matches."][c.train.inten], 16, UI.MUTED))
	v.add_child(UI.divider())
	v.add_child(UI.kv("Training ground", "Level %d" % c.fac.training, UI.TEXT, 17))
	v.add_child(UI.kv("Growth", "%+d%%" % growth, UI.GREEN if growth >= 0 else UI.RED, 17))
	v.add_child(UI.kv("Recovery a day", "+%d%%" % G.OPS.recover_rate({}), UI.TEXT, 17))
	v.add_child(UI.kv("Squad condition", "%d%%" % int(cond / n), UI.cond_color(cond / n), 17))
	v.add_child(UI.kv("Squad morale", "%d%%" % int(mor / n), UI.cond_color(mor / n + 15), 17))
	v.add_child(UI.kv("Injured", str(inj), UI.RED if inj > 0 else UI.TEXT, 17))
	v.add_child(UI.kv("Learning a position", str(learn), UI.TEXT, 17))
	if c.fac.training < 5:
		v.add_child(UI.btn("Upgrade the ground", func(): UI.main.open("campus"), "ghost", "hammer", 44))

	# squad table
	var b = pane(0, 2)
	h.add_child(b[0])
	sc = b[0].get_child(0)
	v = b[1]
	v.add_child(UI.seg(["Room to grow", "Condition", "Age", "Position"], sort, func(i):
		sort = i
		refresh(), 15))
	var w = [40, 0, -30, 36, -34, -46, -40, 132]
	v.add_child(UI.trow(["Pos", "Player", "Age", "Ovr", "Pot", "Cond", "Mor", "Programme"], w, {"head": true}))
	for i in list.size():
		var p = list[i]
		var pid = p.id
		var rt = p.get("rt", null)
		var tf = p.get("tr", "")
		var pt = ("Learning %s" % rt[0]) if rt != null else (tf if tf != "" else "General")
		if p.inj > 0:
			pt = "Injured"
		v.add_child(UI.trow([UI.pos(p.pos, 15), G.pname(p), G.age(p), UI.ovr(p.ovr, 16), p.pot, "%d%%" % int(p.cond), int(p.mor), pt], w,
			{"size": 18, "hi": pid == sel, "alt": i % 2 == 0, "pad": 3,
			"cols": {2: UI.MUTED, 4: UI.GREEN if p.pot >= p.ovr + 4 else UI.MUTED, 5: UI.cond_color(p.cond), 6: UI.cond_color(p.mor + 15), 7: UI.RED if p.inj > 0 else (UI.accent if tf != "" or rt != null else UI.DIM)},
			"tap": func():
				sel = pid
				refresh()}))

	# the selected player's programme
	var d = pane(280, 4)
	h.add_child(d[0])
	v = d[1]
	if sel < 0:
		return
	var p = s.players[sel]
	var hh = UI.hb(8)
	hh.add_child(UI.pos(p.pos, 16))
	hh.add_child(UI.lbl_fill(G.pname(p), 22, UI.TEXT, "semi"))
	hh.add_child(UI.ovr(p.ovr, 18))
	v.add_child(hh)
	v.add_child(UI.lbl("%d yrs · potential %d · growth %+d%%" % [G.age(p), p.pot, int(round((G.OPS.growth_mult(p) - 1.0) * 100))], 15, UI.MUTED))
	if p.get("rt", null) != null:
		v.add_child(UI.lbl("Learning %s · %d sessions left" % [p.rt[0], int(p.rt[1])], 15, UI.accent))
	v.add_child(UI.caps("Individual programme", 15, UI.accent))
	if p.pos == "GK":
		v.add_child(UI.wrap("Goalkeepers work with the keeper coach and do not take an individual programme.", 16, UI.DIM))
	else:
		for k in [""] + G.OPS.INDIV.keys():
			var on = p.get("tr", "") == k
			var r = UI.panel(Color(UI.accent, 0.16) if on else Color(1, 1, 1, 0.03), 8, 10, 5, UI.accent if on else Color(0, 0, 0, 0))
			var rh = UI.hb(6)
			rh.add_child(UI.lbl(k if k != "" else "General", 18, UI.TEXT, "semi" if on else "body"))
			rh.add_child(UI.sp())
			if k != "":
				var names = []
				for at in G.OPS.INDIV[k]:
					names.append(G.RL.ATTR[at].substr(0, 4))
				rh.add_child(UI.caps(" ".join(names), 12, UI.DIM))
			r.add_child(rh)
			var key = k
			UI.tap(r, func():
				if key == "":
					p.erase("tr")
				else:
					p["tr"] = key
				refresh(), true)
			v.add_child(r)
	var sid = sel
	v.add_child(UI.btn("Player profile", func(): UI.main.open("player", {"pid": sid}), "secondary", "user", 44))

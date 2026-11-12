extends "res://scripts/screens/screen.gd"
# Finances: budgets, the weekly ledger, this season's deals and the full wage bill.


func build():
	var s = G.s
	var c = G.uc()
	body.add_child(UI.topbar("Finances"))
	var wages = G.squad_wages(c)
	var fin = c.fin
	UI.main.t_sub = "Settled every Monday · %s a week free for wages" % G.money(c.wage_budget - wages)
	var h = panes(10, 20)

	# budgets
	var a = pane(300, 5)
	h.add_child(a[0])
	var v = a[1]
	v.add_child(UI.caps("Transfer budget", 15, UI.accent))
	v.add_child(UI.lbl(G.money(c.budget), 46, UI.GREEN if c.budget >= 0 else UI.RED, "xbold"))
	v.add_child(UI.caps("Weekly wage bill", 15, UI.accent))
	var frac = wages / float(max(1, c.wage_budget))
	var wcol = UI.GREEN if frac < 0.9 else (UI.AMBER if frac <= 1.0 else UI.RED)
	v.add_child(UI.lbl("%s of %s" % [G.money(wages), G.money(c.wage_budget)], 22, UI.TEXT, "disp"))
	v.add_child(UI.bar(frac, wcol, 10))
	v.add_child(UI.kv("Free each week", G.money(c.wage_budget - wages), wcol, 17))
	v.add_child(UI.kv("Wages a year", G.money(wages * 52), UI.TEXT, 17))
	v.add_child(UI.divider())
	v.add_child(UI.caps("Transfers this season", 15, UI.accent))
	v.add_child(UI.kv("Spent", G.money(c.spent), UI.RED if c.spent > 0 else UI.TEXT, 17))
	v.add_child(UI.kv("Received", G.money(c.earned), UI.GREEN if c.earned > 0 else UI.TEXT, 17))
	v.add_child(UI.kv("Net", G.money(c.earned - c.spent), UI.TEXT, 17))
	v.add_child(UI.divider())
	v.add_child(UI.kv("Club value", G.money(G.OPS.club_value(c)), UI.TEXT, 17))
	v.add_child(UI.kv("Your salary", "%s a week" % G.money(G.OPS.salary()), UI.TEXT, 17))
	var bh = UI.hb(6)
	bh.add_child(UI.btn("Facilities", func(): UI.main.open("campus"), "secondary", "", 44))
	bh.add_child(UI.btn("Sponsors", func(): UI.main.open("hub", {"kind": "sponsors", "grp": "club"}), "ghost", "", 44))
	for x in bh.get_children():
		x.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(bh)

	# weekly ledger
	var b = pane(0, 2)
	b[0].size_flags_stretch_ratio = 1.15
	h.add_child(b[0])
	v = b[1]
	var w = [0, -92, -92]
	var now = G.OPS.week_money(c)
	var has_last = fin.has("net")
	v.add_child(UI.caps("Weekly ledger", 15, UI.accent))
	v.add_child(UI.trow(["", "Last week", "This week"], w, {"head": true}))
	var rows = [["Sponsors and commercial", "sponsor", 1], ["Gate receipts", "tickets", 1], ["Broadcasting", "tv", 1], ["Player wages", "wages", -1], ["Facility upkeep", "upkeep", -1]]
	for i in rows.size():
		var r = rows[i]
		var col = UI.GREEN if r[2] > 0 else UI.RED
		var sign = "+" if r[2] > 0 else "-"
		v.add_child(UI.trow([r[0], (sign + G.money(fin[r[1]])) if has_last else "-", sign + G.money(now[r[1]])], w, {"size": 18, "alt": i % 2 == 0, "cols": {1: col if has_last else UI.DIM, 2: Color(col, 0.75)}}))
	v.add_child(UI.trow(["Into transfer budget", G.money(fin.net) if has_last else "-", G.money(now.net)], w,
		{"size": 18, "hi": true, "bold": 0, "cols": {1: (UI.GREEN if fin.get("net", 0) >= 0 else UI.RED) if has_last else UI.DIM, 2: UI.GREEN if now.net >= 0 else UI.RED}}))
	v.add_child(UI.lbl("This week is an estimate: %d home match%s so far." % [now.home, "" if now.home == 1 else "es"], 14, UI.DIM))
	var log = c.get("bank_log", [])
	if log.size() > 0:
		v.add_child(UI.caps("Weekly balance · last %d weeks" % log.size(), 15, UI.accent))
		var top = 1
		for x in log:
			top = max(top, abs(x))
		for i in log.size():
			var x = log[i]
			v.add_child(UI.trow(["%d wk ago" % (i + 1), UI.bar(abs(x) / float(top), UI.GREEN if x >= 0 else UI.RED, 8), G.money(x)], [74, 0, -84], {"size": 16, "pad": 2, "cols": {0: UI.MUTED, 2: UI.GREEN if x >= 0 else UI.RED}}))
	var mine = []
	for x in s.tx_log:
		if x.user:
			mine.append(x)
	v.add_child(UI.caps("Your deals this season · %d" % mine.size(), 15, UI.accent))
	if mine.is_empty():
		v.add_child(UI.lbl("No business done yet.", 16, UI.DIM))
	for i in mine.size():
		var x = mine[i]
		var incoming = x.to == c.name
		v.add_child(UI.trow([UI.icon("arrow-down" if incoming else "arrow-up", 18, UI.GREEN if incoming else UI.AMBER), x.name, ("from %s" % x.from) if incoming else ("to %s" % x.to), G.money(x.fee) if x.fee > 0 else "Free"], [20, 0, 150, -80],
			{"size": 17, "alt": i % 2 == 0, "cols": {2: UI.MUTED, 3: UI.RED if incoming and x.fee > 0 else (UI.GREEN if x.fee > 0 else UI.TEXT)}}))

	# wage bill
	var d = pane(0, 2)
	h.add_child(d[0])
	v = d[1]
	var list = []
	for pid in c.players:
		list.append(s.players[pid])
	list.sort_custom(func(x, y): return x.wage > y.wage)
	v.add_child(UI.caps("Wage bill · %d players" % list.size(), 15, UI.accent))
	var w2 = [40, 0, -28, 34, -76, -48]
	v.add_child(UI.trow(["Pos", "Player", "Age", "Ovr", "A week", "Until"], w2, {"head": true}))
	for i in list.size():
		var p = list[i]
		var pid = p.id
		var ending = p.cend <= s.season + 1
		v.add_child(UI.trow([UI.pos(p.pos, 15), G.pname(p), G.age(p), UI.ovr(p.ovr, 16), G.money(p.wage), p.cend], w2,
			{"size": 18, "alt": i % 2 == 0, "pad": 3, "cols": {2: UI.MUTED, 5: UI.AMBER if ending else UI.MUTED}, "tap": func(): UI.main.open("player", {"pid": pid})}))

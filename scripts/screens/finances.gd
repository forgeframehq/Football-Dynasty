extends "res://scripts/screens/screen.gd"
# Budgets, wage bill and this season's transfer business.


func build():
	var s = G.s
	var c = G.uc()
	body.add_child(UI.topbar("Finances"))
	var v = content(14)
	var wages = G.squad_wages(c)
	var hero = UI.panel(UI.CARD, 28, 24, 22, Color(UI.GREEN, 0.3))
	var hv = UI.vb(2)
	hv.add_child(UI.caps("Transfer budget", 22, UI.MUTED))
	hv.add_child(UI.lbl(G.money(c.budget), 92, UI.GREEN, "xbold"))
	hero.add_child(hv)
	v.add_child(hero)
	var wc = UI.card()
	var wv = UI.vb(10)
	var wh = UI.hb(8)
	wh.add_child(UI.caps("Weekly wage bill", 22, UI.MUTED))
	wh.add_child(UI.sp())
	wh.add_child(UI.lbl("%s / %s" % [G.money(wages), G.money(c.wage_budget)], 26, UI.TEXT, "disp"))
	wv.add_child(wh)
	var frac = wages / float(max(1, c.wage_budget))
	wv.add_child(UI.bar(frac, UI.GREEN if frac < 0.9 else (UI.AMBER if frac <= 1.0 else UI.RED), 12))
	wv.add_child(UI.lbl("%s per week available for new contracts · %s per year in total" % [G.money(c.wage_budget - wages), G.money(wages * 52)], 20, UI.MUTED))
	wv.get_child(2).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	wc.add_child(wv)
	v.add_child(wc)
	var fin = c.fin
	if fin.has("net"):
		v.add_child(UI.section("Last week", "net %s" % G.money(fin.net)))
		var fc = UI.card()
		var fv = UI.vb(8)
		fv.add_child(UI.kv("Sponsorship & commercial", "+" + G.money(fin.sponsor), UI.GREEN))
		fv.add_child(UI.kv("Gate receipts", "+" + G.money(fin.tickets), UI.GREEN))
		fv.add_child(UI.kv("Broadcasting", "+" + G.money(fin.tv), UI.GREEN))
		fv.add_child(UI.kv("Player wages", "-" + G.money(fin.wages), UI.RED))
		fv.add_child(UI.kv("Facility upkeep", "-" + G.money(fin.upkeep), UI.RED))
		fv.add_child(UI.divider())
		fv.add_child(UI.kv("Into the transfer budget", G.money(fin.net), UI.GREEN if fin.net >= 0 else UI.RED))
		fc.add_child(fv)
		v.add_child(fc)
	else:
		v.add_child(UI.wrap("Income and costs are settled every Monday and the difference goes into your transfer budget.", 21, UI.MUTED))
	v.add_child(UI.btn("Club & facilities", func(): UI.main.open("campus"), "secondary", "landmark", 68))
	var t = UI.hb(10)
	t.add_child(UI.stat_tile("Spent", G.money(c.spent), UI.RED if c.spent > 0 else UI.TEXT))
	t.add_child(UI.stat_tile("Received", G.money(c.earned), UI.GREEN if c.earned > 0 else UI.TEXT))
	t.add_child(UI.stat_tile("Net", G.money(c.earned - c.spent)))
	v.add_child(t)
	var mine = []
	for x in s.tx_log:
		if x.user:
			mine.append(x)
	if mine.size() > 0:
		v.add_child(UI.section("Your deals this season"))
		for x in mine:
			var incoming = x.to == c.name
			var r = UI.panel(UI.CARD, 16, 16, 12, UI.LINE)
			var h = UI.hb(12)
			h.add_child(UI.icon("arrow-down" if incoming else "arrow-up", 26, UI.GREEN if incoming else UI.AMBER))
			var tv = UI.vb(0)
			tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tv.add_child(UI.lbl_fill(x.name, 25, UI.TEXT, "semi"))
			tv.add_child(UI.lbl_fill(("from %s" % x.from) if incoming else ("to %s" % x.to), 20, UI.MUTED))
			h.add_child(tv)
			h.add_child(UI.lbl(G.money(x.fee) if x.fee > 0 else "Free", 28, UI.TEXT, "disp"))
			r.add_child(h)
			v.add_child(r)
	v.add_child(UI.section("Highest earners"))
	var list = []
	for pid in c.players:
		list.append(s.players[pid])
	list.sort_custom(func(a, b): return a.wage > b.wage)
	for i in min(8, list.size()):
		var p = list[i]
		var pid = p.id
		v.add_child(UI.player_row(p, func(): UI.main.open("player", {"pid": pid}), "%s / wk · until June %d" % [G.money(p.wage), p.cend]))

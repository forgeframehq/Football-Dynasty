extends "res://scripts/screens/screen.gd"
# Transfer market desk: your talks, bids for your players, shortlist and the latest deals, all on one screen.

const STAGE = {"new": "Not approached", "enq_wait": "Your move: fee talks", "club": "Your move: fee talks", "bid_wait": "Your move: fee talks", "deleg": "Assistant is talking", "meet": "Fee agreed: he comes in tomorrow", "talks": "Your move: player terms", "done": "Signed", "dead": "Talks off"}


func build():
	var s = G.s
	var c = G.uc()
	var wopen = G.window_open()
	var find = UI.panel(UI.accent, 14, 16, 9)
	var fh = UI.hb(6)
	fh.add_child(UI.icon("search", 20, UI.on_color(UI.accent)))
	fh.add_child(UI.caps("Player search", 17, UI.on_color(UI.accent)))
	find.add_child(fh)
	UI.tap(find, func(): UI.main.root("search"), true)
	body.add_child(UI.topbar("Transfer market", false, find))
	UI.main.t_sub = "Window %s · budget %s · wage room %s/wk" % ["open" if wopen else "closed", G.money(c.budget), G.money(c.wage_budget - G.squad_wages(c))]
	var h = panes(10, 20)
	# ---- left: talks, offers, money
	var a = pane(0, 3)
	h.add_child(a[0])
	var v = a[1]
	v.add_child(UI.caps("Your talks", 15, UI.accent))
	var deals = G.DL.active()
	if deals.size() == 0:
		v.add_child(UI.wrap("No talks in progress. Open a player's profile and approach his club.", 16, UI.DIM))
	for d in deals:
		var p = s.players[d.pid]
		var mine = d.stage == "club" or d.stage == "talks"
		var pid = p.id
		var mode = d.mode
		v.add_child(UI.trow([UI.ovr(p.ovr, 16), G.pname(p), STAGE[d.stage] if d.mode == "buy" else "Contract talks"], [34, 0, -128],
			{"size": 18, "hi": mine, "cols": {2: UI.AMBER if mine else UI.MUTED}, "tap": func(): UI.main.open("nego", {"pid": pid, "mode": mode})}))
	v.add_child(UI.caps("Bids for your players", 15, UI.accent))
	if s.offers.size() == 0:
		v.add_child(UI.wrap("None. Transfer-list a player to invite bids.", 16, UI.DIM))
	for o in s.offers:
		if not s.players.has(o.pid):
			continue
		var p2 = s.players[o.pid]
		var oid = o.id
		var opid = o.pid
		v.add_child(UI.trow([UI.ovr(p2.ovr, 16), G.pname(p2), s.clubs[o.from].short, G.money(o.fee)], [34, 0, 44, -74],
			{"size": 18, "hi": true, "cols": {2: UI.MUTED, 3: UI.GREEN}, "tap": func(): UI.main.open("nego", {"pid": opid, "mode": "sell", "oid": oid})}))
	v.add_child(UI.caps("Money", 15, UI.accent))
	v.add_child(UI.kv("Transfer budget", G.money(c.budget), UI.GREEN))
	v.add_child(UI.kv("Wage room", "%s/wk" % G.money(c.wage_budget - G.squad_wages(c))))
	v.add_child(UI.kv("Spent this season", G.money(c.spent)))
	v.add_child(UI.kv("Received", G.money(c.earned)))
	var ow = G.DL.owed_total(c.id)
	if ow > 0:
		v.add_child(UI.kv("Instalments owed", G.money(ow), UI.AMBER))
	v.add_child(UI.kv("Squad", "%d / %d" % [c.players.size(), G.TR.MAX_SQUAD]))
	# ---- middle: shortlist
	var b = pane(0, 2)
	b[0].size_flags_stretch_ratio = 1.25
	h.add_child(b[0])
	v = b[1]
	v.add_child(UI.caps("Shortlist · %d" % s.shortlist.size(), 15, UI.accent))
	var w = [34, 34, 0, -26, 44, -66]
	v.add_child(UI.trow(["Ovr", "Pos", "Player", "Age", "Club", "Value"], w, {"head": true}))
	var sl = []
	for pid in s.shortlist.duplicate():
		if s.players.has(pid) and s.players[pid].club != c.id:
			sl.append(s.players[pid])
		else:
			s.shortlist.erase(pid)
	sl.sort_custom(func(x, y): return x.ovr > y.ovr)
	for i in sl.size():
		var p3 = sl[i]
		var pid3 = p3.id
		v.add_child(UI.trow([UI.ovr(p3.ovr, 16), p3.pos, G.pname(p3) + (" ★" if p3.listed else ""), G.age(p3), "Free" if p3.club < 0 else s.clubs[p3.club].short, G.money(G.value(p3))], w,
			{"size": 18, "alt": i % 2 == 0, "cols": {1: UI.MUTED, 4: UI.MUTED, 5: UI.GREEN if G.value(p3) <= c.budget else UI.TEXT}, "tap": func(): UI.main.open("player", {"pid": pid3})}))
	if sl.size() == 0:
		v.add_child(UI.wrap("Empty. Star a player on his profile, or send scouts on an assignment — their finds land here.", 16, UI.DIM))
	var qh = UI.hb(6)
	for q in [["Bargains", "bargains"], ["Expiring", "expiring"], ["Free agents", "free"], ["Listed", "listed"]]:
		var ch = UI.chip(q[0].to_upper(), Color(1, 1, 1, 0.07), UI.TEXT, 15)
		ch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var kind = q[1]
		UI.tap(ch, func(): UI.main.open("lists", {"kind": kind, "grp": "search"}), true)
		qh.add_child(ch)
	v.add_child(UI.sp(0, 4))
	v.add_child(qh)
	# ---- right: done deals
	var d2 = pane(0, 2)
	h.add_child(d2[0])
	v = d2[1]
	v.add_child(UI.caps("Latest deals", 15, UI.accent))
	if s.tx_log.size() == 0:
		v.add_child(UI.wrap("No transfers completed yet this season.", 16, UI.DIM))
	for i in min(60, s.tx_log.size()):
		var t = s.tx_log[i]
		var r = UI.panel(Color(UI.accent, 0.14) if t.user else Color(1, 1, 1, 0.045 if i % 2 == 0 else 0.02), 5, 8, 3)
		var rv = UI.vb(-4)
		var top = UI.hb(6)
		top.add_child(UI.lbl_fill("%s (%d)" % [t.name, t.ovr], 17, UI.TEXT, "semi"))
		top.add_child(UI.lbl(G.money(t.fee) if t.fee > 0 else "Free", 17, UI.GREEN if t.fee > 0 else UI.MUTED, "semi"))
		rv.add_child(top)
		rv.add_child(UI.lbl_fill("%s → %s · %s" % [t.from, t.to, G.fmt_date(t.day)], 14, UI.MUTED))
		r.add_child(rv)
		v.add_child(r)

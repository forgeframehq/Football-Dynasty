extends "res://scripts/screens/screen.gd"
# Transfer market: search, shortlist, incoming offers, recent activity.

const POS_F = ["All", "GK", "DEF", "MID", "ATT"]


func _init():
	show_nav = true


func build():
	var s = G.s
	var c = G.uc()
	var st = G.ui
	var wopen = G.window_open()
	var chip = UI.chip("WINDOW OPEN" if wopen else "WINDOW CLOSED", Color(UI.GREEN if wopen else UI.RED, 0.14), UI.GREEN if wopen else UI.RED, 19)
	body.add_child(UI.topbar("Market", false, chip))
	var top = UI.vb(12)
	var th = UI.hb(10)
	th.add_child(UI.stat_tile("Transfer budget", G.money(c.budget), UI.GREEN))
	th.add_child(UI.stat_tile("Wage room / wk", G.money(c.wage_budget - G.squad_wages(c))))
	top.add_child(th)
	top.add_child(UI.seg(["Search", "Shortlist", "Offers" + (" (%d)" % s.offers.size() if s.offers.size() > 0 else ""), "Deals"], st.tr_tab, func(i):
		st.tr_tab = i
		refresh(), 20))
	body.add_child(UI.margin(top, 24, 0, 24, 12))
	var v = content(8)
	match st.tr_tab:
		0: _search(v)
		1: _shortlist(v)
		2: _offers(v)
		3: _deals(v)


func _search(v: Control):
	var s = G.s
	var st = G.ui
	var c = G.uc()
	var le = UI.input(st.tr_name, "Search by name…", func(t): st.tr_name = t)
	le.text_submitted.connect(func(_t): refresh())
	var sh = UI.hb(8)
	sh.add_child(le)
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var go = UI.panel(UI.accent, 18, 22, 0)
	go.custom_minimum_size = Vector2(0, 80)
	go.add_child(UI.icon("search", 32, UI.on_color(UI.accent)))
	UI.tap(go, func(): refresh(), true)
	sh.add_child(go)
	v.add_child(sh)
	v.add_child(UI.seg(POS_F, st.tr_pos, func(i):
		st.tr_pos = i
		refresh(), 20))
	var fh = UI.hb(8)
	for f in [["tr_afford", "Affordable"], ["tr_u23", "Under 23"], ["tr_listed", "Listed"], ["tr_free", "Free agents"]]:
		var on = st[f[0]]
		var ch = UI.chip(f[1].to_upper(), Color(UI.accent, 0.18) if on else Color(1, 1, 1, 0.05), UI.accent if on else UI.MUTED, 19)
		ch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ch.custom_minimum_size = Vector2(0, 48)
		var key = f[0]
		UI.tap(ch, func():
			st[key] = not st[key]
			refresh(), true)
		fh.add_child(ch)
	v.add_child(fh)
	var q = st.tr_name.strip_edges().to_lower()
	var res = []
	for pid in s.players:
		var p = s.players[pid]
		if p.club == c.id:
			continue
		if st.tr_free and p.club >= 0:
			continue
		if st.tr_listed and not p.listed:
			continue
		if st.tr_pos > 0 and G.LINE[p.pos] != st.tr_pos - 1:
			continue
		if st.tr_u23 and G.age(p) >= 23:
			continue
		if q != "" and not G.pfull(p).to_lower().contains(q) and not G.pname(p).to_lower().contains(q):
			continue
		if st.tr_afford and p.club >= 0 and G.value(p) > c.budget:
			continue
		res.append(p)
	res.sort_custom(func(a, b): return a.ovr > b.ovr if a.ovr != b.ovr else a.pot > b.pot)
	v.add_child(UI.section("Results", "%d found%s" % [res.size(), " · top 60" if res.size() > 60 else ""]))
	for i in min(60, res.size()):
		v.add_child(_prow(res[i]))
	if res.size() == 0:
		v.add_child(UI.wrap("No players match these filters.", 23, UI.MUTED))


func _prow(p: Dictionary) -> Control:
	var club = "Free agent" if p.club < 0 else G.s.clubs[p.club].name
	var pid = p.id
	return UI.player_row(p, func(): UI.main.open("player", {"pid": pid}), "%d yrs · %s · %s" % [G.age(p), club, G.money(G.value(p))])


func _shortlist(v: Control):
	var s = G.s
	if s.shortlist.size() == 0:
		v.add_child(UI.wrap("Your shortlist is empty. Tap the star on any player's profile to keep track of him here.", 23, UI.MUTED))
		return
	for pid in s.shortlist.duplicate():
		if s.players.has(pid):
			v.add_child(_prow(s.players[pid]))
		else:
			s.shortlist.erase(pid)


func _offers(v: Control):
	var s = G.s
	if s.offers.size() == 0:
		v.add_child(UI.wrap("No offers on the table. Transfer-list a player from his profile to attract bids while the window is open.", 23, UI.MUTED))
		return
	for o in s.offers.duplicate():
		var p = s.players[o.pid]
		var fc = s.clubs[o.from]
		var card = UI.card()
		var cv = UI.vb(12)
		var h = UI.hb(14)
		h.add_child(UI.badge(fc, 60))
		var tv = UI.vb(0)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UI.caps("%s bid for" % fc.name, 19, UI.MUTED))
		tv.add_child(UI.lbl_fill(G.pname(p), 30, UI.TEXT, "disp"))
		tv.add_child(UI.lbl_fill("Value %s · expires in %d day%s" % [G.money(G.value(p)), o.exp - s.day + 1, "" if o.exp - s.day == 0 else "s"], 20, UI.MUTED))
		h.add_child(tv)
		var fee = UI.lbl(G.money(o.fee), 38, UI.GREEN, "xbold")
		h.add_child(fee)
		cv.add_child(h)
		var bh = UI.hb(8)
		var a = UI.btn("Accept", func():
			if G.uc().players.size() <= 18:
				UI.toast("You need at least 18 players", UI.RED)
				return
			G.TR.accept_offer(o)
			UI.toast("%s sold for %s" % [G.pname(p), G.money(o.fee)], UI.GREEN)
			refresh(), "primary", "", 68)
		var n = UI.btn("Haggle", func():
			UI.toast(G.TR.haggle_offer(o))
			refresh(), "secondary", "", 68)
		var r = UI.btn("Reject", func():
			s.offers.erase(o)
			refresh(), "danger", "", 68)
		for b in [a, n, r]:
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			bh.add_child(b)
		cv.add_child(bh)
		card.add_child(cv)
		v.add_child(card)


func _deals(v: Control):
	var s = G.s
	if s.tx_log.size() == 0:
		v.add_child(UI.wrap("No transfers completed yet this season.", 23, UI.MUTED))
		return
	for i in min(80, s.tx_log.size()):
		var t = s.tx_log[i]
		var r = UI.panel(UI.CARD, 18, 16, 12, Color(UI.accent, 0.5) if t.user else UI.LINE)
		var h = UI.hb(12)
		h.add_child(UI.ovr(t.ovr, 22))
		var tv = UI.vb(0)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UI.lbl_fill(t.name, 25, UI.TEXT, "semi"))
		tv.add_child(UI.lbl_fill("%s → %s" % [t.from, t.to], 20, UI.MUTED))
		h.add_child(tv)
		var rv = UI.vb(0)
		var fl = UI.lbl(G.money(t.fee) if t.fee > 0 else "Free", 26, UI.TEXT, "disp")
		fl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		rv.add_child(fl)
		var dl = UI.caps(G.fmt_date(t.day).substr(4), 17, UI.DIM)
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		rv.add_child(dl)
		h.add_child(rv)
		r.add_child(h)
		v.add_child(r)

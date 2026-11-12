extends "res://scripts/screens/screen.gd"
# Player profile with attributes, contract, season stats and actions.


func build():
	var s = G.s
	if not s.players.has(args.pid):
		body.add_child(UI.topbar("Player"))
		return
	var p = s.players[args.pid]
	var uc = G.uc()
	var own = p.club == uc.id
	var free = p.club < 0
	var short = p.id in s.shortlist
	var star = UI.panel(Color(1, 1, 1, 0.06), 18, 14, 14)
	star.add_child(UI.icon("star-f" if short else "star", 30, UI.GOLD if short else UI.MUTED))
	UI.tap(star, func():
		if short:
			s.shortlist.erase(p.id)
		else:
			s.shortlist.append(p.id)
		refresh(), true)
	body.add_child(UI.topbar(G.pname(p), true, null if own else star))
	var v = content(14)
	# hero
	var hero = UI.panel(UI.CARD, 28, 24, 22, Color(UI.ovr_color(p.ovr), 0.35))
	var hh = UI.hb(20)
	var ov = UI.vb(-6)
	var big = UI.lbl(str(p.ovr), 104, UI.ovr_color(p.ovr), "xbold")
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ov.add_child(big)
	var ol = UI.caps("Overall", 18, UI.MUTED)
	ol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ov.add_child(ol)
	hh.add_child(ov)
	var hv = UI.vb(6)
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var full = UI.wrap(G.pfull(p), 30, UI.TEXT, "disp")
	hv.add_child(full)
	var ph = UI.hb(6)
	ph.add_child(UI.pos(p.pos))
	for a in p.alt:
		ph.add_child(UI.chip(a, Color(1, 1, 1, 0.05), UI.MUTED, 18))
	hv.add_child(ph)
	hv.add_child(UI.lbl_fill("%s · %d yrs · %s foot" % [p.nat, G.age(p), "Left" if p.foot == "L" else "Right"], 21, UI.MUTED))
	var ch = UI.hb(8)
	if free:
		ch.add_child(UI.lbl("Free agent", 22, UI.GREEN, "semi"))
	else:
		ch.add_child(UI.badge(s.clubs[p.club], 30))
		ch.add_child(UI.lbl_fill(s.clubs[p.club].name, 22, UI.TEXT, "semi"))
	hv.add_child(ch)
	hh.add_child(hv)
	var pv = UI.vb(-4)
	var known = G.OPS.knows(p) or p.get("loan", -1) == uc.id
	var pl = UI.lbl(str(p.pot) if known else G.OPS.pot_text(p), 48 if known else 34, UI.ovr_color(p.pot) if known else UI.MUTED, "xbold")
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pv.add_child(pl)
	var pc = UI.caps("Potential", 16, UI.MUTED)
	pc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pv.add_child(pc)
	pv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hh.add_child(pv)
	hero.add_child(hh)
	v.add_child(hero)
	# status
	var t = UI.hb(10)
	t.add_child(UI.stat_tile("Value", G.money(G.value(p))))
	t.add_child(UI.stat_tile("Wage / wk", G.money(p.wage)))
	t.add_child(UI.stat_tile("Contract", "—" if free else "Jun %d" % p.cend, UI.AMBER if (not free and p.cend <= s.season + 1) else UI.TEXT))
	v.add_child(t)
	var t2 = UI.hb(10)
	t2.add_child(UI.stat_tile("Fitness", "%d%%" % p.cond, UI.cond_color(p.cond)))
	t2.add_child(UI.stat_tile("Morale", "%d" % p.mor, UI.cond_color(p.mor + 10)))
	t2.add_child(UI.stat_tile("Form", "%.1f" % p.form, UI.GREEN if p.form >= 7.0 else UI.TEXT))
	v.add_child(t2)
	if p.inj > 0:
		v.add_child(_note("bandage", "Injured — out for around %s." % G.inj_text(p.inj), UI.RED))
	if p.susp > 0:
		v.add_child(_note("square", "Suspended for %d match%s." % [p.susp, "" if p.susp == 1 else "es"], UI.RED))
	# attributes
	v.add_child(UI.section("Attributes", "%d★ skills · %d★ weak foot" % [p.sm, p.wf]))
	var ac = UI.card()
	var av = UI.vb(12)
	var names = G.GK_STAT_NAMES if p.pos == "GK" else G.STAT_NAMES
	for i in 6:
		var r = UI.hb(14)
		var nl = UI.caps(names[i], 22, UI.MUTED)
		nl.custom_minimum_size = Vector2(56, 0)
		r.add_child(nl)
		r.add_child(UI.bar(p.st[i] / 99.0, UI.ovr_color(p.st[i]), 10))
		var vl = UI.lbl(str(p.st[i]), 26, UI.ovr_color(p.st[i]), "disp")
		vl.custom_minimum_size = Vector2(40, 0)
		vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		r.add_child(vl)
		av.add_child(r)
	ac.add_child(av)
	v.add_child(ac)
	if p.pos != "GK":
		var dc = UI.card()
		var dv = UI.vb(14)
		for grp in G.RL.ATTR_GROUPS:
			var gv = UI.vb(6)
			gv.add_child(UI.caps(grp[0], 19, UI.accent))
			var grid = GridContainer.new()
			grid.columns = 2
			grid.add_theme_constant_override("h_separation", 28)
			grid.add_theme_constant_override("v_separation", 6)
			grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
			for k in grp[1]:
				var r = UI.hb(8)
				r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				r.add_child(UI.lbl_fill(G.RL.ATTR[k], 22, UI.MUTED))
				r.add_child(UI.lbl(str(p.at[k]), 24, UI.ovr_color(p.at[k]), "disp"))
				grid.add_child(r)
			gv.add_child(grid)
			dv.add_child(gv)
		dc.add_child(dv)
		v.add_child(dc)
		var best = []
		for rid in G.RL.BY_POS[p.pos]:
			best.append([G.RL.suit(p, rid), G.RL.ROLES[rid].n])
		best.sort_custom(func(x, y): return x[0] > y[0])
		v.add_child(UI.kv("Best roles", "%s · %s" % [best[0][1], best[1][1]] if best.size() > 1 else best[0][1]))
	# season
	v.add_child(UI.section("Season %s" % G.season_name(), "Career: %d apps · %d goals" % [p.cap, p.cg]))
	var g1 = UI.hb(10)
	g1.add_child(UI.stat_tile("Apps", str(p.ss.ap)))
	g1.add_child(UI.stat_tile("Goals", str(p.ss.g)))
	g1.add_child(UI.stat_tile("Assists", str(p.ss.a)))
	g1.add_child(UI.stat_tile("Avg", "%.2f" % G.avg_rating(p) if p.ss.ap > 0 else "—"))
	v.add_child(g1)
	var g2 = UI.hb(10)
	g2.add_child(UI.stat_tile("MOTM", str(p.ss.mom)))
	g2.add_child(UI.stat_tile("Clean sh.", str(p.ss.cs)))
	g2.add_child(UI.stat_tile("Yellows", str(p.ss.yc)))
	g2.add_child(UI.stat_tile("Reds", str(p.ss.rc)))
	v.add_child(g2)
	# actions
	v.add_child(UI.sp(0, 4))
	var loaned_in = own and p.get("loan", -1) >= 0
	var loaned_out = (not own) and p.get("loan", -1) == uc.id
	if loaned_in:
		v.add_child(_note("clock", "On loan from %s until the end of the season." % s.clubs[p.loan].name, UI.BLUE))
	if loaned_out:
		v.add_child(_note("clock", "Your player — on loan at %s until the end of the season." % s.clubs[p.club].name, UI.BLUE))
	if own and not loaned_in:
		if p.get("youth", false):
			v.add_child(UI.btn("Promote to first team", func():
				p.erase("youth")
				UI.toast("%s joins the first-team squad" % G.pname(p), UI.GREEN)
				refresh(), "gold", "arrow-up"))
		v.add_child(UI.section("Squad status", "how he reacts to being left out"))
		v.add_child(UI.seg(["Key", "Rotation", "Backup", "Prospect"], G.status_of(p), func(i):
			p["status"] = i
			refresh(), 20))
		var tf = p.get("tr", "")
		var rt = p.get("rt", null)
		var th = UI.hb(10)
		var tb = UI.btn("Training: %s" % (tf if tf != "" else "general"), func(): _indiv(p), "secondary", "activity", 68)
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		th.add_child(tb)
		var rb0 = UI.btn("Learning %s" % rt[0] if rt != null else "New position", func(): _retrain(p), "secondary", "repeat", 68)
		rb0.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		th.add_child(rb0)
		v.add_child(th)
	v.add_child(UI.btn("Compare with…", func(): _compare(p), "secondary", "users", 68))
	v.add_child(UI.btn("Find similar players", func(): UI.main.open("lists", {"kind": "similar", "pid": p.id, "grp": "search"}), "secondary", "search", 56))
	if G.settings.get("editor", false):
		var eh = UI.hb(8)
		for d in [-1, 1]:
			var eb = UI.btn("Rating %+d" % d, func():
				G.change_ovr(p, d)
				p.pot = max(p.pot, p.ovr)
				refresh(), "ghost", "pencil", 52)
			eb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			eh.add_child(eb)
		v.add_child(eh)
	if own and not loaned_in:
		v.add_child(UI.btn("Offer new contract", func(): UI.main.open("nego", {"pid": p.id, "mode": "renew"}), "primary", "handshake"))
		var hb2 = UI.hb(10)
		var lb = UI.btn("Unlist" if p.listed else "Transfer list", func():
			p.listed = not p.listed
			UI.toast("%s %s the transfer list" % [G.pname(p), "added to" if p.listed else "removed from"])
			refresh(), "secondary", "flag", 72)
		lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb2.add_child(lb)
		var lo = UI.btn("Loan out", func(): _loan_out(p), "secondary", "arrow-left-right", 72)
		lo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb2.add_child(lo)
		var rb = UI.btn("Release", func(): _release(p), "danger", "log-out", 72)
		rb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb2.add_child(rb)
		v.add_child(hb2)
	elif free:
		_scout_btn(v, p)
		v.add_child(UI.btn("Offer contract", func(): UI.main.open("nego", {"pid": p.id, "mode": "free"}), "primary", "handshake"))
	elif not own and not loaned_out:
		_scout_btn(v, p)
		if G.window_open():
			v.add_child(UI.btn("Make transfer offer", func(): UI.main.open("nego", {"pid": p.id, "mode": "buy"}), "primary", "handshake"))
			var ap = UI.caps("Asking price around %s%s" % [G.money(G.TR.asking_price(p)), (" · release clause %s" % G.money(p.rc)) if p.get("rc", 0) > 0 else ""], 19, UI.MUTED)
			ap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			v.add_child(ap)
			v.add_child(UI.btn("Ask for a season loan", func():
				var r = G.OPS.can_loan_in(p)
				if not r.ok:
					UI.toast(r.why, UI.RED)
					return
				G.OPS.loan_in(p)
				UI.toast("%s joins on loan" % G.pname(p), UI.GREEN)
				refresh(), "secondary", "arrow-left-right", 68))
		else:
			v.add_child(_note("clock", "The transfer window is closed. You can approach %s when it reopens." % G.pname(p), UI.MUTED))


func _scout_btn(v: Control, p: Dictionary):
	if G.OPS.knows(p):
		return
	var watching = false
	for q in G.s.scout.queue:
		if q.pid == p.id:
			watching = true
			v.add_child(_note("search", "Your scouts are watching him — report in %d day%s." % [max(1, q.done - G.s.day), "" if q.done - G.s.day == 1 else "s"], UI.accent))
	if not watching:
		v.add_child(UI.btn("Scout player (%d days)" % G.OPS.scout_days(), func():
			var err = G.OPS.scout_player(p)
			if err != "":
				UI.toast(err, UI.RED)
			refresh(), "secondary", "search", 68))


func _loan_out(p: Dictionary):
	UI.confirm("Loan out %s?" % G.pname(p), "Your staff will find him a club where he should play regularly. He returns at the end of the season.", "Send on loan", func():
		var err = G.OPS.loan_out(p)
		if err != "":
			UI.toast(err, UI.RED)
		else:
			UI.main.back())


func _indiv(p: Dictionary):
	var build_sheet = func(v):
		v.add_child(UI.wrap("Extra work on one area each month. It does not raise his overall directly, but sharpens the attributes his role relies on.", 21, UI.MUTED))
		for k in [""] + G.OPS.INDIV.keys():
			var on = p.get("tr", "") == k
			var r = UI.panel(Color(UI.accent, 0.14) if on else UI.CARD, 16, 18, 12, UI.accent if on else UI.LINE)
			var h = UI.hb(10)
			h.add_child(UI.lbl(k if k != "" else "General training", 26, UI.TEXT, "disp"))
			h.add_child(UI.sp())
			if k != "":
				var names = []
				for a in G.OPS.INDIV[k]:
					names.append(G.RL.ATTR[a])
				h.add_child(UI.caps(", ".join(names), 16, UI.DIM))
			r.add_child(h)
			var key = k
			UI.tap(r, func():
				if key == "":
					p.erase("tr")
				else:
					p["tr"] = key
				UI.close_sheet()
				refresh())
			v.add_child(r)
	UI.sheet("Individual training", build_sheet)


func _retrain(p: Dictionary):
	if p.pos == "GK":
		UI.toast("Goalkeepers cannot retrain", UI.RED)
		return
	var build_sheet = func(v):
		v.add_child(UI.wrap("He will learn the position over about three months and can then play there without a penalty.", 21, UI.MUTED))
		for pos in ["CB", "LB", "RB", "CDM", "CM", "CAM", "LM", "RM", "LW", "RW", "ST"]:
			if pos == p.pos or pos in p.alt:
				continue
			var r = UI.panel(UI.CARD, 16, 18, 10, UI.LINE)
			var h = UI.hb(12)
			h.add_child(UI.pos(pos))
			h.add_child(UI.lbl_fill("Current fit %d%%" % int(G.fit(p, pos) * 100), 23, UI.MUTED))
			h.add_child(UI.caps("Best as %s" % G.RL.ROLES[G.RL.best(p, pos)].n, 17, UI.DIM))
			r.add_child(h)
			var np = pos
			UI.tap(r, func():
				G.OPS.start_retrain(p, np)
				UI.close_sheet()
				UI.toast("%s starts learning %s" % [G.pname(p), np], UI.GREEN)
				refresh())
			v.add_child(r)
	UI.sheet("Retrain position", build_sheet)


func _compare(p: Dictionary):
	var build_sheet = func(v):
		var pool = []
		for pid in G.uc().players + G.s.shortlist:
			if pid != p.id and G.s.players.has(pid):
				pool.append(G.s.players[pid])
		pool.sort_custom(func(a, b): return (0 if G.LINE[a.pos] == G.LINE[p.pos] else 1) * 1000 - a.ovr < (0 if G.LINE[b.pos] == G.LINE[p.pos] else 1) * 1000 - b.ovr)
		v.add_child(UI.caps("Your squad and shortlist", 19, UI.DIM))
		for q in pool:
			var qid = q.id
			v.add_child(UI.player_row(q, func():
				UI.close_sheet()
				UI.main.open("compare", {"a": p.id, "b": qid})))
	UI.sheet("Compare %s with" % G.pname(p), build_sheet)


func _note(icon_name: String, text: String, color: Color) -> Control:
	var p = UI.panel(Color(color, 0.1), 18, 18, 14, Color(color, 0.3))
	var h = UI.hb(12)
	h.add_child(UI.icon(icon_name, 26, color))
	h.add_child(UI.wrap(text, 22, color))
	p.add_child(h)
	return p


func _release(p: Dictionary):
	if G.uc().players.size() <= 18:
		UI.toast("You need at least 18 players", UI.RED)
		return
	UI.confirm("Release %s?" % G.pname(p), "His contract will be terminated and he will become a free agent. This cannot be undone.", "Release player", func():
		G.LG.release(p)
		G.fix_lineup()
		G.news("%s release %s." % [G.uc().name, G.pfull(p)])
		UI.main.back(), true)

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
	var pl = UI.lbl(str(p.pot), 48, UI.ovr_color(p.pot), "xbold")
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
	if own:
		v.add_child(UI.section("Squad status", "affects how he reacts to being left out"))
		v.add_child(UI.seg(["Key", "Rotation", "Backup", "Prospect"], G.status_of(p), func(i):
			p["status"] = i
			refresh(), 20))
	v.add_child(UI.btn("Compare with…", func(): _compare(p), "secondary", "users", 68))
	if own:
		v.add_child(UI.btn("Offer new contract", func(): UI.main.open("nego", {"pid": p.id, "mode": "renew"}), "primary", "handshake"))
		var hb2 = UI.hb(10)
		var lb = UI.btn("Unlist" if p.listed else "Transfer list", func():
			p.listed = not p.listed
			UI.toast("%s %s the transfer list" % [G.pname(p), "added to" if p.listed else "removed from"])
			refresh(), "secondary", "flag", 72)
		lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb2.add_child(lb)
		var rb = UI.btn("Release", func(): _release(p), "danger", "log-out", 72)
		rb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb2.add_child(rb)
		v.add_child(hb2)
	elif free:
		v.add_child(UI.btn("Offer contract", func(): UI.main.open("nego", {"pid": p.id, "mode": "free"}), "primary", "handshake"))
	else:
		if G.window_open():
			v.add_child(UI.btn("Make transfer offer", func(): UI.main.open("nego", {"pid": p.id, "mode": "buy"}), "primary", "handshake"))
			v.add_child(UI.caps("Asking price around %s" % G.money(G.TR.asking_price(p)), 19, UI.MUTED))
			v.get_child(v.get_child_count() - 1).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		else:
			v.add_child(_note("clock", "The transfer window is closed. You can approach %s when it reopens." % G.pname(p), UI.MUTED))


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

extends "res://scripts/screens/screen.gd"
# Scouting: three tabs. Network (your scouts, hiring, missions and a new-mission ticket), Reports (every senior
# report as a sortable table with ranges, verdict and fee), Youth Academy (your academy and the youngsters your
# scouts found, ready to sign). The old screen (watch list, standing assignment, recruitment brief) is the fourth tab.

const TABS = ["Network", "Reports", "Youth Academy", "Watch & brief"]

var tab := 0
# new mission ticket
var f_sid := -1
var f_kind := 0
var f_region := ""
var f_months := 1
var f_line := 0
var f_age := 0
var f_focus := 0
var f_budget := 0
var f_where := 2
# reports
var r_line := 0
var r_sort := 0


func build():
	G.SN.ensure()
	var s = G.s
	if args.has("tab") and not has_meta("init"):
		set_meta("init", true)
		tab = int(args.tab)
	backdrop("academy" if tab == 2 else "scouting", 0.8)
	UI.main.t_title = "Scouting"
	UI.main.t_sub = "%d of %d scouts · %d mission%s out · %d reports · academy %d of %d" % [G.SN.scouts().size(), G.SN.cap(), s.sn.missions.size(), "" if s.sn.missions.size() == 1 else "s",
		s.sn.reports.size(), G.SN.academy().size(), G.SN.academy_cap()]
	var bar = UI.seg(TABS, tab, func(i):
		if i == 3:
			UI.main.open("scouting")
			return
		tab = i
		refresh(), 15, 5)
	body.add_child(UI.margin(bar, 20, 0, 20, 4))
	match tab:
		0: _network()
		1: _reports()
		2: _youth()


# ---------------------------------------------------------------- network

func _network():
	var s = G.s
	var h = panes(12, 20)
	var a = pane(380, 6)
	h.add_child(a[0])
	var v = a[1]
	var top = UI.hb(6)
	top.add_child(UI.caps("Your scouts · %d of %d" % [G.SN.scouts().size(), G.SN.cap()], 16, UI.accent))
	top.add_child(UI.sp())
	var hb = UI.chip("HIRE A SCOUT", UI.accent, UI.on_color(UI.accent), 14)
	UI.tap(hb, _hire_sheet, true)
	top.add_child(hb)
	v.add_child(top)
	for p in G.SN.scouts():
		v.add_child(_scout_card(p))
	if G.SN.scouts().size() < G.SN.cap():
		v.add_child(UI.wrap("Room for %d more. Each scout runs one mission at a time." % (G.SN.cap() - G.SN.scouts().size()), 15, UI.DIM))
	var cs = G.SF.who("scout")
	v.add_child(UI.lbl_fill("Chief scout: %s" % (("%s, %s stars, sharpens every report" % [G.SF.nm(cs), str(G.SF.stars(G.SF.r("scout"))).trim_suffix(".0")]) if cs != null else "none (hire one in Staff)"), 15, UI.MUTED))
	# missions
	var b = pane(0, 6)
	h.add_child(b[0])
	var w = b[1]
	w.add_child(UI.caps("Missions", 16, UI.accent))
	if s.sn.missions.is_empty():
		w.add_child(UI.lbl_fill("No scouts out. Send one from the ticket below.", 16, UI.DIM))
	for m in s.sn.missions:
		var p = s.staff[int(m.sid)]
		var row = UI.hb(8)
		row.add_child(UI.icon("graduation-cap" if m.kind == "youth" else "eye", 18, UI.GREEN if m.kind == "youth" else UI.accent))
		var tv = UI.vb(-4)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UI.lbl_fill("%s · %s · %s" % [G.SF.nm(p), m.region, "youth" if m.kind == "youth" else G.SN.FOCUS[int(m.focus)].to_lower()], 16, UI.TEXT, "semi"))
		var left = int(m.end) - s.day
		tv.add_child(UI.lbl_fill("%d days left · %d report%s so far · next in about %d days" % [left, int(m.found), "" if int(m.found) == 1 else "s", max(0, int(m.nextr) - s.day)], 14, UI.DIM))
		row.add_child(tv)
		var pb = UI.bar(1.0 - float(left) / max(1.0, float(int(m.end) - int(m.start))), UI.accent, 6)
		pb.custom_minimum_size = Vector2(90, 6)
		row.add_child(pb)
		w.add_child(row)
	w.add_child(UI.sp(0, 4))
	_ticket(w)


func _scout_card(p: Dictionary) -> Control:
	var s = G.s
	var pc = UI.panel(Color(1, 1, 1, 0.035), 10, 10, 6, UI.LINE)
	var pv = UI.vb(0)
	var r1 = UI.hb(6)
	r1.add_child(UI.flag(p.nat, 20))
	r1.add_child(UI.lbl_fill(G.SF.nm(p), 18, UI.TEXT, "semi"))
	var on = null
	for m in s.sn.missions:
		if int(m.sid) == int(p.id):
			on = m
	r1.add_child(UI.chip(("OUT · " + str(on.region).to_upper()) if on != null else "AVAILABLE", Color(UI.AMBER if on != null else UI.GREEN, 0.16), UI.AMBER if on != null else UI.GREEN, 12))
	pv.add_child(r1)
	var r2 = UI.hb(6)
	r2.add_child(UI.lbl("Senior", 14, UI.MUTED))
	r2.add_child(UI.half_stars(G.SF.stars(float(p.a.judge)), 13))
	r2.add_child(UI.lbl("  Youth", 14, UI.MUTED))
	r2.add_child(UI.half_stars(G.SF.stars(float(p.a.youth)), 13))
	pv.add_child(r2)
	pv.add_child(UI.lbl_fill("Knows %s · %s a week" % [p.region, G.money(p.wage)], 14, UI.DIM))
	pc.add_child(pv)
	var pp = p
	UI.tap(pc, func():
		if on == null:
			f_sid = pp.id
			if f_region == "":
				f_region = pp.region
			f_kind = 1 if float(pp.a.youth) > float(pp.a.judge) else 0
			refresh()
		else:
			UI.confirm("Release %s?" % G.SF.nm(pp), "He leaves the network and his mission ends. Three months' wages (%s) come out of the budget." % G.money(int(pp.wage * 13)), "Release", func():
				G.SN.release(pp)
				refresh(), true))
	return pc


func _ticket(w: VBoxContainer):
	var s = G.s
	var free = G.SN.scouts().filter(func(p): return not G.SN.busy(p))
	var tk = UI.panel(Color(1, 1, 1, 0.04), 12, 12, 10, UI.LINE)
	var tv = UI.vb(6)
	tk.add_child(tv)
	tv.add_child(UI.caps("New mission", 15, UI.accent))
	if free.is_empty():
		tv.add_child(UI.wrap("Every scout is out. Hire another, or wait for one to come back.", 16, UI.DIM))
		w.add_child(tk)
		return
	var sc = null
	for p in free:
		if int(p.id) == f_sid:
			sc = p
	if sc == null:
		sc = free[0]
		f_sid = sc.id
	if f_region == "":
		f_region = sc.region
	var r1 = UI.hb(8)
	var names = free.map(func(p): return str(p.ln))
	var si = free.find(sc)
	var ss = UI.seg(names, si, func(i):
		f_sid = free[i].id
		refresh(), 14, 4)
	ss.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r1.add_child(ss)
	var ks = UI.seg(["Senior", "Youth"], f_kind, func(i):
		f_kind = i
		refresh(), 14, 4)
	ks.custom_minimum_size = Vector2(170, 0)
	r1.add_child(ks)
	tv.add_child(r1)
	var r2 = UI.hb(8)
	var rb = UI.btn("Region: %s%s" % [f_region, " (home)" if f_region == sc.region else ""], _region_sheet, "secondary", "globe", 40)
	rb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r2.add_child(rb)
	var ms = UI.seg(["1 month", "2 months", "3 months"], f_months - 1, func(i):
		f_months = i + 1
		refresh(), 14, 4)
	ms.custom_minimum_size = Vector2(250, 0)
	r2.add_child(ms)
	tv.add_child(r2)
	var r3 = UI.hb(8)
	r3.add_child(UI.seg(G.SN.LINES, f_line, func(i):
		f_line = i
		refresh(), 14, 4))
	if f_kind == 0:
		r3.add_child(UI.seg(G.SN.AGES.map(func(x): return x[0]), f_age, func(i):
			f_age = i
			refresh(), 14, 4))
		r3.add_child(UI.seg(G.SN.BUDGETS.map(func(x): return x[0]), f_budget, func(i):
			f_budget = i
			refresh(), 14, 4))
	for c in r3.get_children():
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(r3)
	if f_kind == 0:
		var r5 = UI.hb(8)
		var ws = UI.seg(G.SN.WHERE, f_where, func(i):
			f_where = i
			refresh(), 14, 4)
		ws.custom_minimum_size = Vector2(300, 0)
		r5.add_child(ws)
		var fs = UI.seg(G.SN.FOCUS, f_focus, func(i):
			f_focus = i
			refresh(), 14, 4)
		fs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r5.add_child(fs)
		tv.add_child(r5)
	var kind = "senior" if f_kind == 0 else "youth"
	var eye = G.SN.eye(sc, kind, f_region)
	var r4 = UI.hb(8)
	var info = UI.vb(-3)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var st = UI.hb(6)
	st.add_child(UI.lbl("His eye here", 15, UI.MUTED))
	st.add_child(UI.half_stars(G.SF.stars(eye), 14))
	info.add_child(st)
	info.add_child(UI.lbl_fill("A report about every %d days · trip %s · %s" % [G.SN.report_gap(sc, kind, f_region), G.money(G.SN.COST[kind] * f_months),
		"talent-rich region" if float(G.SN.TALENT.get(f_region, 1.0)) >= 1.1 else ("cheap region" if G.SN.CHEAP.has(f_region) else "")], 14, UI.DIM))
	r4.add_child(info)
	var go = UI.btn("Send %s" % sc.ln, func():
		var why = G.SN.start(sc, kind, f_region, f_months, f_line, f_age, f_focus, f_budget, f_where)
		if why != "":
			UI.toast(why, UI.RED)
			return
		UI.sfx("confirm", -8.0)
		UI.toast("%s is on his way to %s" % [G.SF.nm(sc), f_region], UI.GREEN)
		f_sid = -1
		refresh(), "primary", "arrow-right", 46)
	go.custom_minimum_size = Vector2(190, 46)
	r4.add_child(go)
	tv.add_child(r4)
	w.add_child(tk)


func _region_sheet():
	var build = func(v):
		var g = GridContainer.new()
		g.columns = 2
		g.add_theme_constant_override("h_separation", 8)
		g.add_theme_constant_override("v_separation", 6)
		for r in G.SN.REGIONS:
			var rr = r
			var tal = float(G.SN.TALENT.get(r, 1.0))
			var sub = ("Talent-rich" if tal >= 1.1 else ("Good talent" if tal >= 1.0 else "Thin talent")) + (" · cheap" if G.SN.CHEAP.has(r) else "")
			var b = UI.panel(Color(UI.accent, 0.2) if r == f_region else Color(1, 1, 1, 0.05), 10, 12, 8)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var bv = UI.vb(-3)
			bv.add_child(UI.lbl_fill(r, 18, UI.TEXT, "semi"))
			bv.add_child(UI.lbl_fill(sub, 14, UI.GREEN if tal >= 1.1 else UI.MUTED))
			b.add_child(bv)
			UI.tap(b, func():
				f_region = rr
				UI.close_sheet()
				refresh(), true)
			g.add_child(b)
		v.add_child(g)
	UI.sheet("Where to scout", build)


func _hire_sheet():
	var build = func(v):
		v.add_child(UI.wrap("Scouts see best in their home region. Senior eye: how well they judge first-team players. Youth eye: how well they spot 15 and 16 year-olds.", 16, UI.MUTED))
		var list = G.SN.market().map(func(x): return G.s.staff[x])
		list.sort_custom(func(a, b): return max(a.a.judge, a.a.youth) > max(b.a.judge, b.a.youth))
		v.add_child(UI.trow(["Name", "Knows", "Senior", "Youth", "Wage", ""], [0, 130, 82, 82, -60, 64], {"head": true, "size": 16, "pad": 1}))
		for p in list.slice(0, 18):
			var nm = UI.hb(5)
			nm.add_child(UI.flag(p.nat, 18))
			nm.add_child(UI.lbl_fill(G.SF.nm(p), 16, UI.TEXT))
			var hc = UI.chip("HIRE", UI.accent, UI.on_color(UI.accent), 14)
			var pp = p
			UI.tap(hc, func():
				var why = G.SN.hire(pp)
				UI.close_sheet()
				if why != "":
					UI.toast(why, UI.RED)
				else:
					UI.sfx("sign", -8.0)
					UI.toast("%s joins your scouting network" % G.SF.nm(pp), UI.GREEN)
				refresh(), true)
			v.add_child(UI.trow([nm, p.region, UI.half_stars(G.SF.stars(float(p.a.judge)), 13), UI.half_stars(G.SF.stars(float(p.a.youth)), 13), G.money(p.wage), hc], [0, 130, 82, 82, -60, 64], {"size": 15, "pad": 2, "cols": {1: UI.MUTED}}))
	UI.sheet("Hire a scout", build)


# ---------------------------------------------------------------- reports

func _reports():
	var s = G.s
	var h = panes(12, 20)
	var a = pane(0, 2)
	h.add_child(a[0])
	var v = a[1]
	var top = UI.hb(8)
	top.add_child(UI.caps("Scout reports", 16, UI.accent))
	top.add_child(UI.sp())
	var ls = UI.seg(G.SN.LINES, r_line, func(i):
		r_line = i
		refresh(), 14, 4)
	ls.custom_minimum_size = Vector2(300, 0)
	top.add_child(ls)
	top.add_child(UI.caps("Sort", 14, UI.MUTED))
	var so = UI.seg(["Potential", "Now", "Fee", "Newest"], r_sort, func(i):
		r_sort = i
		refresh(), 14, 4)
	so.custom_minimum_size = Vector2(300, 0)
	top.add_child(so)
	v.add_child(top)
	var list = s.sn.reports.filter(func(r): return s.players.has(int(r.pid)) and (r_line == 0 or G.LINE[s.players[int(r.pid)].pos] == r_line - 1))
	match r_sort:
		0: list.sort_custom(func(x, y): return x.pot[0] + x.pot[1] > y.pot[0] + y.pot[1])
		1: list.sort_custom(func(x, y): return x.ovr[0] + x.ovr[1] > y.ovr[0] + y.ovr[1])
		2: list.sort_custom(func(x, y): return x.fee < y.fee)
	var W = [0, -36, 46, 150, -70, -70, 150, -66, 82, -52, 74]
	v.add_child(UI.trow(["Player", "Age", "Pos", "Club", "Now", "Pot", "Verdict", "Fee", "Scout", "Date", ""], W, {"head": true, "size": 16, "pad": 1}))
	if list.is_empty():
		v.add_child(UI.wrap("No reports yet. Send a scout on a senior mission from the Network tab; reports come in during the trip.", 17, UI.DIM))
	for i in list.size():
		var r = list[i]
		var p = s.players[int(r.pid)]
		var nm = UI.hb(5)
		nm.add_child(UI.flag(p.nat, 18))
		nm.add_child(UI.lbl_fill(G.pname(p), 16, UI.TEXT, "semi"))
		if p.id in s.shortlist:
			nm.add_child(UI.icon("star-f", 14, UI.GOLD))
		var club = s.clubs[p.club].short if p.club >= 0 else "Free"
		var vc = {"Sign him": UI.GREEN, "Good squad player": UI.accent, "One for the future": UI.AMBER}.get(r.verdict, UI.DIM)
		var pid = p.id
		var oc = UI.chip("OFFER", Color(UI.accent, 0.16), UI.accent, 13)
		UI.tap(oc, func(): UI.main.open("nego", {"pid": pid, "mode": "buy" if p.club >= 0 else "free"}), true)
		v.add_child(UI.trow([nm, str(G.age(p)), UI.pos(p.pos, 14), club, "%d-%d" % [r.ovr[0], r.ovr[1]], "%d-%d" % [r.pot[0], r.pot[1]], r.verdict, G.money(r.fee), UI.half_stars(float(r.stars), 13), G.fmt_date(int(r.day)).substr(4, 6), oc], W,
			{"size": 16, "pad": 2, "alt": i % 2 == 0, "cols": {3: UI.MUTED, 5: UI.GREEN, 6: vc}, "tap": func(): UI.main.open("player", {"pid": pid})}))


# ---------------------------------------------------------------- youth academy

func _youth():
	var s = G.s
	var h = panes(12, 20)
	var a = pane(0, 2)
	a[0].size_flags_stretch_ratio = 1.25
	h.add_child(a[0])
	var v = a[1]
	var ac = G.SN.academy()
	ac.sort_custom(func(x, y): return x.pot > y.pot)
	var top = UI.hb(6)
	top.add_child(UI.caps("Your academy · %d of %d" % [ac.size(), G.SN.academy_cap()], 16, UI.accent))
	top.add_child(UI.sp())
	var hy = G.SF.who("youth")
	top.add_child(UI.lbl("Head of youth", 14, UI.MUTED))
	top.add_child(UI.half_stars(G.SF.stars(G.SF.r("youth")), 13, UI.GOLD if hy != null else UI.RED))
	v.add_child(top)
	var W = [0, -36, 46, -40, -40, -60, 90]
	v.add_child(UI.trow(["Player", "Age", "Pos", "Now", "Pot", "Growth", ""], W, {"head": true, "size": 16, "pad": 1}))
	if ac.is_empty():
		v.add_child(UI.wrap("No academy players. Your intake arrives each summer; your youth scouts can find more.", 16, UI.DIM))
	for i in ac.size():
		var p = ac[i]
		var nm = UI.hb(5)
		nm.add_child(UI.flag(p.nat, 18))
		nm.add_child(UI.lbl_fill(G.pname(p), 16, UI.TEXT, "semi"))
		if G.SN.ready(p):
			nm.add_child(UI.chip("READY", Color(UI.GREEN, 0.16), UI.GREEN, 12))
		var pp = p
		var pr = UI.chip("PROMOTE", Color(UI.accent, 0.16), UI.accent, 13)
		UI.tap(pr, func():
			G.SN.promote(pp)
			UI.toast("%s moves up to the first-team squad" % G.pname(pp), UI.GREEN)
			refresh(), true)
		var g = int(round((G.OPS.growth_mult(p) - 1.0) * 100))
		v.add_child(UI.trow([nm, str(G.age(p)), UI.pos(p.pos, 14), str(p.ovr), str(p.pot), "%+d%%" % g, pr], W,
			{"size": 16, "pad": 2, "alt": i % 2 == 0, "cols": {3: UI.ovr_color(p.ovr), 4: UI.GREEN, 5: UI.GREEN if g >= 0 else UI.RED}, "tap": func(): UI.main.open("player", {"pid": pp.id})}))
	# prospects found by youth scouts
	var b = pane(0, 6)
	h.add_child(b[0])
	var w = b[1]
	w.add_child(UI.caps("Found by your scouts", 16, UI.accent))
	if s.sn.prospects.is_empty():
		w.add_child(UI.wrap("Nobody yet. Send a scout on a youth mission from the Network tab. Prospects wait about two months before other clubs move in.", 16, UI.DIM))
	for pr2 in s.sn.prospects:
		w.add_child(_prospect(pr2))


func _prospect(pr: Dictionary) -> Control:
	var s = G.s
	var pc = UI.panel(Color(1, 1, 1, 0.035), 10, 10, 6, Color(UI.GOLD, 0.6) if int(pr.pr[1]) >= 85 else UI.LINE)
	var pv = UI.vb(0)
	var r1 = UI.hb(6)
	r1.add_child(UI.flag(pr.nat, 20))
	r1.add_child(UI.lbl_fill("%s %s" % [pr.fn, pr.ln], 18, UI.TEXT, "semi"))
	r1.add_child(UI.pos(pr.pos, 14))
	r1.add_child(UI.lbl("%d" % int(pr.age), 16, UI.MUTED, "disp"))
	pv.add_child(r1)
	pv.add_child(UI.lbl_fill("Potential %d-%d · now about %d · %s, %d days ago" % [int(pr.pr[0]), int(pr.pr[1]), int(pr.ovr) + G.rng.randi_range(-2, 2) * 0, pr.region, s.day - int(pr.day)], 15, UI.GREEN))
	var r2 = UI.hb(6)
	r2.add_child(UI.lbl("%s ·" % pr.scout, 14, UI.DIM))
	r2.add_child(UI.half_stars(float(pr.stars), 12))
	r2.add_child(UI.sp())
	var pp = pr
	var sg = UI.chip("SIGN · %s" % G.money(pr.fee), UI.accent, UI.on_color(UI.accent), 14)
	UI.tap(sg, func():
		var why = G.SN.sign(pp)
		if why != "":
			UI.toast(why, UI.RED)
		else:
			UI.sfx("sign", -8.0)
			UI.toast("%s %s signs for the academy" % [pp.fn, pp.ln], UI.GREEN)
		refresh(), true)
	r2.add_child(sg)
	var ps = UI.chip("PASS", Color(1, 1, 1, 0.06), UI.MUTED, 14)
	UI.tap(ps, func():
		s.sn.prospects.erase(pp)
		refresh(), true)
	r2.add_child(ps)
	pv.add_child(r2)
	pc.add_child(pv)
	return pc

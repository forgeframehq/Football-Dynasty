extends "res://scripts/screens/screen.gd"
# First-team squad with switchable views, a summary header and a depth chart.

const FILTERS = ["All", "GK", "DEF", "MID", "ATT"]
const VIEWS = ["Overview", "Stats", "Contract", "Fitness", "Growth"]
const POS_ORDER = ["GK", "CB", "LB", "RB", "CDM", "CM", "CAM", "LM", "RM", "LW", "RW", "ST"]
const SORTS = [["Position", "Rating", "Number"], ["Goals", "Assists", "Rating", "Apps"], ["Wage", "Expiry", "Value"], ["Fitness", "Morale"], ["Potential", "Age", "Room"]]


func _init():
	show_nav = true


func build():
	var c = G.uc()
	var st = G.ui
	var s = G.s
	var tab = st.get("sq_tab", 0)
	var tabs = UI.seg(["First team", "Youth", "On loan"], tab, func(i):
		st["sq_tab"] = i
		refresh(), 20)
	body.add_child(UI.topbar("Squad", false, UI.chip("%d PLAYERS" % c.players.size(), Color(1, 1, 1, 0.06), UI.MUTED, 20)))
	var all = []
	var loaned = []
	for pid in c.players:
		all.append(s.players[pid])
	for pid in s.players:
		var lp = s.players[pid]
		if lp.get("loan", -1) == c.id and lp.club != c.id:
			loaned.append(lp)
	var first = all.filter(func(p): return not p.get("youth", false))
	var youth = all.filter(func(p): return p.get("youth", false))
	var top = UI.vb(10)
	# summary
	var age_t = 0.0
	var val = 0
	for p in first:
		age_t += G.age(p)
		val += G.value(p)
	var tr = G.team_ratings(c.id)
	var sm = UI.hb(8)
	sm.add_child(UI.stat_tile("XI rating", str(tr.ovr), UI.ovr_color(tr.ovr)))
	sm.add_child(UI.stat_tile("Avg age", "%.1f" % (age_t / max(1, first.size()))))
	sm.add_child(UI.stat_tile("Wages / wk", G.money(G.squad_wages(c))))
	sm.add_child(UI.stat_tile("Value", G.money(val)))
	top.add_child(sm)
	top.add_child(tabs)
	if tab == 0:
		top.add_child(UI.seg(FILTERS, st.sq_filter, func(i):
			st.sq_filter = i
			refresh(), 20))
		top.add_child(UI.seg(VIEWS, st.get("sq_view", 0), func(i):
			st["sq_view"] = i
			st.sq_sort = 0
			refresh(), 19))
	body.add_child(UI.margin(top, 24, 0, 24, 10))
	var v = content(8)
	if tab == 1:
		v.add_child(UI.wrap("Academy players train with the youth team and do not count towards the first-team squad. Promote them when they are ready.", 21, UI.MUTED))
		youth.sort_custom(func(a, b): return a.pot > b.pot)
		for p in youth:
			v.add_child(row(p, c, 4))
		if youth.size() == 0:
			v.add_child(UI.wrap("No academy players yet. New prospects arrive at the end of each season.", 22, UI.DIM))
		return
	if tab == 2:
		if loaned.size() == 0:
			v.add_child(UI.wrap("Nobody is out on loan. Loan a player out from his profile to get him games.", 22, UI.DIM))
		for p in loaned:
			var pid = p.id
			v.add_child(UI.player_row(p, func(): UI.main.open("player", {"pid": pid}), "at %s · %d apps · %.2f avg" % [s.clubs[p.club].name, p.ss.ap, G.avg_rating(p)]))
		return
	var view = st.get("sq_view", 0)
	var sh = UI.hb(8)
	sh.add_child(UI.caps("Sort", 20, UI.DIM))
	for i in SORTS[view].size():
		var on = st.sq_sort == i
		var ch = UI.chip(SORTS[view][i].to_upper(), Color(UI.accent, 0.16) if on else Color(1, 1, 1, 0.04), UI.accent if on else UI.MUTED, 19)
		var idx = i
		UI.tap(ch, func():
			st.sq_sort = idx
			refresh(), true)
		sh.add_child(ch)
	sh.add_child(UI.sp())
	var dc = UI.chip("DEPTH CHART", Color(1, 1, 1, 0.06), UI.TEXT, 19)
	UI.tap(dc, _depth, true)
	sh.add_child(dc)
	v.add_child(sh)
	var list = first.filter(func(p): return st.sq_filter == 0 or G.LINE[p.pos] == st.sq_filter - 1)
	var key = SORTS[view][min(st.sq_sort, SORTS[view].size() - 1)]
	var f = func(p):
		match key:
			"Position": return -(POS_ORDER.find(p.pos) * 100 - p.ovr)
			"Rating": return G.avg_rating(p) * 100.0 if view == 1 else float(p.ovr)
			"Number": return -float(p.get("num", 99))
			"Goals": return float(p.ss.g)
			"Assists": return float(p.ss.a)
			"Apps": return float(p.ss.ap)
			"Wage": return float(p.wage)
			"Expiry": return -float(p.cend)
			"Value": return float(G.value(p))
			"Fitness": return -float(p.cond)
			"Morale": return -float(p.mor)
			"Potential": return float(p.pot)
			"Age": return -float(G.age(p))
			"Room": return float(p.pot - p.ovr)
		return 0.0
	list.sort_custom(func(a, b): return f.call(a) > f.call(b))
	for p in list:
		v.add_child(row(p, c, view))


static func arrow(p: Dictionary) -> Control:
	if p.form >= 7.1:
		return UI.icon("trending-up", 24, UI.GREEN)
	if p.form < 6.2 and p.ss.ap > 2:
		return UI.icon("trending-down", 24, UI.RED)
	return UI.sp(24, 1)


static func row(p: Dictionary, c: Dictionary, view: int) -> Control:
	var r = UI.panel(UI.CARD, 18, 14, 11, UI.LINE)
	var h = UI.hb(12)
	var nl = UI.lbl(str(p.get("num", "")), 24, UI.DIM, "disp")
	nl.custom_minimum_size = Vector2(34, 0)
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_child(nl)
	h.add_child(UI.pos(p.pos))
	var v = UI.vb(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nh = UI.hb(6)
	nh.add_child(UI.lbl_fill(G.pname(p), 25, UI.TEXT, "semi"))
	if c.get("capt", -1) == p.id:
		nh.add_child(UI.chip("C", UI.GOLD, Color("0a0e17"), 16))
	v.add_child(nh)
	var mh = UI.hb(8)
	var a = G.age(p)
	match view:
		0:
			mh.add_child(UI.lbl("%d yrs" % a, 19, UI.MUTED))
			var role = "XI" if p.id in c.xi else ("SUB" if p.id in c.bench else "")
			if role != "":
				mh.add_child(UI.chip(role, Color(UI.accent, 0.14), UI.accent, 15))
			if p.inj > 0:
				mh.add_child(UI.chip("INJ " + G.inj_text(p.inj).to_upper(), Color(UI.RED, 0.14), UI.RED, 15))
			if p.susp > 0:
				mh.add_child(UI.chip("BANNED %d" % p.susp, Color(UI.RED, 0.14), UI.RED, 15))
			if p.listed:
				mh.add_child(UI.chip("LISTED", Color(UI.AMBER, 0.14), UI.AMBER, 15))
			if p.get("loan", -1) >= 0:
				mh.add_child(UI.chip("ON LOAN", Color(UI.BLUE, 0.14), UI.BLUE, 15))
			elif p.cend <= G.s.season + 1:
				mh.add_child(UI.chip("EXPIRING", Color(UI.AMBER, 0.1), UI.AMBER, 15))
			if p.get("unhappy", 0) > 0:
				mh.add_child(UI.chip("UNHAPPY", Color(UI.RED, 0.14), UI.RED, 15))
		1:
			mh.add_child(UI.lbl("%d apps · %d MOTM · %d YC · %d RC" % [p.ss.ap, p.ss.mom, p.ss.yc, p.ss.rc], 19, UI.MUTED))
		2:
			mh.add_child(UI.lbl("%s · value %s" % [G.STATUS[G.status_of(p)], G.money(G.value(p))], 19, UI.MUTED))
		3:
			mh.add_child(UI.lbl("Morale %d · form %.1f" % [p.mor, p.form], 19, UI.cond_color(p.mor + 10) if p.mor < 50 else UI.MUTED))
			if p.inj > 0:
				mh.add_child(UI.chip("INJ " + G.inj_text(p.inj).to_upper(), Color(UI.RED, 0.14), UI.RED, 15))
		_:
			var tf = p.get("tr", "")
			mh.add_child(UI.lbl("%d yrs%s" % [a, (" · training " + tf) if tf != "" else ""], 19, UI.MUTED))
	v.add_child(mh)
	h.add_child(v)
	match view:
		0:
			h.add_child(arrow(p))
		1:
			for x in [[str(p.ss.g), "G"], [str(p.ss.a), "A"], ["%.2f" % G.avg_rating(p) if p.ss.ap > 0 else "—", "AVG"]]:
				var sv = UI.vb(-4)
				var a1 = UI.lbl(x[0], 25, UI.TEXT, "disp")
				a1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				var a2 = UI.caps(x[1], 14, UI.DIM)
				a2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				sv.add_child(a1)
				sv.add_child(a2)
				sv.custom_minimum_size = Vector2(52 if x[1] != "AVG" else 66, 0)
				h.add_child(sv)
		2:
			var cv = UI.vb(-2)
			var w = UI.lbl(G.money(p.wage) + "/wk", 23, UI.TEXT, "disp")
			w.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			var e = UI.caps("until Jun %d" % p.cend, 16, UI.AMBER if p.cend <= G.s.season + 1 else UI.DIM)
			e.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			cv.add_child(w)
			cv.add_child(e)
			h.add_child(cv)
		3:
			var cv = UI.vb(4)
			cv.custom_minimum_size = Vector2(120, 0)
			cv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			var cl = UI.caps("Fit %d%%" % p.cond, 17, UI.cond_color(p.cond))
			cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			cv.add_child(cl)
			cv.add_child(UI.bar(p.cond / 100.0, UI.cond_color(p.cond), 6))
			cv.add_child(UI.bar(p.mor / 100.0, UI.cond_color(p.mor + 10), 6))
			h.add_child(cv)
		_:
			var room = p.pot - p.ovr
			if a >= 31:
				h.add_child(UI.icon("trending-down", 24, UI.RED))
			elif room >= 3 and a <= 24:
				h.add_child(UI.icon("trending-up", 24, UI.GREEN))
			h.add_child(UI.ovr(p.ovr, 22))
			h.add_child(UI.lbl("→", 22, UI.DIM))
			h.add_child(UI.ovr(p.pot, 22) if G.OPS.knows(p) else UI.chip(G.OPS.pot_text(p), Color(1, 1, 1, 0.06), UI.MUTED, 20))
	if view != 4:
		h.add_child(UI.ovr(p.ovr))
	r.add_child(h)
	var pid = p.id
	UI.tap(r, func(): UI.main.open("player", {"pid": pid}))
	return r


func _depth():
	var c = G.uc()
	var build_sheet = func(v):
		var seen = []
		for sl in G.slots_of(c):
			if sl[0] in seen:
				continue
			seen.append(sl[0])
			var cands = []
			for pid in c.players:
				var p = G.s.players[pid]
				if p.get("youth", false):
					continue
				var ft = G.fit(p, sl[0])
				if ft >= 0.9:
					cands.append([p.ovr * ft, p])
			cands.sort_custom(func(a, b): return a[0] > b[0])
			var card = UI.card(16, 12)
			var h = UI.hb(12)
			h.add_child(UI.pos(sl[0]))
			var cv = UI.vb(2)
			cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			for i in min(3, cands.size()):
				var p = cands[i][1]
				var r = UI.hb(8)
				r.add_child(UI.lbl_fill(G.pname(p), 23, UI.TEXT if i == 0 else UI.MUTED, "semi" if i == 0 else "body"))
				if not G.available(p):
					r.add_child(UI.chip("OUT", Color(UI.RED, 0.14), UI.RED, 15))
				r.add_child(UI.lbl(str(int(round(cands[i][0]))), 23, UI.ovr_color(int(cands[i][0])), "disp"))
				cv.add_child(r)
			if cands.size() < 2:
				cv.add_child(UI.caps("Thin cover here", 17, UI.AMBER))
			h.add_child(cv)
			card.add_child(h)
			v.add_child(card)
	UI.sheet("Depth chart", build_sheet)

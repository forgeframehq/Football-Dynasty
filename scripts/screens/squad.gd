extends "res://scripts/screens/screen.gd"
# First-team squad with switchable views, a summary header and a depth chart.

const FILTERS = ["All", "GK", "DEF", "MID", "ATT"]
const POS_ORDER = ["GK", "CB", "LB", "RB", "CDM", "CM", "CAM", "LM", "RM", "LW", "RW", "ST"]


const COLS = [["num", "#", 34], ["pos", "POS", 62], ["name", "PLAYER", 0], ["age", "AGE", 44], ["nat", "NAT", 44], ["ovr", "OVR", 56], ["pot", "POT", 62],
	["cond", "FIT", 72], ["mor", "MOR", 48], ["form", "FORM", 52], ["ap", "APPS", 48], ["g", "G", 34], ["a", "A", 34], ["avg", "AVG", 54],
	["wage", "WAGE", 84], ["cend", "UNTIL", 58], ["val", "VALUE", 84]]


func build():
	var c = G.uc()
	var st = G.ui
	var s = G.s
	if args.has("tab"):
		st["sq_tab"] = args.tab
		args.erase("tab")
	var tab = st.get("sq_tab", 0)
	var tabs = UI.seg(["First team", "Youth", "On loan"], tab, func(i):
		st["sq_tab"] = i
		refresh(), 18)
	tabs.custom_minimum_size = Vector2(380, 0)
	body.add_child(UI.topbar(["First Team", "Youth & Reserves", "Loan Watch"][tab], false, tabs))
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
	var list = [first, youth, loaned][tab]
	var age_t = 0.0
	var val = 0
	for p in first:
		age_t += G.age(p)
		val += G.value(p)
	var tr = G.team_ratings(c.id)
	UI.main.t_sub = "%d players · XI rating %d · average age %.1f · wages %s / wk · value %s" % [first.size(), tr.ovr, age_t / max(1, first.size()), G.money(G.squad_wages(c)), G.money(val)]
	# toolbar
	var bar = UI.hb(8)
	for i in FILTERS.size():
		var on = st.sq_filter == i
		var ch = UI.chip(FILTERS[i].to_upper(), Color(UI.accent, 0.18) if on else Color(1, 1, 1, 0.05), UI.accent if on else UI.MUTED, 18, 64)
		var idx = i
		UI.tap(ch, func():
			st.sq_filter = idx
			refresh(), true)
		bar.add_child(ch)
	bar.add_child(UI.sp())
	if tab == 1:
		bar.add_child(UI.lbl("Academy players do not count towards the first-team squad. Promote them from their profile.", 17, UI.DIM))
	if tab == 2 and loaned.is_empty():
		bar.add_child(UI.lbl("Nobody is out on loan. Loan a player out from his profile to get him games.", 17, UI.DIM))
	var dc = UI.chip("DEPTH CHART", Color(1, 1, 1, 0.07), UI.TEXT, 18)
	UI.tap(dc, _depth, true)
	bar.add_child(dc)
	body.add_child(UI.margin(bar, 20, 0, 20, 8))
	# table
	var wide = UI.main.size.x - 92 >= 1300
	var cols = []
	for cdef in COLS:
		if not wide and cdef[0] in ["ap", "cend", "nat", "form"]:
			continue
		cols.append(cdef)
	var key = st.get("sq_col", "pos")
	var desc = st.get("sq_desc", true)
	var head = UI.hb(10)
	for cdef in cols:
		var on = key == cdef[0]
		var l = UI.caps(cdef[1] + (" ▾" if on and desc else (" ▴" if on else "")), 16, UI.accent if on else UI.DIM)
		if cdef[2] > 0:
			l.custom_minimum_size = Vector2(cdef[2], 30)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		else:
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			l.custom_minimum_size = Vector2(0, 30)
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var k = cdef[0]
		UI.tap(l, func():
			if st.get("sq_col", "pos") == k:
				st["sq_desc"] = not st.get("sq_desc", true)
			else:
				st["sq_col"] = k
				st["sq_desc"] = true
			refresh(), true)
		head.add_child(l)
	body.add_child(UI.margin(head, 32, 0, 32, 2))
	list = list.filter(func(p): return st.sq_filter == 0 or G.LINE[p.pos] == st.sq_filter - 1)
	var f = func(p):
		match key:
			"pos": return -(POS_ORDER.find(p.pos) * 100 - p.ovr)
			"num": return -float(p.get("num", 99))
			"name": return -float(G.pname(p).unicode_at(G.pname(p).find(" ") + 1 if G.pname(p).contains(". ") else 0))
			"age": return float(G.age(p))
			"nat": return -float(p.nat.unicode_at(0))
			"ovr": return float(p.ovr)
			"pot": return float(p.pot) if G.OPS.knows(p) else float(p.ovr)
			"cond": return float(p.cond)
			"mor": return float(p.mor)
			"form": return float(p.form)
			"ap": return float(p.ss.ap)
			"g": return float(p.ss.g)
			"a": return float(p.ss.a)
			"avg": return G.avg_rating(p)
			"wage": return float(p.wage)
			"cend": return float(p.cend)
			"val": return float(G.value(p))
		return 0.0
	list.sort_custom(func(a, b): return f.call(a) > f.call(b) if desc else f.call(a) < f.call(b))
	cols_n = cols
	var v = UI.vb(3)
	sc = UI.scroll(UI.margin(v, 20, 0, 20, 14))
	body.add_child(sc)
	for p in list:
		v.add_child(trow(p, c, cols, tab == 2))
	if list.is_empty():
		v.add_child(UI.wrap("No players here.", 21, UI.DIM))


var cols_n: Array = []


func _cell(text: String, w: int, col := UI.TEXT, font := "disp", size := 21) -> Label:
	var l = UI.lbl(text, size, col, font)
	l.custom_minimum_size = Vector2(w, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func trow(p: Dictionary, c: Dictionary, cols: Array, loan: bool) -> Control:
	var in_xi = p.id in c.xi
	var r = UI.panel(UI.CARD, 10, 12, 5, Color(UI.accent, 0.35) if in_xi else UI.LINE)
	var h = UI.hb(10)
	for cdef in cols:
		var w = cdef[2]
		match cdef[0]:
			"num": h.add_child(_cell(str(p.get("num", "")), w, UI.DIM))
			"pos":
				var pc = UI.pos(p.pos, 18)
				pc.custom_minimum_size = Vector2(w, 0)
				h.add_child(pc)
			"name":
				var nh = UI.hb(6)
				nh.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				var nl = UI.lbl(G.pname(p), 23, UI.TEXT, "semi")
				nh.add_child(nl)
				if c.get("capt", -1) == p.id:
					nh.add_child(UI.chip("C", UI.GOLD, Color("0a0e17"), 14))
				if in_xi:
					nh.add_child(UI.chip("XI", Color(UI.accent, 0.16), UI.accent, 14))
				elif p.id in c.bench:
					nh.add_child(UI.chip("SUB", Color(1, 1, 1, 0.07), UI.MUTED, 14))
				if p.inj > 0:
					nh.add_child(UI.chip("INJ " + G.inj_text(p.inj).to_upper(), Color(UI.RED, 0.14), UI.RED, 14))
				if p.susp > 0:
					nh.add_child(UI.chip("BAN %d" % p.susp, Color(UI.RED, 0.14), UI.RED, 14))
				if p.listed:
					nh.add_child(UI.chip("LISTED", Color(UI.AMBER, 0.14), UI.AMBER, 14))
				if p.get("unhappy", 0) > 0:
					nh.add_child(UI.chip("UNHAPPY", Color(UI.RED, 0.14), UI.RED, 14))
				if loan:
					nh.add_child(UI.lbl("at " + G.s.clubs[p.club].name, 17, UI.MUTED))
				elif p.get("loan", -1) >= 0:
					nh.add_child(UI.chip("LOAN", Color(UI.BLUE, 0.14), UI.BLUE, 14))
				h.add_child(nh)
			"age": h.add_child(_cell(str(G.age(p)), w, UI.MUTED))
			"nat":
				var fc = UI.center(UI.flag(p.nat, 30))
				fc.custom_minimum_size = Vector2(w, 0)
				h.add_child(fc)
			"ovr":
				var oc = UI.ovr(p.ovr, 21)
				oc.custom_minimum_size = Vector2(w, 0)
				h.add_child(oc)
			"pot":
				if G.OPS.knows(p):
					h.add_child(_cell(str(p.pot), w, UI.ovr_color(p.pot) if p.pot > p.ovr else UI.DIM))
				else:
					h.add_child(_cell(G.OPS.pot_text(p), w, UI.MUTED, "cond", 16))
			"cond":
				var cv = UI.vb(1)
				cv.custom_minimum_size = Vector2(w, 0)
				cv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				var cl = UI.lbl("%d%%" % int(p.cond), 17, UI.cond_color(p.cond), "disp")
				cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				cv.add_child(cl)
				cv.add_child(UI.bar(p.cond / 100.0, UI.cond_color(p.cond), 4))
				h.add_child(cv)
			"mor": h.add_child(_cell(str(int(p.mor)), w, UI.cond_color(p.mor + 10)))
			"form": h.add_child(_cell("%.1f" % p.form if p.ss.ap > 0 else "-", w, UI.GREEN if p.form >= 7.1 else (UI.RED if p.form < 6.2 and p.ss.ap > 2 else UI.MUTED)))
			"ap": h.add_child(_cell(str(p.ss.ap), w, UI.MUTED))
			"g": h.add_child(_cell(str(p.ss.g), w, UI.TEXT if p.ss.g > 0 else UI.DIM))
			"a": h.add_child(_cell(str(p.ss.a), w, UI.TEXT if p.ss.a > 0 else UI.DIM))
			"avg": h.add_child(_cell("%.2f" % G.avg_rating(p) if p.ss.ap > 0 else "-", w, UI.MUTED))
			"wage": h.add_child(_cell(G.money(p.wage), w, UI.MUTED))
			"cend": h.add_child(_cell(str(p.cend), w, UI.AMBER if p.cend <= G.s.season + 1 else UI.DIM))
			"val": h.add_child(_cell(G.money(G.value(p)), w, UI.TEXT))
	r.add_child(h)
	var pid = p.id
	UI.tap(r, func(): UI.main.open("player", {"pid": pid}))
	return r


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

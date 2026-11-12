extends "res://scripts/screens/screen.gd"
# New career flow: manager name, league, club.

var step := 0
var mname := "Manager"
var lg := -1
var info: Array = []   # per club: {rep, budget, n}


func _load_info():
	if info.size() > 0:
		return
	var raw = DB.load_db()
	var ov = []
	for c in raw.clubs:
		ov.append([])
	for r in raw.players:
		ov[int(r[4])].append(int(r[11]))
	for i in raw.clubs.size():
		var a = ov[i]
		a.sort()
		a.reverse()
		var n = min(16, a.size())
		var t = 0.0
		for k in n:
			t += a[k]
		var rep = t / max(1, n)
		info.append({"rep": rep, "budget": G.nice(900000.0 * pow(1.2, rep - 60.0)), "n": a.size()})


func can_leave() -> bool:
	if step == 1:
		step = 0
		refresh()
		return false
	return true


func build():
	_load_info()
	var raw = DB.raw
	if step == 0:
		body.add_child(UI.topbar("New career"))
		var v = content(12)
		v.add_child(UI.caps("Manager name", 22))
		v.add_child(UI.input(mname, "Your name", func(t): mname = t))
		v.add_child(UI.sp(0, 10))
		v.add_child(UI.caps("Choose a league", 22))
		var country = ""
		for i in raw.leagues.size():
			var l = raw.leagues[i]
			if l.country != country:
				country = l.country
				v.add_child(UI.sp(0, 4))
				v.add_child(UI.lbl(country.to_upper(), 30, UI.GOLD, "xbold"))
			var n = 0
			var best = 0.0
			for ci in raw.clubs.size():
				if int(raw.clubs[ci].lg) == i:
					n += 1
					best = max(best, info[ci].rep)
			var row = UI.panel(UI.CARD, 20, 20, 16, UI.LINE)
			var h = UI.hb(14)
			h.add_child(UI.chip("T%d" % int(l.tier), Color(UI.GOLD, 0.14), UI.GOLD, 22, 52))
			var cv = UI.vb(0)
			cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cv.add_child(UI.lbl_fill(l.name, 30, UI.TEXT, "disp"))
			cv.add_child(UI.lbl_fill("%d clubs" % n, 20, UI.MUTED))
			h.add_child(cv)
			h.add_child(UI.stars(best - 3.0))
			h.add_child(UI.icon("chevron-right", 28, UI.DIM))
			row.add_child(h)
			var idx = i
			UI.tap(row, func():
				lg = idx
				step = 1
				refresh())
			v.add_child(row)
	else:
		var l = raw.leagues[lg]
		body.add_child(UI.topbar(l.name))
		var v = content(10)
		v.add_child(UI.lbl("Pick your club. Bigger clubs bring bigger budgets — and bigger expectations.", 22, UI.MUTED))
		v.get_child(0).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var ids = []
		for ci in raw.clubs.size():
			if int(raw.clubs[ci].lg) == lg:
				ids.append(ci)
		ids.sort_custom(func(a, b): return info[a].rep > info[b].rep)
		for ci in ids:
			var c = raw.clubs[ci]
			var row = UI.panel(UI.CARD, 20, 18, 14, UI.LINE)
			var h = UI.hb(16)
			h.add_child(UI.badge({"c1": c.c1, "c2": c.c2, "short": c.short, "id": ci}, 68))
			var cv = UI.vb(2)
			cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cv.add_child(UI.lbl_fill(c.name, 29, UI.TEXT, "disp"))
			var sub = UI.hb(10)
			sub.add_child(UI.stars(info[ci].rep, 18))
			sub.add_child(UI.lbl("Budget %s" % G.money(info[ci].budget), 20, UI.MUTED))
			cv.add_child(sub)
			h.add_child(cv)
			h.add_child(UI.ovr(int(round(info[ci].rep))))
			row.add_child(h)
			var idx = ci
			UI.tap(row, func(): _confirm(idx))
			v.add_child(row)


func _confirm(ci: int):
	var c = DB.raw.clubs[ci]
	var build_sheet = func(v):
		var h = UI.hb(18)
		h.add_child(UI.badge({"c1": c.c1, "c2": c.c2, "short": c.short, "id": ci}, 96))
		var cv = UI.vb(2)
		cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cv.add_child(UI.caps(DB.raw.leagues[lg].name, 20, UI.GOLD))
		cv.add_child(UI.stars(info[ci].rep))
		if c.stadium != "":
			cv.add_child(UI.lbl_fill(c.stadium, 22, UI.MUTED))
		h.add_child(cv)
		v.add_child(h)
		var t = UI.hb(10)
		t.add_child(UI.stat_tile("Squad rating", str(int(round(info[ci].rep)))))
		t.add_child(UI.stat_tile("Budget", G.money(info[ci].budget)))
		t.add_child(UI.stat_tile("Players", str(info[ci].n)))
		v.add_child(t)
		v.add_child(UI.sp(0, 6))
		v.add_child(UI.btn("Start career", func(): _start(ci), "gold", "play"))
	UI.sheet(c.name, build_sheet)


func _start(ci: int):
	UI.close_sheet()
	var nm = mname.strip_edges()
	G.new_game(nm if nm != "" else "Manager", ci)
	UI.main.root("home")

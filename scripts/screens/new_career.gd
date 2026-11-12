extends "res://scripts/screens/screen.gd"
# New career flow: manager name, league, club.

var step := -1
var mname := "Manager"
var prof: Dictionary = {}
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
	if step >= 0:
		step -= 1
		refresh()
		return false
	return true


func _left() -> int:
	var used = 0
	for k in prof.attr:
		used += prof.attr[k] - 5
	return G.OPS.points_for(prof.badge, prof.bg) - used


func _profile():
	body.add_child(UI.topbar("Your manager"))
	var v = content(12)
	v.add_child(UI.caps("Name", 21))
	v.add_child(UI.input(mname, "Your name", func(t): mname = t))
	var nr = UI.panel(UI.CARD2, 18, 18, 16, Color(1, 1, 1, 0.1))
	var nh = UI.hb(8)
	nh.add_child(UI.caps("Nationality", 20, UI.MUTED))
	nh.add_child(UI.sp())
	nh.add_child(UI.lbl(prof.nat, 28, UI.TEXT, "disp"))
	nh.add_child(UI.icon("chevron-right", 22, UI.MUTED))
	nr.add_child(nh)
	UI.tap(nr, _pick_nat, true)
	v.add_child(nr)
	v.add_child(UI.section("Coaching badge", G.OPS.BADGES[prof.badge]))
	v.add_child(UI.seg(["Nat C", "Nat B", "UEFA B", "UEFA A", "Pro"], prof.badge, func(i):
		prof.badge = i
		_clamp()
		refresh(), 20))
	v.add_child(UI.section("Playing career", G.OPS.BACKGROUNDS[prof.bg]))
	v.add_child(UI.seg(["Sunday", "Semi-pro", "Pro", "Int'l"], prof.bg, func(i):
		prof.bg = i
		_clamp()
		refresh(), 20))
	v.add_child(UI.wrap("Higher badges and a bigger playing career mean more reputation and attribute points — and an easier start. Pick a low badge for a real challenge: boards at big clubs will have little patience.", 20, UI.MUTED))
	var left = _left()
	v.add_child(UI.section("Coaching attributes", "%d point%s left" % [left, "" if left == 1 else "s"]))
	var ac = UI.card()
	var av = UI.vb(12)
	for m in G.OPS.MATTR:
		var r = UI.hb(10)
		var tv = UI.vb(0)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UI.lbl(m[1], 24, UI.TEXT, "semi"))
		tv.add_child(UI.wrap(m[2], 18, UI.DIM))
		r.add_child(tv)
		var key = m[0]
		var minus = UI.panel(Color(1, 1, 1, 0.07), 14, 12, 10)
		minus.add_child(UI.icon("minus", 24, UI.TEXT))
		UI.tap(minus, func():
			if prof.attr[key] > 5:
				prof.attr[key] -= 1
				refresh(), true)
		r.add_child(minus)
		var val = UI.lbl(str(prof.attr[key]), 34, UI.ovr_color(50 + prof.attr[key] * 2), "xbold")
		val.custom_minimum_size = Vector2(48, 0)
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		r.add_child(val)
		var plus = UI.panel(UI.GOLD if left > 0 else Color(1, 1, 1, 0.07), 14, 12, 10)
		plus.add_child(UI.icon("plus", 24, Color("0a0e17") if left > 0 else UI.DIM))
		UI.tap(plus, func():
			if _left() > 0 and prof.attr[key] < 20:
				prof.attr[key] += 1
				refresh(), true)
		r.add_child(plus)
		av.add_child(r)
	ac.add_child(av)
	v.add_child(ac)
	v.add_child(UI.btn("Choose a club", func():
		step = 0
		refresh(), "gold", "chevron-right"))


func _clamp():
	while _left() < 0:
		for k in prof.attr:
			if prof.attr[k] > 5 and _left() < 0:
				prof.attr[k] -= 1


func _pick_nat():
	var build_sheet = func(v):
		var nats = DB.names.keys()
		nats.sort()
		for n in nats:
			var r = UI.panel(UI.CARD, 14, 18, 10, UI.GOLD if n == prof.nat else UI.LINE)
			r.add_child(UI.lbl(n, 24, UI.TEXT, "semi"))
			var nm = n
			UI.tap(r, func():
				prof.nat = nm
				UI.close_sheet()
				refresh())
			v.add_child(r)
	UI.sheet("Nationality", build_sheet)


func build():
	_load_info()
	var raw = DB.raw
	if prof.is_empty():
		prof = G.OPS.default_profile()
		prof.attr = {"tac": 5, "mot": 5, "you": 5, "neg": 5}
		var pts = _left()
		for i in pts:
			prof.attr[["tac", "mot", "you", "neg"][i % 4]] += 1
	if step < 0:
		_profile()
		return
	if step == 0:
		body.add_child(UI.topbar("Choose a league"))
		var v = content(12)
		var country = ""
		for i in raw.leagues.size():
			var l = raw.leagues[i]
			if l.get("roe", false):
				continue
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
	prof.name = nm if nm != "" else "Manager"
	G.new_game(prof, ci)
	UI.main.root("home")

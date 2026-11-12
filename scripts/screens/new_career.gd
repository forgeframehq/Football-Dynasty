extends "res://scripts/screens/screen.gd"
# New career: Nation > League > Club picker with a club panel, then the manager profile.

const NATIONS = ["England", "Spain", "Italy", "Germany", "France"]
const STYLES = [["Balanced", [.25, .25, .25, .25], "A bit of everything."], ["Tactician", [.46, .18, .18, .18], "Your teams control matches."],
	["Motivator", [.18, .46, .18, .18], "Stronger team talks and morale."], ["Developer", [.18, .18, .46, .18], "Young players improve faster."],
	["Negotiator", [.18, .18, .18, .46], "Cheaper fees and wages."]]
const NAT_LIST = ["England", "Spain", "Italy", "Germany", "France", "Scotland", "Wales", "Northern Ireland", "Republic of Ireland", "Portugal", "Holland", "Belgium",
	"Brazil", "Argentina", "United States", "Canada", "Mexico", "Denmark", "Norway", "Sweden", "Switzerland", "Austria", "Poland", "Croatia", "Serbia",
	"Turkey", "Greece", "Morocco", "Nigeria", "Ghana", "Senegal", "Japan", "Australia", "Jamaica", "Uruguay", "Colombia"]

var step := 0
var fn := ""
var ln := ""
var age := 38
var style := 0
var prof: Dictionary = {}
var nat := ""
var lg := -1
var pick := -1
var raw: Dictionary = {}
var info: Array = []   # per club: rep, budget, n, star, att, mid, def, rank, of


func _load_info():
	if info.size() > 0:
		return
	raw = DB.load_db()
	var by = []
	for c in raw.clubs:
		by.append([])
	for r in raw.players:
		by[int(r[4])].append(r)
	for i in raw.clubs.size():
		var a = by[i]
		a.sort_custom(func(x, y): return x[11] > y[11])
		var n = min(16, a.size())
		var t = 0.0
		for k in n:
			t += a[k][11]
		var rep = t / max(1, n)
		var lines = [[], [], [], []]
		for r in a:
			lines[G.LINE.get(r[5], 2)].append(float(r[11]))
		var avg = func(arr, cnt):
			var m = min(cnt, arr.size())
			var tt = 0.0
			for k in m:
				tt += arr[k]
			return int(round(tt / max(1, m)))
		var star = a[0] if a.size() > 0 else null
		var sname_ = ""
		if star != null:
			sname_ = star[3] if str(star[3]) != "" else "%s. %s" % [str(star[1]).substr(0, 1), star[2]]
		info.append({"rep": rep, "budget": G.nice(900000.0 * pow(1.2, rep - 60.0)), "n": a.size(), "star": sname_, "star_ovr": int(star[11]) if star != null else 0,
			"star_pos": star[5] if star != null else "", "att": avg.call(lines[3], 3), "mid": avg.call(lines[2], 4), "def": avg.call(lines[1] + lines[0], 5), "rank": 0, "of": 0})
	for li in raw.leagues.size():
		var ids = []
		for i in raw.clubs.size():
			if int(raw.clubs[i].lg) == li:
				ids.append(i)
		ids.sort_custom(func(x, y): return info[x].rep > info[y].rep)
		for k in ids.size():
			info[ids[k]].rank = k + 1
			info[ids[k]].of = ids.size()


func can_leave() -> bool:
	if step == 1:
		step = 0
	elif pick >= 0:
		pick = -1
	elif lg >= 0:
		lg = -1
	elif nat != "":
		nat = ""
	else:
		return true
	refresh()
	return false


func dev_step() -> bool:
	if nat == "":
		nat = "England"
	elif lg < 0:
		lg = 0
	elif pick < 0:
		pick = 1
	elif step == 0:
		step = 1
	else:
		return false
	refresh()
	return true


func build():
	chrome = false
	_load_info()
	if prof.is_empty():
		prof = G.OPS.default_profile()
		_apply_style()
	if step == 1:
		_manager()
	else:
		_picker()


func _header(title: String, crumbs: Array, right: Control = null):
	var h = UI.hb(12)
	var b = UI.panel(Color(1, 1, 1, 0.07), 14, 12, 10)
	b.add_child(UI.icon("chevron-left", 30, UI.TEXT))
	UI.tap(b, func(): UI.main.back(), true)
	h.add_child(b)
	h.add_child(UI.lbl(title.to_upper(), 34, UI.TEXT, "xbold"))
	h.add_child(UI.sp(10, 0))
	for i in crumbs.size():
		if i > 0:
			h.add_child(UI.icon("chevron-right", 18, UI.DIM))
		var cr = crumbs[i]
		var on = i == crumbs.size() - 1
		var cp = UI.chip(str(cr[0]).to_upper(), Color(UI.GOLD, 0.18) if on else Color(1, 1, 1, 0.06), UI.GOLD if on else UI.MUTED, 18)
		var cb = cr[1]
		UI.tap(cp, cb, true)
		h.add_child(cp)
	h.add_child(UI.sp())
	if right != null:
		h.add_child(right)
	body.add_child(UI.margin(h, 24, 14, 24, 10))


func _picker():
	var crumbs = [["Nations", func():
		nat = ""
		lg = -1
		pick = -1
		refresh()]]
	if nat != "":
		crumbs.append([nat, func():
			lg = -1
			pick = -1
			refresh()])
	if lg >= 0:
		crumbs.append([raw.leagues[lg].name, func():
			pick = -1
			refresh()])
	var rnd = UI.btn("Random team", func():
		var ids = []
		for i in raw.clubs.size():
			var l = raw.leagues[int(raw.clubs[i].lg)]
			if not l.get("roe", false) and (nat == "" or l.country == nat) and (lg < 0 or int(raw.clubs[i].lg) == lg):
				ids.append(i)
		pick = ids[randi() % ids.size()]
		lg = int(raw.clubs[pick].lg)
		nat = raw.leagues[lg].country
		refresh(), "secondary", "shuffle", 48)
	_header("Pick a team", crumbs, rnd)
	var h = panes(16, 24)
	var grid = HFlowContainer.new()
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gs = UI.scroll(grid)
	h.add_child(gs)
	if nat == "":
		for n in NATIONS:
			var cnt = 0
			var clubs = 0
			for li in raw.leagues.size():
				if raw.leagues[li].country == n and not raw.leagues[li].get("roe", false):
					cnt += 1
					for c in raw.clubs:
						if int(c.lg) == li:
							clubs += 1
			var t = _tile(260, 190)
			var tv = t.get_child(0)
			tv.add_child(UI.center(UI.flag(n, 120)))
			var l = UI.lbl(n.to_upper(), 30, UI.TEXT, "xbold")
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			tv.add_child(l)
			var sl = UI.caps("%d divisions · %d clubs" % [cnt, clubs], 16, UI.MUTED)
			sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			tv.add_child(sl)
			var nn = n
			UI.tap(t, func():
				nat = nn
				refresh())
			grid.add_child(t)
	elif lg < 0:
		for li in raw.leagues.size():
			var l = raw.leagues[li]
			if l.country != nat or l.get("roe", false):
				continue
			var best = 0.0
			var cnt = 0
			for i in raw.clubs.size():
				if int(raw.clubs[i].lg) == li:
					cnt += 1
					best += info[i].rep
			var t = _tile(300, 170)
			var tv = t.get_child(0)
			tv.add_child(UI.caps("Tier %d" % int(l.tier), 18, UI.GOLD))
			tv.add_child(UI.wrap(l.name.to_upper(), 30, UI.TEXT, "xbold"))
			tv.add_child(UI.sp())
			tv.add_child(UI.kv("Clubs", str(cnt)))
			tv.add_child(UI.kv("Average rating", str(int(round(best / max(1, cnt))))))
			var idx = li
			UI.tap(t, func():
				lg = idx
				refresh())
			grid.add_child(t)
	else:
		var ids = []
		for i in raw.clubs.size():
			if int(raw.clubs[i].lg) == lg:
				ids.append(i)
		ids.sort_custom(func(a, b): return info[a].rep > info[b].rep)
		for ci in ids:
			var c = raw.clubs[ci]
			var on = ci == pick
			var t = _tile(176, 138, on)
			var tv = t.get_child(0)
			tv.add_child(UI.center(UI.badge({"c1": c.c1, "c2": c.c2, "short": c.short, "id": ci}, 62)))
			var l = UI.lbl(c.name, 19, UI.TEXT, "semi")
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.clip_text = true
			l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			tv.add_child(l)
			var st = UI.stars(info[ci].rep, 14)
			st.alignment = BoxContainer.ALIGNMENT_CENTER
			tv.add_child(st)
			var idx = ci
			UI.tap(t, func():
				pick = idx
				refresh())
			grid.add_child(t)
	h.add_child(_club_panel())


func _tile(w: float, hgt: float, on := false) -> PanelContainer:
	var t = UI.panel(Color(UI.GOLD, 0.14) if on else UI.CARD, 18, 14, 12, UI.GOLD if on else UI.LINE)
	t.custom_minimum_size = Vector2(w, hgt)
	var tv = UI.vb(6)
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	t.add_child(tv)
	return t


func _club_panel() -> Control:
	var p = UI.panel(UI.CARD, 20, 18, 16, Color(UI.GOLD, 0.45) if pick >= 0 else UI.LINE)
	p.custom_minimum_size = Vector2(400, 0)
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var v = UI.vb(8)
	p.add_child(UI.scroll(v))
	if pick < 0:
		v.add_child(UI.sp(0, 40))
		v.add_child(UI.center(UI.icon("shield", 80, UI.DIM)))
		var l = UI.wrap("Pick a nation, a league and a club. Club details appear here.", 21, UI.MUTED)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
		return p
	var c = raw.clubs[pick]
	var inf = info[pick]
	var l = raw.leagues[int(c.lg)]
	var head = UI.hb(14)
	head.add_child(UI.badge({"c1": c.c1, "c2": c.c2, "short": c.short, "id": pick}, 84))
	var hv = UI.vb(-2)
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hv.add_child(UI.wrap(c.name.to_upper(), 30, UI.TEXT, "xbold"))
	hv.add_child(UI.lbl_fill("%s · %s" % [l.name, c.stadium if str(c.stadium) != "" else l.country], 17, UI.MUTED))
	hv.add_child(UI.stars(inf.rep, 18))
	head.add_child(hv)
	v.add_child(head)
	var tiles = UI.hb(8)
	tiles.add_child(UI.stat_tile("Attack", str(inf.att), UI.ovr_color(inf.att)))
	tiles.add_child(UI.stat_tile("Midfield", str(inf.mid), UI.ovr_color(inf.mid)))
	tiles.add_child(UI.stat_tile("Defence", str(inf.def), UI.ovr_color(inf.def)))
	v.add_child(tiles)
	var ord = func(n): return "%d%s" % [n, "th" if (n % 100 >= 11 and n % 100 <= 13) else ["th", "st", "nd", "rd", "th", "th", "th", "th", "th", "th"][n % 10]]
	v.add_child(UI.kv("Transfer budget", "about " + G.money(inf.budget), UI.GREEN))
	v.add_child(UI.kv("Predicted finish", "%s of %d" % [ord.call(inf.rank), inf.of]))
	v.add_child(UI.kv("Star player", "%s (%s, %d)" % [inf.star, inf.star_pos, inf.star_ovr]))
	v.add_child(UI.kv("Squad size", str(inf.n)))
	var frac = float(inf.rank - 1) / max(1.0, inf.of - 1.0)
	var diff = "Expected to win" if frac < 0.12 else ("Comfortable" if frac < 0.4 else ("Challenging" if frac < 0.75 else "Hard"))
	if int(l.tier) > 1 and frac < 0.3:
		diff = "Promotion expected"
	v.add_child(UI.kv("Board pressure", diff, UI.RED if frac < 0.12 else (UI.AMBER if frac >= 0.75 else UI.TEXT)))
	v.add_child(UI.sp(0, 6))
	v.add_child(UI.btn("Manage %s" % c.short, func():
		step = 1
		refresh(), "gold", "chevron-right", 62))
	return p


# ---------------------------------------------------------------- manager profile

func _left() -> int:
	var used = 0
	for k in prof.attr:
		used += prof.attr[k] - 5
	return G.OPS.points_for(prof.badge, prof.bg) - used


func _apply_style():
	var pts = G.OPS.points_for(prof.badge, prof.bg)
	var keys = ["tac", "mot", "you", "neg"]
	var w = STYLES[style][1]
	var used = 0
	for i in 4:
		prof.attr[keys[i]] = clampi(5 + int(pts * w[i]), 5, 20)
		used += prof.attr[keys[i]] - 5
	var i2 = 0
	while used < pts and i2 < 40:
		var k = keys[(i2 + max(0, style - 1)) % 4]
		if prof.attr[k] < 20:
			prof.attr[k] += 1
			used += 1
		i2 += 1


func _manager():
	var c = raw.clubs[pick]
	_header("Your manager", [[c.name, func():
		step = 0
		refresh()]])
	var h = panes(16, 24)
	# identity
	var a = pane(380, 10)
	h.add_child(a[0])
	var v = a[1]
	v.add_child(UI.caps("Identity", 20, UI.GOLD))
	var f1 = UI.input(fn, "First name", func(t): fn = t)
	f1.custom_minimum_size = Vector2(0, 58)
	v.add_child(f1)
	var f2 = UI.input(ln, "Last name", func(t): ln = t)
	f2.custom_minimum_size = Vector2(0, 58)
	v.add_child(f2)
	var nr = UI.panel(Color(1, 1, 1, 0.05), 14, 14, 10, Color(1, 1, 1, 0.1))
	var nh = UI.hb(12)
	nh.add_child(UI.flag(prof.nat, 44))
	nh.add_child(UI.lbl_fill(prof.nat, 23, UI.TEXT, "semi"))
	nh.add_child(UI.caps("Nationality", 16, UI.DIM))
	nh.add_child(UI.icon("chevron-right", 20, UI.DIM))
	nr.add_child(nh)
	UI.tap(nr, _pick_nat, true)
	v.add_child(nr)
	var ar = UI.hb(10)
	ar.add_child(UI.lbl_fill("Age", 22, UI.MUTED))
	ar.add_child(_step_btn("minus", func():
		age = max(25, age - 1)
		refresh()))
	var al = UI.lbl(str(age), 28, UI.TEXT, "disp")
	al.custom_minimum_size = Vector2(46, 0)
	al.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ar.add_child(al)
	ar.add_child(_step_btn("plus", func():
		age = min(75, age + 1)
		refresh()))
	v.add_child(ar)
	v.add_child(UI.sp(0, 4))
	v.add_child(UI.caps("Coaching badge", 18, UI.MUTED))
	v.add_child(UI.seg(["Nat C", "Nat B", "UEFA B", "UEFA A", "Pro"], prof.badge, func(i):
		prof.badge = i
		_apply_style()
		refresh(), 17))
	v.add_child(UI.caps("Playing career", 18, UI.MUTED))
	v.add_child(UI.seg(["Sunday", "Semi-pro", "Pro", "Int'l"], prof.bg, func(i):
		prof.bg = i
		_apply_style()
		refresh(), 17))
	# coaching style
	var b = pane(0, 8)
	h.add_child(b[0])
	v = b[1]
	var left = _left()
	var sh = UI.hb(8)
	sh.add_child(UI.caps("Coaching style", 20, UI.GOLD))
	sh.add_child(UI.sp())
	sh.add_child(UI.caps("%d point%s left" % [left, "" if left == 1 else "s"], 17, UI.GREEN if left > 0 else UI.DIM))
	v.add_child(sh)
	var names = []
	for st in STYLES:
		names.append(st[0])
	v.add_child(UI.seg(names, style, func(i):
		style = i
		_apply_style()
		refresh(), 17))
	v.add_child(UI.lbl(STYLES[style][2] + " Adjust the points if you like.", 17, UI.MUTED))
	for m in G.OPS.MATTR:
		var k = m[0]
		var r = UI.panel(Color(1, 1, 1, 0.04), 12, 12, 6)
		var rh = UI.hb(10)
		var tv = UI.vb(-3)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UI.lbl(m[1], 22, UI.TEXT, "semi"))
		tv.add_child(UI.lbl_fill(m[2], 15, UI.MUTED))
		rh.add_child(tv)
		rh.add_child(_step_btn("minus", func():
			if prof.attr[k] > 5:
				prof.attr[k] -= 1
				refresh()))
		var vl = UI.lbl(str(prof.attr[k]), 30, UI.ovr_color(55 + prof.attr[k] * 2), "disp")
		vl.custom_minimum_size = Vector2(44, 0)
		vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rh.add_child(vl)
		rh.add_child(_step_btn("plus", func():
			if prof.attr[k] < 20 and _left() > 0:
				prof.attr[k] += 1
				refresh()))
		r.add_child(rh)
		v.add_child(r)
	# summary
	var sp = UI.panel(UI.CARD, 20, 18, 16, Color(UI.GOLD, 0.45))
	sp.custom_minimum_size = Vector2(340, 0)
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var sv = UI.vb(8)
	sp.add_child(sv)
	h.add_child(sp)
	var rep = 22.0 + prof.badge * 11.0 + prof.bg * 5.0
	var full = ("%s %s" % [fn, ln]).strip_edges()
	sv.add_child(UI.center(UI.badge({"c1": c.c1, "c2": c.c2, "short": c.short, "id": pick}, 78)))
	var nl = UI.lbl((full if full != "" else "Manager").to_upper(), 30, UI.TEXT, "xbold")
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nl.clip_text = true
	sv.add_child(nl)
	var fh = UI.hb(8)
	fh.alignment = BoxContainer.ALIGNMENT_CENTER
	fh.add_child(UI.flag(prof.nat, 34))
	fh.add_child(UI.lbl("%s · %d" % [prof.nat, age], 19, UI.MUTED))
	sv.add_child(fh)
	sv.add_child(UI.divider())
	sv.add_child(UI.kv("Club", c.name))
	sv.add_child(UI.kv("Licence", G.OPS.BADGES[prof.badge]))
	sv.add_child(UI.kv("Playing career", G.OPS.BACKGROUNDS[prof.bg]))
	sv.add_child(UI.kv("Reputation", "%d / 100" % int(rep)))
	sv.add_child(UI.kv("Style", STYLES[style][0]))
	sv.add_child(UI.sp())
	sv.add_child(UI.btn("Start career", _start, "gold", "play", 66))


func _step_btn(icon_name: String, cb: Callable) -> Control:
	var b = UI.panel(Color(1, 1, 1, 0.08), 12, 12, 8)
	b.add_child(UI.icon(icon_name, 24, UI.TEXT))
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UI.tap(b, cb, true)
	return b


func _pick_nat():
	var build_sheet = func(v):
		for n in NAT_LIST:
			var r = UI.panel(Color(UI.GOLD, 0.14) if n == prof.nat else UI.CARD, 12, 14, 8, UI.GOLD if n == prof.nat else UI.LINE)
			var h = UI.hb(12)
			h.add_child(UI.flag(n, 40))
			h.add_child(UI.lbl_fill(n, 22, UI.TEXT, "semi"))
			r.add_child(h)
			var nn = n
			UI.tap(r, func():
				prof.nat = nn
				UI.close_sheet()
				refresh())
			v.add_child(r)
	UI.sheet("Nationality", build_sheet)


func _start():
	var parts = []
	for w in [fn, ln]:
		w = w.strip_edges()
		if w != "" and not (w.to_lower() in parts.map(func(x): return x.to_lower())):
			parts.append(w.substr(0, 1).to_upper() + w.substr(1))
	prof.name = " ".join(parts) if parts.size() > 0 else "Manager"
	G.slot = args.get("slot", 0)
	G.new_game(prof, pick)
	G.s.user["age"] = age
	G.s.user["style"] = STYLES[style][0]
	UI.main.root("intro", {"kind": "appoint"})

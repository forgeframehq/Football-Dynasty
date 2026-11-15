extends "res://scripts/screens/screen.gd"
const FED = preload("res://scripts/face_editor.gd")
# New career: Nation > League > Club picker with a club panel, then the manager profile.

const NATIONS = ["England", "Spain", "Italy", "Germany", "France"]
# each style has a perk the points cannot buy; Balanced has none but gets BAL_BONUS extra points
const STYLES = [["Balanced", [.25, .25, .25, .25], "Perk: 4 extra points to spend."], ["Tactician", [.46, .18, .18, .18], "Perk: players learn your playstyle 50% faster, and your side gets a small edge in every match."],
	["Motivator", [.18, .46, .18, .18], "Perk: team talks land more often and harder, and squad morale never drops below 45."], ["Developer", [.18, .18, .46, .18], "Perk: an extra academy prospect every season, and players 21 and under grow 8% faster."],
	["Negotiator", [.18, .18, .18, .46], "Perk: transfer fees and wage demands 5% lower on top of your points."]]
const BAL_BONUS = 4
const NAT_LIST = ["England", "Spain", "Italy", "Germany", "France", "Scotland", "Wales", "Northern Ireland", "Republic of Ireland", "Portugal", "Holland", "Belgium",
	"Brazil", "Argentina", "United States", "Canada", "Mexico", "Denmark", "Norway", "Sweden", "Switzerland", "Austria", "Poland", "Croatia", "Serbia",
	"Turkey", "Greece", "Morocco", "Nigeria", "Ghana", "Senegal", "Japan", "Australia", "Jamaica", "Uruguay", "Colombia"]

var step := 0
var fn := ""
var ln := ""
var sh := ""
var age := 38
var style := 0
var prof: Dictionary = {}
var nat := ""
var lg := -1
var pick := -1
var raw: Dictionary = {}
var info: Array = []   # per club: rep, budget, n, star, att, mid, def, rank, of
# the wider world (G.WD.CAT): continent tab, the world league being browsed, and its generated clubs (pick >= WB)
const WB = 10000
var cont := "Europe"
var wl := -1
var wclubs: Array = []
var winfo: Array = []
# nations run on the full match engine (up to five); the club's nation is always one of them
var playable: Array = ["England", "Spain", "Italy", "Germany", "France"]


var _view_key := ""


func refresh():
	# keep the grid's scroll position only while the same nation / league is shown (e.g. picking a club)
	var k = "%s|%d|%d|%s|%d" % [nat, lg, wl, cont, step]
	if k != _view_key:
		sc = null
	_view_key = k
	super.refresh()


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
	# world leagues: the catalogue's clubs that are not in the database yet, with an estimated strength
	var raw_names = {}
	for c in raw.clubs:
		raw_names[c.name] = true
	var allc = G.WD.all_cat()
	for wi in allc.size():
		var e = allc[wi]
		var have = {}
		var raw_ids = []
		for i in raw.clubs.size():
			if raw.leagues[int(raw.clubs[i].lg)].name == e[0]:
				have[raw.clubs[i].name] = true
				raw_ids.append(i)
		# same rule as the game's world builder: a name already used by a database club elsewhere is skipped
		var todo = e[8].filter(func(x): return not have.has(x) and not raw_names.has(x))
		for nm0 in todo:
			raw_names[nm0] = true     # later catalogue leagues skip it too, as the builder does
		var top = float(e[4]) if raw_ids.is_empty() else float(e[4]) - 8.0
		for k in todo.size():
			var nm = todo[k]
			var col = G.WD.COLS[(nm.hash() & 0x7fffffff) % G.WD.COLS.size()]
			var r = lerp(top, float(e[5]), float(k) / max(1.0, float(todo.size() - 1)))
			wclubs.append({"name": nm, "short": G.WD._short(nm), "c1": col[0], "c2": col[1], "stadium": "", "cat": wi})
			winfo.append({"rep": r, "budget": G.nice(900000.0 * pow(1.2, r - 60.0) * 0.6), "n": 22, "star": "Unknown until you arrive", "star_ovr": 0, "star_pos": "",
				"att": int(r), "mid": int(r), "def": int(r), "rank": 0, "of": 0})
		var all = raw_ids.duplicate()
		for j in wclubs.size():
			if wclubs[j].cat == wi:
				all.append(WB + j)
		all.sort_custom(func(x, y): return _inf(x).rep > _inf(y).rep)
		for k in all.size():
			_inf(all[k]).rank = k + 1
			_inf(all[k]).of = all.size()


func _cl(i: int) -> Dictionary:
	return wclubs[i - WB] if i >= WB else raw.clubs[i]


func _inf(i: int) -> Dictionary:
	return winfo[i - WB] if i >= WB else info[i]


func _lg_name(i: int) -> String:
	return G.WD.all_cat()[wclubs[i - WB].cat][0] if i >= WB else raw.leagues[int(raw.clubs[i].lg)].name


func can_leave() -> bool:
	if step == 1:
		step = 0
	elif pick >= 0:
		pick = -1
	elif lg >= 0 or wl >= 0:
		lg = -1
		wl = -1
		if _divisions().size() <= 1:
			nat = ""      # a one-division nation (Korea ...) goes straight back to the continent list
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
		wl = -1
		pick = -1
		refresh()]]
	if nat != "" and _divisions().size() > 1:
		crumbs.append([G.WD.nat_of(nat), func():
			lg = -1
			wl = -1
			pick = -1
			refresh()])
	if wl >= 0:
		crumbs.append([G.WD.all_cat()[wl][0], func():
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
	var hr = UI.hb(8)
	hr.add_child(UI.btn("Playable: %d of 5" % playable.size(), _playable_sheet, "secondary", "globe", 48))
	hr.add_child(rnd)
	_header("Pick a team", crumbs, hr)
	var h = panes(16, 24)
	var grid = HFlowContainer.new()
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gs = UI.scroll(grid)
	h.add_child(gs)
	sc = gs   # screen.refresh() keeps this scroll position, so picking a club lower down no longer jumps to the top
	gs.resized.connect(func(): _fit_tiles(grid, gs))
	_fit_tiles.call_deferred(grid, gs)
	if nat == "" and wl < 0:
		var ct = UI.seg(G.WD.CONTINENTS, G.WD.CONTINENTS.find(cont), func(i):
			cont = G.WD.CONTINENTS[i]
			refresh(), 16, 6)
		ct.custom_minimum_size = Vector2(300, 0)
		ct.set_meta("fullrow", true)
		grid.add_child(ct)
		var later = []     # world league tiles go after the big five
		for wi in G.WD.CAT.size():
			var e = G.WD.CAT[wi]
			if e[3] != cont:
				continue
			var t2 = _tile(260, 190)
			var tv2 = t2.get_child(0)
			tv2.add_child(UI.center(UI.flag(e[2], 120)))
			var l2 = UI.lbl(e[0].to_upper(), 26, UI.TEXT, "xbold")
			l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART   # long names wrap instead of widening the tile
			l2.custom_minimum_size.x = 60
			tv2.add_child(l2)
			var sl2 = UI.caps("%s · %d clubs" % [e[2], e[8].size() + (8 if cont == "Europe" else 0)], 16, UI.MUTED)
			sl2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			tv2.add_child(sl2)
			var wii = wi
			UI.tap(t2, func():
				nat = G.WD.CAT[wii][2]
				if _divisions().size() <= 1:
					wl = wii
				refresh())
			grid.add_child(t2)
			later.append(t2)
		for n in (NATIONS if cont == "Europe" else []):
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
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.custom_minimum_size.x = 60
			tv.add_child(l)
			var sl = UI.caps("%d divisions · %d clubs" % [cnt, clubs], 16, UI.MUTED)
			sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			tv.add_child(sl)
			var nn = n
			UI.tap(t, func():
				nat = nn
				refresh())
			grid.add_child(t)
		for t3 in later:
			grid.move_child(t3, grid.get_child_count() - 1)
	elif lg < 0 and wl < 0:
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
			var t = _league_card(li, cnt, best / max(1, cnt))
			var idx = li
			UI.tap(t, func():
				lg = idx
				refresh())
			grid.add_child(t)
		# the world's lower divisions of this nation (Primera Federación, Serie C, National)
		var allc = G.WD.all_cat()
		for wi in allc.size():
			var e = allc[wi]
			if G.WD.nat_of(e[2]) != G.WD.nat_of(nat):
				continue
			var t3 = _cat_card(wi)
			var wix = wi
			UI.tap(t3, func():
				wl = wix
				refresh())
			grid.add_child(t3)
	else:
		var divs = _divisions()
		if divs.size() > 1:
			var names = divs.map(func(d): return d[0])
			var cur = 0
			for k in divs.size():
				if (divs[k][1] == "lg" and wl < 0 and divs[k][2] == lg) or (divs[k][1] == "wl" and divs[k][2] == wl):
					cur = k
			var dv = UI.seg(names, cur, func(k):
				pick = -1
				if divs[k][1] == "lg":
					lg = divs[k][2]
					wl = -1
				else:
					wl = divs[k][2]
					lg = -1
				refresh(), 15, 6)
			dv.custom_minimum_size = Vector2(300, 0)
			dv.set_meta("fullrow", true)
			grid.add_child(dv)
		var ids = []
		for i in raw.clubs.size():
			if (wl < 0 and int(raw.clubs[i].lg) == lg) or (wl >= 0 and raw.leagues[int(raw.clubs[i].lg)].name == G.WD.all_cat()[wl][0]):
				ids.append(i)
		if wl >= 0:
			for j in wclubs.size():
				if wclubs[j].cat == wl:
					ids.append(WB + j)
		ids.sort_custom(func(a, b): return _inf(a).rep > _inf(b).rep)
		for ci in ids:
			var c = _cl(ci)
			var on = ci == pick
			var t = _tile(176, 138, on)
			var tv = t.get_child(0)
			tv.add_child(UI.center(UI.badge({"c1": c.c1, "c2": c.c2, "short": c.short, "id": ci, "name": c.name}, 62)))
			var l = UI.lbl(c.name, 19, UI.TEXT, "semi")
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.clip_text = true
			l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			tv.add_child(l)
			var st = UI.stars(_inf(ci).rep, 14)
			st.alignment = BoxContainer.ALIGNMENT_CENTER
			tv.add_child(st)
			var idx = ci
			UI.tap(t, func():
				pick = idx
				refresh())
			grid.add_child(t)
	h.add_child(_club_panel())


func _nations() -> Array:
	# [country key as the league stores it, display name, flag nation] for every nation with a league programme
	var out = []
	for n in NATIONS:
		out.append([n, n, n])
	for e in G.WD.CAT:
		var key = e[2]
		for l in raw.leagues:
			if l.name == e[0]:
				key = l.country
		out.append([key, G.WD.nat_of(key), G.WD.nat_of(key)])
	return out


func _club_nation() -> String:
	# the country key of the picked club's league
	if pick < 0:
		return ""
	if pick >= WB:
		return _key_of(G.WD.all_cat()[wclubs[pick - WB].cat])
	return raw.leagues[int(raw.clubs[pick].lg)].country


func _key_of(e: Array) -> String:
	# a catalogue league's country as the game's leagues store it (Eredivisie is "Netherlands" in the data, "Holland" in the catalogue)
	for l in raw.leagues:
		if l.name == e[0]:
			return l.country
	for e2 in G.WD.CAT:
		if G.WD.nat_of(e2[2]) == G.WD.nat_of(e[2]):
			for l in raw.leagues:
				if l.name == e2[0]:
					return l.country
	return e[2]


func _divisions() -> Array:
	# every division of the nation being browsed, top first: [name, "lg" or "wl", index, tier]
	var out = []
	var n = G.WD.nat_of(nat)
	for li in raw.leagues.size():
		var l = raw.leagues[li]
		if not l.get("roe", false) and G.WD.nat_of(l.country) == n:
			out.append([l.name, "lg", li, int(l.tier)])
	var allc = G.WD.all_cat()
	for wi in allc.size():
		if G.WD.nat_of(allc[wi][2]) == n:
			out.append([allc[wi][0], "wl", wi, G.WD.cat_tier(wi)])
	out.sort_custom(func(a, b): return a[3] < b[3])
	return out


func _playable_sheet():
	var build = func(v):
		v.add_child(UI.wrap("Up to five nations use the full match engine: every match properly played, detailed stats, everything you can watch. The rest of the world plays quick results: tables, scorers and transfers still move, at a fraction of the work for your phone. Your club's nation is always playable.", 16, UI.MUTED))
		var g = GridContainer.new()
		g.columns = 4
		g.add_theme_constant_override("h_separation", 8)
		g.add_theme_constant_override("v_separation", 6)
		var mine = _club_nation()
		for n in _nations():
			var key = n[0]
			var on = key in playable or key == mine
			var b = UI.panel(Color(UI.GOLD, 0.2) if on else Color(1, 1, 1, 0.05), 10, 10, 6, UI.GOLD if on else Color(0, 0, 0, 0))
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var bh = UI.hb(8)
			bh.add_child(UI.flag(n[2], 26))
			bh.add_child(UI.lbl_fill(n[1], 17, UI.TEXT if on else UI.MUTED, "semi"))
			if key == mine:
				bh.add_child(UI.chip("YOUR CLUB", Color(UI.GOLD, 0.2), UI.GOLD, 12))
			b.add_child(bh)
			UI.tap(b, func():
				if key == mine:
					return
				if key in playable:
					playable.erase(key)
				elif playable.size() + (0 if mine == "" or mine in playable else 1) < 5:
					playable.append(key)
				else:
					UI.toast("Five nations at most. Switch one off first.", UI.AMBER)
					return
				UI.close_sheet()
				_playable_sheet(), true)
			g.add_child(b)
		v.add_child(g)
	UI.sheet("Playable nations", build)


# each league's own colour for its card (original colours, not the real competitions' branding)
const LCOL = ["5B2A86", "1F5FA8", "B8402E", "2E8B57", "C2423A", "D9822B", "1B6FB5", "3A9D5D", "C8102E", "2F4F8F", "6B7A8F", "1E3A8A", "4C8C3A"]
const UEFA = {0: [4, 2], 4: [4, 2], 6: [4, 2], 8: [4, 2], 11: [3, 2]}


func _league_card(li: int, cnt: int, avg: float) -> PanelContainer:
	# a league's own card: emblem (assets/leagues/<index>.png when Sudhi supplies one, else the flag), stars,
	# full engine or quick results, the favourites, format, money, best player and cups
	var l = raw.leagues[li]
	var col = Color.html(LCOL[li % LCOL.size()])
	var t = UI.panel(col.darkened(0.72), 16, 14, 12, col.darkened(0.2))
	t.custom_minimum_size = Vector2(336, 250)
	t.set_meta("base", Vector2(336, 250))
	var v = UI.vb(5)
	t.add_child(v)
	var top = UI.hb(12)
	var lp = "res://assets/leagues/%d.png" % li
	if ResourceLoader.exists(lp):
		var em = TextureRect.new()
		em.texture = load(lp)
		em.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		em.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		em.custom_minimum_size = Vector2(84, 84)
		top.add_child(em)
	else:
		top.add_child(UI.flag(l.country, 52))
	var tt = UI.vb(0)
	tt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tr = UI.hb(8)
	tr.add_child(UI.caps("Tier %d" % int(l.tier), 15, UI.GOLD))
	tr.add_child(UI.half_stars(clamp((avg - 56.0) / 5.0, 0.5, 5.0), 14))
	tt.add_child(tr)
	tt.add_child(UI.lbl_fill(l.name.to_upper(), 24, UI.TEXT, "xbold"))
	var full = l.country in playable or l.country == _club_nation()
	var cr = UI.hb(8)
	cr.add_child(UI.chip("FULL ENGINE" if full else "QUICK RESULTS", Color(UI.GREEN if full else UI.MUTED, 0.22), UI.GREEN if full else UI.MUTED, 13))
	cr.add_child(UI.caps("%d clubs · avg %d" % [cnt, int(round(avg))], 14, UI.MUTED))
	tt.add_child(cr)
	top.add_child(tt)
	v.add_child(top)
	# favourites: the three strongest clubs
	var ids = []
	for i in raw.clubs.size():
		if int(raw.clubs[i].lg) == li:
			ids.append(i)
	ids.sort_custom(func(x, y): return info[x].rep > info[y].rep)
	var fr = UI.hb(6)
	fr.add_child(UI.caps("Favourites", 13, UI.MUTED))
	for k in min(3, ids.size()):
		var c = raw.clubs[ids[k]].duplicate()
		fr.add_child(UI.badge(c, 26))
		fr.add_child(UI.lbl(c.short, 15, UI.TEXT, "semi"))
	v.add_child(fr)
	# format: European places, promotion, relegation
	var fm = []
	if UEFA.has(li):
		fm.append("%d CL" % UEFA[li][0])
		fm.append("%d EL" % UEFA[li][1])
	var down = 0
	for lk in G.LG.LINKS:
		if lk[1] == li:
			fm.append("%d up%s" % [lk[2], " + PO" if lk[3] != "rel" else ""])
		if lk[0] == li:
			down = lk[2] + (1 if lk[3] == "eng4" else 0)
	if down == 0:
		# a world division below it (Primera Federación under LaLiga 2 ...)
		for e3 in G.WD.CAT3:
			if e3[9] == l.name:
				down = int(e3[10])
	if down > 0:
		fm.append("%d down" % down)
	v.add_child(UI.kv("Format", " · ".join(fm), UI.TEXT, 17))
	var tierf = [1.0, 0.22, 0.07, 0.03][clampi(int(l.tier) - 1, 0, 3)]
	var bsum = 0.0
	for i in ids:
		bsum += 900000.0 * pow(1.2, info[i].rep - 60.0)
	v.add_child(UI.kv("Winner · budgets", "%s · ~%s" % [G.money(40000000.0 * tierf), G.money(G.nice(bsum / max(1, ids.size())))], UI.TEXT, 17))
	var bp = -1
	for i in ids:
		if bp < 0 or info[i].star_ovr > info[bp].star_ovr:
			bp = i
	if bp >= 0:
		v.add_child(UI.kv("Best player", "%s · %s %d · %s" % [info[bp].star, info[bp].star_pos, info[bp].star_ovr, raw.clubs[bp].short], UI.TEXT, 17))
	var cups = []
	for cd in G.CP.CUPS:
		if cd[2] == l.country and (cd[0] != "lc" or int(l.tier) <= 4):
			cups.append(cd[1])
	v.add_child(UI.kv("Cups", ", ".join(cups) if cups.size() > 0 else "—", UI.TEXT, 17))
	return t


const CONT_CUP = {"Europe": "Champions League", "South America": "Copa Libertadores", "Asia": "AFC Champions League", "Africa": "CAF Champions League", "North America": "CONCACAF Champions Cup"}
static var _wl_map = null


static func cat_emblem(name: String) -> Texture2D:
	# a catalogue league's emblem (assets/leagues/w, Sudhi's ChatGPT sheets), or null
	if _wl_map == null:
		_wl_map = {}
		var fa = FileAccess.open("res://assets/leagues/w/map.json", FileAccess.READ)
		if fa != null:
			_wl_map = JSON.parse_string(fa.get_as_text())
	var f = str(_wl_map.get(name, ""))
	var p = "res://assets/leagues/w/" + f
	return load(p) if f != "" and ResourceLoader.exists(p) else null


func _cat_card(wi: int) -> PanelContainer:
	# the same card as the database leagues (Sudhi: "why can't all of them be like the English league"):
	# emblem, stars, engine, favourites, format, money, best player, cups
	var e = G.WD.all_cat()[wi]
	var tier = G.WD.cat_tier(wi)
	var col = Color.html(LCOL[(e[0].hash() & 0x7fffffff) % LCOL.size()])
	var t = UI.panel(col.darkened(0.72), 16, 14, 12, col.darkened(0.2))
	t.custom_minimum_size = Vector2(336, 250)
	t.set_meta("base", Vector2(336, 250))
	var v = UI.vb(5)
	t.add_child(v)
	var ids = []
	for i in raw.clubs.size():
		if raw.leagues[int(raw.clubs[i].lg)].name == e[0]:
			ids.append(i)
	for j in wclubs.size():
		if wclubs[j].cat == wi:
			ids.append(WB + j)
	ids.sort_custom(func(x, y): return _inf(x).rep > _inf(y).rep)
	var avg = 0.0
	for i in ids:
		avg += float(_inf(i).rep)
	avg /= max(1, ids.size())
	var top = UI.hb(12)
	var et = cat_emblem(e[0])
	if et != null:
		var em = TextureRect.new()
		em.texture = et
		em.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		em.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		em.custom_minimum_size = Vector2(84, 84)
		top.add_child(em)
	else:
		top.add_child(UI.flag(e[2], 52))
	var tt = UI.vb(0)
	tt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tr = UI.hb(8)
	tr.add_child(UI.caps("Tier %d" % tier, 15, UI.GOLD))
	tr.add_child(UI.half_stars(clamp((avg - 56.0) / 5.0, 0.5, 5.0), 14))
	tt.add_child(tr)
	tt.add_child(UI.lbl_fill(e[0].to_upper(), 24, UI.TEXT, "xbold"))
	var full = _key_of(e) in playable or _key_of(e) == _club_nation()
	var cr = UI.hb(8)
	cr.add_child(UI.chip("FULL ENGINE" if full else "QUICK RESULTS", Color(UI.GREEN if full else UI.MUTED, 0.22), UI.GREEN if full else UI.MUTED, 13))
	cr.add_child(UI.caps("%d clubs · avg %d" % [ids.size(), int(round(avg))], 14, UI.MUTED))
	tt.add_child(cr)
	top.add_child(tt)
	v.add_child(top)
	var fr = UI.hb(6)
	fr.add_child(UI.caps("Favourites", 13, UI.MUTED))
	for k in min(3, ids.size()):
		var c = _cl(ids[k]).duplicate()
		fr.add_child(UI.badge(c, 26))
		fr.add_child(UI.lbl(str(c.short), 15, UI.TEXT, "semi"))
	v.add_child(fr)
	var fm = []
	if tier == 1:
		fm.append("4 %s" % {"Europe": "CL", "South America": "Libertadores", "Asia": "AFC CL", "Africa": "CAF CL", "North America": "CONCACAF"}[e[3]])
	else:
		fm.append("%d up" % int(e[10]))
	var allc = G.WD.all_cat()
	for e2 in allc:
		if e2.size() > 10 and e2[9] == e[0]:
			fm.append("%d down" % int(e2[10]))
	v.add_child(UI.kv("Format", " · ".join(fm), UI.TEXT, 17))
	var bsum = 0.0
	for i in ids:
		bsum += float(_inf(i).budget)
	v.add_child(UI.kv("Winner · budgets", "%s · ~%s" % [G.money(40000000.0 * 0.12 * [1.0, 0.35, 0.12][tier - 1]), G.money(G.nice(bsum / max(1, ids.size())))], UI.TEXT, 17))
	var bp = -1
	for i in ids:
		if i < WB and (bp < 0 or info[i].star_ovr > info[bp].star_ovr):
			bp = i
	v.add_child(UI.kv("Best player", ("%s · %s %d · %s" % [info[bp].star, info[bp].star_pos, info[bp].star_ovr, raw.clubs[bp].short]) if bp >= 0 else "Generated: scout to find out", UI.TEXT, 17))
	v.add_child(UI.kv("Cups", CONT_CUP[e[3]] if tier == 1 else "—", UI.TEXT, 17))
	return t


func _world_card(wi: int) -> PanelContainer:
	# a catalogue division in a nation's league list: same size and look as the league cards, less detail
	var e = G.WD.all_cat()[wi]
	var tier = G.WD.cat_tier(wi)
	var col = Color.html(LCOL[(e[0].hash() & 0x7fffffff) % LCOL.size()])
	var t = UI.panel(col.darkened(0.72), 16, 14, 12, col.darkened(0.2))
	t.custom_minimum_size = Vector2(336, 250)
	t.set_meta("base", Vector2(336, 250))
	var v = UI.vb(6)
	t.add_child(v)
	var top = UI.hb(12)
	top.add_child(UI.flag(e[2], 52))
	var tt = UI.vb(0)
	tt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tt.add_child(UI.caps("Tier %d" % tier, 15, UI.GOLD))
	tt.add_child(UI.lbl_fill(e[0].to_upper(), 24, UI.TEXT, "xbold"))
	var full = _key_of(e) in playable or _key_of(e) == _club_nation()
	var cr = UI.hb(8)
	cr.add_child(UI.chip("FULL ENGINE" if full else "QUICK RESULTS", Color(UI.GREEN if full else UI.MUTED, 0.22), UI.GREEN if full else UI.MUTED, 13))
	var nclubs = 0
	for j in wclubs.size():
		if wclubs[j].cat == wi:
			nclubs += 1
	for c in raw.clubs:
		if raw.leagues[int(c.lg)].name == e[0]:
			nclubs += 1
	cr.add_child(UI.caps("%d clubs" % nclubs, 14, UI.MUTED))
	tt.add_child(cr)
	top.add_child(tt)
	v.add_child(top)
	if tier >= 2:
		v.add_child(UI.kv("Format", "%d up to the %s" % [int(e[10]), e[9]], UI.TEXT, 17))
	v.add_child(UI.kv("Players", "Generated", UI.TEXT, 17))
	v.add_child(UI.kv("Strength", "%d to %d" % [int(e[5]), int(e[4])], UI.TEXT, 17))
	return t


func _fit_tiles(grid: HFlowContainer, gs: Control):
	# tiles were a fixed size and left a big empty strip; now they share the row (balanced rows) and, when there
	# are only a few, the height too
	if not is_instance_valid(grid) or not is_instance_valid(gs):
		return
	for fr in grid.get_children():
		if fr is Control and fr.has_meta("fullrow"):
			fr.custom_minimum_size.x = gs.size.x - 6
	var tiles = grid.get_children().filter(func(t): return t is Control and t.has_meta("base"))
	var n = tiles.size()
	var W = gs.size.x - 6
	var H = gs.size.y - 6
	if n == 0 or W < 100:
		return
	var sep = 12.0
	var base: Vector2 = tiles[0].get_meta("base")
	var cols = clampi(int((W + sep) / (base.x + sep)), 1, n)
	var rows = int(ceil(n / float(cols)))
	cols = int(ceil(n / float(rows)))
	var w = min(floor((W - sep * (cols - 1)) / cols), base.x * 1.5)
	var hh = base.y
	if rows * (base.y + sep) <= H + sep:
		hh = min(floor((H - sep * (rows - 1)) / rows), base.y * 1.6)
	for t in tiles:
		t.custom_minimum_size = Vector2(w, max(base.y, hh))


func _tile(w: float, hgt: float, on := false) -> PanelContainer:
	var t = UI.panel(Color(UI.GOLD, 0.14) if on else UI.CARD, 18, 14, 12, UI.GOLD if on else UI.LINE)
	t.custom_minimum_size = Vector2(w, hgt)
	t.set_meta("base", Vector2(w, hgt))
	var tv = UI.vb(6)
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	t.add_child(tv)
	return t


func _club_panel() -> Control:
	var p = UI.panel(UI.CARD, 20, 18, 16, Color(UI.GOLD, 0.45) if pick >= 0 else UI.LINE)
	p.custom_minimum_size = Vector2(400, 0)
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var v = UI.vb(8)
	# fixed width: a long line (star player's name) must not widen the panel and squeeze the club grid
	var sc2 = UI.scroll(v)
	sc2.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	sc2.custom_minimum_size.x = 0
	p.add_child(sc2)
	if pick < 0:
		v.add_child(UI.sp(0, 40))
		v.add_child(UI.center(UI.icon("shield", 80, UI.DIM)))
		var l = UI.wrap("Pick a nation, a league and a club. Club details appear here.", 21, UI.MUTED)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
		return p
	var c = _cl(pick)
	var inf = _inf(pick)
	var l = {"name": _lg_name(pick), "country": nat, "tier": 1} if pick >= WB or wl >= 0 else raw.leagues[int(c.lg)]
	v.add_child(UI.stadium_banner(float(inf.rep), 92))   # the ground by size, non-league to mega stadium
	var head = UI.hb(14)
	head.add_child(UI.badge({"c1": c.c1, "c2": c.c2, "short": c.short, "id": pick, "name": c.name}, 84))
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
	v.add_child(UI.kv("Star player", "%s · %s %d" % [inf.star, inf.star_pos, inf.star_ovr], UI.TEXT, 20))
	v.add_child(UI.kv("Squad size", str(inf.n)))
	if pick >= WB or wl >= 0:
		v.add_child(UI.wrap("A league in the wider world: its players are generated for your career, and you will discover them as you go.", 16, UI.MUTED))
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
	return G.OPS.points_for(prof.badge, prof.bg) + (BAL_BONUS if style == 0 else 0) - used


func _apply_style():
	var pts = G.OPS.points_for(prof.badge, prof.bg) + (BAL_BONUS if style == 0 else 0)
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
	var c = _cl(pick)
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
	f1.custom_minimum_size = Vector2(0, 50)
	v.add_child(f1)
	var f2 = UI.input(ln, "Last name", func(t): ln = t)
	f2.custom_minimum_size = Vector2(0, 50)
	v.add_child(f2)
	var f3 = UI.input(sh, "@ Social name (optional)", func(t): sh = t)
	f3.custom_minimum_size = Vector2(0, 46)
	v.add_child(f3)
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
	v.add_child(UI.wrap(STYLES[style][2] + " Adjust the points if you like.", 17, UI.MUTED))
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
	if not prof.has("face"):
		prof["face"] = load("res://scripts/widgets/face.gd").default_face()
	var fr2 = UI.hb(10)
	fr2.alignment = BoxContainer.ALIGNMENT_CENTER
	fr2.add_child(FED.make(prof.face, 104))
	var fb = UI.vb(6)
	fb.alignment = BoxContainer.ALIGNMENT_CENTER
	fb.add_child(UI.badge({"c1": c.c1, "c2": c.c2, "short": c.short, "id": pick, "name": c.name}, 50))
	fb.add_child(UI.btn("Your face", func(): FED.open(prof.face, func(nf):
		prof["face"] = nf
		refresh()), "secondary", "pencil", 40))
	fr2.add_child(fb)
	sv.add_child(fr2)
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
	# the club's nation is always playable; if that makes six, the last one picked drops out
	var pl = playable.duplicate()
	var cn = _club_nation()
	if not (cn in pl):
		pl.append(cn)
	while pl.size() > 5:
		pl.remove_at(pl.size() - 2)
	prof["playable"] = pl
	if pick >= WB:
		prof["world_club"] = wclubs[pick - WB].name
		G.new_game(prof, 0)
	else:
		prof.erase("world_club")
		G.new_game(prof, pick)
	G.s.user["age"] = age
	G.s.user["style"] = STYLES[style][0]
	var hd = sh.strip_edges().replace("@", "").replace(" ", "_")
	G.SOC.data().handle = hd.substr(0, 20) if hd.length() >= 3 else str(prof.name).replace(" ", "")
	UI.main.root("intro", {"kind": "appoint"})

extends "res://scripts/screens/screen.gd"
# Player search: one dense sortable table for every player list in the game.
# Quick lists (Bargains, Free Agents, Listed, Expiring, Top 50, Wonderkids, Similar, Role, Position) are presets of it
# with a "Why" column. Customise opens the full filter page (General / Positions / Attributes), templates and saved searches.

const PER = 9
const GROUPS = ["GK", "DEF", "MID", "ATT"]
const VIEWS = ["General", "Contract", "Attributes", "Skills"]
const LISTS = [["", "All"], ["bargains", "Bargains"], ["free", "Free"], ["listed", "Listed"], ["expiring", "Expiring"], ["top50", "Top 50"], ["wonderkids", "Kids"]]
const LIST_TITLE = {"": "Player Search", "bargains": "Bargains", "free": "Free Agents", "listed": "Transfer Listed", "expiring": "Expiring Contracts",
	"top50": "Top 50 Players", "wonderkids": "Wonderkids", "similar": "Similar Players", "role": "Role Finder", "pos": "Best Available"}
const ALL_POS = ["GK", "RB", "CB", "LB", "CDM", "CM", "CAM", "RM", "LM", "RW", "LW", "ST"]
const STN = ["Pace", "Shooting", "Passing", "Dribbling", "Defending", "Physical"]

var pg := 0
var view := 0
var key := "val"
var desc := true
var rows: Array = []
var why: Dictionary = {}
var cust := false       # the Customise page is showing
var ctab := 0
var F: Dictionary


static func blank() -> Dictionary:
	return {"list": "", "grp": -1, "q": "", "age0": 15, "age1": 45, "ovr0": 40, "ovr1": 99, "val1": 0, "wage1": 0, "afford": false, "listed": false, "free": false,
		"ending": false, "skill": "", "fitstyle": false, "linkfit": false, "foot": 0, "nat": "", "pos": [], "st": [0, 0, 0, 0, 0, 0], "tpl": ""}


func _init_f():
	if not G.ui.has("srch"):
		G.ui["srch"] = blank()
	F = G.ui.srch
	if args.has("list") and not args.get("_used", false):
		args["_used"] = true
		var nf = blank()
		nf.list = str(args.list)
		G.ui["srch"] = nf
		F = nf
		key = "score"
		desc = true
		if nf.list == "similar":
			_template(G.s.players[args.pid], false)
			F.list = "similar"
		elif nf.list == "role" or nf.list == "pos":
			F.pos = [str(args.pos)]
			F.afford = true
	elif F.list != "":
		key = "score"


func active_filters() -> int:
	var b = blank()
	var n = 0
	for k in b:
		if k in ["list", "grp", "q", "tpl"]:
			continue
		if F[k] != b[k]:
			n += 1
	return n


func _template(p: Dictionary, announce := true):
	# search for players like this one
	var nf = blank()
	nf.pos = [p.pos]
	nf.ovr0 = max(40, p.ovr - 7)
	nf.ovr1 = min(99, p.ovr + 4)
	var order = [0, 1, 2, 3, 4, 5]
	order.sort_custom(func(a, b): return p.st[a] > p.st[b])
	for i in order.slice(0, 3):
		nf.st[i] = int(max(40, p.st[i] - 10))
	nf.tpl = G.pname(p)
	G.ui["srch"] = nf
	F = nf
	key = "ovr"
	desc = true
	pg = 0
	if announce:
		UI.toast("Searching for players like %s" % G.pname(p), UI.accent)


func _pass(p: Dictionary, c: Dictionary, st: int, ql: String) -> bool:
	var s = G.s
	if p.club == c.id:
		return false
	if p.club >= 0 and s.leagues[s.clubs[p.club].lg].roe and ql == "":
		return false
	if F.grp >= 0 and G.LINE.get(p.pos, 2) != F.grp:
		return false
	if not F.pos.is_empty():
		var ok = p.pos in F.pos
		if not ok:
			for a in p.alt:
				if a in F.pos:
					ok = true
		if not ok:
			return false
	if p.ovr < F.ovr0 or p.ovr > F.ovr1:
		return false
	var ag = G.age(p)
	if ag < F.age0 or ag > F.age1:
		return false
	if F.afford and G.value(p) > c.budget:
		return false
	if F.val1 > 0 and G.value(p) > F.val1 * 1000000:
		return false
	if F.wage1 > 0 and p.wage > F.wage1 * 1000:
		return false
	if F.listed and not p.listed:
		return false
	if F.free and p.club >= 0:
		return false
	if F.ending and (p.club < 0 or p.cend > s.season + 1):
		return false
	if F.foot > 0 and p.foot != ("L" if F.foot == 1 else "R"):
		return false
	if F.nat != "" and not str(p.nat).to_lower().begins_with(F.nat.to_lower()):
		return false
	for i in 6:
		if F.st[i] > 0 and p.st[i] < F.st[i]:
			return false
	if F.skill != "" and not (F.skill in p.get("sk", [])):
		return false
	if F.fitstyle and G.TC.best_fit_role(p, p.pos, st) == "":
		return false
	if F.linkfit and not _fits_link(p):
		return false
	if ql != "" and not G.pfull(p).to_lower().contains(ql) and not (p.club >= 0 and s.clubs[p.club].name.to_lower().contains(ql)):
		return false
	return true


func _rank(p: Dictionary, c: Dictionary, best: Dictionary) -> Array:
	# [passes, score, reason] for the chosen quick list
	var s = G.s
	var ag = G.age(p)
	match F.list:
		"top50":
			return [p.club >= 0, p.ovr * 100.0 - ag, "%d rated, aged %d" % [p.ovr, ag]]
		"wonderkids":
			return [p.club >= 0 and ag <= 21, p.ovr * 100.0 - ag * 30.0, "%d rated at %d" % [p.ovr, ag]]
		"free":
			return [p.club < 0, float(p.ovr), "No fee · wants about %s a week" % G.money(G.wage_for(p.ovr, ag))]
		"listed":
			return [p.club >= 0 and p.listed, float(p.ovr), "For sale at about %s" % G.money(G.TR.asking_price(p))]
		"expiring":
			return [p.club >= 0 and p.cend <= s.season + 1, float(p.ovr), "Free in June · pre-contract possible"]
		"similar":
			var q = s.players[args.pid] if args.has("pid") and s.players.has(args.pid) else p
			return [p.id != q.id, 100.0 - absi(p.ovr - q.ovr) * 6.0 - maxf(0.0, ag - G.age(q)) * 2.0 - float(G.value(p)) / maxf(1.0, G.value(q)) * 10.0,
				"%+d rating, %+d years" % [p.ovr - q.ovr, ag - G.age(q)]]
		"role":
			var sc0 = G.RL.score(p, args.rid) if args.has("rid") else float(p.ovr)
			return [G.fit(p, str(args.get("pos", p.pos))) >= 0.9, sc0, "Role score %d" % int(sc0)]
		"pos":
			return [G.fit(p, str(args.get("pos", p.pos))) >= 0.9, float(p.ovr), "Plays %s" % str(args.get("pos", p.pos))]
		"bargains":
			if p.club < 0 or p.ovr < best.floor:
				return [false, 0.0, ""]
			var ask = G.TR.asking_price(p)
			var val = float(max(1, G.value(p)))
			if ask > c.budget:
				return [false, 0.0, ""]
			var up = p.ovr - int(best.get(p.pos, best.avg))
			var disc = (val - ask) / val
			var ending = p.cend <= s.season + 1
			var sc1 = p.ovr * 2.2 + clampf(up, -5, 8) * 2.0 + disc * 40.0 + (7.0 if p.listed else 0.0) + (5.0 if ending else 0.0) + maxf(0.0, 24 - ag) * 0.8 - float(ask) / max(1.0, c.budget) * 10.0
			if p.get("unhappy", 0) > 0:
				sc1 += 4.0
			var r = "Good value at %s" % G.money(ask)
			if up > 0 and (p.listed or ending):
				r = "Upgrade at %s (+%d), %s" % [p.pos, up, "listed" if p.listed else "contract ending"]
			elif p.listed:
				r = "Listed: asking about %s" % G.money(ask)
			elif ending:
				r = "Contract ends June: %s now" % G.money(ask)
			elif up > 0:
				r = "Better than your best %s (+%d)" % [p.pos, up]
			elif ag <= 21:
				r = "Aged %d and still improving" % ag
			return [true, sc1, r]
	return [true, 0.0, ""]


func _collect():
	var s = G.s
	var c = G.uc()
	rows = []
	why = {}
	var st = G.TC.style_of(c)
	var ql = str(F.q).strip_edges().to_lower()
	var best = {"avg": 60, "floor": 55}
	if F.list == "bargains":
		var tot = 0
		for pid in c.players:
			var mp = s.players[pid]
			best[mp.pos] = max(int(best.get(mp.pos, 0)), mp.ovr)
			tot += mp.ovr
		best.avg = tot / max(1, c.players.size())
		best.floor = best.avg - 6
	var keyed = []
	for p in s.players.values():
		if not _pass(p, c, st, ql):
			continue
		var sc0 = 0.0
		if F.list != "":
			var rk = _rank(p, c, best)
			if not rk[0]:
				continue
			sc0 = rk[1]
			why[p.id] = rk[2]
		keyed.append([_keyval(p, sc0), p, sc0])
	var cap = 50 if F.list in ["top50", "wonderkids"] else (90 if F.list != "" else 100000)
	if F.list != "" and key != "score":
		# a list keeps its own best, then re-sorts them by the chosen column
		keyed.sort_custom(func(a, b): return a[2] > b[2])
		if keyed.size() > cap:
			keyed.resize(cap)
	if desc:
		keyed.sort_custom(func(a, b): return a[0] > b[0])
	else:
		keyed.sort_custom(func(a, b): return a[0] < b[0])
	for k in keyed:
		rows.append(k[1])
		if rows.size() >= cap:
			break


func _keyval(p: Dictionary, sc0: float) -> float:
	match key:
		"score": return sc0
		"name": return -float(G.pfull(p).unicode_at(0))
		"age": return float(G.age(p))
		"ovr": return float(p.ovr)
		"wage": return float(p.wage)
		"cend": return float(p.cend)
		"pac": return float(p.st[0])
		"sho": return float(p.st[1])
		"pas": return float(p.st[2])
		"dri": return float(p.st[3])
		"def": return float(p.st[4])
		"phy": return float(p.st[5])
	return float(G.value(p))


func _fits_link(p: Dictionary) -> bool:
	for lid in G.s.user.links:
		if not G.TC.LINKS.has(lid):
			continue
		for sl in [G.TC.LINKS[lid].a, G.TC.LINKS[lid].b]:
			if p.pos in sl.pos and G.TC.fits_slot(sl, p):
				return true
	return false


func _pick_skill():
	var build_sheet = func(v):
		var none = UI.panel(UI.CARD, 12, 16, 8, UI.accent if F.skill == "" else UI.LINE)
		none.add_child(UI.lbl("Any skill", 22, UI.TEXT, "semi"))
		UI.tap(none, func():
			F.skill = ""
			pg = 0
			UI.close_sheet()
			refresh())
		v.add_child(none)
		for id in G.TC.SKILLS:
			var sk = G.TC.SKILLS[id]
			var r = UI.panel(UI.CARD, 12, 16, 6, UI.accent if F.skill == id else UI.LINE)
			var h = UI.hb(10)
			h.add_child(UI.lbl(sk.n, 21, UI.TEXT, "semi"))
			h.add_child(UI.lbl_fill(sk.d, 15, UI.MUTED))
			r.add_child(h)
			var sid = id
			UI.tap(r, func():
				F.skill = sid
				pg = 0
				UI.close_sheet()
				refresh())
			v.add_child(r)
	UI.sheet("Filter by skill", build_sheet)


func build():
	_init_f()
	if cust:
		_build_custom()
		return
	var s = G.s
	var c = G.uc()
	_collect()
	var pages = max(1, int(ceil(rows.size() / float(PER))))
	pg = clampi(pg, 0, pages - 1)
	var nav = UI.hb(6)
	for d in [-1, 1]:
		var b = UI.panel(Color(1, 1, 1, 0.07), 10, 12, 8)
		b.add_child(UI.icon("chevron-left" if d < 0 else "chevron-right", 26, UI.TEXT))
		UI.tap(b, func():
			pg = clampi(pg + d, 0, pages - 1)
			refresh(), true)
		nav.add_child(b)
		if d < 0:
			var pl = UI.lbl("Pg. %d/%d" % [pg + 1, pages], 20, UI.TEXT, "semi")
			pl.custom_minimum_size = Vector2(120, 0)
			pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			nav.add_child(pl)
	body.add_child(UI.topbar(LIST_TITLE.get(F.list, "Player Search"), true, nav))
	var nf = active_filters()
	UI.main.t_sub = "%d players%s%s" % [rows.size(), " · like %s" % F.tpl if F.tpl != "" else "", " · %d filter%s on" % [nf, "" if nf == 1 else "s"] if nf > 0 else ""]
	# budget strip, view, customise
	var strip = UI.panel(Color(UI.accent, 0.85), 8, 14, 4)
	var fg = UI.on_color(UI.accent)
	var sh = UI.hb(12)
	sh.add_child(UI.lbl("Budget", 18, fg, "semi"))
	sh.add_child(UI.lbl(G.money(c.budget), 20, fg, "xbold"))
	sh.add_child(UI.lbl("Wage room", 18, fg, "semi"))
	sh.add_child(UI.lbl("%s (p/w)" % G.money(max(0, c.wage_budget - G.squad_wages(c))), 20, fg, "xbold"))
	sh.add_child(UI.sp())
	var mk = func(txt: String, ic: String, cb: Callable, hot := false):
		var b = UI.panel(Color(0, 0, 0, 0.42 if hot else 0.22), 8, 10, 3)
		var bh = UI.hb(6)
		bh.add_child(UI.icon(ic, 18, fg))
		bh.add_child(UI.lbl(txt, 18, fg, "bold"))
		b.add_child(bh)
		UI.tap(b, cb, true)
		sh.add_child(b)
	mk.call("View: %s" % VIEWS[view], "eye", func():
		view = (view + 1) % VIEWS.size()
		refresh())
	mk.call("Saved", "bookmark", _saved_sheet)
	mk.call("Customise%s" % (" · %d" % nf if nf > 0 else ""), "sliders-horizontal", func():
		cust = true
		refresh(), nf > 0)
	strip.add_child(sh)
	body.add_child(UI.margin(strip, 16, 0, 16, 4))
	var fh = UI.hb(5)
	for li in LISTS:
		var on = F.list == li[0]
		var ch = UI.chip(li[1].to_upper(), Color(UI.accent, 0.24) if on else Color(1, 1, 1, 0.06), UI.accent.lightened(0.3) if on else UI.MUTED, 16)
		var lk = li[0]
		UI.tap(ch, func():
			F.list = lk
			key = "score" if lk != "" else "val"
			desc = true
			pg = 0
			refresh(), true)
		fh.add_child(ch)
	var dv = ColorRect.new()
	dv.color = Color(1, 1, 1, 0.12)
	dv.custom_minimum_size = Vector2(1, 0)
	fh.add_child(dv)
	for i in GROUPS.size():
		var on2 = F.grp == i
		var ch2 = UI.chip(GROUPS[i], Color(UI.accent, 0.24) if on2 else Color(1, 1, 1, 0.06), UI.accent.lightened(0.3) if on2 else UI.MUTED, 16, 50)
		var idx = i
		UI.tap(ch2, func():
			F.grp = -1 if F.grp == idx else idx
			pg = 0
			refresh(), true)
		fh.add_child(ch2)
	var ac = UI.chip("IN BUDGET", Color(UI.GREEN, 0.2) if F.afford else Color(1, 1, 1, 0.06), UI.GREEN if F.afford else UI.MUTED, 16)
	UI.tap(ac, func():
		F.afford = not F.afford
		pg = 0
		refresh(), true)
	fh.add_child(ac)
	var le = UI.input(str(F.q), "Name or club…", func(t): F.q = t)
	le.custom_minimum_size = Vector2(0, 38)
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	le.text_submitted.connect(func(_t):
		pg = 0
		refresh())
	fh.add_child(le)
	var go = UI.chip("SEARCH", UI.accent, UI.on_color(UI.accent), 16)
	UI.tap(go, func():
		pg = 0
		refresh(), true)
	fh.add_child(go)
	body.add_child(UI.margin(fh, 16, 0, 16, 4))
	# columns for this view
	var listed = F.list != ""
	var cols = [["name", "Name", 0], ["", "Club", 250], ["", "Nat", 46], ["", "Pos", 130], ["age", "Age", 50], ["ovr", "Rtg", 54]]
	if listed and view == 0:
		cols = [["name", "Name", 0], ["", "Club", 200], ["", "Pos", 56], ["age", "Age", 50], ["ovr", "Rtg", 54], ["score", "Why", 330], ["val", "Value", 96]]
	elif view == 0:
		cols += [["val", "Value", 96]]
	elif view == 1:
		cols += [["wage", "Wage", 90], ["cend", "Until", 70], ["val", "Value", 96]]
	elif view == 3:
		cols = [["name", "Name", 260], ["", "Pos", 60], ["age", "Age", 50], ["ovr", "Rtg", 54], ["", "Skills", 0], ["val", "Value", 96]]
	else:
		cols = [["name", "Name", 0], ["", "Pos", 70], ["ovr", "Rtg", 54], ["pac", "Pac", 50], ["sho", "Sho", 50], ["pas", "Pas", 50], ["dri", "Dri", 50], ["def", "Def", 50], ["phy", "Phy", 50], ["val", "Value", 96]]
	var head = UI.panel(Color(UI.accent, 0.5), 6, 14, 3)
	var hh = UI.hb(8)
	for cd in cols:
		var on = cd[0] != "" and cd[0] == key
		var l = UI.lbl(cd[1] + (" ▾" if on and desc else (" ▴" if on else "")), 19, UI.GOLD if on else UI.TEXT, "semi")
		if cd[2] > 0:
			l.custom_minimum_size = Vector2(cd[2], 0)
			l.clip_text = true
		else:
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if cd[0] != "":
			var k = cd[0]
			UI.tap(l, func():
				if key == k:
					desc = not desc
				else:
					key = k
					desc = true
				pg = 0
				refresh(), true)
		hh.add_child(l)
	head.add_child(hh)
	body.add_child(UI.margin(head, 16, 0, 16, 2))
	var list = UI.vb(2)
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(UI.margin(list, 16, 0, 16, 8))
	body.get_child(body.get_child_count() - 1).size_flags_vertical = Control.SIZE_EXPAND_FILL
	var rank = pg * PER
	var shown = rows.slice(pg * PER, pg * PER + PER)
	for p in shown:
		rank += 1
		var r = UI.panel(Color(1, 1, 1, 0.035), 6, 14, 0)
		r.custom_minimum_size = Vector2(0, 40)
		if shown.size() == PER:
			r.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var h = UI.hb(8)
		for cd in cols:
			var w = cd[2]
			var node: Control
			match cd[1]:
				"Name":
					node = UI.lbl_fill(("%d. " % rank if F.list in ["top50", "wonderkids"] and key == "score" else "") + G.pfull(p), 22, UI.TEXT, "semi")
				"Club":
					var ch3 = UI.hb(8)
					if p.club >= 0:
						ch3.add_child(UI.badge(s.clubs[p.club], 28))
						ch3.add_child(UI.lbl_fill(s.clubs[p.club].name, 20, UI.TEXT))
					else:
						ch3.add_child(UI.lbl_fill("Free agent", 20, UI.GREEN))
					node = ch3
				"Nat":
					node = UI.center(UI.flag(p.nat, 34))
				"Pos":
					node = UI.lbl(p.pos + ((", " + ", ".join(p.alt)) if p.alt.size() > 0 and w > 60 else ""), 19, UI.TEXT)
					node.clip_text = true
				"Age":
					node = UI.lbl(str(G.age(p)), 21, UI.TEXT, "disp")
				"Rtg":
					node = UI.ovr(p.ovr, 19)
				"Why":
					node = UI.lbl(str(why.get(p.id, "")), 17, UI.GREEN if (p.listed or p.club < 0) else UI.MUTED)
					node.clip_text = true
					node.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
				"Value":
					node = UI.lbl(G.money(G.value(p)), 21, UI.GOLD if G.value(p) <= c.budget else UI.TEXT, "disp")
				"Wage":
					node = UI.lbl(G.money(p.wage), 20, UI.MUTED, "disp")
				"Until":
					node = UI.lbl(str(p.cend) if p.club >= 0 else "-", 20, UI.AMBER if p.cend <= s.season + 1 else UI.MUTED, "disp")
				"Skills":
					node = UI.lbl_fill(", ".join(G.TC.skill_names(p)) if p.get("sk", []).size() > 0 else "-", 16, UI.MUTED)
				_:
					var i = ["Pac", "Sho", "Pas", "Dri", "Def", "Phy"].find(cd[1])
					node = UI.lbl(str(int(p.st[i])), 21, UI.ovr_color(int(p.st[i])), "disp")
			if w > 0:
				node.custom_minimum_size = Vector2(w, 0)
				node.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			node.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			h.add_child(node)
		r.add_child(h)
		var pid = p.id
		UI.tap(r, func(): UI.main.open("player", {"pid": pid}))
		list.add_child(r)
	if rows.is_empty():
		list.add_child(UI.wrap("No players match. Open Customise to loosen the filters, or pick All.", 21, UI.MUTED))


# ---------------------------------------------------------------- customise

func _count() -> int:
	var c = G.uc()
	var st = G.TC.style_of(c)
	var n = 0
	for p in G.s.players.values():
		if _pass(p, c, st, ""):
			n += 1
	return n


func _build_custom():
	body.add_child(UI.topbar("Customise search", true))
	var n = _count()
	UI.main.t_sub = "%d players match · %s" % [n, "like %s" % F.tpl if F.tpl != "" else "set the filters, then Show"]
	var top = UI.hb(8)
	var sg = UI.seg(["General", "Positions", "Attributes"], ctab, func(i):
		ctab = i
		refresh(), 17, 6)
	sg.custom_minimum_size = Vector2(430, 0)
	top.add_child(sg)
	top.add_child(UI.sp())
	var small = func(txt: String, ic: String, cb: Callable, kind := 0):
		var b = UI.panel(UI.accent if kind == 1 else Color(1, 1, 1, 0.07), 10, 14, 7)
		var bh = UI.hb(6)
		var col = UI.on_color(UI.accent) if kind == 1 else UI.TEXT
		bh.add_child(UI.icon(ic, 20, col))
		bh.add_child(UI.lbl(txt, 19, col, "bold"))
		b.add_child(bh)
		UI.tap(b, cb, true)
		top.add_child(b)
	small.call("Templates", "wand-sparkles", _templates)
	small.call("Save", "bookmark", _save_search)
	small.call("Reset", "rotate-cw", func():
		var keep = F.list
		G.ui["srch"] = blank()
		G.ui.srch.list = keep
		refresh())
	small.call("Show %d players" % n, "search", func():
		cust = false
		pg = 0
		refresh(), 1)
	body.add_child(UI.margin(top, 20, 0, 20, 6))
	var h = panes(10, 20)
	if ctab == 0:
		_tab_general(h)
	elif ctab == 1:
		_tab_positions(h)
	else:
		_tab_attrs(h)


func can_leave() -> bool:
	if cust:
		cust = false
		refresh()
		return false
	return true


func _range(v: VBoxContainer, label: String, k: String, lo: float, hi: float, step: float, fmt: Callable):
	var r = UI.hb(10)
	var l = UI.lbl(label, 18, UI.MUTED)
	l.custom_minimum_size = Vector2(120, 0)
	r.add_child(l)
	var val = UI.lbl(fmt.call(F[k]), 19, UI.TEXT, "disp")
	val.custom_minimum_size = Vector2(96, 0)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var sl = UI.slider(lo, hi, float(F[k]), step, func(x):
		F[k] = int(x)
		val.text = fmt.call(int(x)), true)
	sl.custom_minimum_size = Vector2(0, 40)
	sl.drag_ended.connect(func(_c): refresh())
	r.add_child(sl)
	r.add_child(val)
	v.add_child(r)


func _toggle(v: Control, label: String, k: String, sub := ""):
	var on = bool(F[k])
	var r = UI.panel(Color(UI.accent, 0.14) if on else Color(1, 1, 1, 0.04), 10, 12, 6)
	var rh = UI.hb(8)
	rh.add_child(UI.icon("square-check" if on else "square", 22, UI.accent if on else UI.DIM))
	var tv = UI.vb(-4)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(UI.lbl_fill(label, 19, UI.TEXT if on else UI.MUTED, "semi"))
	if sub != "":
		tv.add_child(UI.lbl_fill(sub, 14, UI.DIM))
	rh.add_child(tv)
	r.add_child(rh)
	UI.tap(r, func():
		F[k] = not F[k]
		refresh(), true)
	v.add_child(r)


func _tab_general(h: Control):
	var a = pane(0, 4)
	h.add_child(a[0])
	var v = a[1]
	v.add_child(UI.caps("Age and ability", 15, UI.accent))
	var num = func(x): return str(x)
	_range(v, "Youngest", "age0", 15, 40, 1, num)
	_range(v, "Oldest", "age1", 16, 45, 1, num)
	_range(v, "Rating from", "ovr0", 40, 95, 1, num)
	_range(v, "Rating up to", "ovr1", 45, 99, 1, num)
	v.add_child(UI.caps("Money", 15, UI.accent))
	_range(v, "Value up to", "val1", 0, 150, 1, func(x): return "Any" if x <= 0 else G.money(x * 1000000))
	_range(v, "Wage up to", "wage1", 0, 400, 5, func(x): return "Any" if x <= 0 else G.money(x * 1000))
	var b = pane(0, 5)
	h.add_child(b[0])
	var w = b[1]
	w.add_child(UI.caps("Availability", 15, UI.accent))
	_toggle(w, "Within my transfer budget", "afford", "Value no more than %s" % G.money(G.uc().budget))
	_toggle(w, "Transfer listed", "listed", "His club wants to sell")
	_toggle(w, "Free agents", "free", "No fee to pay")
	_toggle(w, "Contract ends this June", "ending", "Cheap now, or sign a pre-contract")
	w.add_child(UI.caps("Fit for my team", 15, UI.accent))
	_toggle(w, "Has a role for my playstyle", "fitstyle")
	if G.s.user.links.size() > 0:
		_toggle(w, "Fits one of my link-up plays", "linkfit")
	var d = pane(0, 6)
	h.add_child(d[0])
	var x = d[1]
	x.add_child(UI.caps("Preferred foot", 15, UI.accent))
	x.add_child(UI.seg(["Either", "Left", "Right"], int(F.foot), func(i):
		F.foot = i
		refresh(), 17, 6))
	x.add_child(UI.caps("Skill", 15, UI.accent))
	var skb = UI.panel(Color(1, 1, 1, 0.05), 10, 12, 8)
	var skh = UI.hb(8)
	skh.add_child(UI.lbl_fill(G.TC.SKILLS[F.skill].n if F.skill != "" else "Any skill", 19, UI.TEXT, "semi"))
	skh.add_child(UI.icon("chevron-right", 18, UI.DIM))
	skb.add_child(skh)
	UI.tap(skb, _pick_skill, true)
	x.add_child(skb)
	x.add_child(UI.caps("Nationality", 15, UI.accent))
	var le = UI.input(str(F.nat), "Country, e.g. Brazil", func(t): F.nat = t)
	le.custom_minimum_size = Vector2(0, 42)
	le.text_submitted.connect(func(_t): refresh())
	x.add_child(le)
	x.add_child(UI.wrap("Filters stay on until you reset them. The quick lists (Bargains, Free, Listed…) work on top of them.", 15, UI.DIM))


func _tab_positions(h: Control):
	var a = pane(0, 8)
	a[0].size_flags_stretch_ratio = 1.6
	h.add_child(a[0])
	var v = a[1]
	v.add_child(UI.caps("Tap the positions you want · none ticked means any", 15, UI.accent))
	for line in [["ST", "LW", "RW"], ["CAM", "LM", "RM"], ["CM", "CDM"], ["LB", "CB", "RB"], ["GK"]]:
		var r = UI.hb(8)
		r.alignment = BoxContainer.ALIGNMENT_CENTER
		for ps in line:
			var on = ps in F.pos
			var b = UI.panel(Color(UI.accent, 0.3) if on else Color(1, 1, 1, 0.05), 12, 0, 12, UI.accent if on else UI.LINE)
			b.custom_minimum_size = Vector2(150, 0)
			var l = UI.lbl(ps, 24, UI.TEXT if on else UI.MUTED, "xbold")
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			b.add_child(l)
			var pp = ps
			UI.tap(b, func():
				if pp in F.pos:
					F.pos.erase(pp)
				else:
					F.pos.append(pp)
				F.grp = -1
				refresh(), true)
			r.add_child(b)
		v.add_child(r)
	var b2 = pane(0, 6)
	h.add_child(b2[0])
	var w = b2[1]
	w.add_child(UI.caps("Shortcuts", 15, UI.accent))
	for sc0 in [["Any position", []], ["Goalkeepers", ["GK"]], ["Full-backs", ["LB", "RB"]], ["Centre-backs", ["CB"]], ["Central midfield", ["CDM", "CM", "CAM"]], ["Wide players", ["LM", "RM", "LW", "RW"]], ["Strikers", ["ST"]]]:
		var same = F.pos.size() == sc0[1].size()
		for q in sc0[1]:
			if not (q in F.pos):
				same = false
		var r2 = UI.panel(Color(UI.accent, 0.14) if same else Color(1, 1, 1, 0.04), 10, 12, 7)
		r2.add_child(UI.lbl_fill(sc0[0], 19, UI.TEXT if same else UI.MUTED, "semi"))
		var set_to = sc0[1]
		UI.tap(r2, func():
			F.pos = set_to.duplicate()
			F.grp = -1
			refresh(), true)
		w.add_child(r2)
	w.add_child(UI.wrap("A player counts if it is his main position or one he can also play.", 15, UI.DIM))


func _tab_attrs(h: Control):
	var a = pane(0, 4)
	a[0].size_flags_stretch_ratio = 1.5
	h.add_child(a[0])
	var v = a[1]
	v.add_child(UI.caps("Minimum for each attribute · 0 means any", 15, UI.accent))
	for i in 6:
		var r = UI.hb(10)
		var l = UI.lbl(STN[i], 19, UI.MUTED)
		l.custom_minimum_size = Vector2(120, 0)
		r.add_child(l)
		var val = UI.lbl("Any" if F.st[i] <= 0 else str(F.st[i]), 21, UI.ovr_color(F.st[i]) if F.st[i] > 0 else UI.DIM, "disp")
		val.custom_minimum_size = Vector2(60, 0)
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		var idx = i
		var sl = UI.slider(0, 95, float(F.st[i]), 1, func(x):
			F.st[idx] = int(x) if x >= 40 else 0
			val.text = "Any" if F.st[idx] <= 0 else str(F.st[idx]), true)
		sl.custom_minimum_size = Vector2(0, 46)
		sl.drag_ended.connect(func(_c): refresh())
		r.add_child(sl)
		r.add_child(val)
		v.add_child(r)
	v.add_child(UI.wrap("For goalkeepers the six are diving, handling, kicking, reflexes, speed and positioning.", 15, UI.DIM))
	var b = pane(0, 6)
	h.add_child(b[0])
	var w = b[1]
	w.add_child(UI.caps("Start from a player", 15, UI.accent))
	w.add_child(UI.wrap("Pick one of your players or someone on your shortlist and the search fills in his position, level and strengths.", 16, UI.MUTED))
	w.add_child(UI.btn("One of my players", func(): _pick_player(G.uc().players), "secondary", "users", 50))
	w.add_child(UI.btn("From my shortlist", func(): _pick_player(G.s.shortlist), "secondary", "star", 50))
	w.add_child(UI.btn("A role in my tactics", _pick_role, "secondary", "target", 50))
	if F.tpl != "":
		w.add_child(UI.lbl_fill("Now searching for players like %s." % F.tpl, 16, UI.GREEN))


func _templates():
	ctab = 2
	refresh()


func _pick_player(ids: Array):
	if ids.is_empty():
		UI.toast("Nobody there yet", UI.MUTED)
		return
	UI.sheet("Search for players like…", func(v):
		var ps = []
		for pid in ids:
			if G.s.players.has(pid):
				ps.append(G.s.players[pid])
		ps.sort_custom(func(a, b): return a.ovr > b.ovr)
		var grid = GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 4)
		for p in ps:
			var r = UI.panel(Color(1, 1, 1, 0.05), 10, 10, 5)
			r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var rh = UI.hb(8)
			rh.add_child(UI.pos(p.pos, 16))
			rh.add_child(UI.lbl_fill(G.pname(p), 19, UI.TEXT, "semi"))
			rh.add_child(UI.ovr(p.ovr, 17))
			r.add_child(rh)
			var pp = p
			UI.tap(r, func():
				UI.close_sheet()
				_template(pp)
				refresh(), true)
			grid.add_child(r)
		v.add_child(grid))


func _pick_role():
	var c = G.uc()
	var slots = G.TC.slot_pos(c)
	UI.sheet("Search for a role in your team", func(v):
		var grid = GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 4)
		for i in slots.size():
			var rid = c.roles[i] if i < c.roles.size() else ""
			var rn = G.RL.ROLES[rid].n if G.RL.ROLES.has(rid) else str(slots[i])
			var r = UI.panel(Color(1, 1, 1, 0.05), 10, 10, 6)
			r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var rh = UI.hb(8)
			rh.add_child(UI.pos(str(slots[i]), 16))
			rh.add_child(UI.lbl_fill(rn, 19, UI.TEXT, "semi"))
			r.add_child(rh)
			var ps = str(slots[i])
			var rr = rid
			UI.tap(r, func():
				UI.close_sheet()
				var nf = blank()
				nf.list = "role"
				nf.pos = [ps]
				nf.afford = true
				G.ui["srch"] = nf
				args["rid"] = rr
				args["pos"] = ps
				key = "score"
				cust = false
				pg = 0
				refresh(), true)
			grid.add_child(r)
		v.add_child(grid))


func _summary() -> String:
	var bits = []
	if not F.pos.is_empty():
		bits.append("/".join(F.pos))
	elif F.grp >= 0:
		bits.append(GROUPS[F.grp])
	if F.list != "":
		bits.append(LIST_TITLE.get(F.list, ""))
	if F.age0 > 15 or F.age1 < 45:
		bits.append("%d-%d yrs" % [F.age0, F.age1])
	if F.ovr0 > 40 or F.ovr1 < 99:
		bits.append("%d-%d" % [F.ovr0, F.ovr1])
	if F.val1 > 0:
		bits.append("under %s" % G.money(F.val1 * 1000000))
	if F.afford:
		bits.append("in budget")
	if F.tpl != "":
		bits.append("like %s" % F.tpl)
	return " · ".join(bits) if not bits.is_empty() else "Everyone"


func _save_search():
	var u = G.s.user
	if not u.has("searches"):
		u["searches"] = []
	u.searches.push_front({"n": _summary(), "f": F.duplicate(true)})
	if u.searches.size() > 8:
		u.searches.resize(8)
	UI.toast("Search saved: %s" % _summary(), UI.GREEN)


func _saved_sheet():
	var u = G.s.user
	var list = u.get("searches", [])
	UI.sheet("Saved searches", func(v):
		if list.is_empty():
			v.add_child(UI.wrap("Nothing saved yet. Open Customise, set your filters and press Save. Up to eight are kept.", 18, UI.MUTED))
		for i in list.size():
			var e = list[i]
			var r = UI.hb(8)
			var b = UI.panel(Color(1, 1, 1, 0.05), 10, 12, 8)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.add_child(UI.lbl_fill(str(e.n), 19, UI.TEXT, "semi"))
			var idx = i
			UI.tap(b, func():
				UI.close_sheet()
				var nf = blank()
				for k in e.f:
					nf[k] = e.f[k]
				G.ui["srch"] = nf
				key = "score" if nf.list != "" else "val"
				pg = 0
				refresh(), true)
			r.add_child(b)
			var x = UI.panel(Color(UI.RED, 0.14), 10, 10, 8)
			x.add_child(UI.icon("trash", 20, UI.RED))
			UI.tap(x, func():
				list.remove_at(idx)
				_saved_sheet(), true)
			r.add_child(x)
			v.add_child(r))

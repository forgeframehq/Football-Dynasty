extends "res://scripts/screens/screen.gd"
# Staff Search: the whole staff market as one table, like Player Search. Filters for job, minimum stars, coaching
# style, ex-players and name; sort by stars, upgrade over yours, wage or age. Every attribute is on the row.
# Tap a row for the hire sheet (staff.gd detail).

const STAFF = preload("res://scripts/screens/staff.gd")
const JOBS = [["All jobs", ""], ["Assistant", "ass"], ["Coach", "coach1"], ["GK coach", "gk"], ["Fitness", "fit"], ["Physio", "phys"], ["Youth", "youth"], ["Scout", "scout"]]
const MINS = [["Any", 0.0], ["2+", 2.0], ["3+", 3.0], ["4+", 4.0]]
const STYLES = ["All styles", "Tactician", "Motivator", "Developer", "Talent spotter", "Hands-on coach"]
const SORTS = ["Stars", "Upgrade", "Wage", "Age"]
const W = [0, -36, 92, 86, 24, 116, -34, -34, -34, -34, -34, -34, -34, -34, -62]

var job := 0
var min_i := 0
var style_i := 0
var sort_i := 0
var ex := false
var q := ""


func build():
	G.SF.ensure()
	var rf = int(args.get("role", 0))
	if rf > 0 and not has_meta("init"):
		set_meta("init", true)
		var r = G.SF.ROLES[rf - 1]
		for i in JOBS.size():
			if JOBS[i][1] == r or (r == "coach2" and JOBS[i][1] == "coach1"):
				job = i
	var s = G.s
	UI.main.t_title = "Staff Search"
	var h = panes(12, 20)
	var a = pane(0, 4)
	h.add_child(a[0])
	var v = a[1]
	# filters
	var r1 = UI.hb(8)
	var js = UI.seg(JOBS.map(func(x): return x[0]), job, func(i):
		job = i
		refresh(), 14, 4)
	js.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r1.add_child(js)
	var le = UI.input(q, "Name…", func(t):
		q = t
		refresh())
	le.custom_minimum_size = Vector2(170, 38)
	r1.add_child(le)
	v.add_child(r1)
	var r2 = UI.hb(8)
	r2.add_child(UI.caps("Stars", 14, UI.MUTED))
	var ms = UI.seg(MINS.map(func(x): return x[0]), min_i, func(i):
		min_i = i
		refresh(), 14, 4)
	ms.custom_minimum_size = Vector2(170, 0)
	r2.add_child(ms)
	var ss = UI.seg(STYLES, style_i, func(i):
		style_i = i
		refresh(), 13, 4)
	ss.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r2.add_child(ss)
	var exc = UI.chip("EX-PLAYERS", Color(UI.GOLD, 0.22) if ex else Color(1, 1, 1, 0.05), UI.GOLD if ex else UI.MUTED, 14)
	UI.tap(exc, func():
		ex = not ex
		refresh(), true)
	r2.add_child(exc)
	r2.add_child(UI.caps("Sort", 14, UI.MUTED))
	var so = UI.seg(SORTS, sort_i, func(i):
		sort_i = i
		refresh(), 14, 4)
	so.custom_minimum_size = Vector2(250, 0)
	r2.add_child(so)
	v.add_child(r2)
	# rows
	var role = JOBS[job][1]
	var list = []
	for sid in s.staff_free:
		var p = s.staff[sid]
		if ex and p.ex == null:
			continue
		if q.strip_edges() != "" and not G.SF.nm(p).to_lower().contains(q.strip_edges().to_lower()):
			continue
		if style_i > 0 and G.SF.style(p) != STYLES[style_i]:
			continue
		var br = role if role != "" else G.SF.best_role(p)
		var rt = G.SF.rating(p, br)
		if G.SF.stars(rt) < MINS[min_i][1]:
			continue
		list.append({"p": p, "r": br, "st": G.SF.stars(rt), "up": G.SF.vs_mine(p, br)})
	match sort_i:
		0: list.sort_custom(func(x, y): return x.st > y.st or (x.st == y.st and x.p.wage < y.p.wage))
		1: list.sort_custom(func(x, y): return x.up > y.up)
		2: list.sort_custom(func(x, y): return x.p.wage < y.p.wage)
		3: list.sort_custom(func(x, y): return G.SF.age(x.p) < G.SF.age(y.p))
	UI.main.t_sub = "%d of %d available · %s" % [list.size(), s.staff_free.size(), JOBS[job][0].to_lower()]
	v.add_child(UI.trow(["Name", "Age", "Job", "Stars", "", "Style", "Coa", "Tac", "Mot", "GK", "Fit", "Med", "You", "Jud", "Wage"], W, {"head": true, "size": 16, "pad": 1}))
	if list.is_empty():
		v.add_child(UI.wrap("Nobody matches. Loosen a filter; new names come onto the market every week.", 17, UI.DIM))
	var keys = ["coach", "tac", "mot", "gkc", "fit", "med", "youth", "judge"]
	for i in min(list.size(), 60):
		var it = list[i]
		var p = it.p
		var nm = UI.hb(5)
		nm.add_child(UI.flag(p.nat, 18))
		nm.add_child(UI.lbl_fill(G.SF.nm(p), 16, UI.TEXT, "semi"))
		if p.ex != null:
			nm.add_child(UI.chip("YOURS" if p.ex.get("own", false) else "EX-PRO", Color(UI.GOLD, 0.16), UI.GOLD, 12))
		var cells = [nm, str(G.SF.age(p)), STAFF.short_job(it.r), UI.half_stars(it.st, 14), STAFF.arrow(it.up), G.SF.style(p)]
		var cols = {2: UI.MUTED, 5: UI.MUTED}
		for k in keys.size():
			var val = int(p.a[keys[k]])
			cells.append(str(val))
			cols[6 + k] = UI.ovr_color(50 + val * 2) if keys[k] in G.SF.ROLE[it.r][1] else Color(1, 1, 1, 0.55)
		cells.append(G.money(p.wage))
		var pp = p
		var br2 = it.r
		v.add_child(UI.trow(cells, W, {"size": 16, "pad": 2, "alt": i % 2 == 0, "cols": cols, "tap": func(): STAFF.detail(pp, br2, refresh)}))

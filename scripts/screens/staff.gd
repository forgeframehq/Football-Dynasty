extends "res://scripts/screens/screen.gd"
# Staff: your eight backroom jobs on the left (who, rating for the job, what they change, wage and contract),
# the staff market on the right, filtered by job. Tap anyone for the full ratings, then hire, renew or release.

var role_f := 0         # 0 = all jobs, 1.. = SF.ROLES[role_f - 1]
var only_ex := false


func build():
	backdrop("office", 0.82)
	G.SF.ensure()
	var c = G.uc()
	UI.main.t_title = "Staff"
	UI.main.t_sub = "%d of 8 jobs filled · staff wages %s a week" % [c.staff.size(), G.money(G.SF.wage_bill())]
	var h = panes(12, 20)
	var a = pane(0, 6)
	a[0].size_flags_stretch_ratio = 1.35
	h.add_child(a[0])
	_mine(a[1])
	var b = pane(0, 2)
	h.add_child(b[0])
	_market(b[1])


func _mine(v: VBoxContainer):
	v.add_child(UI.caps("Your backroom", 16, UI.accent))
	var g = GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 8)
	for role in G.SF.ROLES:
		g.add_child(_card(role))
	v.add_child(g)


func _card(role: String) -> Control:
	var p = G.SF.who(role)
	var info = G.SF.ROLE[role]
	var pc = UI.panel(Color(1, 1, 1, 0.035), 10, 10, 6, UI.LINE if p != null else Color(UI.RED, 0.5))
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pv = UI.vb(0)
	var top = UI.hb(6)
	top.add_child(UI.icon(info[2], 16, UI.accent))
	top.add_child(UI.caps(info[0], 14, UI.accent))
	top.add_child(UI.sp())
	top.add_child(UI.half_stars(G.SF.stars(G.SF.r(role)), 15, UI.GOLD if p != null else Color(UI.RED, 0.8)))
	pv.add_child(top)
	if p == null:
		pv.add_child(UI.lbl_fill("Vacant", 18, UI.RED, "semi"))
		pv.add_child(UI.lbl_fill("A stand-in covers it badly. Tap to find someone.", 14, UI.DIM))
		var rr = role
		UI.tap(pc, func():
			role_f = G.SF.ROLES.find(rr) + 1
			refresh())
	else:
		var nh = UI.hb(6)
		nh.add_child(UI.flag(p.nat, 20))
		nh.add_child(UI.lbl_fill(G.SF.nm(p), 18, UI.TEXT, "semi"))
		if p.ex != null:
			nh.add_child(UI.chip("EX-PRO", Color(UI.GOLD, 0.16), UI.GOLD, 12))
		pv.add_child(nh)
		pv.add_child(UI.lbl_fill(G.SF.effect_text(role), 14, UI.GREEN if G.SF.r(role) >= 10 else UI.AMBER))
		pv.add_child(UI.lbl_fill("%s · %d · %s a week · until %d" % [G.SF.style(p), G.SF.age(p), G.money(p.wage), int(p.cend) + 1], 14, UI.DIM))
		var pp = p
		var rr2 = role
		UI.tap(pc, func(): detail(pp, rr2, refresh))
	pc.add_child(pv)
	return pc


func _market(v: VBoxContainer):
	var s = G.s
	var top = UI.hb(6)
	top.add_child(UI.caps("Find staff", 16, UI.accent))
	top.add_child(UI.sp())
	var sa = UI.chip("SEARCH ALL", UI.accent, UI.on_color(UI.accent), 14)
	UI.tap(sa, func(): UI.main.open("staffsearch", {"role": role_f}), true)
	top.add_child(sa)
	var ex = UI.chip("EX-PLAYERS", Color(UI.GOLD, 0.22) if only_ex else Color(1, 1, 1, 0.05), UI.GOLD if only_ex else UI.MUTED, 14)
	UI.tap(ex, func():
		only_ex = not only_ex
		refresh(), true)
	top.add_child(ex)
	v.add_child(top)
	var labels = ["All"]
	for r in G.SF.ROLES:
		labels.append({"ass": "Asst", "coach1": "Coach", "coach2": "Coach 2", "gk": "GK", "fit": "Fitness", "phys": "Physio", "youth": "Youth", "scout": "Scout"}[r])
	labels.remove_at(3)   # one "Coach" filter covers both coaching jobs
	var fi = role_f if role_f <= 2 else (2 if role_f == 3 else role_f - 1)
	v.add_child(UI.seg(labels, fi, func(i):
		role_f = i if i <= 2 else i + 1
		refresh(), 13, 4))
	var role = "" if role_f == 0 else G.SF.ROLES[role_f - 1]
	var list = []
	for sid in s.staff_free:
		var p = s.staff[sid]
		if only_ex and p.ex == null:
			continue
		var br = role if role != "" else G.SF.best_role(p)
		list.append([p, br, G.SF.rating(p, br)])
	list.sort_custom(func(x, y): return x[2] + (2.0 if x[0].ex != null and x[0].ex.get("own", false) else 0.0) > y[2] + (2.0 if y[0].ex != null and y[0].ex.get("own", false) else 0.0))
	v.add_child(UI.trow(["Name", "Job", "Stars", "", "Wage"], [0, 74, 86, 22, -60], {"head": true, "size": 16, "pad": 1}))
	for it in list.slice(0, 40):
		var p = it[0]
		var nm = UI.hb(5)
		nm.add_child(UI.flag(p.nat, 18))
		nm.add_child(UI.lbl_fill(G.SF.nm(p), 16, UI.TEXT))
		if p.ex != null:
			nm.add_child(UI.chip("YOURS" if p.ex.get("own", false) else "EX-PRO", Color(UI.GOLD, 0.16), UI.GOLD, 12))
		var pp = p
		var br = it[1]
		v.add_child(UI.trow([nm, short_job(br), UI.half_stars(G.SF.stars(it[2]), 14), arrow(G.SF.vs_mine(p, br)), G.money(p.wage)], [0, 74, 86, 22, -60],
			{"size": 16, "pad": 2, "cols": {1: UI.MUTED}, "tap": func(): detail(pp, br, refresh)}))
	if list.is_empty():
		v.add_child(UI.wrap("Nobody available for that job right now. New names come onto the market every week.", 16, UI.DIM))


static func short_job(r: String) -> String:
	return {"ass": "Assistant", "coach1": "Coach", "coach2": "Coach", "gk": "GK coach", "fit": "Fitness", "phys": "Physio", "youth": "Youth", "scout": "Scout"}[r]


static func arrow(d: float) -> Control:
	# green up / red down against the person you have in that job now
	if absf(d) < 0.25:
		return UI.lbl("=", 15, UI.DIM, "disp")
	return UI.icon("arrow-up" if d > 0 else "arrow-down", 16, UI.GREEN if d > 0 else UI.RED)


static func detail(p: Dictionary, role: String, after: Callable):
	var mine = int(p.club) == G.uc().id
	var build = func(v):
		var hd = UI.hb(10)
		hd.add_child(UI.flag(p.nat, 30))
		var tv = UI.vb(-4)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UI.lbl_fill(G.SF.nm(p), 26, UI.TEXT, "bold"))
		var sub = "%d · %s" % [G.SF.age(p), p.nat]
		if p.ex != null:
			sub += " · former %s (peak %d)%s" % [p.ex.pos, int(p.ex.ovr), (", " + str(p.ex.club)) if str(p.ex.club) != "" else ""]
		tv.add_child(UI.lbl_fill(sub, 16, UI.MUTED))
		hd.add_child(tv)
		var srow = UI.hb(8)
		srow.add_child(UI.half_stars(G.SF.stars(G.SF.rating(p, role)), 20))
		srow.add_child(UI.lbl("as %s · %s" % [G.SF.ROLE[role][0].to_lower(), G.SF.style(p)], 16, UI.MUTED))
		hd.add_child(srow)
		v.add_child(hd)
		var g = GridContainer.new()
		g.columns = 2
		g.add_theme_constant_override("h_separation", 24)
		for k in G.SF.ATTR:
			var kv = UI.kv(G.SF.ATTR_NAME[k], str(int(p.a[k])), UI.ovr_color(50 + int(p.a[k]) * 2), 17)
			kv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			g.add_child(kv)
		v.add_child(g)
		v.add_child(UI.caps("Rating by job", 15, UI.accent))
		var jr = UI.hb(6)
		for r in ["ass", "coach1", "gk", "fit", "phys", "youth", "scout"]:
			var lab = {"ass": "AST", "coach1": "COA", "gk": "GK", "fit": "FIT", "phys": "PHY", "youth": "YTH", "scout": "SCT"}[r]
			var rt = G.SF.rating(p, r)
			var stv = G.SF.stars(rt)
			jr.add_child(UI.chip("%s %s/5" % [lab, str(stv).trim_suffix(".0")], Color(UI.ovr_color(50 + int(rt * 2.4)), 0.16), UI.ovr_color(50 + int(rt * 2.4)), 14))
		v.add_child(jr)
		if mine:
			v.add_child(UI.kv("Contract", "%s a week until summer %d" % [G.money(p.wage), int(p.cend) + 1], UI.TEXT, 17))
			var row = UI.hb(8)
			var rn = UI.btn("Extend 2 years (+10%)", func():
				p.cend = int(p.cend) + 2
				p.wage = G.nice(int(p.wage * 1.1))
				UI.close_sheet()
				UI.toast("Contract extended", UI.GREEN)
				after.call(), "secondary", "file-text", 48)
			rn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(rn)
			var rl = UI.btn("Release (%s)" % G.money(G.SF.payoff(p)), func():
				UI.close_sheet()
				UI.confirm("Release %s?" % G.SF.nm(p), "His compensation of %s comes out of the transfer budget. The job stays empty until you hire someone." % G.money(G.SF.payoff(p)), "Release", func():
					G.SF.release(p)
					after.call(), true), "ghost", "", 48)
			rl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(rl)
			v.add_child(row)
			return
		# hiring
		var a = G.SF.ask(p, role)
		var cur = G.SF.who(role)
		v.add_child(UI.kv("Job", G.SF.ROLE[role][0], UI.TEXT, 17))
		var gain = UI.panel(Color(UI.GREEN if G.SF.vs_mine(p, role) >= 0 else UI.RED, 0.10), 10, 12, 8)
		var gv = UI.vb(0)
		gv.add_child(UI.caps("What changes", 14, UI.MUTED))
		gv.add_child(UI.lbl_fill("Now: %s" % G.SF.effect_at(role, G.SF.r(role)), 17, UI.MUTED))
		gv.add_child(UI.lbl_fill("With him: %s" % G.SF.effect_at(role, G.SF.rating(p, role)), 18, UI.GREEN if G.SF.vs_mine(p, role) >= 0 else UI.RED, "semi"))
		gain.add_child(gv)
		v.add_child(gain)
		v.add_child(UI.kv("He wants", "%s a week" % G.money(a.wage), UI.TEXT, 17))
		v.add_child(UI.kv("Chance he says yes", ["Slim", "Fair", "Good", "Very likely"][clampi(int(a.chance * 4.0), 0, 3)], UI.cond_color(a.chance * 100.0), 17))
		if cur != null:
			v.add_child(UI.wrap("%s leaves; his compensation of %s comes out of the transfer budget." % [G.SF.nm(cur), G.money(G.SF.payoff(cur))], 15, UI.AMBER))
		var hr = UI.hb(8)
		for yrs in [1, 2, 3]:
			var y = yrs
			var b = UI.btn("Offer %d year%s" % [y, "" if y == 1 else "s"], func():
				var why = G.SF.offer(p, role, y)
				UI.close_sheet()
				if why == "":
					UI.sfx("sign", -8.0)
					UI.toast("%s has joined your staff" % G.SF.nm(p), UI.GREEN)
				else:
					UI.sfx("error", -8.0)
					UI.toast(why, UI.RED)
				after.call(), "primary" if y == 2 else "secondary", "", 48)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hr.add_child(b)
		v.add_child(hr)
		if role == "coach1" or role == "coach2":
			var other = "coach2" if role == "coach1" else "coach1"
			v.add_child(UI.btn("Hire as the other coach instead", func():
				UI.close_sheet()
				detail(p, other, after), "ghost", "", 42))
	UI.sheet(G.SF.ROLE[role][0] if not mine else "Your staff", build)

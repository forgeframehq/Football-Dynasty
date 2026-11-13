extends "res://scripts/screens/screen.gd"
# Scouting: players being watched and a standing assignment for the scouting team.

var lg := -1
var line := -1
var young := true
# recruitment brief being written
var b_pos := "ST"
var b_age := 1
var b_fee := 2
var b_foot := 0
var b_style := false
var b_link := ""


func build():
	var s = G.s
	var c = G.uc()
	var sc = s.scout
	if lg < 0:
		lg = sc.assign.lg if sc.assign != null else c.lg
		line = sc.assign.line if sc.assign != null else -1
		young = sc.assign.young if sc.assign != null else true
	body.add_child(UI.topbar("Scouting"))
	UI.main.t_sub = "Network level %d · reports take %d days · %d of %d slots used" % [c.fac.scouting, G.OPS.scout_days(), sc.queue.size(), 1 + c.fac.scouting]
	var h = panes(10, 20)
	var a = pane(290, 5)
	h.add_child(a[0])
	var v = a[1]
	v.add_child(UI.caps("Standing assignment · %s" % ("active" if sc.assign != null else "none"), 15, UI.accent))
	var lr = UI.panel(UI.CARD2, 12, 12, 8, Color(1, 1, 1, 0.1))
	var lh = UI.hb(8)
	lh.add_child(UI.caps("League", 15, UI.MUTED))
	lh.add_child(UI.sp())
	lh.add_child(UI.lbl(s.leagues[lg].name, 20, UI.TEXT, "semi"))
	lh.add_child(UI.icon("chevron-right", 20, UI.MUTED))
	lr.add_child(lh)
	UI.tap(lr, _pick_league, true)
	v.add_child(lr)
	v.add_child(UI.seg(["Any", "GK", "DEF", "MID", "ATT"], line + 1, func(i):
		line = i - 1
		refresh(), 15, 6))
	v.add_child(UI.seg(["Under 23", "Any age"], 0 if young else 1, func(i):
		young = i == 0
		refresh(), 15, 6))
	v.add_child(UI.btn("Send scouts", func():
		G.OPS.set_assignment(lg, line, young)
		UI.toast("Scouts assigned to the %s" % s.leagues[lg].name, UI.GREEN)
		refresh(), "primary", "search", 46))
	if sc.assign != null:
		v.add_child(UI.wrap("Next report in %d days. Three players each time, added to your shortlist." % max(1, sc.next - s.day), 16, UI.DIM))
		v.add_child(UI.btn("Recall scouts", func():
			sc.assign = null
			refresh(), "ghost", "", 46))
	v.add_child(UI.wrap("Other clubs' players show a potential range until a report is filed. Scout anyone from his profile.", 16, UI.DIM))
	var b = pane(0, 2)
	h.add_child(b[0])
	v = b[1]
	v.add_child(UI.caps("Being watched", 15, UI.accent))
	var w = [34, 34, 0, -26, 44, -96]
	_brief_pane(h)
	if sc.queue.size() == 0:
		v.add_child(UI.lbl("Nobody at the moment.", 17, UI.DIM))
	for q in sc.queue:
		if s.players.has(q.pid):
			var p = s.players[q.pid]
			var pid = q.pid
			v.add_child(UI.trow([UI.ovr(p.ovr, 16), p.pos, G.pname(p), G.age(p), "Free" if p.club < 0 else s.clubs[p.club].short, "%d days" % max(1, q.done - s.day)], w,
				{"size": 18, "cols": {1: UI.MUTED, 4: UI.MUTED, 5: UI.AMBER}, "tap": func(): UI.main.open("player", {"pid": pid})}))
	v.add_child(UI.caps("Reports on file", 15, UI.accent))
	v.add_child(UI.trow(["Ovr", "Pos", "Player", "Age", "Club", "Pot · Value"], w, {"head": true}))
	var known = []
	for pid in sc.known:
		if s.players.has(pid) and s.players[pid].club != c.id:
			known.append(s.players[pid])
	known.sort_custom(func(x, y): return x.pot > y.pot)
	for i in min(40, known.size()):
		var p2 = known[i]
		var pid2 = p2.id
		v.add_child(UI.trow([UI.ovr(p2.ovr, 16), p2.pos, G.pname(p2), G.age(p2), "Free" if p2.club < 0 else s.clubs[p2.club].short, "%d · %s" % [p2.pot, G.money(G.value(p2))]], w,
			{"size": 18, "alt": i % 2 == 0, "cols": {1: UI.MUTED, 4: UI.MUTED, 5: UI.GREEN if p2.pot >= p2.ovr + 5 else UI.TEXT}, "tap": func(): UI.main.open("player", {"pid": pid2})}))
	if known.size() == 0:
		v.add_child(UI.wrap("No reports yet. Reports reveal a player's true potential.", 16, UI.DIM))


func _pick_league():
	var build_sheet = func(v):
		var country = ""
		for l in G.s.leagues:
			if l.country != country:
				country = l.country
				v.add_child(UI.caps(country, 19, UI.GOLD))
			var r = UI.panel(UI.CARD, 16, 18, 12, UI.accent if l.id == lg else UI.LINE)
			r.add_child(UI.lbl(l.name, 25, UI.TEXT, "disp"))
			var id = l.id
			UI.tap(r, func():
				lg = id
				UI.close_sheet()
				refresh())
			v.add_child(r)
	UI.sheet("Where to look", build_sheet)


# ---------------------------------------------------------------- recruitment brief

func _row(v: Control, label: String, node: Control):
	var r = UI.hb(8)
	var l = UI.lbl(label, 15, UI.MUTED)
	l.custom_minimum_size = Vector2(64, 0)
	r.add_child(l)
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_child(node)
	v.add_child(r)


func _link_opts() -> Array:
	var out = [["", "No link-up"]]
	for lid in G.s.user.links:
		if G.TC.LINKS.has(lid):
			var L = G.TC.LINKS[lid]
			out.append(["%s:a" % lid, "%s: %s" % [L.n, L.a.t.to_lower()]])
			out.append(["%s:b" % lid, "%s: %s" % [L.n, L.b.t.to_lower()]])
	return out


func _brief_pane(h: Control):
	# tell the chief scout what you need; he comes back with a ranked shortlist
	var s = G.s
	var c = G.uc()
	var sc = s.scout
	var a = pane(380, 4)
	h.add_child(a[0])
	var v = a[1]
	var res = sc.get("brief_res", null)
	if sc.has("brief"):
		v.add_child(UI.caps("Recruitment brief · out looking", 15, UI.accent))
		v.add_child(UI.wrap("Your chief scout is looking for: %s." % G.MK.brief_text(sc.brief), 17, UI.TEXT))
		v.add_child(UI.kv("Back in", "%d days" % max(1, int(sc.brief.done) - s.day), UI.AMBER, 17))
		v.add_child(UI.btn("Call him back", func():
			sc.erase("brief")
			refresh(), "ghost", "", 40))
	else:
		v.add_child(UI.caps("Recruitment brief", 15, UI.accent))
		var g = GridContainer.new()
		g.columns = 6
		g.add_theme_constant_override("h_separation", 4)
		g.add_theme_constant_override("v_separation", 4)
		for ps in G.MK.POSITIONS:
			var on = ps == b_pos
			var ch = UI.chip(ps, UI.accent if on else Color(1, 1, 1, 0.06), UI.on_color(UI.accent) if on else UI.MUTED, 15)
			ch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var pv = ps
			UI.tap(ch, func():
				b_pos = pv
				refresh(), true)
			g.add_child(ch)
		v.add_child(g)
		_row(v, "Age", UI.seg(["21", "24", "28", "Any"], b_age, func(i):
			b_age = i
			refresh(), 14, 5))
		_row(v, "Budget", UI.seg(["Quarter", "Half", "All", "Any"], b_fee, func(i):
			b_fee = i
			refresh(), 14, 5))
		_row(v, "Foot", UI.seg(["Any", "Left", "Right"], b_foot, func(i):
			b_foot = i
			refresh(), 14, 5))
		_row(v, "Style", UI.seg(["Any role", "Fits %s" % G.TC.STYLES[G.TC.style_of(c)].s], 1 if b_style else 0, func(i):
			b_style = i == 1
			refresh(), 14, 5))
		var opts = _link_opts()
		if opts.size() > 1:
			var cur = 0
			for i in opts.size():
				if opts[i][0] == b_link:
					cur = i
			var lr = UI.panel(Color(1, 1, 1, 0.05), 8, 10, 5)
			var lh = UI.hb(6)
			lh.add_child(UI.lbl_fill(opts[cur][1], 15, UI.TEXT if cur > 0 else UI.MUTED))
			lh.add_child(UI.icon("chevron-right", 16, UI.MUTED))
			lr.add_child(lh)
			UI.tap(lr, func():
				b_link = opts[(cur + 1) % opts.size()][0]
				refresh(), true)
			_row(v, "Link-up", lr)
		v.add_child(UI.btn("Send the chief scout · %d days" % max(2, G.OPS.scout_days() - 2), func():
			G.MK.brief_start({"pos": b_pos, "age": b_age, "fee": b_fee, "foot": b_foot, "style": b_style, "link": b_link})
			UI.toast("Chief scout sent out", UI.GREEN)
			refresh(), "primary", "user-round-search", 44))
	if res != null:
		v.add_child(UI.divider())
		v.add_child(UI.caps("His shortlist · %s" % G.fmt_date(int(res.day)), 15, UI.accent))
		v.add_child(UI.lbl_fill(str(res.text), 13, UI.DIM))
		var w = [34, 0, -26, 44, -66]
		var i = 0
		for pid in res.ids:
			if not s.players.has(pid):
				continue
			var p = s.players[pid]
			var id = pid
			v.add_child(UI.trow([UI.ovr(p.ovr, 15), G.pname(p), G.age(p), "Free" if p.club < 0 else s.clubs[p.club].short, G.money(G.TR.asking_price(p)) if p.club >= 0 else "Free"], w,
				{"size": 17, "alt": i % 2 == 0, "pad": 3, "cols": {2: UI.MUTED, 3: UI.MUTED, 4: UI.GREEN if p.club < 0 or G.TR.asking_price(p) <= c.budget else UI.AMBER}, "tap": func(): UI.main.open("player", {"pid": id})}))
			i += 1
		if res.ids.is_empty():
			v.add_child(UI.lbl("Nobody met the brief.", 15, UI.DIM))

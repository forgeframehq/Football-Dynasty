extends "res://scripts/screens/screen.gd"
# Career hub: six panels (next match, league, to-do, fixtures, club, news).


func build():
	var s = G.s
	if s.review != null:
		UI.main.call_deferred("root", "review")
		return
	if s.user.sacked:
		UI.main.call_deferred("root", "jobs", {"sacked": true})
		return
	var c = G.uc()
	body.add_child(UI.clubbar())
	var g = UI.vb(14)
	g.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var m = UI.margin(g, 20, 4, 20, 14)
	m.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(m)
	var r1 = UI.hb(14)
	r1.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var r2 = UI.hb(14)
	r2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	g.add_child(r1)
	g.add_child(r2)
	r1.add_child(_next_match(c))
	r1.add_child(_league(c))
	r1.add_child(_todo(c))
	r2.add_child(_fixtures(c))
	r2.add_child(_club(c))
	r2.add_child(_news())


func _card(title: String, right := "", cb = null, hot := false) -> Array:
	var p = UI.panel(UI.CARD, 18, 0, 0, Color(UI.accent, 0.5) if hot else UI.LINE)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	p.clip_contents = true
	var v = UI.vb(0)
	var head = UI.panel(Color(1, 1, 1, 0.05), 0, 16, 7)
	var hh = UI.hb(8)
	hh.add_child(UI.caps(title, 20, UI.accent if hot else UI.TEXT))
	hh.add_child(UI.sp())
	if right != "":
		hh.add_child(UI.caps(right, 17, UI.MUTED))
	if cb != null:
		hh.add_child(UI.icon("chevron-right", 20, UI.DIM))
	head.add_child(hh)
	v.add_child(head)
	var inner = UI.vb(8)
	inner.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(UI.margin(inner, 16, 10, 16, 10))
	v.get_child(1).size_flags_vertical = Control.SIZE_EXPAND_FILL
	p.add_child(v)
	if cb != null:
		UI.tap(p, cb)
	return [p, inner]


func _next_match(c: Dictionary) -> Control:
	var s = G.s
	var f = G.next_user_fixture()
	var today = f != null and f.day == s.day
	var k = _card("Match day" if today else "Next match", G.fx_caption(f) if f != null else "", func(): UI.main.root("tactics"), true)
	var v = k[1]
	if f == null:
		v.add_child(UI.wrap("No more fixtures this season. Continue to the season review.", 22, UI.MUTED))
		return k[0]
	var hc = s.clubs[f.h]
	var ac = s.clubs[f.a]
	var mh = UI.hb(6)
	mh.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mh.add_child(_side(hc))
	var mid = UI.vb(0)
	mid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var vs = UI.lbl("VS", 38, UI.TEXT, "xbold")
	vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mid.add_child(vs)
	var d = f.day - s.day
	var dl = UI.caps("Today" if today else ("Tomorrow" if d == 1 else "In %d days" % d), 17, UI.accent)
	dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mid.add_child(dl)
	mh.add_child(mid)
	mh.add_child(_side(ac))
	v.add_child(mh)
	var venue = UI.caps("%s · %s · %s" % [G.fmt_date(f.day), "Home" if f.h == c.id else "Away", hc.stadium if hc.stadium != "" else hc.name], 16, UI.DIM)
	venue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(venue)
	return k[0]


func _side(c: Dictionary) -> Control:
	var v = UI.vb(4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(UI.center(UI.badge(c, 78)))
	var l = UI.lbl(c.name.to_upper(), 21, UI.TEXT, "disp")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.clip_text = true
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(l)
	var pos = UI.caps("%s · %d pts" % [G.LG.ordinal(G.LG.position(c.id)), c.t.pts], 15, UI.MUTED)
	pos.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(pos)
	var fd = UI.form_dots(c.form, 10)
	fd.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(fd)
	return v


func _league(c: Dictionary) -> Control:
	var s = G.s
	var t = G.LG.table(c.lg)
	var pos = t.find(c.id) + 1
	var k = _card(s.leagues[c.lg].name, "%s · %d pts" % [G.LG.ordinal(pos), c.t.pts], func(): UI.main.root("table", {"lg": c.lg}))
	var v = k[1]
	v.add_theme_constant_override("separation", 5)
	var from = clampi(pos - 3, 0, max(0, t.size() - 6))
	for i in range(from, min(t.size(), from + 6)):
		var tc = s.clubs[t[i]]
		var me = tc.id == c.id
		var row = UI.panel(Color(UI.accent, 0.14) if me else Color(0, 0, 0, 0), 8, 8, 3)
		var r = UI.hb(10)
		var pn = UI.lbl(str(i + 1), 20, UI.accent if me else UI.MUTED, "disp")
		pn.custom_minimum_size = Vector2(26, 0)
		r.add_child(pn)
		r.add_child(UI.badge(tc, 26))
		r.add_child(UI.lbl_fill(tc.name, 21, UI.TEXT if me else UI.MUTED, "semi" if me else "body"))
		var pl = UI.lbl(str(tc.t.p), 19, UI.DIM)
		pl.custom_minimum_size = Vector2(26, 0)
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		r.add_child(pl)
		var gd = UI.lbl("%+d" % (tc.t.gf - tc.t.ga), 19, UI.DIM)
		gd.custom_minimum_size = Vector2(36, 0)
		gd.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		r.add_child(gd)
		var pts = UI.lbl(str(tc.t.pts), 22, UI.TEXT if me else UI.MUTED, "disp")
		pts.custom_minimum_size = Vector2(34, 0)
		pts.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		r.add_child(pts)
		row.add_child(r)
		v.add_child(row)
	return k[0]


func todo_items(c: Dictionary) -> Array:
	var s = G.s
	var a: Array = []
	var f = G.user_fixture_today()
	var out = 0
	for pid in c.xi:
		if not G.available(s.players[pid]):
			out += 1
	if out > 0:
		a.append(["bandage", "%d unavailable player%s in your XI" % [out, "" if out == 1 else "s"], UI.RED, func(): UI.main.root("tactics")])
	elif f != null:
		a.append(["layout-grid", "Check your team for today's match", UI.accent, func(): UI.main.root("tactics")])
	var n = G.unread()
	if n > 0:
		a.append(["mail", "%d unread message%s" % [n, "" if n == 1 else "s"], UI.accent, func(): UI.main.root("inbox")])
	var mine = 0
	for o in s.offers:
		if s.players.has(o.pid) and s.players[o.pid].club == c.id:
			mine += 1
	if mine > 0:
		a.append(["handshake", "%d transfer offer%s to answer" % [mine, "" if mine == 1 else "s"], UI.AMBER, func():
			G.ui.tr_tab = 2
			UI.main.root("transfers")])
	var exp = 0
	for pid in c.players:
		var p = s.players[pid]
		if p.cend <= s.season + 1 and p.get("loan", -1) < 0 and G.status_of(p) <= 1:
			exp += 1
	if exp > 0:
		a.append(["file-text", "%d first-team contract%s ending in June" % [exp, "" if exp == 1 else "s"], UI.AMBER, func(): UI.main.root("lists", {"kind": "contracts", "grp": "club"})])
	var unhappy = 0
	for pid in c.players:
		if s.players[pid].get("unhappy", 0) > 0:
			unhappy += 1
	if unhappy > 0:
		a.append(["heart", "%d unhappy player%s" % [unhappy, "" if unhappy == 1 else "s"], UI.RED, func(): UI.main.root("squad")])
	if c.get("build") == null or c.build.is_empty():
		a.append(["hammer", "No building work in progress", UI.MUTED, func(): UI.main.root("campus")])
	if s.scout.queue.is_empty() and G.window_open():
		a.append(["binoculars", "Your scouts have nothing to do", UI.MUTED, func(): UI.main.root("transfers")])
	return a


func _todo(c: Dictionary) -> Control:
	var items = todo_items(c)
	var k = _card("To do", "%d item%s" % [items.size(), "" if items.size() == 1 else "s"])
	var v = k[1]
	v.add_theme_constant_override("separation", 4)
	if items.is_empty():
		v.add_child(UI.wrap("Nothing needs you right now. Press Continue.", 21, UI.MUTED))
	for it in items.slice(0, 6):
		var r = UI.panel(Color(1, 1, 1, 0.04), 10, 10, 6)
		var h = UI.hb(10)
		h.add_child(UI.icon(it[0], 22, it[2]))
		h.add_child(UI.lbl_fill(it[1], 20, UI.TEXT))
		h.add_child(UI.icon("chevron-right", 18, UI.DIM))
		r.add_child(h)
		UI.tap(r, it[3], true)
		v.add_child(r)
	return k[0]


func _fixtures(c: Dictionary) -> Control:
	var s = G.s
	var k = _card("Fixtures & results", "", func(): UI.main.root("fixtures"))
	var v = k[1]
	v.add_theme_constant_override("separation", 4)
	var all = G.club_fixtures(c.id)
	var idx = all.size()
	for i in all.size():
		if not all[i].played:
			idx = i
			break
	for i in range(max(0, idx - 2), min(all.size(), idx + 4)):
		var f = all[i]
		var home = f.h == c.id
		var oc = s.clubs[f.a if home else f.h]
		var r = UI.hb(10)
		var d = UI.caps(G.fmt_date(f.day).substr(4), 17, UI.DIM)
		d.custom_minimum_size = Vector2(64, 0)
		r.add_child(d)
		r.add_child(UI.badge(oc, 26))
		r.add_child(UI.lbl_fill(oc.name, 21, UI.TEXT if not f.played else UI.MUTED))
		r.add_child(UI.lbl("H" if home else "A", 19, UI.MUTED, "disp"))
		var tag = "FR" if f.get("fr", false) else (str(f.comp).to_upper() if f.get("comp", "") != "" else s.leagues[f.lg].short)
		var tl = UI.lbl(tag, 17, UI.DIM, "cond")
		tl.custom_minimum_size = Vector2(44, 0)
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		r.add_child(tl)
		if f.played:
			var us = f.hg if home else f.ag
			var them = f.ag if home else f.hg
			var col = UI.GREEN if us > them else (UI.RED if us < them else UI.MUTED)
			r.add_child(UI.chip("%d-%d" % [us, them], Color(col, 0.16), col, 19, 54))
		else:
			r.add_child(UI.sp(54, 0))
		v.add_child(r)
	return k[0]


func _club(c: Dictionary) -> Control:
	var s = G.s
	var k = _card("Club", "", func(): UI.main.root("board"))
	var v = k[1]
	v.add_theme_constant_override("separation", 6)
	var inj = 0
	for pid in c.players:
		if s.players[pid].inj > 0:
			inj += 1
	var oh = UI.hb(8)
	oh.add_child(UI.icon("target", 22, UI.accent))
	oh.add_child(UI.lbl_fill(s.user.obj.text, 22, UI.TEXT, "semi"))
	v.add_child(oh)
	var ch = UI.hb(10)
	ch.add_child(UI.lbl("Board confidence", 19, UI.MUTED))
	ch.add_child(UI.bar(s.user.conf / 100.0, UI.cond_color(s.user.conf + 20), 8))
	ch.add_child(UI.lbl("%d%%" % int(s.user.conf), 20, UI.cond_color(s.user.conf + 20), "disp"))
	v.add_child(ch)
	v.add_child(UI.divider())
	v.add_child(UI.kv("Transfer budget", G.money(c.budget), UI.GREEN))
	v.add_child(UI.kv("Wage room", "%s / wk" % G.money(max(0, c.wage_budget - G.squad_wages(c)))))
	v.add_child(UI.kv("Injured", str(inj), UI.RED if inj > 0 else UI.TEXT))
	var b = c.get("build")
	if b != null and not b.is_empty():
		v.add_child(UI.kv("Building", "%s · %d days" % [str(b.key).capitalize(), max(1, b.done - s.day)], UI.AMBER))
	return k[0]


func _news() -> Control:
	var s = G.s
	var k = _card("Around the leagues")
	var v = k[1]
	v.add_theme_constant_override("separation", 7)
	if s.news.is_empty():
		v.add_child(UI.wrap("No news yet. The season starts in August.", 21, UI.MUTED))
	for i in min(5, s.news.size()):
		var item = s.news[i]
		var r = UI.hb(10)
		var d = UI.caps(G.fmt_date(item.day).substr(4), 16, UI.DIM)
		d.custom_minimum_size = Vector2(60, 0)
		r.add_child(d)
		var t = UI.wrap(item.text, 19, UI.MUTED)
		t.max_lines_visible = 2
		r.add_child(t)
		v.add_child(r)
	return k[0]

extends "res://scripts/screens/screen.gd"
# League table: the whole division on one screen, with form, zones, scorers and the next round alongside.

const ZONE_COL = {"cl": Color("4da3ff"), "eu": Color("f6ad3c"), "up": Color("2ee59d"), "po": Color("29c7c7"), "rpo": Color("f08a5d"), "down": Color("ff5c72"), "": Color(0, 0, 0, 0)}
const ZONE_TXT = {"cl": "Champions League", "eu": "Europe", "up": "Promotion", "po": "Play-offs", "rpo": "Relegation play-off", "down": "Relegation"}
const W = [6, 26, 26, 0, -28, -28, -28, -28, -34, -34, -38, -40, 84]

var lg := -1


func build():
	var s = G.s
	if lg < 0:
		lg = args.get("lg", G.uc().lg)
	var l = s.leagues[lg]
	var sw = UI.panel(Color(1, 1, 1, 0.06), 18, 16, 12)
	var swh = UI.hb(6)
	swh.add_child(UI.caps("Leagues", 20, UI.TEXT))
	swh.add_child(UI.icon("chevron-right", 22, UI.MUTED))
	sw.add_child(swh)
	var on_pick = func(i):
		lg = i
		refresh()
	UI.tap(sw, func(): pick_league(on_pick), true)
	body.add_child(UI.topbar(l.name, true, sw))
	var t = G.LG.table(lg)
	UI.main.t_sub = "%s · tier %d · %d clubs" % [l.country, l.tier, t.size()]
	var h = panes(12, 20)
	var a = pane(0, 2)
	a[0].size_flags_stretch_ratio = 2.2
	h.add_child(a[0])
	var v = a[1]
	v.add_child(UI.trow(["", "#", "", "Club", "P", "W", "D", "L", "GF", "GA", "GD", "Pts", "Form"], W, {"head": true}))
	var seen = []
	var goals = 0
	var games = 0
	for i in t.size():
		var c = s.clubs[t[i]]
		var me = c.id == s.user.club
		var z = G.LG.zone_of(lg, i + 1, t.size())
		if z != "" and not (z in seen):
			seen.append(z)
		var zb = ColorRect.new()
		zb.color = ZONE_COL[z]
		zb.custom_minimum_size = Vector2(6, 24)
		goals += c.t.gf
		games += c.t.p
		var cid = c.id
		v.add_child(UI.trow([zb, str(i + 1), UI.badge(c, 24), c.name, c.t.p, c.t.w, c.t.d, c.t.l, c.t.gf, c.t.ga, "%+d" % (c.t.gf - c.t.ga), c.t.pts, UI.form_dots(c.form.slice(-5), 12)], W,
			{"hi": me, "alt": i % 2 == 0, "bold": 3, "cols": {11: UI.TEXT, 1: UI.MUTED}, "pad": 3, "tap": func(): UI.main.open("clubview", {"cid": cid})}))
	var b = pane(0, 4)
	h.add_child(b[0])
	v = b[1]
	v.add_child(UI.caps("Zones", 15, UI.accent))
	for z in seen:
		var lh = UI.hb(8)
		var dot = UI.panel(ZONE_COL[z], 6, 0, 0)
		dot.custom_minimum_size = Vector2(12, 12)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		lh.add_child(dot)
		lh.add_child(UI.lbl(ZONE_TXT[z], 17, UI.TEXT))
		v.add_child(lh)
	v.add_child(UI.caps("Top scorers", 15, UI.accent))
	var sc = []
	for cid in l.clubs:
		for pid in s.clubs[cid].players:
			var p = s.players[pid]
			if p.ss.g > 0:
				sc.append(p)
	sc.sort_custom(func(x, y): return x.ss.g > y.ss.g)
	if sc.size() == 0:
		v.add_child(UI.lbl("Season not started", 17, UI.DIM))
	for i in min(5, sc.size()):
		var p = sc[i]
		var pid2 = p.id
		v.add_child(UI.trow([G.pname(p), s.clubs[p.club].short, p.ss.g], [0, 44, -28], {"size": 18, "alt": i % 2 == 0, "cols": {1: UI.MUTED}, "tap": func(): UI.main.open("player", {"pid": pid2})}))
	v.add_child(UI.caps("Next round", 15, UI.accent))
	var shown = 0
	var up = []
	for f in s.fixtures:
		if f.get("lg", -1) == lg and not f.played and f.day >= s.day and not f.has("comp"):
			up.append(f)
	up.sort_custom(func(x, y): return x.day < y.day)
	for f in up:
		if f.day > up[0].day + 3 or shown >= 10:
			break
		var mine = f.h == s.user.club or f.a == s.user.club
		v.add_child(UI.trow([s.clubs[f.h].short, "v", s.clubs[f.a].short, G.fmt_date(f.day)], [52, 16, 52, 0], {"size": 18, "hi": mine, "cols": {1: UI.DIM, 3: UI.MUTED}}))
		shown += 1
	if shown == 0:
		v.add_child(UI.lbl("No league matches left", 17, UI.DIM))
	v.add_child(UI.caps("Division", 15, UI.accent))
	v.add_child(UI.kv("Goals per game", "%.2f" % (goals / float(max(1, games))) if games > 0 else "-"))
	v.add_child(UI.kv("Leaders", s.clubs[t[0]].short))


static func pick_league(cb: Callable):
	var build_sheet = func(v):
		var country = ""
		for l in G.s.leagues:
			if l.roe:
				continue
			if l.country != country:
				country = l.country
				v.add_child(UI.caps(country, 20, UI.GOLD))
			var r = UI.panel(UI.CARD, 16, 18, 10, UI.LINE)
			var h = UI.hb(10)
			h.add_child(UI.lbl_fill(l.name, 24, UI.TEXT, "disp"))
			h.add_child(UI.caps("Tier %d" % l.tier, 18, UI.DIM))
			r.add_child(h)
			var id = l.id
			UI.tap(r, func():
				UI.close_sheet()
				cb.call(id))
			v.add_child(r)
	UI.sheet("Select league", build_sheet)

extends "res://scripts/screens/screen.gd"
# Trophy room: the manager's trophies, the club's honours and the roll of honour.


func build():
	var s = G.s
	var u = s.user
	var c = G.uc()
	body.add_child(UI.topbar("Trophy room"))
	var v = content(12)
	v.add_child(UI.section("Your trophies", str(u.trophies.size())))
	if u.trophies.size() == 0:
		var e = UI.card()
		var ev = UI.vb(8)
		var ic = UI.icon("trophy", 72, Color(1, 1, 1, 0.12))
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		ev.add_child(ic)
		var el = UI.wrap("The cabinet is empty. Win the league, a cup or a European trophy and it will be displayed here.", 22, UI.MUTED)
		el.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ev.add_child(el)
		e.add_child(ev)
		v.add_child(e)
	else:
		var grid = GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 12)
		grid.add_theme_constant_override("v_separation", 12)
		grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for t in u.trophies:
			var big = t.contains("Champions League") or t.contains("Premier League") or t.contains("LaLiga") or t.contains("Serie A") or t.contains("Bundesliga") or t.contains("Ligue 1")
			var col = UI.GOLD if big else Color("c9d2e0")
			var p = UI.panel(Color(col, 0.08), 22, 16, 18, Color(col, 0.4))
			p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var pv = UI.vb(6)
			var ic = UI.icon("trophy", 64, col)
			ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			pv.add_child(ic)
			var parts = t.rsplit(" ", true, 1)
			var nl = UI.wrap(parts[0].to_upper(), 23, UI.TEXT, "disp")
			nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			pv.add_child(nl)
			var sl = UI.caps(parts[1] if parts.size() > 1 else "", 19, col)
			sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			pv.add_child(sl)
			p.add_child(pv)
			grid.add_child(p)
		v.add_child(grid)
	var hon = s.get("honours", {}).get(c.id, [])
	v.add_child(UI.section("%s honours" % c.name, "this career"))
	if hon.size() == 0:
		v.add_child(UI.wrap("Nothing yet in this career.", 22, UI.DIM))
	else:
		var counts = {}
		for h in hon:
			if not counts.has(h[0]):
				counts[h[0]] = []
			counts[h[0]].append(G.season_name(h[1]))
		var card = UI.card()
		var cv = UI.vb(10)
		for k in counts:
			var r = UI.hb(12)
			r.add_child(UI.icon("trophy", 28, UI.GOLD))
			var tv = UI.vb(0)
			tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tv.add_child(UI.lbl(k, 25, UI.TEXT, "semi"))
			tv.add_child(UI.wrap(", ".join(counts[k]), 19, UI.MUTED))
			r.add_child(tv)
			r.add_child(UI.lbl("×%d" % counts[k].size(), 30, UI.GOLD, "xbold"))
			cv.add_child(r)
		card.add_child(cv)
		v.add_child(card)
	if s.history.size() > 0:
		v.add_child(UI.section("Career"))
		var t = UI.hb(10)
		var titles = 0
		var promos = 0
		for h in s.history:
			if h.note == "Champions":
				titles += 1
			if h.note == "Promoted":
				promos += 1
		t.add_child(UI.stat_tile("Seasons", str(s.history.size())))
		t.add_child(UI.stat_tile("League titles", str(titles), UI.GOLD if titles > 0 else UI.TEXT))
		t.add_child(UI.stat_tile("Promotions", str(promos)))
		t.add_child(UI.stat_tile("Win rate", "%d%%" % int(100.0 * u.w / max(1, u.p))))
		v.add_child(t)
	if s.champs.size() > 0:
		v.add_child(UI.section("Roll of honour"))
		for ch in s.champs:
			var cc = UI.card()
			var cv = UI.vb(6)
			cv.add_child(UI.caps(G.season_name(ch.season), 22, UI.accent))
			for l in s.leagues:
				if l.tier == 1 and not l.roe and ch.c.has(l.id):
					cv.add_child(UI.kv(l.name, ch.c[l.id]))
			cc.add_child(cv)
			v.add_child(cc)

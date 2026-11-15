extends "res://scripts/screens/screen.gd"
# World Leagues: every league in the game by continent, with the leader, the top scorer and your scouting coverage.
# Tap a league for its table.

var cont := "Europe"


func build():
	var s = G.s
	UI.main.t_title = "World Leagues"
	var n = 0
	for l in s.leagues:
		if not l.roe or l.has("cont"):
			n += 1
	UI.main.t_sub = "%d leagues · %d clubs · %d players" % [n, s.clubs.size(), s.players.size()]
	var bar = UI.seg(G.WD.CONTINENTS, G.WD.CONTINENTS.find(cont), func(i):
		cont = G.WD.CONTINENTS[i]
		refresh(), 15, 5)
	var row = UI.hb(10)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(bar)
	var open_now = can_swap()
	row.add_child(UI.btn("Playable %d of 5%s" % [G.WD.playable().size(), " · change now" if open_now else ""], func(): playable_sheet(), "gold" if open_now else "secondary", "globe", 44))
	body.add_child(UI.margin(row, 20, 0, 20, 4))
	var f = content(0, 0)
	for l in s.leagues:
		if l.clubs.size() < 4 or (l.roe and not l.has("cont")):
			continue
		var lc = l.get("cont", "Europe")
		if lc != cont:
			continue
		f.add_child(_card(l))


func _card(l: Dictionary) -> Control:
	var s = G.s
	var t = G.LG.table(l.id)
	var pc = UI.panel(UI.CARD, 12, 14, 10, UI.accent if l.id == G.uc().lg else UI.LINE)
	var v = UI.vb(3)
	var top = UI.hb(8)
	top.add_child(UI.flag(G.WD.nat_of(l.country), 26))
	var tv = UI.vb(-4)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(UI.lbl_fill(l.name, 20, UI.TEXT, "bold"))
	tv.add_child(UI.lbl_fill("%s · tier %d · %d clubs%s" % [l.country, int(l.tier), l.clubs.size(), " · quick results" if l.get("bg", false) else ""], 14, UI.DIM))
	top.add_child(tv)
	v.add_child(top)
	for i in min(3, t.size()):
		var c = s.clubs[t[i]]
		var r = UI.hb(6)
		r.add_child(UI.lbl("%d" % (i + 1), 15, UI.DIM, "disp"))
		r.add_child(UI.badge(c, 20))
		r.add_child(UI.lbl_fill(c.name, 16, UI.TEXT))
		r.add_child(UI.lbl("%d pts" % c.t.pts, 15, UI.MUTED, "semi"))
		v.add_child(r)
	var ts = G.LG.top_scorer(l.id)
	if ts != null and ts.ss.g > 0:
		v.add_child(UI.lbl_fill("Top scorer: %s (%s) %d" % [G.pname(ts), s.clubs[ts.club].short, ts.ss.g], 14, UI.GOLD))
	if l.has("cont"):
		var hid = 0
		var tot = 0
		for cid in l.clubs:
			for pid in s.clubs[cid].players:
				tot += 1
				if G.WD.hidden(s.players[pid]):
					hid += 1
		v.add_child(UI.lbl_fill("Scouted: %d of %d players" % [tot - hid, tot], 14, UI.GREEN if hid < tot else UI.DIM))
	pc.add_child(v)
	var id = l.id
	UI.tap(pc, func(): UI.main.open("table", {"lg": id}))
	return pc


# ---------------------------------------------------------------- playable nations

static func can_swap() -> bool:
	# the playable nations can be changed from the end of the season until four weeks into the new one
	return G.s.day <= int(G.s.user.get("swap_until", -1))


static func nations() -> Array:
	# every nation with a league programme, once: [country key as the leagues store it, flag/display name]
	var out = []
	var seen = {}
	for l in G.s.leagues:
		if l.clubs.size() < 4 or (l.roe and not l.has("cont")) or seen.has(l.country):
			continue
		seen[l.country] = true
		out.append([l.country, G.WD.nat_of(l.country)])
	return out


static func playable_sheet():
	var edit = can_swap()
	var mine = G.s.leagues[G.uc().lg].country
	var build = func(v):
		v.add_child(UI.wrap(("Choose up to five nations for next season's full match engine. Your club's nation always stays. The rest of the world plays quick results." if edit
			else "These nations use the full match engine. You can change them at the end of each season (for four weeks into the new one)."), 16, UI.MUTED))
		var cur = G.WD.playable()
		var g = GridContainer.new()
		g.columns = 4
		g.add_theme_constant_override("h_separation", 8)
		g.add_theme_constant_override("v_separation", 6)
		for n in nations():
			var key = n[0]
			var on = key in cur or key == mine
			var b = UI.panel(Color(UI.GOLD, 0.2) if on else Color(1, 1, 1, 0.05), 10, 10, 6, UI.GOLD if on else Color(0, 0, 0, 0))
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var bh = UI.hb(8)
			bh.add_child(UI.flag(n[1], 26))
			bh.add_child(UI.lbl_fill(n[1], 16, UI.TEXT if on else UI.MUTED, "semi"))
			if key == mine:
				bh.add_child(UI.chip("YOU", Color(UI.GOLD, 0.2), UI.GOLD, 12))
			b.add_child(bh)
			if edit:
				UI.tap(b, func():
					if key == mine:
						return
					var now = G.WD.playable()
					if key in now:
						now.erase(key)
					elif now.size() < 5:
						now.append(key)
					else:
						UI.toast("Five nations at most. Switch one off first.", UI.AMBER)
						return
					if not (mine in now):
						now.append(mine)
					G.WD.set_playable(now)
					UI.close_sheet()
					playable_sheet()
					if UI.main.stack.size() > 0:
						UI.main.stack[-1].refresh(), true)
			g.add_child(b)
		v.add_child(g)
	UI.sheet("Playable nations", build)

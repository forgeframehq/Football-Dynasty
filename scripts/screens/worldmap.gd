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
	body.add_child(UI.margin(bar, 20, 0, 20, 4))
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

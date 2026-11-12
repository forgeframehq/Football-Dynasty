extends "res://scripts/screens/screen.gd"
# Scouting: players being watched and a standing assignment for the scouting team.

var lg := -1
var line := -1
var young := true


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
	var a = pane(330, 6)
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
		refresh(), 17))
	v.add_child(UI.seg(["Under 23", "Any age"], 0 if young else 1, func(i):
		young = i == 0
		refresh(), 17))
	v.add_child(UI.btn("Send scouts", func():
		G.OPS.set_assignment(lg, line, young)
		UI.toast("Scouts assigned to the %s" % s.leagues[lg].name, UI.GREEN)
		refresh(), "primary", "search", 54))
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
	var w = [34, 34, 0, -26, 44, -70]
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

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
	var v = content(12)
	var t = UI.hb(10)
	t.add_child(UI.stat_tile("Network", "Level %d" % c.fac.scouting))
	t.add_child(UI.stat_tile("Report time", "%d days" % G.OPS.scout_days()))
	t.add_child(UI.stat_tile("Watching", "%d / %d" % [sc.queue.size(), 1 + c.fac.scouting]))
	v.add_child(t)
	v.add_child(UI.wrap("Other clubs' players show only a potential range until your scouts have filed a report. Scout a player from his profile, or give the team a standing assignment below.", 21, UI.MUTED))
	v.add_child(UI.section("Being watched"))
	if sc.queue.size() == 0:
		v.add_child(UI.wrap("Nobody at the moment.", 22, UI.DIM))
	for q in sc.queue:
		if s.players.has(q.pid):
			var pid = q.pid
			v.add_child(UI.player_row(s.players[q.pid], func(): UI.main.open("player", {"pid": pid}), "report in %d days" % max(1, q.done - s.day)))
	v.add_child(UI.section("Standing assignment", "active" if sc.assign != null else "none"))
	var card = UI.card()
	var cv = UI.vb(10)
	var lr = UI.panel(UI.CARD2, 16, 16, 12, Color(1, 1, 1, 0.1))
	var lh = UI.hb(8)
	lh.add_child(UI.caps("League", 19, UI.MUTED))
	lh.add_child(UI.sp())
	lh.add_child(UI.lbl(s.leagues[lg].name, 26, UI.TEXT, "disp"))
	lh.add_child(UI.icon("chevron-right", 22, UI.MUTED))
	lr.add_child(lh)
	UI.tap(lr, _pick_league, true)
	cv.add_child(lr)
	cv.add_child(UI.seg(["Any", "GK", "DEF", "MID", "ATT"], line + 1, func(i):
		line = i - 1
		refresh(), 20))
	cv.add_child(UI.seg(["Under 23 only", "Any age"], 0 if young else 1, func(i):
		young = i == 0
		refresh(), 20))
	cv.add_child(UI.btn("Send scouts", func():
		G.OPS.set_assignment(lg, line, young)
		UI.toast("Scouts assigned to the %s" % s.leagues[lg].name, UI.GREEN)
		refresh(), "primary", "search", 72))
	if sc.assign != null:
		cv.add_child(UI.caps("Next report in %d days · three players each time, added to your shortlist" % max(1, sc.next - s.day), 18, UI.DIM))
		cv.add_child(UI.btn("Recall scouts", func():
			sc.assign = null
			refresh(), "ghost", "", 60))
	card.add_child(cv)
	v.add_child(card)


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

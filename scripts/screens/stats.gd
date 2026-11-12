extends "res://scripts/screens/screen.gd"
# League leaderboards: goals, assists, average rating, clean sheets.

const KINDS = ["Goals", "Assists", "Rating", "Clean sheets"]

var lg := -1
var kind := 0


func build():
	var s = G.s
	if lg < 0:
		lg = args.get("lg", G.uc().lg)
	var sw = UI.panel(Color(1, 1, 1, 0.06), 18, 16, 12)
	var swh = UI.hb(6)
	swh.add_child(UI.caps("Leagues", 20, UI.TEXT))
	swh.add_child(UI.icon("chevron-right", 22, UI.MUTED))
	sw.add_child(swh)
	var on_pick = func(i):
		lg = i
		refresh()
	UI.tap(sw, func(): preload("res://scripts/screens/table.gd").pick_league(on_pick), true)
	body.add_child(UI.topbar("Player stats", true, sw))
	var top = UI.vb(8)
	top.add_child(UI.caps(s.leagues[lg].name, 22, UI.accent))
	top.add_child(UI.seg(KINDS, kind, func(i):
		kind = i
		refresh(), 20))
	body.add_child(UI.margin(top, 24, 0, 24, 12))
	var v = content(8)
	var list = []
	var min_apps = 1
	for cid in s.leagues[lg].clubs:
		min_apps = max(min_apps, int(s.clubs[cid].t.p * 0.5))
	for cid in s.leagues[lg].clubs:
		for pid in s.clubs[cid].players:
			var p = s.players[pid]
			var val = 0.0
			match kind:
				0: val = p.ss.g
				1: val = p.ss.a
				2: val = G.avg_rating(p) if p.ss.ap >= min_apps else 0.0
				3: val = p.ss.cs if p.pos == "GK" else 0
			if val > 0:
				list.append([val, p])
	list.sort_custom(func(a, b): return a[0] > b[0] if a[0] != b[0] else a[1].ss.ap < b[1].ss.ap)
	if list.size() == 0:
		v.add_child(UI.wrap("No matches have been played yet.", 23, UI.MUTED))
	for i in min(30, list.size()):
		var p = list[i][1]
		var c = s.clubs[p.club]
		var me = p.club == s.user.club
		var r = UI.panel(Color(UI.accent, 0.12) if me else UI.CARD, 16, 14, 10, Color(UI.accent, 0.5) if me else UI.LINE)
		var h = UI.hb(12)
		var rk = UI.lbl(str(i + 1), 24, UI.GOLD if i < 3 else UI.MUTED, "disp")
		rk.custom_minimum_size = Vector2(34, 0)
		rk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		h.add_child(rk)
		h.add_child(UI.badge(c, 40))
		var tv = UI.vb(0)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UI.lbl_fill(G.pname(p), 25, UI.TEXT, "semi"))
		tv.add_child(UI.lbl_fill("%s · %s · %d apps" % [p.pos, c.name, p.ss.ap], 19, UI.MUTED))
		h.add_child(tv)
		h.add_child(UI.lbl("%.2f" % list[i][0] if kind == 2 else str(int(list[i][0])), 34, UI.TEXT, "xbold"))
		r.add_child(h)
		var pid = p.id
		UI.tap(r, func(): UI.main.open("player", {"pid": pid}))
		v.add_child(r)

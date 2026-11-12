extends "res://scripts/screens/screen.gd"
# League leaderboards, all four side by side.

const KINDS = ["Goals", "Assists", "Average rating", "Clean sheets"]

var lg := -1


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
	UI.main.t_sub = s.leagues[lg].name
	var min_apps = 1
	var all = []
	var played = false
	for cid in s.leagues[lg].clubs:
		min_apps = max(min_apps, int(s.clubs[cid].t.p * 0.5))
		for pid in s.clubs[cid].players:
			var p = s.players[pid]
			all.append(p)
			if p.ss.ap > 0:
				played = true
	var h = panes(10, 20)
	if not played:
		# before a ball is kicked: the players to watch
		var titles = ["Best players", "Best under 21", "Most valuable", "Top earners"]
		for k in 4:
			var list = all.duplicate()
			if k == 1:
				list = list.filter(func(p): return G.age(p) <= 21)
			match k:
				0, 1: list.sort_custom(func(x, y): return x.ovr > y.ovr)
				2: list.sort_custom(func(x, y): return G.value(x) > G.value(y))
				3: list.sort_custom(func(x, y): return x.wage > y.wage)
			_board(h, titles[k], list, func(p): return str(p.ovr) if k < 2 else (G.money(G.value(p)) if k == 2 else G.money(p.wage)), -68 if k >= 2 else -34)
		return
	for k in 4:
		var list = []
		for p in all:
			var val = 0.0
			match k:
				0: val = p.ss.g
				1: val = p.ss.a
				2: val = G.avg_rating(p) if p.ss.ap >= min_apps else 0.0
				3: val = p.ss.cs if p.pos == "GK" else 0
			if val > 0:
				list.append(p)
		match k:
			0: list.sort_custom(func(x, y): return x.ss.g > y.ss.g if x.ss.g != y.ss.g else x.ss.ap < y.ss.ap)
			1: list.sort_custom(func(x, y): return x.ss.a > y.ss.a if x.ss.a != y.ss.a else x.ss.ap < y.ss.ap)
			2: list.sort_custom(func(x, y): return G.avg_rating(x) > G.avg_rating(y))
			3: list.sort_custom(func(x, y): return x.ss.cs > y.ss.cs)
		_board(h, KINDS[k], list, func(p): return [str(p.ss.g), str(p.ss.a), "%.2f" % G.avg_rating(p), str(p.ss.cs)][k], -46)


func _board(h: Control, title: String, list: Array, val: Callable, vw: int):
	var s = G.s
	var a = pane(0, 2)
	h.add_child(a[0])
	var v = a[1]
	v.add_child(UI.caps(title, 15, UI.accent))
	if list.size() == 0:
		v.add_child(UI.lbl("Nobody yet", 17, UI.DIM))
	for i in min(25, list.size()):
		var p = list[i]
		var pid = p.id
		v.add_child(UI.trow([str(i + 1), G.pname(p), s.clubs[p.club].short, val.call(p)], [20, 0, 40, vw],
			{"size": 18, "hi": p.club == s.user.club, "alt": i % 2 == 0, "cols": {0: UI.GOLD if i < 3 else UI.DIM, 2: UI.MUTED}, "pad": 3, "tap": func(): UI.main.open("player", {"pid": pid})}))

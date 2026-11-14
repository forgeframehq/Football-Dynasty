extends RefCounted
# Domestic cups and European competitions.

const CUPS = [["fa", "FA Cup", "England", 0], ["lc", "League Cup", "England", 1], ["cdr", "Copa del Rey", "Spain", 0], ["ci", "Coppa Italia", "Italy", 0], ["dfb", "DFB-Pokal", "Germany", 0], ["cdf", "Coupe de France", "France", 0]]
const EUROS = [["ucl", "Champions League", 1.0], ["uel", "Europa League", 0.35], ["uecl", "Conference League", 0.15]]
const CUP_DATES = [[[9, 9], [10, 7], [11, 11], [12, 9], [1, 13], [2, 10], [3, 10], [4, 14], [5, 19]], [[8, 12], [8, 26], [9, 23], [10, 28], [12, 16], [1, 27], [2, 24]]]
const EURO_DATES = [[9, 15], [9, 29], [10, 20], [11, 3], [11, 17], [12, 1], [2, 16], [3, 16], [4, 20], [5, 30]]
const GROUP_MD = [[[0, 1], [2, 3]], [[1, 2], [3, 0]], [[0, 2], [1, 3]], [[2, 0], [3, 1]], [[2, 1], [0, 3]], [[1, 0], [3, 2]]]


static func snap(md: Array, weekday: int) -> int:
	var s = G.s
	var d = G.ymd(s.season if md[0] >= 7 else s.season + 1, md[0], md[1])
	while G.date(d).weekday != weekday:
		d += 1
	return d


static func get_comp(id: String):
	for c in G.s.comps:
		if c.id == id:
			return c
	return null


static func round_name(n_teams: int, rd: int) -> String:
	match n_teams:
		2: return "Final"
		4: return "Semi-final"
		8: return "Quarter-final"
		16: return "Round of 16"
		32: return "Round of 32"
	return "Round %d" % (rd + 1)


static func _add(comp: Dictionary, day: int, h: int, a: int, ko: bool, label: String) -> int:
	var s = G.s
	var id = s.fixtures.size()
	s.fixtures.append({"id": id, "lg": -1, "comp": comp.id, "rd": comp.round, "day": day, "h": h, "a": a, "hg": -1, "ag": -1, "played": false, "ko": ko, "label": "%s · %s" % [comp.name, label]})
	if not G.fx_by_day.has(day):
		G.fx_by_day[day] = []
	G.fx_by_day[day].append(id)
	return id


static func setup_season():
	var s = G.s
	s.comps = []
	var rng = G.rng
	# domestic cups
	for cd in CUPS:
		var teams = []
		for lg in s.leagues:
			if lg.roe or lg.country != cd[2]:
				continue
			for cid in lg.clubs:
				if not G.LG.is_reserve(cid):
					teams.append(cid)
		teams.sort_custom(func(a, b):
			var ta = s.leagues[s.clubs[a].lg].tier
			var tb = s.leagues[s.clubs[b].lg].tier
			return ta < tb if ta != tb else s.clubs[a].rep > s.clubs[b].rep)
		var target = 1
		while target * 2 <= teams.size():
			target *= 2
		var ties = teams.size() - target
		var rounds = int(round(log(target) / log(2.0))) + (1 if ties > 0 else 0)
		var pool = CUP_DATES[cd[3]]
		var dates = []
		for i in range(pool.size() - rounds, pool.size()):
			dates.append(snap(pool[i], 3))
		var comp = {"id": cd[0], "name": cd[1], "kind": "cup", "country": cd[2], "dates": dates, "round": 0, "alive": [], "byes": [], "fx": [], "done": false, "winner": -1, "rounds": [], "scale": 0.06 if cd[3] == 0 else 0.03}
		if ties > 0:
			comp.byes = teams.slice(0, teams.size() - 2 * ties)
			comp.alive = teams.slice(teams.size() - 2 * ties)
		else:
			comp.alive = teams
		s.comps.append(comp)
		_draw_round(comp)
	# europe
	var q = s.get("euro_q", null)
	if q == null:
		q = {"ucl": [], "uel": [], "uecl": []}
		for lgid in G.LG.EURO:
			var ids = s.leagues[lgid].clubs.duplicate()
			ids.sort_custom(func(a, b): return s.clubs[a].rep > s.clubs[b].rep)
			var e = G.LG.EURO[lgid]
			q.ucl.append_array(ids.slice(0, e[0]))
			q.uel.append_array(ids.slice(e[0], e[1]))
			q.uecl.append(ids[e[1]])
	var roe = []
	for lg in s.leagues:
		if lg.roe:
			roe.append_array(lg.clubs)
	roe.sort_custom(func(a, b): return s.clubs[a].rep > s.clubs[b].rep)
	var taken = {}
	for ed in EUROS:
		var teams = []
		for cid in q[ed[0]]:
			if not taken.has(cid) and teams.size() < 32:
				teams.append(cid)
				taken[cid] = true
		for cid in roe:
			if teams.size() >= 32:
				break
			if not taken.has(cid):
				teams.append(cid)
				taken[cid] = true
		if teams.size() < 32:
			continue
		teams.sort_custom(func(a, b): return s.clubs[a].rep > s.clubs[b].rep)
		var groups = []
		for g in 8:
			groups.append([])
		for pot in 4:
			var p = teams.slice(pot * 8, pot * 8 + 8)
			p.shuffle()
			for g in 8:
				groups[g].append(p[g])
		var dates = []
		for i in EURO_DATES.size():
			dates.append(snap(EURO_DATES[i], 6 if i == EURO_DATES.size() - 1 else 2))
		var comp = {"id": ed[0], "name": ed[1], "kind": "euro", "dates": dates, "round": 0, "groups": groups, "gt": {}, "alive": [], "byes": [], "fx": [], "done": false, "winner": -1, "rounds": [], "scale": ed[2], "stage": 0}
		for cid in teams:
			comp.gt[cid] = G.new_table()
			s.clubs[cid].budget += int(12000000 * ed[2])
		for md in 6:
			comp.round = md
			for g in 8:
				for m in GROUP_MD[md]:
					comp.fx.append(_add(comp, dates[md], groups[g][m[0]], groups[g][m[1]], false, "Group %s" % "ABCDEFGH"[g]))
		comp.round = 0
		s.comps.append(comp)
		if s.user.has("club") and s.user.club in teams:
			var gi = 0
			for g in 8:
				if s.user.club in groups[g]:
					gi = g
			var names = []
			for cid in groups[gi]:
				if cid != s.user.club:
					names.append(s.clubs[cid].name)
			G.msg("%s draw" % ed[1], "You have been drawn in Group %s of the %s with %s." % ["ABCDEFGH"[gi], ed[1], ", ".join(names)], "board")


static func _two_legs(comp: Dictionary, day: int, h: int, a: int, label: String):
	# European knockout rounds before the final: away first, home second a week later, settled on aggregate
	var s = G.s
	var id1 = _add(comp, day, a, h, false, label + " · 1st leg")
	s.fixtures[id1]["leg"] = 1
	var id2 = _add(comp, day + 7, h, a, true, label + " · 2nd leg")
	s.fixtures[id2]["leg"] = 2
	s.fixtures[id2]["first"] = id1
	comp.fx.append(id1)
	comp.fx.append(id2)


static func _draw_round(comp: Dictionary):
	var s = G.s
	var teams = comp.alive.duplicate()
	teams.shuffle()
	var n_total = comp.alive.size() + comp.byes.size()
	var label = round_name(n_total, comp.round) if comp.byes.size() == 0 else "Round 1"
	var day = comp.dates[min(comp.round, comp.dates.size() - 1)]
	comp.fx = []
	for i in range(0, teams.size() - 1, 2):
		var h = teams[i]
		var a = teams[i + 1]
		# the lower-division side gets the home tie
		if s.leagues[s.clubs[a].lg].tier > s.leagues[s.clubs[h].lg].tier:
			var t = h
			h = a
			a = t
		var two = comp.kind == "euro" and teams.size() > 2
		if two:
			_two_legs(comp, day, h, a, label)
		else:
			comp.fx.append(_add(comp, day, h, a, true, label))
		if s.user.has("club") and (h == s.user.club or a == s.user.club):
			var opp = s.clubs[a if h == s.user.club else h]
			if two:
				G.msg("%s draw" % comp.name, "%s: you will play %s over two legs, %s first on %s and the return a week later. Away goals do not count double; level on aggregate means extra time and penalties." % [label, opp.name, "away" if h == s.user.club else "at home", G.fmt_date(day)], "board")
			else:
				G.msg("%s draw" % comp.name, "%s: you will play %s %s on %s." % [label, opp.name, "at home" if h == s.user.club else "away", G.fmt_date(day)], "board")


static func on_result(f: Dictionary):
	# group tables for european group games
	var comp = get_comp(f.comp)
	if comp == null or f.ko or int(f.get("leg", 0)) > 0:
		return
	for i in 2:
		var cid = f.h if i == 0 else f.a
		var gf = f.hg if i == 0 else f.ag
		var ga = f.ag if i == 0 else f.hg
		var t = comp.gt[cid]
		t.p += 1
		t.gf += gf
		t.ga += ga
		if gf > ga:
			t.w += 1
			t.pts += 3
			G.s.clubs[cid].budget += int(2000000 * comp.scale)
		elif gf == ga:
			t.d += 1
			t.pts += 1
		else:
			t.l += 1


static func group_order(comp: Dictionary, g: int) -> Array:
	var ids = comp.groups[g].duplicate()
	ids.sort_custom(func(a, b):
		var ta = comp.gt[a]
		var tb = comp.gt[b]
		if ta.pts != tb.pts:
			return ta.pts > tb.pts
		if ta.gf - ta.ga != tb.gf - tb.ga:
			return ta.gf - ta.ga > tb.gf - tb.ga
		return ta.gf > tb.gf)
	return ids


static func daily():
	var s = G.s
	for comp in s.comps:
		if comp.done:
			continue
		var all_played = true
		for id in comp.fx:
			if not s.fixtures[id].played:
				all_played = false
				break
		if not all_played:
			continue
		if comp.kind == "euro" and comp.stage == 0:
			_start_knockout(comp)
			continue
		var res = []
		var winners = []
		for id in comp.fx:
			var f = s.fixtures[id]
			if int(f.get("leg", 0)) == 1:
				continue
			var w = G.LG.fx_winner(f)
			winners.append(w)
			if int(f.get("leg", 0)) == 2 and f.has("first"):
				var f1 = s.fixtures[int(f.first)]
				res.append([f.h, f.a, int(f.hg) + int(f1.ag), int(f.ag) + int(f1.hg), f.get("pens", null)])
			else:
				res.append([f.h, f.a, f.hg, f.ag, f.get("pens", null)])
			if comp.kind == "euro":
				s.clubs[w].budget += int([6, 8, 10, 12][min(comp.round - 6, 3)] * 1000000 * comp.scale)
		comp.rounds.append(res)
		comp.alive = comp.byes + winners
		comp.byes = []
		comp.round += 1
		if comp.alive.size() == 1:
			_finish(comp)
		else:
			_draw_round(comp)


static func _start_knockout(comp: Dictionary):
	var s = G.s
	var first = []
	var second = []
	for g in 8:
		var o = group_order(comp, g)
		first.append(o[0])
		second.append(o[1])
	var grp = {}
	for g in 8:
		for cid in comp.groups[g]:
			grp[cid] = g
	for t in 60:
		second.shuffle()
		var ok = true
		for i in 8:
			if grp[second[i]] == grp[first[i]]:
				ok = false
				break
		if ok:
			break
	comp.stage = 1
	comp.round = 6
	comp.fx = []
	for i in 8:
		_two_legs(comp, comp.dates[6], first[i], second[i], "Round of 16")
		s.clubs[first[i]].budget += int(4000000 * comp.scale)
		s.clubs[second[i]].budget += int(4000000 * comp.scale)
		if first[i] == s.user.club or second[i] == s.user.club:
			var opp = s.clubs[second[i] if first[i] == s.user.club else first[i]]
			G.msg("%s knockout draw" % comp.name, "You are through to the last 16 and will face %s over two legs, starting on %s." % [opp.name, G.fmt_date(comp.dates[6])], "board", null, true)
	if s.user.club in comp.gt and not (s.user.club in first) and not (s.user.club in second):
		G.msg("%s exit" % comp.name, "Your %s campaign is over after the group stage." % comp.name, "board")


static func _finish(comp: Dictionary):
	var s = G.s
	comp.done = true
	comp.winner = comp.alive[0]
	var c = s.clubs[comp.winner]
	c.budget += int((8000000 if comp.kind == "euro" else 40000000) * comp.scale)
	G.news("%s win the %s!" % [c.name, comp.name])
	if comp.winner == s.user.club:
		var u = s.user
		u.trophies.append("%s %s" % [comp.name, G.season_name()])
		u["film"] = "euro" if comp.kind == "euro" else "cup"
		G.OPS.mgr_bonus("euro" if comp.kind == "euro" else "cup")
		u.conf = min(100.0, u.conf + (18 if comp.id == "ucl" else 10))
		u.rep = min(100.0, u.rep + (8 if comp.id == "ucl" else 4))
		G.msg("%s winners!" % comp.name, "You have won the %s with %s. The board and the fans are overjoyed." % [comp.name, c.name], "board", null, true)


static func qualify(tables: Array):
	# european places for next season from the final league tables and cup winners
	var s = G.s
	var q = {"ucl": [], "uel": [], "uecl": []}
	for lgid in G.LG.EURO:
		var t = tables[lgid]
		var e = G.LG.EURO[lgid]
		q.ucl.append_array(t.slice(0, e[0]))
		q.uel.append_array(t.slice(e[0], e[1]))
		q.uecl.append(t[e[1]])
	for cd in CUPS:
		if cd[3] != 0:
			continue
		var comp = get_comp(cd[0])
		if comp == null or comp.winner < 0:
			continue
		var w = comp.winner
		if w in q.ucl or w in q.uel or not (w in tables[s.clubs[w].lg]) or s.leagues[s.clubs[w].lg].tier != 1:
			continue
		q.uecl.erase(w)
		q.uel.append(w)
	s["euro_q"] = q


static func club_comps(cid: int) -> Array:
	var out = []
	for comp in G.s.comps:
		var alive = false
		var was_in = false
		if comp.kind == "euro":
			was_in = comp.gt.has(cid)
			alive = was_in and (comp.stage == 0 or cid in comp.alive or _in_fx(comp, cid))
		else:
			alive = cid in comp.alive or cid in comp.byes or _in_fx(comp, cid)
			was_in = alive
			for r in comp.rounds:
				for m in r:
					if m[0] == cid or m[1] == cid:
						was_in = true
		if comp.done:
			alive = comp.winner == cid
		if was_in:
			out.append([comp, alive])
	return out


static func _in_fx(comp: Dictionary, cid: int) -> bool:
	for id in comp.fx:
		var f = G.s.fixtures[id]
		if not f.played and (f.h == cid or f.a == cid):
			return true
	return false

extends RefCounted
# International tournaments (G.IT): World Cup, Euros, Copa América, AFCON and the Asian Cup. National squads are
# the best 23 players of each nation anywhere in the game; nations with too few players use an estimated strength.
# Matches are quick results spread over the tournament's days. Your players get caps and goals, can come back
# injured, and winners return lifted. The Asian Cup is played in January: AFC players at your club are away
# (p.away) until their nation is knocked out.
#
# Save: s.intl = {live: [running tournaments], done: [{id, name, year, host, winner, runner, scorer, goals, groups, games, ko}]}.

const T = {
	"wc": ["World Cup", 48, [6, 11], 4, 2, "World"],
	"euro": ["European Championship", 24, [6, 12], 4, 0, "UEFA"],
	"copa": ["Copa América", 16, [6, 20], 4, 0, "CONMEBOL"],
	"afcon": ["Africa Cup of Nations", 24, [6, 21], 2, 1, "CAF"],
	"asia": ["AFC Asian Cup", 24, [1, 8], 4, 3, "AFC"],
}
const HOSTS = {"wc2030": "Spain, Portugal and Morocco", "euro2028": "England, Scotland, Wales and Ireland", "afcon2027": "Kenya, Uganda and Tanzania", "asia2027": "Saudi Arabia"}
const CONF = {
	"UEFA": ["England", "Spain", "France", "Germany", "Italy", "Portugal", "Holland", "Belgium", "Croatia", "Denmark", "Switzerland", "Austria", "Turkey", "Poland", "Serbia", "Ukraine",
		"Czech Republic", "Scotland", "Norway", "Sweden", "Hungary", "Wales", "Slovakia", "Slovenia", "Greece", "Romania", "Republic of Ireland", "Albania", "Georgia", "Northern Ireland", "Bosnia and Herzegovina", "Finland", "Iceland", "Kosovo"],
	"CONMEBOL": ["Brazil", "Argentina", "Uruguay", "Colombia", "Ecuador", "Chile", "Paraguay", "Peru", "Venezuela", "Bolivia"],
	"CONCACAF": ["United States", "Mexico", "Canada", "Jamaica", "Panama", "Costa Rica", "Honduras", "Haiti"],
	"CAF": ["Morocco", "Senegal", "Nigeria", "Côte d'Ivoire", "Egypt", "Algeria", "Cameroon", "Ghana", "Mali", "Tunisia", "Congo DR", "Guinea", "Burkina Faso", "South Africa", "Cape Verde Islands", "Gambia",
		"Gabon", "Zambia", "Angola", "Equatorial Guinea", "Mauritania", "Kenya", "Uganda", "Tanzania"],
	"AFC": ["Japan", "Korea Republic", "Iran", "Australia", "Saudi Arabia", "Qatar", "Iraq", "Uzbekistan", "United Arab Emirates", "Jordan", "Oman", "China PR", "Bahrain", "Syria", "Palestine", "Thailand",
		"Kyrgyzstan", "Tajikistan", "Lebanon", "India", "Vietnam", "Indonesia", "Kuwait", "Malaysia"],
}
# estimated strength for nations without enough players in the game
const EST = {"Iran": 72, "Qatar": 67, "Iraq": 66, "Uzbekistan": 66, "United Arab Emirates": 64, "Jordan": 64, "Oman": 62, "China PR": 62, "Bahrain": 60, "Syria": 60,
	"Palestine": 58, "Thailand": 59, "Kyrgyzstan": 56, "Tajikistan": 56, "Lebanon": 56, "India": 55, "Vietnam": 58, "Indonesia": 58, "Kuwait": 57, "Malaysia": 55,
	"Egypt": 70, "South Africa": 66, "Kenya": 58, "Uganda": 58, "Tanzania": 56, "Zambia": 62, "Panama": 65, "Costa Rica": 65, "Honduras": 62, "Peru": 68, "Bolivia": 62}


static func ensure():
	var s = G.s
	if not s.has("intl"):
		s["intl"] = {"live": [], "done": []}


static func due(year: int) -> Array:
	# which tournaments start in this calendar year
	var out = []
	for id in T:
		var t = T[id]
		if year % t[3] == t[4] and year >= 2027:
			out.append(id)
	return out


static func strength(nat: String) -> Dictionary:
	# the 23 best players of a nation, and its strength (average of the best 11)
	var s = G.s
	var pl = []
	for pid in s.players:
		var p = s.players[pid]
		if p.nat == nat:
			pl.append(p)
	pl.sort_custom(func(a, b): return a.ovr > b.ovr)
	var sq = pl.slice(0, 23)
	var st = float(EST.get(nat, 58))
	if sq.size() >= 11:
		var t = 0.0
		for i in 11:
			t += sq[i].ovr
		st = t / 11.0
	return {"nat": nat, "str": st, "squad": sq.map(func(p): return p.id)}


static func daily():
	ensure()
	var s = G.s
	var cur = G.cur
	# start any tournament due today
	for id in due(cur.year):
		var t = T[id]
		if cur.month == t[2][0] and cur.day == t[2][1]:
			_start(id, cur.year)
	for tm in s.intl.live.duplicate():
		_play_day(tm)


static func _start(id: String, year: int):
	var s = G.s
	var t = T[id]
	var pool = []
	if t[5] == "World":
		for k in CONF:
			pool.append_array(CONF[k])
	else:
		pool = CONF[t[5]].duplicate()
		if id == "copa":
			pool.append_array(["United States", "Mexico", "Canada", "Jamaica", "Panama", "Costa Rica"])
	var teams = pool.map(func(n): return strength(n))
	teams.sort_custom(func(a, b): return a.str > b.str)
	teams = teams.slice(0, t[1])
	var host = HOSTS.get("%s%d" % [id, year], "")
	if host == "":
		host = teams[G.rng.randi() % min(8, teams.size())].nat
	# pots by strength, groups of four
	var ng = int(teams.size() / 4)
	var groups = []
	for g in ng:
		groups.append([])
	for pot in 4:
		var p = teams.slice(pot * ng, pot * ng + ng)
		p.shuffle()
		for g in ng:
			groups[g].append(p[g].nat)
	var info = {}
	for tm in teams:
		info[tm.nat] = {"str": tm.str, "squad": tm.squad, "p": 0, "w": 0, "d": 0, "l": 0, "gf": 0, "ga": 0, "pts": 0, "out": false}
	var start = G.ymd(year, t[2][0], t[2][1])
	var cur = {"id": id, "name": t[0], "year": year, "host": host, "groups": groups, "info": info, "games": [], "stage": "group", "ko": [], "scorers": {}, "start": start}
	# three group matchdays, two games per group per matchday
	var md = [[[0, 1], [2, 3]], [[0, 2], [1, 3]], [[3, 0], [1, 2]]]
	for r in 3:
		for g in ng:
			for m in md[r]:
				cur.games.append({"day": start + r * 4 + (g % 2), "h": groups[g][m[0]], "a": groups[g][m[1]], "g": g, "hg": -1, "ag": -1})
	s.intl.live.append(cur)
	# your players who are called up
	var mine = []
	for pid in G.uc().players:
		for nat in info:
			if pid in info[nat].squad:
				mine.append(G.pname(s.players[pid]))
				if id == "asia":
					s.players[pid]["away"] = start + 40
	G.msg("%s %d begins" % [t[0], year], "The %s starts today in %s with %d nations.%s" % [t[0], host, teams.size(),
		("\n\nYour players called up: %s.%s" % [", ".join(mine), " They miss club matches until their nation is knocked out." if id == "asia" else ""]) if mine.size() > 0 else ""], "info", null, true)
	G.SOC.news_post("The %s %d kicks off today in %s." % [t[0], year, host], true)


static func _match(cur: Dictionary, h: String, a: String, ko: bool) -> Array:
	var ih = cur.info[h]
	var ia = cur.info[a]
	var hb = 0.04 if cur.host.contains(h) else 0.0
	var ab = 0.04 if cur.host.contains(a) else 0.0
	var d = (ih.str - ia.str) * 0.05
	var hg = G.WD._pois(1.25 * exp(d + hb))
	var ag = G.WD._pois(1.25 * exp(-d + ab))
	for side in [[h, hg], [a, ag]]:
		var sq = cur.info[side[0]].squad
		for k in side[1]:
			if sq.is_empty():
				break
			var pick = _scorer(sq)
			if pick >= 0:
				cur.scorers[pick] = int(cur.scorers.get(pick, 0)) + 1
				var p = G.s.players[pick]
				var cp = G.PS.caps(p)
				cp[1] += 1
		for pid in sq.slice(0, 14):
			if G.s.players.has(pid):
				G.PS.caps(G.s.players[pid])[0] += 1
	var pens = null
	if ko and hg == ag:
		var ph = G.rng.randi_range(3, 5)
		var pa = ph
		while pa == ph:
			pa = G.rng.randi_range(2, 5)
		pens = [ph, pa]
	return [hg, ag, pens]


static func _scorer(sq: Array) -> int:
	var s = G.s
	var tot = 0.0
	var w = []
	for pid in sq.slice(0, 16):
		var v = 0.05
		if s.players.has(pid):
			v = [0.05, 0.5, 1.4, 3.2][G.LINE[s.players[pid].pos]] * (1.0 + (s.players[pid].ovr - 60) * 0.03)
		w.append([pid, max(0.01, v)])
		tot += max(0.01, v)
	var r = G.rng.randf() * tot
	for x in w:
		r -= x[1]
		if r <= 0:
			return x[0]
	return -1


static func _play_day(cur: Dictionary):
	var s = G.s
	var left = false
	for gm in cur.games:
		if gm.hg >= 0:
			continue
		if gm.day > s.day:
			left = true
			continue
		var r = _match(cur, gm.h, gm.a, cur.stage != "group")
		gm.hg = r[0]
		gm.ag = r[1]
		if r[2] != null:
			gm["pens"] = r[2]
		if cur.stage == "group":
			for side in [[gm.h, gm.hg, gm.ag], [gm.a, gm.ag, gm.hg]]:
				var t = cur.info[side[0]]
				t.p += 1
				t.gf += side[1]
				t.ga += side[2]
				if side[1] > side[2]:
					t.w += 1
					t.pts += 3
				elif side[1] == side[2]:
					t.d += 1
					t.pts += 1
				else:
					t.l += 1
		else:
			var loser = gm.a if (gm.hg > gm.ag or (gm.hg == gm.ag and gm.pens[0] > gm.pens[1])) else gm.h
			cur.info[loser].out = true
			_release(cur, loser)
	if left:
		return
	# the round is complete: next round or the end
	if cur.stage == "group":
		_knockout(cur, _qualifiers(cur))
	else:
		var winners = []
		for gm in cur.games:
			if gm.get("rnd", -1) == cur.ko.size() - 1:
				winners.append(gm.h if not cur.info[gm.h].out else gm.a)
		if winners.size() <= 1:
			_finish(cur, winners[0] if winners.size() == 1 else "")
		else:
			_knockout(cur, winners)


static func group_table(cur: Dictionary, g: int) -> Array:
	var arr = cur.groups[g].duplicate()
	arr.sort_custom(func(a, b):
		var ta = cur.info[a]
		var tb = cur.info[b]
		if ta.pts != tb.pts:
			return ta.pts > tb.pts
		if ta.gf - ta.ga != tb.gf - tb.ga:
			return ta.gf - ta.ga > tb.gf - tb.ga
		return ta.gf > tb.gf)
	return arr


static func _qualifiers(cur: Dictionary) -> Array:
	# top two in each group, then the best third-placed sides up to a power of two
	var tops = []
	var thirds = []
	for g in cur.groups.size():
		var t = group_table(cur, g)
		tops.append(t[0])
		tops.append(t[1])
		if t.size() > 2:
			thirds.append(t[2])
	var n = 1
	while n * 2 <= tops.size() + thirds.size():
		n *= 2
	thirds.sort_custom(func(a, b): return cur.info[a].pts * 100 + cur.info[a].gf - cur.info[a].ga > cur.info[b].pts * 100 + cur.info[b].gf - cur.info[b].ga)
	var q = tops + thirds.slice(0, max(0, n - tops.size()))
	for nat in cur.info:
		if not (nat in q) and not cur.info[nat].out:
			cur.info[nat].out = true
			_release(cur, nat)
	return q


static func _knockout(cur: Dictionary, teams: Array):
	var s = G.s
	var rnd = cur.ko.size()
	cur.stage = "ko"
	var label = {2: "Final", 4: "Semi-finals", 8: "Quarter-finals", 16: "Round of 16", 32: "Round of 32"}.get(teams.size(), "Knockout")
	cur.ko.append(label)
	# strong against weak in the first knockout round, then in bracket order
	var order = teams.duplicate()
	if rnd == 0:
		order.sort_custom(func(a, b): return cur.info[a].pts * 10 + cur.info[a].str * 0.1 > cur.info[b].pts * 10 + cur.info[b].str * 0.1)
		var paired = []
		for i in order.size() / 2:
			paired.append(order[i])
			paired.append(order[order.size() - 1 - i])
		order = paired
	var day = s.day + 3
	for i in range(0, order.size() - 1, 2):
		cur.games.append({"day": day, "h": order[i], "a": order[i + 1], "rnd": rnd, "hg": -1, "ag": -1, "label": label})


static func _release(cur: Dictionary, nat: String):
	# a nation is out: its players head home (back for the club after a winter tournament)
	var s = G.s
	for pid in cur.info[nat].squad:
		if s.players.has(pid) and s.players[pid].has("away"):
			s.players[pid].away = s.day + 2


static func _finish(cur: Dictionary, winner: String):
	var s = G.s
	var final = cur.games[cur.games.size() - 1]
	var runner = final.a if final.h == winner else final.h
	var best = -1
	var bg = 0
	for pid in cur.scorers:
		if int(cur.scorers[pid]) > bg:
			bg = int(cur.scorers[pid])
			best = int(pid)
	var bs = G.pname(s.players[best]) if s.players.has(best) else ""
	s.intl.done.push_front({"id": cur.id, "name": cur.name, "year": cur.year, "host": cur.host, "winner": winner, "runner": runner, "score": "%d-%d%s" % [final.hg, final.ag, " (pens)" if final.has("pens") else ""],
		"scorer": bs, "goals": bg, "groups": cur.groups, "games": cur.games, "ko": cur.ko})
	while s.intl.done.size() > 12:
		s.intl.done.pop_back()
	# what it means for your players
	var notes = []
	for pid in G.uc().players:
		var p = s.players[pid]
		p.erase("away")
		if pid in cur.info.get(winner, {}).get("squad", []):
			p.mor = min(100.0, p.mor + 10.0)
			notes.append("%s won the %s with %s" % [G.pname(p), cur.name, winner])
		elif pid in cur.info.get(runner, {}).get("squad", []):
			p.mor = min(100.0, p.mor + 4.0)
		var played = false
		for nat in cur.info:
			if pid in cur.info[nat].squad:
				played = true
		if played and G.rng.randf() < 0.05:
			p.inj = max(p.inj, G.rng.randi_range(7, 30))
			s.recov[pid] = true
			notes.append("%s came back injured (%s)" % [G.pname(p), G.inj_text(p.inj)])
	G.msg("%s win the %s" % [winner, cur.name], "%s beat %s %s in the final of the %s %d (%s). Top scorer: %s with %d.%s" % [winner, runner, s.intl.done[0].score, cur.name, cur.year, cur.host, bs, bg,
		("\n\n" + ".\n".join(notes) + ".") if notes.size() > 0 else ""], "info", null, true)
	G.SOC.news_post("%s are %s champions! They beat %s %s in the final." % [winner, cur.name, runner, s.intl.done[0].score], true)
	s.intl.live.erase(cur)


static func next_list() -> Array:
	# upcoming tournaments for the next four years: [id, name, year, start day]
	var out = []
	var y = G.cur.year
	for yy in range(y, y + 5):
		for id in due(yy):
			var d = G.ymd(yy, T[id][2][0], T[id][2][1])
			if d >= G.s.day:
				out.append([id, T[id][0], yy, d, HOSTS.get("%s%d" % [id, yy], "")])
	out.sort_custom(func(a, b): return a[3] < b[3])
	return out

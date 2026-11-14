extends RefCounted
# League structure, scheduling, play-offs and the end-of-season rollover.

# [upper league, lower league, automatic places, play-off type]
const LINKS = [[0, 1, 2, "eng4"], [1, 2, 2, "eng4"], [2, 3, 3, "eng4"], [4, 5, 2, "eng4"], [6, 7, 2, "eng4"], [8, 9, 2, "rel"], [9, 10, 2, "rel"], [11, 12, 2, "fra"]]
# top flight: [champions league places, total european places]
const EURO = {0: [4, 6], 4: [4, 6], 6: [4, 6], 8: [4, 6], 11: [3, 5]}


static func zones(lg: int) -> Dictionary:
	var z = {"cl": 0, "eu": 0, "up": 0, "po": 0, "down": 0, "rpo": 0}
	if EURO.has(lg):
		z.cl = EURO[lg][0]
		z.eu = EURO[lg][1]
	for l in LINKS:
		if l[0] == lg:
			z.down = l[2] + (1 if l[3] == "eng4" else 0)
			z.rpo = 0 if l[3] == "eng4" else 1
		if l[1] == lg:
			z.up = l[2]
			z.po = 4 if l[3] == "eng4" else (1 if l[3] == "rel" else 3)
	return z


static func zone_of(lg: int, pos: int, n: int) -> String:
	var z = zones(lg)
	if pos <= z.cl: return "cl"
	if pos <= z.eu: return "eu"
	if pos <= z.up: return "up"
	if pos <= z.up + z.po: return "po"
	if pos > n - z.down: return "down"
	if pos > n - z.down - z.rpo: return "rpo"
	return ""


static func table(lg: int) -> Array:
	var cl = G.s.clubs
	var arr = G.s.leagues[lg].clubs.duplicate()
	arr.sort_custom(func(a, b):
		var ta = cl[a].t
		var tb = cl[b].t
		if ta.pts != tb.pts:
			return ta.pts > tb.pts
		var ga = ta.gf - ta.ga
		var gb = tb.gf - tb.ga
		if ga != gb:
			return ga > gb
		if ta.gf != tb.gf:
			return ta.gf > tb.gf
		return cl[a].name < cl[b].name)
	return arr


static func is_reserve(cid: int) -> bool:
	var n = G.s.clubs[cid].name
	return n.ends_with(" B") or n.ends_with(" II") or n == "Celta Fortuna"


static func promo_table(lg: int) -> Array:
	# league order without reserve sides, which cannot be promoted
	var out = []
	for cid in table(lg):
		if not is_reserve(cid):
			out.append(cid)
	return out


static func position(cid: int) -> int:
	return table(G.s.clubs[cid].lg).find(cid) + 1


static func ordinal(n: int) -> String:
	var suf = "th"
	if n % 100 < 11 or n % 100 > 13:
		match n % 10:
			1: suf = "st"
			2: suf = "nd"
			3: suf = "rd"
	return "%d%s" % [n, suf]


static func objective(c: Dictionary, shift := 0) -> Dictionary:
	# shift moves the expected finish: negative = more ambitious, positive = more cautious
	var ids = G.s.leagues[c.lg].clubs.duplicate()
	ids.sort_custom(func(a, b): return G.s.clubs[a].rep > G.s.clubs[b].rep)
	var n = ids.size()
	var ex = clampi(ids.find(c.id) + 1 + shift, 1, n)
	var z = zones(c.lg)
	var safe = n - z.down - z.rpo
	var text = ""
	var target = 0
	if z.cl > 0:
		if ex <= 2:
			text = "Challenge for the title"
			target = 2
		elif ex <= z.cl + 1:
			text = "Qualify for the Champions League"
			target = z.cl
		elif ex <= z.eu + 2:
			text = "Qualify for Europe"
			target = z.eu
		elif ex <= safe - 4:
			text = "Secure a mid-table finish"
			target = min(ex + 2, safe - 2)
		else:
			text = "Avoid relegation"
			target = safe
	else:
		if ex <= z.up + 1:
			text = "Win automatic promotion"
			target = z.up
		elif ex <= z.up + z.po + 2:
			text = "Reach the promotion play-offs"
			target = z.up + z.po
		elif z.down == 0 or ex <= safe - 4:
			text = "Secure a mid-table finish"
			target = min(ex + 2, safe - 2) if z.down > 0 else min(ex + 3, n - 2)
		else:
			text = "Avoid relegation"
			target = safe
	return {"exp": ex, "target": target, "text": text}


# ---------------------------------------------------------------- fixtures

static func round_days(year: int, rounds: int) -> Array:
	var start = G.ymd(year, 8, 8 if rounds > 40 else 15)
	while G.date(start).weekday != 6:
		start += 1
	var last = G.ymd(year + 1, 5, 24)
	var sats = []
	var d = start
	while d <= last:
		sats.append(d)
		d += 7
	var days = []
	if rounds <= sats.size():
		var drop = {}
		var nd = sats.size() - rounds
		for k in nd:
			drop[int((k + 1) * sats.size() / float(nd + 1))] = true
		for i in sats.size():
			if not drop.has(i):
				days.append(sats[i])
		while days.size() > rounds:
			days.remove_at(days.size() / 2)
	else:
		days = sats.duplicate()
		var extra = rounds - sats.size()
		for k in extra:
			days.append(sats[int((k + 0.5) * sats.size() / float(extra))] + 3)
		days.sort()
	return days


static func generate_fixtures():
	var s = G.s
	s.fixtures = []
	s.playoffs = []
	for lg in s.leagues:
		if lg.roe:
			continue
		var ids = lg.clubs.duplicate()
		ids.shuffle()
		var n = ids.size()
		var half = []
		for r in n - 1:
			var rd = []
			for i in n / 2:
				var a = ids[i]
				var b = ids[n - 1 - i]
				if r % 2 == 1:
					rd.append([b, a])
				else:
					rd.append([a, b])
			half.append(rd)
			var last = ids.pop_back()
			ids.insert(1, last)
		var rounds = half.duplicate()
		for rd in half:
			var rev = []
			for m in rd:
				rev.append([m[1], m[0]])
			rounds.append(rev)
		var days = round_days(s.season, rounds.size())
		for r in rounds.size():
			for m in rounds[r]:
				s.fixtures.append({"id": s.fixtures.size(), "lg": lg.id, "rd": r + 1, "day": days[r], "h": m[0], "a": m[1], "hg": -1, "ag": -1, "played": false, "ko": false, "label": ""})
	G.build_index()
	G.CP.setup_season()
	# pre-season friendlies for the manager's club
	if s.user.has("club") and s.day < G.ymd(s.season, 7, 15):
		var me = s.clubs[s.user.club]
		var used = {me.id: true}
		var k = 0
		for md in [[7, 18], [7, 25], [8, 1]]:
			var day = G.CP.snap(md, 6)
			for t in 200:
				var o = s.clubs[G.rng.randi() % s.clubs.size()]
				if used.has(o.id) or s.leagues[o.lg].country == s.leagues[me.lg].country or abs(o.rep - me.rep) > 9:
					continue
				used[o.id] = true
				var id = s.fixtures.size()
				s.fixtures.append({"id": id, "lg": -1, "comp": "fr", "fr": true, "rd": 0, "day": day, "h": me.id if k % 2 == 0 else o.id, "a": o.id if k % 2 == 0 else me.id, "hg": -1, "ag": -1, "played": false, "ko": false, "label": "Pre-season friendly"})
				if not G.fx_by_day.has(day):
					G.fx_by_day[day] = []
				G.fx_by_day[day].append(id)
				k += 1
				break


static func add_ko(lg: int, h: int, a: int, day: int, label: String) -> int:
	var s = G.s
	var id = s.fixtures.size()
	s.fixtures.append({"id": id, "lg": lg, "rd": 0, "day": day, "h": h, "a": a, "hg": -1, "ag": -1, "played": false, "ko": true, "label": label})
	if not G.fx_by_day.has(day):
		G.fx_by_day[day] = []
	G.fx_by_day[day].append(id)
	if h == s.user.club or a == s.user.club:
		var opp = s.clubs[a if h == s.user.club else h]
		G.msg(label, "You face %s in the %s on %s. Everything is on the line." % [opp.name, label.to_lower(), G.fmt_date(day)], "board", null, true)
	return id


static func fx_winner(f: Dictionary) -> int:
	if f.hg > f.ag:
		return f.h
	if f.ag > f.hg:
		return f.a
	return f.h if f.pens[0] > f.pens[1] else f.a


static func update_playoffs():
	var s = G.s
	var start = G.ymd(s.season + 1, 5, 26)
	if s.day < start:
		return
	if s.day == start and s.playoffs.size() == 0:
		for li in LINKS.size():
			var l = LINKS[li]
			var tu = table(l[0])
			var tl = promo_table(l[1])
			var au = l[2]
			var b = {"link": li, "stage": 0, "fx": [], "done": false, "up": -1, "down": -1, "seeds": [], "upper": tu[tu.size() - au - 1]}
			var lname = s.leagues[l[1]].name
			if l[3] == "eng4":
				b.seeds = [tl[au], tl[au + 1], tl[au + 2], tl[au + 3]]
				b.down = b.upper
				b.fx.append(add_ko(l[1], b.seeds[0], b.seeds[3], s.day + 2, lname + " Play-off Semi-final"))
				b.fx.append(add_ko(l[1], b.seeds[1], b.seeds[2], s.day + 2, lname + " Play-off Semi-final"))
			elif l[3] == "rel":
				b.seeds = [tl[au]]
				b.fx.append(add_ko(l[1], b.upper, tl[au], s.day + 2, "%s Relegation Play-off" % s.leagues[l[0]].name))
			else:
				b.seeds = [tl[au], tl[au + 1], tl[au + 2]]
				b.fx.append(add_ko(l[1], tl[au + 1], tl[au + 2], s.day + 2, lname + " Play-off Round 1"))
			s.playoffs.append(b)
		return
	for b in s.playoffs:
		if b.done:
			continue
		var all_played = true
		for id in b.fx:
			if not s.fixtures[id].played:
				all_played = false
		if not all_played:
			continue
		var l = LINKS[b.link]
		var lname = s.leagues[l[1]].name
		var last = s.fixtures[b.fx[b.fx.size() - 1]]
		var w = fx_winner(last)
		if l[3] == "eng4":
			if b.stage == 0:
				var w1 = fx_winner(s.fixtures[b.fx[0]])
				var w2 = fx_winner(s.fixtures[b.fx[1]])
				var h = w1 if b.seeds.find(w1) < b.seeds.find(w2) else w2
				b.fx = [add_ko(l[1], h, w2 if h == w1 else w1, last.day + 4, lname + " Play-off Final")]
				b.stage = 1
			else:
				b.up = w
				b.done = true
		elif l[3] == "rel":
			_finish_rel(b, w)
		else:
			if b.stage == 0:
				b.fx = [add_ko(l[1], b.seeds[0], w, last.day + 4, lname + " Play-off Round 2")]
				b.stage = 1
			elif b.stage == 1:
				b.fx = [add_ko(l[1], b.upper, w, last.day + 4, "%s Relegation Play-off" % s.leagues[l[0]].name)]
				b.stage = 2
			else:
				_finish_rel(b, w)
		if b.done and b.up >= 0:
			G.news("%s win promotion to the %s through the play-offs." % [s.clubs[b.up].name, s.leagues[l[0]].name])


static func _finish_rel(b: Dictionary, w: int):
	b.done = true
	if w != b.upper:
		b.up = w
		b.down = b.upper
	else:
		G.news("%s survive the relegation play-off." % G.s.clubs[b.upper].name)


# ---------------------------------------------------------------- season end

static func top_scorer(lg: int):
	var best = null
	for cid in G.s.leagues[lg].clubs:
		for pid in G.s.clubs[cid].players:
			var p = G.s.players[pid]
			if best == null or p.ss.g > best.ss.g:
				best = p
	return best


static func rollover():
	var s = G.s
	var rng = G.rng
	var u = s.user
	var ucl = G.uc()
	var old_lg = ucl.lg
	var review = {"season": s.season, "leagues": [], "ups": [], "downs": [], "user": {}}
	# final tables, champions, awards
	var tables = []
	var champs = {}
	for lg in s.leagues:
		var t = table(lg.id)
		tables.append(t)
		if lg.roe:
			continue
		champs[lg.id] = s.clubs[t[0]].name
		var ts = top_scorer(lg.id)
		review.leagues.append({"lg": lg.id, "champ": t[0], "scorer": G.pname(ts) if ts != null else "", "goals": ts.ss.g if ts != null else 0, "scorer_club": s.clubs[ts.club].short if ts != null else ""})
	# season awards
	var awards = []
	var best = null
	var best_y = null
	for lg in s.leagues:
		if lg.roe or lg.tier != 1:
			continue
		var lb = null
		for cid in lg.clubs:
			for pid in s.clubs[cid].players:
				var p = s.players[pid]
				if p.ss.ap < 20:
					continue
				var r = G.avg_rating(p)
				if lb == null or r > G.avg_rating(lb):
					lb = p
				if best == null or r + p.ovr * 0.01 > G.avg_rating(best) + best.ovr * 0.01:
					best = p
				if G.age(p) <= 21 and (best_y == null or r > G.avg_rating(best_y)):
					best_y = p
		if lb != null:
			awards.append(["%s Player of the Season" % lg.name, G.pname(lb), s.clubs[lb.club].short, "%.2f avg · %d G · %d A" % [G.avg_rating(lb), lb.ss.g, lb.ss.a]])
	if best != null:
		awards.push_front(["World Player of the Year", G.pname(best), s.clubs[best.club].short, "%.2f avg · %d G · %d A" % [G.avg_rating(best), best.ss.g, best.ss.a]])
		G.news("%s is named World Player of the Year." % G.pfull(best))
	if best_y != null:
		awards.append(["Young Player of the Year", G.pname(best_y), s.clubs[best_y.club].short, "%.2f avg · age %d" % [G.avg_rating(best_y), G.age(best_y)]])
	review["awards"] = awards
	var cups = []
	for comp in s.get("comps", []):
		if comp.winner >= 0:
			cups.append([comp.name, comp.winner])
	review["cups"] = cups
	if not s.has("honours"):
		s["honours"] = {}
	var hon = []
	for lg in s.leagues:
		if not lg.roe:
			hon.append([tables[lg.id][0], lg.name])
	for x in cups:
		hon.append([x[1], x[0]])
	for x in hon:
		if not s.honours.has(x[0]):
			s.honours[x[0]] = []
		s.honours[x[0]].append([x[1], s.season])
	G.CP.qualify(tables)
	s.champs.push_front({"season": s.season, "c": champs})
	# user review
	var pos = tables[old_lg].find(ucl.id) + 1
	var obj = u.obj
	var met = pos <= obj.target
	var promoted = false
	var relegated = false
	# promotions / relegations
	var moves = []
	for li in LINKS.size():
		var l = LINKS[li]
		var tu = tables[l[0]]
		var tl = promo_table(l[1])
		var ups = tl.slice(0, l[2])
		var downs = tu.slice(tu.size() - l[2])
		for b in s.playoffs:
			if b.link == li:
				if b.up >= 0: ups.append(b.up)
				if b.down >= 0: downs.append(b.down)
		for cid in ups:
			moves.append([cid, l[0]])
			review.ups.append([cid, l[0]])
			if cid == ucl.id: promoted = true
		for cid in downs:
			moves.append([cid, l[1]])
			review.downs.append([cid, l[1]])
			if cid == ucl.id: relegated = true
	var title = pos == 1
	var note = ""
	if title:
		note = "Champions"
		u.trophies.append("%s %s" % [s.leagues[old_lg].name, G.season_name()])
		u["film"] = "league"
		G.OPS.mgr_bonus("league")
		G.OPS.life().cash += G.OPS.salary() * 20
		G.scrap("Champions", "%s won the %s" % [ucl.name, s.leagues[old_lg].name])
	elif promoted:
		u["film"] = "promo"
		G.OPS.mgr_bonus("promo")
		note = "Promoted"
	elif relegated:
		note = "Relegated"
	s.history.push_front({"season": s.season, "club": ucl.name, "lg": s.leagues[old_lg].name, "pos": pos, "w": ucl.t.w, "d": ucl.t.d, "l": ucl.t.l, "gf": ucl.t.gf, "ga": ucl.t.ga, "pts": ucl.t.pts, "note": note})
	u.rep = clamp(u.rep + (obj.exp - pos) * 1.2 + (10.0 if title else 0.0) + (6.0 if promoted else 0.0) - (6.0 if relegated else 0.0), 5.0, 100.0)
	u.conf = clamp(u.conf + (12.0 if met else -(pos - obj.target) * 5.0) + (15.0 if title or promoted else 0.0) - (20.0 if relegated else 0.0), 0.0, 100.0)
	review.user = {"pos": pos, "n": tables[old_lg].size(), "lg": old_lg, "obj": obj.text, "met": met, "note": note, "t": ucl.t.duplicate(), "conf": u.conf}
	for m in moves:
		var c = s.clubs[m[0]]
		s.leagues[c.lg].clubs.erase(c.id)
		c.lg = m[1]
		s.leagues[c.lg].clubs.append(c.id)
	# prize money before the reset
	for lg in s.leagues:
		var t = tables[lg.id]
		for i in t.size():
			var c = s.clubs[t[i]]
			var tierf = 0.12 if lg.roe else [1.0, 0.22, 0.07, 0.03][s.leagues[c.lg].tier - 1]
			var base = 900000.0 * pow(1.2, c.rep - 60.0)
			var prize = 40000000.0 * tierf * (1.0 - float(i) / t.size())
			if c.id == ucl.id:
				c.budget += G.nice(prize * 0.5)
			else:
				c.budget = G.nice(max(0.0, c.budget) * 0.6 + base * 0.6 + prize)
	s.season += 1
	G.MK.before_return()
	G.OPS.return_loans()
	var promoted_youth = []
	for pid in ucl.players:
		var yp0 = s.players[pid]
		if yp0.get("youth", false) and G.age(yp0) >= 21:
			yp0.erase("youth")
			promoted_youth.append(G.pname(yp0))
	if promoted_youth.size() > 0:
		G.msg("Academy graduates", "These players are too old for the youth team and have joined the first-team squad: " + ", ".join(promoted_youth) + ".", "info")
	# retirements and contracts
	var retired = []
	var left = []
	for pid in s.players.keys():
		var p = s.players[pid]
		var a = G.age(p)
		var limit = 37 if p.pos == "GK" else 34
		if a >= limit and rng.randf() < (a - limit + 1) * 0.28 + (0.3 if p.club < 0 else 0.0):
			if p.club == ucl.id:
				retired.append(G.pname(p))
			remove_player(p)
			continue
		if p.has("prec") and p.club >= 0 and p.cend <= s.season:
			# he signed a pre-contract during the season and now moves on a free transfer
			if p.club == ucl.id:
				left.append(G.pname(p))
			G.MK.fulfil_pre(p)
			continue
		p.erase("prec")
		if p.club >= 0 and p.cend <= s.season:
			var c = s.clubs[p.club]
			if p.club == ucl.id:
				left.append(G.pname(p))
				release(p)
			elif (p.ovr >= c.rep - 9 or a <= 23) and rng.randf() < 0.88:
				p.cend = s.season + rng.randi_range(1, 3)
				p.wage = max(p.wage, G.wage_for(p.ovr, a))
			else:
				release(p)
	# youth intake, squad trimming, resets
	for c in s.clubs:
		var country = s.leagues[c.lg].country
		var mine = c.id == ucl.id
		var acad = c.fac.academy if mine and c.has("fac") else 3
		for k in (2 + (1 if c.rep > 76 else 0) + (1 if mine and acad >= 4 else 0)):
			var nat = country if rng.randf() < 0.75 else s.leagues[rng.randi() % s.leagues.size()].country
			var o = clampi(int(c.rep) - 22 + rng.randi_range(-5, 6) + (acad - 3 if mine else 0), 40, 70)
			var pot = clampi(o + rng.randi_range(8, 22) + (rng.randi_range(0, 8) if rng.randf() < 0.15 else 0) + (acad - 3) * 3, o + 4, 94)
			var pos_opts = ["GK", "CB", "CB", "LB", "RB", "CDM", "CM", "CM", "CAM", "LM", "RM", "LW", "RW", "ST", "ST"]
			var yp = G.gen_player(c.id, pos_opts[rng.randi() % pos_opts.size()], rng.randi_range(16, 18), o, pot, nat)
			if c.id == ucl.id:
				yp["youth"] = true
				G.msg("Youth intake: %s" % G.pname(yp), "%s (%s, %d) has been promoted from the academy. The coaches rate his potential at %d." % [G.pfull(yp), yp.pos, G.age(yp), yp.pot], "info")
		if c.id != ucl.id and c.players.size() > 31:
			var arr = []
			for pid in c.players:
				arr.append(s.players[pid])
			arr.sort_custom(func(a, b): return a.ovr + (3 if G.age(a) < 21 else 0) < b.ovr + (3 if G.age(b) < 21 else 0))
			var gk = 0
			for p in arr:
				if p.pos == "GK": gk += 1
			for p in arr:
				if c.players.size() <= 29:
					break
				if p.pos == "GK" and gk <= 3:
					continue
				if p.pos == "GK": gk -= 1
				release(p)
		G.ensure_squad(c)
		c.t = G.new_table()
		c.form = []
		c.spent = 0
		c.earned = 0
		c.rep = c.rep * 0.4 + G.calc_rep(c) * 0.6
		c.wage_budget = G.nice(max(G.squad_wages(c) * 1.12, c.wage_budget * 0.9))
	for pid in s.players:
		var p = s.players[pid]
		G.PS.season_end(p)
		p.ss = G.new_stats()
		p.ycs = 0
		p.susp = 0
		p.cond = 100
		p.inj = min(p.inj, 40)
	# trim the free agent pool
	if s.free.size() > 250:
		var fa = []
		for pid in s.free:
			fa.append(s.players[pid])
		fa.sort_custom(func(a, b): return a.ovr > b.ovr)
		for i in range(250, fa.size()):
			remove_player(fa[i])
	s.tx_log = []
	s.negos = {}
	s.deals = {}
	s.offers = []
	G.MK.after_rollover()
	G.OPS.sponsor_call()
	generate_fixtures()
	u.obj = objective(ucl)
	G.fix_lineup()
	if retired.size() > 0:
		G.msg("Retirements", "The following players have retired from football: " + ", ".join(retired) + ".", "info")
	if left.size() > 0:
		G.msg("Contracts expired", "These players left the club at the end of their contracts: " + ", ".join(left) + ".", "contract")
	G.msg("Season %s" % G.season_name(), "A new season begins. The board's objective: %s.\n\nTransfer budget: %s. The transfer window is open until 31 August." % [u.obj.text, G.money(ucl.budget)], "board")
	if u.conf < 12.0:
		u.sacked = true
	if G.OPS.mc_rollover():
		u.sacked = true
	s.review = review
	G.refresh_jobs()


static func release(p: Dictionary):
	var s = G.s
	if p.club >= 0:
		var c = s.clubs[p.club]
		c.players.erase(p.id)
		c.bench.erase(p.id)
		var i = c.xi.find(p.id)
		if i >= 0:
			c.xi[i] = -1
	p.club = -1
	p.listed = false
	if not (p.id in s.free):
		s.free.append(p.id)


static func remove_player(p: Dictionary):
	var s = G.s
	release(p)
	s.free.erase(p.id)
	s.shortlist.erase(p.id)
	s.players.erase(p.id)

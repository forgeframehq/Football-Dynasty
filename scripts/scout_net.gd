extends RefCounted
# Scouting network (G.SN). Scouts you hire (each with a senior eye, a youth eye and a home region) go on missions:
# a region, one to three months, instructions (position, age, budget, what to look for). Reports arrive every week or
# two during the mission. Senior reports are real players with uncertain ranges ("potential 78-86") that narrow with
# better scouts and repeat reports; youth missions find 15-16 year-olds you can sign into the academy.
#
# Scouts are staff records (G.SF) with extra keys: region, net = true. Save: s.sn = {scouts [sid], missions [..],
# reports [..], prospects [..], next, alerted {pid: day}}. Club academy players are the existing youth = true players.

const REGIONS = {
	"British Isles": ["England", "Scotland", "Wales", "Northern Ireland", "Republic of Ireland"],
	"Iberia": ["Spain", "Portugal"],
	"France": ["France"],
	"Italy": ["Italy"],
	"Germany & Alps": ["Germany", "Austria", "Switzerland"],
	"Benelux": ["Holland", "Belgium", "Luxembourg", "Netherlands"],
	"Scandinavia": ["Denmark", "Norway", "Sweden", "Finland", "Iceland"],
	"Eastern Europe": ["Poland", "Czech Republic", "Ukraine", "Hungary", "Slovakia", "Romania", "Russia", "Georgia", "Bulgaria", "Czechia"],
	"Balkans & Turkey": ["Croatia", "Serbia", "Bosnia and Herzegovina", "Slovenia", "Albania", "Kosovo", "Greece", "Turkey", "North Macedonia", "Montenegro", "Türkiye"],
	"South America": ["Brazil", "Argentina", "Uruguay", "Colombia", "Ecuador", "Chile", "Venezuela", "Paraguay", "Peru", "Bolivia"],
	"Africa": ["Morocco", "Senegal", "Nigeria", "Côte d'Ivoire", "Ghana", "Algeria", "Cameroon", "Mali", "Congo DR", "Guinea", "Gambia", "Burkina Faso", "Tunisia", "Egypt"],
	"North America": ["United States", "Canada", "Mexico", "Jamaica"],
	"Asia & Oceania": ["Japan", "Korea Republic", "Australia", "New Zealand", "China PR", "Saudi Arabia"],
}
# how rich each region is in young talent, and how cheap
const TALENT = {"South America": 1.15, "Africa": 1.1, "Iberia": 1.1, "France": 1.1, "Benelux": 1.05, "Germany & Alps": 1.05, "British Isles": 1.0, "Italy": 1.0,
	"Balkans & Turkey": 1.0, "Scandinavia": 0.95, "Eastern Europe": 0.95, "North America": 0.9, "Asia & Oceania": 0.9}
const CHEAP = {"South America": 0.6, "Africa": 0.5, "Asia & Oceania": 0.6, "North America": 0.8, "Eastern Europe": 0.7, "Balkans & Turkey": 0.75}
const FOCUS = ["Potential", "Ready now", "Pace", "Technique", "Defending"]
const LINES = ["Any", "GK", "DEF", "MID", "ATT"]
const AGES = [["Any", 40], ["Under 24", 23], ["Under 21", 20]]
const BUDGETS = [["Any", 999999999], ["€5M", 5000000], ["€15M", 15000000], ["€40M", 40000000]]
const WHERE = ["Home-based", "In Europe", "Both"]
const COST = {"senior": 20000, "youth": 10000}     # travel each month of a mission
const YOUTH_POS = ["GK", "CB", "CB", "LB", "RB", "CDM", "CM", "CM", "CAM", "LM", "RM", "LW", "RW", "ST", "ST"]


static func ensure():
	var s = G.s
	if not s.has("sn"):
		s["sn"] = {"scouts": [], "missions": [], "reports": [], "prospects": [], "next": 1, "alerted": {}}
		# the club starts with one scout of its own
		var c = G.uc()
		var home = region_of(s.leagues[c.lg].country)
		var p = gen_scout(clampi(int((c.rep - 40.0) / 3.5), 6, 15), home)
		s.sn_free.erase(p.id)
		p.club = c.id
		p.cend = s.season + 2
		s.sn.scouts.append(p.id)
	if market().size() < 10:
		for i in 12:
			gen_scout(int(clamp(G.rng.randfn(10.5, 3.3), 4, 19)), REGIONS.keys()[G.rng.randi() % REGIONS.size()])


static func region_of(nat: String) -> String:
	for r in REGIONS:
		if nat in REGIONS[r]:
			return r
	return "British Isles"


static func gen_scout(q: int, region: String) -> Dictionary:
	var nat = REGIONS[region][G.rng.randi() % REGIONS[region].size()]
	var p = G.SF.gen("scout", q, nat)
	p["region"] = region
	p["net"] = true
	# some are senior specialists, some youth specialists
	var yb = G.rng.randi_range(-4, 4)
	p.a.youth = clampi(int(p.a.judge) + yb, 1, 20)
	p.wage = G.nice(int(G.SF.wage_for(p) * 0.7))
	G.s.staff_free.erase(p.id)
	if not G.s.has("sn_free"):
		G.s["sn_free"] = []
	G.s.sn_free.append(p.id)
	return p


static func market() -> Array:
	var s = G.s
	if not s.has("sn_free"):
		return []
	return s.sn_free.filter(func(x): return s.staff.has(x))


static func scouts() -> Array:
	var s = G.s
	return s.sn.scouts.filter(func(x): return s.staff.has(x)).map(func(x): return s.staff[x])


static func cap() -> int:
	return 1 + G.OPS.lvl("scouting")


static func eye(p: Dictionary, kind: String, region := "") -> float:
	# how good he is at this kind of mission here: his eye, +3 in his home region, + a little from the chief scout
	var v = float(p.a.judge if kind == "senior" else p.a.youth)
	if region != "" and region == p.region:
		v += 3.0
	v += (G.SF.r("scout") - 10.0) * 0.15
	return clamp(v, 1.0, 20.0)


static func busy(p: Dictionary) -> bool:
	for m in G.s.sn.missions:
		if int(m.sid) == int(p.id):
			return true
	return false


static func hire(p: Dictionary) -> String:
	var s = G.s
	if scouts().size() >= cap():
		return "Your scouting network has room for %d scouts. Upgrade the scouting facility for more." % cap()
	var c = G.uc()
	var want = G.SF.rating(p, "scout") * 3.4 + 22.0
	if want > c.rep + 8 and float((p.id * 7919 + s.day) % 100) / 100.0 > 0.5:
		return "%s would rather work for a bigger club." % G.SF.nm(p)
	s.sn_free.erase(p.id)
	s.sn.scouts.append(p.id)
	p.club = c.id
	p.cend = s.season + 2
	return ""


static func release(p: Dictionary):
	var s = G.s
	s.sn.scouts.erase(p.id)
	for i in range(s.sn.missions.size() - 1, -1, -1):
		if int(s.sn.missions[i].sid) == int(p.id):
			s.sn.missions.remove_at(i)
	p.club = -1
	s.sn_free.append(p.id)
	G.uc().budget = max(0, G.uc().budget - int(p.wage * 13))


static func wage_bill() -> int:
	var t = 0
	for p in scouts():
		t += int(p.wage)
	return t


# ---------------------------------------------------------------- missions

static func start(p: Dictionary, kind: String, region: String, months: int, line: int, age_i: int, focus: int, budget_i: int, where := 2) -> String:
	var s = G.s
	var c = G.uc()
	if busy(p):
		return "%s is already on a mission." % G.SF.nm(p)
	var cost = COST[kind] * months
	if c.budget < cost:
		return "The trip costs %s; the budget has %s." % [G.money(cost), G.money(c.budget)]
	c.budget -= cost
	var gap = report_gap(p, kind, region)
	s.sn.missions.append({"id": s.sn.next, "sid": p.id, "kind": kind, "region": region, "line": line, "age": age_i, "focus": focus, "budget": budget_i,
		"start": s.day, "end": s.day + months * 30, "nextr": s.day + gap, "found": 0, "where": where})
	s.sn.next += 1
	return ""


static func report_gap(p: Dictionary, kind: String, region: String) -> int:
	return clampi(int(16 - eye(p, kind, region) * 0.45), 6, 15)


static func daily():
	ensure()
	var s = G.s
	for i in range(s.sn.missions.size() - 1, -1, -1):
		var m = s.sn.missions[i]
		var p = s.staff.get(int(m.sid), null)
		if p == null:
			s.sn.missions.remove_at(i)
			continue
		if s.day >= int(m.nextr):
			if m.kind == "senior":
				_senior_report(p, m)
			else:
				_youth_report(p, m)
			m.nextr = s.day + report_gap(p, m.kind, m.region)
		if s.day >= int(m.end):
			s.sn.missions.remove_at(i)
			G.msg("%s is back from %s" % [G.SF.nm(p), m.region], "Your scout's %s mission is over. He filed %d report%s; they are in Scouting > %s." % ["youth" if m.kind == "youth" else "scouting", int(m.found), "" if int(m.found) == 1 else "s", "Youth Academy" if m.kind == "youth" else "Reports"], "info")
	# prospects nobody signs go elsewhere after two months
	for i in range(s.sn.prospects.size() - 1, -1, -1):
		if s.day - int(s.sn.prospects[i].day) > 60:
			s.sn.prospects.remove_at(i)
	if G.cur.weekday == 1:
		_shortlist_alerts()


static func _range(true_v: int, skill: float) -> Array:
	# a scout sees a range around the truth: narrower for a better eye; a weak scout can be off-centre
	var w = int(clamp(14.0 - skill * 0.6, 2.0, 11.0))
	var bias = 0
	if skill < 11 and G.rng.randf() < 0.4:
		bias = G.rng.randi_range(-w / 2, w / 2)
	var lo = true_v - G.rng.randi_range(0, w) + bias
	return [clampi(lo, 30, 99), clampi(lo + w, 30, 99)]


static func _senior_report(sc: Dictionary, m: Dictionary):
	var s = G.s
	var c = G.uc()
	var nats = REGIONS[m.region]
	var max_age = AGES[int(m.age)][1]
	var max_val = BUDGETS[int(m.budget)][1]
	var seen = {}
	for r in s.sn.reports:
		if r.has("pid"):
			seen[int(r.pid)] = true
	var cands = []
	var where = int(m.get("where", 2))
	for pid in s.players:
		var p = s.players[pid]
		if p.club == c.id or p.get("youth", false) or seen.has(pid):
			continue
		# home-based: playing in a league of this region (mostly hidden generated players); in Europe: from the region but playing in the big leagues
		var home = p.club >= 0 and s.leagues[s.clubs[p.club].lg].country in nats and s.leagues[s.clubs[p.club].lg].has("cont")
		var abroad = p.nat in nats and not home
		if not ((where != 1 and home) or (where != 0 and abroad)):
			continue
		if G.age(p) > max_age or G.value(p) > max_val:
			continue
		if int(m.line) > 0 and G.LINE[p.pos] != int(m.line) - 1:
			continue
		var at = p.get("at", [])
		var sc_v = 0.0
		match int(m.focus):
			0: sc_v = p.pot * 1.2 + p.ovr * 0.3 - G.age(p) * 0.4
			1: sc_v = p.ovr * 1.3 + p.pot * 0.2
			2: sc_v = p.ovr * 0.5 + float(p.st[0]) * 0.9
			3: sc_v = p.ovr * 0.5 + (float(p.st[2]) + float(p.st[3])) * 0.45
			4: sc_v = p.ovr * 0.5 + float(p.st[4]) * 0.9
		# value for money matters to every scout; a better one finds the hidden gems
		sc_v += (eye(sc, "senior", m.region) - 10.0) * 0.3 * float(p.pot - p.ovr) / 10.0
		sc_v -= G.value(p) / 4000000.0
		sc_v += G.rng.randf() * 6.0
		cands.append([sc_v, p])
	if cands.is_empty():
		return
	cands.sort_custom(func(a, b): return a[0] > b[0])
	var p = cands[0][1]
	add_report(p, sc, m.region)
	m.found = int(m.found) + 1


static func add_report(p: Dictionary, sc: Dictionary, region := "") -> Dictionary:
	var s = G.s
	var sk = eye(sc, "senior", region)
	var pr = _range(int(p.pot), sk)
	var orr = _range(int(p.ovr), sk + 4.0)
	pr[0] = max(pr[0], orr[0])
	var mid = (pr[0] + pr[1]) / 2.0
	var verdict = "Sign him" if mid >= G.uc().rep + 4 else ("Good squad player" if mid >= G.uc().rep - 3 else ("One for the future" if p.pot - p.ovr >= 8 else "Not good enough"))
	var r = {"id": s.sn.next, "pid": p.id, "day": s.day, "sid": sc.id, "scout": G.SF.nm(sc), "stars": G.SF.stars(sk), "pot": pr, "ovr": orr, "verdict": verdict,
		"fee": G.nice(int(G.value(p) * G.rng.randf_range(0.9, 1.25)))}
	s.sn.next += 1
	# a second report on the same player narrows what you know
	for old in s.sn.reports:
		if int(old.get("pid", -1)) == p.id:
			r.pot = [max(r.pot[0], old.pot[0]), min(r.pot[1], old.pot[1])] if max(r.pot[0], old.pot[0]) <= min(r.pot[1], old.pot[1]) else r.pot
			s.sn.reports.erase(old)
			break
	s.sn.reports.push_front(r)
	while s.sn.reports.size() > 80:
		s.sn.reports.pop_back()
	return r


static var _ri := {}
static var _ri_n := -1
static var _ri_list = null


static func report_for(pid: int):
	# indexed: search asks this for every generated player, so a scan of all reports each time was the slow part
	if not G.s.has("sn"):
		return null
	var reps = G.s.sn.reports
	if not is_same(reps, _ri_list) or reps.size() != _ri_n:
		_ri.clear()
		for k in range(reps.size() - 1, -1, -1):
			_ri[int(reps[k].get("pid", -1))] = reps[k]   # newest (front) wins, as the old scan did
		_ri_list = reps
		_ri_n = reps.size()
	return _ri.get(pid, null)


static func _youth_report(sc: Dictionary, m: Dictionary):
	# a 15 or 16 year-old found on the youth circuit
	var s = G.s
	var rng = G.rng
	var nats = REGIONS[m.region].filter(func(n): return DB.names.has(n))
	if nats.is_empty():
		nats = REGIONS[m.region]
	var nat = nats[rng.randi() % nats.size()]
	var sk = eye(sc, "youth", m.region)
	var talent = float(TALENT.get(m.region, 1.0))
	var pos = YOUTH_POS[rng.randi() % YOUTH_POS.size()]
	if int(m.line) > 0:
		var tries = 0
		while G.LINE[pos] != int(m.line) - 1 and tries < 30:
			pos = YOUTH_POS[rng.randi() % YOUTH_POS.size()]
			tries += 1
	var ovr = clampi(int(rng.randfn(48.0, 5.0) + (sk - 10.0) * 0.3), 38, 62)
	# potential: a better eye and a richer region find better kids; true stars stay rare
	var pot = int(ovr + rng.randi_range(14, 31) * talent + (sk - 10.0) * 0.5 + (rng.randi_range(0, 8) if rng.randf() < 0.08 else 0))
	if int(m.focus) == 0:
		pot += 2
	pot = clampi(pot, ovr + 6, 93)
	var nm = DB.random_name(nat, rng)
	var pr = _range(pot, sk)
	var fee = G.nice(int((20000.0 + pow(max(0.0, (pr[0] + pr[1]) / 2.0 - 60.0), 2.2) * 900.0) * float(CHEAP.get(m.region, 1.0))))
	s.sn.prospects.push_front({"id": s.sn.next, "fn": nm[0], "ln": nm[1], "nat": nat, "pos": pos, "age": rng.randi_range(15, 16), "ovr": ovr, "pot": pot,
		"pr": pr, "fee": fee, "day": s.day, "scout": G.SF.nm(sc), "stars": G.SF.stars(sk), "region": m.region})
	s.sn.next += 1
	m.found = int(m.found) + 1
	if pr[1] >= 85:
		G.msg("Exciting prospect: %s %s" % [nm[0], nm[1]], "%s has found a %s-year-old %s in %s and rates his potential %d-%d. He is in Scouting > Youth Academy; other clubs will hear about him soon." % [G.SF.nm(sc), str(s.sn.prospects[0].age), pos, nat, pr[0], pr[1]], "info", null, true)


static func academy_cap() -> int:
	return 10 + 2 * G.OPS.lvl("academy")


static func academy() -> Array:
	var s = G.s
	return G.uc().players.filter(func(x): return s.players[x].get("youth", false)).map(func(x): return s.players[x])


static func sign(pr: Dictionary) -> String:
	var s = G.s
	var c = G.uc()
	if academy().size() >= academy_cap():
		return "The academy is full (%d). Promote or release someone, or upgrade the academy." % academy_cap()
	if c.budget < int(pr.fee):
		return "He costs %s; the budget has %s." % [G.money(pr.fee), G.money(c.budget)]
	c.budget -= int(pr.fee)
	var p = G.gen_player(c.id, pr.pos, int(pr.age), int(pr.ovr), int(pr.pot), pr.nat)
	p.fn = pr.fn
	p.ln = pr.ln
	p["youth"] = true
	p.wage = G.nice(max(500, int(p.wage * 0.2)))
	p.cend = s.season + 3
	G.give_number(c, p)
	s.sn.prospects.erase(pr)
	G.msg("%s joins the academy" % G.pname(p), "%s (%s, %d, from %s) has signed for %s. Fee %s." % [G.pfull(p), p.pos, G.age(p), p.nat, G.money(pr.fee)], "info")
	return ""


static func promote(p: Dictionary):
	p.erase("youth")
	p.wage = max(p.wage, G.wage_for(p.ovr, G.age(p)))


static func ready(p: Dictionary) -> bool:
	# good enough to train with the first team
	var c = G.uc()
	var avg = 0.0
	var n = 0
	for pid in c.xi:
		if pid >= 0:
			avg += G.s.players[pid].ovr
			n += 1
	avg /= max(1, n)
	return p.ovr >= avg - 10 or G.age(p) >= 20


static func _shortlist_alerts():
	# a shortlisted player becomes available: transfer listed, a free agent, or in the last months of his contract
	var s = G.s
	for pid in s.shortlist:
		if not s.players.has(pid):
			continue
		var p = s.players[pid]
		var why = ""
		if p.club < 0:
			why = "is a free agent"
		elif p.get("listed", false):
			why = "has been transfer listed by %s" % s.clubs[p.club].name
		elif p.cend <= s.season and G.cur.month in [1, 2, 3, 4, 5]:
			why = "is in the last months of his contract (pre-contract talks are open)"
		if why == "":
			continue
		var key = "%d%s" % [pid, why.substr(0, 6)]
		if s.sn.alerted.has(key):
			continue
		s.sn.alerted[key] = s.day
		G.msg("Shortlist: %s available" % G.pname(p), "%s %s." % [G.pfull(p), why], "deal", p.id)

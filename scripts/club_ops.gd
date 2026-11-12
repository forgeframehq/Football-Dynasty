extends RefCounted
# Club operations: facilities, weekly finances, training, scouting, loans and the manager profile.

const FAC = ["stadium", "training", "academy", "medical", "scouting", "commercial"]
const FAC_NAME = {"stadium": "Stadium", "training": "Training ground", "academy": "Youth academy", "medical": "Medical centre", "scouting": "Scouting network", "commercial": "Commercial"}
const FAC_ICON = {"stadium": "landmark", "training": "activity", "academy": "graduation-cap", "medical": "bandage", "scouting": "search", "commercial": "trending-up"}
const CAPACITY = [9000, 19000, 33000, 54000, 80000]
const COST_F = [0.12, 0.25, 0.45, 0.75]
const BADGES = ["National C", "National B", "UEFA B", "UEFA A", "UEFA Pro"]
const BACKGROUNDS = ["Sunday league", "Semi-pro", "Professional", "International"]
const MATTR = [["tac", "Tactical knowledge", "Small boost to your team's control of matches"], ["mot", "Motivation", "Better team talks and squad morale"],
	["you", "Youth development", "Young players improve faster"], ["neg", "Negotiation", "Lower transfer fees and wage demands"]]
const FOCUS = ["Balanced", "Attacking", "Defending", "Possession", "Fitness"]
const FOCUS_ATTR = [[], [0, 1, 12], [10, 11, 2], [4, 5, 6, 15], [7, 8, 9]]
const INTENSITY = ["Light", "Normal", "Intense"]
const INDIV = {"Shooting": [0, 1], "Passing": [4, 5, 15], "Dribbling": [6, 3], "Defending": [10, 11], "Physical": [7, 8, 9], "Aerial": [2, 9], "Set pieces": [16, 17], "Mentality": [12, 13]}


static func default_profile() -> Dictionary:
	return {"name": "Manager", "nat": "England", "badge": 2, "bg": 1, "attr": {"tac": 10, "mot": 10, "you": 10, "neg": 10}}


static func points_for(badge: int, bg: int) -> int:
	return 16 + badge * 5 + bg * 3


static func ensure(c: Dictionary):
	var s = G.s
	if not c.has("fac"):
		var base = clampi(int(round((c.rep - 54.0) / 6.5)), 1, 5)
		c["fac"] = {}
		for k in FAC:
			c.fac[k] = clampi(base + (G.rng.randi_range(-1, 0) if k != "stadium" else 0), 1, 5)
		c["build"] = null
		c["bank_log"] = []
		c["fin"] = {"tickets": 0, "sponsor": 0, "tv": 0, "wages": 0, "upkeep": 0, "home": 0}
	if not c.has("train"):
		c["train"] = {"focus": 0, "inten": 1}
	if not s.has("scout"):
		s["scout"] = {"queue": [], "known": {}, "assign": null, "next": 0}
	if not s.has("retrain"):
		s["retrain"] = []
	var u = s.user
	if not u.has("attr"):
		var d = default_profile()
		for k in ["nat", "badge", "bg", "attr"]:
			u[k] = d[k]
	if not u.has("points"):
		u["points"] = 0
		u["study"] = 0


static func lvl(key: String) -> int:
	var c = G.uc()
	return c.fac[key] if c.has("fac") else 3


static func capacity(c: Dictionary) -> int:
	return CAPACITY[c.fac.stadium - 1] if c.has("fac") else 30000


static func upgrade_cost(c: Dictionary, key: String) -> int:
	var l = c.fac[key]
	if l >= 5:
		return 0
	return G.nice(c.wage_budget * 52.0 * COST_F[l - 1] * (1.6 if key == "stadium" else 1.0))


static func upgrade_days(c: Dictionary, key: String) -> int:
	return (40 if key == "stadium" else 25) * c.fac[key]


static func start_upgrade(key: String) -> String:
	var c = G.uc()
	if c.build != null:
		return "Builders are still working on the %s." % FAC_NAME[c.build.key].to_lower()
	if c.fac[key] >= 5:
		return "Already at the top level."
	var cost = upgrade_cost(c, key)
	if cost > c.budget:
		return "You need %s in the budget for this." % G.money(cost)
	c.budget -= cost
	c.build = {"key": key, "done": G.s.day + upgrade_days(c, key), "cost": cost}
	return ""


static func effect_text(key: String, l: int) -> String:
	match key:
		"stadium": return "%s seats · bigger gates every home game" % _thousands(CAPACITY[l - 1])
		"training": return "Player growth %+d%%" % int(round((0.85 + 0.075 * l - 1.0) * 100))
		"academy": return "Youth intake potential %+d%s" % [(l - 3) * 3, " · extra prospect" if l >= 4 else ""]
		"medical": return "Injuries last %d%% %s" % [abs(int(round((1.15 - 0.07 * l - 1.0) * 100))), "longer" if l < 3 else "shorter"]
		"scouting": return "Reports in %d days · %d players at once" % [12 - 2 * l, 1 + l]
		"commercial": return "Sponsorship worth %d%% of the wage budget" % int(round((0.86 + 0.03 * l) * 100))
	return ""


static func _thousands(n: int) -> String:
	var t = str(n)
	return t.substr(0, t.length() - 3) + "," + t.substr(t.length() - 3) if t.length() > 3 else t


# ---------------------------------------------------------------- daily / weekly

static func daily():
	var s = G.s
	var c = G.uc()
	if not c.has("fac"):
		ensure(c)
	if c.build != null and s.day >= c.build.done:
		c.fac[c.build.key] += 1
		G.msg("%s upgraded" % FAC_NAME[c.build.key], "Work is complete: your %s is now level %d. %s." % [FAC_NAME[c.build.key].to_lower(), c.fac[c.build.key], effect_text(c.build.key, c.fac[c.build.key])], "board", null, true)
		c.build = null
	# scouting queue
	var sc = s.scout
	for i in range(sc.queue.size() - 1, -1, -1):
		var q = sc.queue[i]
		if not s.players.has(q.pid):
			sc.queue.remove_at(i)
		elif s.day >= q.done:
			sc.queue.remove_at(i)
			sc.known[q.pid] = true
			var p = s.players[q.pid]
			var room = p.pot - p.ovr
			var verdict = "a finished article" if room <= 1 else ("some room to grow" if room <= 4 else ("a real prospect" if room <= 9 else "a potential star"))
			G.msg("Scout report: %s" % G.pname(p), "%s (%s, %d) is rated %d now with a potential of %d — %s. Value around %s." % [G.pfull(p), p.pos, G.age(p), p.ovr, p.pot, verdict, G.money(G.value(p))], "info", null, true)
	if sc.assign != null and s.day >= sc.next:
		_assignment_report()
	# position retraining
	for i in range(s.retrain.size() - 1, -1, -1):
		var pid = s.retrain[i]
		if not s.players.has(pid) or not s.players[pid].has("rt"):
			s.retrain.remove_at(i)
			continue
		var p = s.players[pid]
		p.rt[1] -= 1
		if p.rt[1] <= 0:
			if not (p.rt[0] in p.alt) and p.rt[0] != p.pos:
				p.alt.append(p.rt[0])
			G.msg("%s can now play %s" % [G.pname(p), p.rt[0]], "%s has finished his position training and is comfortable at %s." % [G.pfull(p), p.rt[0]], "info")
			p.erase("rt")
			s.retrain.remove_at(i)
	# coaching course
	var u = s.user
	if u.get("study", 0) > 0 and s.day >= u.study:
		u.study = 0
		u.badge = min(4, u.badge + 1)
		u.points += 3
		u.rep = min(100.0, u.rep + 5.0)
		G.msg("Coaching badge earned", "Congratulations — you now hold the %s licence. You have 3 new attribute points to spend in the board room." % BADGES[u.badge], "board", null, true)
	if G.cur.weekday == 1:
		weekly()


static func weekly():
	var s = G.s
	var c = G.uc()
	var tier = s.leagues[c.lg].tier
	var wages = G.squad_wages(c)
	var sponsor = int(c.wage_budget * (0.86 + 0.03 * c.fac.commercial))
	var tv = int(c.wage_budget * 0.05)
	var price = [46, 30, 20, 15][clampi(tier - 1, 0, 3)]
	var fill = clamp(0.55 + (c.rep - 55.0) * 0.012 + (0.1 if c.form.count("W") >= 3 else 0.0), 0.35, 0.98)
	var tickets = int(c.fin.home * capacity(c) * fill * price)
	var levels = 0
	for k in FAC:
		levels += c.fac[k]
	var upkeep = int(c.wage_budget * 0.011 * levels)
	var net = sponsor + tv + tickets - wages - upkeep
	c.budget += net
	c.fin = {"tickets": tickets, "sponsor": sponsor, "tv": tv, "wages": wages, "upkeep": upkeep, "home": 0, "net": net}
	c.bank_log.push_front(net)
	if c.bank_log.size() > 12:
		c.bank_log.resize(12)
	var u = s.user
	for pid in c.players:
		var p = s.players[pid]
		if u.attr.mot >= 14 and p.mor < 70:
			p.mor += 1
		if p.get("loan", -1) >= 0 or p.get("youth", false):
			continue
		var un = p.get("unhappy", 0)
		if un == 0 and p.mor < 36 and G.status_of(p) <= 1:
			p["unhappy"] = s.day
			G.msg("%s is unhappy" % G.pname(p), "%s feels he is not playing enough and wants reassurance. Give him games, change his squad status, or expect a transfer request." % G.pfull(p), "contract", null, true)
		elif un > 0 and p.mor >= 55:
			p.erase("unhappy")
			G.msg("%s is settled again" % G.pname(p), "%s is happy with his situation at the club." % G.pfull(p), "info")
		elif un > 0 and s.day - un > 35 and not p.listed:
			p.listed = true
			G.msg("Transfer request: %s" % G.pname(p), "%s has handed in a transfer request and has been placed on the transfer list." % G.pfull(p), "contract", null, true)


static func on_home_match(c: Dictionary):
	if c.has("fin"):
		c.fin.home += 1


# ---------------------------------------------------------------- training

static func growth_mult(p: Dictionary) -> float:
	# extra development factor for the user's players
	var c = G.uc()
	var u = G.s.user
	var m = (0.85 + 0.075 * c.fac.training) * [0.9, 1.0, 1.12][c.train.inten]
	if c.train.focus == 0:
		m *= 1.05
	if G.age(p) <= 21:
		m *= 1.0 + (u.attr.you - 10) * 0.02
	return m


static func monthly_training():
	var s = G.s
	var c = G.uc()
	var rng = G.rng
	var fa = FOCUS_ATTR[c.train.focus]
	for pid in c.players:
		var p = s.players[pid]
		if p.pos == "GK":
			continue
		var cap = p.pot + 4
		if fa.size() > 0 and rng.randf() < 0.22 * [0.8, 1.0, 1.25][c.train.inten]:
			var k = fa[rng.randi() % fa.size()]
			if p.at[k] < cap:
				p.at[k] += 1
		var tf = p.get("tr", "")
		if tf != "" and INDIV.has(tf) and rng.randf() < 0.5:
			var arr = INDIV[tf]
			var k = arr[rng.randi() % arr.size()]
			if p.at[k] < cap:
				p.at[k] += 1


static func recover_rate(p: Dictionary) -> int:
	var c = G.uc()
	return [7, 6, 5][c.train.inten] + (1 if c.fac.medical >= 4 else 0)


static func injury_days(days: int) -> int:
	return max(2, int(days * (1.15 - 0.07 * lvl("medical"))))


static func start_retrain(p: Dictionary, pos: String):
	p["rt"] = [pos, 100 - lvl("training") * 8]
	if not (p.id in G.s.retrain):
		G.s.retrain.append(p.id)


# ---------------------------------------------------------------- scouting

static func knows(p: Dictionary) -> bool:
	return p.club == G.s.user.club or p.get("loan", -1) == G.s.user.club or G.s.scout.known.has(p.id)


static func pot_text(p: Dictionary) -> String:
	if knows(p):
		return str(p.pot)
	var h = (p.id * 2654435761) % 97
	var lo = max(p.ovr, p.pot - 3 - h % 4)
	var hi = min(99, max(lo + 3, p.pot + 2 + (h / 4) % 5))
	return "%d–%d" % [lo, hi]


static func scout_days() -> int:
	return 12 - 2 * lvl("scouting")


static func scout_player(p: Dictionary) -> String:
	var sc = G.s.scout
	for q in sc.queue:
		if q.pid == p.id:
			return "Your scouts are already watching him."
	if sc.queue.size() >= 1 + lvl("scouting"):
		return "Your scouts are busy (%d players at once). Upgrade the scouting network for more." % (1 + lvl("scouting"))
	sc.queue.append({"pid": p.id, "done": G.s.day + scout_days()})
	return ""


static func set_assignment(lg: int, line: int, young: bool):
	var sc = G.s.scout
	sc.assign = {"lg": lg, "line": line, "young": young}
	sc.next = G.s.day + scout_days() + 3


static func _assignment_report():
	var s = G.s
	var sc = s.scout
	var a = sc.assign
	sc.next = s.day + scout_days() + 6
	var c = G.uc()
	var cands = []
	for cid in s.leagues[a.lg].clubs:
		if cid == c.id:
			continue
		for pid in s.clubs[cid].players:
			var p = s.players[pid]
			if sc.known.has(pid) or (a.line >= 0 and G.LINE[p.pos] != a.line) or (a.young and G.age(p) > 22):
				continue
			if p.ovr > c.rep + 7 or G.value(p) > max(c.budget, 500000) * 1.6:
				continue
			cands.append(p)
	cands.sort_custom(func(x, y): return x.pot * 1.0 + x.ovr * 0.6 > y.pot * 1.0 + y.ovr * 0.6)
	var names = []
	for i in min(3, cands.size()):
		var p = cands[i]
		sc.known[p.id] = true
		if not (p.id in s.shortlist):
			s.shortlist.append(p.id)
		names.append("%s (%s, %d) — %d now, %d potential, about %s" % [G.pfull(p), p.pos, G.age(p), p.ovr, p.pot, G.money(G.value(p))])
	if names.size() > 0:
		G.msg("Scouting report: %s" % s.leagues[a.lg].name, "Your scouts recommend:\n\n" + "\n\n".join(names) + "\n\nAll three have been added to your shortlist.", "info", null, true)


# ---------------------------------------------------------------- loans

static func _shift(p: Dictionary, to_id: int):
	var s = G.s
	if p.club >= 0:
		var fc = s.clubs[p.club]
		fc.players.erase(p.id)
		fc.bench.erase(p.id)
		var i = fc.xi.find(p.id)
		if i >= 0:
			fc.xi[i] = -1
		G.lu_cache.erase(fc.id)
	var tc = s.clubs[to_id]
	tc.players.append(p.id)
	p.club = to_id
	p.listed = false
	G.give_number(tc, p)
	G.lu_cache.erase(to_id)


static func loan_out(p: Dictionary) -> String:
	var s = G.s
	var uc = G.uc()
	if uc.players.size() <= 18:
		return "You need at least 18 players."
	var best = null
	for t in 80:
		var c = s.clubs[G.rng.randi() % s.clubs.size()]
		if c.id == uc.id or c.players.size() >= 30 or c.rep > p.ovr + 4 or c.rep < p.ovr - 9:
			continue
		var better = 0
		for pid in c.players:
			if s.players[pid].ovr > p.ovr and G.LINE[s.players[pid].pos] == G.LINE[p.pos]:
				better += 1
		if better > 2:
			continue
		if best == null or c.rep > best.rep:
			best = c
	if best == null:
		return "No club is offering %s regular football right now." % G.pname(p)
	_shift(p, best.id)
	p["loan"] = uc.id
	p.erase("youth")
	G.fix_lineup()
	G.news("%s joins %s on loan from %s." % [G.pfull(p), best.name, uc.name])
	G.msg("%s loaned out" % G.pname(p), "%s has joined %s on loan until the end of the season. They will pay his wages." % [G.pfull(p), best.name], "info")
	return ""


static func can_loan_in(p: Dictionary) -> Dictionary:
	var uc = G.uc()
	if p.club < 0 or p.get("loan", -1) >= 0:
		return {"ok": false, "why": "Not available for loan."}
	if not G.window_open():
		return {"ok": false, "why": "The transfer window is closed."}
	if uc.players.size() >= G.TR.MAX_SQUAD:
		return {"ok": false, "why": "Your squad is full."}
	var c = G.s.clubs[p.club]
	if not p.listed and (G.TR.squad_rank(p) < 13 or G.age(p) > 24):
		return {"ok": false, "why": "%s consider him part of their first-team plans." % c.name}
	if p.ovr > uc.rep + 6:
		return {"ok": false, "why": "%s want him to play at a higher level." % c.name}
	if G.squad_wages(uc) + p.wage > uc.wage_budget:
		return {"ok": false, "why": "You cannot cover his %s weekly wage." % G.money(p.wage)}
	return {"ok": true, "why": ""}


static func loan_in(p: Dictionary):
	var from = p.club
	_shift(p, G.s.user.club)
	p["loan"] = from
	G.news("%s joins %s on loan from %s." % [G.pfull(p), G.uc().name, G.s.clubs[from].name])


static func return_loans():
	var s = G.s
	for pid in s.players:
		var p = s.players[pid]
		var o = p.get("loan", -1)
		if o >= 0:
			p.erase("loan")
			if o != p.club:
				_shift(p, o)

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
	c.build = {"key": key, "done": G.s.day + upgrade_days(c, key), "cost": cost, "days": upgrade_days(c, key)}
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
	mc_daily()
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
			var sk = G.TC.skill_names(p)
			var extra = "\n\nSkills: %s." % (", ".join(sk) if sk.size() > 0 else "none of note")
			extra += "\n%s" % G.TC.fit_text(p)
			extra += "\nInjury record: %s. Form: %s." % [["fragile", "normal", "robust"][G.TC.inj_res(p) - 1], "streaky" if G.TC.form_type(p) == 1 else "steady"]
			G.msg("Scout report: %s" % G.pname(p), "%s (%s, %d) is rated %d now with a potential of %d: %s. Value around %s.%s" % [G.pfull(p), p.pos, G.age(p), p.ovr, p.pot, verdict, G.money(G.value(p)), extra], "deal", p.id, true)
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
		G.TC.on_badge()
		u.rep = min(100.0, u.rep + 5.0)
		G.msg("Coaching badge earned", "Congratulations — you now hold the %s licence. You have 3 new attribute points to spend in the board room." % BADGES[u.badge], "board", null, true)
	market_day(life())
	if G.cur.weekday == 1:
		weekly()
		G.TC.weekly()


static func life() -> Dictionary:
	var u = G.s.user
	if not u.has("life"):
		u["life"] = {"cash": 20000, "home": 0, "car": 0, "lang": {}, "study": "", "income": 0, "settled": 10.0, "biz": [], "country": ""}
	return u.life


static func club_value(c: Dictionary) -> int:
	return G.nice(c.wage_budget * 52.0 * 1.4 + CAPACITY[c.fac.stadium - 1] * 900.0 if c.has("fac") else c.wage_budget * 52.0 * 1.6)


const HOME_UP = [0, 300, 1200, 4000, 12000]
const CAR_UP = [0, 150, 500, 1800, 5000, 60, 140, 220, 420, 700, 330, 1000, 2600, 7000]
const HOME_PRICE = [0, 180000, 900000, 3500000, 12000000]
const CAR_PRICE = [0, 45000, 160000, 600000, 2500000, 14000, 38000, 62000, 120000, 210000, 95000, 320000, 950000, 2900000]


static func car_stock() -> Array:
	# the cars the dealers have this month: seven of the range, the first of them on offer
	var ids = range(1, CAR_PRICE.size())
	var rng = RandomNumberGenerator.new()
	rng.seed = G.s.season * 97 + int(G.s.day / 30) * 13 + 5
	for i in range(ids.size() - 1, 0, -1):
		var j = rng.randi() % (i + 1)
		var t = ids[i]
		ids[i] = ids[j]
		ids[j] = t
	return ids.slice(0, 7)


static func car_price(i: int) -> int:
	var st = car_stock()
	return int(CAR_PRICE[i] * 0.88) if not st.is_empty() and st[0] == i else CAR_PRICE[i]


# ---------------------------------------------------------------- the manager's own contract

const MC_BONUS = [["None", 0.0], ["Standard", 1.0], ["Big", 2.0]]


static func mc() -> Dictionary:
	# the manager's deal with his club: last season it covers, bonus level, release clause (weeks of salary a
	# new club must pay; 0 = none), patience left in the current talks
	var u = G.s.user
	if not u.has("mc"):
		u["mc"] = {"end": G.s.season + 1, "bonus": 1, "clause": 0, "pat": 100, "talk_day": -400, "asked": -1}
	return u.mc


static func board_value() -> int:
	# the most the board will pay a week, before the extras are counted
	var u = G.s.user
	var c = G.uc()
	var base = c.wage_budget * 0.012 * (0.5 + u.rep / 100.0)
	var v = base * (0.75 + u.conf / 100.0 * 0.7)
	if life().get("agent", false):
		v *= 1.08
	if not u.get("jobs", []).is_empty():
		v *= 1.07          # other clubs are asking about you
	return G.nice(max(v, salary() * (0.9 if u.conf < 40.0 else 1.0)))


static func mc_can_talk() -> String:
	# "" when talks can open, otherwise the reason they cannot
	var u = G.s.user
	var m = mc()
	if G.s.day - int(m.talk_day) < 90 and int(m.pat) <= 0:
		return "The board walked away from the last talks. They will sit down again in %d days." % (90 - (G.s.day - int(m.talk_day)))
	if u.conf < 35.0:
		return "The board will not discuss a new deal while confidence in you is this low."
	if int(m.end) > G.s.season and G.s.day - int(u.get("raise_day", -400)) < 180:
		return "You signed recently. The board will talk again in %d days." % (180 - (G.s.day - int(u.get("raise_day", -400))))
	return ""


static func mc_propose(ask: int, years: int, bonus: int, clause: int) -> Dictionary:
	# -> {res: "accept" | "counter" | "reject" | "dead", text, offer}
	var u = G.s.user
	var m = mc()
	if int(m.pat) <= 0 or G.s.day - int(m.talk_day) > 30:
		m.pat = 100
	m.talk_day = G.s.day
	var top = float(board_value())
	top *= 1.0 - 0.04 * bonus                      # bonuses come out of what they will pay weekly
	if clause == 1:
		top *= 0.95                                # a cheap way out for you costs them security
	elif clause == 2:
		top *= 1.02
	var max_years = 1 if u.conf < 50.0 else (2 if u.conf < 65.0 else (3 if u.conf < 80.0 else 4))
	if years > max_years:
		m.pat = max(0, int(m.pat) - 20)
		return {"res": "counter", "text": "The board will not commit beyond %d season%s at the moment." % [max_years, "" if max_years == 1 else "s"], "offer": G.nice(min(ask, top)), "years": max_years}
	if ask <= top:
		u["salary"] = ask
		u["raise_day"] = G.s.day
		m.end = G.s.season + years - (0 if (G.s.day > 200 and int(m.end) <= G.s.season) else 1)
		m.bonus = bonus
		m.clause = clause
		m.pat = 100
		m.asked = -1
		u.conf = min(100.0, u.conf + 1.0)
		G.msg("New contract signed", "You have agreed terms with the board of %s: %s a week until the end of the %d/%02d season, %s bonuses%s." % [G.uc().name, G.money(ask), int(m.end), (int(m.end) + 1) % 100, MC_BONUS[bonus][0].to_lower(), "" if clause == 0 else ", with a release clause"], "board")
		return {"res": "accept", "text": "The chairman shakes your hand. It is done.", "offer": ask, "years": years}
	if ask <= top * 1.15:
		m.pat = max(0, int(m.pat) - 25)
		if int(m.pat) <= 0:
			u.conf = max(0.0, u.conf - 2.0)
			return {"res": "dead", "text": "The board has run out of patience and ended the talks.", "offer": 0, "years": years}
		return {"res": "counter", "text": "Too much, the chairman says, but he can go to %s a week." % G.money(G.nice(top)), "offer": G.nice(top), "years": years}
	m.pat = max(0, int(m.pat) - 40)
	if int(m.pat) <= 0:
		u.conf = max(0.0, u.conf - 3.0)
		return {"res": "dead", "text": "The board has run out of patience and ended the talks.", "offer": 0, "years": years}
	return {"res": "reject", "text": "The chairman laughs it off. That is nowhere near what the club will pay.", "offer": 0, "years": years}


static func mc_daily():
	# in the last season of the deal the board comes to you, once, if they want to keep you
	var u = G.s.user
	var m = mc()
	if int(m.end) <= G.s.season and int(m.asked) != G.s.season and G.s.day >= 150 and not u.sacked:
		m.asked = G.s.season
		if u.conf >= 45.0:
			G.msg("The board wants to talk", "Your contract at %s runs out at the end of this season. The board would like you to stay and has invited you to discuss new terms. Open My Contract to negotiate: salary, length, bonuses and a release clause are all on the table." % G.uc().name, "mycontract", null, true)
		else:
			G.msg("No new contract on the table", "Your contract at %s runs out at the end of this season and the board has not offered new terms. Results between now and then will decide whether they do." % G.uc().name, "mycontract", null, true)


static func mc_rollover() -> bool:
	# called when a season ends. Returns true if the manager is out of contract and has to leave.
	var u = G.s.user
	var m = mc()
	if int(m.end) >= G.s.season or u.sacked:
		return false
	if u.conf >= 50.0:
		m.end = G.s.season
		G.msg("One more year", "You let your contract run down, but the board has used its option to keep you for one more season on the same terms. Sort out a proper deal before it runs out again.", "mycontract", null, true)
		return false
	G.msg("Your contract has expired", "Your deal at %s ran out and the board chose not to renew it. You are free to look for a new club." % G.uc().name, "board", null, true)
	return true


static func mgr_bonus(kind: String):
	# trophies and promotion pay the manager, according to the bonus level in his contract
	var lvl = float(MC_BONUS[int(mc().bonus)][1])
	if lvl <= 0.0:
		return
	var weeks = {"league": 20, "euro": 26, "cup": 8, "promo": 14}.get(kind, 0)
	var amt = G.nice(salary() * weeks * lvl * 0.5)
	if amt > 0:
		life().cash += amt
		G.msg("Bonus paid", "Your contract pays a bonus for this: %s has gone into your account." % G.money(amt), "board")


static func invest_init(lf: Dictionary):
	if not lf.has("cars"):
		lf["cars"] = []
		for i in int(lf.car) + 1:
			lf.cars.append(i)
	if not lf.has("savings"):
		lf["savings"] = 0
		lf["props"] = []
		lf["shares"] = {}
		lf["px"] = []
		while lf.px.size() < 16:
			lf.px.append(float(G.rng.randi_range(20, 180)))
		lf["stakes"] = {}
		lf["agent"] = false
		lf["media"] = false
	while lf.px.size() < 16:
		lf.px.append(float(G.rng.randi_range(20, 180)))


static func life_ledger(lf: Dictionary) -> Array:
	# what comes in and goes out of the manager's own account each week
	invest_init(lf)
	var rows = [["Salary", salary()]]
	if lf.income > 0: rows.append(["Businesses", int(lf.income)])
	var rent = 0
	for pr in lf.props:
		rent += int(pr.rent)
	if rent > 0: rows.append(["Rent from property", rent])
	var div = 0
	for cid in lf.stakes:
		div += int(G.s.clubs[int(cid)].wage_budget * 0.06 * float(lf.stakes[cid]) / 100.0)
	if div > 0: rows.append(["Club dividends", div])
	var dv = dividends(lf)
	if dv > 0: rows.append(["Share dividends", dv])
	if lf.media: rows.append(["Media work", 8000])
	if lf.agent: rows.append(["Personal agent", -2000])
	if lf.study != "": rows.append(["Language lessons", -400])
	if HOME_UP[lf.home] > 0: rows.append(["Home upkeep", -HOME_UP[lf.home]])
	var cu = 0
	for ci in lf.cars:
		cu += CAR_UP[ci]
	if cu > 0: rows.append(["Cars", -cu])
	rows.append(["Living costs", -living(lf)])
	return rows


static func living(lf: Dictionary) -> int:
	return 350 + 250 * int(lf.home)


static func worth_rows(lf: Dictionary) -> Array:
	invest_init(lf)
	var rows = [["Cash", int(lf.cash)], ["Savings", int(lf.savings)], ["Home", HOME_PRICE[lf.home]]]
	var cv = 0
	for ci in lf.cars:
		cv += int(CAR_PRICE[ci] * 0.7)
	rows.append(["Cars", cv])
	var pv = 0
	for pr in lf.props:
		pv += int(pr.value)
	rows.append(["Rental property", pv])
	var bz = 0
	for i in lf.biz:
		bz += [250000, 1200000, 5000000][i]
	rows.append(["Businesses", bz])
	var sh = 0
	for k in lf.shares:
		if int(k) < lf.px.size():
			sh += int(float(lf.shares[k]) * lf.px[int(k)])
	rows.append(["Shares", sh])
	var st = 0
	for cid in lf.stakes:
		st += int(club_value(G.s.clubs[int(cid)]) * float(lf.stakes[cid]) / 100.0)
	rows.append(["Club stakes", st])
	return rows


static func net_worth(lf: Dictionary) -> int:
	var t = 0
	for r in worth_rows(lf):
		t += r[1]
	return t


static func invest_week(lf: Dictionary):
	var s = G.s
	invest_init(lf)
	var cu = living(lf) + HOME_UP[lf.home]
	for ci in lf.cars:
		cu += CAR_UP[ci]
	lf.cash = max(0, lf.cash - cu)
	if not lf.has("savings"):
		lf["savings"] = 0
		lf["props"] = []
		lf["shares"] = {}
		lf["px"] = []
		lf["stakes"] = {}
		lf["agent"] = false
		lf["media"] = false
	lf.savings = int(lf.savings * 1.0007)
	for pr in lf.props:
		lf.cash += int(pr.rent)
		pr.value = int(pr.value * G.rng.randf_range(0.996, 1.007))
	while lf.px.size() < 16:
		lf.px.append(float(G.rng.randi_range(20, 180)))
	lf.cash += dividends(lf)
	for cid in lf.stakes:
		var c = s.clubs[int(cid)]
		lf.cash += int(c.wage_budget * 0.06 * float(lf.stakes[cid]) / 100.0)
	if lf.agent:
		lf.cash -= 2000
	if lf.media:
		lf.cash += 8000
		s.user.conf = max(0.0, s.user.conf - 0.3)
		s.user.rep = min(100.0, s.user.rep + 0.05)


static func salary() -> int:
	var u = G.s.user
	if u.has("salary"):
		return int(u.salary)
	var c = G.uc()
	return G.nice(c.wage_budget * 0.012 * (0.5 + u.rep / 100.0))


static func sponsor_now():
	# this season's shirt sponsor, or null if none has been signed yet
	var sp = G.s.user.get("sponsor")
	if sp != null and int(sp.get("season", -1)) == G.s.season:
		return sp
	return null


static func sponsor_list() -> Array:
	return load("res://scripts/screens/hub.gd").SPONSORS


static func sponsor_logo(nm: String) -> Texture2D:
	var all = sponsor_list()
	for i in all.size():
		if all[i][0] == nm:
			var path = "res://assets/sponsors/sponsor_%02d.png" % (i + 1)
			if ResourceLoader.exists(path):
				return load(path)
	return null


static func sponsor_offers() -> Array:
	# three offers a season: all guaranteed money, a mix, or mostly win bonuses
	var s = G.s
	var c = G.uc()
	var all = sponsor_list()
	var rng = RandomNumberGenerator.new()
	rng.seed = s.season * 977 + c.id * 13
	var base = c.wage_budget * (0.06 + c.fac.commercial * 0.012)
	var out = []
	var used = []
	for t in [["Guaranteed", 1.0, 0.0], ["Balanced", 0.72, 0.9], ["Win bonus", 0.4, 2.2]]:
		var i = rng.randi() % all.size()
		while i in used:
			i = (i + 1) % all.size()
		used.append(i)
		out.append({"name": all[i][0], "sector": all[i][1], "type": t[0], "weekly": G.nice(base * t[1]), "win": G.nice(base * t[2]), "season": s.season})
	return out


static func sponsor_call(first := false):
	# start of a season (or a new job): the offers are in and the manager has to pick one
	var old = G.s.user.get("sponsor")
	var names = []
	for o in sponsor_offers():
		names.append("%s (%s)" % [o.name, o.type.to_lower()])
	var lead = "Three companies want their name on the shirt this season: %s." % ", ".join(names)
	if not first and old != null:
		lead = "Your deal with %s has run its course. %s" % [old.name, lead]
	G.msg("Sponsor offers are in", lead + "\n\nA guaranteed deal pays the most each week; a win-bonus deal pays less each week and more for every win. The deal runs for the whole season and cannot be changed once signed. Until you choose, the club earns nothing from the shirt.\n\nOpen Kit & Sponsors to choose, and to set this season's kit.", "sponsor", null, true)


static func week_money(c: Dictionary) -> Dictionary:
	# the club's income and costs for the week so far (settled every Monday by weekly())
	var s = G.s
	var tier = s.leagues[c.lg].tier
	var wages = G.squad_wages(c)
	var sponsor = int(c.wage_budget * (0.86 + 0.03 * c.fac.commercial))
	var sp = sponsor_now()
	if sp != null and c.id == s.user.club:
		sponsor += int(sp.weekly)
	if c.id == s.user.club:
		sponsor += spx_week()
	var tv = int(c.wage_budget * 0.05)
	var price = [46, 30, 20, 15][clampi(tier - 1, 0, 3)]
	var fill = clamp(0.55 + (c.rep - 55.0) * 0.012 + (0.1 if c.form.count("W") >= 3 else 0.0), 0.35, 0.98)
	var tickets = int(c.fin.home * capacity(c) * fill * price)
	var levels = 0
	for k in FAC:
		levels += c.fac[k]
	var upkeep = int(c.wage_budget * 0.011 * levels)
	wages += G.MK.loan_wages(c)
	return {"tickets": tickets, "sponsor": sponsor, "tv": tv, "wages": wages, "upkeep": upkeep, "home": c.fin.home, "net": sponsor + tv + tickets - wages - upkeep}


static func weekly():
	var s = G.s
	var c = G.uc()
	# the manager's own money and life
	var lf = life()
	lf.cash += salary() + int(lf.income)
	if lf.study != "":
		var cost = 400
		if lf.cash >= cost:
			lf.cash -= cost
			lf.lang[lf.study] = min(100.0, float(lf.lang.get(lf.study, 0.0)) + 4.0 + s.user.attr.tac * 0.1)
			if lf.lang[lf.study] >= 100.0:
				G.msg("You are now fluent in %s" % lf.study, "Months of lessons have paid off. Speaking the language helps you get your message across: Motivation +1.", "info")
				s.user.attr.mot = min(22, s.user.attr.mot + 1)
				lf.study = ""
	lf.settled = min(100.0, float(lf.settled) + 1.5 + lf.home * 0.8)
	invest_week(lf)
	G.SOC.weekly()
	var wm = week_money(c)
	var net = wm.net
	c.budget += net
	wm.home = 0
	c.fin = wm
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


# ---------------------------------------------------------------- conversations with players
const TALKS = [
	{"k": "praise", "n": "Praise his form", "d": "Lands when he has been playing well", "i": "star"},
	{"k": "push", "n": "Ask for more", "d": "Works on professionals, backfires on some", "i": "zap"},
	{"k": "games", "n": "Promise more games", "d": "Lifts him now; break it and he turns", "i": "calendar-check"},
	{"k": "patient", "n": "Ask him to be patient", "d": "May calm an unhappy player", "i": "hourglass"},
]


static func talk_ok(p: Dictionary, k: String) -> bool:
	if k == "games":
		return not p.has("pg")
	if k == "patient":
		return p.get("unhappy", 0) > 0 or p.mor < 60
	return true


static func talk(p: Dictionary, k: String) -> Dictionary:
	# one conversation: what you say, what he answers, what it does to morale
	var s = G.s
	var per = G.PS.personality(p)
	var pro = per in ["Professional", "Model professional", "Driven", "Ambitious", "Leader", "Determined"]
	var form = float(p.get("form", 6.5))
	var r = {"you": "", "reply": "", "mor": 0, "note": ""}
	p["talk"] = s.day
	match k:
		"praise":
			r.you = "You have been excellent lately. Keep it going."
			if form >= 7.0 and p.ss.ap >= 3:
				r.mor = 6
				r.reply = "Thanks, boss. That means a lot."
			elif p.ss.ap < 3:
				r.mor = -1
				r.reply = "I have hardly played, boss."
			else:
				r.mor = -2
				r.reply = "We both know I can do better than that."
		"push":
			r.you = "I need more from you. You are better than this."
			if form >= 7.2:
				r.mor = -5
				r.reply = "More? I am giving you everything."
			elif pro:
				r.mor = 4
				r.reply = "You are right. I will put it right in training."
				p.form = min(10.0, form + 0.2)
				r.note = "sharper in training"
			else:
				r.mor = -4
				r.reply = "Maybe pick me in my proper position, then."
		"games":
			r.you = "You will get more football over the next month. My word on it."
			r.mor = 8
			r.reply = "That is all I wanted to hear."
			p["pg"] = {"day": s.day, "ap": int(p.ss.ap)}
			p["unhappy"] = 0
			r.note = "he expects 3 games in 30 days"
		"patient":
			r.you = "Your chance will come. I need you to stay ready."
			if pro or G.rng.randf() < 0.45:
				r.mor = 5
				p["unhappy"] = 0
				r.reply = "All right. I will keep working."
			else:
				r.mor = -2
				r.reply = "I have heard that before."
	p.mor = clampf(p.mor + r.mor, 5, 100)
	return r


static func talks_daily():
	# promises of more games fall due after 30 days; mentors give young players a small lift each month
	var s = G.s
	var c = G.uc()
	for pid in c.players:
		var p = s.players[pid]
		if p.has("pg") and s.day - int(p.pg.day) >= 30:
			var got = int(p.ss.ap) - int(p.pg.ap)
			if got >= 3:
				p.mor = min(100.0, p.mor + 4)
			else:
				p.mor = max(5.0, p.mor - 14)
				p["unhappy"] = max(int(p.get("unhappy", 0)), 20)
				G.msg("%s: promise broken" % G.pname(p), "You promised %s more football a month ago and he has played %d game%s since. He is angry, and the dressing room has noticed." % [G.pname(p), got, "" if got == 1 else "s"], "info", p.id)
			p.erase("pg")


static func mentor_mult(p: Dictionary) -> float:
	var m = int(p.get("mentor", -1))
	if m < 0 or not G.s.players.has(m) or G.s.players[m].club != p.club:
		return 1.0
	var q = G.s.players[m]
	var per = G.PS.personality(q)
	return 1.12 + clampf((q.ovr - p.ovr) * 0.008, 0.0, 0.08) + (0.06 if per in ["Professional", "Model professional", "Leader", "Driven", "Determined"] else 0.0)


# ---------------------------------------------------------------- kits and the smaller sponsor deals
const KIT_NAMES = {"home": "Home", "away": "Away", "third": "Third", "gk": "Keeper"}
const STRIPES = ["Newcastle", "Juventus", "Milan", "Inter", "Barcelona", "Atlético", "Sunderland", "Sheffield United", "Sheffield Wednesday", "Brentford", "Southampton", "Stoke", "West Brom",
	"Brighton", "Crystal Palace", "Athletic", "Real Sociedad", "Espanyol", "Betis", "Atalanta", "Udinese", "Hertha", "Nice", "Huddersfield", "Lincoln", "Exeter", "Cheltenham", "Grimsby", "Notts County", "Barnsley"]
const HOOPS = ["Queens Park Rangers", "Reading", "Celtic", "Sporting", "Greuther"]
const HALVES = ["Blackburn", "Bristol Rovers", "Basel"]
const SASH = ["Rayo", "River"]
const SLEEVES = ["Arsenal", "Feyenoord", "Braga", "Charlton"]
const SPX = [["back", "Back of shirt", 0.22, 1], ["sleeve", "Sleeve", 0.14, 1], ["training", "Training kit", 0.12, 1], ["stadium", "Stadium name", 0.38, 3]]


static func default_pattern(c: Dictionary) -> int:
	var nm = str(c.name)
	for it in [[STRIPES, 1], [HOOPS, 2], [HALVES, 3], [SASH, 4], [SLEEVES, 5]]:
		for k in it[0]:
			if nm.contains(k):
				return it[1]
	return 0


static func kit(c: Dictionary, which := "home") -> Dictionary:
	# {c1, c2, p}: every club has a home kit; the user's club also keeps away, third and keeper kits
	if not c.has("kitp"):
		c["kitp"] = default_pattern(c)
	if which == "home":
		return {"c1": str(c.c1), "c2": str(c.c2), "p": int(c.kitp)}
	if not c.has("kits"):
		var c1 = Color(str(c.c1))
		var light = c1.get_luminance() > 0.55
		c["kits"] = {"away": {"c1": "1b2333" if light else "f4f4f4", "c2": str(c.c1), "p": 0},
			"third": {"c1": "f6ad3c" if not light else "0b6e4f", "c2": "111111", "p": 5},
			"gk": {"c1": "38d27a", "c2": "111111", "p": 5}}
	return c.kits[which]


static func _cd(a: Color, b: Color) -> float:
	return abs(a.r - b.r) + abs(a.g - b.g) + abs(a.b - b.b)


static func match_kits(home: Dictionary, away: Dictionary) -> Array:
	# what each side wears: the home side its home kit, the away side whichever of its kits clashes least
	var hk = kit(home)
	var best = kit(away)
	var hc = Color(hk.c1)
	if _cd(hc, Color(best.c1)) < 0.5:
		var opts = []
		if away.has("kits") or away.id == G.s.user.club:
			opts = [kit(away, "away"), kit(away, "third")]
		else:
			var alt = Color(str(away.c2))
			if _cd(hc, alt) < 0.5:
				alt = Color("1b2333") if hc.get_luminance() > 0.3 else Color("f6ad3c")
			opts = [{"c1": alt.to_html(false), "c2": str(away.c1), "p": 0}]
		for o in opts:
			if _cd(hc, Color(o.c1)) > _cd(hc, Color(best.c1)):
				best = o
	return [hk, best]


static func spx() -> Dictionary:
	var u = G.s.user
	if not u.has("spx"):
		u["spx"] = {}
	return u.spx


static func spx_now(kind: String):
	var d = spx().get(kind)
	if d != null and int(d.until) >= G.s.season:
		return d
	return null


static func spx_offers(kind: String) -> Array:
	var s = G.s
	var c = G.uc()
	var all = sponsor_list()
	var row = null
	for r in SPX:
		if r[0] == kind:
			row = r
	var rng = RandomNumberGenerator.new()
	rng.seed = s.season * 613 + c.id * 29 + hash(kind) % 1000
	var base = c.wage_budget * (0.06 + c.fac.commercial * 0.012) * float(row[2])
	var out = []
	var main = sponsor_now()
	var used = [main.name if main != null else ""]
	for t in [["Safe", 1.0, 0], ["Bigger, longer", 1.22, 1]]:
		var i = rng.randi() % all.size()
		while all[i][0] in used:
			i = (i + 1) % all.size()
		used.append(all[i][0])
		out.append({"name": all[i][0], "sector": all[i][1], "weekly": G.nice(base * t[1] * rng.randf_range(0.9, 1.1)), "until": s.season + int(row[3]) - 1 + int(t[2]), "type": t[0]})
	return out


static func spx_sign(kind: String, deal: Dictionary):
	var c = G.uc()
	spx()[kind] = deal
	if kind == "stadium":
		if not c.has("stad0"):
			c["stad0"] = str(c.stadium)
		c.stadium = "%s %s" % [deal.name, ["Stadium", "Arena", "Park"][absi(hash(deal.name)) % 3]]


static func spx_week() -> int:
	var tot = 0
	for r in SPX:
		var d = spx_now(r[0])
		if d != null:
			tot += int(d.weekly)
	return tot


static func spx_rollover():
	# naming rights run out: the ground gets its old name back
	var c = G.uc()
	var d = spx().get("stadium")
	if c.has("stad0") and (d == null or int(d.until) <= G.s.season):
		c.stadium = str(c.stad0)
		c.erase("stad0")


# ---------------------------------------------------------------- 3D models shared by the city, the match-day card and the home
const STADIA = [["FSt_Fra_003", 0.86], ["Fst_Eng_003", 0.6953], ["Fst_Eng_001", 0.66375], ["Fst_Eng_002", 0.7575], ["FSt_Ita_001", 0.693]]
const CAR_MODEL = ["sedan", "sedan", "sedan-sports", "race", "hatchback-sports", "hatchback-sports", "hatchback-sports", "suv", "sedan", "suv-luxury", "sedan-sports", "sedan-sports", "race", "race-future"]
const CAR_TINT = ["ffffff", "30343c", "d8342c", "f2c019", "8b1a1a", "6cabdd", "2f6fe0", "9aa3ad", "16161a", "1c2a22", "e8e8e8", "0a1a5c", "ff6f00", "7a2fd0"]


static func stadium_model(level: int) -> Array:
	# [scene path, how far up the model's bounding box the ground sits]
	var e = STADIA[clampi(level - 1, 0, STADIA.size() - 1)]
	return ["res://assets/city3d/stadium/%s.FBX" % e[0], float(e[1])]


static func stadium_level(c: Dictionary) -> int:
	if c.has("fac"):
		return int(c.fac.stadium)
	return clampi(int((float(c.rep) - 40.0) / 9.0), 1, 5)


static func car_node(idx: int) -> Node3D:
	# the Kenney car that stands for one of the 14 cars in the garage, tinted so each looks its own
	idx = clampi(idx, 0, CAR_MODEL.size() - 1)
	var path = "res://assets/cars3d/%s.glb" % CAR_MODEL[idx]
	if not ResourceLoader.exists(path):
		return null
	var n: Node3D = load(path).instantiate()
	var tint = Color(CAR_TINT[idx])
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		if str(mi.name).to_lower().contains("wheel"):
			continue
		for si in mi.mesh.get_surface_count():
			var m = mi.mesh.surface_get_material(si)
			if m is StandardMaterial3D:
				var m2 = m.duplicate()
				m2.albedo_color = tint.lerp(Color.WHITE, 0.25)
				mi.set_surface_override_material(si, m2)
	return n


# ---------------------------------------------------------------- stock market
# Sixteen listed companies (the sponsor names). Prices move every day: a market-wide swing, a swing for the
# sector, the company's own noise and now and then company news. While the Investments screen is open the
# price also ticks a little every second or two. Every share pays a weekly dividend at its sector's yield.
# Data on the manager's life record: px (price now), ph (daily closes, newest last), cost (average price paid),
# mnews (headlines), trades (recent orders).

const TICK = ["AERO", "SKYL", "HZTR", "PNBK", "NOVA", "PLSD", "HLXS", "APXM", "TRBF", "WAVC", "SGPL", "LMVT", "TRSP", "FZVT", "AQBT", "AEGS"]
# sector: [daily volatility, yearly dividend yield]
const SECTOR = {"Airline": [0.022, 0.010], "Bank": [0.015, 0.035], "Tech": [0.026, 0.004], "Car maker": [0.020, 0.015],
	"Telecom": [0.011, 0.042], "Energy": [0.019, 0.026], "Drinks": [0.010, 0.030], "Insurance": [0.010, 0.036]}
const HIST = 260
const FEE = 0.002


static func sector(i: int) -> String:
	return sponsor_list()[i][1]


static func vol(i: int) -> float:
	return float(SECTOR.get(sector(i), [0.015, 0.02])[0])


static func yld(i: int) -> float:
	return float(SECTOR.get(sector(i), [0.015, 0.02])[1])


static func market_init(lf: Dictionary):
	invest_init(lf)
	if not lf.has("ph") or lf.ph.size() < lf.px.size():
		# a year of made-up history that ends at today's price
		lf["ph"] = []
		for i in lf.px.size():
			var h = []
			var p = float(lf.px[i])
			for d in HIST:
				h.push_front(snappedf(p, 0.01))
				p = clamp(p / exp(randfn_g(0.0003, vol(i))), 2.0, 5000.0)
			lf.ph.append(h)
	if not lf.has("cost"):
		lf["cost"] = {}
	for k in lf.shares:
		if not lf.cost.has(k):
			lf.cost[k] = float(lf.px[int(k)])
	if not lf.has("mnews"):
		lf["mnews"] = []
	if not lf.has("trades"):
		lf["trades"] = []


static func randfn_g(mean: float, sd: float) -> float:
	return G.rng.randfn(mean, sd)


static func prev_close(lf: Dictionary, i: int) -> float:
	var h = lf.ph[i]
	return float(h[h.size() - 2]) if h.size() >= 2 else float(lf.px[i])


static func day_change(lf: Dictionary, i: int) -> float:
	var pc = prev_close(lf, i)
	return (float(lf.px[i]) / pc - 1.0) if pc > 0 else 0.0


static func market_day(lf: Dictionary):
	# close yesterday, open today: one daily move for every company
	if not lf.has("savings"):
		return
	market_init(lf)
	if G.cur.weekday == 0 or G.cur.weekday == 6:
		return     # no trading at the weekend
	var mkt = G.rng.randfn(0.0002, 0.007)
	var sec = {}
	for k in SECTOR:
		sec[k] = G.rng.randfn(0.0, 0.006)
	var sp = sponsor_now()
	for i in lf.px.size():
		var r = mkt + sec.get(sector(i), 0.0) + G.rng.randfn(0.00025, vol(i))
		# the club's shirt sponsor gets a little lift from the exposure
		if sp != null and str(sp.get("name", "")) == sponsor_list()[i][0]:
			r += 0.0004
		if G.rng.randf() < 0.012:
			var good = G.rng.randf() < 0.53
			var mv = G.rng.randf_range(0.04, 0.12) * (1.0 if good else -1.15)
			r += mv
			_headline(lf, i, mv)
		lf.px[i] = clamp(float(lf.px[i]) * exp(r), 2.0, 5000.0)
		var h = lf.ph[i]
		h.append(snappedf(lf.px[i], 0.01))
		while h.size() > HIST:
			h.remove_at(0)


const GOOD = ["%s beats profit forecasts", "%s wins a major contract", "Analysts upgrade %s to buy", "%s raises its outlook for the year", "%s unveils a new product line"]
const BAD = ["%s misses profit forecasts", "%s chief executive steps down", "%s hit by a product recall", "Analysts cut %s to sell", "%s warns on profits"]


static func _headline(lf: Dictionary, i: int, mv: float):
	var nm = sponsor_list()[i][0]
	var t = (GOOD if mv > 0 else BAD)[G.rng.randi() % 5] % nm
	lf.mnews.push_front({"d": G.s.day, "i": i, "t": t, "mv": mv})
	while lf.mnews.size() > 30:
		lf.mnews.pop_back()
	if int(lf.shares.get(i, 0)) > 0 and absf(mv) >= 0.07:
		G.msg("%s %s %d%%" % [TICK[i], "up" if mv > 0 else "down", int(round(absf(mv) * 100))], "%s. You hold %s shares, now worth %s." % [t, _n(int(lf.shares[i])), G.money(int(float(lf.px[i]) * exp(mv) * int(lf.shares[i])))], "info")


static func _n(v: int) -> String:
	var s = str(v)
	var out = ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out


static func market_tick(lf: Dictionary):
	# a small live move while the market screen is open
	for i in lf.px.size():
		lf.px[i] = clamp(float(lf.px[i]) * exp(G.rng.randfn(0.0, vol(i) * 0.07)), 2.0, 5000.0)
		lf.ph[i][lf.ph[i].size() - 1] = snappedf(lf.px[i], 0.01)


static func dividends(lf: Dictionary) -> int:
	var t = 0.0
	for k in lf.get("shares", {}):
		var i = int(k)
		if i < lf.px.size():
			t += float(lf.shares[k]) * float(lf.px[i]) * yld(i) / 52.0
	return int(t)


static func trade(lf: Dictionary, i: int, qty: int) -> String:
	# qty > 0 buys, qty < 0 sells; returns "" when done, or why not
	market_init(lf)
	var px = float(lf.px[i])
	var held = int(lf.shares.get(i, 0))
	if qty > 0:
		var cost = int(ceil(px * qty * (1.0 + FEE)))
		if cost > lf.cash:
			return "You need %s; you have %s" % [G.money(cost), G.money(lf.cash)]
		lf.cash -= cost
		lf.cost[i] = (float(lf.cost.get(i, px)) * held + px * qty) / float(held + qty)
		lf.shares[i] = held + qty
	else:
		var q = min(-qty, held)
		if q <= 0:
			return "You hold no %s shares" % TICK[i]
		lf.cash += int(px * q * (1.0 - FEE))
		if held - q <= 0:
			lf.shares.erase(i)
			lf.cost.erase(i)
		else:
			lf.shares[i] = held - q
		qty = -q
	lf.trades.push_front({"d": G.s.day, "i": i, "q": qty, "p": snappedf(px, 0.01)})
	while lf.trades.size() > 20:
		lf.trades.pop_back()
	return ""


static func max_buy(lf: Dictionary, i: int) -> int:
	return int(floor(float(lf.cash) / (float(lf.px[i]) * (1.0 + FEE))))


static func portfolio(lf: Dictionary) -> Dictionary:
	# value, what it cost, and how it moved today
	market_init(lf)
	var val = 0.0
	var cost = 0.0
	var today = 0.0
	for k in lf.shares:
		var i = int(k)
		var q = float(lf.shares[k])
		val += q * float(lf.px[i])
		cost += q * float(lf.cost.get(k, lf.px[i]))
		today += q * (float(lf.px[i]) - prev_close(lf, i))
	return {"value": val, "cost": cost, "pl": val - cost, "today": today}

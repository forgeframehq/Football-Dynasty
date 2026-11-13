extends RefCounted
# Transfers as a two-day process. Day 1: enquiry and a face-to-face fee negotiation with the
# selling club (patience bar, final offer, player swaps, or delegate it to the assistant).
# Day 2: the player and his agent come in; you see what he wants and agree terms.
# Also instalments, appearance add-ons, sell-on clauses, squad-role promises, performance
# bonuses, pre-contracts, rival bids and counter-offers when clubs bid for the user's players.

const ROLES = ["Star player", "First team", "Rotation", "Backup", "Prospect"]
const INST = ["All up front", "Half now, half in 12 months", "Three payments over 2 years"]
const NOW = [1.0, 0.5, 0.34]
const ADDON_APPS = 20
const BONUS = ["None", "Appearances", "Goals", "Both"]
const BONUS_DEF = ["None", "Appearances", "Clean sheets", "Both"]


static func all() -> Dictionary:
	if not G.s.has("deals"):
		G.s["deals"] = {}
	return G.s.deals


static func find(pid: int):
	return all().get(pid, null)


static func active() -> Array:
	var out = []
	for pid in all():
		var d = all()[pid]
		if d.stage != "done" and d.stage != "dead" and G.s.players.has(pid):
			out.append(d)
	return out


static func say(d: Dictionary, who: String, text: String):
	d.log.append([G.s.day, who, text])
	if d.log.size() > 30:
		d.log.pop_front()


static func start(p: Dictionary, mode: String) -> Dictionary:
	var d = find(p.id)
	if d != null and d.mode == mode and d.stage != "done":
		if d.stage == "dead" and d.block <= G.s.day:
			all().erase(p.id)
		else:
			return d
	d = {"pid": p.id, "mode": mode, "stage": "new" if mode == "buy" else "talks", "club": p.club, "started": G.s.day, "ask": -1, "fee": 0, "inst": 0,
		"addon": 0, "sellon": 0, "wait": 0, "pat": 100.0, "ppat": 100.0, "rival": -1, "exp": 0, "block": 0, "log": [], "terms": {}, "counter": {}, "swap": -1, "meet": 0, "v": 2}
	if mode == "pre":
		d.stage = "talks"
	all()[p.id] = d
	return d


static func upgrade(d: Dictionary):
	# deals saved before the two-day flow used small counters for patience and waited a day for every reply
	if int(d.get("v", 1)) >= 2:
		return
	d["v"] = 2
	d.pat = clamp(float(d.pat) * 33.0, 0.0, 100.0)
	d.ppat = clamp(float(d.ppat) * 25.0, 0.0, 100.0)
	d["swap"] = -1
	d["meet"] = 0
	if d.stage == "enq_wait" or d.stage == "bid_wait":
		d.stage = "club"


static func kill(d: Dictionary, days := 14):
	d.stage = "dead"
	d.block = G.s.day + days


# ---------------------------------------------------------------- club side

static func pay_now(fee: int, inst: int) -> int:
	return int(fee * NOW[inst])


static func package(p: Dictionary, fee: int, inst: int, addon: int, sellon: int) -> float:
	# what the selling club thinks the whole offer is worth today
	return fee * [1.0, 0.96, 0.92][inst] + addon * 0.5 + sellon / 100.0 * G.value(p) * 0.35


static func ask(p: Dictionary, d: Dictionary) -> int:
	var a = float(G.TR.asking_price(p))
	if d.rival >= 0:
		a *= 1.08
	return G.nice(a)


static func untouchable(p: Dictionary) -> bool:
	if p.club < 0 or p.listed or p.get("rc", 0) > 0:
		return false
	var c = G.s.clubs[p.club]
	return G.TR.squad_rank(p) < 3 and c.rep >= G.uc().rep - 1 and p.cend - G.s.season > 1


static func swap_value(d: Dictionary, q: Dictionary) -> float:
	# what the selling club thinks one of your players is worth to them as part of the deal
	var c = G.s.clubs[d.club]
	if q.ovr < c.rep - 9:
		return 0.0
	var same = 0
	for pid in c.players:
		var o = G.s.players[pid]
		if G.LINE[o.pos] == G.LINE[q.pos] and o.ovr >= q.ovr:
			same += 1
	var need = 1.05 if same < 2 else (0.85 if same < 4 else 0.65)
	return G.value(q) * need


static func swap_ok(d: Dictionary, q: Dictionary) -> String:
	var c = G.s.clubs[d.club]
	if q.get("loan", -1) >= 0:
		return "He is here on loan."
	if q.ovr < c.rep - 9:
		return "%s do not think he is good enough for them." % c.short
	if q.ovr > c.rep + 9:
		return "%s would not agree to join %s." % [G.pname(q), c.short]
	return ""


static func total_value(d: Dictionary, fee: int, inst: int, addon: int, sellon: int, swap: int) -> float:
	var p = G.s.players[d.pid]
	var v = package(p, fee, inst, addon, sellon)
	if swap >= 0 and G.s.players.has(swap):
		v += swap_value(d, G.s.players[swap])
	return v


static func stance(p: Dictionary) -> String:
	return "listed" if p.listed else ("no" if untouchable(p) else "price")


static func enquire(d: Dictionary) -> String:
	# day one starts here: their manager tells you where they stand, there and then
	var p = G.s.players[d.pid]
	var c = G.s.clubs[p.club]
	var w = G.TR.willing(p)
	d.stage = "club"
	say(d, "you", "Asked %s whether %s is available and at what price." % [c.name, G.pname(p)])
	var t = ""
	if untouchable(p):
		d.ask = G.nice(ask(p, d) * 1.25)
		t = "He is not for sale. He is one of our most important players. Only something exceptional, around %s, would make us think again." % G.money(d.ask)
	elif p.listed:
		d.ask = ask(p, d)
		t = "He is available. We would let him go for around %s and we are open to a sensible structure." % G.money(d.ask)
	else:
		d.ask = ask(p, d)
		t = "We are not looking to sell, but every player has a price. We value him at %s." % G.money(d.ask)
	if p.get("rc", 0) > 0:
		t += " His contract has a release clause of %s, payable in full." % G.money(p.rc)
	if not w.ok:
		t += " I should tell you the player himself may not be keen."
	say(d, "club", t)
	return t


static func submit_bid(d: Dictionary, fee: int, inst: int, addon: int, sellon: int, swap := -1, final := false) -> Dictionary:
	# an offer across the table: accepted, countered or turned down on the spot
	var p = G.s.players[d.pid]
	var c = G.s.clubs[p.club]
	var uc = G.uc()
	if not G.window_open():
		return {"ok": false, "res": "error", "text": "The transfer window is closed."}
	var w = G.TR.willing(p)
	if not w.ok and uc.players.size() >= G.TR.MAX_SQUAD:
		return {"ok": false, "res": "error", "text": w.why}
	if pay_now(fee, inst) > uc.budget:
		return {"ok": false, "res": "error", "text": "The first payment of %s is more than your %s budget." % [G.money(pay_now(fee, inst)), G.money(uc.budget)]}
	if swap >= 0:
		var why = swap_ok(d, G.s.players[swap])
		if why != "":
			return {"ok": false, "res": "error", "text": why}
	d.fee = fee
	d.inst = inst
	d.addon = addon
	d.sellon = sellon
	d.swap = swap
	var swap_txt = (" plus %s" % G.pname(G.s.players[swap])) if swap >= 0 else ""
	say(d, "you", "%s %s%s%s." % ["Final offer:" if final else "Offered", G.money(fee), swap_txt, extras(d)])
	var a = float(ask(p, d))
	if untouchable(p):
		a *= 1.25
	d.ask = G.nice(a)
	var pv = total_value(d, fee, inst, addon, sellon, swap)
	var rc = p.get("rc", 0)
	if rc > 0 and fee >= rc and inst == 0:
		_agree(d, "That meets the release clause. We cannot refuse.")
		return {"ok": true, "res": "accept", "text": "Your %s offer meets the release clause in %s's contract. %s cannot refuse." % [G.money(fee), G.pname(p), c.name]}
	var ratio = pv / max(1.0, a)
	if ratio >= (0.92 if final else 0.95):
		# a bigger club selling a promising youngster keeps a way to get him back
		var bbt = ""
		d["bb"] = 0
		if G.age(p) <= 21 and p.pot >= p.ovr + 5 and c.rep >= uc.rep + 2 and fee > 500000:
			d.bb = G.nice(max(fee, G.value(p)) * 1.8)
			bbt = " They insist on a buy-back clause at %s for the next three seasons." % G.money(int(d.bb))
		_agree(d, "We have a deal at %s%s%s.%s" % [G.money(fee), swap_txt, extras(d), bbt])
		return {"ok": true, "res": "accept", "text": "“We have a deal.” %s accept %s%s%s for %s.%s" % [c.name, G.money(fee), swap_txt, extras(d), G.pname(p), bbt]}
	if final:
		kill(d, 21)
		say(d, "club", "Refused the final offer and ended the talks.")
		return {"ok": true, "res": "dead", "text": "“Then we have nothing more to discuss.” %s refuse your final offer and will not talk about %s again before %s." % [c.name, G.pname(p), G.fmt_date(d.block)]}
	d.pat = float(d.pat) - clamp((0.95 - ratio) * 170.0, 8.0, 55.0)
	if d.pat <= 0.0:
		kill(d, 21)
		say(d, "club", "Walked away from the table.")
		return {"ok": true, "res": "dead", "text": "“You are wasting my time.” Their manager gets up and leaves. %s will not discuss %s again before %s." % [c.name, G.pname(p), G.fmt_date(d.block)]}
	if ratio >= 0.72:
		var want = G.nice(a * (0.97 + 0.04 * d.pat / 100.0))
		d.counter = {"fee": want, "inst": 0, "addon": 0, "sellon": 0}
		var alt = ""
		if sellon == 0 and want > 2000000:
			alt = " Or %s with fifteen per cent of any future sale." % G.money(G.nice(want * 0.93))
		var line = "“We are getting closer.”" if ratio >= 0.88 else "“That is not enough for a player like him.”"
		say(d, "club", "Turned it down. Would accept %s." % G.money(want))
		return {"ok": true, "res": "counter", "text": "%s He would do it at %s up front.%s" % [line, G.money(want), alt]}
	d.counter = {}
	say(d, "club", "Dismissed it as far too low.")
	return {"ok": true, "res": "reject", "text": "“Is that a serious offer?” It is well short of their %s valuation, and his patience is going." % G.money(d.ask)}


static func delegate(d: Dictionary, max_fee: int) -> Dictionary:
	# hand the fee talks to the assistant with a ceiling; he reports back tomorrow
	var uc = G.uc()
	if not G.window_open():
		return {"ok": false, "text": "The transfer window is closed."}
	if max_fee > uc.budget:
		return {"ok": false, "text": "Your limit of %s is more than the %s budget." % [G.money(max_fee), G.money(uc.budget)]}
	d.stage = "deleg"
	d["dmax"] = max_fee
	d.wait = G.s.day + 1
	say(d, "you", "Sent the assistant to negotiate, up to %s." % G.money(max_fee))
	return {"ok": true, "text": "Your assistant will meet them today and report back tomorrow."}


static func _delegate_result(d: Dictionary):
	var p = G.s.players[d.pid]
	var c = G.s.clubs[p.club]
	var a = float(ask(p, d))
	if untouchable(p):
		a *= 1.25
	d.ask = G.nice(a)
	var mx = float(d.dmax)
	# he is a steadier negotiator than a bold one: he lands close to their price, never a steal
	var settle = G.nice(a * G.rng.randf_range(0.96, 1.01))
	if settle <= mx:
		d.fee = settle
		d.inst = 0
		d.addon = 0
		d.sellon = 0
		d.swap = -1
		_agree(d, "Agreed with your assistant at %s." % G.money(settle), "Your assistant has agreed a fee of %s with %s for %s, inside the %s limit you gave him." % [G.money(settle), c.name, G.pfull(p), G.money(int(mx))])
		return
	d.stage = "club"
	d.pat = max(15.0, float(d.pat) - 20.0)
	d.counter = {"fee": G.nice(a * 0.98), "inst": 0, "addon": 0, "sellon": 0}
	say(d, "club", "Would not go below %s with the assistant." % G.money(int(d.counter.fee)))
	G.msg("%s: no agreement yet" % G.pname(p), "Your assistant could not agree a fee with %s inside your %s limit. They want about %s for %s.\n\nThe talks are still open if you want to sit down with them yourself." % [c.name, G.money(int(mx)), G.money(int(d.counter.fee)), G.pfull(p)], "deal", p.id, true)


static func extras(d: Dictionary) -> String:
	var t = ""
	if d.inst > 0: t += ", " + INST[d.inst].to_lower()
	if d.addon > 0: t += ", %s after %d appearances" % [G.money(d.addon), ADDON_APPS]
	if d.sellon > 0: t += ", %d%% of any future sale" % d.sellon
	return t


static func _agree(d: Dictionary, line: String, msg_text := ""):
	# fee settled: the player and his agent come in tomorrow
	var p = G.s.players[d.pid]
	var c = G.s.clubs[d.club]
	d.stage = "meet"
	d.meet = G.s.day + 1
	d.exp = G.s.day + 10
	d.ppat = 100.0
	say(d, "club", line)
	if G.MK.is_deadline() and G.window_open():
		# no tomorrow on deadline day: his agent brings him straight over
		d.meet = G.s.day
		d.stage = "talks"
		say(d, "agent", "Came straight over: the window shuts tonight.")
		G.msg("%s: fee agreed, talks tonight" % G.pname(p), "%s have accepted your offer for %s. With the window closing at 23:00 his agent has brought him straight over: agree his contract today or the deal is off until the next window." % [c.name, G.pfull(p)], "deal", p.id)
		return
	var swap_txt = (" plus %s" % G.pname(G.s.players[d.swap])) if d.swap >= 0 and G.s.players.has(d.swap) else ""
	var body = msg_text if msg_text != "" else "%s have accepted %s%s%s for %s." % [c.name, G.money(d.fee), swap_txt, extras(d), G.pfull(p)]
	G.msg("%s: fee agreed" % G.pname(p), body + "\n\n%s and his agent will come in to discuss personal terms on %s. The agreement with %s stands for 10 days." % [G.pname(p), G.fmt_date(d.meet), c.short], "deal", p.id)


static func _meeting(d: Dictionary):
	var p = G.s.players[d.pid]
	d.stage = "talks"
	say(d, "agent", "Arrived for talks.")
	G.msg("%s is here to talk terms" % G.pname(p), "%s and his agent are at the club today to discuss a contract. Open the talks to see what he wants and make your offer.\n\nThe fee agreed with %s stands until %s." % [G.pfull(p), G.s.clubs[d.club].name, G.fmt_date(d.exp)], "deal", p.id, true)


# ---------------------------------------------------------------- player side

static func expected_role(p: Dictionary) -> int:
	var uc = G.uc()
	var r = 0
	for pid in uc.players:
		if pid != p.id and G.s.players[pid].ovr > p.ovr:
			r += 1
	if r < 3: return 0
	if r < 11: return 1
	if G.age(p) <= 20 and r >= 14: return 4
	if r < 18: return 2
	return 3


static func demand(d: Dictionary, t: Dictionary) -> Dictionary:
	var p = G.s.players[d.pid]
	var uc = G.uc()
	var dem = float(G.TR.wage_demand(p))
	var per = G.PS.personality(p)
	var notes = []
	if per == "Mercenary":
		dem *= 1.1
		notes.append("Mercenary: wants top money")
	if per == "Loyal" and d.mode == "renew":
		dem *= 0.93
		notes.append("Loyal: happy to stay")
	if per == "Ambitious" and d.mode != "renew" and uc.rep < p.ovr:
		dem *= 1.06
		notes.append("Ambitious: sees this as a step down")
	if G.PS.favoured(p) == uc.id and d.mode != "renew":
		dem *= 0.92
		notes.append("Supports %s" % uc.name)
	var er = expected_role(p)
	var diff = int(t.role) - er
	var blocked = ""
	if diff > 0:
		dem *= 1.0 + 0.09 * diff
		if diff >= 2 and er <= 1:
			blocked = "%s expects to be a %s. He will not sign as a %s." % [G.pname(p), ROLES[er].to_lower(), ROLES[t.role].to_lower()]
	elif diff < 0:
		dem *= 1.0 + 0.05 * diff
	var a = G.age(p)
	if a >= 32 and t.years > 2:
		dem *= 0.95
	if a <= 24 and p.pot >= p.ovr + 4 and t.years >= 5:
		dem *= 1.04
	if t.rc > 0:
		dem *= 0.94 if t.rc < G.value(p) * 1.6 else 0.98
	# what he wants beyond money: each unmet wish makes him dearer, the essential ones stop the deal
	var pr = priorities(d)
	for w in pr:
		match w.k:
			"europe":
				dem *= 1.06
			"clause":
				if int(t.rc) == 0:
					dem *= 1.05
			"games":
				if int(t.role) >= 3:
					if blocked == "":
						blocked = "%s wants to play. He will not sign as a %s." % [G.pname(p), ROLES[t.role].to_lower()]
			"short":
				if int(t.years) > 3:
					dem *= 1.05
			"long":
				if int(t.years) < int(w.v):
					dem *= 1.05
	var sm = {"free": 20.0, "buy": 8.0, "renew": 4.0, "pre": 14.0}[d.mode]
	var base = float(G.TR.wage_demand(p))
	var agent = base * {"free": 10.0, "buy": 5.0, "renew": 3.0, "pre": 8.0}[d.mode]
	if d.mode == "buy":
		agent = max(agent, d.fee * 0.05)
	return {"wage": G.nice(dem), "sign": G.nice(base * sm), "agent": G.nice(agent), "role": er, "blocked": blocked, "notes": notes, "want": pr}


static func in_europe(c: Dictionary) -> bool:
	for cp in G.s.get("comps", []):
		if cp.get("kind", "") != "euro":
			continue
		for g in cp.get("groups", []):
			if c.id in g:
				return true
		if c.id in cp.get("alive", []):
			return true
	return false


static func priorities(d: Dictionary) -> Array:
	# the things this player cares about in a move: [{k, text, ess}] (ess = he will not sign without it)
	var p = G.s.players[d.pid]
	var uc = G.uc()
	var per = G.PS.personality(p)
	var a = G.age(p)
	var out = []
	if d.mode != "renew" and p.ovr >= 78 and p.ovr >= uc.rep - 2 and not in_europe(uc):
		out.append({"k": "europe", "text": "Wants European football: you cannot offer it this season, so he asks for more", "ess": false})
	if a <= 22 and p.pot >= p.ovr + 3 and p.ovr >= uc.rep - 12:
		out.append({"k": "games", "text": "Wants to play: will not sign as a Backup or Prospect", "ess": true})
	if (per == "Ambitious" or (p.club >= 0 and uc.rep < p.ovr - 1)) and d.mode != "renew":
		out.append({"k": "clause", "text": "Wants a release clause in case a bigger club comes", "ess": false})
	if per == "Ambitious" and a <= 25:
		out.append({"k": "short", "text": "Prefers three years or fewer, to keep his options open", "ess": false})
	elif a >= 30 or per == "Loyal":
		out.append({"k": "long", "v": 2 if a >= 30 else 4, "text": "Wants security: at least %d years" % (2 if a >= 30 else 4), "ess": false})
	if per == "Mercenary":
		out.append({"k": "cash", "text": "Prefers guaranteed money to bonuses", "ess": false})
	return out


static func knows_wants(d: Dictionary) -> bool:
	var p = G.s.players[d.pid]
	return d.mode == "renew" or p.club == G.s.user.club or G.OPS.knows(p)


static func bonus_amounts(p: Dictionary, wage: int, kind: int) -> Dictionary:
	# performance bonuses are sized from the weekly wage so they scale with the player
	var back = G.LINE[p.pos] <= 1
	var b = {"ab": 0, "gb": 0, "cs": 0}
	if kind == 1 or kind == 3:
		b.ab = G.nice(wage * 0.15)
	if kind == 2 or kind == 3:
		if back:
			b.cs = G.nice(wage * 0.25)
		else:
			b.gb = G.nice(wage * 0.4)
	return b


static func bonus_week(p: Dictionary, b: Dictionary) -> float:
	# what the bonuses are worth to him per week, on a normal season
	var goals = {"ST": 14.0, "LW": 8.0, "RW": 8.0, "CAM": 7.0, "LM": 5.0, "RM": 5.0, "CM": 4.0}.get(p.pos, 1.5) * p.ovr / 80.0
	return (b.ab * 30.0 + b.gb * goals + b.cs * 11.0) / 52.0


static func default_terms(d: Dictionary) -> Dictionary:
	var p = G.s.players[d.pid]
	var t = {"wage": 0, "years": 3, "role": expected_role(p), "sign": 0, "agent": 0, "rc": 0, "bon": 0}
	if d.mode == "renew":
		t.years = clampi(p.cend - G.s.season + 2, 1, 5)
	if G.age(p) >= 32:
		t.years = min(t.years, 2)
	var dm = demand(d, t)
	t.wage = G.nice(dm.wage * 0.9)
	t.sign = G.nice(dm.sign * 0.5)
	t.agent = G.nice(dm.agent * 0.7)
	return t


static func upfront(d: Dictionary, t: Dictionary) -> int:
	var x = int(t.sign) + int(t.agent)
	if d.mode == "buy":
		x += pay_now(d.fee, d.inst)
	return x


static func offer_terms(d: Dictionary, t: Dictionary) -> Dictionary:
	var p = G.s.players[d.pid]
	var uc = G.uc()
	var own = d.mode == "renew"
	if d.mode != "renew":
		var w = G.TR.willing(p)
		if not w.ok:
			return {"res": "error", "text": w.why}
	var total = G.squad_wages(uc) + t.wage - (p.wage if own else 0)
	if total > uc.wage_budget:
		return {"res": "error", "text": "This would take the wage bill to %s/wk — over the %s/wk budget." % [G.money(total), G.money(uc.wage_budget)]}
	if upfront(d, t) > uc.budget:
		return {"res": "error", "text": "You need %s today (first payment, signing-on and agent fees) but have %s." % [G.money(upfront(d, t)), G.money(uc.budget)]}
	if own and p.mor < 35:
		return {"res": "reject", "text": "%s is unhappy and refuses to discuss a new deal right now." % G.pname(p)}
	if own and p.has("pre"):
		return {"res": "error", "text": "%s has already signed a pre-contract with %s. It is too late for a new deal." % [G.pname(p), G.s.clubs[int(p.pre.club)].name]}
	if d.mode == "buy" and not G.window_open():
		return {"res": "error", "text": "The window is closed. The move cannot be registered until it reopens."}
	if d.mode == "buy" and d.swap >= 0 and (not G.s.players.has(d.swap) or G.s.players[d.swap].club != uc.id):
		d.swap = -1
	say(d, "you", "Offered %s/wk for %d yr%s as %s." % [G.money(t.wage), t.years, "" if t.years == 1 else "s", ROLES[t.role].to_lower()])
	var dm = demand(d, t)
	if dm.blocked != "":
		d.ppat -= 20.0
		say(d, "agent", dm.blocked)
		return _talk_end(d, {"res": "reject", "text": dm.blocked})
	if t.agent < dm.agent * 0.5:
		d.ppat -= 15.0
		var tx = "The agent will not let this through without a proper fee. He wants about %s for himself." % G.money(dm.agent)
		say(d, "agent", tx)
		return _talk_end(d, {"res": "counter", "text": tx, "wage": t.wage, "sign": t.sign, "agent": dm.agent})
	var span = 52.0 * t.years
	var need = dm.wage + dm.sign / span
	if t.agent >= dm.agent * 1.5:
		need *= 0.96
	var bon = bonus_amounts(p, t.wage, int(t.get("bon", 0)))
	var have = t.wage + t.sign / span + bonus_week(p, bon) * (0.5 if G.PS.personality(p) == "Mercenary" else 0.75)
	if have >= need * 0.97:
		complete(d, t)
		return {"res": "accept", "text": "%s agrees to a %d-year deal worth %s per week." % [G.pname(p), t.years, G.money(t.wage)]}
	d.ppat -= clamp((0.97 - have / need) * 150.0, 10.0, 35.0)
	if have >= need * 0.8:
		var tx2 = "We are not far apart. %s would sign for %s a week with %s on signing." % [G.pname(p), G.money(dm.wage), G.money(dm.sign)]
		say(d, "agent", tx2)
		return _talk_end(d, {"res": "counter", "text": tx2, "wage": dm.wage, "sign": dm.sign, "agent": max(t.agent, dm.agent)})
	var tx3 = "That is a long way short. My client is looking for around %s a week." % G.money(dm.wage)
	say(d, "agent", tx3)
	return _talk_end(d, {"res": "reject", "text": tx3})


static func _talk_end(d: Dictionary, r: Dictionary) -> Dictionary:
	if d.ppat <= 0.0:
		var p = G.s.players[d.pid]
		kill(d)
		r.res = "dead"
		r.text = "%s's agent has walked out. Talks are off until %s." % [G.pname(p), G.fmt_date(d.block)]
		say(d, "agent", "Walked out of the talks.")
	return r


static func complete(d: Dictionary, t: Dictionary):
	var p = G.s.players[d.pid]
	var uc = G.uc()
	var s = G.s
	d.terms = t.duplicate()
	if d.mode == "pre":
		# signed now, joins when his contract runs out in June
		p["pre"] = {"club": uc.id, "wage": int(t.wage), "years": int(t.years), "role": int(t.role), "rc": int(t.rc), "bon": bonus_amounts(p, t.wage, int(t.get("bon", 0)))}
		uc.budget -= int(t.sign) + int(t.agent)
		d.stage = "done"
		say(d, "agent", "Pre-contract signed.")
		G.news("%s has agreed to join %s when his %s contract ends in June." % [G.pfull(p), uc.name, G.s.clubs[p.club].name if p.club >= 0 else ""])
		G.scrap("Pre-contract: %s" % G.pname(p), "%s agreed to join on a free transfer in the summer." % G.pfull(p))
		G.save_game()
		return
	if d.mode == "renew":
		G.TR.renew(p, t.wage, t.years)
	else:
		var from_id = p.club
		var first = pay_now(d.fee, d.inst) if d.mode == "buy" else 0
		G.TR.move(p, uc.id, first, t.wage, t.years)
		if d.mode == "buy":
			if s.tx_log.size() > 0:
				s.tx_log[0].fee = d.fee
			var rest = d.fee - first
			var parts = d.inst
			for i in parts:
				owed().append({"day": s.day + 365 * (i + 1), "amt": int(rest / parts), "from": uc.id, "to": from_id, "name": G.pname(p)})
			if d.addon > 0:
				clauses().append({"pid": p.id, "from": uc.id, "to": from_id, "amt": d.addon, "base": p.cap, "apps": ADDON_APPS})
			if d.sellon > 0:
				p["sellon"] = [from_id, d.sellon]
			if d.swap >= 0 and s.players.has(d.swap) and s.players[d.swap].club == uc.id:
				var q = s.players[d.swap]
				G.TR.move(q, from_id, 0, q.wage, 3)
				G.msg("%s leaves in the %s deal" % [G.pname(q), G.pname(p)], "%s has joined %s as part of the agreement that brought %s to the club." % [G.pfull(q), s.clubs[from_id].name, G.pfull(p)], "info")
			if int(d.get("bb", 0)) > 0:
				p["bb"] = {"club": from_id, "fee": int(d.bb), "until": s.season + 3}
		G.PS.learn(p, G.PS.country_of(uc.id))
		G.scrap("Signed %s" % G.pname(p), "%s joined%s on a %d-year contract." % [G.pfull(p), (" for " + G.money(d.fee)) if d.fee > 0 else " on a free transfer", t.years])
		G.SOC.on_signing(p, d.fee)
	uc.budget -= int(t.sign) + int(t.agent)
	p["rolep"] = int(t.role)
	p.erase("rolew")
	if t.rc > 0:
		p["rc"] = int(t.rc)
	var bn = bonus_amounts(p, t.wage, int(t.get("bon", 0)))
	if bn.ab + bn.gb + bn.cs > 0:
		p["bon"] = bn
	else:
		p.erase("bon")
	d.stage = "done"
	say(d, "agent", "Contract signed.")
	G.save_game()


# ---------------------------------------------------------------- money owed later

static func owed() -> Array:
	if not G.s.has("owed"):
		G.s["owed"] = []
	return G.s.owed


static func clauses() -> Array:
	if not G.s.has("clauses"):
		G.s["clauses"] = []
	return G.s.clauses


static func owed_total(cid: int) -> int:
	var t = 0
	for o in owed():
		if o.from == cid:
			t += o.amt
	return t


static func _pay(o: Dictionary, why: String):
	var s = G.s
	s.clubs[o.from].budget -= o.amt
	s.clubs[o.from].spent += o.amt
	s.clubs[o.to].budget += o.amt
	if o.from == s.user.club:
		G.msg("Payment made: %s" % o.name, "%s of %s has been paid to %s for %s." % [why, G.money(o.amt), s.clubs[o.to].name, o.name], "info")
	elif o.to == s.user.club:
		G.msg("Payment received: %s" % o.name, "%s of %s has arrived from %s for %s." % [why, G.money(o.amt), s.clubs[o.from].name, o.name], "info")


# ---------------------------------------------------------------- daily

static func tick():
	var s = G.s
	var ow = owed()
	for i in range(ow.size() - 1, -1, -1):
		if ow[i].day <= s.day:
			_pay(ow[i], "An instalment")
			ow.remove_at(i)
	var cl = clauses()
	for i in range(cl.size() - 1, -1, -1):
		var c = cl[i]
		if not s.players.has(c.pid) or s.players[c.pid].club != c.from:
			cl.remove_at(i)
		elif s.players[c.pid].cap - c.base >= c.apps:
			c["name"] = G.pname(s.players[c.pid])
			_pay(c, "The appearance bonus")
			cl.remove_at(i)
	for pid in all().keys():
		var d = all()[pid]
		if not s.players.has(pid):
			all().erase(pid)
			continue
		var p = s.players[pid]
		upgrade(d)
		if d.stage == "done" or d.stage == "dead":
			if d.stage == "done" and s.day - d.started > 30 or d.stage == "dead" and d.block < s.day - 20:
				all().erase(pid)
			continue
		if d.mode != "buy":
			if s.day - d.started > 21:
				all().erase(pid)
			elif d.mode == "pre" and p.club == s.user.club:
				all().erase(pid)
			continue
		if p.club != d.club:
			kill(d, 0)
			G.msg("%s: deal off" % G.pname(p), "%s has left %s, so your talks have ended." % [G.pfull(p), s.clubs[d.club].name], "deal", pid, true)
			continue
		if d.stage == "deleg" and s.day >= d.wait:
			_delegate_result(d)
		elif d.stage == "meet" and s.day >= d.meet:
			_meeting(d)
		elif d.stage == "talks" and s.day > d.exp:
			kill(d, 7)
			G.msg("%s: agreement lapsed" % G.pname(p), "Your agreed fee with %s for %s has lapsed because personal terms were not settled in time." % [s.clubs[d.club].name, G.pname(p)], "deal", pid, true)
		_rival(d, p)
	_sales()
	if G.cur.day == 20:
		_promises()


static func _rival(d: Dictionary, p: Dictionary):
	var s = G.s
	if d.stage == "dead" or d.stage == "new" or not G.window_open() or p.ovr < 68:
		return
	if d.rival < 0:
		if G.rng.randf() < 0.07:
			var a = ask(p, d)
			for t in 25:
				var c = s.clubs[G.rng.randi() % s.clubs.size()]
				if c.id == s.user.club or c.id == p.club or abs(c.rep - p.ovr) > 6 or c.budget < a or c.players.size() >= 32:
					continue
				d.rival = c.id
				say(d, "news", "%s have joined the race." % c.name)
				G.msg("%s: rival interest" % G.pname(p), "%s are reported to have made an approach for %s. %s now have two clubs at the table and will hold out for more — and the player may not wait for you." % [c.name, G.pfull(p), s.clubs[p.club].name], "deal", p.id, true)
				return
	elif d.stage in ["talks", "meet"] and s.clubs[d.rival].rep >= G.uc().rep - 3 and G.rng.randf() < 0.1:
		var rc = s.clubs[d.rival]
		var fee = min(rc.budget, max(d.fee, ask(p, d)))
		kill(d, 30)
		say(d, "news", "Signed for %s." % rc.name)
		G.TR.move(p, rc.id, fee, max(p.wage, G.wage_for(p.ovr, G.age(p))), 4)
		G.msg("%s joins %s" % [G.pname(p), rc.name], "While you were still discussing terms, %s moved quickly and completed the signing of %s for %s. Your deal is dead." % [rc.name, G.pfull(p), G.money(fee)], "deal", p.id, true)


static func _promises():
	# a player promised a big role who is not getting games lets you know
	var uc = G.uc()
	var played = int(uc.t.p)
	if played < 10:
		return
	for pid in uc.players:
		var p = G.s.players[pid]
		if p.get("rolep", 9) > 1 or p.inj > 0 or p.get("rolew", -1) == G.s.season:
			continue
		if p.ss.ap < played * (0.55 if p.rolep == 0 else 0.4):
			p["rolew"] = G.s.season
			p.mor = max(10, p.mor - 14)
			G.msg("%s: broken promise" % G.pname(p), "%s was promised a place as a %s when he signed, but has played only %d of %d league matches.\n\nHe feels misled and his morale has dropped sharply. Play him, or expect a transfer request." % [G.pfull(p), ROLES[p.rolep].to_lower(), p.ss.ap, played], "contract", null, true)


# ---------------------------------------------------------------- selling

static func counter_sale(o: Dictionary, fee: int, sellon: int, clause := 0):
	o["counter"] = fee
	o["csell"] = sellon
	o["cclause"] = clause
	o["wait"] = G.s.day + 1
	o.exp = max(o.exp, G.s.day + 4)


static func _sales():
	var s = G.s
	for o in s.offers.duplicate():
		if not o.has("wait") or o.wait > s.day or not s.players.has(o.pid):
			continue
		var p = s.players[o.pid]
		var c = s.clubs[o.from]
		var want = int(o.counter)
		var so = int(o.get("csell", 0))
		o.erase("wait")
		var limit = float(G.value(p)) * (1.25 if p.listed else 1.7) * G.rng.randf_range(0.92, 1.06)
		var ccl = int(o.get("cclause", 0))
		var cost = want + so / 100.0 * G.value(p) * 0.35 + [0.0, 0.1, 0.04][ccl] * G.value(p)
		o["rounds"] = o.get("rounds", 0) + 1
		if cost <= limit and want <= c.budget:
			o.fee = want
			o["sellon"] = so
			o["clause"] = ccl
			G.msg("%s: %s agree" % [G.pname(p), c.name], "%s have agreed to your terms: %s%s for %s.\n\nThe offer is on the table for you to accept." % [c.name, G.money(want), (" plus %d%% of any future sale" % so) if so > 0 else "", G.pfull(p)], "offer", o.id, true)
		elif o.rounds >= 3 or cost > limit * 1.5:
			s.offers.erase(o)
			G.msg("%s: %s walk away" % [G.pname(p), c.name], "%s feel your demands for %s are unrealistic and have withdrawn from the talks." % [c.name, G.pfull(p)], "info", null, true)
		else:
			var mid = G.nice(min(c.budget, (o.fee + min(want, limit)) / 2.0))
			o.fee = max(o.fee, mid)
			G.msg("%s: %s improve offer" % [G.pname(p), c.name], "%s will not meet %s, but have raised their bid for %s to %s. You can accept, ask again or turn it down." % [c.name, G.money(want), G.pfull(p), G.money(o.fee)], "offer", o.id, true)

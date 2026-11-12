extends RefCounted
# Transfers as a process: enquiry, a fee negotiated with the club over days (answered by
# message), then personal terms with the player and his agent, then completion.
# Also instalments, appearance add-ons, sell-on clauses, squad-role promises, rival bids
# and counter-offers when other clubs bid for the user's players.

const ROLES = ["Star player", "First team", "Rotation", "Backup", "Prospect"]
const INST = ["All up front", "Half now, half in 12 months", "Three payments over 2 years"]
const NOW = [1.0, 0.5, 0.34]
const ADDON_APPS = 20


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
		"addon": 0, "sellon": 0, "wait": 0, "pat": 3, "ppat": 4, "rival": -1, "exp": 0, "block": 0, "log": [], "terms": {}, "counter": {}}
	all()[p.id] = d
	return d


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


static func enquire(d: Dictionary):
	var p = G.s.players[d.pid]
	d.stage = "enq_wait"
	d.wait = G.s.day + 1
	say(d, "you", "Asked %s whether %s is available and at what price." % [G.s.clubs[p.club].name, G.pname(p)])


static func submit_bid(d: Dictionary, fee: int, inst: int, addon: int, sellon: int) -> Dictionary:
	var p = G.s.players[d.pid]
	var uc = G.uc()
	if not G.window_open():
		return {"ok": false, "text": "The transfer window is closed."}
	var w = G.TR.willing(p)
	if not w.ok and uc.players.size() >= G.TR.MAX_SQUAD:
		return {"ok": false, "text": w.why}
	if pay_now(fee, inst) > uc.budget:
		return {"ok": false, "text": "The first payment of %s is more than your %s budget." % [G.money(pay_now(fee, inst)), G.money(uc.budget)]}
	d.fee = fee
	d.inst = inst
	d.addon = addon
	d.sellon = sellon
	d.stage = "bid_wait"
	d.wait = G.s.day + 1
	say(d, "you", "Bid %s%s." % [G.money(fee), extras(d)])
	return {"ok": true, "text": "Bid sent. %s will reply by message." % G.s.clubs[p.club].name}


static func extras(d: Dictionary) -> String:
	var t = ""
	if d.inst > 0: t += ", " + INST[d.inst].to_lower()
	if d.addon > 0: t += ", %s after %d appearances" % [G.money(d.addon), ADDON_APPS]
	if d.sellon > 0: t += ", %d%% of any future sale" % d.sellon
	return t


static func _reply_enquiry(d: Dictionary):
	var p = G.s.players[d.pid]
	var c = G.s.clubs[p.club]
	var w = G.TR.willing(p)
	d.stage = "club"
	var t = ""
	if untouchable(p):
		d.ask = G.nice(ask(p, d) * 1.25)
		t = "%s is not for sale. He is one of our most important players and we have no wish to lose him.\n\nOnly an exceptional offer — in the region of %s — would make us think again." % [G.pname(p), G.money(d.ask)]
	elif p.listed:
		d.ask = ask(p, d)
		t = "%s is available. We would let him go for around %s and are open to a sensible structure." % [G.pname(p), G.money(d.ask)]
	else:
		d.ask = ask(p, d)
		t = "We are not actively looking to sell %s, but every player has a price. We value him at %s." % [G.pname(p), G.money(d.ask)]
	if p.get("rc", 0) > 0:
		t += "\n\nHis contract contains a release clause of %s, payable in full." % G.money(p.rc)
	if not w.ok:
		t += "\n\nOur understanding is that the player himself may not be keen: %s" % w.why
	say(d, "club", t.split("\n")[0])
	G.msg("%s: reply from %s" % [G.pname(p), c.name], t, "deal", p.id, true)


static func _reply_bid(d: Dictionary):
	var p = G.s.players[d.pid]
	var c = G.s.clubs[p.club]
	var a = float(ask(p, d))
	if untouchable(p):
		a *= 1.25
	var pv = package(p, d.fee, d.inst, d.addon, d.sellon)
	var rc = p.get("rc", 0)
	var title = "%s: %s reply" % [G.pname(p), c.name]
	if rc > 0 and d.fee >= rc and d.inst == 0:
		_agree(d, "Your %s bid meets the release clause in %s's contract. %s cannot refuse, and you may now speak to the player." % [G.money(d.fee), G.pname(p), c.name])
		return
	if pv >= a * 0.95:
		_agree(d, "%s accept your offer of %s%s for %s.\n\nYou have permission to discuss personal terms with the player and his agent. The agreement stands for 10 days." % [c.name, G.money(d.fee), extras(d), G.pfull(p)])
		return
	d.pat -= 1
	d.ask = G.nice(a)
	if d.pat <= 0:
		kill(d)
		say(d, "club", "Talks ended.")
		G.msg(title, "%s have rejected your latest offer and ended the talks. They will not discuss %s again before %s." % [c.name, G.pname(p), G.fmt_date(d.block)], "deal", p.id, true)
		return
	d.stage = "club"
	if pv >= a * 0.72:
		# a counter-offer, softened a little each round
		var want = G.nice(a * (0.99 + 0.03 * d.pat / 3.0))
		d.counter = {"fee": want, "inst": 0, "addon": 0, "sellon": 0}
		var alt = ""
		if d.sellon == 0 and want > 2000000:
			var w2 = G.nice(want * 0.93)
			alt = " Alternatively we would take %s with a 15%% sell-on clause." % G.money(w2)
		say(d, "club", "Rejected. Would accept %s." % G.money(want))
		G.msg(title, "%s have turned down your offer of %s%s.\n\nThey would do business at %s paid up front.%s\n\nThey are prepared to hear %d more offer%s." % [c.name, G.money(d.fee), extras(d), G.money(want), alt, d.pat, "" if d.pat == 1 else "s"], "deal", p.id, true)
	else:
		d.counter = {}
		say(d, "club", "Rejected as far too low.")
		G.msg(title, "%s have dismissed your offer of %s as well short of their valuation of %s.\n\nThey are prepared to hear %d more offer%s." % [c.name, G.money(d.fee), G.money(d.ask), d.pat, "" if d.pat == 1 else "s"], "deal", p.id, true)


static func _agree(d: Dictionary, text: String):
	var p = G.s.players[d.pid]
	d.stage = "talks"
	d.exp = G.s.day + 10
	d.ppat = 4
	say(d, "club", "Fee agreed: %s%s." % [G.money(d.fee), extras(d)])
	G.msg("%s: fee agreed" % G.pname(p), text, "deal", p.id, true)


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
	var sm = {"free": 20.0, "buy": 8.0, "renew": 4.0}[d.mode]
	var base = float(G.TR.wage_demand(p))
	var agent = base * {"free": 10.0, "buy": 5.0, "renew": 3.0}[d.mode]
	if d.mode == "buy":
		agent = max(agent, d.fee * 0.05)
	return {"wage": G.nice(dem), "sign": G.nice(base * sm), "agent": G.nice(agent), "role": er, "blocked": blocked, "notes": notes}


static func default_terms(d: Dictionary) -> Dictionary:
	var p = G.s.players[d.pid]
	var t = {"wage": 0, "years": 3, "role": expected_role(p), "sign": 0, "agent": 0, "rc": 0}
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
	if d.mode == "buy" and not G.window_open():
		return {"res": "error", "text": "The window is closed. The move cannot be registered until it reopens."}
	say(d, "you", "Offered %s/wk for %d yr%s as %s." % [G.money(t.wage), t.years, "" if t.years == 1 else "s", ROLES[t.role].to_lower()])
	var dm = demand(d, t)
	if dm.blocked != "":
		d.ppat -= 1
		say(d, "agent", dm.blocked)
		return _talk_end(d, {"res": "reject", "text": dm.blocked})
	if t.agent < dm.agent * 0.5:
		d.ppat -= 1
		var tx = "The agent will not let this through without a proper fee. He wants about %s for himself." % G.money(dm.agent)
		say(d, "agent", tx)
		return _talk_end(d, {"res": "counter", "text": tx, "wage": t.wage, "sign": t.sign, "agent": dm.agent})
	var span = 52.0 * t.years
	var need = dm.wage + dm.sign / span
	if t.agent >= dm.agent * 1.5:
		need *= 0.96
	var have = t.wage + t.sign / span
	if have >= need * 0.97:
		complete(d, t)
		return {"res": "accept", "text": "%s agrees to a %d-year deal worth %s per week." % [G.pname(p), t.years, G.money(t.wage)]}
	d.ppat -= 1
	if have >= need * 0.8:
		var tx2 = "We are not far apart. %s would sign for %s a week with %s on signing." % [G.pname(p), G.money(dm.wage), G.money(dm.sign)]
		say(d, "agent", tx2)
		return _talk_end(d, {"res": "counter", "text": tx2, "wage": dm.wage, "sign": dm.sign, "agent": max(t.agent, dm.agent)})
	var tx3 = "That is a long way short. My client is looking for around %s a week." % G.money(dm.wage)
	say(d, "agent", tx3)
	return _talk_end(d, {"res": "reject", "text": tx3})


static func _talk_end(d: Dictionary, r: Dictionary) -> Dictionary:
	if d.ppat <= 0:
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
		G.PS.learn(p, G.PS.country_of(uc.id))
		G.scrap("Signed %s" % G.pname(p), "%s joined%s on a %d-year contract." % [G.pfull(p), (" for " + G.money(d.fee)) if d.fee > 0 else " on a free transfer", t.years])
		G.SOC.on_signing(p, d.fee)
	uc.budget -= int(t.sign) + int(t.agent)
	p["rolep"] = int(t.role)
	p.erase("rolew")
	if t.rc > 0:
		p["rc"] = int(t.rc)
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
		if d.stage == "done" or d.stage == "dead":
			if d.stage == "done" and s.day - d.started > 30 or d.stage == "dead" and d.block < s.day - 20:
				all().erase(pid)
			continue
		if d.mode != "buy":
			if s.day - d.started > 21:
				all().erase(pid)
			continue
		if p.club != d.club:
			kill(d, 0)
			G.msg("%s: deal off" % G.pname(p), "%s has left %s, so your talks have ended." % [G.pfull(p), s.clubs[d.club].name], "deal", pid, true)
			continue
		if d.stage == "enq_wait" and s.day >= d.wait:
			_reply_enquiry(d)
		elif d.stage == "bid_wait" and s.day >= d.wait:
			_reply_bid(d)
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
	elif d.stage == "talks" and s.clubs[d.rival].rep >= G.uc().rep - 3 and G.rng.randf() < 0.1:
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

static func counter_sale(o: Dictionary, fee: int, sellon: int):
	o["counter"] = fee
	o["csell"] = sellon
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
		var cost = want + so / 100.0 * G.value(p) * 0.35
		o["rounds"] = o.get("rounds", 0) + 1
		if cost <= limit and want <= c.budget:
			o.fee = want
			o["sellon"] = so
			G.msg("%s: %s agree" % [G.pname(p), c.name], "%s have agreed to your terms: %s%s for %s.\n\nThe offer is on the table for you to accept." % [c.name, G.money(want), (" plus %d%% of any future sale" % so) if so > 0 else "", G.pfull(p)], "offer", o.id, true)
		elif o.rounds >= 3 or cost > limit * 1.5:
			s.offers.erase(o)
			G.msg("%s: %s walk away" % [G.pname(p), c.name], "%s feel your demands for %s are unrealistic and have withdrawn from the talks." % [c.name, G.pfull(p)], "info", null, true)
		else:
			var mid = G.nice(min(c.budget, (o.fee + min(want, limit)) / 2.0))
			o.fee = max(o.fee, mid)
			G.msg("%s: %s improve offer" % [G.pname(p), c.name], "%s will not meet %s, but have raised their bid for %s to %s. You can accept, ask again or turn it down." % [c.name, G.money(want), G.pfull(p), G.money(o.fee)], "offer", o.id, true)

extends RefCounted
# Transfer market: valuations, negotiations, AI activity and offers for the user's players.

const MAX_SQUAD = 40


static func squad_rank(p: Dictionary) -> int:
	var c = G.s.clubs[p.club]
	var r = 0
	for pid in c.players:
		if G.s.players[pid].ovr > p.ovr:
			r += 1
	return r


static func asking_price(p: Dictionary) -> int:
	var v = float(G.value(p))
	if p.club < 0:
		return 0
	var r = squad_rank(p)
	var m = 1.0
	if r < 5: m = 1.6
	elif r < 11: m = 1.35
	elif r < 18: m = 1.15
	if p.listed:
		m = 0.9
	if p.cend - G.s.season <= 1:
		m *= 0.85
	m *= 1.0 - (G.s.user.attr.neg - 10) * 0.01
	return G.nice(v * m)


static func nego(pid: int) -> Dictionary:
	if not G.s.negos.has(pid):
		G.s.negos[pid] = {"tries": 0, "block": 0, "fee": -1}
	return G.s.negos[pid]


static func willing(p: Dictionary) -> Dictionary:
	# would the player consider joining the user's club?
	var uc = G.uc()
	if uc.players.size() >= MAX_SQUAD:
		return {"ok": false, "why": "Your squad is full (%d players)." % MAX_SQUAD}
	if p.club < 0:
		if p.ovr > uc.rep + 9:
			return {"ok": false, "why": "%s is holding out for a bigger club." % G.pname(p)}
		return {"ok": true, "why": ""}
	var c = G.s.clubs[p.club]
	var gap = c.rep - uc.rep
	var tol = 4.0
	if p.listed: tol += 14.0
	if squad_rank(p) >= 14: tol += 8.0
	if p.ovr > uc.rep + 8:
		return {"ok": false, "why": "%s does not see %s as a step forward in his career." % [G.pname(p), uc.name]}
	if gap > tol:
		return {"ok": false, "why": "%s is not interested in leaving %s for %s." % [G.pname(p), c.name, uc.name]}
	return {"ok": true, "why": ""}


static func bid(p: Dictionary, fee: int) -> Dictionary:
	var n = nego(p.id)
	var ask = asking_price(p)
	var uc = G.uc()
	if fee > uc.budget:
		return {"res": "error", "text": "You only have %s in the transfer budget." % G.money(uc.budget)}
	if n.block > G.s.day:
		return {"res": "reject", "text": "%s have ended negotiations for now. Try again after %s." % [G.s.clubs[p.club].name, G.fmt_date(n.block)]}
	if fee >= ask * 0.95:
		n.fee = fee
		return {"res": "accept", "text": "%s accept your offer of %s." % [G.s.clubs[p.club].name, G.money(fee)]}
	n.tries += 1
	if n.tries >= 4:
		n.block = G.s.day + 14
		n.tries = 0
		return {"res": "reject", "text": "%s are tired of your offers and have walked away from the table." % G.s.clubs[p.club].name}
	if fee >= ask * 0.72:
		return {"res": "counter", "fee": ask, "text": "%s reject the bid but would do business at %s." % [G.s.clubs[p.club].name, G.money(ask)]}
	return {"res": "reject", "text": "%s dismiss the offer as far below their valuation." % G.s.clubs[p.club].name}


static func wage_demand(p: Dictionary) -> int:
	var uc = G.uc()
	var base = float(G.wage_for(p.ovr, G.age(p)))
	if p.club == uc.id:
		return G.nice(max(base, p.wage * 1.08))
	var m = 1.12 * (1.0 - (G.s.user.attr.neg - 10) * 0.008)
	if p.club >= 0:
		m += clamp((G.s.clubs[p.club].rep - uc.rep) * 0.02, 0.0, 0.3)
		base = max(base, p.wage * 1.05)
	return G.nice(base * m)


static func contract_offer(p: Dictionary, wage: int, years: int) -> Dictionary:
	var uc = G.uc()
	var dem = wage_demand(p)
	var own = p.club == uc.id
	var total = G.squad_wages(uc) + wage - (p.wage if own else 0)
	if total > uc.wage_budget:
		return {"res": "error", "text": "This would take the wage bill to %s/wk — over the %s/wk budget." % [G.money(total), G.money(uc.wage_budget)]}
	if own and p.mor < 35:
		return {"res": "reject", "text": "%s is unhappy and refuses to discuss a new deal right now." % G.pname(p)}
	var a = G.age(p)
	if a >= 32 and years > 2:
		dem = int(dem * 0.95)
	if wage >= dem * 0.97:
		return {"res": "accept", "text": "%s agrees to a %d-year deal worth %s per week." % [G.pname(p), years, G.money(wage)]}
	if wage >= dem * 0.8:
		return {"res": "counter", "wage": dem, "text": "%s's agent wants %s per week." % [G.pname(p), G.money(dem)]}
	return {"res": "reject", "text": "%s's agent calls the offer insulting. He expects around %s per week." % [G.pname(p), G.money(dem)]}


static func move(p: Dictionary, to_id: int, fee: int, wage: int, years: int):
	var s = G.s
	var from_id = p.club
	var from_name = "Free agent"
	if from_id >= 0:
		var fc = s.clubs[from_id]
		from_name = fc.name
		fc.players.erase(p.id)
		fc.bench.erase(p.id)
		var i = fc.xi.find(p.id)
		if i >= 0:
			fc.xi[i] = -1
		fc.budget += fee
		fc.earned += fee
	else:
		s.free.erase(p.id)
	var tc = s.clubs[to_id]
	tc.players.append(p.id)
	tc.budget -= fee
	tc.spent += fee
	p.club = to_id
	p.erase("status")
	G.give_number(tc, p)
	p.wage = wage
	p.cend = s.season + years
	p.listed = false
	p.mor = max(p.mor, 75)
	s.shortlist.erase(p.id)
	s.negos.erase(p.id)
	for i in range(s.offers.size() - 1, -1, -1):
		if s.offers[i].pid == p.id:
			s.offers.remove_at(i)
	s.tx_log.push_front({"day": s.day, "name": G.pname(p), "from": from_name, "to": tc.name, "fee": fee, "ovr": p.ovr, "user": to_id == s.user.club or from_id == s.user.club})
	if s.tx_log.size() > 200:
		s.tx_log.resize(200)
	if fee >= 15000000 or to_id == s.user.club or from_id == s.user.club:
		G.news("%s joins %s from %s%s." % [G.pfull(p), tc.name, from_name, " for " + G.money(fee) if fee > 0 else " on a free transfer"])
	if from_id == s.user.club:
		G.fix_lineup()


static func renew(p: Dictionary, wage: int, years: int):
	p.wage = wage
	p.cend = G.s.season + years
	p.mor = min(100, p.mor + 8)


# ---------------------------------------------------------------- AI

static func has_offer(pid: int) -> bool:
	for o in G.s.offers:
		if o.pid == pid:
			return true
	return false


static func daily():
	var s = G.s
	var rng = G.rng
	var uc = G.uc()
	for pid in uc.players:
		var p = s.players[pid]
		if p.get("loan", -1) >= 0 or p.get("youth", false) or (not p.listed and p.ovr < uc.rep - 2):
			continue
		if rng.randf() < (0.2 if p.listed else 0.004) and not has_offer(pid):
			make_offer(p)
	for i in 5:
		ai_deal()
	if rng.randf() < 0.6 and s.free.size() > 0:
		ai_free()


static func make_offer(p: Dictionary):
	var s = G.s
	var rng = G.rng
	var uc = G.uc()
	var v = float(G.value(p))
	for t in 30:
		var c = s.clubs[rng.randi() % s.clubs.size()]
		if c.id == uc.id or c.players.size() >= 32:
			continue
		if p.ovr < c.rep - 7 or p.ovr > c.rep + 7:
			continue
		if not p.listed and c.rep < uc.rep - 1:
			continue
		var fee = G.nice(v * (rng.randf_range(0.82, 1.08) if p.listed else rng.randf_range(1.15, 1.5)))
		if fee > c.budget:
			continue
		var o = {"id": s.offer_id, "pid": p.id, "from": c.id, "fee": fee, "exp": s.day + 5, "haggled": false}
		s.offer_id += 1
		s.offers.append(o)
		G.msg("Offer for %s" % G.pname(p), "%s have made a %s bid for %s (value %s).\n\nThe offer expires in 5 days." % [c.name, G.money(fee), G.pfull(p), G.money(v)], "offer", o.id, true)
		return


static func expire_offers():
	var s = G.s
	for i in range(s.offers.size() - 1, -1, -1):
		var o = s.offers[i]
		if o.exp < s.day or not s.players.has(o.pid) or s.players[o.pid].club != s.user.club:
			s.offers.remove_at(i)


static func accept_offer(o: Dictionary):
	var p = G.s.players[o.pid]
	var c = G.s.clubs[o.from]
	move(p, o.from, o.fee, max(p.wage, G.wage_for(p.ovr, G.age(p))), G.rng.randi_range(2, 4))
	G.msg("%s sold" % G.pname(p), "%s has completed his move to %s for %s. The fee has been added to your transfer budget." % [G.pfull(p), c.name, G.money(o.fee)], "info")


static func haggle_offer(o: Dictionary) -> String:
	# ask for 15% more; the buyer may improve, hold or walk away
	var p = G.s.players[o.pid]
	var c = G.s.clubs[o.from]
	if o.haggled:
		return "%s say this is their final offer." % c.name
	o.haggled = true
	var want = G.nice(o.fee * 1.15)
	var limit = float(G.value(p)) * (1.25 if p.listed else 1.7)
	var r = G.rng.randf()
	if want <= limit and want <= c.budget and r < 0.6:
		o.fee = want
		return "%s improve their offer to %s." % [c.name, G.money(want)]
	if r < 0.85:
		return "%s refuse to go any higher than %s." % [c.name, G.money(o.fee)]
	G.s.offers.erase(o)
	return "%s have withdrawn their offer." % c.name


static func ai_deal():
	var s = G.s
	var rng = G.rng
	var buyer = s.clubs[rng.randi() % s.clubs.size()]
	if buyer.id == s.user.club or buyer.players.size() >= 30 or buyer.budget < 200000:
		return
	for t in 12:
		var seller = s.clubs[rng.randi() % s.clubs.size()]
		if seller.id == buyer.id or seller.id == s.user.club or seller.players.size() <= 21:
			continue
		var p = s.players[seller.players[rng.randi() % seller.players.size()]]
		if p.ovr < buyer.rep - 1 or p.ovr > buyer.rep + 6 or G.age(p) > 30 or p.get("loan", -1) >= 0:
			continue
		if seller.rep > buyer.rep + 2 and not p.listed:
			continue
		var fee = G.nice(G.value(p) * 1.2)
		if fee > buyer.budget:
			continue
		var line = G.LINE[p.pos]
		var better = 0
		var same_line = 0
		for pid in buyer.players:
			var q = s.players[pid]
			if G.LINE[q.pos] == line:
				same_line += 1
				if q.ovr >= p.ovr:
					better += 1
		if better >= (1 if line == 0 else 3) or (line == 0 and same_line >= 3):
			continue
		# the seller must keep enough cover in that line
		var cover = 0
		for pid in seller.players:
			if G.LINE[s.players[pid].pos] == line:
				cover += 1
		if cover <= [2, 6, 6, 4][line]:
			continue
		move(p, buyer.id, fee, max(p.wage, G.wage_for(p.ovr, G.age(p))), rng.randi_range(2, 5))
		return


static func ai_free():
	var s = G.s
	var rng = G.rng
	var p = s.players[s.free[rng.randi() % s.free.size()]]
	for t in 10:
		var c = s.clubs[rng.randi() % s.clubs.size()]
		if c.id == s.user.club or c.players.size() >= 28:
			continue
		if p.ovr >= c.rep - 6 and p.ovr <= c.rep + 3:
			move(p, c.id, 0, G.wage_for(p.ovr, G.age(p)), rng.randi_range(1, 2))
			return

extends RefCounted
# The transfer market around the negotiation itself: recruitment briefs, loans with terms,
# pre-contracts, buy-back clauses and matching rights, players with minds of their own,
# agents offering players, performance bonuses, and deadline day played hour by hour.

const SHARE = [0.5, 0.75, 1.0]
const SHARE_TXT = ["Half his wages", "Three quarters", "All his wages"]
const OPT_TXT = ["Straight loan", "Option to buy", "Must buy"]
const AGES = [21, 24, 28, 99]
const AGE_TXT = ["21 or under", "24 or under", "28 or under", "Any age"]
const FEES = [0.25, 0.5, 1.0, 99.0]
const FEE_TXT = ["Quarter of budget", "Half of budget", "Whole budget", "Any price"]
const POSITIONS = ["GK", "CB", "LB", "RB", "CDM", "CM", "CAM", "LM", "RM", "LW", "RW", "ST"]


# ---------------------------------------------------------------- performance bonuses

static func pay_bonuses(sim, side: int):
	# the user's players with bonuses in their contracts are paid as they earn them
	var s = G.s
	var t = sim.sd[side]
	var o = sim.sd[1 - side]
	var uc = G.uc()
	var tot = 0
	for pid in sim.pm:
		var q = sim.pm[pid]
		if q.tin < 0 or not s.players.has(pid):
			continue
		var p = s.players[pid]
		if p.club != uc.id or not p.has("bon"):
			continue
		var b = p.bon
		var amt = int(b.ab) + int(b.gb) * int(q.g)
		if o.goals == 0 and q.tin == 0 and q.tout < 0:
			amt += int(b.cs)
		tot += amt
		p["bonp"] = int(p.get("bonp", 0)) + amt
	if tot > 0:
		uc.budget -= tot
		s.user["bon_week"] = int(s.user.get("bon_week", 0)) + tot


# ---------------------------------------------------------------- pre-contracts

static func pre_window() -> bool:
	# from 1 January a player in the last months of his deal may sign for next season
	var s = G.s
	return s.day >= G.ymd(s.season + 1, 1, 1) and s.day < G.ymd(s.season + 1, 6, 1)


static func can_pre(p: Dictionary) -> Dictionary:
	var s = G.s
	if p.club < 0 or p.club == s.user.club:
		return {"ok": false, "why": ""}
	if p.cend > s.season + 1:
		return {"ok": false, "why": ""}
	if not pre_window():
		return {"ok": false, "why": "His contract ends in June. From 1 January you can agree a pre-contract with him."}
	if p.has("pre"):
		return {"ok": false, "why": "He has already agreed to join %s in the summer." % s.clubs[int(p.pre.club)].name}
	var w = G.TR.willing(p)
	if not w.ok:
		return {"ok": false, "why": w.why}
	return {"ok": true, "why": ""}


static func fulfil_pre(p: Dictionary):
	# called at the season rollover for a player whose contract has run out and who signed elsewhere
	var s = G.s
	var pre = p.pre
	p.erase("pre")
	var cid = int(pre.club)
	if cid < 0 or cid >= s.clubs.size():
		G.LG.release(p)
		return
	var old = s.clubs[p.club].name if p.club >= 0 else "his old club"
	G.TR.move(p, cid, 0, int(pre.wage), int(pre.years))
	if cid == s.user.club:
		p["rolep"] = int(pre.get("role", 2))
		if int(pre.get("rc", 0)) > 0:
			p["rc"] = int(pre.rc)
		var b = pre.get("bon", {"ab": 0, "gb": 0, "cs": 0})
		if int(b.ab) + int(b.gb) + int(b.cs) > 0:
			p["bon"] = b
		G.msg("%s has arrived" % G.pname(p), "%s has joined from %s on the pre-contract he signed earlier in the year. He is yours on a free transfer." % [G.pfull(p), old], "info", null, true)


static func ai_pre():
	# rivals move for the user's players who have been left to run their contracts down
	var s = G.s
	var uc = G.uc()
	if not pre_window():
		return
	for pid in uc.players:
		var p = s.players[pid]
		if p.cend > s.season + 1 or p.has("pre") or p.get("loan", -1) >= 0 or p.ovr < uc.rep - 8 or G.age(p) >= 34:
			continue
		if G.rng.randf() > 0.22:
			continue
		for t in 30:
			var c = s.clubs[G.rng.randi() % s.clubs.size()]
			if c.id == uc.id or abs(c.rep - p.ovr) > 6 or c.players.size() >= 30:
				continue
			p["pre"] = {"club": c.id, "wage": max(p.wage, G.wage_for(p.ovr, G.age(p))), "years": G.rng.randi_range(2, 4)}
			p.mor = max(30, p.mor - 4)
			G.news("%s will join %s on a free transfer when his contract ends in June." % [G.pfull(p), c.name])
			G.msg("%s signs for %s" % [G.pname(p), c.name], "%s has agreed a pre-contract with %s and will leave on a free transfer when his deal runs out in June.\n\nHe stays with you until then. There is nothing you can do to stop it now: a new contract had to be agreed before he signed elsewhere." % [G.pfull(p), c.name], "contract", null, true)
			break


# ---------------------------------------------------------------- loans with terms

static func loan_view(p: Dictionary) -> Dictionary:
	# how the parent club sees a loan request, before any terms
	var s = G.s
	var uc = G.uc()
	if p.club < 0 or p.get("loan", -1) >= 0:
		return {"ok": false, "why": "Not available for loan."}
	if not G.window_open():
		return {"ok": false, "why": "The transfer window is closed."}
	if uc.players.size() >= G.TR.MAX_SQUAD:
		return {"ok": false, "why": "Your squad is full."}
	var c = s.clubs[p.club]
	if p.ovr > uc.rep + 6:
		return {"ok": false, "why": "%s want him to play at a higher level." % c.name}
	var core = not p.listed and (G.TR.squad_rank(p) < 13 or G.age(p) > 24)
	return {"ok": true, "why": "", "core": core, "young": G.age(p) <= 21}


static func loan_offer(p: Dictionary, share: int, opt: int, fee: int, starter: bool) -> Dictionary:
	var s = G.s
	var uc = G.uc()
	var lv = loan_view(p)
	if not lv.ok:
		return {"ok": false, "text": lv.why}
	var c = s.clubs[p.club]
	var pay = int(p.wage * SHARE[share])
	if G.squad_wages(uc) + pay > uc.wage_budget:
		return {"ok": false, "text": "You cannot cover %s a week of his wages." % G.money(pay)}
	var val = float(G.value(p))
	var tries = int(p.get("ltry", 0))
	if lv.core:
		if opt != 2 or fee < val * 1.05:
			p["ltry"] = tries + 1
			return {"ok": false, "text": "“He is part of our plans. The only loan we would consider is one you must make permanent, at %s or more.”" % G.money(G.nice(val * 1.05))}
	if lv.young and not starter and share < 2:
		p["ltry"] = tries + 1
		return {"ok": false, "text": "“We want him to play. Promise him first-team football or pay all of his wages.”"}
	if share == 0 and not p.listed and opt == 0:
		p["ltry"] = tries + 1
		return {"ok": false, "text": "“Half his wages is not enough for a straight loan. Pay more of them, or add an option to buy.”"}
	if opt == 1 and fee < val * 1.1:
		return {"ok": false, "text": "“An option has to be worth our while: %s or more.”" % G.money(G.nice(val * 1.1))}
	if opt == 2 and fee < val * 0.95:
		return {"ok": false, "text": "“If you must buy him, the price is %s or more.”" % G.money(G.nice(val * 0.95))}
	p.erase("ltry")
	var from = p.club
	G.OPS.loan_in(p)
	p["lw"] = SHARE[share]
	p["lterms"] = {"from": from, "opt": opt, "fee": fee if opt > 0 else 0, "starter": starter}
	if starter:
		p["rolep"] = 1
	var extra = ""
	if opt == 1:
		extra = " You have an option to buy him for %s in the summer." % G.money(fee)
	elif opt == 2:
		extra = " You are committed to buying him for %s in the summer." % G.money(fee)
	return {"ok": true, "text": "%s agree. %s joins on loan until the end of the season; you pay %s a week.%s" % [c.name, G.pname(p), G.money(pay), extra]}


static func loan_check():
	# monthly: a loanee promised football who is not getting it is called back by his club
	var s = G.s
	var uc = G.uc()
	if int(uc.t.p) < 8:
		return
	for pid in uc.players.duplicate():
		var p = s.players[pid]
		var lt = p.get("lterms", null)
		if lt == null or p.get("loan", -1) < 0 or not lt.starter or p.inj > 0:
			continue
		if p.ss.ap < uc.t.p * 0.4 and G.window_open():
			var parent = int(p.loan)
			p.erase("loan")
			p.erase("lw")
			p.erase("lterms")
			p.erase("rolep")
			G.OPS._shift(p, parent)
			G.fix_lineup()
			G.msg("%s recalled" % G.pname(p), "%s have ended %s's loan. You promised him first-team football and he has played %d of %d league matches." % [s.clubs[parent].name, G.pfull(p), p.ss.ap, uc.t.p], "info", null, true)


static func before_return():
	# season end, before loans go home: remember options and obligations to buy
	var s = G.s
	var out = []
	for pid in s.players:
		var p = s.players[pid]
		if p.has("lterms"):
			if p.club == s.user.club and int(p.lterms.opt) > 0:
				out.append({"pid": pid, "opt": int(p.lterms.opt), "fee": int(p.lterms.fee), "from": int(p.lterms.from)})
			p.erase("lterms")
			p.erase("lw")
		p.erase("lpay")
		p.erase("lrecall")
	s["loan_opts"] = out


static func after_rollover():
	# the new season has started: complete compulsory purchases and put options on the table
	var s = G.s
	var uc = G.uc()
	for o in s.get("loan_opts", []):
		if not s.players.has(o.pid):
			continue
		var p = s.players[o.pid]
		if p.club != o.from:
			continue
		if o.opt == 2:
			G.TR.move(p, uc.id, o.fee, max(p.wage, G.wage_for(p.ovr, G.age(p))), 4)
			G.msg("%s signs permanently" % G.pname(p), "Under the terms of last season's loan, %s has joined permanently for %s." % [G.pfull(p), G.money(o.fee)], "info", null, true)
		else:
			var d = G.DL.start(p, "buy")
			d.fee = o.fee
			d.ask = o.fee
			d.stage = "talks"
			d.exp = s.day + 21
			G.DL.say(d, "club", "Option to buy at %s." % G.money(o.fee))
			G.msg("%s: option to buy" % G.pname(p), "Your loan agreement gives you the option to sign %s for %s. The fee is already agreed: open the talks to settle his contract. The option lapses on %s." % [G.pfull(p), G.money(o.fee), G.fmt_date(d.exp)], "deal", p.id, true)
	s["loan_opts"] = []


static func loan_out(p: Dictionary, they_pay: int, recall: bool) -> String:
	# they_pay: 0 half, 1 three quarters, 2 all. Paying part of the wages yourself finds him a better club
	var s = G.s
	var uc = G.uc()
	if uc.players.size() <= 18:
		return "You need at least 18 players."
	var reach = [14, 11, 9][they_pay]
	var best = null
	for t in 120:
		var c = s.clubs[G.rng.randi() % s.clubs.size()]
		if c.id == uc.id or c.players.size() >= 30 or c.rep > p.ovr + (7 if they_pay < 2 else 4) or c.rep < p.ovr - reach:
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
		return "No club is offering %s regular football on those terms. Try paying more of his wages yourself." % G.pname(p)
	G.OPS._shift(p, best.id)
	p["loan"] = uc.id
	p.erase("youth")
	if they_pay < 2:
		p["lpay"] = 1.0 - SHARE[they_pay]
	if recall:
		p["lrecall"] = true
	G.fix_lineup()
	G.news("%s joins %s on loan from %s." % [G.pfull(p), best.name, uc.name])
	G.msg("%s loaned out" % G.pname(p), "%s has joined %s on loan until the end of the season. They pay %s of his wages.%s" % [G.pfull(p), best.name, SHARE_TXT[they_pay].to_lower().replace("his wages", "").strip_edges() if they_pay < 2 else "all", " You can recall him in January." if recall else ""], "info")
	return ""


static func can_recall(p: Dictionary) -> bool:
	return p.get("loan", -1) == G.s.user.club and p.club != G.s.user.club and p.get("lrecall", false) and G.window_open()


static func recall(p: Dictionary):
	var uc = G.uc()
	var at = G.s.clubs[p.club].name
	p.erase("loan")
	p.erase("lpay")
	p.erase("lrecall")
	G.OPS._shift(p, uc.id)
	G.msg("%s recalled" % G.pname(p), "%s is back from his loan at %s." % [G.pfull(p), at], "info")


static func loan_wages(c: Dictionary) -> int:
	# the share of wages the user still pays for players he has loaned out
	var tot = 0
	for pid in G.s.players:
		var p = G.s.players[pid]
		if p.has("lpay") and p.get("loan", -1) == c.id:
			tot += int(p.wage * float(p.lpay))
	return tot


# ---------------------------------------------------------------- buy-backs and matching rights

static func bb_fee(fee: int) -> int:
	return G.nice(fee * 1.6)


static func set_sale_clause(p: Dictionary, kind: int, fee: int):
	# kind 1: buy-back for the user; 2: the user may match any accepted bid
	var s = G.s
	if kind == 1:
		p["bb"] = {"club": s.user.club, "fee": bb_fee(fee), "until": s.season + 3}
	elif kind == 2:
		p["mr"] = s.user.club


static func can_buy_back(p: Dictionary) -> bool:
	var b = p.get("bb", null)
	return b != null and int(b.club) == G.s.user.club and p.club != G.s.user.club and p.club >= 0 and int(b.until) >= G.s.season


static func agreed_deal(p: Dictionary, fee: int, line: String) -> Dictionary:
	# a deal whose fee is fixed in advance (buy-back, matched bid): straight to the player's side
	G.DL.all().erase(p.id)
	var d = G.DL.start(p, "buy")
	d.fee = fee
	d.ask = fee
	G.DL._agree(d, line)
	return d


static func ai_buy_backs():
	# clubs that sold the user a young player with a buy-back take him home if he has grown
	var s = G.s
	var uc = G.uc()
	if not G.window_open():
		return
	for pid in uc.players.duplicate():
		var p = s.players[pid]
		var b = p.get("bb", null)
		if b == null or int(b.club) == uc.id:
			continue
		if int(b.until) < s.season:
			p.erase("bb")
			continue
		var c = s.clubs[int(b.club)]
		if G.value(p) > int(b.fee) * 1.25 and c.budget >= int(b.fee) and G.rng.randf() < 0.5:
			var fee = int(b.fee)
			p.erase("bb")
			G.TR.move(p, c.id, fee, max(p.wage, G.wage_for(p.ovr, G.age(p))), 4)
			G.msg("%s: buy-back activated" % G.pname(p), "%s have used the buy-back clause they insisted on when they sold you %s. He returns to them for %s and there is nothing you can do." % [c.name, G.pfull(p), G.money(fee)], "info", null, true)


static func hold_for_match(p: Dictionary, buyer: Dictionary, fee: int) -> bool:
	# a club has agreed to buy a player the user holds a matching right on: the user gets three days
	var s = G.s
	if int(p.get("mr", -1)) != s.user.club or p.has("mrh"):
		return false
	p["mrh"] = {"club": buyer.id, "fee": fee, "exp": s.day + 3}
	G.msg("%s: your right to match" % G.pname(p), "%s have agreed to sign %s from %s for %s.\n\nYou kept a matching right when you sold him. Open his profile and match the bid within three days and he comes back to you instead." % [buyer.name, G.pfull(p), s.clubs[p.club].name, G.money(fee)], "deal", p.id, true)
	return true


static func _held_moves():
	var s = G.s
	for pid in s.players:
		var p = s.players[pid]
		var h = p.get("mrh", null)
		if h == null or int(h.exp) >= s.day:
			continue
		p.erase("mrh")
		p.erase("mr")
		var c = s.clubs[int(h.club)]
		if p.club >= 0 and p.club != c.id and p.club != s.user.club and c.budget >= int(h.fee):
			G.TR.move(p, c.id, int(h.fee), max(p.wage, G.wage_for(p.ovr, G.age(p))), 4)


# ---------------------------------------------------------------- players with their own minds

static func rejected_offer(o: Dictionary):
	# the user turned down a bid: a player wanted by a bigger club may not take it well
	var s = G.s
	if not s.players.has(o.pid):
		return
	var p = s.players[o.pid]
	var c = s.clubs[o.from]
	var uc = G.uc()
	if c.rep < uc.rep + 3 or p.listed:
		return
	var per = G.PS.personality(p)
	var ch = 0.45 if per == "Ambitious" else (0.1 if per == "Loyal" else 0.28)
	if G.rng.randf() < ch:
		p.mor = max(15, p.mor - 14)
		p["unhappy"] = 1
		G.msg("%s is unsettled" % G.pname(p), "%s knows %s wanted him and that you said no. He feels he has been denied a move to a bigger club.\n\nHis morale has dropped. A better contract or a run in the team may bring him round; otherwise expect him to push to leave." % [G.pfull(p), c.name], "info", null, true)


static func turn_heads():
	# weekly in the window: a bigger club makes eyes at one of the user's best players
	var s = G.s
	var uc = G.uc()
	if not G.window_open() or G.rng.randf() > 0.1:
		return
	var best = []
	for pid in uc.players:
		best.append(s.players[pid])
	best.sort_custom(func(a, b): return a.ovr > b.ovr)
	var p = best[G.rng.randi() % min(5, best.size())]
	if p.get("loan", -1) >= 0 or G.TR.has_offer(p.id) or G.age(p) >= 32:
		return
	for t in 40:
		var c = s.clubs[G.rng.randi() % s.clubs.size()]
		if c.id == uc.id or c.rep < uc.rep + 3 or c.rep < p.ovr - 5 or c.players.size() >= 32:
			continue
		var fee = G.nice(G.value(p) * G.rng.randf_range(1.2, 1.5))
		if fee > c.budget:
			continue
		var o = {"id": s.offer_id, "pid": p.id, "from": c.id, "fee": fee, "exp": s.day + 5, "haggled": false}
		s.offer_id += 1
		s.offers.append(o)
		G.msg("%s want %s" % [c.name, G.pname(p)], "%s have bid %s for %s, and the player knows about it. A move to a club of their size will appeal to him.\n\nIf you turn it down he may be unsettled. The offer stands for 5 days." % [c.name, G.money(fee), G.pfull(p)], "offer", o.id, true)
		return


static func agent_offer(panic := false) -> bool:
	# an agent rings up offering a player who suits the user's club and budget
	var s = G.s
	var uc = G.uc()
	var st = G.TC.style_of(uc)
	var best = null
	var bs = -1.0
	for t in 400:
		var c = s.clubs[G.rng.randi() % s.clubs.size()]
		if c.id == uc.id or c.players.is_empty() or s.leagues[c.lg].get("roe", false):
			continue
		var p = s.players[c.players[G.rng.randi() % c.players.size()]]
		if p.get("loan", -1) >= 0 or p.has("pre") or G.DL.find(p.id) != null or p.ovr < uc.rep - 5 or p.ovr > uc.rep + 4 or G.age(p) > 30:
			continue
		if not (p.listed or p.cend <= s.season + 1 or G.TR.squad_rank(p) >= 12):
			continue
		if not G.TR.willing(p).ok or G.TR.asking_price(p) > uc.budget * 0.8:
			continue
		var sc = p.ovr + (4.0 if G.TC.best_fit_role(p, p.pos, st) != "" else 0.0) + (3.0 if p.listed else 0.0) - G.age(p) * 0.2
		if sc > bs:
			bs = sc
			best = p
	if best == null:
		return false
	var c2 = s.clubs[best.club]
	if panic:
		best.listed = true
	var price = G.TR.asking_price(best)
	G.msg("Agent offers %s" % G.pname(best), "%s's agent has been in touch. %s (%s, %d, rated %d) %s and could be signed for around %s.\n\n%s\n\nOpen the talks from this message if you are interested." % [G.pname(best), G.pfull(best), best.pos, G.age(best), best.ovr,
		"is free to leave %s" % c2.name if best.listed else ("is in the last year of his contract at %s" % c2.name if best.cend <= s.season + 1 else "is not getting games at %s" % c2.name),
		G.money(price), G.TC.fit_text(best)], "deal", best.id, panic)
	return true


# ---------------------------------------------------------------- recruitment brief

static func brief_start(b: Dictionary):
	var sc = G.s.scout
	b["done"] = G.s.day + max(2, G.OPS.scout_days() - 2)
	sc["brief"] = b
	sc.erase("brief_res")


static func brief_text(b: Dictionary) -> String:
	var bits = [b.pos, AGE_TXT[b.age].to_lower(), FEE_TXT[b.fee].to_lower()]
	if int(b.foot) > 0:
		bits.append("%s-footed" % ("left" if b.foot == 1 else "right"))
	if b.style:
		bits.append("fits your playstyle")
	if str(b.link) != "":
		var pr = str(b.link).split(":")
		if G.TC.LINKS.has(pr[0]):
			bits.append("for your %s link-up" % G.TC.LINKS[pr[0]].n)
	return ", ".join(bits)


static func _brief_run():
	var s = G.s
	var uc = G.uc()
	var b = s.scout.brief
	var st = G.TC.style_of(uc)
	var max_fee = uc.budget * FEES[b.fee]
	var slot = null
	if str(b.link) != "":
		var pr = str(b.link).split(":")
		if G.TC.LINKS.has(pr[0]):
			slot = G.TC.LINKS[pr[0]].a if pr[1] == "a" else G.TC.LINKS[pr[0]].b
	var rows = []
	for pid in s.players:
		var p = s.players[pid]
		if p.club == uc.id or p.has("pre"):
			continue
		if p.pos != b.pos and not (b.pos in p.alt):
			continue
		if G.age(p) > AGES[b.age]:
			continue
		if p.club >= 0 and s.leagues[s.clubs[p.club].lg].get("roe", false):
			continue
		if int(b.foot) == 1 and str(p.foot) != "L" or int(b.foot) == 2 and str(p.foot) == "L":
			continue
		var price = G.TR.asking_price(p) if p.club >= 0 else 0
		if price > max_fee:
			continue
		if p.ovr > uc.rep + 8 or not G.TR.willing(p).ok:
			continue
		var fit = G.TC.best_fit_role(p, b.pos, st) != ""
		if b.style and not fit:
			continue
		if slot != null and not G.TC.fits_slot(slot, p):
			continue
		var sc = p.ovr * 1.0 + (p.pot - p.ovr) * (0.5 if G.age(p) <= 23 else 0.15) + (2.0 if fit else 0.0) - float(price) / max(1.0, float(uc.budget)) * 4.0 + (1.5 if p.listed or p.club < 0 else 0.0)
		rows.append([sc, pid])
	rows.sort_custom(func(x, y): return x[0] > y[0])
	var ids = []
	for i in min(10, rows.size()):
		ids.append(rows[i][1])
		if i < 5:
			s.scout.known[rows[i][1]] = true
	s.scout["brief_res"] = {"day": s.day, "ids": ids, "text": brief_text(b)}
	s.scout.erase("brief")
	if ids.is_empty():
		G.msg("Recruitment brief: nobody found", "Your chief scout could not find anyone who meets the brief (%s) and would come. Loosen it and send him out again." % brief_text(b), "info", null, true)
	else:
		var names = []
		for i in min(3, ids.size()):
			names.append("%s (%d)" % [G.pname(s.players[ids[i]]), s.players[ids[i]].ovr])
		G.msg("Recruitment brief: %d names" % ids.size(), "Your chief scout is back with a shortlist for the brief: %s.\n\nTop of his list: %s. The first five have been watched closely, so you know their potential and what they would want.\n\nThe full list is under Scouting." % [brief_text(b), ", ".join(names)], "info", null, true)


# ---------------------------------------------------------------- deadline day

static func is_deadline() -> bool:
	return G.cur.day == 31 and (G.cur.month == 8 or G.cur.month == 1)


static func dd() -> Dictionary:
	var s = G.s
	if not s.has("dd") or int(s.dd.get("day", -1)) != s.day:
		return {}
	return s.dd


static func dd_start():
	G.s["dd"] = {"day": G.s.day, "hour": 9, "left": 30, "feed": [], "deals": 0, "big": 0, "big_txt": ""}
	_dd_say("09:00", "The window closes at 23:00. Phones are ringing in every boardroom.", "info")


static func _dd_say(clock: String, text: String, kind: String):
	G.s.dd.feed.push_front([clock, text, kind])


static func dd_finish_quietly():
	# the user slept through deadline day: the rest of the world's business still happens
	var s = G.s
	if not s.has("dd"):
		return
	for i in int(s.dd.get("left", 0)):
		G.TR.ai_deal()
	s.erase("dd")


static func dd_hour() -> bool:
	# one hour of deadline day; returns false once the window has shut
	var s = G.s
	var d = dd()
	if d.is_empty() or int(d.hour) >= 23:
		return false
	var uc = G.uc()
	var rng = G.rng
	d.hour = int(d.hour) + 1
	var clock = "%02d:00" % d.hour
	var late = int(d.hour) >= 20
	var n = min(int(d.left), 3 if late else 2)
	for i in n:
		var before = s.tx_log.size()
		var top = s.tx_log[0] if before > 0 else null
		G.TR.ai_deal()
		d.left = int(d.left) - 1
		if s.tx_log.size() > 0 and not is_same(s.tx_log[0], top):
			var x = s.tx_log[0]
			d.deals = int(d.deals) + 1
			if int(x.fee) > int(d.big):
				d.big = int(x.fee)
				d.big_txt = "%s to %s for %s" % [x.name, x.to, G.money(x.fee)]
			_dd_say("%02d:%02d" % [d.hour - 1, rng.randi_range(5, 55)], "DONE DEAL: %s joins %s from %s for %s." % [x.name, x.to, x.from, G.money(x.fee)], "deal")
	var r = rng.randf()
	if r < 0.14:
		# a late bid for one of the user's players
		var cands = []
		for pid in uc.players:
			var p = s.players[pid]
			if p.get("loan", -1) < 0 and not p.get("youth", false) and not G.TR.has_offer(pid) and p.ovr >= uc.rep - 8:
				cands.append(p)
		if cands.size() > 0:
			var p = cands[rng.randi() % cands.size()]
			var n0 = s.offers.size()
			G.TR.make_offer(p)
			if s.offers.size() > n0:
				s.offers[-1].exp = s.day
				_dd_say(clock, "LATE BID: %s have offered %s for your player %s. It lapses at the deadline." % [s.clubs[s.offers[-1].from].name, G.money(s.offers[-1].fee), G.pname(p)], "you")
	elif r < 0.26:
		if agent_offer(true):
			_dd_say(clock, "An agent is on the phone: his client is available at a cut price if you move now. Check your inbox.", "you")
	elif r < 0.36 and late:
		_dd_say(clock, "A club's fax machine is said to have jammed. A deal is in the balance.", "info")
	elif r < 0.46:
		_dd_say(clock, ["Helicopters reported over three training grounds.", "A striker has been seen at an airport with his agent.", "One chairman has turned his phone off. Nobody knows why.", "A medical is under way behind closed doors.", "A manager has walked out of a press conference to take a call."][rng.randi() % 5], "info")
	# the user's own deals
	for dl in G.DL.active():
		if dl.mode == "buy" and dl.stage == "meet":
			G.DL._meeting(dl)
			_dd_say(clock, "%s's agent has brought him straight over to talk terms with you tonight." % G.pname(s.players[dl.pid]), "you")
	if int(d.hour) >= 23:
		_dd_say("23:00", "THE WINDOW IS SHUT. %d deals were done today.%s" % [d.deals, (" The biggest: %s." % d.big_txt) if int(d.big) > 0 else ""], "end")
		for i in int(d.left):
			G.TR.ai_deal()
		d.left = 0
		return false
	return true


# ---------------------------------------------------------------- daily

static func daily():
	var s = G.s
	var cur = G.cur
	_held_moves()
	if s.scout.has("brief") and s.day >= int(s.scout.brief.done):
		_brief_run()
	if s.has("dd") and int(s.dd.day) < s.day:
		dd_finish_quietly()
	if G.window_open():
		if cur.weekday == 3:
			turn_heads()
		if G.rng.randf() < 0.07 and int(s.get("agent_day", -99)) < s.day - 6:
			if agent_offer():
				s["agent_day"] = s.day
		if cur.day == 2 or cur.day == 16:
			ai_buy_backs()
	if cur.day == 15:
		ai_pre()
	if cur.day == 20:
		loan_check()

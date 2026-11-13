extends RefCounted
# Headless test of the transfer features around the negotiation and of the tactics data.
#   godot --headless --path . -- --mktest

static func ok(name: String, cond: bool, extra = ""):
	print(("  PASS  " if cond else "  FAIL  ") + name + ((" · " + str(extra)) if str(extra) != "" else ""))


static func run(_node: Node):
	G.new_game("Tester", 1)
	var s = G.s
	var c = G.uc()
	c.budget = 300000000
	c.wage_budget *= 3
	print("club ", c.name, " style ", G.TC.STYLES[G.TC.style_of(c)].n, " prof ", s.user.prof)
	# ---- tactics data
	var with_sk = 0
	var tot_sk = 0
	for pid in s.players:
		var n = s.players[pid].get("sk", []).size()
		tot_sk += n
		with_sk += 1 if n > 0 else 0
	ok("skills generated", with_sk > 1000, "%d players have skills, %d in total" % [with_sk, tot_sk])
	var star = s.players[c.xi[9]]
	print("    ", G.pname(star), " skills: ", G.TC.skill_names(star), " learnable: ", G.TC.learnable(star).size())
	s.user.links = []
	for id in G.TC.LINK_ORDER:
		if not G.TC.user_pair(id, c).is_empty():
			s.user.links.append(id)
	ok("link-ups found for XI", s.user.links.size() > 0, s.user.links)
	ok("style fit number", G.TC.style_fit(c) > 0, G.TC.style_fit(c))
	G.TC.set_style(c, 2)
	ok("style switch applies defaults", c.instr.counter == true and c.instr["pass"] == 2)
	c.pins[9] = "ct"
	var f0 = G.next_user_fixture()
	var sim = G.new_sim(f0, false)
	sim.run_to_end()
	ok("match runs with pins and links", sim.phase == 4, "%d-%d, link goals %d, active links %d" % [sim.sd[0].goals, sim.sd[1].goals, sim.sd[0].tc.link_goals + sim.sd[1].tc.link_goals, sim.sd[0].tc.links.size()])
	# ---- two-day deal with swap
	var seller = s.clubs[2]
	var tp = s.players[seller.players[7]]
	var d = G.DL.start(tp, "buy")
	var txt = G.DL.enquire(d)
	ok("enquiry answered on the spot", d.stage == "club" and d.ask > 0, G.money(d.ask))
	var low = G.DL.submit_bid(d, int(d.ask * 0.5), 0, 0, 0)
	ok("low bid costs patience", low.res == "reject" and d.pat < 100.0, "patience %d" % int(d.pat))
	var mid = G.DL.submit_bid(d, int(d.ask * 0.85), 0, 0, 0)
	ok("near bid is countered", mid.res == "counter" and d.counter.has("fee"), mid.text.substr(0, 60))
	var swp = c.players[c.players.size() - 1]
	var good = G.DL.submit_bid(d, int(d.ask), 0, 0, 0, -1, false)
	ok("asking price accepted, meeting tomorrow", good.res == "accept" and d.stage == "meet" and d.meet == s.day + 1)
	s.day += 1
	G.DL.tick()
	ok("player arrives on day two", d.stage == "talks")
	var t = G.DL.default_terms(d)
	var dm = G.DL.demand(d, t)
	t.wage = dm.wage
	t.sign = dm.sign
	t.agent = dm.agent
	t.bon = 3
	var r = G.DL.offer_terms(d, t)
	ok("terms accepted with bonuses", r.res == "accept" and tp.club == c.id and tp.has("bon"), tp.get("bon", {}))
	ok("wants list built", typeof(dm.want) == TYPE_ARRAY, dm.want.size())
	# ---- final offer and delegate
	var tp2 = s.players[s.clubs[3].players[9]]
	var d2 = G.DL.start(tp2, "buy")
	G.DL.enquire(d2)
	var fin = G.DL.submit_bid(d2, int(d2.ask * 0.4), 0, 0, 0, -1, true)
	ok("refused final offer ends talks", fin.res == "dead" and d2.stage == "dead" and d2.block > s.day)
	var tp3 = s.players[s.clubs[4].players[9]]
	var d3 = G.DL.start(tp3, "buy")
	G.DL.enquire(d3)
	G.DL.delegate(d3, int(d3.ask * 1.2))
	s.day += 1
	G.DL.tick()
	ok("assistant agrees a fee overnight", d3.stage == "meet" and d3.fee > 0, G.money(d3.fee))
	# ---- swap
	var tp4 = s.players[s.clubs[5].players[6]]
	var d4 = G.DL.start(tp4, "buy")
	G.DL.enquire(d4)
	var q = null
	for pid in c.players:
		if G.DL.swap_ok(d4, s.players[pid]) == "" and not (pid in c.xi):
			q = s.players[pid]
			break
	if q != null:
		var sv = G.DL.swap_value(d4, q)
		var rs = G.DL.submit_bid(d4, max(0, int(d4.ask - sv)), 0, 0, 0, q.id, false)
		ok("swap counted towards the price", rs.res == "accept", "%s worth %s to them" % [G.pname(q), G.money(int(sv))])
		d4.stage = "talks"
		var t4 = G.DL.default_terms(d4)
		var dm4 = G.DL.demand(d4, t4)
		t4.wage = dm4.wage
		t4.sign = dm4.sign
		t4.agent = dm4.agent
		t4.role = dm4.role
		var r4 = G.DL.offer_terms(d4, t4)
		ok("swap player leaves on completion", r4.res == "accept" and q.club == 5 and tp4.club == c.id, r4.res)
	# ---- loans
	var lp = null
	for pid in s.clubs[6].players:
		var p = s.players[pid]
		if G.age(p) <= 21 and G.MK.loan_view(p).ok and not G.MK.loan_view(p).core:
			lp = p
			break
	if lp != null:
		var l1 = G.MK.loan_offer(lp, 0, 0, 0, false)
		ok("young loan needs a promise or full wages", not l1.ok, l1.text.substr(0, 50))
		var l2 = G.MK.loan_offer(lp, 1, 1, G.nice(G.value(lp) * 1.2), true)
		ok("loan with option agreed", l2.ok and lp.club == c.id and lp.has("lterms") and lp.lw == 0.75)
	var out = s.players[c.players[c.players.size() - 2]]
	var e = G.MK.loan_out(out, 0, true)
	ok("loan out with recall", e == "" and out.get("loan", -1) == c.id and G.MK.loan_wages(c) > 0, e)
	# ---- brief, agent, heads
	G.MK.brief_start({"pos": "CB", "age": 1, "fee": 3, "foot": 0, "style": false, "link": ""})
	s.scout.brief.done = s.day
	G.MK.daily()
	ok("recruitment brief returns names", s.scout.has("brief_res") and s.scout.brief_res.ids.size() > 0, s.scout.get("brief_res", {}).get("ids", []).size())
	ok("agent offers a player", G.MK.agent_offer())
	# ---- sale clauses
	var yp = null
	for pid in c.players:
		if G.age(s.players[pid]) <= 23 and not (pid in c.xi) and s.players[pid].get("loan", -1) < 0:
			yp = s.players[pid]
			break
	if yp != null:
		var o = {"id": 777, "pid": yp.id, "from": 8, "fee": G.nice(G.value(yp) * 1.3), "exp": s.day + 5, "haggled": false, "clause": 1}
		s.offers.append(o)
		s.clubs[8].budget = max(s.clubs[8].budget, o.fee * 2)
		G.TR.accept_offer(o)
		ok("buy-back kept on sale", yp.club == 8 and G.MK.can_buy_back(yp), G.money(int(yp.get("bb", {"fee": 0}).fee)))
	# ---- deadline day
	s.day = G.ymd(s.season, 8, 30)
	G.start_of_day()
	s.day += 1
	G.start_of_day()
	ok("deadline day starts", not G.MK.dd().is_empty() and G.MK.is_deadline())
	var hours = 0
	while G.MK.dd_hour():
		hours += 1
	ok("deadline day runs to 23:00", int(s.dd.hour) == 23, "%d deals, %d feed lines" % [int(s.dd.deals), s.dd.feed.size()])
	# ---- pre-contract
	s.day = G.ymd(s.season + 1, 1, 10)
	G.set_date()
	var pp = null
	for cl in s.clubs:
		if cl.id == c.id:
			continue
		for pid in cl.players:
			var p = s.players[pid]
			if p.cend <= s.season + 1 and G.MK.can_pre(p).ok and p.ovr >= 70:
				pp = p
				break
		if pp != null:
			break
	if pp != null:
		var d5 = G.DL.start(pp, "pre")
		var t5 = G.DL.default_terms(d5)
		var dm5 = G.DL.demand(d5, t5)
		t5.wage = dm5.wage
		t5.sign = dm5.sign
		t5.agent = dm5.agent
		t5.role = dm5.role
		t5.rc = G.nice(G.value(pp) * 2.0)
		var r5 = G.DL.offer_terms(d5, t5)
		ok("pre-contract signed, player stays for now", r5.res == "accept" and pp.has("prec") and pp.club != c.id, r5.text.substr(0, 60))
		var old = pp.club
		G.s.season += 1
		G.MK.fulfil_pre(pp)
		G.s.season -= 1
		ok("pre-contract player joins in the summer", pp.club == c.id and old != c.id)
	else:
		ok("found a pre-contract target", false)
	print("mktest done")

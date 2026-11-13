extends RefCounted
# How much do tactics matter? Plays the same fixture many times under different set-ups.
#   godot --headless --path . -- --tactest [n=400]

static func xi_ovr(cid: int) -> float:
	var c = G.s.clubs[cid]
	var xi = c.xi if cid == G.s.user.club else G.pick_xi(c, G.FORMATIONS[c.formation]).xi
	var t = 0.0
	for pid in xi:
		t += G.s.players[pid].ovr
	return t / 11.0


static func series(opp: int, n: int) -> Array:
	# -> [win%, draw%, loss%, points per game, goals for, goals against]
	var me = G.s.user.club
	var w = 0
	var d = 0
	var gf = 0
	var ga = 0
	var cond = {}
	for pid in G.s.players:
		cond[pid] = G.s.players[pid].cond
	for i in n:
		var home = i % 2 == 0
		var f = {"h": me if home else opp, "a": opp if home else me, "ko": false, "d": G.s.day, "comp": "L"}
		var sim = G.new_sim(f, false)
		sim.sd[0].auto = true
		sim.sd[1].auto = true
		sim.run_to_end()
		var mine = sim.sd[0 if home else 1].goals
		var theirs = sim.sd[1 if home else 0].goals
		gf += mine
		ga += theirs
		if mine > theirs:
			w += 1
		elif mine == theirs:
			d += 1
		for pid in cond:
			G.s.players[pid].cond = cond[pid]
	return [100.0 * w / n, 100.0 * d / n, 100.0 * (n - w - d) / n, (3.0 * w + d) / n, float(gf) / n, float(ga) / n]


static func show(label: String, r: Array):
	print("%-46s W %4.1f%%  D %4.1f%%  L %4.1f%%   %.2f pts/game   %.2f-%.2f" % [label, r[0], r[1], r[2], r[3], r[4], r[5]])


static func run(_node: Node):
	var n = 400
	for a in OS.get_cmdline_user_args():
		if a.begins_with("n="):
			n = int(a.substr(2))
	G.new_game("Tester", 1)
	var s = G.s
	# take charge of a mid-table side in the same league
	var lg = s.clubs[1].lg
	var ids = []
	for cid in s.clubs.size():
		if s.clubs[cid].lg == lg:
			ids.append(cid)
	ids.sort_custom(func(a, b): return xi_ovr(a) > xi_ovr(b))
	var me = ids[ids.size() / 2]
	G.new_game("Tester", me)
	s = G.s
	var c = G.uc()
	G.fix_lineup()
	var strong = ids[0]
	var weak = ids[-1]
	var equal = ids[ids.size() / 2 + 1]
	print("You: %s (XI %.1f)  equal: %s (%.1f)  strong: %s (%.1f)  weak: %s (%.1f)   %d matches each, half home half away" % [c.name, xi_ovr(me), s.clubs[equal].name, xi_ovr(equal), s.clubs[strong].name, xi_ovr(strong), s.clubs[weak].name, xi_ovr(weak), n])
	var base = {"xi": c.xi.duplicate(), "roles": c.roles.duplicate(), "instr": c.instr.duplicate(), "ment": c.ment, "press": c.press, "tempo": c.tempo, "pstyle": c.get("pstyle", 0), "prof": s.user.prof.duplicate(), "links": s.user.get("links", []).duplicate()}
	var fam0 = {}
	for pid in c.players:
		fam0[pid] = s.players[pid].get("fam", 50.0)
	var reset = func():
		c.xi = base.xi.duplicate()
		c.roles = base.roles.duplicate()
		c.instr = base.instr.duplicate()
		c.ment = base.ment
		c.press = base.press
		c.tempo = base.tempo
		c["pstyle"] = base.pstyle
		s.user.prof = base.prof.duplicate()
		s.user["links"] = base.links.duplicate()
		for pid in fam0:
			s.players[pid]["fam"] = fam0[pid]
	print("\n--- 1. Squad strength: default tactics against three opponents")
	show("vs equal side", series(equal, n))
	show("vs the strongest side", series(strong, n))
	show("vs the weakest side", series(weak, n))
	print("\n--- 2. Against the EQUAL side: what your choices do")
	show("default set-up", series(equal, n))
	for st in 5:
		reset.call()
		G.TC.set_style(c, st)
		s.user.prof[st] = 50.0
		show("playstyle: %s (average at it)" % G.TC.STYLES[st].n, series(equal, n))
	reset.call()
	s.user.prof[base.pstyle] = 95.0
	for pid in fam0:
		s.players[pid]["fam"] = 100.0
	show("mastered style, squad fully settled", series(equal, n))
	reset.call()
	s.user.prof[base.pstyle] = 20.0
	for pid in fam0:
		s.players[pid]["fam"] = 20.0
	show("style you are poor at, squad unsettled", series(equal, n))
	reset.call()
	c.ment = 4
	show("all-out attack", series(equal, n))
	reset.call()
	c.ment = 0
	show("park the bus", series(equal, n))
	reset.call()
	for k in 11:
		var worst_r = c.roles[k]
		var ws = 9.0
		for rid in G.RL.BY_POS[c.slots[k][0]]:
			var sv = G.RL.suit(s.players[c.xi[k]], rid)
			if sv < ws:
				ws = sv
				worst_r = rid
		c.roles[k] = worst_r
	show("every player in the role that suits him least", series(equal, n))
	reset.call()
	var x = c.xi.duplicate()
	for k in range(1, 6):
		var t = x[k]
		x[k] = x[11 - k]
		x[11 - k] = t
	c.xi = x
	show("defenders and attackers swapped over", series(equal, n))
	reset.call()
	var all_links = []
	for id in G.TC.LINK_ORDER:
		if not G.TC.user_pair(id, c).is_empty():
			all_links.append(id)
	s.user["links"] = []
	show("no link-up plays", series(equal, n))
	s.user["links"] = all_links.slice(0, 2)
	show("two link-up plays active %s" % str(all_links.slice(0, 2)), series(equal, n))
	reset.call()
	print("\n--- 2b. Style against style at equal strength (you good at each, 75): rows you, columns them")
	var oc = s.clubs[equal]
	var native = oc.get("pstyle", null)
	var grid = "%-20s" % ""
	for st in 5:
		grid += "%8s" % G.TC.STYLES[st].s
	print(grid)
	var best = [-1.0, 0, 0]
	var worst = [9.0, 0, 0]
	for mine in 5:
		var line = "%-20s" % G.TC.STYLES[mine].n
		for theirs in 5:
			reset.call()
			G.TC.set_style(c, mine)
			s.user.prof[mine] = 75.0
			oc["pstyle"] = theirs
			var r = series(equal, int(n / 2))
			line += "%8.2f" % r[3]
			if r[3] > best[0]:
				best = [r[3], mine, theirs]
			if r[3] < worst[0]:
				worst = [r[3], mine, theirs]
		print(line)
	print("best plan %.2f pts/game, worst %.2f: over 38 games that is %.0f points" % [best[0], worst[0], (best[0] - worst[0]) * 38])
	if native == null:
		oc.erase("pstyle")
	else:
		oc["pstyle"] = native
	reset.call()
	print("\n--- 2c. Notes the scout report would show for your default set-up against the equal side")
	var mu = G.TC.matchup(G.TC.side_view(G.lineup(me, equal)), G.TC.side_view(G.lineup(equal, me)))
	for nt in mu.notes:
		print("   %+.3f  %s" % [nt[0], nt[1]])
	print("\n--- 3. Underdog: best and worst plan against the STRONGEST side")
	show("default set-up", series(strong, n))
	for st in 5:
		reset.call()
		G.TC.set_style(c, st)
		s.user.prof[st] = 80.0
		show("playstyle: %s (good at it)" % G.TC.STYLES[st].n, series(strong, n))
	reset.call()
	c.ment = 0
	show("park the bus", series(strong, n))
	reset.call()
	c.ment = 4
	show("all-out attack", series(strong, n))
	reset.call()
	var sc = s.clubs[strong]
	var sn = sc.get("pstyle", null)
	print("\n--- 3b. Underdog, each style against each style the strongest side might use")
	var gb = [-1.0, 0, 0]
	for theirs in 5:
		var line = "they play %-18s" % G.TC.STYLES[theirs].n
		for mine in 5:
			reset.call()
			G.TC.set_style(c, mine)
			s.user.prof[mine] = 80.0
			sc["pstyle"] = theirs
			var r = series(strong, int(n / 2))
			line += "  %s %4.1f%%" % [G.TC.STYLES[mine].s, r[0]]
		print(line)
	if sn == null:
		sc.erase("pstyle")
	else:
		sc["pstyle"] = sn
	reset.call()
	print("\n--- 4. Cup tie: best second-tier side at home to top-tier sides")
	var low = -1
	var lb = 0.0
	for cid in s.clubs.size():
		var l2 = s.leagues[s.clubs[cid].lg]
		if l2.country == s.leagues[lg].country and l2.tier == 2 and xi_ovr(cid) > lb:
			lb = xi_ovr(cid)
			low = cid
	if low >= 0:
		for top in [ids[0], ids[ids.size() / 2], ids[-1]]:
			var w = 0
			var dr = 0
			for i in n:
				var sim = G.new_sim({"h": low, "a": top, "ko": true, "d": s.day, "comp": "cup"}, false)
				sim.sd[0].auto = true
				sim.sd[1].auto = true
				sim.run_to_end()
				if sim.winner() == 0:
					w += 1
			print("%s (XI %.1f) at home to %s (XI %.1f): goes through %.1f%%" % [s.clubs[low].name, lb, s.clubs[top].name, xi_ovr(top), 100.0 * w / n])

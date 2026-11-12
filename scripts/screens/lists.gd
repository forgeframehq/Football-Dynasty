extends "res://scripts/screens/screen.gd"
# Ready-made player lists: medical centre, contracts, top players, smart searches.

const TITLES = {"medical": "Medical Centre", "contracts": "Contracts", "top50": "Top 50 Players", "wonderkids": "Wonderkids",
	"bargains": "Bargains", "expiring": "Expiring Contracts", "free": "Free Agents", "listed": "Transfer Listed", "similar": "Similar Players", "role": "Role Finder", "pos": "Best Available"}


func build():
	var s = G.s
	var c = G.uc()
	var kind = str(args.get("kind", "top50"))
	var rows: Array = []
	var note = ""
	if kind == "medical":
		for pid in c.players:
			var p = s.players[pid]
			if p.inj > 0:
				rows.append([p, "Injured · back in %s" % G.inj_text(p.inj), 1000 + p.inj])
			elif p.susp > 0:
				rows.append([p, "Suspended · %d match%s" % [p.susp, "" if p.susp == 1 else "es"], 500 + p.susp])
			elif p.cond < 70:
				rows.append([p, "Tired · condition %d%%" % int(p.cond), 100 - p.cond])
		rows.sort_custom(func(a, b): return a[2] > b[2])
		note = "Medical centre level %d. %s" % [G.OPS.lvl("medical"), G.OPS.effect_text("medical", G.OPS.lvl("medical"))]
		if rows.is_empty():
			note += "\n\nEveryone is fit and available."
	elif kind == "contracts":
		for pid in c.players:
			var p = s.players[pid]
			if p.get("loan", -1) >= 0 and p.get("loan", -1) != c.id:
				continue
			var left = p.cend - s.season - 1
			rows.append([p, "%s / wk · until June %d%s" % [G.money(p.wage), p.cend, " · expiring" if left <= 0 else ""], -p.cend * 100 + p.ovr])
		rows.sort_custom(func(a, b): return a[2] > b[2])
		note = "Wage bill %s a week of a %s budget. Tap a player to offer a new contract." % [G.money(G.squad_wages(c)), G.money(c.wage_budget)]
	else:
		var budget = c.budget
		for p in s.players.values():
			var sc_ = 0.0
			var extra = ""
			var cl = s.clubs[p.club].name if p.club >= 0 else "Free agent"
			if kind == "top50":
				if p.club < 0: continue
				sc_ = p.ovr * 100 - G.age(p)
				extra = "%s · %d yrs · %s" % [cl, G.age(p), G.money(G.value(p))]
			elif kind == "wonderkids":
				if p.club < 0 or G.age(p) > 21: continue
				sc_ = p.ovr * 100 - G.age(p) * 30
				extra = "%s · %d yrs · %s" % [cl, G.age(p), G.money(G.value(p))]
			elif kind == "free":
				if p.club >= 0: continue
				sc_ = p.ovr
				extra = "%d yrs · wants about %s / wk" % [G.age(p), G.money(G.wage_for(p.ovr, G.age(p)))]
			elif kind == "listed":
				if p.club < 0 or p.club == c.id or not p.listed: continue
				sc_ = p.ovr
				extra = "%s · %d yrs · %s" % [cl, G.age(p), G.money(G.value(p))]
			elif kind == "expiring":
				if p.club < 0 or p.club == c.id or p.cend > s.season + 1: continue
				sc_ = p.ovr
				extra = "%s · %d yrs · contract ends June %d" % [cl, G.age(p), p.cend]
			elif kind == "similar":
				var q = s.players[args.pid]
				if p.id == q.id or p.club == c.id or p.pos != q.pos or absi(p.ovr - q.ovr) > 4: continue
				if p.club >= 0 and s.leagues[s.clubs[p.club].lg].roe: continue
				sc_ = 100.0 - absi(p.ovr - q.ovr) * 6.0 - maxf(0.0, G.age(p) - G.age(q)) * 2.0 - float(G.value(p)) / maxf(1.0, G.value(q)) * 10.0
				extra = "%s · %d yrs · %s" % [cl, G.age(p), G.money(G.value(p))]
			elif kind == "role" or kind == "pos":
				if p.club == c.id or G.fit(p, args.pos) < 0.9: continue
				if p.club >= 0 and (s.leagues[s.clubs[p.club].lg].roe or G.value(p) > budget): continue
				sc_ = G.RL.score(p, args.rid) if kind == "role" else float(p.ovr)
				extra = "%s · %d yrs · %s" % [cl, G.age(p), G.money(G.value(p))]
			elif kind == "bargains":
				if p.club < 0 or p.club == c.id or s.leagues[s.clubs[p.club].lg].roe: continue
				var val = G.value(p)
				if val > budget or p.ovr < 60: continue
				sc_ = p.ovr * 3.0 - G.age(p) - float(val) / max(1.0, budget) * 12.0 + (6.0 if p.listed else 0.0)
				extra = "%s · %d yrs · %s%s" % [cl, G.age(p), G.money(val), " · listed" if p.listed else ""]
			rows.append([p, extra, sc_])
		rows.sort_custom(func(a, b): return a[2] > b[2])
		if rows.size() > (50 if kind in ["top50", "wonderkids"] else 60):
			rows.resize(50 if kind in ["top50", "wonderkids"] else 60)
		if kind == "bargains":
			note = "The best players your %s budget can buy, weighted towards younger and cheaper." % G.money(budget)
	if kind == "similar":
		note = "Players like %s: same position, close in ability, ranked towards younger and cheaper." % G.pname(s.players[args.pid])
	elif kind == "role":
		note = "Best affordable players for the %s role at %s." % [G.RL.ROLES[args.rid].n, args.pos]
	elif kind == "pos":
		note = "Best affordable players who can play %s." % args.pos
	body.add_child(UI.topbar(TITLES.get(kind, "Players"), true, UI.chip("%d PLAYERS" % rows.size(), Color(1, 1, 1, 0.06), UI.MUTED, 18)))
	var v = content(8)
	if note != "":
		var nc = UI.card(18, 14)
		nc.set_meta("span", true)
		nc.add_child(UI.wrap(note, 21, UI.MUTED))
		v.add_child(nc)
	var i = 0
	for r in rows:
		i += 1
		var pid = r[0].id
		var extra = r[1]
		if kind in ["top50", "wonderkids"]:
			extra = "#%d · %s" % [i, extra]
		v.add_child(UI.player_row(r[0], func(): UI.main.open("player", {"pid": pid}), extra))

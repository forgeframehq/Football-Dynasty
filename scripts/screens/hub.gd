extends "res://scripts/screens/screen.gd"
# Menu pages that are mostly information: dressing room, fans, sponsors, board requests,
# transfer centre, awards, live scores, league standards, career timeline, achievements and more.

const TITLES = {"dressing": "Dressing Room", "fans": "Fans", "sponsors": "Sponsors", "request": "Board Request", "report": "Team Report",
	"tcentre": "Transfer Centre", "awards": "Awards", "scores": "Live Scores", "standards": "League Standards", "timeline": "Career Timeline",
	"philosophy": "Philosophy", "status": "Game Status", "manual": "Manual", "achieve": "Achievements", "fame": "Hall of Fame",
	"editor": "Editor", "findclub": "Find Club", "rolefinder": "Role Finder", "identity": "Club Identity", "analysis": "Match Analysis", "life": "Lifestyle", "contract": "My Contract"}
const HOMES = [["Club flat", 0, "A small flat the club lends you."], ["City apartment", 180000, "Two bedrooms near the ground."], ["Riverside penthouse", 900000, "Top floor, skyline views."],
	["Country villa", 3500000, "Gardens, a pool and privacy."], ["Mansion estate", 12000000, "The home of a football great."]]
const CARS = [["Club car", 0], ["Executive saloon", 45000], ["Sports coupe", 160000], ["Supercar", 600000], ["Classic collection", 2500000]]
const BIZ = [["Local restaurant", 250000, 1800], ["Football academy school", 1200000, 9500], ["Boutique hotel", 5000000, 42000]]
const LANG = {"England": "English", "Spain": "Spanish", "Italy": "Italian", "Germany": "German", "France": "French"}
const SPONSORS = [["AeroNova", "Airline"], ["SkyLink", "Airline"], ["Horizon Trust", "Bank"], ["Pinnacle Bank", "Bank"], ["NovaCore", "Tech"], ["PulseDyn", "Tech"],
	["HelixSys", "Tech"], ["Apex Motors", "Car maker"], ["TurboForge", "Car maker"], ["WaveConnect", "Telecom"], ["SignalPulse", "Telecom"], ["LuminaVolt", "Energy"],
	["TerraSpark", "Energy"], ["FizzVital", "Drinks"], ["AquaBoost", "Drinks"], ["AegisGuard", "Insurance"]]
const DNA = [["Balanced", "", "No bonus, no extra demands."], ["Total Football", "tac", "Tactical knowledge +2. The board expects attacking play."],
	["Iron Discipline", "mot", "Motivation +2. Players respond to firm team talks."], ["Home Grown", "you", "Youth development +2. The board wants academy players used."],
	["Moneyball", "neg", "Negotiation +2. Buy low, sell high."]]

var q := ""


func build():
	var kind = str(args.get("kind", "status"))
	body.add_child(UI.topbar(TITLES.get(kind, "Club")))
	if kind in ["manual", "request", "philosophy", "editor", "status"]:
		max_w = 900
		cols = 1
	if kind == "dressing":
		backdrop("dressing_room", 0.78)
	elif kind == "request":
		backdrop("boardroom", 0.8)
	var v = content(10)
	call("_" + kind, v)


func _card(v: Control, title := "") -> VBoxContainer:
	var c = UI.card(18, 14)
	var cv = UI.vb(7)
	if title != "":
		cv.add_child(UI.caps(title, 19, UI.accent))
	c.add_child(cv)
	v.add_child(c)
	return cv


func _prow(p: Dictionary, right: String, col := UI.MUTED) -> Control:
	var r = UI.hb(10)
	r.add_child(UI.pos(p.pos, 17))
	r.add_child(UI.lbl_fill(G.pname(p), 21, UI.TEXT, "semi"))
	r.add_child(UI.lbl(right, 19, col, "disp"))
	r.add_child(UI.ovr(p.ovr, 18))
	var pid = p.id
	UI.tap(r, func(): UI.main.open("player", {"pid": pid}))
	return r


func _note(v: Control, text: String):
	var n = UI.card(18, 12)
	n.set_meta("span", true)
	n.add_child(UI.wrap(text, 20, UI.MUTED))
	v.add_child(n)


# ---------------------------------------------------------------- club

func _dressing(v: Control):
	var s = G.s
	var c = G.uc()
	var groups = [[], [], [], []]
	var tot = 0.0
	var n = 0
	for pid in c.players:
		var p = s.players[pid]
		if p.get("youth", false):
			continue
		groups[G.status_of(p)].append(p)
		tot += p.mor
		n += 1
	var avg = tot / max(1, n)
	var capt = s.players.get(c.get("capt", -1))
	_note(v, "Squad morale is %s (%d). %s" % ["excellent" if avg >= 75 else ("good" if avg >= 60 else ("mixed" if avg >= 45 else "poor")), int(avg),
		("%s leads the dressing room as captain." % G.pname(capt)) if capt != null else "Nobody wears the armband yet; pick a captain in Tactics."])
	for i in 4:
		groups[i].sort_custom(func(a, b): return a.ovr > b.ovr)
		var cv = _card(v, ["Team leaders", "Regulars", "Squad players", "Prospects"][i])
		for p in groups[i]:
			var txt = "unhappy" if p.get("unhappy", 0) > 0 else str(int(p.mor))
			cv.add_child(_prow(p, txt, UI.cond_color(p.mor + 10)))
		if groups[i].is_empty():
			cv.add_child(UI.lbl("Nobody in this group.", 18, UI.DIM))


func _fans(v: Control):
	var s = G.s
	var c = G.uc()
	var fans = float(s.user.get("fans", 55.0))
	var cv = _card(v, "Supporter confidence")
	var h = UI.hb(12)
	h.add_child(UI.lbl("%d%%" % int(fans), 52, UI.cond_color(fans + 15), "xbold"))
	h.add_child(UI.bar(fans / 100.0, UI.cond_color(fans + 15), 12))
	cv.add_child(h)
	cv.add_child(UI.wrap("The fans are %s. Results against the odds and big wins lift them; flat defeats to weaker sides turn them." % ["singing your name" if fans >= 75 else ("behind you" if fans >= 55 else ("restless" if fans >= 35 else "calling for change"))], 20, UI.MUTED))
	var fill = clamp(0.55 + (c.rep - 55.0) * 0.012 + (0.1 if c.form.count("W") >= 3 else 0.0), 0.35, 0.98)
	var av = _card(v, "Attendance")
	av.add_child(UI.kv("Capacity", G.OPS._thousands(G.OPS.capacity(c))))
	av.add_child(UI.kv("Typical crowd", "%s (%d%% full)" % [G.OPS._thousands(int(G.OPS.capacity(c) * fill)), int(fill * 100)]))
	av.add_child(UI.kv("Last week's gate money", G.money(c.fin.get("tickets", 0)), UI.GREEN))
	av.add_child(UI.wrap("A winning run fills the ground. A bigger stadium only pays once you can fill it.", 18, UI.DIM))
	var ev = _card(v, "What they expect")
	ev.add_child(UI.wrap(s.user.obj.text, 26, UI.TEXT, "disp"))
	ev.add_child(UI.kv("League position", G.LG.ordinal(G.LG.position(c.id))))
	var favs = []
	for pid in c.players:
		if s.players[pid].ss.ap >= 3:
			favs.append(s.players[pid])
	favs.sort_custom(func(a, b): return G.avg_rating(a) + a.ss.g * 0.05 > G.avg_rating(b) + b.ss.g * 0.05)
	var fv = _card(v, "Fan favourites")
	for i in min(5, favs.size()):
		fv.add_child(_prow(favs[i], "%.2f" % G.avg_rating(favs[i])))
	if favs.is_empty():
		fv.add_child(UI.lbl("Favourites emerge once the season is under way.", 18, UI.DIM))


func _offers() -> Array:
	var s = G.s
	var c = G.uc()
	var rng = RandomNumberGenerator.new()
	rng.seed = s.season * 977 + c.id * 13
	var base = c.wage_budget * (0.06 + c.fac.commercial * 0.012)
	var out = []
	var used = []
	for t in [["Guaranteed", 1.0, 0.0], ["Balanced", 0.72, 0.9], ["Win bonus", 0.4, 2.2]]:
		var i = rng.randi() % SPONSORS.size()
		while i in used:
			i = (i + 1) % SPONSORS.size()
		used.append(i)
		out.append({"name": SPONSORS[i][0], "sector": SPONSORS[i][1], "type": t[0], "weekly": G.nice(base * t[1]), "win": G.nice(base * t[2]), "season": s.season})
	return out


func _sponsors(v: Control):
	var s = G.s
	var cur = s.user.get("sponsor")
	_note(v, "Your shirt sponsor pays every week on top of the club's commercial income. A win-bonus deal pays less each week and more when you win. Deals run for one season; a better commercial building brings bigger offers.")
	var cv = _card(v, "Current shirt sponsor")
	if cur != null and cur.season == s.season:
		cv.add_child(UI.lbl(cur.name.to_upper(), 40, UI.TEXT, "xbold"))
		cv.add_child(UI.kv("Sector", cur.sector))
		cv.add_child(UI.kv("Weekly", G.money(cur.weekly), UI.GREEN))
		cv.add_child(UI.kv("Per win", G.money(cur.win), UI.GREEN))
		return
	cv.add_child(UI.wrap("No shirt sponsor signed for this season. Pick one of the offers.", 20, UI.AMBER))
	for o in _offers():
		var c = UI.panel(UI.CARD, 18, 18, 12, UI.LINE)
		var h = UI.hb(12)
		var tv = UI.vb(-2)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UI.caps("%s · %s" % [o.type, o.sector], 16, UI.accent))
		tv.add_child(UI.lbl(o.name.to_upper(), 32, UI.TEXT, "xbold"))
		tv.add_child(UI.lbl("%s a week · %s per win" % [G.money(o.weekly), G.money(o.win)], 19, UI.MUTED))
		h.add_child(tv)
		h.add_child(UI.chip("SIGN", UI.accent, UI.on_color(UI.accent), 20))
		c.add_child(h)
		var deal = o
		UI.tap(c, func():
			s.user["sponsor"] = deal
			UI.sfx("cash", -8.0)
			UI.toast("%s are your new shirt sponsor" % deal.name, UI.GREEN)
			refresh())
		v.add_child(c)


func _request(v: Control):
	var s = G.s
	var c = G.uc()
	var u = s.user
	var wait = int(u.get("req_day", 0)) + 60 - s.day
	_note(v, "Ask the board for backing. They say yes more often when their confidence in you is high (%d%% now). A refusal costs a little goodwill, and you can ask again after 60 days." % int(u.conf))
	if wait > 0:
		v.add_child(UI.wrap("The board will hear another request in %d days." % wait, 22, UI.AMBER))
		return
	var asks = [["More transfer funds", "About %s added to the budget" % G.money(G.nice(c.wage_budget * 6.0)), 52.0, func(): c.budget += G.nice(c.wage_budget * 6.0)],
		["A bigger wage budget", "Raise the weekly wage budget by 8%", 58.0, func(): c.wage_budget = int(c.wage_budget * 1.08)],
		["Pay for a facility upgrade", "The board covers half of your next upgrade", 64.0, func(): c.budget += int(G.OPS.upgrade_cost(c, "training") * 0.5)],
		["More time", "Board confidence is topped up", 40.0, func(): u.conf = min(100.0, u.conf + 8.0)]]
	for a in asks:
		var p = UI.panel(UI.CARD, 18, 18, 12, UI.LINE)
		var h = UI.hb(12)
		var tv = UI.vb(-2)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UI.lbl(a[0], 26, UI.TEXT, "disp"))
		tv.add_child(UI.lbl(a[1], 18, UI.MUTED))
		h.add_child(tv)
		var chance = clamp(0.5 + (u.conf - a[2]) * 0.02, 0.05, 0.95)
		h.add_child(UI.caps("%s chance" % ("good" if chance >= 0.65 else ("fair" if chance >= 0.4 else "slim")), 17, UI.GREEN if chance >= 0.65 else (UI.AMBER if chance >= 0.4 else UI.RED)))
		h.add_child(UI.chip("ASK", UI.accent, UI.on_color(UI.accent), 20))
		p.add_child(h)
		var grant = a[3]
		var title_ = a[0]
		UI.tap(p, func():
			u["req_day"] = s.day
			if G.rng.randf() < chance:
				grant.call()
				UI.sfx("confirm", -8.0)
				G.msg("Board agrees: %s" % title_.to_lower(), "The board has approved your request.", "board")
				UI.toast("The board said yes", UI.GREEN)
			else:
				u.conf = max(0.0, u.conf - 3.0)
				UI.sfx("error", -8.0)
				G.msg("Board refuses: %s" % title_.to_lower(), "The board has turned down your request and expects you to work with what you have.", "board")
				UI.toast("The board said no", UI.RED)
			refresh())
		v.add_child(p)


func _report(v: Control):
	var s = G.s
	var c = G.uc()
	var slots = G.slots_of(c)
	var rows = []
	var tot = 0.0
	for i in 11:
		var pos = slots[i][0]
		var cands = []
		for pid in c.players:
			var p = s.players[pid]
			if not p.get("youth", false) and G.fit(p, pos) >= 0.9:
				cands.append(p)
		cands.sort_custom(func(a, b): return a.ovr > b.ovr)
		var st = s.players[c.xi[i]] if c.xi[i] >= 0 else null
		rows.append({"pos": pos, "st": st, "cover": cands.size(), "ovr": st.ovr if st != null else 0, "slot": i})
		tot += st.ovr if st != null else 0
	var avg = tot / 11.0
	rows.sort_custom(func(a, b): return a.ovr - (0 if a.cover >= 2 else 3) < b.ovr - (0 if b.cover >= 2 else 3))
	var tr = G.team_ratings(c.id)
	_note(v, "Your first XI averages %d (attack %d, midfield %d, defence %d). Weakest positions are listed first; tap Find to see who you could afford there." % [int(avg), tr.att, tr.mid, tr.def])
	for r in rows:
		var p = UI.panel(UI.CARD, 14, 14, 8, Color(UI.RED, 0.5) if r.ovr < avg - 3 or r.cover < 2 else UI.LINE)
		var h = UI.hb(10)
		h.add_child(UI.pos(r.pos, 18))
		var tv = UI.vb(-3)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UI.lbl_fill(G.pname(r.st) if r.st != null else "Nobody", 22, UI.TEXT, "semi"))
		var note = "%d player%s can play here" % [r.cover, "" if r.cover == 1 else "s"]
		if r.ovr < avg - 3:
			note += " · below the team's level"
		if r.cover < 2:
			note += " · thin cover"
		tv.add_child(UI.lbl_fill(note, 16, UI.MUTED))
		h.add_child(tv)
		if r.st != null:
			h.add_child(UI.ovr(r.ovr, 20))
		var fb = UI.chip("FIND", Color(1, 1, 1, 0.08), UI.TEXT, 17)
		var pos = r.pos
		UI.tap(fb, func(): UI.main.open("lists", {"kind": "pos", "pos": pos, "grp": "search"}), true)
		h.add_child(fb)
		p.add_child(h)
		v.add_child(p)


func _identity(v: Control):
	var s = G.s
	var c = G.uc()
	var cv = _card(v, "Colours")
	var h = UI.hb(12)
	h.add_child(UI.badge(c, 84))
	var tv = UI.vb(4)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(UI.lbl(c.name.to_upper(), 30, UI.TEXT, "xbold"))
	tv.add_child(UI.lbl(c.stadium if c.stadium != "" else "Home ground", 18, UI.MUTED))
	h.add_child(tv)
	cv.add_child(h)
	for key in ["c1", "c2"]:
		cv.add_child(UI.caps("Primary colour" if key == "c1" else "Secondary colour", 16, UI.MUTED))
		var sw = HFlowContainer.new()
		sw.add_theme_constant_override("h_separation", 6)
		sw.add_theme_constant_override("v_separation", 6)
		for hex in ["ffffff", "111111", "d0021b", "8b0000", "f5a623", "f8e71c", "1e8e3e", "0b6e4f", "6cabdd", "1f4fbf", "0a1a5c", "6b2fb3", "ff6fb1", "7a4a1e", "9aa3ad", "e9c46a"]:
			var on = str(c[key]).to_lower() == hex
			var chip_ = UI.panel(Color(hex), 8, 0, 0, UI.TEXT if on else Color(1, 1, 1, 0.2))
			chip_.get_theme_stylebox("panel").set_border_width_all(3 if on else 1)
			chip_.custom_minimum_size = Vector2(44, 34)
			var k = key
			var hx = hex
			UI.tap(chip_, func():
				c[k] = hx
				refresh(), true)
			sw.add_child(chip_)
		cv.add_child(sw)
	cv.add_child(UI.wrap("Colours change the shield, the kit in matches and the stadium seats.", 17, UI.DIM))
	var rv = _card(v, "Records under you")
	rv.add_child(UI.kv("Matches", str(s.user.p)))
	rv.add_child(UI.kv("Won / drawn / lost", "%d / %d / %d" % [s.user.w, s.user.d, s.user.l]))
	rv.add_child(UI.kv("Trophies", str(s.user.trophies.size())))
	var best = []
	for pid in c.players:
		best.append(s.players[pid])
	best.sort_custom(func(a, b): return a.get("cg", 0) > b.get("cg", 0))
	var lv = _card(v, "Top scorers in the squad (career)")
	for i in min(5, best.size()):
		lv.add_child(_prow(best[i], "%d goals" % best[i].get("cg", 0)))


func _analysis(v: Control):
	var s = G.s
	var c = G.uc()
	var all = G.club_fixtures(c.id)
	var gf_h = 0
	var ga_h = 0
	var gf_a = 0
	var ga_a = 0
	var n_h = 0
	var n_a = 0
	var cs = 0
	var big = null
	for f in all:
		if not f.played or f.get("fr", false):
			continue
		var home = f.h == c.id
		var us = f.hg if home else f.ag
		var them = f.ag if home else f.hg
		if home:
			gf_h += us
			ga_h += them
			n_h += 1
		else:
			gf_a += us
			ga_a += them
			n_a += 1
		if them == 0:
			cs += 1
		if big == null or us - them > big[0]:
			big = [us - them, "%d-%d %s %s" % [us, them, "v" if home else "at", s.clubs[f.a if home else f.h].name]]
	var n = n_h + n_a
	if n == 0:
		_note(v, "Analysis appears once competitive matches have been played.")
		return
	var a = _card(v, "Season so far")
	a.add_child(UI.kv("Matches", str(n)))
	a.add_child(UI.kv("Goals for / against", "%d / %d" % [gf_h + gf_a, ga_h + ga_a]))
	a.add_child(UI.kv("Per match", "%.2f scored · %.2f conceded" % [float(gf_h + gf_a) / n, float(ga_h + ga_a) / n]))
	a.add_child(UI.kv("Clean sheets", str(cs)))
	if big != null:
		a.add_child(UI.kv("Best result", big[1]))
	var b = _card(v, "Home and away")
	b.add_child(UI.kv("Home", "%d played · %d scored · %d conceded" % [n_h, gf_h, ga_h]))
	b.add_child(UI.kv("Away", "%d played · %d scored · %d conceded" % [n_a, gf_a, ga_a]))
	var sc_ = []
	for pid in c.players:
		if s.players[pid].ss.g + s.players[pid].ss.a > 0:
			sc_.append(s.players[pid])
	sc_.sort_custom(func(x, y): return x.ss.g * 2 + x.ss.a > y.ss.g * 2 + y.ss.a)
	var g = _card(v, "Where the goals come from")
	for i in min(6, sc_.size()):
		g.add_child(_prow(sc_[i], "%d G · %d A" % [sc_[i].ss.g, sc_[i].ss.a]))


# ---------------------------------------------------------------- manager

func _timeline(v: Control):
	var s = G.s
	var c = G.uc()
	var cur = _card(v, "%s · now" % G.season_name())
	cur.add_child(UI.lbl(c.name, 28, UI.TEXT, "disp"))
	cur.add_child(UI.kv(s.leagues[c.lg].name, "%s · %d pts" % [G.LG.ordinal(G.LG.position(c.id)), c.t.pts]))
	for i in range(s.history.size() - 1, -1, -1):
		var hst = s.history[i]
		var cv = _card(v, G.season_name(int(hst.season) - 1))
		cv.add_child(UI.lbl(str(hst.club), 26, UI.TEXT, "disp"))
		cv.add_child(UI.kv(str(hst.lg), "%s · %d pts" % [G.LG.ordinal(int(hst.pos)), int(hst.pts)]))
		cv.add_child(UI.kv("Record", "%dW %dD %dL · %d-%d" % [hst.w, hst.d, hst.l, hst.gf, hst.ga]))
		if str(hst.get("note", "")) != "":
			cv.add_child(UI.lbl(str(hst.note), 19, UI.GOLD, "semi"))
	if s.history.is_empty():
		_note(v, "Your story starts here. Each finished season is added to the timeline.")


func _philosophy(v: Control):
	var u = G.s.user
	var cur = int(u.get("dna", 0))
	_note(v, "A philosophy is the identity you give the club. It adds two points to one of your coaching attributes. You can change it once a season.")
	var locked = int(u.get("dna_season", -1)) == G.s.season
	for i in DNA.size():
		var on = i == cur
		var p = UI.panel(Color(UI.accent, 0.14) if on else UI.CARD, 18, 18, 12, UI.accent if on else UI.LINE)
		var tv = UI.vb(-2)
		tv.add_child(UI.lbl(DNA[i][0], 28, UI.TEXT, "disp"))
		tv.add_child(UI.lbl(DNA[i][2], 18, UI.MUTED))
		p.add_child(tv)
		var idx = i
		UI.tap(p, func():
			if locked and not on:
				UI.toast("You have already changed philosophy this season", UI.AMBER)
				return
			if DNA[cur][1] != "":
				u.attr[DNA[cur][1]] = max(5, u.attr[DNA[cur][1]] - 2)
			if DNA[idx][1] != "":
				u.attr[DNA[idx][1]] = min(22, u.attr[DNA[idx][1]] + 2)
			u["dna"] = idx
			u["dna_season"] = G.s.season
			refresh())
		v.add_child(p)


func _buy(lf: Dictionary, cost: int, what: String, apply: Callable):
	if lf.cash < cost:
		UI.sfx("error", -8.0)
		UI.toast("You need %s; you have %s" % [G.money(cost), G.money(lf.cash)], UI.RED)
		return
	lf.cash -= cost
	apply.call()
	UI.sfx("cash", -8.0)
	UI.toast("Bought: %s" % what, UI.GREEN)
	refresh()


func _life(v: Control):
	var s = G.s
	var u = s.user
	var lf = G.OPS.life()
	var country = s.leagues[G.uc().lg].country
	if lf.country != country:
		lf.country = country
		lf.settled = 10.0
	var net = int(lf.cash)
	for i in lf.home + 1:
		net += HOMES[i][1]
	for i in lf.car + 1:
		net += CARS[i][1]
	_note(v, "Your own money and life away from the pitch. You are paid %s a week. Homes and cars raise your standing in the game; a business pays you every week; learning the language and giving to local causes win over the dressing room and the fans." % G.money(G.OPS.salary()))
	var o = _card(v, "Your money")
	o.add_child(UI.lbl(G.money(lf.cash), 44, UI.GREEN, "xbold"))
	o.add_child(UI.kv("Weekly salary", G.money(G.OPS.salary())))
	o.add_child(UI.kv("Business income", "%s a week" % G.money(lf.income)))
	o.add_child(UI.kv("Net worth", G.money(net)))
	var cc = _card(v, "Life in %s" % country)
	var ch = UI.hb(10)
	ch.add_child(UI.flag(country, 44))
	ch.add_child(UI.lbl_fill("Settled in", 21, UI.MUTED))
	ch.add_child(UI.bar(lf.settled / 100.0, UI.accent, 8))
	ch.add_child(UI.lbl("%d%%" % int(lf.settled), 20, UI.TEXT, "disp"))
	cc.add_child(ch)
	var lang = LANG.get(country, "English")
	var prog = float(lf.lang.get(lang, 100.0 if (lang == "English" and u.nat in ["England", "Scotland", "Wales", "Northern Ireland", "Republic of Ireland", "United States", "Australia", "Canada", "Jamaica"]) or LANG.get(u.nat, "") == lang else 0.0))
	lf.lang[lang] = prog
	cc.add_child(UI.kv(lang, "Fluent" if prog >= 100 else ("%d%% · studying" % int(prog) if lf.study == lang else "%d%%" % int(prog)), UI.GREEN if prog >= 100 else UI.TEXT))
	if prog < 100:
		cc.add_child(UI.btn("Stop lessons" if lf.study == lang else "Take %s lessons (€400 a week)" % lang, func():
			lf.study = "" if lf.study == lang else lang
			refresh(), "secondary", "book-open", 50))
		cc.add_child(UI.wrap("Fluency takes about five months and gives Motivation +1.", 17, UI.DIM))
	cc.add_child(UI.btn("Give €25K to a local cause", func(): _buy(lf, 25000, "a donation the fans noticed", func():
		u["fans"] = min(100.0, float(u.get("fans", 55.0)) + 3.0)), "secondary", "heart", 50))
	var hv = _card(v, "Home")
	for i in HOMES.size():
		var owned = i <= lf.home
		var r = UI.hb(10)
		r.add_child(UI.icon("house", 22, UI.GOLD if i == lf.home else (UI.DIM if owned else UI.MUTED)))
		var tv = UI.vb(-4)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UI.lbl(HOMES[i][0], 21, UI.TEXT if not owned or i == lf.home else UI.DIM, "semi"))
		tv.add_child(UI.lbl_fill(HOMES[i][2], 15, UI.MUTED))
		r.add_child(tv)
		if i == lf.home:
			r.add_child(UI.chip("HOME", Color(UI.GOLD, 0.16), UI.GOLD, 15))
		elif i == lf.home + 1:
			var idx = i
			var b = UI.chip("BUY " + G.money(HOMES[i][1]), UI.accent, UI.on_color(UI.accent), 16)
			UI.tap(b, func(): _buy(lf, HOMES[idx][1], HOMES[idx][0], func():
				lf.home = idx
				u.rep = min(100.0, u.rep + 1.0)), true)
			r.add_child(b)
		elif not owned:
			r.add_child(UI.lbl(G.money(HOMES[i][1]), 18, UI.DIM, "disp"))
		hv.add_child(r)
	var cv = _card(v, "Garage")
	for i in CARS.size():
		var r = UI.hb(10)
		r.add_child(UI.lbl_fill(CARS[i][0], 21, UI.TEXT if i >= lf.car else UI.DIM, "semi"))
		if i == lf.car:
			r.add_child(UI.chip("DRIVING", Color(UI.GOLD, 0.16), UI.GOLD, 15))
		elif i == lf.car + 1:
			var idx = i
			var b = UI.chip("BUY " + G.money(CARS[i][1]), UI.accent, UI.on_color(UI.accent), 16)
			UI.tap(b, func(): _buy(lf, CARS[idx][1], CARS[idx][0], func(): lf.car = idx), true)
			r.add_child(b)
		elif i > lf.car:
			r.add_child(UI.lbl(G.money(CARS[i][1]), 18, UI.DIM, "disp"))
		cv.add_child(r)
	var bv = _card(v, "Business")
	for i in BIZ.size():
		var own = i in lf.biz
		var r = UI.hb(10)
		var tv = UI.vb(-4)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UI.lbl(BIZ[i][0], 21, UI.TEXT, "semi"))
		tv.add_child(UI.lbl_fill("Pays %s a week" % G.money(BIZ[i][2]), 15, UI.MUTED))
		r.add_child(tv)
		if own:
			r.add_child(UI.chip("OWNED", Color(UI.GREEN, 0.16), UI.GREEN, 15))
		else:
			var idx = i
			var b = UI.chip("BUY " + G.money(BIZ[i][1]), UI.accent, UI.on_color(UI.accent), 16)
			UI.tap(b, func(): _buy(lf, BIZ[idx][1], BIZ[idx][0], func():
				lf.biz.append(idx)
				lf.income += BIZ[idx][2]), true)
			r.add_child(b)
		bv.add_child(r)


func _contract(v: Control):
	var s = G.s
	var u = s.user
	var sal = G.OPS.salary()
	var cv = _card(v, "Your deal at %s" % G.uc().name)
	cv.add_child(UI.lbl("%s a week" % G.money(sal), 40, UI.TEXT, "xbold"))
	cv.add_child(UI.kv("A year", G.money(sal * 52)))
	cv.add_child(UI.kv("Board confidence", "%d%%" % int(u.conf)))
	cv.add_child(UI.kv("Reputation", "%d / 100" % int(u.rep)))
	var wait = int(u.get("raise_day", -400)) + 180 - s.day
	var rv = _card(v, "Ask for a new contract")
	if wait > 0:
		rv.add_child(UI.wrap("You can open talks again in %d days." % wait, 20, UI.AMBER))
	else:
		rv.add_child(UI.wrap("The board pays more to managers they trust. Above 60% confidence they usually agree; below 45% asking only annoys them.", 19, UI.MUTED))
		for pct in [10, 25]:
			var p = pct
			rv.add_child(UI.btn("Ask for %d%% more" % p, func():
				u["raise_day"] = s.day
				var chance = clamp(0.5 + (u.conf - (55.0 + p * 0.6)) * 0.03, 0.03, 0.95)
				if G.rng.randf() < chance:
					u["salary"] = int(sal * (1.0 + p / 100.0))
					UI.sfx("cash", -8.0)
					UI.toast("New contract agreed: %s a week" % G.money(u.salary), UI.GREEN)
				else:
					u.conf = max(0.0, u.conf - 2.0)
					UI.sfx("error", -8.0)
					UI.toast("The board refused", UI.RED)
				refresh(), "secondary", "file-text", 52))


# ---------------------------------------------------------------- world

func _tcentre(v: Control):
	var s = G.s
	var rec = null
	var total = 0
	for t in s.tx_log:
		total += int(t.fee)
		if rec == null or t.fee > rec.fee:
			rec = t
	_note(v, "%s. %d deals done this season worth %s.%s" % ["The transfer window is open" if G.window_open() else "The transfer window is closed", s.tx_log.size(), G.money(total),
		(" Biggest: %s to %s for %s." % [rec.name, rec.to, G.money(rec.fee)]) if rec != null and rec.fee > 0 else ""])
	for t in s.tx_log.slice(0, 80):
		var p = UI.panel(UI.CARD, 12, 14, 7, Color(UI.accent, 0.5) if t.user else UI.LINE)
		var h = UI.hb(10)
		var d = UI.caps(G.fmt_date(t.day).substr(4), 15, UI.DIM)
		d.custom_minimum_size = Vector2(56, 0)
		h.add_child(d)
		var tv = UI.vb(-4)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UI.lbl_fill(str(t.name), 21, UI.TEXT, "semi"))
		tv.add_child(UI.lbl_fill("%s → %s" % [t.from, t.to], 16, UI.MUTED))
		h.add_child(tv)
		h.add_child(UI.lbl(G.money(t.fee) if t.fee > 0 else "Free", 20, UI.GREEN if t.fee > 0 else UI.MUTED, "disp"))
		h.add_child(UI.ovr(int(t.ovr), 18))
		p.add_child(h)
		v.add_child(p)
	if s.tx_log.is_empty():
		v.add_child(UI.wrap("No deals yet this season.", 21, UI.DIM))


func _awards(v: Control):
	var s = G.s
	var lg = G.uc().lg
	var all = []
	for cid in s.leagues[lg].clubs:
		for pid in s.clubs[cid].players:
			all.append(s.players[pid])
	for row in [["Golden boot", func(p): return float(p.ss.g), "%d goals"], ["Most assists", func(p): return float(p.ss.a), "%d assists"],
			["Player of the season", func(p): return G.avg_rating(p) if p.ss.ap >= 5 else 0.0, "%.2f"], ["Clean sheets", func(p): return float(p.ss.cs) if p.pos == "GK" else 0.0, "%d"]]:
		var f = row[1]
		var list = all.duplicate()
		list.sort_custom(func(a, b): return f.call(a) > f.call(b))
		var cv = _card(v, "%s · %s" % [row[0], s.leagues[lg].short])
		for i in min(5, list.size()):
			var val = f.call(list[i])
			if val <= 0:
				break
			var txt = row[2] % (val if row[2].contains("f") else int(val))
			cv.add_child(_prow(list[i], "%s · %s" % [s.clubs[list[i].club].short, txt], UI.GOLD if i == 0 else UI.MUTED))
		if cv.get_child_count() <= 1:
			cv.add_child(UI.lbl("Decided once matches are played.", 18, UI.DIM))


func _scores(v: Control):
	var s = G.s
	var lg = G.uc().lg
	var last = -1
	for f in s.fixtures:
		if f.played and f.get("lg", -1) == lg and f.day > last:
			last = f.day
	if last < 0:
		_note(v, "No league matches have been played yet.")
		return
	_note(v, "%s · results from %s" % [s.leagues[lg].name, G.fmt_date(last, true)])
	for f in s.fixtures:
		if not f.played or f.get("lg", -1) != lg or f.day != last:
			continue
		var p = UI.panel(UI.CARD, 12, 14, 8, Color(UI.accent, 0.5) if (f.h == s.user.club or f.a == s.user.club) else UI.LINE)
		var h = UI.hb(10)
		var a = UI.lbl_fill(s.clubs[f.h].name, 21, UI.TEXT, "semi")
		a.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		h.add_child(a)
		h.add_child(UI.badge(s.clubs[f.h], 28))
		h.add_child(UI.chip("%d - %d" % [f.hg, f.ag], Color(1, 1, 1, 0.08), UI.TEXT, 22, 76))
		h.add_child(UI.badge(s.clubs[f.a], 28))
		h.add_child(UI.lbl_fill(s.clubs[f.a].name, 21, UI.TEXT, "semi"))
		p.add_child(h)
		v.add_child(p)


func _standards(v: Control):
	var s = G.s
	var rows = []
	for l in s.leagues:
		if l.roe:
			continue
		var t = 0.0
		var best = 0.0
		for cid in l.clubs:
			t += s.clubs[cid].rep
			best = max(best, s.clubs[cid].rep)
		rows.append([l, t / max(1, l.clubs.size()), best])
	rows.sort_custom(func(a, b): return a[1] > b[1])
	_note(v, "Leagues ranked by the average strength of their clubs. Stronger leagues attract better players and earn more prize money.")
	var i = 0
	for r in rows:
		i += 1
		var p = UI.panel(UI.CARD, 12, 14, 8, UI.LINE)
		var h = UI.hb(10)
		var n = UI.lbl(str(i), 22, UI.MUTED, "disp")
		n.custom_minimum_size = Vector2(30, 0)
		h.add_child(n)
		h.add_child(UI.flag(r[0].country, 34))
		var tv = UI.vb(-4)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UI.lbl_fill(r[0].name, 21, UI.TEXT, "semi"))
		tv.add_child(UI.lbl_fill("%s · tier %d · %d clubs" % [r[0].country, r[0].tier, r[0].clubs.size()], 15, UI.MUTED))
		h.add_child(tv)
		h.add_child(UI.ovr(int(round(r[1])), 20))
		p.add_child(h)
		var lid = r[0].id
		UI.tap(p, func(): UI.main.open("table", {"lg": lid}))
		v.add_child(p)


# ---------------------------------------------------------------- search

func _findclub(v: Control):
	var s = G.s
	var row = UI.hb(8)
	row.set_meta("span", true)
	var le = UI.input(q, "Club name…", func(t): q = t)
	le.custom_minimum_size = Vector2(0, 56)
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	le.text_submitted.connect(func(_t): refresh())
	row.add_child(le)
	row.add_child(UI.btn("Search", func(): refresh(), "primary", "search", 56))
	v.add_child(row)
	var found = []
	for c in s.clubs:
		if q.strip_edges() == "" or c.name.to_lower().contains(q.strip_edges().to_lower()):
			found.append(c)
	found.sort_custom(func(a, b): return a.rep > b.rep)
	for c in found.slice(0, 45):
		var p = UI.panel(UI.CARD, 12, 14, 7, UI.LINE)
		var h = UI.hb(10)
		h.add_child(UI.badge(c, 34))
		var tv = UI.vb(-4)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UI.lbl_fill(c.name, 21, UI.TEXT, "semi"))
		tv.add_child(UI.lbl_fill(s.leagues[c.lg].name, 15, UI.MUTED))
		h.add_child(tv)
		h.add_child(UI.ovr(int(round(c.rep)), 19))
		p.add_child(h)
		var cid = c.id
		UI.tap(p, func(): UI.main.open("clubview", {"cid": cid}))
		v.add_child(p)


func _rolefinder(v: Control):
	var c = G.uc()
	_note(v, "Pick a position in your current shape to see the best affordable players for the role you use there.")
	var slots = G.slots_of(c)
	for i in 11:
		var rid = c.roles[i]
		var rd = G.RL.ROLES[rid]
		var p = UI.panel(UI.CARD, 12, 14, 8, UI.LINE)
		var h = UI.hb(10)
		h.add_child(UI.pos(slots[i][0], 18))
		var tv = UI.vb(-4)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UI.lbl_fill(rd.n, 22, UI.TEXT, "semi"))
		tv.add_child(UI.lbl_fill("Now: %s" % (G.pname(G.s.players[c.xi[i]]) if c.xi[i] >= 0 else "nobody"), 15, UI.MUTED))
		h.add_child(tv)
		h.add_child(UI.icon("chevron-right", 20, UI.DIM))
		p.add_child(h)
		var pos = slots[i][0]
		UI.tap(p, func(): UI.main.open("lists", {"kind": "role", "rid": rid, "pos": pos, "grp": "search"}))
		v.add_child(p)


# ---------------------------------------------------------------- options

func _status(v: Control):
	var s = G.s
	var cv = _card(v, "This career")
	cv.add_child(UI.kv("Manager", "%s (%s)" % [s.user.name, s.user.nat]))
	cv.add_child(UI.kv("Club", G.uc().name))
	cv.add_child(UI.kv("Date", G.fmt_date(s.day, true)))
	cv.add_child(UI.kv("Seasons completed", str(s.history.size())))
	cv.add_child(UI.kv("Matches managed", str(s.user.p)))
	var wv = _card(v, "Game world")
	wv.add_child(UI.kv("Leagues", str(s.leagues.size())))
	wv.add_child(UI.kv("Clubs", str(s.clubs.size())))
	wv.add_child(UI.kv("Players", str(s.players.size())))
	wv.add_child(UI.kv("Free agents", str(s.free.size())))
	wv.add_child(UI.kv("Save slot", str(G.slot + 1)))
	wv.add_child(UI.kv("Version", "0.4"))


func _manual(v: Control):
	for sec in [["Getting around", "The rail on the left opens every part of the game: News, Home, Club, Manager, World, Search and Options. The arrow at the top goes back. Continue in the top bar moves time on; hold it to run straight to your next match."],
			["Picking a team", "In Tactics, tap two players to swap them or drag a name onto the pitch. Drag a shirt to move a position and build your own shape. Tap a role badge to change what a player does. The tabs set how the team plays, and the pitch shows the effect."],
			["Matches", "Choose a speed, make changes from Team, and give a team talk at half time. Key speed skips to the important moments."],
			["Money", "Gate money, sponsors and TV come in weekly; wages and upkeep go out. The rest goes into your transfer budget. Upgrade buildings in Club City; one project runs at a time."],
			["Players", "Morale drops when players are left out. Unhappy players ask to leave after a few weeks. Young players grow faster with a good training ground and when they play."],
			["The board", "Meet the season objective to keep your job. Confidence rises with results against expectation. Use Board Request when confidence is high."]]:
		var cv = _card(v, sec[0])
		cv.add_child(UI.wrap(sec[1], 20, UI.TEXT))


func achievements() -> Array:
	var s = G.s
	var u = s.user
	var c = G.uc()
	var fac5 = 0
	for k in G.OPS.FAC:
		if c.fac[k] >= 5:
			fac5 += 1
	var cups = 0
	var leagues = 0
	var euro = 0
	for t in u.trophies:
		if str(t).contains("Champions League") or str(t).contains("Europa") or str(t).contains("Conference"):
			euro += 1
		elif str(t).contains("Cup") or str(t).contains("Copa") or str(t).contains("Coppa") or str(t).contains("Pokal") or str(t).contains("Coupe"):
			cups += 1
		else:
			leagues += 1
	return [["First win", "Win a match", u.w >= 1], ["Fifty up", "Win 50 matches", u.w >= 50], ["Centurion", "Manage 100 matches", u.p >= 100],
		["Silverware", "Win any trophy", u.trophies.size() >= 1], ["Champions", "Win a league title", leagues >= 1], ["Cup run", "Win a domestic cup", cups >= 1],
		["Kings of Europe", "Win a European trophy", euro >= 1], ["Dynasty", "Win five trophies", u.trophies.size() >= 5], ["Survivor", "Complete a season", s.history.size() >= 1],
		["Long haul", "Complete five seasons", s.history.size() >= 5], ["Top of the class", "Earn the UEFA Pro licence", u.badge >= 4],
		["Master builder", "Take a facility to level 5", fac5 >= 1], ["Super club", "Take every facility to level 5", fac5 >= 6],
		["Fan favourite", "Reach 80% supporter confidence", float(u.get("fans", 55.0)) >= 80.0], ["Untouchable", "Reach 90% board confidence", u.conf >= 90.0],
		["Rich list", "Hold a transfer budget of 200M", c.budget >= 200000000]]


func _achieve(v: Control):
	var list = achievements()
	var done = 0
	for a in list:
		if a[2]:
			done += 1
	_note(v, "%d of %d unlocked in this career." % [done, list.size()])
	for a in list:
		var p = UI.panel(Color(UI.GOLD, 0.1) if a[2] else UI.CARD, 14, 14, 9, Color(UI.GOLD, 0.5) if a[2] else UI.LINE)
		var h = UI.hb(12)
		h.add_child(UI.icon("award" if a[2] else "lock", 28, UI.GOLD if a[2] else UI.DIM))
		var tv = UI.vb(-3)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UI.lbl(a[0], 23, UI.TEXT if a[2] else UI.MUTED, "semi"))
		tv.add_child(UI.lbl(a[1], 16, UI.MUTED))
		h.add_child(tv)
		p.add_child(h)
		v.add_child(p)


func _fame(v: Control):
	var u = G.s.user
	var tv = _card(v, "Honours")
	for t in u.trophies:
		var h = UI.hb(10)
		h.add_child(UI.icon("trophy", 22, UI.GOLD))
		h.add_child(UI.lbl_fill(str(t), 21, UI.TEXT, "semi"))
		tv.add_child(h)
	if u.trophies.is_empty():
		tv.add_child(UI.lbl("No trophies yet.", 18, UI.DIM))
	var sv = _card(v, "Scrapbook")
	for e in u.get("scrap", []):
		var h = UI.hb(10)
		var d = UI.caps(G.fmt_date(e.day, true).substr(4), 15, UI.DIM)
		d.custom_minimum_size = Vector2(96, 0)
		h.add_child(d)
		var ev = UI.vb(-4)
		ev.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ev.add_child(UI.lbl(str(e.title), 20, UI.GOLD, "semi"))
		ev.add_child(UI.wrap(str(e.text), 18, UI.TEXT))
		h.add_child(ev)
		sv.add_child(h)
	if u.get("scrap", []).is_empty():
		sv.add_child(UI.lbl("Big wins, upsets and titles are saved here as they happen.", 18, UI.DIM))


func _editor(v: Control):
	var c = G.uc()
	var on = G.settings.get("editor", false)
	_note(v, "The editor is for fixing things or playing your own way. With it on, every player page shows rating buttons, and the tools below change your club.")
	v.add_child(UI.btn("Editor: %s" % ("on" if on else "off"), func():
		G.settings["editor"] = not on
		G.save_settings()
		refresh(), "primary" if on else "secondary", "pencil", 58))
	if not on:
		return
	for t in [["Add 10M to the transfer budget", func(): c.budget += 10000000], ["Add 100M to the transfer budget", func(): c.budget += 100000000],
			["Raise the wage budget by 10%", func(): c.wage_budget = int(c.wage_budget * 1.1)],
			["Heal every injury and lift suspensions", func():
				for pid in c.players:
					G.s.players[pid].inj = 0
					G.s.players[pid].susp = 0],
			["Full fitness and high morale", func():
				for pid in c.players:
					G.s.players[pid].cond = 100.0
					G.s.players[pid].mor = 85.0],
			["Board confidence to 80%", func(): G.s.user.conf = 80.0]]:
		var f = t[1]
		var nm = t[0]
		v.add_child(UI.btn(nm, func():
			f.call()
			UI.toast("Done: %s" % nm.to_lower(), UI.GREEN)
			UI.main.refresh_nav(), "secondary", "", 52))

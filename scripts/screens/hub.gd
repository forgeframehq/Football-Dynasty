extends "res://scripts/screens/screen.gd"
# Menu pages that are mostly information: dressing room, fans, sponsors, board requests,
# transfer centre, awards, live scores, league standards, career timeline, achievements and more.

const TITLES = {"dressing": "Dressing Room", "fans": "Fans", "sponsors": "Sponsors", "request": "Board Request", "report": "Team Report",
	"tcentre": "Transfer Centre", "awards": "Awards", "scores": "Live Scores", "standards": "League Standards", "timeline": "Career Timeline",
	"philosophy": "Philosophy", "status": "Game Status", "manual": "Manual", "achieve": "Achievements", "fame": "Hall of Fame",
	"editor": "Editor", "findclub": "Find Club", "rolefinder": "Role Finder", "identity": "Club Records", "analysis": "Match Analysis", "life": "Lifestyle", "contract": "My Contract", "invest": "Investments", "owner": "Club Ownership", "press": "Press Conference", "doc": "Season Documentary", "social": "Social"}
const QUESTIONS = [["How confident are you of a result?", [["We will win. I have no doubt.", "bold"], ["We respect them, and we are ready.", "calm"], ["I only talk about my own team.", "flat"]]],
	["Your star player has been quiet lately. Is he under pressure?", [["He is the best in the league. Watch him.", "bold"], ["Form comes and goes. He has my trust.", "calm"], ["Next question.", "flat"]]],
	["The fans are asking for more attacking football.", [["They will get goals, I promise.", "bold"], ["We play to win, in whatever way it takes.", "calm"], ["The fans do not pick the team.", "cold"]]],
	["What do you make of the opposition manager's comments?", [["He should worry about his own side.", "bold"], ["I have a lot of respect for him.", "calm"], ["I have not read them.", "flat"]]],
	["Is the board giving you enough backing?", [["We need more if we want to compete.", "cold"], ["The board and I are working as one.", "calm"], ["That stays in the boardroom.", "flat"]]]]

var pq := 0
var plog: Array = []
var slide := 0
const PROPS = [["Studio to let", 120000, 260], ["Terraced house", 320000, 640], ["City apartments", 1100000, 2300], ["Office building", 6000000, 13500]]
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
	if kind == "press":
		backdrop("press_room", 0.7)
		max_w = 900
		cols = 1
	if kind == "doc":
		backdrop("title", 0.72)
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


func _logo(name_: String, h: float) -> Control:
	var idx = -1
	for i in SPONSORS.size():
		if SPONSORS[i][0] == name_:
			idx = i
	var path = "res://assets/sponsors/sponsor_%02d.png" % (idx + 1)
	if idx < 0 or not ResourceLoader.exists(path):
		return UI.lbl(name_.to_upper(), 30, UI.TEXT, "xbold")
	var t = TextureRect.new()
	t.texture = load(path)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(h * 4.0, h)
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	t.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


func _offers() -> Array:
	return G.OPS.sponsor_offers()


func _sponsors(v: Control):
	var s = G.s
	var cur = s.user.get("sponsor")
	_note(v, "Your shirt sponsor pays every week on top of the club's commercial income. A win-bonus deal pays less each week and more when you win. Deals run for one season; a better commercial building brings bigger offers.")
	var cv = _card(v, "Current shirt sponsor")
	if cur != null and cur.season == s.season:
		cv.add_child(_logo(cur.name, 70))
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
		tv.add_child(_logo(o.name, 44))
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
	cv.add_child(UI.btn("Kit & Sponsors", func(): UI.main.root("kit"), "secondary", "shirt", 50))
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


func _pic(nm: String, w: float, h: float) -> Control:
	var path = "res://assets/life/%s.jpg" % nm
	var p = UI.panel(Color("14171f"), 10, 0, 0)
	p.custom_minimum_size = Vector2(w, h)
	p.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(path):
		var t = TextureRect.new()
		t.texture = load(path)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(t)
	if w <= 0:
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return p


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
	var hero = UI.hb(12)
	hero.set_meta("span", true)
	for it in [["home_%d" % (lf.home + 1), "Home", HOMES[lf.home][0], HOMES[lf.home][2]], ["car_%d" % max(1, lf.car), "Driving", CARS[lf.car][0], "Provided by the club" if lf.car == 0 else "Yours, paid in full"]]:
		var hp = UI.panel(UI.CARD, 16, 10, 10, UI.LINE)
		hp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var hh2 = UI.hb(12)
		hh2.add_child(_pic(it[0], 190, 112))
		var hv2 = UI.vb(-2)
		hv2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hv2.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hv2.add_child(UI.caps(it[1], 16, UI.accent))
		hv2.add_child(UI.lbl_fill(it[2], 26, UI.TEXT, "disp"))
		hv2.add_child(UI.lbl_fill(it[3], 16, UI.MUTED))
		hh2.add_child(hv2)
		hp.add_child(hh2)
		hero.add_child(hp)
	var mp = UI.panel(UI.CARD, 16, 14, 10, UI.LINE)
	mp.custom_minimum_size = Vector2(250, 0)
	var mv = UI.vb(-2)
	mv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mv.add_child(UI.caps("In the bank", 16, UI.accent))
	mv.add_child(UI.lbl(G.money(lf.cash), 34, UI.GREEN, "xbold"))
	mv.add_child(UI.lbl("%s a week in · net worth %s" % [G.money(G.OPS.salary() + int(lf.income)), G.money(net)], 15, UI.MUTED))
	mp.add_child(mv)
	hero.add_child(mp)
	v.add_child(hero)
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
		cc.add_child(UI.btn("Stop lessons" if lf.study == lang else "Take %s lessons (%s a week)" % [lang, G.money(400)], func():
			lf.study = "" if lf.study == lang else lang
			refresh(), "secondary", "book-open", 50))
		cc.add_child(UI.wrap("Fluency takes about five months and gives Motivation +1.", 17, UI.DIM))
	cc.add_child(UI.btn("Give %s to a local cause" % G.money(25000), func(): _buy(lf, 25000, "a donation the fans noticed", func():
		u["fans"] = min(100.0, float(u.get("fans", 55.0)) + 3.0)), "secondary", "heart", 50))
	var hv = _card(v, "Property showroom")
	for i in HOMES.size():
		var owned = i <= lf.home
		if i <= lf.home:
			continue
		var r = UI.hb(10)
		r.add_child(_pic("home_%d" % (i + 1), 80, 50))
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
	var cv = _card(v, "Car showroom")
	for i in CARS.size():
		if i <= lf.car:
			continue
		var r = UI.hb(10)
		if i > 0:
			r.add_child(_pic("car_%d" % i, 80, 50))
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
		r.add_child(_pic("biz_%d" % (i + 1), 80, 50))
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


func _invest(v: Control):
	var lf = G.OPS.life()
	if not lf.has("savings"):
		G.OPS.invest_week(lf)
	var pv = 0
	for pr in lf.props:
		pv += int(pr.value)
	var sv = 0.0
	for k in lf.shares:
		sv += lf.px[int(k)] * float(lf.shares[k])
	_note(v, "Put your salary to work. Savings are safe and slow. Property pays rent every week. Shares in the sponsor companies move up and down each week and can lose money. You have %s in cash." % G.money(lf.cash))
	var a = _card(v, "Savings · safe")
	a.add_child(UI.lbl(G.money(lf.savings), 36, UI.GREEN, "xbold"))
	a.add_child(UI.lbl("About 3.7% a year, paid weekly.", 17, UI.MUTED))
	var ah = UI.hb(8)
	for amt in [50000, 500000]:
		var x = amt
		var b1 = UI.btn("Pay in %s" % G.money(x), func():
			if lf.cash >= x:
				lf.cash -= x
				lf.savings += x
				refresh()
			else:
				UI.toast("Not enough cash", UI.RED), "secondary", "", 46)
		b1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ah.add_child(b1)
	a.add_child(ah)
	a.add_child(UI.btn("Withdraw everything", func():
		lf.cash += lf.savings
		lf.savings = 0
		refresh(), "ghost", "", 44))
	var p = _card(v, "Property · steady (%s owned)" % G.money(pv))
	for i in PROPS.size():
		var n = 0
		for pr in lf.props:
			if pr.k == i:
				n += 1
		var r = UI.hb(10)
		r.add_child(_pic("prop_%d" % (i + 1), 80, 50))
		var tv = UI.vb(-4)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UI.lbl("%s%s" % [PROPS[i][0], " × %d" % n if n > 0 else ""], 21, UI.TEXT, "semi"))
		tv.add_child(UI.lbl_fill("Rent %s a week" % G.money(PROPS[i][2]), 15, UI.MUTED))
		r.add_child(tv)
		var idx = i
		var b = UI.chip("BUY " + G.money(PROPS[i][1]), UI.accent, UI.on_color(UI.accent), 16)
		UI.tap(b, func(): _buy(lf, PROPS[idx][1], PROPS[idx][0], func(): lf.props.append({"k": idx, "rent": PROPS[idx][2], "value": PROPS[idx][1]})), true)
		r.add_child(b)
		p.add_child(r)
	if lf.props.size() > 0:
		p.add_child(UI.btn("Sell all property for %s" % G.money(pv), func():
			lf.cash += pv
			lf.props = []
			refresh(), "ghost", "", 44))
	var sh = _card(v, "Shares · risky (%s held)" % G.money(int(sv)))
	for i in SPONSORS.size():
		var q = int(lf.shares.get(i, 0))
		var price = lf.px[i]
		var r = UI.hb(8)
		var tv = UI.vb(-4)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UI.lbl(SPONSORS[i][0], 20, UI.TEXT, "semi"))
		tv.add_child(UI.lbl_fill("%s · %s%.1f a share%s" % [SPONSORS[i][1], G.settings.get("cur", "€"), price * G.CUR_RATE.get(G.settings.get("cur", "€"), 1.0), " · you hold %d" % q if q > 0 else ""], 15, UI.MUTED))
		r.add_child(tv)
		var idx = i
		var bb = UI.chip("BUY 1K", UI.accent, UI.on_color(UI.accent), 15)
		UI.tap(bb, func(): _buy(lf, int(lf.px[idx] * 1000), "1,000 %s shares" % SPONSORS[idx][0], func(): lf.shares[idx] = int(lf.shares.get(idx, 0)) + 1000), true)
		r.add_child(bb)
		if q > 0:
			var sb = UI.chip("SELL", Color(1, 1, 1, 0.1), UI.TEXT, 15)
			UI.tap(sb, func():
				lf.cash += int(lf.px[idx] * q)
				lf.shares.erase(idx)
				UI.sfx("cash", -8.0)
				refresh(), true)
			r.add_child(sb)
		sh.add_child(r)
	var e = _card(v, "Work off the pitch")
	e.add_child(UI.btn("Agent: %s (%s a week)" % ["hired" if lf.agent else "none", G.money(2000)], func():
		lf.agent = not lf.agent
		refresh(), "primary" if lf.agent else "secondary", "briefcase", 48))
	e.add_child(UI.lbl("An agent makes the board more likely to agree a pay rise.", 16, UI.DIM))
	e.add_child(UI.btn("TV and newspaper work: %s" % ("on" if lf.media else "off"), func():
		lf.media = not lf.media
		refresh(), "primary" if lf.media else "secondary", "megaphone", 48))
	e.add_child(UI.lbl("Pays %s a week and builds reputation, but the board likes it less each week." % G.money(8000), 16, UI.DIM))


func _owner(v: Control):
	var s = G.s
	var lf = G.OPS.life()
	if not lf.has("savings"):
		G.OPS.invest_week(lf)
	var c = G.uc()
	var mine = float(lf.stakes.get(c.id, 0))
	_note(v, "Buy shares in clubs in blocks of 10%%. Every stake pays you a weekly dividend. Hold 51%% or more of the club you manage and you are the owner: you cannot be sacked, and you can put your own money into the club. You have %s in cash." % G.money(lf.cash))
	var targets = [c]
	var others = []
	for o in s.clubs:
		if o.id != c.id and not s.leagues[o.lg].roe and float(lf.stakes.get(o.id, 0)) > 0:
			targets.append(o)
		elif o.id != c.id and not s.leagues[o.lg].roe and not G.LG.is_reserve(o.id):
			others.append(o)
	others.sort_custom(func(a, b): return G.OPS.club_value(a) < G.OPS.club_value(b))
	targets += others.slice(0, 8)
	for o in targets:
		var val = G.OPS.club_value(o)
		var pct = float(lf.stakes.get(o.id, 0))
		var p = UI.panel(UI.CARD, 14, 14, 9, Color(UI.GOLD, 0.6) if pct >= 51 else (Color(UI.accent, 0.5) if o.id == c.id else UI.LINE))
		var h = UI.hb(10)
		h.add_child(UI.badge(o, 40))
		var tv = UI.vb(-4)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UI.lbl_fill(o.name, 21, UI.TEXT, "semi"))
		tv.add_child(UI.lbl_fill("Worth %s · you own %d%%%s" % [G.money(val), int(pct), " · OWNER" if pct >= 51 else ""], 15, UI.GOLD if pct >= 51 else UI.MUTED))
		h.add_child(tv)
		var oid = o.id
		if pct < 100:
			var b = UI.chip("BUY 10% " + G.money(int(val * 0.1)), UI.accent, UI.on_color(UI.accent), 15)
			UI.tap(b, func(): _buy(lf, int(val * 0.1), "10%% of %s" % s.clubs[oid].name, func():
				lf.stakes[oid] = float(lf.stakes.get(oid, 0)) + 10.0
				if oid == c.id and lf.stakes[oid] >= 51.0 and lf.stakes[oid] < 61.0:
					G.scrap("Owner", "You bought control of %s" % c.name)
					G.msg("You now own %s" % c.name, "With a majority of the shares the club is yours. The board answers to you.", "board")), true)
			h.add_child(b)
		if pct > 0:
			var sb = UI.chip("SELL 10%", Color(1, 1, 1, 0.1), UI.TEXT, 15)
			UI.tap(sb, func():
				lf.cash += int(val * 0.1)
				lf.stakes[oid] = pct - 10.0
				if lf.stakes[oid] <= 0:
					lf.stakes.erase(oid)
				UI.sfx("cash", -8.0)
				refresh(), true)
			h.add_child(sb)
		p.add_child(h)
		v.add_child(p)
	if mine >= 51:
		var ov = _card(v, "Owner's office")
		ov.add_child(UI.kv("Transfer budget", G.money(c.budget)))
		ov.add_child(UI.kv("Wage budget", "%s / wk" % G.money(c.wage_budget)))
		for amt in [1000000, 10000000]:
			var x = amt
			ov.add_child(UI.btn("Put %s of your money into transfers" % G.money(x), func(): _buy(lf, x, "a cash injection", func(): c.budget += x), "secondary", "", 46))
		ov.add_child(UI.btn("Raise the wage budget by 10%", func():
			c.wage_budget = int(c.wage_budget * 1.1)
			refresh(), "secondary", "", 46))


func _social(v: Control):
	var s = G.s
	var u = s.user
	var c = G.uc()
	var d = G.SOC.data()
	var can = d.last < s.day
	var head = UI.card(18, 12)
	head.set_meta("span", true)
	var hh = UI.hb(14)
	hh.add_child(UI.lbl("@%s" % str(u.name).to_lower().replace(" ", "_"), 24, UI.TEXT, "bold"))
	hh.add_child(UI.lbl("%s followers" % G.OPS._thousands(d.followers), 20, UI.accent, "disp"))
	hh.add_child(UI.sp())
	if d.trend != "":
		hh.add_child(UI.chip("TRENDING " + d.trend, Color(UI.accent, 0.16), UI.accent, 17))
	head.add_child(hh)
	v.add_child(head)
	var comp = _card(v, "New post" if can else "You have posted today")
	if can:
		var le = UI.input(q, "Write something…", func(t): q = t)
		le.custom_minimum_size = Vector2(0, 54)
		comp.add_child(le)
		comp.add_child(UI.btn("Post", func():
			if q.strip_edges() == "":
				return
			var r = G.SOC.post(q.strip_edges())
			q = ""
			UI.sfx("message", -8.0)
			UI.toast(r, UI.accent)
			refresh(), "primary", "megaphone", 48))
		comp.add_child(UI.caps("Or pick one", 15, UI.DIM))
		var best = null
		for pid in c.xi:
			if pid >= 0 and (best == null or s.players[pid].form > best.form):
				best = s.players[pid]
		var nf = G.next_user_fixture()
		var quick = [["Thank you to every fan who backs this team. We feel it.", "good"], ["We go again. Heads up, work hard, together.", "good"]]
		if best != null:
			quick.append(["%s has been brilliant in training. Proud of him." % G.pname(best), "good"])
		if nf != null:
			var on = s.clubs[nf.a if nf.h == c.id else nf.h].name
			quick.append(["%s next. They know what's coming." % on, "neutral"])
		for qk in quick:
			var txt = qk[0]
			var tn = qk[1]
			var b = UI.panel(Color(1, 1, 1, 0.05), 10, 12, 7, Color(1, 1, 1, 0.1))
			b.add_child(UI.wrap(txt, 17, UI.TEXT))
			UI.tap(b, func():
				var r = G.SOC.post(txt, tn)
				UI.sfx("message", -8.0)
				UI.toast(r, UI.accent)
				refresh(), true)
			comp.add_child(b)
	else:
		comp.add_child(UI.wrap("One post a day keeps the board calm. Come back tomorrow.", 18, UI.MUTED))
	for p in d.posts.slice(0, 40):
		var col = UI.accent if p.mine else (UI.GOLD if p.kind == "press" else UI.LINE)
		var pc = UI.panel(UI.CARD, 14, 14, 10, Color(col, 0.6) if p.mine or p.kind == "press" else UI.LINE)
		var pv = UI.vb(4)
		var ph = UI.hb(8)
		ph.add_child(UI.lbl(str(p.who), 19, UI.TEXT, "bold"))
		ph.add_child(UI.lbl_fill("@%s · %s" % [p.handle, G.fmt_date(p.day).substr(4)], 15, UI.DIM))
		pv.add_child(ph)
		pv.add_child(UI.wrap(str(p.text), 19, UI.TEXT))
		var st = UI.hb(14)
		st.add_child(UI.icon("heart", 16, UI.RED))
		st.add_child(UI.lbl(G.OPS._thousands(int(p.likes)), 15, UI.MUTED))
		st.add_child(UI.icon("repeat", 16, UI.GREEN))
		st.add_child(UI.lbl(G.OPS._thousands(int(p.reposts)), 15, UI.MUTED))
		pv.add_child(st)
		for r in p.replies:
			var rr = UI.panel(Color(1, 1, 1, 0.04), 8, 10, 5)
			rr.add_child(UI.wrap("@%s  %s" % [r[0], r[1]], 16, UI.MUTED))
			pv.add_child(rr)
		pc.add_child(pv)
		v.add_child(pc)
	if d.posts.is_empty():
		_note(v, "The feed fills up once matches are played.")


func _press(v: Control):
	var s = G.s
	var u = s.user
	var c = G.uc()
	if pq == 0 and plog.is_empty():
		UI.sfx("sting_news", -12.0)
	if pq >= 3:
		u["press_day"] = s.day
		var cv = _card(v, "The headlines")
		for line in plog:
			cv.add_child(UI.wrap(line, 21, UI.TEXT))
		v.add_child(UI.btn("Done", func(): UI.main.back(), "primary", "check", 56))
		return
	var rng = RandomNumberGenerator.new()
	rng.seed = s.day * 31 + c.id
	var order = range(QUESTIONS.size())
	for i in range(order.size() - 1, 0, -1):
		var j = rng.randi() % (i + 1)
		var t = order[i]
		order[i] = order[j]
		order[j] = t
	var q = QUESTIONS[order[pq]]
	var qc = _card(v, "Question %d of 3" % (pq + 1))
	var ql = UI.wrap("“%s”" % q[0], 28, UI.TEXT, "disp")
	qc.add_child(ql)
	ql.modulate.a = 0.0
	ql.create_tween().tween_property(ql, "modulate:a", 1.0, 0.5)
	for ans in q[1]:
		var kind = ans[1]
		var text = ans[0]
		v.add_child(UI.btn(text, func():
			if kind == "bold":
				for pid in c.players:
					s.players[pid].mor = min(100.0, s.players[pid].mor + 2.0)
				u["fans"] = min(100.0, float(u.get("fans", 55.0)) + 1.0)
				u.conf = max(0.0, u.conf - 0.5)
				plog.append("Bold words lift the squad and the fans. The board hopes you can back them up.")
			elif kind == "calm":
				u.conf = min(100.0, u.conf + 0.7)
				plog.append("A measured answer. The board approves.")
			elif kind == "cold":
				u["fans"] = max(0.0, float(u.get("fans", 55.0)) - 2.0)
				u.conf = max(0.0, u.conf - 1.0)
				plog.append("A sharp reply makes the back pages. Fans and directors are not impressed.")
			else:
				plog.append("You gave nothing away.")
			pq += 1
			UI.sfx("click", -12.0)
			refresh(), "secondary", "", 58))


func _doc(v: Control):
	var s = G.s
	var u = s.user
	var c = G.uc()
	var slides = [["%s" % G.season_name(), "%s · %s" % [c.name, u.name]]]
	slides.append(["%s in the %s" % [G.LG.ordinal(G.LG.position(c.id)), s.leagues[c.lg].name], "%d points · %d scored · %d conceded" % [c.t.pts, c.t.gf, c.t.ga]])
	var sc_ = c.players.map(func(pid): return s.players[pid])
	sc_.sort_custom(func(a, b): return a.ss.g > b.ss.g)
	if sc_.size() > 0 and sc_[0].ss.g > 0:
		slides.append(["%s · %d goals" % [G.pname(sc_[0]), sc_[0].ss.g], "Top scorer"])
	var ev = u.get("scrap", []).filter(func(e): return e.day > s.day - 330)
	ev.reverse()
	for e in ev.slice(0, 10):
		slides.append([str(e.text), "%s · %s" % [str(e.title), G.fmt_date(e.day, true)]])
	slides.append(["Board %d%% · Fans %d%%" % [int(u.conf), int(u.get("fans", 55.0))], "How it stands"])
	slide = clampi(slide, 0, slides.size() - 1)
	var card = UI.panel(Color(0.04, 0.06, 0.1, 0.82), 24, 30, 40, Color(UI.GOLD, 0.6))
	card.custom_minimum_size = Vector2(0, 300)
	var cv = UI.vb(10)
	cv.alignment = BoxContainer.ALIGNMENT_CENTER
	var cap = UI.caps(slides[slide][1], 22, UI.GOLD)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var big = UI.wrap(slides[slide][0], 46, UI.TEXT, "xbold")
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cv.add_child(cap)
	cv.add_child(big)
	card.add_child(cv)
	v.add_child(card)
	card.modulate.a = 0.0
	card.scale = Vector2(0.96, 0.96)
	var tw = card.create_tween().set_parallel(true)
	tw.tween_property(card, "modulate:a", 1.0, 0.6)
	tw.tween_property(card, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if slide == 0:
		UI.sfx("sting_trophy", -12.0)
	var nav = UI.hb(10)
	nav.add_child(UI.lbl_fill("%d / %d" % [slide + 1, slides.size()], 18, UI.MUTED))
	if slide < slides.size() - 1:
		nav.add_child(UI.btn("Next", func():
			slide += 1
			refresh(), "primary", "chevron-right", 52))
		var at = slide
		get_tree().create_timer(3.4).timeout.connect(func():
			if is_instance_valid(self) and slide == at and is_visible_in_tree():
				slide += 1
				refresh())
	else:
		nav.add_child(UI.btn("Watch again", func():
			slide = 0
			refresh(), "secondary", "repeat", 52))
	v.add_child(nav)


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
				var chance = clamp(0.5 + (u.conf - (55.0 + p * 0.6)) * 0.03 + (0.15 if G.OPS.life().get("agent", false) else 0.0), 0.03, 0.95)
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
	wv.add_child(UI.kv("Version", "0.5"))


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
		h.add_child(UI.trophy(str(t), 44))
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

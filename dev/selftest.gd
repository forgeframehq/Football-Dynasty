extends RefCounted
# Headless smoke test: plays full seasons and prints calibration numbers.
#   godot --headless --path . -- --selftest [seasons]

static func run(node: Node):
	var args = OS.get_cmdline_user_args()
	var seasons = 1
	for a in args:
		if a.is_valid_int():
			seasons = int(a)
	var cid = 1
	for a in args:
		if a.begins_with("club="):
			cid = int(a.substr(5))
	var t0 = Time.get_ticks_msec()
	if "load" in args:
		print("loaded old save: ", G.load_game(), " v", G.s.v, " clubs ", G.s.clubs.size(), " user ", G.uc().name, " formation ", G.uc().formation)
	else:
		G.new_game("Tester", cid)
	print("new game ms: ", Time.get_ticks_msec() - t0, " players: ", G.s.players.size(), " fixtures: ", G.s.fixtures.size())
	var c = G.uc()
	print("club: ", c.name, " rep ", snapped(c.rep, 0.1), " budget ", G.money(c.budget), " obj ", G.s.user.obj)
	for se in seasons:
		var start = Time.get_ticks_msec()
		var season = G.s.season
		var guard = 0
		while G.s.season == season and guard < 500:
			guard += 1
			if G.s.day == G.ymd(season + 1, 6, 5):
				calib()
			var f = G.user_fixture_today()
			if f != null:
				G.auto_pick(G.uc())
				G.sim_fixture(f)
				G.play_day_fixtures()
			G.s.user.sacked = false
			for o in G.s.offers.duplicate():
				if G.rng.randf() < 0.5 and G.uc().players.size() > 22:
					G.TR.accept_offer(o)
			G.advance()
		var played = 0
		var goals = 0
		var hw = 0
		var dr = 0
		# stats are from the review since fixtures were regenerated
		var rv = G.s.review
		G.s.review = null
		print("--- season ", season, " done in ", Time.get_ticks_msec() - start, " ms, continues: ", guard)
		print("user: ", rv.user)
		for l in rv.leagues:
			print("  ", G.s.leagues[l.lg].name, ": ", G.s.clubs[l.champ].name, " | top scorer ", l.scorer, " (", l.scorer_club, ") ", l.goals)
		print("  ups: ", rv.ups.map(func(x): return G.s.clubs[x[0]].name))
		print("  downs: ", rv.downs.map(func(x): return G.s.clubs[x[0]].name))
		print("  players: ", G.s.players.size(), " free: ", G.s.free.size(), " inbox: ", G.s.inbox.size(), " news: ", G.s.news.size())
		var sizes = G.s.clubs.map(func(x): return x.players.size())
		print("  squad sizes min/max: ", sizes.min(), "/", sizes.max(), " history: ", G.s.history[0])
	node.get_tree().quit()


static func calib():
	var n = 0
	var goals = 0
	var hw = 0
	var dr = 0
	for f in G.s.fixtures:
		if f.played and not f.ko:
			n += 1
			goals += f.hg + f.ag
			if f.hg > f.ag: hw += 1
			elif f.hg == f.ag: dr += 1
	print("CALIB matches ", n, " goals/game ", snapped(goals / float(n), 0.01), " home% ", snapped(100.0 * hw / n, 0.1), " draw% ", snapped(100.0 * dr / n, 0.1))
	for lg in [0, 1, 4, 8]:
		var t = G.LG.table(lg)
		var line = G.s.leagues[lg].name + ": "
		for i in [0, 1, 2, 3, 4, t.size() / 2, t.size() - 3, t.size() - 2, t.size() - 1]:
			var c = G.s.clubs[t[i]]
			line += "%s %d(%d:%d) r%d | " % [c.short, c.t.pts, c.t.gf, c.t.ga, int(c.rep)]
		print(line)
	var top = []
	for pid in G.s.clubs[G.LG.table(0)[0]].players:
		var p = G.s.players[pid]
		top.append([p.ss.g, G.pname(p), p.pos, p.ss.ap, p.ss.a, snapped(G.avg_rating(p), 0.01)])
	top.sort_custom(func(a, b): return a[0] > b[0])
	print("PL champs scorers: ", top.slice(0, 8))

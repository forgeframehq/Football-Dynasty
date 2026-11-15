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
	elif "world" in args:
		# a career at Flamengo with Brazil, Argentina, England, Spain and Portugal playable
		var prof = G.OPS.default_profile()
		prof.name = "Tester"
		prof["playable"] = ["Brazil", "Argentina", "England", "Spain", "Portugal"]
		prof["world_club"] = "Flamengo"
		G.new_game(prof, 0)
	else:
		G.new_game("Tester", cid)
	print("new game ms: ", Time.get_ticks_msec() - t0, " players: ", G.s.players.size(), " fixtures: ", G.s.fixtures.size())
	var ts0 = Time.get_ticks_msec()
	G.save_game()
	print("save ms: ", Time.get_ticks_msec() - ts0, " file: ", FileAccess.get_file_as_bytes(G.save_path()).size() / 1024, " KB")
	# send the club's scout on a senior mission and a hired one on a youth mission
	G.SN.ensure()
	G.uc().budget += 1000000
	var sc0 = G.SN.scouts()[0]
	G.SN.start(sc0, "senior", "Iberia", 3, 0, 1, 0, 2)
	var mk0 = G.SN.market()
	if mk0.size() > 0 and G.SN.hire(G.s.staff[mk0[0]]) == "":
		G.SN.start(G.s.staff[mk0[0]], "youth", "Africa", 2, 0, 0, 0, 0)
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
		print("  cups: ", rv.cups.map(func(x): return x[0] + ": " + G.s.clubs[x[1]].name))
		print("  ups: ", rv.ups.map(func(x): return G.s.clubs[x[0]].name))
		print("  downs: ", rv.downs.map(func(x): return G.s.clubs[x[0]].name))
		print("  players: ", G.s.players.size(), " free: ", G.s.free.size(), " inbox: ", G.s.inbox.size(), " news: ", G.s.news.size())
		# the newer systems: staff, managers, stories, social feed, backups
		var kinds = {}
		for sp in G.SOC.data().posts:
			kinds[sp.kind] = kinds.get(sp.kind, 0) + 1
		var stories = 0
		for m in G.s.inbox:
			if m.get("kind", "") == "story":
				stories += 1
		var fe = 0
		for mcid in G.s.mgrs:
			if float(G.s.mgrs[mcid].feud) > 0:
				fe += 1
		print("  staff: ", G.uc().staff.size(), " market: ", G.s.staff_free.size(), " ex-players: ", G.s.staff_free.filter(func(x): return G.s.staff[x].ex != null).size(),
			" | managers: ", G.s.mgrs.size(), " feuds: ", fe, " moves: ", G.s.mgr_log.size(), " | stories in inbox: ", stories, " | posts: ", kinds, " | backups: ", G.backups(G.slot).size(), " | scout reports: ", G.s.sn.reports.size(), " prospects: ", G.s.sn.prospects.size(), " missions out: ", G.s.sn.missions.size())
		# the wider world: last season's champions and how many moved to the big leagues
		var wl = []
		for l in G.s.leagues:
			if l.has("cont"):
				wl.append("%s %d clubs" % [l.name, l.clubs.size()])
		var exports = 0
		for pid in G.s.players:
			var pp = G.s.players[pid]
			if pp.has("prevc") and pp.prevc >= 0 and G.s.leagues[G.s.clubs[pp.prevc].lg].has("cont") and pp.club >= 0 and not G.s.leagues[G.s.clubs[pp.club].lg].has("cont"):
				exports += 1
		var it = G.s.intl.done.map(func(x): return "%s %d: %s" % [x.name, x.year, x.winner])
		var cc = []
		for comp in G.s.get("comps", []):
			cc.append(comp.name)
		print("  intl: ", it, " | playable: ", G.WD.playable(), " | comps now: ", cc)
		print("  world: ", wl, " | exports to the big leagues: ", exports, " | world champions: ", G.s.champs[0].c.keys().size() if G.s.champs.size() > 0 else 0)
		var sizes = G.s.clubs.map(func(x): return x.players.size())
		print("  squad sizes min/max: ", sizes.min(), "/", sizes.max(), " history: ", G.s.history[0])
		var bl = G.backups(G.slot)
		if bl.size() > 1 and se == seasons - 1:
			var day_now = G.s.day
			var ok = G.restore(bl[1].base, G.slot) and G.load_game(G.slot)
			print("  restore test: ", ok, " back from day ", day_now, " to day ", G.s.day)
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

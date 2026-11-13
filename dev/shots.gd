extends RefCounted
# Dev tool: opens screens and saves screenshots to /tmp/shots.
#   xvfb-run -a -s "-screen 0 1600x720x24" godot --path . --audio-driver Dummy --rendering-driver opengl3 --resolution 1600x720 -- --shots [only=a,b] [club=ID] [days=N] [notch=PX]

var main
var n := 0


func snap(tag: String, wait := 0.3):
	for i in 4:
		await main.get_tree().process_frame
	await main.get_tree().create_timer(wait).timeout
	var img = main.get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute("/tmp/shots")
	img.save_png("/tmp/shots/%02d_%s.png" % [n, tag])
	n += 1


func run(m):
	main = m
	var only: Array = []
	var club = 1
	var days = 0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("only="):
			only = Array(a.substr(5).split(","))
		if a.begins_with("club="):
			club = int(a.substr(5))
		if a.begins_with("days="):
			days = int(a.substr(5))
	var want = func(k): return only.is_empty() or k in only
	if want.call("menu"):
		await snap("menu")
	if want.call("new"):
		main.open("new_career", {"slot": 0})
		await snap("new_0")
		var nc = main.stack[-1]
		if nc.has_method("dev_step"):
			for i in 6:
				if not nc.dev_step():
					break
				await snap("new_%d" % (i + 1))
	G.new_game("Sudhi", club)
	if want.call("intro"):
		main.root("intro", {"kind": "appoint"})
		await snap("intro", 1.2)
		main.root("intro", {"kind": "board"})
		await snap("intro_board")
	for i in 3:
		G.advance()
	for i in days:
		# play on so screens have results, finances and news to show
		var fx0 = G.user_fixture_today()
		if fx0 != null:
			var sim0 = G.new_sim(fx0, false)
			while sim0.phase < 4:
				sim0.step()
			G.apply_match(sim0)
		G.advance()
	var c = G.uc()
	if want.call("tacsetup") and not only.is_empty():
		main.root("home")
		await snap("setup_style", 0.8)
		main.close_sheet()
		G.TC.set_style(c, 1)
		preload("res://scripts/screens/tac_sheets.gd").pick_link(-1, func(): pass)
		await snap("setup_link", 0.8)
		main.close_sheet()
	G.s.user["tac_set"] = true
	var simple = ["home", "inbox", "squad", "tactics", "training", "fixtures", "finances", "campus", "board", "trophies", "jobs", "table", "comps", "stats", "transfers", "scouting", "club"]
	if want.call("trophies"):
		G.s.user.trophies = ["Premier League 2026/27", "FA Cup 2026/27", "UEFA Champions League 2027/28", "EFL Cup 2027/28"]
	for k in simple:
		if want.call(k):
			main.root(k, {"lg": c.lg} if k in ["table", "stats"] else {})
			await snap(k)
	if want.call("dense"):
		main.root("fixtures")
		main.stack[-1].mode = 1
		main.stack[-1].refresh()
		await snap("fixtures_round")
		main.root("clubview", {"cid": 2})
		await snap("clubview")
	if want.call("exit"):
		main.root("home")
		main.back()
		await snap("exit", 0.6)
		main.close_sheet()
	if want.call("menus"):
		main.root("home")
		for k in ["club", "manager", "world", "search", "options"]:
			main.open_menu(k)
			await snap("menu_" + k)
		main.close_menu()
	if want.call("lists"):
		for k in ["medical", "contracts", "top50", "bargains"]:
			main.root("lists", {"kind": k, "grp": "club"})
			await snap("list_" + k)
	if want.call("social"):
		for i in 30:
			G.advance()
			var fx = G.user_fixture_today()
			if fx != null:
				var sim = G.new_sim(fx, false)
				while sim.phase < 4:
					sim.step()
				G.apply_match(sim)
		print("posts ", G.SOC.data().posts.size(), " ", G.SOC.post("Proud of the lads, great win. Haaland was superb"))
		main.root("hub", {"kind": "social", "grp": "manager"})
		await snap("social")
	if want.call("hub"):
		for k in ["press", "doc", "invest", "owner", "life", "contract", "dressing", "fans", "sponsors", "request", "report", "identity", "analysis", "timeline", "philosophy", "tcentre", "awards", "scores", "standards", "findclub", "rolefinder", "status", "manual", "achieve", "fame", "editor"]:
			main.root("hub", {"kind": k, "grp": "club"})
			await snap("hub_" + k)
		main.root("lists", {"kind": "similar", "pid": c.xi[9], "grp": "search"})
		await snap("list_similar")
		main.root("lists", {"kind": "role", "rid": c.roles[9], "pos": c.slots[9][0], "grp": "search"})
		await snap("list_role")
	if want.call("player"):
		main.root("search")
		await snap("search")
		main.stack[-1].view = 2
		main.stack[-1].refresh()
		await snap("search_attr")
		main.root("player", {"pid": c.xi[9]})
		await snap("player")
		for pg in [1, 2, 3, 4, 5]:
			main.stack[-1].page = pg
			main.stack[-1].refresh()
			await snap("player_p%d" % pg)
		main.root("player", {"pid": G.s.clubs[2].players[0]})
		await snap("player_other")
		main.root("clubview", {"cid": 2})
		await snap("clubview")
	if want.call("deal"):
		var tp = G.s.players[G.s.clubs[2].players[7]]
		main.root("nego", {"pid": tp.id, "mode": "buy"})
		await snap("deal_new")
		var dd = G.DL.find(tp.id)
		var scd = main.stack[-1]
		scd.reply = "\u201c%s\u201d" % G.DL.enquire(dd)
		scd.reply_col = UI.AMBER
		scd.refresh()
		await snap("deal_club")
		scd.fee = int(dd.ask * 0.85)
		scd.swap = c.players[20]
		scd._bid(tp, false)
		await snap("deal_counter1")
		scd.fee = int(dd.ask)
		scd.swap = -1
		scd._bid(tp, false)
		await snap("deal_meet")
		G.s.day += 1
		G.DL.tick()
		main.root("nego", {"pid": tp.id, "mode": "buy"})
		await snap("deal_talks")
		var sc = main.stack[-1]
		sc.t.wage = int(sc.t.wage * 0.95)
		sc.t.bon = 3
		sc._offer_terms(tp)
		await snap("deal_counter")
		var dm = G.DL.demand(dd, sc.t)
		sc.t.wage = dm.wage
		sc.t.sign = dm.sign
		sc.t.agent = dm.agent
		c.budget = max(c.budget, dd.fee * 2)
		c.wage_budget += dm.wage * 2
		sc._offer_terms(tp)
		await snap("deal_done", 0.8)
		main.root("inbox")
		await snap("deal_inbox")
		main.root("player", {"pid": tp.id})
		main.stack[-1].page = 1
		main.stack[-1].refresh()
		await snap("deal_personal")
		main.stack[-1].page = 4
		main.stack[-1].refresh()
		await snap("deal_stats")
		G.s.offers.append({"id": 999, "pid": c.xi[5], "from": 3, "fee": G.nice(G.value(G.s.players[c.xi[5]]) * 1.1), "exp": G.s.day + 5, "haggled": false})
		if G.s.offers.size() > 0:
			main.root("nego", {"pid": c.xi[5], "mode": "sell", "oid": 999})
			await snap("deal_sell")
		main.root("nego", {"pid": c.xi[3], "mode": "renew"})
		await snap("deal_renew")
	if want.call("life"):
		G.OPS.life().cash = 2400000
		main.root("life")
		for i in 5:
			main.stack[-1].tab = i
			main.stack[-1].pick = -1
			main.stack[-1].refresh()
			await snap("life_%d" % i)
	if want.call("tactics2"):
		if G.s.user.links.is_empty():
			for id in G.TC.LINK_ORDER:
				if not G.TC.user_pair(id, c).is_empty() and G.s.user.links.size() < 2:
					G.s.user.links.append(id)
		main.root("tactics")
		await snap("tactics_0")
		var t = main.stack[-1]
		for i in [1, 2, 3, 4, 5]:
			t.tab = i
			t.refresh()
			await snap("tactics_%d" % i)
	if want.call("city"):
		for lv in [1, 3, 5]:
			for k in G.OPS.FAC:
				c.fac[k] = lv
			c.build = {"key": "training", "done": G.s.day + 40, "cost": 0} if lv == 3 else null
			main.root("campus")
			await snap("city%d" % lv)
			if lv == 3:
				main.stack[-1].sel = "stadium"
				main.stack[-1].zoom = 1.0
				main.stack[-1].refresh()
				await snap("city_sel")
	if want.call("match"):
		for i in 8:
			if G.user_fixture_today() != null:
				break
			G.advance()
		main.root("home")
		await snap("home_matchday")
		var fx = G.user_fixture_today()
		main.root("match", {"fx": fx})
		await snap("match_pre")
		var ms = main.stack[-1]
		ms._kickoff()
		ms.speed = 2
		await main.get_tree().create_timer(6.0).timeout
		await snap("match_live")
		for tb in [1, 2, 3]:
			ms.tab = tb
			ms._build_tabs()
			ms._refresh_tab()
			await snap("match_tab%d" % tb)
		ms._team_sheet()
		await snap("match_team")
		main.close_sheet()
		ms._skip()
		await snap("match_ft")
	main.get_tree().quit()

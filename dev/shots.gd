extends RefCounted
# Dev tool: opens screens and saves screenshots to /tmp/shots.
#   xvfb-run -a -s "-screen 0 1600x720x24" godot --path . --audio-driver Dummy --rendering-driver opengl3 --resolution 1600x720 -- --shots [only=a,b] [club=ID]

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
	for a in OS.get_cmdline_user_args():
		if a.begins_with("only="):
			only = Array(a.substr(5).split(","))
		if a.begins_with("club="):
			club = int(a.substr(5))
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
	var c = G.uc()
	var simple = ["home", "inbox", "squad", "tactics", "training", "fixtures", "finances", "campus", "board", "trophies", "jobs", "table", "comps", "stats", "transfers", "scouting", "club"]
	for k in simple:
		if want.call(k):
			main.root(k, {"lg": c.lg} if k in ["table", "stats"] else {})
			await snap(k)
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
	if want.call("hub"):
		for k in ["life", "contract", "dressing", "fans", "sponsors", "request", "report", "identity", "analysis", "timeline", "philosophy", "tcentre", "awards", "scores", "standards", "findclub", "rolefinder", "status", "manual", "achieve", "fame", "editor"]:
			main.root("hub", {"kind": k, "grp": "club"})
			await snap("hub_" + k)
		main.root("lists", {"kind": "similar", "pid": c.xi[9], "grp": "search"})
		await snap("list_similar")
		main.root("lists", {"kind": "role", "rid": c.roles[9], "pos": c.slots[9][0], "grp": "search"})
		await snap("list_role")
	if want.call("player"):
		main.root("player", {"pid": c.xi[9]})
		await snap("player")
		main.root("clubview", {"cid": 2})
		await snap("clubview")
	if want.call("tactics2"):
		main.root("tactics")
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

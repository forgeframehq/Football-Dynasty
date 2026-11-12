extends RefCounted
# Dev tool: walks through the screens and saves screenshots to /tmp/shots.
#   xvfb-run godot --path . --resolution 720x1560 -- --shots

var main
var n := 0


func snap(tag: String):
	for i in 4:
		await main.get_tree().process_frame
	await main.get_tree().create_timer(0.25).timeout
	var img = main.get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute("/tmp/shots")
	img.save_png("/tmp/shots/%02d_%s.png" % [n, tag])
	n += 1


func run(m):
	main = m
	var only = ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("only="):
			only = a.substr(5)
	if only == "campus":
		G.new_game("Sudhi", 1)
		for lv in [5, 3, 1]:
			for k in G.OPS.FAC:
				G.uc().fac[k] = lv
			if lv == 3:
				G.uc().build = {"key": "stadium", "done": G.s.day + 40, "cost": 0}
			main.root("campus")
			await snap("campus%d" % lv)
		main.get_tree().quit()
		return
	await snap("menu")
	main.open("new_career")
	await snap("new_league")
	var nc = main.stack[-1]
	nc.lg = 0
	nc.step = 1
	nc.refresh()
	await snap("new_club")
	nc._confirm(1)
	await snap("new_confirm")
	main.close_sheet()
	G.new_game("Sudhi", 1)
	main.root("home")
	await snap("home")
	for i in 7:
		var f = G.user_fixture_today()
		if f != null:
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
	ms.tab = 0
	ms._build_tabs()
	ms._refresh_tab()
	ms._team_sheet()
	await snap("match_team")
	ms.sub_out = 9
	ms._team_sheet()
	await snap("match_team2")
	main.close_sheet()
	ms._skip()
	await snap("match_ft")
	ms.lower.get_child(0).scroll_vertical = 600
	await snap("match_ft2")
	G.apply_match(ms.sim)
	for o in ms.others:
		G.apply_match(o)
	G.play_day_fixtures()
	for i in 6:
		var f = G.user_fixture_today()
		if f != null:
			G.auto_pick(G.uc())
			G.sim_fixture(f)
			G.play_day_fixtures()
		G.advance()
	main.root("home")
	await snap("home_later")
	main.stack[-1].sc.scroll_vertical = 700
	await snap("home_later2")
	for t in ["squad", "tactics", "transfers", "club"]:
		main.tab(t)
		await snap(t)
	main.tab("tactics")
	main.stack[-1].sc.scroll_vertical = 900
	await snap("tactics2")
	main.stack[-1].sc.scroll_vertical = 1700
	await snap("tactics3")
	main.stack[-1]._pick_role(9)
	await snap("tactics_role")
	main.close_sheet()
	main.stack[-1]._presets()
	await snap("tactics_presets")
	main.close_sheet()
	main.open("player", {"pid": G.uc().players[3]})
	await snap("player")
	main.stack[-1].sc.scroll_vertical = 700
	await snap("player2")
	main.open("nego", {"pid": G.uc().players[3], "mode": "renew"})
	await snap("nego_renew")
	main.back()
	main.back()
	var target = G.s.clubs[5].players[2]
	main.open("player", {"pid": target})
	await snap("player_other")
	main.open("nego", {"pid": target, "mode": "buy"})
	await snap("nego_buy")
	main.back()
	main.back()
	G.s.players[G.uc().players[20]].listed = true
	G.TR.make_offer(G.s.players[G.uc().players[20]])
	G.ui.tr_tab = 2
	main.tab("transfers")
	await snap("offers")
	G.ui.tr_tab = 3
	main.tab("transfers")
	await snap("deals")
	G.ui.tr_tab = 0
	for t in ["table", "fixtures", "stats", "finances", "board", "inbox", "jobs", "training", "scouting", "comps", "campus", "trophies"]:
		main.open(t, {"lg": G.uc().lg})
		await snap(t)
		main.back()
	main.open("comps", {"id": "ucl"})
	await snap("comp_ucl")
	main.back()
	main.open("board")
	main.stack[-1].sc.scroll_vertical = 600
	await snap("board2")
	main.back()
	main.open("clubview", {"cid": 3})
	await snap("clubview")
	main.back()
	main.open("inbox")
	main.stack[-1]._open(G.s.inbox[0])
	await snap("inbox_msg")
	main.close_sheet()
	if "review" in OS.get_cmdline_user_args():
		var guard = 0
		while G.s.review == null and guard < 80:
			guard += 1
			var f = G.user_fixture_today()
			if f != null:
				G.auto_pick(G.uc())
				G.sim_fixture(f)
				G.play_day_fixtures()
			G.s.user.sacked = false
			G.advance()
		main.root("home")
		await snap("review")
		main.stack[-1].sc.scroll_vertical = 900
		await snap("review2")
	main.get_tree().quit()

extends RefCounted
# Game check. Visits every page a player can reach and reports, for each one: script errors, how long it took
# to build, whether anything is pushed off the screen, whether it needs scrolling, and very small text.
# Then checks the save data and plays a stretch of the season to catch errors in the day-to-day code.
#   xvfb-run godot --path . -- --audit [days=40] [notch=70]      report: /tmp/audit.txt

var main: Node
var rows: Array = []
var out: Array = []


func say(line: String):
	out.append(line)
	print("AUDIT ", line)


func _walk(n: Node, vis: Callable):
	if n is CanvasItem and not n.visible:
		return
	vis.call(n)
	for ch in n.get_children():
		_walk(ch, vis)


func _in_scroll(n: Node) -> bool:
	var p = n.get_parent()
	while p != null:
		if p is ScrollContainer or (p is Control and p.clip_contents):
			return true
		p = p.get_parent()
	return false


func check(label: String, ms: float, errs_before: int):
	await main.get_tree().process_frame
	await main.get_tree().process_frame
	var vs: Vector2 = main.size
	var res = {"name": label, "ms": ms, "nodes": 0, "off": 0, "off_ex": "", "scroll": 0, "tiny": 0, "errs": G.errlog.total - errs_before, "lap": 0, "lap_ex": ""}
	var scr = main.stack[-1] if main.stack.size() > 0 else main
	var taps = []
	_walk(scr, func(n):
		res.nodes += 1
		if n is Control and n.has_meta("tap") and n.size.x > 4 and n.size.y > 4:
			var tr: Rect2 = n.get_global_rect()
			if tr.position.x < vs.x and tr.position.y < vs.y and tr.end.x > 0 and tr.end.y > 0:
				taps.append([n, tr])
		if n is ScrollContainer:
			var sb = n.get_v_scroll_bar()
			var extra = sb.max_value - n.size.y
			if extra > 6.0:
				res.scroll = max(res.scroll, int(extra))
		elif n is Label:
			if n.get_theme_font_size("font_size") < 14 and n.text.strip_edges() != "":
				res.tiny += 1
			if not _in_scroll(n) and n.text.strip_edges() != "":
				var r: Rect2 = n.get_global_rect()
				if r.end.x > vs.x + 3.0 or r.end.y > vs.y + 3.0 or r.position.x < -3.0:
					res.off += 1
					if res.off_ex == "":
						res.off_ex = n.text.substr(0, 28))
	# buttons that sit on top of each other (neither inside the other)
	for i in taps.size():
		for j in range(i + 1, taps.size()):
			var a: Rect2 = taps[i][1]
			var b: Rect2 = taps[j][1]
			if not a.intersects(b):
				continue
			if taps[i][0].is_ancestor_of(taps[j][0]) or taps[j][0].is_ancestor_of(taps[i][0]):
				continue
			var inter = a.intersection(b)
			if inter.get_area() > 0.2 * min(a.get_area(), b.get_area()):
				res.lap += 1
				if res.lap_ex == "":
					res.lap_ex = "%s / %s" % [_txt(taps[i][0]), _txt(taps[j][0])]
	rows.append(res)


func _txt(n: Node) -> String:
	if n is Label and n.text.strip_edges() != "":
		return n.text.substr(0, 18)
	for ch in n.get_children():
		var t = _txt(ch)
		if t != "":
			return t
	return ""


func visit(label: String, fn: Callable):
	var e0 = G.errlog.total
	var t0 = Time.get_ticks_usec()
	fn.call()
	var ms = (Time.get_ticks_usec() - t0) / 1000.0
	await check(label, ms, e0)


func run(m):
	main = m
	var days = 40
	for a in OS.get_cmdline_user_args():
		if a.begins_with("days="):
			days = int(a.substr(5))
	G.new_game("Auditor", 1)
	main.root("home")
	await main.get_tree().process_frame
	# 1. every page reachable from the rail menus
	await visit("Home", func(): main.root("home"))
	await visit("Inbox", func(): main.root("inbox"))
	for key in ["club", "manager", "world", "search", "options"]:
		var items = main.menu_items(key)
		for it in items:
			if it[1] in ["Exit to Menu", "Save Game", "Editor"]:
				continue
			await visit("%s > %s" % [key, it[1]], it[3])
			main.close_menu()
			if main.sheet_node != null:
				main.close_sheet()
	# 2. pages with tabs or states of their own
	main.root("tactics")
	for i in 6:
		await visit("Tactics tab %d" % (i + 1), func():
			main.stack[-1].tab = i
			main.stack[-1].refresh())
	var pid = G.uc().players[0]
	for i in 6:
		await visit("Player page %d" % (i + 1), func(): main.open("player", {"pid": pid, "page": i}))
		main.back()
	main.root("life")
	for i in 5:
		await visit("Lifestyle tab %d" % (i + 1), func():
			main.stack[-1].tab = i
			main.stack[-1].pick = -1
			main.stack[-1].refresh())
	await visit("Settings", func(): main.root("settings", {"grp": "options"}))
	await visit("Kit & Sponsors", func(): main.root("kit"))
	await visit("Calendar", func(): main.root("calendar"))
	main.travel_menu()
	await check("Move-on menu", 0.0, G.errlog.total)
	main.close_sheet()
	G.TC.plans_init(G.uc())
	G.uc().plans.append({"n": "Test plan", "pr": G.make_preset(G.uc())})
	main.root("plans")
	for i in 4:
		await visit("Plans tab %d" % (i + 1), func():
			main.stack[-1].tab = i
			main.stack[-1].refresh())
	await visit("Search: bargains", func(): main.root("search", {"list": "bargains", "grp": "search"}))
	for i in 3:
		await visit("Search: customise %d" % (i + 1), func():
			main.stack[-1].cust = true
			main.stack[-1].ctab = i
			main.stack[-1].refresh())
	await visit("My Home 3D", func(): main.root("home3d"))
	for i in 5:
		await visit("My Home room %d" % (i + 1), func():
			main.stack[-1].room = i
			main.stack[-1].refresh())
	await visit("Club City 3D", func(): main.root("city3d"))
	await visit("Club City classic", func(): main.root("campus"))
	# 3. a match day
	for i in 10:
		if G.user_fixture_today() != null:
			break
		G.advance()
	if G.user_fixture_today() != null:
		await visit("Match: pre-match", func(): main.root("match", {"fx": G.user_fixture_today()}))
		var ms = main.stack[-1]
		await visit("Match: live (3D)", func(): ms._kickoff())
		await visit("Match: sim to half-time", func(): ms._sim_to(45, false))
		main.close_sheet()
		await visit("Match: live tactics", func(): ms._open_tactics())
		main.back()
		await visit("Match: shouts", func(): ms._team_sheet())
		main.close_sheet()
		ms._resume_ht(0)
		var e0 = G.errlog.total
		ms._skip()
		await check("Match: full time", 0.0, e0)
		ms._finish()
	# 4. play on, opening the main pages now and then
	var e1 = G.errlog.total
	var t1 = Time.get_ticks_msec()
	var played = 0
	for d in days:
		if G.s.user.sacked:
			break
		if G.user_fixture_today() != null:
			var sim = G.new_sim(G.user_fixture_today(), false)
			sim.sd[0].auto = true
			sim.sd[1].auto = true
			sim.run_to_end()
			G.apply_match(sim)
			played += 1
		G.s.review = null
		G.advance()
		if d % 10 == 5:
			main.root("home")
			await main.get_tree().process_frame
	say("Played on %d days (%d matches) in %.1f s: %d errors" % [days, played, (Time.get_ticks_msec() - t1) / 1000.0, G.errlog.total - e1])
	# 5. the save data
	var s = G.s
	var thin = 0
	var nogk = 0
	var dup = 0
	var badxi = 0
	for c in s.clubs:
		if c.players.size() < 16:
			thin += 1
		var gk = 0
		var nums = {}
		for p2 in c.players:
			var p = s.players[p2]
			if p.pos == "GK":
				gk += 1
			var nn = int(p.get("num", 0))
			if nn > 0:
				if nums.has(nn):
					dup += 1
				nums[nn] = true
		if gk == 0:
			nogk += 1
	for k in 11:
		if G.uc().xi[k] < 0:
			badxi += 1
	say("Data: %d clubs, %d players. Clubs under 16 players: %d. Clubs with no goalkeeper: %d. Duplicate shirt numbers: %d. Empty places in your XI: %d." % [s.clubs.size(), s.players.size(), thin, nogk, dup, badxi])
	say("Save size: %.1f MB in memory" % (var_to_bytes(s).size() / 1048576.0))
	# report
	var total_err = 0
	var slow = []
	var scrolls = []
	var offs = []
	var tiny = []
	var laps = []
	for r in rows:
		if r.lap > 0:
			laps.append("%s (%d, e.g. %s)" % [r.name, r.lap, r.lap_ex])
		total_err += r.errs
		if r.ms >= 120.0:
			slow.append("%s (%d ms)" % [r.name, int(r.ms)])
		if r.scroll > 0:
			scrolls.append("%s (%d px)" % [r.name, r.scroll])
		if r.off > 0:
			offs.append("%s (%d, e.g. \"%s\")" % [r.name, r.off, r.off_ex])
		if r.tiny > 0:
			tiny.append("%s (%d)" % [r.name, r.tiny])
		if r.errs > 0:
			say("ERRORS on %s: %d" % [r.name, r.errs])
	say("Pages visited: %d. Pages with script errors: %d total errors." % [rows.size(), total_err])
	say("Slow to open (120 ms or more): %s" % (", ".join(slow) if not slow.is_empty() else "none"))
	say("Need scrolling: %s" % (", ".join(scrolls) if not scrolls.is_empty() else "none"))
	say("Text pushed off screen: %s" % (", ".join(offs) if not offs.is_empty() else "none"))
	say("Text under 14 px: %s" % (", ".join(tiny) if not tiny.is_empty() else "none"))
	say("Buttons overlapping: %s" % (", ".join(laps) if not laps.is_empty() else "none"))
	for e in G.errlog.snapshot().slice(0, 12):
		say("LOG " + e)
	var f = FileAccess.open("/tmp/audit.txt", FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(out))
	main.get_tree().quit()

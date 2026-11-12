extends "res://scripts/screens/screen.gd"
# Job market. Also shown (forced) after being sacked.

var sel := -1


func build():
	var s = G.s
	var u = s.user
	var sacked = args.get("sacked", false)
	if sacked:
		body.add_child(UI.topbar("Sacked", false))
	else:
		body.add_child(UI.topbar("Job market"))
	if sacked:
		if u.jobs.size() == 0:
			G.refresh_jobs()
		if u.jobs.size() == 0:
			var all = []
			for c in s.clubs:
				if c.id != u.club and c.rep < G.uc().rep:
					all.append(c.id)
			all.shuffle()
			u.jobs = all.slice(0, 4)
	UI.main.t_sub = "%d club%s interested · your reputation %d" % [u.jobs.size(), "" if u.jobs.size() == 1 else "s", int(u.rep)]
	var h = panes(10, 20)
	var a = pane(0, 2)
	a[0].size_flags_stretch_ratio = 1.3
	h.add_child(a[0])
	var v = a[1]
	if sacked:
		var card = UI.panel(Color(UI.RED, 0.1), 12, 14, 10, Color(UI.RED, 0.35))
		var cv = UI.vb(2)
		cv.add_child(UI.lbl("YOU HAVE BEEN DISMISSED", 26, UI.RED, "xbold"))
		cv.add_child(UI.wrap("The board of %s has lost patience. Your career is not over — these clubs would like to talk." % G.uc().name, 18, UI.TEXT))
		card.add_child(cv)
		v.add_child(card)
	else:
		v.add_child(UI.wrap("Clubs interested in you. Taking a job means leaving %s at once." % G.uc().name, 17, UI.MUTED))
	if u.jobs.size() == 0:
		v.add_child(UI.wrap("No clubs are interested right now. Build your reputation and check back later.", 19, UI.DIM))
		return
	if sel < 0 or not (sel in u.jobs):
		sel = u.jobs[0]
	var w = [28, 0, 150, -40, -40, -74]
	v.add_child(UI.trow(["", "Club", "League", "Pos", "Rep", "Budget"], w, {"head": true}))
	for i in u.jobs.size():
		var c = s.clubs[u.jobs[i]]
		var cid = c.id
		v.add_child(UI.trow([UI.badge(c, 24), c.name, s.leagues[c.lg].name, G.LG.ordinal(G.LG.position(c.id)), int(round(c.rep)), G.money(c.budget)], w,
			{"hi": cid == sel, "alt": i % 2 == 0, "cols": {2: UI.MUTED, 5: UI.GREEN}, "tap": func():
				sel = cid
				refresh()}))
	var b = pane(0, 5)
	h.add_child(b[0])
	v = b[1]
	var c2 = s.clubs[sel]
	var hh = UI.hb(12)
	hh.add_child(UI.badge(c2, 60))
	var tv = UI.vb(-2)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(UI.lbl_fill(c2.name.to_upper(), 26, UI.TEXT, "xbold"))
	tv.add_child(UI.lbl_fill("%s · %s" % [s.leagues[c2.lg].name, s.leagues[c2.lg].country], 17, UI.MUTED))
	tv.add_child(UI.stars(c2.rep, 16))
	hh.add_child(tv)
	v.add_child(hh)
	var best = null
	var tot = 0.0
	for pid in c2.players:
		var p = s.players[pid]
		tot += G.age(p)
		if best == null or p.ovr > best.ovr:
			best = p
	v.add_child(UI.kv("Board objective", G.LG.objective(c2).text))
	v.add_child(UI.kv("League position", G.LG.ordinal(G.LG.position(c2.id))))
	v.add_child(UI.kv("Transfer budget", G.money(c2.budget), UI.GREEN))
	v.add_child(UI.kv("Wage budget", "%s/wk" % G.money(c2.wage_budget)))
	v.add_child(UI.kv("Squad", "%d players · average age %.1f" % [c2.players.size(), tot / max(1, c2.players.size())]))
	if best != null:
		v.add_child(UI.kv("Best player", "%s (%d)" % [G.pname(best), best.ovr]))
	v.add_child(UI.kv("Stadium", c2.stadium if c2.stadium != "" else "—"))
	v.add_child(UI.kv("Compared with %s" % G.uc().short, "%+d reputation" % int(round(c2.rep - G.uc().rep)), UI.GREEN if c2.rep >= G.uc().rep else UI.AMBER))
	var bh = UI.hb(8)
	var jb = UI.btn("Accept job", func(): _take(sel), "primary", "briefcase", 54)
	jb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bh.add_child(jb)
	bh.add_child(UI.btn("View squad", func(): UI.main.open("clubview", {"cid": sel}), "secondary", "users", 54))
	v.add_child(bh)


func _take(cid: int):
	var c = G.s.clubs[cid]
	if args.get("sacked", false):
		G.take_job(cid)
		UI.main.root("home")
		return
	UI.confirm("Join %s?" % c.name, "You will resign from %s and take charge of %s straight away." % [G.uc().name, c.name], "Sign contract", func():
		G.take_job(cid)
		UI.main.root("home"))

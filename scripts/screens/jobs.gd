extends "res://scripts/screens/screen.gd"
# Job market. Also shown (forced) after being sacked.


func build():
	var s = G.s
	var u = s.user
	var sacked = args.get("sacked", false)
	if sacked:
		body.add_child(UI.topbar("Sacked", false))
	else:
		body.add_child(UI.topbar("Job market"))
	var v = content(12)
	if sacked:
		var card = UI.panel(Color(UI.RED, 0.1), 24, 22, 20, Color(UI.RED, 0.35))
		var cv = UI.vb(8)
		cv.add_child(UI.lbl("YOU HAVE BEEN DISMISSED", 40, UI.RED, "xbold"))
		cv.add_child(UI.wrap("The board of %s has lost patience and relieved you of your duties. Your career is not over — these clubs would like to talk." % G.uc().name, 23, UI.TEXT))
		card.add_child(cv)
		v.add_child(card)
		if u.jobs.size() == 0:
			G.refresh_jobs()
		if u.jobs.size() == 0:
			var all = []
			for c in s.clubs:
				if c.id != u.club and c.rep < G.uc().rep:
					all.append(c.id)
			all.shuffle()
			u.jobs = all.slice(0, 4)
	else:
		v.add_child(UI.wrap("Clubs currently interested in your services. Taking a new job means leaving %s immediately." % G.uc().name, 23, UI.MUTED))
	if u.jobs.size() == 0:
		v.add_child(UI.wrap("No clubs are interested right now. Build your reputation and check back later.", 23, UI.DIM))
	for cid in u.jobs:
		var c = s.clubs[cid]
		var r = UI.card()
		var rv = UI.vb(12)
		var h = UI.hb(16)
		h.add_child(UI.badge(c, 72))
		var tv = UI.vb(2)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UI.lbl_fill(c.name.to_upper(), 30, UI.TEXT, "disp"))
		tv.add_child(UI.lbl_fill("%s · %s" % [s.leagues[c.lg].name, G.LG.ordinal(G.LG.position(c.id))], 21, UI.MUTED))
		tv.add_child(UI.stars(c.rep, 18))
		h.add_child(tv)
		h.add_child(UI.ovr(int(round(c.rep)), 28))
		rv.add_child(h)
		rv.add_child(UI.kv("Objective", G.LG.objective(c).text))
		rv.add_child(UI.kv("Transfer budget", G.money(c.budget), UI.GREEN))
		rv.add_child(UI.btn("Accept job", func(): _take(cid), "primary" if sacked else "secondary", "briefcase", 72))
		r.add_child(rv)
		v.add_child(r)


func _take(cid: int):
	var c = G.s.clubs[cid]
	if args.get("sacked", false):
		G.take_job(cid)
		UI.main.root("home")
		return
	UI.confirm("Join %s?" % c.name, "You will resign from %s and take charge of %s straight away." % [G.uc().name, c.name], "Sign contract", func():
		G.take_job(cid)
		UI.main.root("home"))

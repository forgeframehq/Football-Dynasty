extends "res://scripts/screens/screen.gd"
# Board room: the objective and confidence, the manager's profile and attributes, and the career record.


func build():
	backdrop("boardroom", 0.84)
	var s = G.s
	var u = s.user
	var c = G.uc()
	body.add_child(UI.topbar("Board room"))
	var pos = G.LG.position(c.id)
	var fans = float(u.get("fans", 55.0))
	UI.main.t_sub = "Board %d%% · supporters %d%% · %s in the %s" % [int(u.conf), int(fans), G.LG.ordinal(pos), s.leagues[c.lg].name]
	var h = panes(10, 20)

	# objective and confidence
	var a = pane(320, 5)
	h.add_child(a[0])
	var v = a[1]
	v.add_child(UI.caps("Season objective", 15, UI.accent))
	v.add_child(UI.wrap(u.obj.text, 28, UI.TEXT, "xbold"))
	var on_track = pos <= u.obj.target
	v.add_child(UI.wrap("Target: %s or better. Now %s, %s." % [G.LG.ordinal(u.obj.target), G.LG.ordinal(pos), "on track" if on_track else "behind target"], 16, UI.GREEN if on_track else UI.AMBER))
	var ch = UI.hb(8)
	ch.add_child(UI.caps("Board confidence", 15, UI.MUTED))
	ch.add_child(UI.sp())
	ch.add_child(UI.lbl("%d%%" % int(u.conf), 22, UI.cond_color(u.conf + 20), "disp"))
	v.add_child(ch)
	v.add_child(UI.bar(u.conf / 100.0, UI.cond_color(u.conf + 20), 10))
	var mood = "The board is delighted with your work."
	if u.conf < 20: mood = "Your job is hanging by a thread. Results must improve at once."
	elif u.conf < 40: mood = "The board is concerned about recent results."
	elif u.conf < 65: mood = "The board is satisfied with your progress."
	elif u.conf < 85: mood = "The board is pleased with how things are going."
	v.add_child(UI.wrap(mood, 16, UI.MUTED))
	var fh = UI.hb(8)
	fh.add_child(UI.caps("Supporters", 15, UI.MUTED))
	fh.add_child(UI.sp())
	fh.add_child(UI.lbl("%d%%" % int(fans), 22, UI.cond_color(fans + 20), "disp"))
	v.add_child(fh)
	v.add_child(UI.bar(fans / 100.0, UI.cond_color(fans + 20), 10))
	v.add_child(UI.divider())
	v.add_child(UI.kv("League record", "%dW %dD %dL · %d pts" % [c.t.w, c.t.d, c.t.l, c.t.pts], UI.TEXT, 16))
	v.add_child(UI.kv("Transfer budget", G.money(c.budget), UI.GREEN, 16))
	v.add_child(UI.kv("Your salary", "%s a week" % G.money(G.OPS.salary()), UI.TEXT, 16))
	var bh = UI.hb(6)
	bh.add_child(UI.btn("Board request", func(): UI.main.open("hub", {"kind": "request", "grp": "manager"}), "primary", "", 44))
	bh.add_child(UI.btn("My contract", func(): UI.main.open("hub", {"kind": "contract", "grp": "manager"}), "secondary", "", 44))
	for x in bh.get_children():
		x.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(bh)

	# manager
	var b = pane(0, 4)
	h.add_child(b[0])
	v = b[1]
	var mh = UI.hb(10)
	mh.add_child(UI.flag(u.nat, 34))
	var nv = UI.vb(-2)
	nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nv.add_child(UI.lbl_fill(u.name, 24, UI.TEXT, "disp"))
	nv.add_child(UI.lbl_fill("%s · %s · ex %s" % [u.nat, G.OPS.BADGES[u.badge], G.OPS.BACKGROUNDS[u.bg].to_lower()], 15, UI.MUTED))
	mh.add_child(nv)
	mh.add_child(UI.stars(50.0 + u.rep * 0.4, 16))
	v.add_child(mh)
	var w = [0, 0, 0, 0, 0, 0]
	v.add_child(UI.trow(["Games", "Won", "Drawn", "Lost", "Win %", "Rep"], w, {"head": true}))
	v.add_child(UI.trow([u.p, u.w, u.d, u.l, "%d%%" % int(100.0 * u.w / max(1, u.p)), int(u.rep)], w, {"size": 20, "alt": true, "cols": {1: UI.GREEN, 3: UI.RED}}))
	v.add_child(UI.caps("Coaching attributes" + (" · %d point%s to spend" % [u.points, "" if u.points == 1 else "s"] if u.points > 0 else ""), 15, UI.accent))
	for m in G.OPS.MATTR:
		var r = UI.panel(Color(1, 1, 1, 0.03), 8, 10, 4)
		var rh = UI.hb(10)
		var tv = UI.vb(-3)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UI.lbl(m[1], 18, UI.TEXT, "semi"))
		tv.add_child(UI.lbl_fill(m[2], 13, UI.DIM))
		rh.add_child(tv)
		rh.add_child(UI.lbl(str(u.attr[m[0]]), 26, UI.ovr_color(50 + u.attr[m[0]] * 2), "xbold"))
		if u.points > 0 and u.attr[m[0]] < 20:
			var plus = UI.panel(UI.accent, 10, 10, 6)
			plus.add_child(UI.icon("plus", 20, UI.on_color(UI.accent)))
			var key = m[0]
			UI.tap(plus, func():
				u.attr[key] += 1
				u.points -= 1
				refresh(), true)
			rh.add_child(plus)
		r.add_child(rh)
		v.add_child(r)
	if u.badge < 4:
		var days = 120 + u.badge * 30
		if u.get("study", 0) > 0:
			v.add_child(UI.kv("Studying for %s" % G.OPS.BADGES[u.badge + 1], "%d days left" % max(1, u.study - s.day), UI.accent, 17))
		else:
			v.add_child(UI.btn("Study for %s · %d days" % [G.OPS.BADGES[u.badge + 1], days], func():
				u.study = s.day + days
				UI.toast("Course booked: %d days" % days, UI.GREEN)
				refresh(), "secondary", "graduation-cap", 44))
			v.add_child(UI.lbl("Passing earns 3 attribute points and reputation.", 13, UI.DIM))
	else:
		v.add_child(UI.kv("Coaching badge", "UEFA Pro, the highest", UI.GOLD, 17))

	# record
	var d = pane(0, 2)
	h.add_child(d[0])
	v = d[1]
	v.add_child(UI.caps("Career history", 15, UI.accent))
	var w2 = [64, 0, -44, -26, -26, -26, -36]
	v.add_child(UI.trow(["Season", "Club", "Pos", "W", "D", "L", "Pts"], w2, {"head": true}))
	v.add_child(UI.trow([G.season_name(), c.name, G.LG.ordinal(pos), c.t.w, c.t.d, c.t.l, c.t.pts], w2, {"size": 17, "hi": true, "pad": 3, "cols": {0: UI.accent}}))
	for i in s.history.size():
		var hr = s.history[s.history.size() - 1 - i]
		v.add_child(UI.trow([G.season_name(hr.season), hr.club, G.LG.ordinal(hr.pos), hr.w, hr.d, hr.l, hr.pts], w2,
			{"size": 17, "alt": i % 2 == 0, "pad": 3, "cols": {0: UI.MUTED, 2: UI.GOLD if hr.pos == 1 else UI.TEXT}}))
		if hr.note != "":
			v.add_child(UI.lbl_fill("      " + hr.note, 13, UI.DIM))
	v.add_child(UI.caps("Trophy cabinet · %d" % u.trophies.size(), 15, UI.accent))
	if u.trophies.is_empty():
		v.add_child(UI.lbl("Nothing yet. The first one is the hardest.", 15, UI.DIM))
	for i in u.trophies.size():
		v.add_child(UI.trow([UI.icon("trophy", 18, UI.GOLD), u.trophies[i]], [22, 0], {"size": 17, "alt": i % 2 == 0, "pad": 3, "cols": {1: UI.GOLD}}))
	if u.trophies.size() > 0:
		v.add_child(UI.btn("Trophy room", func(): UI.main.open("trophies"), "ghost", "", 40))
	if s.champs.size() > 0:
		v.add_child(UI.caps("Past champions", 15, UI.accent))
		for i in s.champs.size():
			var ch2 = s.champs[s.champs.size() - 1 - i]
			for l in s.leagues:
				if l.tier == 1 and ch2.c.has(l.id):
					v.add_child(UI.trow([G.season_name(ch2.season), l.name, ch2.c[l.id]], [64, 0, 0], {"size": 16, "pad": 2, "alt": i % 2 == 0, "cols": {0: UI.MUTED, 1: UI.MUTED}}))

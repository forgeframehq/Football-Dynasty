extends "res://scripts/screens/screen.gd"
# Deadline day, hour by hour: the clock, your own business, and the ticker of deals going through.


func build():
	var s = G.s
	var c = G.uc()
	var d = G.MK.dd()
	body.add_child(UI.topbar("Deadline day"))
	if d.is_empty():
		UI.main.t_sub = "The window is not closing today"
		var v0 = content(10)
		v0.add_child(UI.wrap("Deadline day is the last day of each transfer window: 31 August and 31 January. Come back then.", 21, UI.MUTED))
		return
	var hour = int(d.hour)
	var shut = hour >= 23
	UI.main.t_sub = "%s · %d deals done so far" % ["The window is shut" if shut else "%d hours to go" % (23 - hour), int(d.deals)]
	var h = panes(10, 20)

	var a = pane(330, 6)
	h.add_child(a[0])
	var v = a[1]
	var clock = UI.lbl("%02d:00" % hour, 76, UI.RED if hour >= 21 else (UI.AMBER if hour >= 18 else UI.TEXT), "xbold")
	clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(clock)
	v.add_child(UI.bar((hour - 9) / 14.0, UI.RED if hour >= 21 else UI.accent, 8))
	var cap = UI.caps("Window closes at 23:00" if not shut else "Window closed", 15, UI.MUTED)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(cap)
	if not shut:
		v.add_child(UI.btn("Next hour", func():
			G.MK.dd_hour()
			UI.sfx("message")
			refresh(), "primary", "fast-forward", 54))
	else:
		v.add_child(UI.btn("Done", func(): UI.main.root("home"), "gold", "check", 54))
	v.add_child(UI.divider())
	v.add_child(UI.kv("Transfer budget", G.money(c.budget), UI.GREEN, 17))
	v.add_child(UI.kv("Wage room", "%s/wk" % G.money(c.wage_budget - G.squad_wages(c)), UI.TEXT, 17))
	v.add_child(UI.caps("Your business", 15, UI.accent))
	var any = false
	for dl in G.DL.active():
		if dl.mode != "buy":
			continue
		any = true
		var p = s.players[dl.pid]
		var pid = dl.pid
		var txt = {"new": "Not approached", "club": "Fee talks open", "deleg": "Assistant talking", "meet": "Fee agreed", "talks": "Agree terms now"}.get(dl.stage, "")
		v.add_child(UI.trow([UI.ovr(p.ovr, 15), G.pname(p), txt], [34, 0, -126], {"size": 17, "pad": 3, "cols": {2: UI.GREEN if dl.stage == "talks" else UI.AMBER}, "tap": func(): UI.main.open("nego", {"pid": pid, "mode": "buy"})}))
	for o in s.offers:
		if not s.players.has(o.pid):
			continue
		any = true
		var p2 = s.players[o.pid]
		var oid = o.id
		var pid2 = o.pid
		v.add_child(UI.trow([UI.ovr(p2.ovr, 15), G.pname(p2), "%s bid %s" % [s.clubs[o.from].short, G.money(o.fee)]], [34, 0, -150], {"size": 17, "pad": 3, "cols": {2: UI.GREEN}, "tap": func(): UI.main.open("nego", {"pid": pid2, "mode": "sell", "oid": oid})}))
	if not any:
		v.add_child(UI.lbl_fill("No deals in progress.", 15, UI.DIM))
	var bh = UI.hb(6)
	bh.add_child(UI.btn("Search", func(): UI.main.open("search"), "secondary", "", 42))
	bh.add_child(UI.btn("Transfers", func(): UI.main.open("transfers"), "ghost", "", 42))
	for x in bh.get_children():
		x.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(bh)

	var b = pane(0, 3)
	h.add_child(b[0])
	v = b[1]
	v.add_child(UI.caps("Live", 15, UI.accent))
	for i in d.feed.size():
		var e = d.feed[i]
		var col = {"deal": UI.TEXT, "you": UI.GOLD, "end": UI.RED, "info": UI.MUTED}.get(e[2], UI.MUTED)
		var r = UI.panel(Color(UI.GOLD, 0.1) if e[2] == "you" else Color(1, 1, 1, 0.045 if i % 2 == 0 else 0.02), 6, 10, 5)
		var rh = UI.hb(10)
		var tl = UI.lbl(e[0], 16, UI.DIM, "disp")
		tl.custom_minimum_size = Vector2(52, 0)
		tl.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		rh.add_child(tl)
		rh.add_child(UI.wrap(e[1], 17, col))
		r.add_child(rh)
		v.add_child(r)

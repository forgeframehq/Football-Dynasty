extends "res://scripts/screens/screen.gd"
# Calendar: the month at a glance with matches and key dates; tap a day to see it and sim to it.

var ym := -1            # year * 12 + month - 1 being shown
var sel := -1           # selected day number


func build():
	var s = G.s
	var c = G.uc()
	if ym < 0:
		ym = G.cur.year * 12 + G.cur.month - 1
		sel = s.day
	var yr = ym / 12
	var mo = ym % 12 + 1
	UI.main.t_title = "Calendar"
	UI.main.t_sub = "%s %d · tap a day, then sim to it" % [G.MONTHS_FULL[mo - 1], yr]
	var h = panes(10, 20)
	var a = pane(0, 4)
	a[0].size_flags_stretch_ratio = 2.3
	h.add_child(a[0])
	var v = a[1]
	var top = UI.hb(8)
	top.add_child(UI.seg(["Calendar", "Fixtures"], 0, func(i):
		if i == 1:
			UI.main.root("fixtures"), 15, 6))
	top.add_child(UI.sp())
	var nav = func(d: int):
		ym += d
		refresh()
	var pb = UI.panel(Color(1, 1, 1, 0.07), 10, 12, 5)
	pb.add_child(UI.icon("chevron-left", 22, UI.TEXT))
	UI.tap(pb, func(): nav.call(-1), true)
	top.add_child(pb)
	var ml = UI.lbl("%s %d" % [G.MONTHS_FULL[mo - 1].to_upper(), yr], 22, UI.TEXT, "disp")
	ml.custom_minimum_size = Vector2(190, 0)
	ml.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(ml)
	var nb = UI.panel(Color(1, 1, 1, 0.07), 10, 12, 5)
	nb.add_child(UI.icon("chevron-right", 22, UI.TEXT))
	UI.tap(nb, func(): nav.call(1), true)
	top.add_child(nb)
	var tb = UI.panel(Color(UI.accent, 0.18), 10, 12, 5)
	tb.add_child(UI.caps("Today", 15, UI.accent))
	UI.tap(tb, func():
		ym = G.cur.year * 12 + G.cur.month - 1
		sel = G.s.day
		refresh(), true)
	top.add_child(tb)
	v.add_child(top)
	var wk = UI.hb(4)
	for n in ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]:
		var l = UI.caps(n, 14, UI.DIM)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		wk.add_child(l)
	v.add_child(wk)
	var first = G.ymd(yr, mo, 1)
	var nxt = G.ymd(yr + (1 if mo == 12 else 0), 1 if mo == 12 else mo + 1, 1)
	var lead = posmod(int(G.date(first).weekday) - 1, 7)
	var mine = {}
	for f in G.club_fixtures(c.id):
		mine[int(f.day)] = f
	var rows = int(ceil((lead + nxt - first) / 7.0))
	var grid = UI.vb(4)
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for r in rows:
		var row = UI.hb(4)
		row.size_flags_vertical = Control.SIZE_EXPAND_FILL
		for k in 7:
			var dy = first - lead + r * 7 + k
			var cl = _cell(dy, dy >= first and dy < nxt, mine.get(dy), c)
			cl.custom_minimum_size = Vector2(0, floor(432.0 / rows) - 4)
			row.add_child(cl)
		grid.add_child(row)
	v.add_child(grid)
	var b = pane(0, 6)
	h.add_child(b[0])
	_detail(b[1], mine.get(sel), c)


func _cell(dy: int, inm: bool, f, c: Dictionary) -> Control:
	var s = G.s
	var today = dy == s.day
	var p = UI.panel(Color(UI.accent, 0.2) if dy == sel else Color(1, 1, 1, 0.045 if inm else 0.015), 8, 5, 2, UI.accent if today else Color(0, 0, 0, 0))
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	p.clip_contents = true
	var v = UI.vb(-3)
	var d = G.date(dy)
	var top = UI.hb(3)
	top.add_child(UI.lbl(str(d.day), 18, (UI.accent if today else UI.TEXT) if inm else UI.DIM, "disp"))
	top.add_child(UI.sp())
	var kd = key_dates(dy)
	if not kd.is_empty():
		top.add_child(UI.icon(kd[0][0], 16, kd[0][2]))
	v.add_child(top)
	if f != null:
		var home = f.h == c.id
		var oc = s.clubs[f.a if home else f.h]
		var r = UI.hb(3)
		r.add_child(UI.badge(oc, 24))
		var col = UI.TEXT
		var txt = "%s %s" % [oc.short, "H" if home else "A"]
		if f.played:
			var us = f.hg if home else f.ag
			var th = f.ag if home else f.hg
			col = UI.GREEN if us > th else (UI.RED if us < th else UI.MUTED)
			txt = "%s %d-%d" % [oc.short, us, th]
		var l = UI.lbl_fill(txt, 17, col, "semi")
		r.add_child(l)
		v.add_child(r)
	elif not kd.is_empty():
		v.add_child(UI.lbl_fill(kd[0][1], 14, kd[0][2]))
	p.add_child(v)
	p.modulate.a = 1.0 if dy >= s.day or f != null else 0.55
	UI.tap(p, func():
		sel = dy
		refresh(), true)
	return p


static func key_dates(dy: int) -> Array:
	# [icon, short text, colour] for the fixed dates of the football year
	var d = G.date(dy)
	var a = []
	if (d.month == 8 or d.month == 1) and d.day == 31:
		a.append(["clock", "Deadline day", UI.RED])
	if (d.month == 6 and d.day == 12) or (d.month == 1 and d.day == 1):
		a.append(["door-open", "Window opens", UI.GREEN])
	if d.day == 1 and d.month >= 9 or d.day == 1 and d.month <= 5:
		if not (d.month == 1):
			a.append(["trending-up", "Player progress", UI.accent])
	if d.weekday == 1:
		a.append(["banknote", "Weekly money", UI.DIM])
	if d.day == 15:
		a.append(["briefcase", "Job market", UI.DIM])
	return a


func _detail(v: VBoxContainer, f, c: Dictionary):
	var s = G.s
	var d = G.date(sel)
	v.add_child(UI.caps(["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][d.weekday], 15, UI.accent))
	v.add_child(UI.lbl("%d %s %d" % [d.day, G.MONTHS_FULL[d.month - 1], d.year], 28, UI.TEXT, "xbold"))
	var gap = sel - s.day
	v.add_child(UI.lbl_fill("Today" if gap == 0 else ("In %d day%s" % [gap, "" if gap == 1 else "s"] if gap > 0 else "%d day%s ago" % [-gap, "" if gap == -1 else "s"]), 17, UI.MUTED))
	if f != null:
		var home = f.h == c.id
		var oc = s.clubs[f.a if home else f.h]
		var card = UI.panel(Color(1, 1, 1, 0.05), 12, 12, 8)
		var cv = UI.vb(2)
		cv.add_child(UI.caps(G.fx_caption(f), 14, UI.DIM))
		var r = UI.hb(8)
		r.add_child(UI.badge(oc, 40))
		var tv = UI.vb(-4)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UI.lbl_fill(oc.name, 22, UI.TEXT, "disp"))
		tv.add_child(UI.lbl_fill("%s · %s in the table" % ["Home" if home else "Away", G.LG.ordinal(G.LG.position(oc.id))], 15, UI.MUTED))
		r.add_child(tv)
		if f.played:
			r.add_child(UI.lbl("%d - %d" % [f.hg, f.ag], 26, UI.TEXT, "xbold"))
		cv.add_child(r)
		card.add_child(cv)
		UI.tap(card, func(): UI.main.open("clubview", {"club": oc.id}), true)
		v.add_child(card)
	for k in key_dates(sel):
		var r2 = UI.hb(8)
		r2.add_child(UI.icon(k[0], 18, k[2]))
		r2.add_child(UI.lbl_fill(k[1], 17, UI.TEXT))
		v.add_child(r2)
	# other matches that day in the user's league
	var n = 0
	if G.fx_by_day.has(sel):
		for i in G.fx_by_day[sel]:
			var o = s.fixtures[i]
			if o.h == c.id or o.a == c.id or o.lg != c.lg or n >= 5:
				continue
			if n == 0:
				v.add_child(UI.caps("Also that day", 13, UI.DIM))
			n += 1
			v.add_child(UI.lbl_fill("%s %s %s" % [s.clubs[o.h].short, ("%d-%d" % [o.hg, o.ag]) if o.played else "v", s.clubs[o.a].short], 16, UI.MUTED))
	v.add_child(UI.sp(0, 4))
	var sv = UI.sp()
	sv.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sv)
	if gap > 0 and s.review == null and not s.user.sacked:
		var stops = 0
		for dd in range(s.day, sel):
			if G.fx_by_day.has(dd):
				for i in G.fx_by_day[dd]:
					var o = s.fixtures[i]
					if not o.played and (o.h == c.id or o.a == c.id):
						stops += 1
		v.add_child(UI.wrap("You stop for every match on the way (%d) and for anything urgent." % stops if stops > 0 else "No matches on the way. You still stop for anything urgent.", 15, UI.MUTED))
		v.add_child(UI.btn("Sim to this day", func(): UI.main.travel(sel), "primary", "fast-forward", 52))
	elif gap == 0:
		v.add_child(UI.wrap("This is today. Press Continue to move on one day.", 15, UI.MUTED))

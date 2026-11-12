extends "res://scripts/screens/screen.gd"
# League table with a league switcher.

const ZONE_COL = {"cl": Color("4da3ff"), "eu": Color("f6ad3c"), "up": Color("2ee59d"), "po": Color("29c7c7"), "rpo": Color("f08a5d"), "down": Color("ff5c72"), "": Color(0, 0, 0, 0)}
const ZONE_TXT = {"cl": "Champions League", "eu": "Europe", "up": "Promotion", "po": "Play-offs", "rpo": "Relegation play-off", "down": "Relegation"}

var lg := -1


func build():
	var s = G.s
	if lg < 0:
		lg = args.get("lg", G.uc().lg)
	var l = s.leagues[lg]
	var sw = UI.panel(Color(1, 1, 1, 0.06), 18, 16, 12)
	var swh = UI.hb(6)
	swh.add_child(UI.caps("Leagues", 20, UI.TEXT))
	swh.add_child(UI.icon("chevron-right", 22, UI.MUTED))
	sw.add_child(swh)
	var on_pick = func(i):
		lg = i
		refresh()
	UI.tap(sw, func(): pick_league(on_pick), true)
	body.add_child(UI.topbar(l.name, true, sw))
	var v = content(4)
	var head = UI.hb(8)
	head.add_child(UI.sp(98, 0))
	head.add_child(UI.caps("Club", 18, UI.DIM))
	head.add_child(UI.sp())
	for hd in ["P", "W", "D", "L", "GD", "PTS"]:
		var hl = UI.caps(hd, 18, UI.DIM)
		hl.custom_minimum_size = Vector2(52 if hd == "PTS" or hd == "GD" else 36, 0)
		hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		head.add_child(hl)
	v.add_child(UI.margin(head, 14, 0, 16, 4))
	var t = G.LG.table(lg)
	var seen = []
	for i in t.size():
		var c = s.clubs[t[i]]
		var me = c.id == s.user.club
		var z = G.LG.zone_of(lg, i + 1, t.size())
		if z != "" and not (z in seen):
			seen.append(z)
		var r = UI.panel(Color(UI.accent, 0.14) if me else UI.CARD, 14, 0, 0, Color(UI.accent, 0.5) if me else UI.LINE)
		var h = UI.hb(8)
		var zb = ColorRect.new()
		zb.color = ZONE_COL[z]
		zb.custom_minimum_size = Vector2(6, 60)
		zb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(zb)
		var pn = UI.lbl(str(i + 1), 24, UI.TEXT if me else UI.MUTED, "disp")
		pn.custom_minimum_size = Vector2(34, 0)
		pn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		h.add_child(pn)
		h.add_child(UI.badge(c, 40))
		h.add_child(UI.lbl_fill(c.name, 24, UI.TEXT, "semi" if me else "body"))
		for val in [c.t.p, c.t.w, c.t.d, c.t.l]:
			var cl = UI.lbl(str(val), 22, UI.MUTED)
			cl.custom_minimum_size = Vector2(36, 0)
			cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			h.add_child(cl)
		var gd = UI.lbl("%+d" % (c.t.gf - c.t.ga), 22, UI.MUTED)
		gd.custom_minimum_size = Vector2(52, 0)
		gd.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		h.add_child(gd)
		var pts = UI.lbl(str(c.t.pts), 27, UI.TEXT, "disp")
		pts.custom_minimum_size = Vector2(52, 0)
		pts.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		h.add_child(pts)
		h.add_child(UI.sp(12, 0))
		r.add_child(h)
		var cid = c.id
		UI.tap(r, func(): UI.main.open("clubview", {"cid": cid}))
		v.add_child(r)
	v.add_child(UI.sp(0, 8))
	var legend = UI.hb(14)
	for z in seen:
		var lh = UI.hb(6)
		var dot = UI.panel(ZONE_COL[z], 6, 0, 0)
		dot.custom_minimum_size = Vector2(12, 12)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		lh.add_child(dot)
		lh.add_child(UI.caps(ZONE_TXT[z], 17, UI.MUTED))
		legend.add_child(lh)
	v.add_child(legend)


static func pick_league(cb: Callable):
	var build_sheet = func(v):
		var country = ""
		for l in G.s.leagues:
			if l.country != country:
				country = l.country
				v.add_child(UI.caps(country, 20, UI.GOLD))
			var r = UI.panel(UI.CARD, 16, 18, 14, UI.LINE)
			var h = UI.hb(10)
			h.add_child(UI.lbl_fill(l.name, 27, UI.TEXT, "disp"))
			h.add_child(UI.caps("Tier %d" % l.tier, 18, UI.DIM))
			r.add_child(h)
			var id = l.id
			UI.tap(r, func():
				UI.close_sheet()
				cb.call(id))
			v.add_child(r)
	UI.sheet("Select league", build_sheet)

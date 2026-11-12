extends "res://scripts/screens/screen.gd"
# First-team squad list.

const FILTERS = ["All", "GK", "DEF", "MID", "ATT"]
const SORTS = ["Position", "Rating", "Fitness", "Value"]
const POS_ORDER = ["GK", "CB", "LB", "RB", "CDM", "CM", "CAM", "LM", "RM", "LW", "RW", "ST"]


func _init():
	show_nav = true


func build():
	var c = G.uc()
	var st = G.ui
	var count = UI.chip("%d PLAYERS" % c.players.size(), Color(1, 1, 1, 0.06), UI.MUTED, 20)
	body.add_child(UI.topbar("Squad", false, count))
	var top = UI.vb(10)
	top.add_child(UI.seg(FILTERS, st.sq_filter, func(i):
		st.sq_filter = i
		refresh()))
	var sh = UI.hb(8)
	sh.add_child(UI.caps("Sort", 20, UI.DIM))
	for i in SORTS.size():
		var on = st.sq_sort == i
		var ch = UI.chip(SORTS[i].to_upper(), Color(UI.accent, 0.16) if on else Color(1, 1, 1, 0.04), UI.accent if on else UI.MUTED, 19)
		var idx = i
		UI.tap(ch, func():
			st.sq_sort = idx
			refresh(), true)
		sh.add_child(ch)
	top.add_child(sh)
	body.add_child(UI.margin(top, 24, 0, 24, 12))
	var v = content(8)
	var list = []
	for pid in c.players:
		var p = G.s.players[pid]
		if st.sq_filter == 0 or G.LINE[p.pos] == st.sq_filter - 1:
			list.append(p)
	match st.sq_sort:
		0: list.sort_custom(func(a, b): return POS_ORDER.find(a.pos) * 100 - a.ovr < POS_ORDER.find(b.pos) * 100 - b.ovr)
		1: list.sort_custom(func(a, b): return a.ovr > b.ovr)
		2: list.sort_custom(func(a, b): return a.cond < b.cond)
		3: list.sort_custom(func(a, b): return G.value(a) > G.value(b))
	for p in list:
		v.add_child(row(p, c))


static func row(p: Dictionary, c: Dictionary) -> Control:
	var r = UI.panel(UI.CARD, 18, 16, 12, UI.LINE)
	var h = UI.hb(14)
	h.add_child(UI.pos(p.pos))
	var v = UI.vb(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nh = UI.hb(8)
	nh.add_child(UI.lbl_fill(G.pname(p), 26, UI.TEXT, "semi"))
	v.add_child(nh)
	var mh = UI.hb(10)
	mh.add_child(UI.lbl("%d yrs" % G.age(p), 20, UI.MUTED))
	var role = "XI" if p.id in c.xi else ("SUB" if p.id in c.bench else "")
	if role != "":
		mh.add_child(UI.chip(role, Color(UI.accent, 0.14), UI.accent, 16))
	if p.inj > 0:
		mh.add_child(UI.chip("INJ " + G.inj_text(p.inj).to_upper(), Color(UI.RED, 0.14), UI.RED, 16))
	if p.susp > 0:
		mh.add_child(UI.chip("BANNED %d" % p.susp, Color(UI.RED, 0.14), UI.RED, 16))
	if p.listed:
		mh.add_child(UI.chip("LISTED", Color(UI.AMBER, 0.14), UI.AMBER, 16))
	if p.cend <= G.s.season + 1:
		mh.add_child(UI.chip("EXPIRING", Color(UI.AMBER, 0.1), UI.AMBER, 16))
	v.add_child(mh)
	h.add_child(v)
	var cv = UI.vb(4)
	cv.custom_minimum_size = Vector2(86, 0)
	cv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var cl = UI.caps("Fit %d%%" % p.cond, 17, UI.cond_color(p.cond))
	cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cv.add_child(cl)
	cv.add_child(UI.bar(p.cond / 100.0, UI.cond_color(p.cond), 6))
	h.add_child(cv)
	h.add_child(UI.ovr(p.ovr))
	r.add_child(h)
	var pid = p.id
	UI.tap(r, func(): UI.main.open("player", {"pid": pid}))
	return r

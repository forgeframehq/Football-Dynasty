extends "res://scripts/screens/screen.gd"
# The user's fixtures and results, plus a round-by-round view of any league.

var mode := 0
var lg := -1
var rd := -1


func build():
	var s = G.s
	var c = G.uc()
	if lg < 0:
		lg = c.lg
	body.add_child(UI.topbar("Fixtures"))
	body.add_child(UI.margin(UI.seg(["My club", "By round"], mode, func(i):
		mode = i
		refresh()), 24, 0, 24, 12))
	var v = content(8)
	if mode == 0:
		var next_done = false
		for f in G.club_fixtures(c.id):
			var hl = not f.played and not next_done
			if hl:
				next_done = true
			v.add_child(_row(f, c.id, hl))
		return
	var maxr = 0
	var cur_r = 1
	for f in s.fixtures:
		if f.lg == lg and not f.ko:
			maxr = max(maxr, f.rd)
			if f.played:
				cur_r = max(cur_r, f.rd)
	if rd < 0:
		rd = cur_r
	var nav = UI.hb(10)
	var prev = UI.panel(Color(1, 1, 1, 0.06), 16, 16, 12)
	prev.add_child(UI.icon("chevron-left", 28, UI.TEXT))
	UI.tap(prev, func():
		rd = max(1, rd - 1)
		refresh(), true)
	nav.add_child(prev)
	var mid = UI.panel(UI.CARD2, 16, 16, 10, Color(1, 1, 1, 0.1))
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var mv = UI.vb(-2)
	var a = UI.lbl(s.leagues[lg].name.to_upper(), 26, UI.TEXT, "disp")
	a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var b = UI.caps("Round %d of %d · tap to change league" % [rd, maxr], 17, UI.MUTED)
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mv.add_child(a)
	mv.add_child(b)
	mid.add_child(mv)
	var on_pick = func(i):
		lg = i
		rd = -1
		refresh()
	UI.tap(mid, func(): preload("res://scripts/screens/table.gd").pick_league(on_pick), true)
	nav.add_child(mid)
	var nxt = UI.panel(Color(1, 1, 1, 0.06), 16, 16, 12)
	nxt.add_child(UI.icon("chevron-right", 28, UI.TEXT))
	UI.tap(nxt, func():
		rd = min(maxr, rd + 1)
		refresh(), true)
	nav.add_child(nxt)
	v.add_child(nav)
	for f in s.fixtures:
		if f.lg == lg and f.rd == rd and not f.ko:
			v.add_child(_row(f, -1, false))
	var ko = []
	for f in s.fixtures:
		if f.ko and (f.lg == lg):
			ko.append(f)
	if ko.size() > 0:
		v.add_child(UI.section("Play-offs"))
		for f in ko:
			v.add_child(_row(f, -1, false))


func _row(f: Dictionary, cid: int, highlight: bool) -> Control:
	var s = G.s
	var hc = s.clubs[f.h]
	var ac = s.clubs[f.a]
	var r = UI.panel(UI.CARD, 16, 14, 10, Color(UI.accent, 0.6) if highlight else UI.LINE)
	var v = UI.vb(4)
	var top = UI.hb(8)
	top.add_child(UI.caps(G.fmt_date(f.day), 17, UI.DIM))
	top.add_child(UI.sp())
	top.add_child(UI.caps(f.label if f.ko else ("Round %d" % f.rd), 17, UI.DIM))
	v.add_child(top)
	var h = UI.hb(10)
	var hn = UI.lbl_fill(hc.name, 24, UI.TEXT if f.h == cid or cid < 0 else UI.MUTED, "semi" if f.h == cid else "body")
	hn.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(hn)
	h.add_child(UI.badge(hc, 36))
	var sc_text = "%d – %d" % [f.hg, f.ag] if f.played else "v"
	var col = UI.TEXT
	var bg = Color(1, 1, 1, 0.06)
	if f.played and cid >= 0:
		var mine = f.hg if f.h == cid else f.ag
		var theirs = f.ag if f.h == cid else f.hg
		col = UI.GREEN if mine > theirs else (UI.RED if mine < theirs else UI.MUTED)
		bg = Color(col, 0.12)
	var sc_chip = UI.chip(sc_text, bg, col, 26, 92)
	h.add_child(sc_chip)
	h.add_child(UI.badge(ac, 36))
	h.add_child(UI.lbl_fill(ac.name, 24, UI.TEXT if f.a == cid or cid < 0 else UI.MUTED, "semi" if f.a == cid else "body"))
	v.add_child(h)
	if f.played and f.has("pens"):
		var pl = UI.caps("Penalties %d–%d" % [f.pens[0], f.pens[1]], 17, UI.MUTED)
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(pl)
	if f.played and f.has("sc") and (f.sc[0].size() + f.sc[1].size()) > 0:
		var parts = []
		for i in 2:
			for g in f.sc[i]:
				parts.append("%s %d'" % [g[0], g[1]])
		var gl = UI.wrap(" · ".join(parts), 18, UI.DIM)
		gl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(gl)
	r.add_child(v)
	return r

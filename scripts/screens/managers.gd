extends "res://scripts/screens/screen.gd"
# Manager Watch: who is under pressure in your league (and everywhere), your rivals and your record against them,
# and the latest sackings and appointments.

var all_lg := false


func build():
	G.MG.ensure()
	var s = G.s
	var c = G.uc()
	UI.main.t_title = "Manager Watch"
	UI.main.t_sub = "Hot seats, rivals, sackings"
	var h = panes(12, 20)
	var a = pane(0, 2)
	h.add_child(a[0])
	_hot(a[1])
	var b = pane(0, 2)
	h.add_child(b[0])
	_rivals(b[1])
	var d = pane(330, 2)
	h.add_child(d[0])
	_moves(d[1])


func _hot(v: VBoxContainer):
	var s = G.s
	var c = G.uc()
	var top = UI.hb(6)
	top.add_child(UI.caps("Hot seat", 16, UI.accent))
	top.add_child(UI.sp())
	var sg = UI.seg([s.leagues[c.lg].short if s.leagues[c.lg].has("short") else "League", "Everywhere"], 1 if all_lg else 0, func(i):
		all_lg = i == 1
		refresh(), 13, 4)
	sg.custom_minimum_size = Vector2(190, 0)
	top.add_child(sg)
	v.add_child(top)
	var hs = G.MG.hot_seat(-1 if all_lg else c.lg)
	v.add_child(UI.trow(["Manager", "Pos", "Pressure"], [0, -40, 96], {"head": true, "size": 16, "pad": 1}))
	if hs.is_empty():
		v.add_child(UI.wrap("Nobody is under real pressure yet. It builds once a few matches are played.", 16, UI.DIM))
	for it in hs.slice(0, 15):
		var cid = it[0]
		var m = G.MG.of(cid)
		var nm = UI.hb(6)
		nm.add_child(UI.badge(s.clubs[cid], 22))
		var tv = UI.vb(-5)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UI.lbl_fill(G.MG.nm(m), 16, UI.TEXT, "semi"))
		tv.add_child(UI.lbl_fill(s.clubs[cid].name, 14, UI.DIM))
		nm.add_child(tv)
		var p = float(it[1])
		var col = UI.RED if p > 0.6 else (UI.AMBER if p > 0.35 else UI.MUTED)
		v.add_child(UI.trow([nm, G.LG.ordinal(G.LG.position(cid)), UI.bar(p, col, 8)], [0, -40, 96], {"size": 16, "pad": 2, "tap": func(): UI.main.open("clubview", {"cid": cid})}))


func _rivals(v: VBoxContainer):
	var s = G.s
	v.add_child(UI.caps("Your rivals", 16, UI.accent))
	var list = []
	for cid in s.mgrs:
		var m = s.mgrs[cid]
		var games = int(m.vs[0]) + int(m.vs[1]) + int(m.vs[2])
		if games > 0 or float(m.feud) >= 15:
			list.append([cid, m, games])
	list.sort_custom(func(x, y): return float(x[1].feud) * 2 + x[2] > float(y[1].feud) * 2 + y[2])
	v.add_child(UI.trow(["Manager", "W-D-L", "Feeling"], [0, -64, -96], {"head": true, "size": 16, "pad": 1}))
	if list.is_empty():
		v.add_child(UI.wrap("Play a few matches. Heavy wins, derbies and what you say in press conferences and online decide who holds a grudge.", 16, UI.DIM))
	for it in list.slice(0, 15):
		var cid = it[0]
		var m = it[1]
		var nm = UI.hb(6)
		nm.add_child(UI.badge(s.clubs[cid], 22))
		var tv = UI.vb(-5)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UI.lbl_fill(G.MG.nm(m), 16, UI.TEXT, "semi"))
		tv.add_child(UI.lbl_fill("%s · %d · since %d" % [s.clubs[cid].short, G.MG.age(m), int(m.since)], 14, UI.DIM))
		nm.add_child(tv)
		var f = float(m.feud)
		# his record against you, turned round to yours
		v.add_child(UI.trow([nm, "%d-%d-%d" % [int(m.vs[2]), int(m.vs[1]), int(m.vs[0])], G.MG.feud_word(f)], [0, -64, -96],
			{"size": 16, "pad": 2, "cols": {2: UI.RED if f >= 50 else (UI.AMBER if f >= 25 else UI.GREEN)}}))


func _moves(v: VBoxContainer):
	var s = G.s
	v.add_child(UI.caps("Sackings and appointments", 16, UI.accent))
	if s.mgr_log.is_empty():
		v.add_child(UI.wrap("No changes yet. Struggling clubs start pulling the trigger in October.", 16, UI.DIM))
	for e in s.mgr_log.slice(0, 16):
		var r = UI.hb(8)
		r.add_child(UI.icon("user-minus" if str(e.t).contains("sacked") else "user-plus", 16, UI.RED if str(e.t).contains("sacked") else UI.GREEN))
		r.add_child(UI.lbl_fill(str(e.t), 16, UI.TEXT))
		r.add_child(UI.lbl(G.fmt_date(int(e.d)).substr(4), 14, UI.DIM))
		v.add_child(r)
	v.add_child(UI.sp(0, 6))
	v.add_child(UI.caps("Out of work", 16, UI.accent))
	var fr = s.mgr_free.duplicate()
	fr.sort_custom(func(x, y): return x.rep > y.rep)
	for m in fr.slice(0, 6):
		v.add_child(UI.kv(G.MG.nm(m), "rep %d" % int(m.rep), UI.MUTED, 16))
	if fr.is_empty():
		v.add_child(UI.lbl_fill("Nobody yet.", 16, UI.DIM))

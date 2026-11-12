extends "res://scripts/screens/screen.gd"
# Fixtures and results: the club's whole season in one table with a match panel, or any league round by round.

var mode := 0
var lg := -1
var rd := -1
var sel = null
var jumped := false


func build():
	var s = G.s
	var c = G.uc()
	if lg < 0:
		lg = c.lg
	body.add_child(UI.topbar("Fixtures"))
	var h = panes(10, 20)
	var a = pane(0, 2)
	a[0].size_flags_stretch_ratio = 1.6
	h.add_child(a[0])
	sc = a[0].get_child(0)
	var v = a[1]
	v.add_child(UI.seg(["My club", "By round"], mode, func(i):
		mode = i
		sel = null
		jumped = false
		refresh(), 15))
	var b = pane(0, 4)
	h.add_child(b[0])
	if mode == 0:
		_mine(v, b[1], c)
	else:
		_rounds(v, b[1])


func _tag(f: Dictionary) -> String:
	if f.get("fr", false):
		return "Friendly"
	if f.get("comp", "") != "" or f.ko:
		return str(f.label)
	return "%s · R%d" % [G.s.leagues[f.lg].short, f.rd]


func _result(f: Dictionary, cid: int) -> Control:
	if not f.played:
		var d = UI.lbl("v" if cid < 0 else "", 15, UI.DIM)
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		d.custom_minimum_size = Vector2(58, 0)
		return d
	var col = UI.TEXT
	if cid >= 0:
		var us = f.hg if f.h == cid else f.ag
		var them = f.ag if f.h == cid else f.hg
		col = UI.GREEN if us > them else (UI.RED if us < them else UI.MUTED)
	return UI.chip("%d - %d" % [f.hg, f.ag], Color(col, 0.14) if cid >= 0 else Color(1, 1, 1, 0.07), col, 17, 58)


func _mine(v: VBoxContainer, side: VBoxContainer, c: Dictionary):
	var s = G.s
	var all = G.club_fixtures(c.id)
	var nxt = null
	var rec = [[0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0]]
	for f in all:
		if not f.played:
			if nxt == null:
				nxt = f
			continue
		if f.get("fr", false):
			continue
		var home = f.h == c.id
		var us = f.hg if home else f.ag
		var them = f.ag if home else f.hg
		var r = rec[0 if home else 1]
		r[0] += 1
		r[1 if us > them else (2 if us == them else 3)] += 1
		r[4] += us
		r[5] += them
	if sel == null:
		sel = nxt if nxt != null else (all[-1] if all.size() > 0 else null)
	var left = 0
	for f in all:
		left += 0 if f.played else 1
	UI.main.t_sub = "%d played · %d to come · tap a match for the detail" % [all.size() - left, left]
	var w = [90, 204, 18, 24, 0, 60]
	v.add_child(UI.trow(["Date", "Competition", "", "", "Opponent", "Result"], w, {"head": true}))
	var target = null
	for i in all.size():
		var f = all[i]
		var home = f.h == c.id
		var oc = s.clubs[f.a if home else f.h]
		var row = UI.trow([G.fmt_date(f.day), _tag(f), "H" if home else "A", UI.badge(oc, 22), oc.name, _result(f, c.id)], w,
			{"size": 18, "hi": is_same(f, sel), "alt": i % 2 == 0, "pad": 3, "bold": 4,
			"cols": {0: UI.accent if is_same(f, nxt) else UI.MUTED, 1: UI.MUTED, 2: UI.TEXT if home else UI.MUTED, 4: UI.MUTED if f.played and not is_same(f, sel) else UI.TEXT},
			"tap": func():
				sel = f
				refresh()})
		v.add_child(row)
		if is_same(f, nxt):
			target = row
	if not jumped:
		jumped = true
		_jump(sc, target)
	# season record and the selected match
	side.add_child(UI.caps("Record this season · friendlies not counted", 15, UI.accent))
	var w2 = [0, -30, -30, -30, -30, -34, -34]
	side.add_child(UI.trow(["", "P", "W", "D", "L", "GF", "GA"], w2, {"head": true}))
	var tot = [0, 0, 0, 0, 0, 0]
	for k in 2:
		for j in 6:
			tot[j] += rec[k][j]
		side.add_child(UI.trow([["Home", "Away"][k]] + rec[k], w2, {"size": 17, "alt": k == 0, "pad": 2, "cols": {2: UI.GREEN, 4: UI.RED}}))
	side.add_child(UI.trow(["All"] + tot, w2, {"size": 17, "hi": true, "pad": 2, "cols": {2: UI.GREEN, 4: UI.RED}}))
	if sel != null:
		_detail(side, sel, c.id, is_same(sel, nxt))


func _jump(scn, node):
	if node == null:
		return
	for i in 3:
		await get_tree().process_frame
	if is_instance_valid(scn) and is_instance_valid(node):
		scn.scroll_vertical = max(0, int(node.position.y) - 96)


func _name(c: Dictionary, right: bool) -> Label:
	var l = UI.lbl_fill(c.name, 19, UI.TEXT, "semi")
	if right:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	return l


func _detail(v: VBoxContainer, f: Dictionary, cid: int, is_next: bool):
	var s = G.s
	var hc = s.clubs[f.h]
	var ac = s.clubs[f.a]
	v.add_child(UI.divider())
	v.add_child(UI.caps("%s · %s" % [G.fx_caption(f) if not f.get("fr", false) else "Pre-season friendly", G.fmt_date(f.day, true)], 15, UI.accent))
	var hh = UI.hb(8)
	hh.add_child(_name(hc, true))
	hh.add_child(UI.badge(hc, 34))
	hh.add_child(UI.chip("%d - %d" % [f.hg, f.ag] if f.played else "v", Color(1, 1, 1, 0.07), UI.TEXT, 24, 74))
	hh.add_child(UI.badge(ac, 34))
	hh.add_child(_name(ac, false))
	v.add_child(hh)
	var venue = UI.caps(hc.stadium if hc.stadium != "" else hc.name, 13, UI.DIM)
	venue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(venue)
	if f.played:
		if f.has("pens"):
			var pl = UI.caps("Penalties %d-%d" % [f.pens[0], f.pens[1]], 15, UI.MUTED)
			pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			v.add_child(pl)
		if f.has("sc") and (f.sc[0].size() + f.sc[1].size()) > 0:
			var gh = UI.hb(12)
			for i in 2:
				var parts = []
				for g in f.sc[i]:
					parts.append("%s %d'" % [g[0], g[1]])
				var gl = UI.wrap("\n".join(parts), 15, UI.MUTED)
				gl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if i == 0 else HORIZONTAL_ALIGNMENT_LEFT
				gh.add_child(gl)
			v.add_child(gh)
	else:
		var w = [0, -44, -44, -44, -44, 76]
		v.add_child(UI.trow(["", "Pos", "Pts", "Att", "Def", "Form"], w, {"head": true}))
		for k in [hc, ac]:
			var tr = G.team_ratings(k.id)
			var roe = s.leagues[k.lg].get("roe", false)
			v.add_child(UI.trow([k.short, "-" if roe else G.LG.ordinal(G.LG.position(k.id)), "-" if roe else str(k.t.pts), tr.att, tr.def, UI.form_dots(k.form.slice(-5), 11)], w,
				{"size": 17, "hi": k.id == cid, "pad": 3, "cols": {3: UI.ovr_color(tr.att), 4: UI.ovr_color(tr.def)}}))
	# earlier meetings this season
	if cid >= 0:
		var opp = f.a if f.h == cid else f.h
		var other = []
		for g in s.fixtures:
			if not is_same(g, f) and ((g.h == cid and g.a == opp) or (g.a == cid and g.h == opp)):
				other.append(g)
		if other.size() > 0:
			v.add_child(UI.caps("Also this season", 15, UI.accent))
			for g in other:
				v.add_child(UI.trow([G.fmt_date(g.day), _tag(g), "H" if g.h == cid else "A", _result(g, cid)], [86, 0, 20, 60], {"size": 16, "pad": 2, "cols": {0: UI.MUTED, 1: UI.MUTED}}))
		var bh = UI.hb(6)
		bh.add_child(UI.btn("Their squad", func(): UI.main.open("clubview", {"cid": opp}), "secondary", "", 44))
		if is_next:
			bh.add_child(UI.btn("Tactics", func(): UI.main.root("tactics"), "primary", "", 44))
		for x in bh.get_children():
			x.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(bh)


func _rounds(v: VBoxContainer, side: VBoxContainer):
	var s = G.s
	var maxr = 0
	var cur_r = 1
	for f in s.fixtures:
		if f.lg == lg and not f.ko and f.get("comp", "") == "" and not f.get("fr", false):
			maxr = max(maxr, f.rd)
			if f.played:
				cur_r = max(cur_r, f.rd)
	if rd < 0:
		rd = cur_r
	UI.main.t_sub = "%s · round %d of %d" % [s.leagues[lg].name, rd, maxr]
	var nav = UI.hb(6)
	var prev = UI.panel(Color(1, 1, 1, 0.06), 10, 14, 6)
	prev.add_child(UI.icon("chevron-left", 22, UI.TEXT))
	UI.tap(prev, func():
		rd = max(1, rd - 1)
		sel = null
		refresh(), true)
	nav.add_child(prev)
	var mid = UI.panel(UI.CARD2, 10, 12, 6, Color(1, 1, 1, 0.1))
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ml = UI.lbl("%s · ROUND %d OF %d · CHANGE LEAGUE" % [s.leagues[lg].name.to_upper(), rd, maxr], 17, UI.TEXT, "disp")
	ml.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ml.clip_text = true
	mid.add_child(ml)
	var on_pick = func(i):
		lg = i
		rd = -1
		sel = null
		refresh()
	UI.tap(mid, func(): preload("res://scripts/screens/table.gd").pick_league(on_pick), true)
	nav.add_child(mid)
	var nx = UI.panel(Color(1, 1, 1, 0.06), 10, 14, 6)
	nx.add_child(UI.icon("chevron-right", 22, UI.TEXT))
	UI.tap(nx, func():
		rd = min(maxr, rd + 1)
		sel = null
		refresh(), true)
	nav.add_child(nx)
	v.add_child(nav)
	var w = [80, 0, 22, 60, 22, 0]
	var i = 0
	var ko = []
	for f in s.fixtures:
		if f.lg != lg or f.get("comp", "") != "" or f.get("fr", false):
			continue
		if f.ko:
			ko.append(f)
		elif f.rd == rd:
			v.add_child(_round_row(f, w, i))
			i += 1
	if ko.size() > 0:
		v.add_child(UI.caps("Play-offs", 15, UI.accent))
		for f in ko:
			v.add_child(_round_row(f, w, i))
			i += 1
	# league table beside the round
	if sel != null:
		side.add_child(UI.caps("%s · %s" % [_tag(sel), G.fmt_date(sel.day, true)], 15, UI.accent))
		var hh = UI.hb(8)
		hh.add_child(_name(s.clubs[sel.h], true))
		hh.add_child(UI.chip("%d - %d" % [sel.hg, sel.ag] if sel.played else "v", Color(1, 1, 1, 0.07), UI.TEXT, 20, 64))
		hh.add_child(_name(s.clubs[sel.a], false))
		side.add_child(hh)
		if sel.played and sel.has("sc"):
			var parts = []
			for k in 2:
				for g in sel.sc[k]:
					parts.append("%s %d'" % [g[0], g[1]])
			if parts.size() > 0:
				var gl = UI.wrap(" · ".join(parts), 15, UI.MUTED)
				gl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				side.add_child(gl)
		side.add_child(UI.divider())
	side.add_child(UI.caps("Table", 15, UI.accent))
	var w2 = [26, 22, 0, -28, -38, -34]
	side.add_child(UI.trow(["#", "", "Club", "P", "GD", "Pts"], w2, {"head": true}))
	var t = G.LG.table(lg)
	for k in t.size():
		var tc = s.clubs[t[k]]
		var cid = tc.id
		side.add_child(UI.trow([str(k + 1), UI.badge(tc, 20), tc.name, tc.t.p, "%+d" % (tc.t.gf - tc.t.ga), tc.t.pts], w2,
			{"size": 16, "hi": cid == s.user.club, "alt": k % 2 == 0, "pad": 2, "bold": 2, "cols": {0: UI.MUTED, 3: UI.MUTED, 4: UI.MUTED},
			"tap": func(): UI.main.open("clubview", {"cid": cid})}))


func _round_row(f: Dictionary, w: Array, i: int) -> Control:
	var s = G.s
	var mine = f.h == s.user.club or f.a == s.user.club
	return UI.trow([G.fmt_date(f.day).substr(4), _name(s.clubs[f.h], true), UI.badge(s.clubs[f.h], 22), _result(f, -1), UI.badge(s.clubs[f.a], 22), _name(s.clubs[f.a], false)], w,
		{"size": 16, "hi": is_same(f, sel) or (mine and sel == null), "alt": i % 2 == 0, "pad": 3, "cols": {0: UI.MUTED},
		"tap": func():
			sel = f
			refresh()})

extends "res://scripts/screens/screen.gd"
# International: what is coming up, the tournament running now (or the last one) with groups and knockout rounds,
# and the roll of honour. Your own players are marked.

var sel := 0     # index into the tournaments shown (live first, then finished)


func build():
	G.IT.ensure()
	var s = G.s
	UI.main.t_title = "International"
	var shown = s.intl.live + s.intl.done
	UI.main.t_sub = ("%s %d is on" % [s.intl.live[0].name, s.intl.live[0].year]) if s.intl.live.size() > 0 else "World Cup, Euros, Copa América, AFCON, Asian Cup"
	var h = panes(12, 20)
	var a = pane(300, 4)
	h.add_child(a[0])
	_side(a[1], shown)
	var b = pane(0, 4)
	h.add_child(b[0])
	if shown.is_empty():
		b[1].add_child(UI.caps("No tournament yet", 16, UI.accent))
		b[1].add_child(UI.wrap("The first one is listed on the left. Squads are picked from the best players of each nation anywhere in the game, so your own players can be called up.", 17, UI.MUTED))
		return
	sel = clampi(sel, 0, shown.size() - 1)
	_tournament(b[1], shown[sel])


func _side(v: VBoxContainer, shown: Array):
	v.add_child(UI.caps("Coming up", 16, UI.accent))
	var nl = G.IT.next_list()
	if nl.is_empty():
		v.add_child(UI.lbl_fill("Nothing in the next four years.", 15, UI.DIM))
	for it in nl.slice(0, 5):
		var r = UI.vb(-4)
		r.add_child(UI.lbl_fill("%s %d" % [it[1], it[2]], 17, UI.TEXT, "semi"))
		r.add_child(UI.lbl_fill("from %s%s" % [G.fmt_date(it[3]), (" · " + it[4]) if it[4] != "" else ""], 14, UI.DIM))
		v.add_child(r)
	v.add_child(UI.sp(0, 6))
	v.add_child(UI.caps("Tournaments", 16, UI.accent))
	for i in shown.size():
		var t = shown[i]
		var live = G.s.intl.live.has(t)
		var ch = UI.panel(Color(UI.accent, 0.2) if i == sel else Color(1, 1, 1, 0.04), 8, 10, 6)
		var cv = UI.vb(-4)
		cv.add_child(UI.lbl_fill("%s %d%s" % [t.name, t.year, "  · LIVE" if live else ""], 16, UI.GREEN if live else UI.TEXT, "semi"))
		cv.add_child(UI.lbl_fill(("Winners: %s" % t.winner) if t.has("winner") else t.host, 14, UI.GOLD if t.has("winner") else UI.DIM))
		ch.add_child(cv)
		var ii = i
		UI.tap(ch, func():
			sel = ii
			refresh(), true)
		v.add_child(ch)


func _tournament(v: VBoxContainer, t: Dictionary):
	var s = G.s
	var head = UI.hb(8)
	head.add_child(UI.lbl("%s %d" % [t.name, t.year], 24, UI.TEXT, "xbold"))
	head.add_child(UI.lbl_fill("  %s" % t.host, 16, UI.MUTED))
	v.add_child(head)
	if t.has("winner"):
		v.add_child(UI.lbl_fill("Winners %s · beat %s %s in the final · top scorer %s (%d)" % [t.winner, t.runner, t.score, t.scorer, int(t.goals)], 17, UI.GOLD, "semi"))
	# knockout rounds, latest first
	var ko = t.get("ko", [])
	for rnd in range(ko.size() - 1, -1, -1):
		v.add_child(UI.caps(ko[rnd], 15, UI.accent))
		var g = GridContainer.new()
		g.columns = 2
		g.add_theme_constant_override("h_separation", 12)
		for gm in t.games:
			if int(gm.get("rnd", -1)) != rnd:
				continue
			g.add_child(_game(gm))
		v.add_child(g)
	# groups
	v.add_child(UI.caps("Groups", 15, UI.accent))
	var gg = GridContainer.new()
	gg.columns = 4 if t.groups.size() >= 8 else 3
	gg.add_theme_constant_override("h_separation", 10)
	gg.add_theme_constant_override("v_separation", 8)
	var cur = t if t.has("info") else null
	for gi in t.groups.size():
		var p = UI.panel(Color(1, 1, 1, 0.035), 8, 8, 6)
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var pv = UI.vb(0)
		pv.add_child(UI.caps("Group %s" % "ABCDEFGHIJKL"[gi], 13, UI.MUTED))
		var order = G.IT.group_table(cur, gi) if cur != null else t.groups[gi]
		for nat in order:
			var r = UI.hb(4)
			r.add_child(UI.flag(nat, 18))
			r.add_child(UI.lbl_fill(nat, 14, UI.TEXT if cur == null or not cur.info[nat].out else UI.DIM))
			if cur != null:
				r.add_child(UI.lbl("%d" % int(cur.info[nat].pts), 14, UI.MUTED, "semi"))
			pv.add_child(r)
		p.add_child(pv)
		gg.add_child(p)
	v.add_child(gg)


func _game(gm: Dictionary) -> Control:
	var r = UI.hb(6)
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_child(UI.flag(gm.h, 18))
	r.add_child(UI.lbl_fill(gm.h, 15, UI.TEXT))
	var sc = "v" if int(gm.hg) < 0 else "%d-%d%s" % [gm.hg, gm.ag, " p" if gm.has("pens") else ""]
	r.add_child(UI.lbl(sc, 15, UI.GOLD, "disp"))
	var al = UI.lbl_fill(gm.a, 15, UI.TEXT)
	al.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	r.add_child(al)
	r.add_child(UI.flag(gm.a, 18))
	return r

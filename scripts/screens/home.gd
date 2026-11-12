extends "res://scripts/screens/screen.gd"
# Career hub: next match, league snapshot, board, news.

var busy := false


func _init():
	show_nav = true


func build():
	var s = G.s
	if s.review != null:
		UI.main.call_deferred("root", "review")
		return
	if s.user.sacked:
		UI.main.call_deferred("root", "jobs", {"sacked": true})
		return
	var c = G.uc()
	var n = G.unread()
	var inbox_btn = UI.panel(Color(1, 1, 1, 0.06), 20, 14, 14)
	var ih = UI.hb(6)
	ih.add_child(UI.icon("mail", 30, UI.TEXT if n == 0 else UI.accent))
	if n > 0:
		ih.add_child(UI.lbl(str(n), 24, UI.accent, "disp"))
	inbox_btn.add_child(ih)
	UI.tap(inbox_btn, func(): UI.main.open("inbox"), true)
	body.add_child(UI.clubbar(inbox_btn))
	var v = content(16)
	# date strip
	var ds = UI.hb(10)
	ds.add_child(UI.icon("calendar", 24, UI.MUTED))
	ds.add_child(UI.caps(G.fmt_date(s.day, true), 23, UI.TEXT))
	ds.add_child(UI.sp())
	if G.window_open():
		ds.add_child(UI.chip("WINDOW OPEN", Color(UI.GREEN, 0.14), UI.GREEN, 18))
	ds.add_child(UI.chip(G.season_name(), Color(1, 1, 1, 0.06), UI.MUTED, 18))
	v.add_child(ds)
	# next match
	var f = G.next_user_fixture()
	var today = f != null and f.day == s.day
	var hero = UI.panel(UI.CARD, 28, 24, 24, Color(UI.accent, 0.45))
	var hv = UI.vb(16)
	if f != null:
		var hc = s.clubs[f.h]
		var ac = s.clubs[f.a]
		var top = UI.hb(8)
		top.add_child(UI.caps("Match day" if today else "Next match", 22, UI.accent))
		top.add_child(UI.sp())
		top.add_child(UI.caps(f.label if f.ko else "%s · Round %d" % [s.leagues[f.lg].name, f.rd], 20, UI.MUTED))
		hv.add_child(top)
		var mh = UI.hb(8)
		mh.add_child(_side(hc))
		var mid = UI.vb(2)
		mid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var vs = UI.lbl("VS", 44, UI.TEXT, "xbold")
		vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mid.add_child(vs)
		var dl = UI.caps("Today" if today else G.fmt_date(f.day), 19, UI.MUTED)
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mid.add_child(dl)
		mh.add_child(mid)
		mh.add_child(_side(ac))
		hv.add_child(mh)
		var venue = UI.caps("%s%s" % ["Home · " if f.h == c.id else "Away · ", hc.stadium if hc.stadium != "" else hc.name], 19, UI.DIM)
		venue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hv.add_child(venue)
	else:
		hv.add_child(UI.caps("Season complete", 22, UI.accent))
		hv.add_child(UI.wrap("No more fixtures this season. Continue to the season review.", 24, UI.MUTED))
	if today:
		hv.add_child(UI.btn("Play match", func(): UI.main.root("match", {"fx": f}), "primary", "play", 92))
	else:
		var days = (f.day - s.day) if f != null else 0
		hv.add_child(UI.btn("Continue", _continue, "primary", "fast-forward", 92))
		if f != null:
			var nl = UI.caps("Kick-off in %d day%s" % [days, "" if days == 1 else "s"], 19, UI.MUTED)
			nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			hv.add_child(nl)
	hero.add_child(hv)
	v.add_child(hero)
	# league snapshot
	var t = G.LG.table(c.lg)
	var pos = t.find(c.id) + 1
	var lc = UI.card()
	var lv = UI.vb(12)
	var lh = UI.hb(14)
	var pl = UI.lbl(G.LG.ordinal(pos), 64, UI.TEXT, "xbold")
	lh.add_child(pl)
	var lm = UI.vb(0)
	lm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lm.add_child(UI.caps(s.leagues[c.lg].name, 22, UI.accent))
	lm.add_child(UI.lbl("%d pts · %dW %dD %dL · GD %+d" % [c.t.pts, c.t.w, c.t.d, c.t.l, c.t.gf - c.t.ga], 22, UI.MUTED))
	lh.add_child(lm)
	lh.add_child(UI.form_dots(c.form))
	lv.add_child(lh)
	lv.add_child(UI.divider())
	var from = clampi(pos - 3, 0, max(0, t.size() - 5))
	for i in range(from, min(t.size(), from + 5)):
		var tc = s.clubs[t[i]]
		var r = UI.hb(12)
		var me = tc.id == c.id
		var pn = UI.lbl(str(i + 1), 22, UI.accent if me else UI.MUTED, "disp")
		pn.custom_minimum_size = Vector2(34, 0)
		r.add_child(pn)
		r.add_child(UI.badge(tc, 34))
		r.add_child(UI.lbl_fill(tc.name, 24, UI.TEXT if me else UI.MUTED, "semi" if me else "body"))
		r.add_child(UI.lbl(str(tc.t.p), 22, UI.DIM))
		var pts = UI.lbl(str(tc.t.pts), 25, UI.TEXT if me else UI.MUTED, "disp")
		pts.custom_minimum_size = Vector2(44, 0)
		pts.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		r.add_child(pts)
		lv.add_child(r)
	lc.add_child(lv)
	UI.tap(lc, func(): UI.main.open("table", {"lg": c.lg}))
	v.add_child(lc)
	# board
	var bc = UI.card()
	var bv = UI.vb(10)
	var bh = UI.hb(10)
	bh.add_child(UI.icon("target", 26, UI.accent))
	bh.add_child(UI.caps("Board objective", 22, UI.MUTED))
	bh.add_child(UI.sp())
	bh.add_child(UI.caps("Confidence %d%%" % int(s.user.conf), 20, UI.cond_color(s.user.conf + 20)))
	bv.add_child(bh)
	bv.add_child(UI.lbl(s.user.obj.text, 30, UI.TEXT, "disp"))
	bv.add_child(UI.bar(s.user.conf / 100.0, UI.cond_color(s.user.conf + 20), 10))
	bc.add_child(bv)
	UI.tap(bc, func(): UI.main.open("board"))
	v.add_child(bc)
	# squad status
	var inj = 0
	var sus = 0
	var tired = 0
	for pid in c.players:
		var p = s.players[pid]
		if p.inj > 0: inj += 1
		if p.susp > 0: sus += 1
		if pid in c.xi and p.cond < 75: tired += 1
	var st = UI.hb(10)
	st.add_child(UI.stat_tile("Injured", str(inj), UI.RED if inj > 0 else UI.TEXT))
	st.add_child(UI.stat_tile("Suspended", str(sus), UI.RED if sus > 0 else UI.TEXT))
	st.add_child(UI.stat_tile("Tired in XI", str(tired), UI.AMBER if tired > 0 else UI.TEXT))
	st.add_child(UI.stat_tile("Budget", G.money(c.budget), UI.GREEN))
	v.add_child(st)
	# news
	if s.news.size() > 0:
		v.add_child(UI.section("Around the leagues"))
		var nc = UI.card()
		var nv = UI.vb(12)
		for i in min(5, s.news.size()):
			var item = s.news[i]
			var r = UI.hb(12)
			var d = UI.caps(G.fmt_date(item.day).substr(4), 18, UI.DIM)
			d.custom_minimum_size = Vector2(74, 0)
			r.add_child(d)
			r.add_child(UI.wrap(item.text, 22, UI.MUTED))
			nv.add_child(r)
		nc.add_child(nv)
		v.add_child(nc)


func _side(c: Dictionary) -> Control:
	var v = UI.vb(8)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(UI.badge(c, 104))
	var l = UI.lbl(c.name.to_upper(), 26, UI.TEXT, "disp")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(l)
	var pos = UI.caps("%s · %d pts" % [G.LG.ordinal(G.LG.position(c.id)), c.t.pts], 18, UI.MUTED)
	pos.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(pos)
	var fd = UI.form_dots(c.form, 12)
	fd.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(fd)
	return v


func _continue():
	if busy:
		return
	busy = true
	UI.toast("Simulating…", UI.MUTED)
	await get_tree().process_frame
	await get_tree().process_frame
	var before = G.unread()
	G.advance()
	busy = false
	if G.s.review != null:
		UI.main.root("review")
		return
	if G.s.user.sacked:
		UI.main.root("jobs", {"sacked": true})
		return
	refresh()
	UI.main.refresh_nav()
	if G.unread() > before and G.s.inbox.size() > 0:
		UI.toast("New message: %s" % G.s.inbox[0].title, UI.accent)

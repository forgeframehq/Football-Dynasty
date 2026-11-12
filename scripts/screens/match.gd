extends "res://scripts/screens/screen.gd"
# Match day: pre-match briefing, live match with commentary, full-time report.

const PITCH = preload("res://scripts/widgets/match_pitch.gd")
const MOM = preload("res://scripts/widgets/momentum.gd")
const SPEEDS = [0.85, 0.4, 0.13, 0.85]
const TABS = ["Feed", "Stats", "Line-ups", "Live"]
const MENT_SHORT = ["Bus", "Def", "Bal", "Att", "All out"]
const EV = {"goal": ["zap", "e9c46a"], "save": ["shield", "4da3ff"], "miss": ["x", "8b96ab"], "yellow": ["square", "f6ad3c"], "red": ["square", "ff5c72"],
	"sub": ["repeat", "2ee59d"], "injury": ["bandage", "ff5c72"], "info": ["activity", "5b6680"], "ht": ["clock", "f3f6fb"], "ft": ["clock", "f3f6fb"]}

var f: Dictionary
var sim = null
var stage := "pre"
var us := 0
var speed := 0
var paused := false
var acc := 0.0
var hold := 0.0
var applied := false
var sub_out := -1
var score_l: Label
var min_l: Label
var sc_l: Array = []
var pitch: Control
var poss_bar: Control
var stat_l: Dictionary = {}
var feed: VBoxContainer
var lower: Control
var ctrl: HBoxContainer
var tab := 0
var others: Array = []
var banner: PanelContainer
var banner_l: Label
var banner_s: Label
var tabv: VBoxContainer
var feed_sc: ScrollContainer
var tab_sc: ScrollContainer
var tab_holder: Control


func can_leave() -> bool:
	return stage == "pre"


func on_resume():
	if stage == "pre":
		refresh()


func build():
	chrome = false
	f = args.fx
	us = 0 if f.h == G.s.user.club else 1
	if stage == "pre":
		_build_pre()
	else:
		_build_live()
		if stage == "ft":
			_show_ft()


# ---------------------------------------------------------------- pre-match

func _build_pre():
	var s = G.s
	var hc = s.clubs[f.h]
	var ac = s.clubs[f.a]
	var changes = G.fix_lineup()
	body.add_child(UI.topbar("Match day"))
	var v = content(14)
	var hero = UI.panel(UI.CARD, 28, 22, 22, Color(UI.accent, 0.45))
	var hv = UI.vb(12)
	var cap = UI.caps(G.fx_caption(f), 21, UI.accent)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hv.add_child(cap)
	var mh = UI.hb(8)
	mh.add_child(_side(hc))
	var vs = UI.lbl("VS", 44, UI.TEXT, "xbold")
	vs.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mh.add_child(vs)
	mh.add_child(_side(ac))
	hv.add_child(mh)
	var ven = UI.caps(hc.stadium if hc.stadium != "" else hc.name, 19, UI.DIM)
	ven.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hv.add_child(ven)
	hero.add_child(hv)
	v.add_child(hero)
	if changes.size() > 0:
		var note = UI.panel(Color(UI.AMBER, 0.1), 18, 18, 12, Color(UI.AMBER, 0.3))
		note.add_child(UI.wrap("Line-up changed (unavailable players): " + ", ".join(changes), 21, UI.AMBER))
		v.add_child(note)
	# comparison
	var rh = G.team_ratings(f.h)
	var ra = G.team_ratings(f.a)
	var cc = UI.card()
	var cv = UI.vb(10)
	for k in [["Overall", "ovr"], ["Attack", "att"], ["Midfield", "mid"], ["Defence", "def"]]:
		var r = UI.hb(12)
		var a = UI.lbl(str(rh[k[1]]), 28, UI.ovr_color(rh[k[1]]), "disp")
		a.custom_minimum_size = Vector2(44, 0)
		r.add_child(a)
		var lb = UI.bar((rh[k[1]] - 45) / 50.0, Color(hc.c1) if Color(hc.c1).get_luminance() > 0.12 else Color(hc.c2), 8)
		lb.scale.x = -1
		lb.resized.connect(func(): lb.pivot_offset = lb.size / 2.0)
		r.add_child(lb)
		var l = UI.caps(k[0], 18, UI.MUTED)
		l.custom_minimum_size = Vector2(96, 0)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		r.add_child(l)
		r.add_child(UI.bar((ra[k[1]] - 45) / 50.0, Color(ac.c1) if Color(ac.c1).get_luminance() > 0.12 else Color(ac.c2), 8))
		var b = UI.lbl(str(ra[k[1]]), 28, UI.ovr_color(ra[k[1]]), "disp")
		b.custom_minimum_size = Vector2(44, 0)
		b.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		r.add_child(b)
		cv.add_child(r)
	cc.add_child(cv)
	v.add_child(cc)
	v.add_child(UI.btn("Kick off", _kickoff, "primary", "play", 92))
	var opp = ac if f.h == G.s.user.club else hc
	var ro = ra if f.h == G.s.user.club else rh
	var rep_card = UI.card()
	var rv = UI.vb(8)
	rv.add_child(UI.caps("Opposition report · %s" % opp.name, 20, UI.accent))
	var lines = [["att", "going forward"], ["mid", "in midfield"], ["def", "at the back"]]
	lines.sort_custom(func(x, y): return ro[x[0]] > ro[y[0]])
	rv.add_child(UI.wrap("They line up in a %s and are strongest %s (%d), weakest %s (%d)." % [opp.formation, lines[0][1], ro[lines[0][0]], lines[2][1], ro[lines[2][0]]], 22, UI.MUTED))
	var stars = []
	for pid in opp.players:
		stars.append(G.s.players[pid])
	stars.sort_custom(func(x, y): return x.ovr + x.form > y.ovr + y.form)
	for k in min(3, stars.size()):
		var sp = stars[k]
		var r = UI.hb(10)
		r.add_child(UI.pos(sp.pos, 18))
		r.add_child(UI.lbl_fill(G.pname(sp), 23, UI.TEXT, "semi"))
		r.add_child(UI.caps("%d G · %d A" % [sp.ss.g, sp.ss.a], 17, UI.DIM))
		r.add_child(UI.ovr(sp.ovr, 22))
		rv.add_child(r)
	rep_card.add_child(rv)
	v.add_child(rep_card)
	var bh = UI.hb(10)
	var tb = UI.btn("Tactics", func(): UI.main.open("tactics"), "secondary", "layout-grid", 72)
	tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bh.add_child(tb)
	var qb = UI.btn("Quick result", _quick, "secondary", "fast-forward", 72)
	qb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bh.add_child(qb)
	v.add_child(bh)
	# line-ups
	v.add_child(UI.section("Line-ups"))
	var lu = [G.lineup(f.h, f.a), G.lineup(f.a, f.h)]
	var lc = UI.card(16, 16)
	var lh = UI.hb(14)
	for i in 2:
		var col = UI.vb(6)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_child(UI.caps("%s · %s" % [s.clubs[lu[i].club].short, lu[i].formation], 20, UI.accent if i == us else UI.MUTED))
		var slots = lu[i].slots
		for k in 11:
			var pid = lu[i].xi[k]
			var r = UI.hb(8)
			var pl = UI.caps(slots[k][0], 16, UI.LINE_COL[G.LINE[slots[k][0]]])
			pl.custom_minimum_size = Vector2(40, 0)
			r.add_child(pl)
			if pid >= 0:
				var p = s.players[pid]
				r.add_child(UI.lbl_fill(G.pname(p), 21, UI.TEXT))
				r.add_child(UI.lbl(str(p.ovr), 21, UI.ovr_color(p.ovr), "disp"))
			else:
				r.add_child(UI.lbl_fill("—", 21, UI.DIM))
			col.add_child(r)
		lh.add_child(col)
	lc.add_child(lh)
	v.add_child(lc)


func _side(c: Dictionary) -> Control:
	var v = UI.vb(8)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(UI.badge(c, 108))
	var l = UI.lbl(c.name.to_upper(), 26, UI.TEXT, "disp")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(l)
	var fd = UI.form_dots(c.form, 12)
	fd.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(fd)
	return v


func _start_others():
	# same-competition fixtures kick off at the same time; results are applied at full time
	others = []
	for i in G.fx_by_day.get(G.s.day, []):
		var f2 = G.s.fixtures[i]
		if f2.played or f2.id == f.id or f2.lg != f.lg or f2.get("comp", "") != f.get("comp", ""):
			continue
		var s2 = G.new_sim(f2, false)
		s2.run_to_end()
		others.append(s2)


func _kickoff():
	sim = G.new_sim(f, true)
	_start_others()
	UI.sfx("whistle")
	UI.sfx("vo_kickoff", -4.0)
	UI.ambience(true)
	stage = "live"
	refresh()


func _quick():
	sim = G.new_sim(f, true)
	_start_others()
	sim.sd[us].auto = true
	sim.run_to_end()
	stage = "ft"
	refresh()


# ---------------------------------------------------------------- live

func _col(c: Dictionary) -> Color:
	return Color(c.c1) if Color(c.c1).get_luminance() > 0.12 else Color(c.c2)


func _build_live():
	var h = sim.sd[0]
	var a = sim.sd[1]
	# scoreboard strip
	var sb = UI.panel(UI.CARD, 18, 18, 6, UI.LINE)
	var row = UI.hb(12)
	row.add_child(UI.badge(h.club, 56))
	var hn = UI.lbl(h.club.short, 38, UI.TEXT, "xbold")
	row.add_child(hn)
	sc_l = []
	var l0 = UI.wrap("", 16, UI.MUTED)
	l0.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l0.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sc_l.append(l0)
	row.add_child(l0)
	var mid = UI.vb(-8)
	mid.custom_minimum_size = Vector2(230, 0)
	score_l = UI.lbl("0 – 0", 54, UI.TEXT, "xbold")
	score_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mid.add_child(score_l)
	var mc = UI.chip("0'", Color(UI.accent, 0.16), UI.accent, 20, 84)
	mc.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	min_l = mc.get_child(0)
	mid.add_child(mc)
	row.add_child(mid)
	var l1 = UI.wrap("", 16, UI.MUTED)
	l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l1.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sc_l.append(l1)
	row.add_child(l1)
	row.add_child(UI.lbl(a.club.short, 38, UI.TEXT, "xbold"))
	row.add_child(UI.badge(a.club, 56))
	sb.add_child(row)
	body.add_child(UI.margin(sb, 20, 8, 20, 8))
	var hbx = UI.hb(14)
	hbx.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var hm = UI.margin(hbx, 20, 0, 20, 12)
	hm.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(hm)
	var left = UI.vb(8)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbx.add_child(left)
	pitch = PITCH.new()
	pitch.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pitch.custom_minimum_size = Vector2(0, 300)
	pitch.setup(sim)
	left.add_child(pitch)
	banner = UI.panel(Color("0b111c"), 20, 26, 12, UI.GOLD)
	var bv = UI.vb(-2)
	banner_l = UI.lbl("GOAL!", 52, UI.GOLD, "xbold")
	banner_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_s = UI.lbl("", 22, UI.TEXT, "semi")
	banner_s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bv.add_child(banner_l)
	bv.add_child(banner_s)
	banner.add_child(bv)
	var bc = CenterContainer.new()
	bc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bc.add_child(banner)
	pitch.add_child(bc)
	banner.visible = false
	# possession strip
	var pr = UI.hb(12)
	stat_l["ph"] = UI.lbl("50%", 22, UI.TEXT, "disp")
	stat_l["pa"] = UI.lbl("50%", 22, UI.TEXT, "disp")
	stat_l["sh"] = UI.caps("0 shots", 17, UI.MUTED)
	stat_l["sa"] = UI.caps("0 shots", 17, UI.MUTED)
	pr.add_child(stat_l["sh"])
	pr.add_child(stat_l["ph"])
	poss_bar = UI.bar(0.5, pitch.cols[0] if pitch.cols[0].get_luminance() > 0.12 else pitch.rims[0], 10, pitch.cols[1] if pitch.cols[1].get_luminance() > 0.12 else pitch.rims[1])
	pr.add_child(poss_bar)
	pr.add_child(stat_l["pa"])
	pr.add_child(stat_l["sa"])
	left.add_child(pr)
	ctrl = UI.hb(8)
	left.add_child(ctrl)
	# side panel: tabs + feed
	var side = UI.panel(UI.CARD, 18, 0, 10, UI.LINE)
	side.custom_minimum_size = Vector2(clamp((UI.main.size.x) * 0.31, 400, 500), 0)
	var sv = UI.vb(0)
	side.add_child(sv)
	hbx.add_child(side)
	tab_holder = Control.new()
	tab_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sv.add_child(tab_holder)
	_build_tabs()
	lower = Control.new()
	lower.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lower.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lower.clip_contents = true
	sv.add_child(lower)
	feed = UI.vb(6)
	feed_sc = UI.scroll(UI.margin(feed, 12, 0, 12, 8))
	feed_sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lower.add_child(feed_sc)
	tabv = UI.vb(8)
	tab_sc = UI.scroll(UI.margin(tabv, 12, 0, 12, 8))
	tab_sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tab_sc.visible = false
	lower.add_child(tab_sc)
	_build_ctrl()
	_update()
	for e in sim.events:
		if e.x != "":
			_add_event(e)


func _build_tabs():
	for c in tab_holder.get_children():
		c.queue_free()
	var sg = UI.seg(TABS, tab, func(i):
		tab = i
		_build_tabs()
		_refresh_tab(), 20)
	var m = UI.margin(sg, 10, 0, 10, 8)
	tab_holder.add_child(m)
	m.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	tab_holder.custom_minimum_size = Vector2(0, 54)


func _score_at(sm, side: int, minute: int) -> int:
	var n = 0
	for e in sm.events:
		if e.t == "goal" and e.s == side and e.m <= minute:
			n += 1
	return n


func _refresh_tab():
	if stage == "ft" or feed_sc == null or not is_instance_valid(feed_sc):
		return
	feed_sc.visible = tab == 0
	tab_sc.visible = tab != 0
	if tab == 0:
		return
	for c in tabv.get_children():
		tabv.remove_child(c)
		c.queue_free()
	var h = sim.sd[0]
	var a = sim.sd[1]
	if tab == 1:
		tabv.add_child(UI.caps("Momentum", 18, UI.DIM))
		tabv.add_child(_momentum())
		tabv.add_child(_stats_card())
	elif tab == 2:
		for i in [us, 1 - us]:
			var t = sim.sd[i]
			tabv.add_child(UI.section("%s · %s" % [t.club.name, t.formation]))
			for k in 11:
				var pid = t.xi[k]
				if pid < 0:
					continue
				tabv.add_child(_live_row(pid, t.roles[k]))
	else:
		var m = sim.minute
		if others.size() > 0:
			tabv.add_child(UI.section("Live scores"))
			var card = UI.card(16, 12)
			var cv = UI.vb(8)
			for o in others:
				var r = UI.hb(8)
				var hn = UI.lbl_fill(o.sd[0].club.name, 21, UI.MUTED)
				hn.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				r.add_child(hn)
				r.add_child(UI.chip("%d – %d" % [_score_at(o, 0, m), _score_at(o, 1, m)], Color(1, 1, 1, 0.06), UI.TEXT, 22, 80))
				r.add_child(UI.lbl_fill(o.sd[1].club.name, 21, UI.MUTED))
				cv.add_child(r)
			card.add_child(cv)
			tabv.add_child(card)
		if f.get("comp", "") == "" and not f.ko:
			tabv.add_child(UI.section("As it stands"))
			var rows = {}
			for cid in G.s.leagues[f.lg].clubs:
				var t = G.s.clubs[cid].t
				rows[cid] = [t.pts, t.gf - t.ga, t.gf]
			var live = [[h.cid, a.cid, h.goals, a.goals]]
			for o in others:
				live.append([o.sd[0].cid, o.sd[1].cid, _score_at(o, 0, m), _score_at(o, 1, m)])
			for l in live:
				rows[l[0]][0] += 3 if l[2] > l[3] else (1 if l[2] == l[3] else 0)
				rows[l[1]][0] += 3 if l[3] > l[2] else (1 if l[2] == l[3] else 0)
				rows[l[0]][1] += l[2] - l[3]
				rows[l[1]][1] += l[3] - l[2]
				rows[l[0]][2] += l[2]
				rows[l[1]][2] += l[3]
			var ids = rows.keys()
			ids.sort_custom(func(x, y): return rows[x][0] * 10000 + rows[x][1] * 100 + rows[x][2] > rows[y][0] * 10000 + rows[y][1] * 100 + rows[y][2])
			var card = UI.card(16, 12)
			var cv = UI.vb(6)
			for i in ids.size():
				var c = G.s.clubs[ids[i]]
				var me = c.id == G.s.user.club
				var r = UI.hb(10)
				var pn = UI.lbl(str(i + 1), 21, UI.accent if me else UI.DIM, "disp")
				pn.custom_minimum_size = Vector2(30, 0)
				r.add_child(pn)
				r.add_child(UI.badge(c, 28))
				r.add_child(UI.lbl_fill(c.name, 21, UI.TEXT if me else UI.MUTED, "semi" if me else "body"))
				r.add_child(UI.lbl("%+d" % rows[c.id][1], 20, UI.DIM))
				var pl = UI.lbl(str(rows[c.id][0]), 23, UI.TEXT if me else UI.MUTED, "disp")
				pl.custom_minimum_size = Vector2(40, 0)
				pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				r.add_child(pl)
				cv.add_child(r)
			card.add_child(cv)
			tabv.add_child(card)
		elif others.size() == 0:
			tabv.add_child(UI.wrap("No other matches in this competition today.", 22, UI.MUTED))


func _momentum() -> Control:
	var g = MOM.new()
	g.data = sim.momentum
	g.ch = pitch.cols[0] if pitch.cols[0].get_luminance() > 0.12 else pitch.rims[0]
	g.ca = pitch.cols[1] if pitch.cols[1].get_luminance() > 0.12 else pitch.rims[1]
	for i in 2:
		for sc in sim.sd[i].scorers:
			g.goals.append([sc.m, i])
	g.custom_minimum_size = Vector2(0, 110)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var p = UI.card(14, 10)
	p.add_child(g)
	return p


func _stats_card() -> Control:
	var h = sim.sd[0]
	var a = sim.sd[1]
	var stc = UI.card()
	var stv = UI.vb(8)
	var tp = max(1, h.poss + a.poss)
	var ph = int(round(100.0 * h.poss / tp))
	var rows = [["Possession", "%d%%" % ph, "%d%%" % (100 - ph)], ["Shots", str(h.shots), str(a.shots)], ["On target", str(h.sot), str(a.sot)],
		["Expected goals", "%.2f" % h.xg, "%.2f" % a.xg], ["Corners", str(h.corners), str(a.corners)], ["Fouls", str(h.fouls), str(a.fouls)], ["Yellow cards", str(h.yc), str(a.yc)], ["Red cards", str(h.rc), str(a.rc)]]
	for r in rows:
		var rh = UI.hb(8)
		var l1 = UI.lbl(r[1], 25, UI.TEXT, "disp")
		l1.custom_minimum_size = Vector2(90, 0)
		rh.add_child(l1)
		var l2 = UI.caps(r[0], 19, UI.MUTED)
		l2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rh.add_child(l2)
		var l3 = UI.lbl(r[2], 25, UI.TEXT, "disp")
		l3.custom_minimum_size = Vector2(90, 0)
		l3.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		rh.add_child(l3)
		stv.add_child(rh)
	stc.add_child(stv)
	return stc


func _live_row(pid: int, role: String) -> Control:
	var p = G.s.players[pid]
	var q = sim.pm[pid]
	var r = UI.panel(UI.CARD, 14, 14, 8, UI.LINE)
	var h = UI.hb(10)
	h.add_child(UI.pos(role, 18))
	h.add_child(UI.lbl_fill(G.pname(p), 22, UI.TEXT, "semi"))
	var bits = []
	if q.g > 0: bits.append("%dG" % q.g)
	if q.a > 0: bits.append("%dA" % q.a)
	if q.yc > 0: bits.append("YC")
	if bits.size() > 0:
		h.add_child(UI.caps(" ".join(bits), 17, UI.GOLD))
	h.add_child(UI.caps("%d%%" % int(q.cond), 18, UI.cond_color(q.cond)))
	var lr = sim.live_rating(pid)
	var rc = UI.GOLD if lr >= 8.0 else (UI.GREEN if lr >= 7.0 else UI.TEXT)
	h.add_child(UI.chip("%.1f" % lr, Color(rc, 0.14), rc, 21, 56))
	r.add_child(h)
	return r


func _build_ctrl():
	for c in ctrl.get_children():
		ctrl.remove_child(c)
		c.queue_free()
	if stage == "ft":
		ctrl.visible = false
		return
	if stage == "ht":
		var b = UI.btn("Team talk & restart", _team_talk, "primary", "play", 56)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ctrl.add_child(b)
		ctrl.add_child(UI.btn("Team", _team_sheet, "secondary", "repeat", 56))
		return
	var pb = UI.panel(UI.accent, 16, 26, 0)
	pb.custom_minimum_size = Vector2(0, 56)
	pb.add_child(UI.icon("play" if paused else "pause", 34, UI.on_color(UI.accent)))
	UI.tap(pb, func():
		paused = not paused
		_build_ctrl(), true)
	ctrl.add_child(pb)
	var sg = UI.seg(["1x", "2x", "4x", "Key"], speed, func(i):
		speed = i
		_build_ctrl(), 22)
	sg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sg.custom_minimum_size = Vector2(0, 56)
	ctrl.add_child(sg)
	ctrl.add_child(UI.btn("Team", _team_sheet, "secondary", "repeat", 56))
	var sk = UI.panel(UI.CARD2, 16, 22, 0, Color(1, 1, 1, 0.1))
	sk.custom_minimum_size = Vector2(0, 56)
	sk.add_child(UI.icon("fast-forward", 32, UI.TEXT))
	UI.tap(sk, _skip, true)
	ctrl.add_child(sk)


func _team_talk():
	var me = sim.sd[us]
	var op = sim.sd[1 - us]
	var diff = me.goals - op.goals
	var go = func(kind: int):
		var good = false
		if kind == 0:
			good = diff >= 0
		elif kind == 1:
			good = diff < 0 or (diff == 0 and me.club.rep > op.club.rep + 2)
		else:
			good = diff > 0
		var roll = G.rng.randf()
		var mot = G.s.user.get("attr", {}).get("mot", 10)
		if good and roll < 0.6 + mot * 0.015:
			me.boost *= 1.025
			UI.toast("The players look fired up.", UI.GREEN)
		elif not good and roll < 0.5:
			me.boost *= 0.985
			UI.toast("That didn't go down well in the dressing room.", UI.RED)
		else:
			UI.toast("The players listen quietly.")
		UI.close_sheet()
		stage = "live"
		paused = false
		sim.recalc(us)
		sim.resume()
		_build_ctrl()
	var build_sheet = func(v):
		v.add_child(UI.wrap("Half-time: %s. What do you tell the players?" % sim.score_text(), 22, UI.MUTED))
		v.add_child(UI.btn("Well done, keep it going", func(): go.call(0), "secondary", "heart", 72))
		v.add_child(UI.btn("I expect much more from you", func(): go.call(1), "secondary", "zap", 72))
		v.add_child(UI.btn("Stay calm and see it out", func(): go.call(2), "secondary", "shield", 72))
	UI.sheet("Team talk", build_sheet)


func _process(delta):
	if stage != "live" or paused or sim == null or UI.main.sheet_node != null:
		return
	if hold > 0.0:
		hold -= delta
		if hold <= 0.0 and banner != null:
			banner.visible = false
		return
	acc += delta
	if speed == 3:
		for n in 40:
			if _tick() or stage != "live":
				hold = max(hold, 1.2)
				break
		return
	if acc >= SPEEDS[speed]:
		acc = 0.0
		_tick()


func _tick() -> bool:
	var evs = sim.step()
	var notable = false
	for e in evs:
		_add_event(e)
		if e.t != "info" and e.t != "sub":
			notable = true
		if e.t == "ht":
			UI.sfx("whistle")
			UI.sfx("vo_half", -4.0)
		elif e.t == "ft":
			UI.sfx("whistle_end")
			UI.sfx("vo_full", -4.0)
		elif e.t == "save":
			UI.sfx("kick", -8.0)
			UI.sfx("applause" if e.s != us else "groan", -12.0)
		elif e.t == "miss":
			UI.sfx("kick", -8.0)
		elif e.t == "red":
			UI.sfx("vo_red", -4.0)
			UI.sfx("boo", -8.0)
		if e.t == "goal":
			UI.sfx("kick", -6.0)
			UI.sfx("cheer" if e.s == us else "groan", -3.0)
			UI.sfx("vo_goal%d" % (1 + randi() % 4), -3.0)
			hold = 1.8 if speed != 2 else 0.7
			banner_l.text = "GOAL!"
			var sub = "%s %d'" % [G.pname(G.s.players[e.p]), min(e.m, 90)]
			if e.get("a", -1) >= 0:
				sub += "  ·  assist %s" % G.pname(G.s.players[e.a])
			banner_s.text = sub
			banner.get_theme_stylebox("panel").border_color = pitch.cols[e.s] if pitch.cols[e.s].get_luminance() > 0.2 else UI.GOLD
			banner.visible = true
			var tw = create_tween()
			tw.tween_method(pitch.set_flash, 1.0, 0.0, 1.2)
	pitch.ball_color = pitch.cols[sim.ball_side]
	pitch.tick()
	_update()
	if tab != 0 and (notable or sim.minute % 3 == 0):
		_refresh_tab()
	if sim.phase == 2:
		stage = "ht"
		_build_ctrl()
		return true
	elif sim.phase == 4:
		stage = "ft"
		_build_ctrl()
		_show_ft()
		return true
	return notable


func _skip():
	if sim == null or stage == "ft":
		return
	sim.sd[us].auto = true
	while sim.phase != 4:
		for e in sim.step():
			_add_event(e)
	stage = "ft"
	_update()
	_build_ctrl()
	_show_ft()


func _update():
	var h = sim.sd[0]
	var a = sim.sd[1]
	score_l.text = "%d – %d" % [h.goals, a.goals]
	if sim.phase == 4:
		min_l.text = "FT"
	elif sim.phase == 2:
		min_l.text = "HT"
	else:
		min_l.text = "%d'" % min(sim.minute, 90) if sim.minute <= 90 else "90+%d'" % (sim.minute - 90)
	for i in 2:
		var parts = []
		for g in sim.sd[i].scorers:
			parts.append("%s %d'%s" % [G.pname(G.s.players[g.pid]), min(g.m, 90), " (P)" if g.pen else ""])
		sc_l[i].text = "  ·  ".join(parts)
	var tp = max(1, h.poss + a.poss)
	var ph = int(round(100.0 * h.poss / tp))
	stat_l["ph"].text = "%d%%" % ph
	stat_l["pa"].text = "%d%%" % (100 - ph)
	stat_l["sh"].text = "%d shots" % h.shots
	stat_l["sa"].text = "%d shots" % a.shots
	poss_bar.frac = clamp(ph / 100.0, 0.05, 0.95)
	poss_bar.queue_redraw()


func _add_event(e: Dictionary):
	if e.x == "" or feed == null or not is_instance_valid(feed):
		return
	var meta = EV.get(e.t, EV["info"])
	var col = Color(meta[1])
	var big = e.t == "goal" or e.t == "red" or e.t == "ht" or e.t == "ft"
	var r = UI.panel(Color(col, 0.12) if big else Color(1, 1, 1, 0.03), 16, 14, 10, Color(col, 0.4) if big else Color(0, 0, 0, 0))
	var h = UI.hb(12)
	var ml = UI.lbl("%d'" % min(e.m, 90), 22, col if big else UI.DIM, "disp")
	ml.custom_minimum_size = Vector2(44, 0)
	h.add_child(ml)
	h.add_child(UI.icon(meta[0], 24, col))
	h.add_child(UI.wrap(e.x, 22, UI.TEXT if big or e.t == "save" else UI.MUTED, "semi" if big else "body"))
	r.add_child(h)
	feed.add_child(r)
	feed.move_child(r, 0)
	if feed.get_child_count() > 70:
		feed.get_child(feed.get_child_count() - 1).queue_free()


# ---------------------------------------------------------------- in-match management

func _team_sheet():
	paused = true
	if stage == "live":
		_build_ctrl()
	var t = sim.sd[us]
	var c = G.uc()
	var build_sheet = func(v):
		v.add_child(UI.caps("Touchline shouts", 20, UI.MUTED))
		var shh = UI.hb(6)
		for k in sim.SHOUTS.keys():
			var on = t.shout == k
			var ch = UI.chip(sim.SHOUTS[k].to_upper(), Color(UI.accent, 0.2) if on else Color(1, 1, 1, 0.06), UI.accent if on else UI.TEXT, 18)
			ch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			ch.custom_minimum_size = Vector2(0, 56)
			var kk = k
			UI.tap(ch, func():
				if sim.shout(us, kk):
					_add_event(sim.ev("info", us, "%s's manager shouts from the touchline: \"%s!\"" % [t.club.name, sim.SHOUTS[kk]]))
				else:
					UI.toast("You can only demand more once per match", UI.RED)
				_team_sheet(), true)
			shh.add_child(ch)
		v.add_child(shh)
		v.add_child(UI.caps("Mentality", 20, UI.MUTED))
		v.add_child(UI.seg(MENT_SHORT, t.ment, func(i):
			t.ment = i
			sim.recalc(us)
			_team_sheet(), 20))
		v.add_child(UI.caps("Pressing", 20, UI.MUTED))
		v.add_child(UI.seg(G.PRESSING, t.press, func(i):
			t.press = i
			sim.recalc(us)
			_team_sheet(), 20))
		v.add_child(UI.caps("Tempo", 20, UI.MUTED))
		v.add_child(UI.seg(G.TEMPO, t.tempo, func(i):
			t.tempo = i
			sim.recalc(us)
			_team_sheet(), 20))
		var have = false
		for pr in c.presets:
			if pr != null:
				have = true
		if have:
			v.add_child(UI.caps("Switch to preset", 20, UI.MUTED))
			var ph = UI.hb(8)
			for i in 3:
				var pr = c.presets[i]
				if pr == null:
					continue
				var b = UI.btn("%d · %s" % [i + 1, pr.formation], func():
					sim.set_shape(us, pr.slots, pr.roles, pr.instr)
					t.formation = pr.formation
					t.ment = pr.ment
					t.press = pr.press
					t.tempo = pr.tempo
					sim.recalc(us)
					_add_event(sim.ev("info", us, "%s change shape to %s." % [t.club.name, pr.formation]))
					_team_sheet(), "secondary", "", 60)
				b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				ph.add_child(b)
			v.add_child(ph)
		v.add_child(UI.section("On the pitch", "Subs used %d / 5" % t.subs))
		if sub_out < 0:
			v.add_child(UI.caps("Tap a player to take him off", 18, UI.DIM))
		for k in 11:
			var pid = t.xi[k]
			if pid < 0:
				continue
			var kk = k
			v.add_child(_sub_row(G.s.players[pid], t.roles[k], sim.pm[pid].cond, sub_out == k, func():
				sub_out = -1 if sub_out == kk else kk
				_team_sheet()))
		if sub_out >= 0:
			v.add_child(UI.section("Bring on"))
			for pid in t.bench:
				var pp = pid
				v.add_child(_sub_row(G.s.players[pid], G.s.players[pid].pos, sim.pm[pid].cond, false, func():
					if t.subs >= 5:
						UI.toast("No substitutions left", UI.RED)
						return
					sim.do_sub(us, sub_out, pp)
					_add_event(sim.events[sim.events.size() - 1])
					sub_out = -1
					_team_sheet()))
		v.add_child(UI.btn("Done", func(): UI.close_sheet(), "primary", "check", 72))
	UI.sheet("Team management", build_sheet)


func _sub_row(p: Dictionary, role: String, cond: float, on: bool, cb: Callable) -> Control:
	var r = UI.panel(Color(UI.accent, 0.16) if on else UI.CARD, 16, 14, 10, UI.accent if on else UI.LINE)
	var h = UI.hb(12)
	h.add_child(UI.pos(role))
	h.add_child(UI.lbl_fill(G.pname(p), 24, UI.TEXT, "semi"))
	h.add_child(UI.caps("%d%%" % int(cond), 19, UI.cond_color(cond)))
	h.add_child(UI.ovr(p.ovr, 22))
	r.add_child(h)
	UI.tap(r, cb)
	return r


# ---------------------------------------------------------------- full time

func _exit_tree():
	UI.ambience(false)


func _show_ft():
	UI.ambience(false)
	for c in lower.get_children():
		lower.remove_child(c)
		c.queue_free()
	feed = null
	tab_holder.visible = false
	banner.visible = false
	pitch.shot_mode = true
	pitch.queue_redraw()
	var me = sim.sd[us]
	var op = sim.sd[1 - us]
	var v = UI.vb(12)
	var sc2 = UI.scroll(UI.margin(v, 20, 0, 20, 24))
	sc2.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lower.add_child(sc2)
	var w = sim.winner()
	var res = "DRAW"
	var col = UI.MUTED
	if w == us or me.goals > op.goals:
		res = "VICTORY"
		col = UI.GREEN
	elif w == 1 - us or me.goals < op.goals:
		res = "DEFEAT"
		col = UI.RED
	var head = UI.panel(Color(col, 0.12), 22, 20, 12, Color(col, 0.4))
	var hh = UI.hb(12)
	hh.add_child(UI.lbl(res, 42, col, "xbold"))
	hh.add_child(UI.sp())
	hh.add_child(UI.caps("Pens %d–%d" % [sim.pens[0], sim.pens[1]] if sim.pens != null else "Shot map above · gold = goal", 18, UI.MUTED))
	head.add_child(hh)
	v.add_child(head)
	v.add_child(UI.btn("Continue", _finish, "primary", "chevron-right", 84))
	if sim.motm >= 0:
		var mp = G.s.players[sim.motm]
		var mc = UI.panel(Color(UI.GOLD, 0.1), 20, 18, 12, Color(UI.GOLD, 0.35))
		var mh = UI.hb(12)
		mh.add_child(UI.icon("star-f", 28, UI.GOLD))
		var mv = UI.vb(-2)
		mv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mv.add_child(UI.caps("Player of the match", 18, UI.GOLD))
		mv.add_child(UI.lbl_fill("%s · %s" % [G.pname(mp), G.s.clubs[mp.club].short], 26, UI.TEXT, "semi"))
		mh.add_child(mv)
		mh.add_child(UI.lbl("%.1f" % sim.pm[sim.motm].r, 36, UI.GOLD, "xbold"))
		mc.add_child(mh)
		v.add_child(mc)
	v.add_child(UI.section("Match stats"))
	v.add_child(_momentum())
	v.add_child(_stats_card())
	v.add_child(UI.section("Your player ratings"))
	var list = []
	for pid in sim.pm:
		if sim.pm[pid].tin >= 0 and G.s.players[pid].club == me.cid:
			list.append(pid)
	list.sort_custom(func(x, y): return sim.pm[x].r > sim.pm[y].r)
	for pid in list:
		var p = G.s.players[pid]
		var q = sim.pm[pid]
		var r = UI.panel(UI.CARD, 16, 14, 8, UI.LINE)
		var rh = UI.hb(10)
		rh.add_child(UI.pos(p.pos, 18))
		rh.add_child(UI.lbl_fill(G.pname(p), 23, UI.TEXT, "semi"))
		var bits = []
		if q.g > 0: bits.append("%d G" % q.g)
		if q.a > 0: bits.append("%d A" % q.a)
		if q.yc > 0: bits.append("YC")
		if q.rc > 0: bits.append("RC")
		if q.inj > 0: bits.append("INJ")
		if q.tin > 0: bits.append("sub %d'" % q.tin)
		if bits.size() > 0:
			rh.add_child(UI.caps(" · ".join(bits), 17, UI.MUTED))
		var rc = UI.GOLD if q.r >= 8.0 else (UI.GREEN if q.r >= 7.0 else (UI.TEXT if q.r >= 6.0 else UI.RED))
		rh.add_child(UI.chip("%.1f" % q.r, Color(rc, 0.14), rc, 24, 62))
		r.add_child(rh)
		v.add_child(r)


func _finish():
	if applied:
		return
	applied = true
	UI.toast("Simulating other matches…", UI.MUTED)
	await get_tree().process_frame
	await get_tree().process_frame
	G.apply_match(sim)
	for o in others:
		if not o.fx.played:
			G.apply_match(o)
	G.play_day_fixtures()
	G.save_game()
	UI.main.root("home")

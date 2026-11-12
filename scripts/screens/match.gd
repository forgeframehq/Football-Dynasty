extends "res://scripts/screens/screen.gd"
# Match day: pre-match briefing, live match with commentary, full-time report.

const PITCH = preload("res://scripts/widgets/pitch.gd")
const SPEEDS = [0.85, 0.4, 0.13]
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
var ball_tw: Tween


func can_leave() -> bool:
	return stage == "pre"


func on_resume():
	if stage == "pre":
		refresh()


func build():
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
	var cap = UI.caps(f.label if f.ko else "%s · Round %d" % [s.leagues[f.lg].name, f.rd], 21, UI.accent)
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
		var slots = G.FORMATIONS[lu[i].formation]
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


func _kickoff():
	sim = G.new_sim(f, true)
	stage = "live"
	refresh()


func _quick():
	sim = G.new_sim(f, true)
	sim.sd[us].auto = true
	sim.run_to_end()
	stage = "ft"
	refresh()


# ---------------------------------------------------------------- live

func _build_live():
	var s = G.s
	var h = sim.sd[0]
	var a = sim.sd[1]
	var sb = UI.panel(UI.CARD, 26, 18, 14, UI.LINE)
	var sv = UI.vb(6)
	var cap = UI.caps(f.label if f.ko else "%s · Round %d" % [s.leagues[f.lg].name, f.rd], 18, UI.DIM)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sv.add_child(cap)
	var row = UI.hb(10)
	row.add_child(UI.badge(h.club, 78))
	var hn = UI.lbl_fill(h.club.short, 44, UI.TEXT, "xbold")
	row.add_child(hn)
	var mid = UI.vb(-2)
	score_l = UI.lbl("0 – 0", 76, UI.TEXT, "xbold")
	score_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mid.add_child(score_l)
	row.add_child(mid)
	var an = UI.lbl_fill(a.club.short, 44, UI.TEXT, "xbold")
	an.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(an)
	row.add_child(UI.badge(a.club, 78))
	sv.add_child(row)
	var mc = UI.chip("0'", Color(UI.accent, 0.16), UI.accent, 24, 90)
	mc.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	min_l = mc.get_child(0)
	sv.add_child(mc)
	var sh = UI.hb(16)
	sc_l = []
	for i in 2:
		var l = UI.wrap("", 18, UI.MUTED)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if i == 0 else HORIZONTAL_ALIGNMENT_RIGHT
		sc_l.append(l)
		sh.add_child(l)
	sv.add_child(sh)
	sb.add_child(sv)
	body.add_child(UI.margin(sb, 20, 4, 20, 10))
	pitch = PITCH.new()
	pitch.vertical = false
	pitch.ball_on = true
	pitch.custom_minimum_size = Vector2(0, 290)
	body.add_child(UI.margin(pitch, 20, 0, 20, 10))
	# stats strip
	var st = UI.panel(UI.CARD, 22, 18, 12, UI.LINE)
	var stv = UI.vb(8)
	var pr = UI.hb(12)
	stat_l["ph"] = UI.lbl("50%", 24, UI.TEXT, "disp")
	stat_l["pa"] = UI.lbl("50%", 24, UI.TEXT, "disp")
	pr.add_child(stat_l["ph"])
	var hcol = Color(h.club.c1) if Color(h.club.c1).get_luminance() > 0.12 else Color(h.club.c2)
	var acol = Color(a.club.c1) if Color(a.club.c1).get_luminance() > 0.12 else Color(a.club.c2)
	if abs(hcol.h - acol.h) < 0.06 and abs(hcol.v - acol.v) < 0.3:
		acol = Color(a.club.c2) if Color(a.club.c2).get_luminance() > 0.12 else Color("8b96ab")
	poss_bar = UI.bar(0.5, hcol, 12, acol)
	pr.add_child(poss_bar)
	pr.add_child(stat_l["pa"])
	stv.add_child(pr)
	var sr = UI.hb(0)
	for k in [["shots", "Shots (on target)"], ["xg", "xG"], ["cards", "Corners · cards"]]:
		var cell = UI.hb(8)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.alignment = BoxContainer.ALIGNMENT_CENTER
		stat_l[k[0] + "h"] = UI.lbl("0", 22, UI.TEXT, "disp")
		stat_l[k[0] + "a"] = UI.lbl("0", 22, UI.TEXT, "disp")
		cell.add_child(stat_l[k[0] + "h"])
		cell.add_child(UI.caps(k[1], 15, UI.DIM))
		cell.add_child(stat_l[k[0] + "a"])
		sr.add_child(cell)
	stv.add_child(sr)
	st.add_child(stv)
	body.add_child(UI.margin(st, 20, 0, 20, 10))
	lower = Control.new()
	lower.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lower.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lower.clip_contents = true
	body.add_child(lower)
	feed = UI.vb(8)
	var fs = UI.scroll(UI.margin(feed, 20, 0, 20, 12))
	fs.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lower.add_child(fs)
	ctrl = UI.hb(10)
	body.add_child(UI.margin(ctrl, 20, 8, 20, 18))
	_build_ctrl()
	_update()
	for e in sim.events:
		if e.x != "":
			_add_event(e)


func _build_ctrl():
	for c in ctrl.get_children():
		ctrl.remove_child(c)
		c.queue_free()
	if stage == "ft":
		ctrl.get_parent().visible = false
		return
	if stage == "ht":
		var b = UI.btn("Start second half", func():
			stage = "live"
			paused = false
			sim.resume()
			_build_ctrl(), "primary", "play", 80)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ctrl.add_child(b)
		ctrl.add_child(UI.btn("Team", _team_sheet, "secondary", "repeat", 80))
		return
	var pb = UI.panel(UI.accent, 20, 24, 0)
	pb.custom_minimum_size = Vector2(0, 80)
	pb.add_child(UI.icon("play" if paused else "pause", 34, UI.on_color(UI.accent)))
	UI.tap(pb, func():
		paused = not paused
		_build_ctrl(), true)
	ctrl.add_child(pb)
	var sg = UI.seg(["1x", "2x", "4x"], speed, func(i):
		speed = i
		_build_ctrl(), 24)
	sg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sg.custom_minimum_size = Vector2(0, 80)
	ctrl.add_child(sg)
	ctrl.add_child(UI.btn("Team", _team_sheet, "secondary", "repeat", 80))
	var sk = UI.panel(UI.CARD2, 20, 22, 0, Color(1, 1, 1, 0.1))
	sk.custom_minimum_size = Vector2(0, 80)
	sk.add_child(UI.icon("fast-forward", 32, UI.TEXT))
	UI.tap(sk, _skip, true)
	ctrl.add_child(sk)


func _process(delta):
	if stage != "live" or paused or sim == null or UI.main.sheet_node != null:
		return
	if hold > 0.0:
		hold -= delta
		return
	acc += delta
	if acc >= SPEEDS[speed]:
		acc = 0.0
		_tick()


func _tick():
	var evs = sim.step()
	for e in evs:
		_add_event(e)
		if e.t == "goal":
			hold = 1.4 if speed < 2 else 0.5
			var tw = create_tween()
			tw.tween_method(pitch.set_flash, 1.0, 0.0, 1.2)
	_update()
	if sim.phase == 2:
		stage = "ht"
		_build_ctrl()
	elif sim.phase == 4:
		stage = "ft"
		_build_ctrl()
		_show_ft()


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
	poss_bar.frac = clamp(ph / 100.0, 0.05, 0.95)
	poss_bar.queue_redraw()
	stat_l["shotsh"].text = "%d (%d)" % [h.shots, h.sot]
	stat_l["shotsa"].text = "%d (%d)" % [a.shots, a.sot]
	stat_l["xgh"].text = "%.2f" % h.xg
	stat_l["xga"].text = "%.2f" % a.xg
	stat_l["cardsh"].text = "%d · %d" % [h.corners, h.yc + h.rc]
	stat_l["cardsa"].text = "%d · %d" % [a.corners, a.yc + a.rc]
	var side = sim.sd[sim.ball_side].club
	var col = Color(side.c1) if Color(side.c1).get_luminance() > 0.12 else Color(side.c2)
	pitch.ball_color = col
	pitch.label = sim.ball_state if sim.ball_state != "" and sim.phase != 4 else ""
	pitch.label_color = UI.GOLD if sim.ball_state == "GOAL" else Color.WHITE
	if ball_tw != null and ball_tw.is_valid():
		ball_tw.kill()
	ball_tw = create_tween()
	ball_tw.tween_method(pitch.set_ball, pitch.ball, sim.ball, min(0.5, SPEEDS[speed] * 0.8)).set_trans(Tween.TRANS_SINE)


func _add_event(e: Dictionary):
	if e.x == "" or feed == null:
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
	var build_sheet = func(v):
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

func _show_ft():
	for c in lower.get_children():
		lower.remove_child(c)
		c.queue_free()
	feed = null
	var h = sim.sd[0]
	var a = sim.sd[1]
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
	var head = UI.panel(Color(col, 0.12), 22, 20, 14, Color(col, 0.4))
	var hh = UI.hb(12)
	hh.add_child(UI.lbl(res, 44, col, "xbold"))
	hh.add_child(UI.sp())
	if sim.pens != null:
		hh.add_child(UI.caps("Pens %d–%d" % [sim.pens[0], sim.pens[1]], 22, UI.TEXT))
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
	var stc = UI.card()
	var stv = UI.vb(8)
	var tp = max(1, h.poss + a.poss)
	var rows = [["Possession", "%d%%" % int(round(100.0 * h.poss / tp)), "%d%%" % (100 - int(round(100.0 * h.poss / tp)))], ["Shots", str(h.shots), str(a.shots)], ["On target", str(h.sot), str(a.sot)],
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
	v.add_child(stc)
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
	G.play_day_fixtures()
	G.save_game()
	UI.main.root("home")

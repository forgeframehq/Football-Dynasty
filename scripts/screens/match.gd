extends "res://scripts/screens/screen.gd"
# Match day: pre-match briefing, live match with commentary, full-time report.

const PITCH = preload("res://scripts/widgets/match_pitch.gd")
const MOM = preload("res://scripts/widgets/momentum.gd")
const VIEW3D = preload("res://scripts/widgets/match3d.gd")
const VIEWS = ["Watch", "Key moments", "Text only"]
const SPEEDS = [0.85, 0.4, 0.13, 0.85]
const TABS = ["Feed", "Stats", "Line-ups", "Live"]
const MENT_SHORT = ["Bus", "Def", "Bal", "Att", "All out"]
const EV = {"goal": ["zap", "e9c46a"], "save": ["shield", "4da3ff"], "miss": ["x", "8b96ab"], "yellow": ["square", "f6ad3c"], "red": ["square", "ff5c72"],
	"sub": ["repeat", "2ee59d"], "injury": ["bandage", "ff5c72"], "info": ["activity", "5b6680"], "ht": ["clock", "f3f6fb"], "ft": ["clock", "f3f6fb"]}

var f: Dictionary
var sim = null
var stage := "pre"
var us := 0
var speed: int = int(G.settings.get("speed", 0))
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
var view3d = null            # the 3D pitch, when the match is being watched
var vmode: int = int(G.settings.get("view", 1))   # 0 watch the match, 1 key moments, 2 text only
var deferred: Array = []     # events held back until the staged move on the pitch reaches its outcome
var snap = null              # the club's tactics before kick-off, put back at full time
var replays: Array = []      # goals queued for a replay after a sim
var replaying := false
var ht_panel: Control = null
var pitch_box: Control = null
const STADIUM = preload("res://scripts/widgets/stadium_view.gd")


func can_leave() -> bool:
	return stage == "pre"


func on_resume():
	if stage == "pre":
		refresh()
	elif G.live != null:
		# back from the full Tactics screen: everything changed there is already in the match
		var n0 = int(G.live.get("ev0", sim.events.size()))
		G.live_sync()
		G.live = null
		for i in range(n0, sim.events.size()):
			_add_event(sim.events[i])
		_update()
		_refresh_tab()
		if stage == "ht":
			_show_ht()
		else:
			_build_ctrl()
		UI.main._update_chrome()


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
	# one dense page, nothing to scroll: fixture, comparison, how the plans meet, both line-ups, kick-off
	var s = G.s
	var hc = s.clubs[f.h]
	var ac = s.clubs[f.a]
	var uid = s.user.club
	var changes = G.fix_lineup()
	var opp = ac if f.h == uid else hc
	var rep = G.TC.report(uid, opp.id)
	var wx = G.weather(f)
	var root = UI.vb(8)
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var rm = UI.margin(root, 16, 10, 16, 10)
	rm.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(rm)
	# ---- row A: fixture card and comparison
	var ra_ = UI.hb(10)
	ra_.custom_minimum_size = Vector2(0, 196)
	root.add_child(ra_)
	var fxc = UI.panel(UI.CARD, 16, 0, 0, Color(UI.accent, 0.45))
	fxc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fxc.size_flags_stretch_ratio = 1.55
	fxc.clip_contents = true
	var layer = Control.new()
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fxc.add_child(layer)
	if not G.settings.get("lowgfx", false):
		var sv = STADIUM.new()
		var d0 = G.date(int(f.day))
		sv.night = d0.weekday in [2, 3] or d0.month in [11, 12, 1]
		sv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		layer.add_child(sv)
	var shade = ColorRect.new()
	shade.color = Color(UI.BG, 0.62)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(shade)
	var fv = UI.vb(2)
	var top = UI.hb(8)
	var bk = UI.panel(Color(0, 0, 0, 0.35), 10, 8, 4)
	bk.add_child(UI.icon("chevron-left", 22, UI.TEXT))
	UI.tap(bk, func(): UI.main.root("home"), true)
	top.add_child(bk)
	var cap = UI.caps(G.fx_caption(f) + (" · derby" if G.is_derby(f.h, f.a) else ""), 17, UI.accent.lightened(0.3))
	cap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(cap)
	var wch = UI.panel(Color(0, 0, 0, 0.35), 10, 10, 4)
	var wh = UI.hb(6)
	wh.add_child(UI.icon(str(wx.i), 18, UI.TEXT))
	wh.add_child(UI.lbl("%s · %d°" % [wx.n, int(wx.temp)], 16, UI.TEXT, "semi"))
	wch.add_child(wh)
	top.add_child(wch)
	fv.add_child(top)
	var mh = UI.hb(8)
	mh.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mh.add_child(_side(hc))
	var vs = UI.vb(-4)
	vs.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var vl = UI.lbl("VS", 40, UI.TEXT, "xbold")
	vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vs.add_child(vl)
	if int(f.get("leg", 0)) == 2 and f.has("first"):
		var f1 = s.fixtures[int(f.first)]
		var al = UI.caps("1st leg %d–%d" % [int(f1.ag), int(f1.hg)], 15, UI.GOLD)
		al.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vs.add_child(al)
	mh.add_child(vs)
	mh.add_child(_side(ac))
	fv.add_child(mh)
	var ven = UI.caps("%s · %s" % [hc.stadium if hc.stadium != "" else hc.name, G.fmt_date(int(f.day))], 15, UI.MUTED)
	ven.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fv.add_child(ven)
	fxc.add_child(UI.margin(fv, 12, 8, 12, 6))
	ra_.add_child(fxc)
	var rh = G.team_ratings(f.h)
	var ra = G.team_ratings(f.a)
	var cc = UI.panel(UI.CARD, 16, 14, 8, UI.LINE)
	cc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cv = UI.vb(3)
	var ch = UI.hb(6)
	ch.add_child(UI.lbl(hc.short, 17, UI.TEXT, "disp"))
	var cm = UI.caps("Strength", 14, UI.DIM)
	cm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ch.add_child(cm)
	ch.add_child(UI.lbl(ac.short, 17, UI.TEXT, "disp"))
	cv.add_child(ch)
	for k in [["Overall", "ovr"], ["Attack", "att"], ["Midfield", "mid"], ["Defence", "def"]]:
		var r = UI.hb(8)
		var a = UI.lbl(str(rh[k[1]]), 22, UI.ovr_color(rh[k[1]]), "disp")
		a.custom_minimum_size = Vector2(34, 0)
		r.add_child(a)
		var lb = UI.bar((rh[k[1]] - 45) / 50.0, _col(hc), 7)
		lb.scale.x = -1
		lb.resized.connect(func(): lb.pivot_offset = lb.size / 2.0)
		r.add_child(lb)
		var l = UI.caps(k[0], 14, UI.MUTED)
		l.custom_minimum_size = Vector2(74, 0)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		r.add_child(l)
		r.add_child(UI.bar((ra[k[1]] - 45) / 50.0, _col(ac), 7))
		var b = UI.lbl(str(ra[k[1]]), 22, UI.ovr_color(ra[k[1]]), "disp")
		b.custom_minimum_size = Vector2(34, 0)
		b.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		r.add_child(b)
		cv.add_child(r)
	var vd = UI.panel(Color(rep.col, 0.14), 10, 10, 5, Color(rep.col, 0.4))
	var vdh = UI.hb(8)
	vdh.add_child(UI.caps("Match-up", 14, UI.MUTED))
	vdh.add_child(UI.lbl_fill(rep.verdict, 19, rep.col, "bold"))
	vdh.add_child(UI.caps("they play %s" % rep.style, 14, UI.AMBER if rep.changed else UI.MUTED))
	vd.add_child(vdh)
	cv.add_child(vd)
	cc.add_child(cv)
	ra_.add_child(cc)
	# ---- row B: advantage, threat, key man, kick-off
	var rb = UI.hb(10)
	rb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(rb)
	var mk = func(title: String, col: Color) -> VBoxContainer:
		var p = UI.panel(UI.CARD, 16, 14, 8, Color(col, 0.35))
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p.clip_contents = true
		var v = UI.vb(4)
		v.add_child(UI.caps(title, 15, col))
		p.add_child(v)
		rb.add_child(p)
		return v
	var av = mk.call("Your advantage", UI.GREEN)
	for k in min(3, rep.good.size()):
		var ph = UI.hb(6)
		ph.add_child(UI.icon("trending-up", 16, UI.GREEN))
		ph.add_child(UI.wrap(str(rep.good[k][1]) + ".", 16, UI.TEXT))
		av.add_child(ph)
	var mine_r = rh if f.h == uid else ra
	var their_r = ra if f.h == uid else rh
	var units = [["Your attack against their defence", mine_r.att - their_r.def], ["Midfield against midfield", mine_r.mid - their_r.mid], ["Your defence against their attack", mine_r.def - their_r.att]]
	for u in units:
		if u[1] >= 2 and av.get_child_count() < 5:
			var uh = UI.hb(6)
			uh.add_child(UI.icon("plus", 16, UI.GREEN))
			uh.add_child(UI.wrap("%s: %+d." % [u[0], u[1]], 16, UI.TEXT))
			av.add_child(uh)
	if f.h == uid:
		av.add_child(UI.wrap("Home crowd behind you.", 15, UI.MUTED))
	if av.get_child_count() <= 1:
		av.add_child(UI.wrap("Nothing in your plan gives you an edge over theirs today. Open Tactics and try another playstyle or line.", 16, UI.MUTED))
	if str(wx.k) not in ["clear", "cloud"]:
		var wr = UI.hb(6)
		wr.add_child(UI.icon(str(wx.i), 16, UI.BLUE))
		wr.add_child(UI.wrap("%s: %s" % [wx.n, wx.d], 15, UI.MUTED))
		av.add_child(wr)
	var tv = mk.call("Their threat", UI.RED)
	if rep.changed:
		tv.add_child(UI.wrap("They have switched to %s (usually %s) to stop you." % [rep.style, rep.usual], 16, UI.AMBER))
	for k in min(2 if rep.changed else 3, rep.bad.size()):
		var ph2 = UI.hb(6)
		ph2.add_child(UI.icon("trending-down", 16, UI.RED))
		ph2.add_child(UI.wrap(str(rep.bad[k][1]) + ".", 16, UI.TEXT))
		tv.add_child(ph2)
	for u in units:
		if u[1] <= -2 and tv.get_child_count() < 5:
			var uh2 = UI.hb(6)
			uh2.add_child(UI.icon("minus", 16, UI.RED))
			uh2.add_child(UI.wrap("%s: %d." % [u[0], u[1]], 16, UI.TEXT))
			tv.add_child(uh2)
	if f.h != uid:
		tv.add_child(UI.wrap("Away from home: their crowd, their pitch.", 15, UI.MUTED))
	tv.add_child(UI.wrap("Form: %s. %s in the table with %d points." % [_form_txt(opp), G.LG.ordinal(G.LG.position(opp.id)), opp.t.pts], 15, UI.MUTED))
	if not rep.pair.is_empty():
		tv.add_child(UI.wrap("Link-up to watch: %s, %s to %s." % [rep.link, G.pname(s.players[rep.pair[0]]), G.pname(s.players[rep.pair[1]])], 15, UI.AMBER))
	var kv = mk.call("Key man", UI.GOLD)
	if rep.stars.size() > 0:
		var sp = rep.stars[0]
		var kh = UI.hb(8)
		kh.add_child(UI.pos(sp.pos, 16))
		kh.add_child(UI.lbl_fill(G.pname(sp), 22, UI.TEXT, "bold"))
		kh.add_child(UI.ovr(sp.ovr, 19))
		kv.add_child(kh)
		kv.add_child(UI.lbl_fill("%d goals · %d assists · form %.1f" % [sp.ss.g, sp.ss.a, float(sp.form)], 15, UI.MUTED))
		var marked = int(G.uc().get("tm_pid", -1)) == sp.id
		kv.add_child(UI.wrap("You are tight-marking him." if marked else "Not marked. Tactics > Defence can put a man on him.", 15, UI.GREEN if marked else UI.AMBER))
		for k in range(1, min(3, rep.stars.size())):
			var o2 = rep.stars[k]
			var oh = UI.hb(8)
			oh.add_child(UI.pos(o2.pos, 14))
			oh.add_child(UI.lbl_fill(G.pname(o2), 17, UI.TEXT))
			oh.add_child(UI.lbl(str(o2.ovr), 17, UI.ovr_color(o2.ovr), "disp"))
			kv.add_child(oh)
	if changes.size() > 0:
		kv.add_child(UI.wrap("Your XI changed: " + ", ".join(changes), 14, UI.AMBER))
	var act = UI.vb(6)
	act.custom_minimum_size = Vector2(300, 0)
	rb.add_child(act)
	act.add_child(UI.seg(VIEWS, vmode, func(i):
		vmode = i
		G.settings["view"] = i
		G.save_settings()
		refresh(), 15, 6))
	var ko = UI.btn("Kick off", _kickoff, "primary", "play", 70)
	ko.size_flags_vertical = Control.SIZE_EXPAND_FILL
	act.add_child(ko)
	var bh = UI.hb(6)
	var tb = UI.btn("Tactics", func(): UI.main.open("tactics"), "secondary", "layout-grid", 48)
	tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bh.add_child(tb)
	var qb = UI.btn("Quick result", _quick, "secondary", "fast-forward", 48)
	qb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bh.add_child(qb)
	act.add_child(bh)
	var bh2 = UI.hb(6)
	var hb1 = UI.btn("To half-time", func():
		_kickoff()
		_sim_to(45, false), "ghost", "skip-forward", 40)
	hb1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bh2.add_child(hb1)
	var hb2 = UI.btn("Sim rules", _sim_rules, "ghost", "sliders-horizontal", 40)
	hb2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bh2.add_child(hb2)
	act.add_child(bh2)
	# ---- row C: both line-ups along the bottom
	var lu = [rep.ulu, rep.olu] if f.h == uid else [rep.olu, rep.ulu]
	for i in 2:
		var row = UI.hb(4)
		var hd = UI.vb(-5)
		hd.custom_minimum_size = Vector2(74, 0)
		hd.add_child(UI.lbl(s.clubs[lu[i].club].short, 17, UI.accent.lightened(0.3) if i == us else UI.TEXT, "disp"))
		hd.add_child(UI.lbl(str(lu[i].formation), 13, UI.MUTED))
		row.add_child(hd)
		for k in 11:
			var pid = lu[i].xi[k]
			var chp = UI.panel(Color(1, 1, 1, 0.05), 8, 6, 2)
			chp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			chp.clip_contents = true
			var cvv = UI.vb(-5)
			var t1 = UI.hb(4)
			t1.add_child(UI.lbl(str(lu[i].slots[k][0]), 12, UI.LINE_COL[G.LINE[lu[i].slots[k][0]]], "bold"))
			t1.add_child(UI.sp())
			if pid >= 0:
				t1.add_child(UI.lbl(str(s.players[pid].ovr), 13, UI.ovr_color(s.players[pid].ovr), "disp"))
			cvv.add_child(t1)
			var nl = UI.lbl(str(s.players[pid].ln if s.players[pid].get("cn", "") == "" else s.players[pid].cn) if pid >= 0 else "—", 15, UI.TEXT, "semi")
			nl.clip_text = true
			cvv.add_child(nl)
			chp.add_child(cvv)
			row.add_child(chp)
		root.add_child(row)


func _form_txt(c: Dictionary) -> String:
	var a = []
	for r in c.form.slice(max(0, c.form.size() - 5)):
		a.append(str(r) if r is String else ["L", "D", "W"][clampi(int(r), 0, 2)])
	return " ".join(a) if a.size() > 0 else "no games yet"


func _sim_rules():
	var st = G.settings
	UI.sheet("Sim rules", func(v):
		v.add_child(UI.wrap("When you sim part of a match, it stops for the things ticked here. The rest is shown afterwards in “What you missed”.", 17, UI.MUTED))
		for k in [["ss_goal", "Any goal", true], ["ss_behind", "My team goes behind", true], ["ss_red", "A red card", true], ["ss_inj", "An injury to my player", true],
				["auto_fr", "Always quick-result friendlies", false]]:
			var on = bool(st.get(k[0], k[2]))
			var r = UI.panel(Color(UI.accent, 0.14) if on else Color(1, 1, 1, 0.04), 10, 12, 8)
			var rh2 = UI.hb(8)
			rh2.add_child(UI.icon("square-check" if on else "square", 22, UI.accent if on else UI.DIM))
			rh2.add_child(UI.lbl_fill(k[1], 19, UI.TEXT if on else UI.MUTED, "semi"))
			r.add_child(rh2)
			var kk = k[0]
			var dflt = k[2]
			UI.tap(r, func():
				st[kk] = not bool(st.get(kk, dflt))
				G.save_settings()
				_sim_rules(), true)
			v.add_child(r))


func _side(c: Dictionary) -> Control:
	var v = UI.vb(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(UI.center(UI.badge(c, 74)))
	var l = UI.lbl(c.name.to_upper(), 22, UI.TEXT, "disp")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.clip_text = true
	v.add_child(l)
	var ps = UI.caps("%s · %d pts" % [G.LG.ordinal(G.LG.position(c.id)), c.t.pts], 14, UI.MUTED)
	ps.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(ps)
	var fd = UI.form_dots(c.form, 10)
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


func _snapshot():
	var c = G.uc()
	snap = {"pr": G.make_preset(c), "xi": c.xi.duplicate(), "bench": c.bench.duplicate()}


func _restore():
	# in-match changes were for this match only
	if snap == null:
		return
	var c = G.uc()
	G.apply_preset(c, snap.pr)
	c.xi = snap.xi.duplicate()
	c.bench = snap.bench.duplicate()
	snap = null
	G.live = null


func _kickoff():
	_snapshot()
	sim = G.new_sim(f, true)
	_start_others()
	UI.sfx("whistle")
	UI.sfx("vo_kickoff", -4.0)
	UI.ambience(true)
	UI.music_duck(true)
	stage = "live"
	refresh()


func _quick():
	_snapshot()
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
	var sb = UI.panel(UI.CARD, 14, 16, 2, UI.LINE)
	var row = UI.hb(12)
	row.add_child(UI.badge(h.club, 44))
	var hn = UI.lbl(h.club.short, 32, UI.TEXT, "xbold")
	row.add_child(hn)
	sc_l = []
	var l0 = UI.wrap("", 16, UI.MUTED)
	l0.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l0.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sc_l.append(l0)
	row.add_child(l0)
	var mid = UI.vb(-8)
	mid.custom_minimum_size = Vector2(230, 0)
	score_l = UI.lbl("0 – 0", 44, UI.TEXT, "xbold")
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
	row.add_child(UI.lbl(a.club.short, 32, UI.TEXT, "xbold"))
	row.add_child(UI.badge(a.club, 44))
	sb.add_child(row)
	body.add_child(UI.margin(sb, 14, 6, 14, 6))
	var hbx = UI.hb(10)
	hbx.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var hm = UI.margin(hbx, 14, 0, 14, 8)
	hm.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(hm)
	var left = UI.vb(8)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbx.add_child(left)
	pitch = PITCH.new()
	pitch.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pitch.custom_minimum_size = Vector2(0, 300)
	pitch.setup(sim)
	var pitch_host: Control = pitch
	view3d = null
	if vmode != 2:
		# watching: the 3D pitch takes the place of the flat one (which still works out the two kit colours)
		pitch_host = Control.new()
		pitch_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
		pitch_host.custom_minimum_size = Vector2(0, 300)
		pitch_host.clip_contents = true
		view3d = VIEW3D.new()
		view3d.setup(sim, pitch.cols[0], pitch.cols[1], _second(h.club, pitch.cols[0]), _second(a.club, pitch.cols[1]))
		view3d.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		pitch_host.add_child(view3d)
		view3d.impact.connect(_on_impact)
	left.add_child(pitch_host)
	pitch_box = pitch_host
	ht_panel = null
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
	pitch_host.add_child(bc)
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
	side.custom_minimum_size = Vector2(clamp((UI.main.size.x) * 0.275, 350, 410), 0)
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
		_refresh_tab(), 16, 6)
	var m = UI.margin(sg, 8, 0, 8, 6)
	tab_holder.add_child(m)
	m.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	tab_holder.custom_minimum_size = Vector2(0, 44)


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
		var b = UI.btn("Second half", func(): _resume_ht(-1), "primary", "play", 50)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ctrl.add_child(b)
		ctrl.add_child(UI.btn("Tactics", _open_tactics, "secondary", "layout-grid", 50))
		ctrl.add_child(UI.btn("Sim", _sim_sheet, "secondary", "skip-forward", 50))
		return
	var pb = UI.panel(UI.accent, 14, 20, 0)
	pb.custom_minimum_size = Vector2(0, 50)
	pb.add_child(UI.icon("play" if paused else "pause", 30, UI.on_color(UI.accent)))
	UI.tap(pb, func():
		paused = not paused
		_build_ctrl(), true)
	ctrl.add_child(pb)
	var sg = UI.seg(["1x", "2x", "4x", "Key"], speed, func(i):
		speed = i
		_build_ctrl(), 19, 6)
	sg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sg.custom_minimum_size = Vector2(0, 50)
	ctrl.add_child(sg)
	ctrl.add_child(UI.btn("Tactics", _open_tactics, "secondary", "layout-grid", 50))
	ctrl.add_child(UI.btn("Shouts", _team_sheet, "secondary", "megaphone", 50))
	ctrl.add_child(UI.btn("Sim", _sim_sheet, "secondary", "skip-forward", 50))


func _open_tactics():
	# the full Tactics screen, live: substitutions, shape, roles and instructions all take effect in this match
	if sim == null or stage == "ft" or replaying:
		return
	_flush()
	paused = true
	if stage == "live":
		_build_ctrl()
	var t = sim.sd[us]
	var c = G.uc()
	c.xi = t.xi.duplicate()
	c.bench = t.bench.duplicate()
	c.ment = t.ment
	c.press = t.press
	c.tempo = t.tempo
	G.live = {"sim": sim, "us": us, "ev0": sim.events.size()}
	UI.main.open("tactics")


func _read() -> Array:
	# the assistant's view of how it is going: [text, colour] lines
	var me = sim.sd[us]
	var op = sim.sd[1 - us]
	var out = []
	var tp = max(1, me.poss + op.poss)
	var poss = 100.0 * me.poss / tp
	if me.xg > op.xg + 0.5:
		out.append(["We are making the better chances (%.1f to %.1f expected goals)." % [me.xg, op.xg], UI.GREEN])
	elif op.xg > me.xg + 0.5:
		out.append(["They are making the better chances (%.1f to %.1f expected goals)." % [op.xg, me.xg], UI.RED])
	if poss < 42:
		out.append(["We cannot keep the ball: %d%% possession. A calmer tempo or shorter passing would help." % int(poss), UI.AMBER])
	elif poss > 58 and me.shots <= op.shots:
		out.append(["Plenty of the ball (%d%%) but little to show for it. More direct, or push the mentality up." % int(poss), UI.AMBER])
	var tired = []
	for k in 11:
		var pid = me.xi[k]
		if pid >= 0 and sim.pm[pid].cond < 62:
			tired.append(G.pname(G.s.players[pid]))
	if tired.size() > 0:
		out.append(["Tiring: %s." % ", ".join(tired.slice(0, 3)), UI.AMBER])
	var carded = []
	for k in 11:
		var pid2 = me.xi[k]
		if pid2 >= 0 and sim.pm[pid2].yc > 0:
			carded.append(G.pname(G.s.players[pid2]))
	if carded.size() > 0:
		out.append(["On a yellow: %s." % ", ".join(carded.slice(0, 3)), UI.MUTED])
	if out.is_empty():
		out.append(["An even game so far. Nothing needs changing yet.", UI.MUTED])
	return out


func _show_ht():
	# half-time: the score, the numbers, who is playing well, and the team talk, over the pitch
	if ht_panel != null and is_instance_valid(ht_panel):
		ht_panel.queue_free()
	var me = sim.sd[us]
	var op = sim.sd[1 - us]
	var p = UI.panel(Color(UI.BG, 0.94), 14, 16, 10, Color(UI.accent, 0.5))
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var v = UI.vb(6)
	var hd = UI.hb(10)
	hd.add_child(UI.lbl("HALF-TIME", 26, UI.accent.lightened(0.3), "xbold"))
	hd.add_child(UI.lbl_fill(sim.score_text(), 22, UI.TEXT, "disp"))
	v.add_child(hd)
	var cols = UI.hb(14)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var c1 = UI.vb(3)
	c1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c1.add_child(UI.caps("First half", 14, UI.DIM))
	var tp = max(1, sim.sd[0].poss + sim.sd[1].poss)
	for r in [["Possession", "%d%%" % int(round(100.0 * sim.sd[0].poss / tp)), "%d%%" % (100 - int(round(100.0 * sim.sd[0].poss / tp)))], ["Shots", str(sim.sd[0].shots), str(sim.sd[1].shots)],
			["On target", str(sim.sd[0].sot), str(sim.sd[1].sot)], ["Expected goals", "%.1f" % sim.sd[0].xg, "%.1f" % sim.sd[1].xg], ["Corners", str(sim.sd[0].corners), str(sim.sd[1].corners)], ["Fouls", str(sim.sd[0].fouls), str(sim.sd[1].fouls)]]:
		var rh = UI.hb(6)
		var l1 = UI.lbl(r[1], 19, UI.TEXT, "disp")
		l1.custom_minimum_size = Vector2(50, 0)
		rh.add_child(l1)
		var l2 = UI.caps(r[0], 14, UI.MUTED)
		l2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rh.add_child(l2)
		var l3 = UI.lbl(r[2], 19, UI.TEXT, "disp")
		l3.custom_minimum_size = Vector2(50, 0)
		l3.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		rh.add_child(l3)
		c1.add_child(rh)
	cols.add_child(c1)
	var c2 = UI.vb(3)
	c2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c2.add_child(UI.caps("Your players", 14, UI.DIM))
	var ids = []
	for k in 11:
		if me.xi[k] >= 0:
			ids.append(me.xi[k])
	ids.sort_custom(func(x, y): return sim.live_rating(x) > sim.live_rating(y))
	var show = ids.slice(0, 3)
	if ids.size() > 5:
		show.append_array(ids.slice(ids.size() - 2))
	for pid in show:
		var q = sim.pm[pid]
		var lr = sim.live_rating(pid)
		var rh2 = UI.hb(6)
		rh2.add_child(UI.lbl_fill(G.pname(G.s.players[pid]), 17, UI.TEXT))
		rh2.add_child(UI.caps("%d%%" % int(q.cond), 14, UI.cond_color(q.cond)))
		rh2.add_child(UI.lbl("%.1f" % lr, 18, UI.GOLD if lr >= 7.5 else (UI.GREEN if lr >= 6.8 else (UI.TEXT if lr >= 6.0 else UI.RED)), "disp"))
		c2.add_child(rh2)
	cols.add_child(c2)
	var c3 = UI.vb(3)
	c3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c3.size_flags_stretch_ratio = 1.25
	c3.add_child(UI.caps("Your assistant", 14, UI.DIM))
	for ln in _read().slice(0, 4):
		c3.add_child(UI.wrap(ln[0], 15, ln[1]))
	cols.add_child(c3)
	v.add_child(cols)
	v.add_child(UI.caps("Team talk: pick one to start the second half", 14, UI.accent))
	var th = UI.hb(6)
	for t in [["Well done, keep it going", "heart", 0], ["I expect much more", "zap", 1], ["Stay calm, see it out", "shield", 2]]:
		var kind = t[2]
		var b = UI.btn(t[0], func(): _resume_ht(kind), "secondary", t[1], 46)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		th.add_child(b)
	v.add_child(th)
	p.add_child(v)
	pitch_box.add_child(p)
	ht_panel = p
	_build_ctrl()


func _resume_ht(kind: int):
	var me = sim.sd[us]
	var op = sim.sd[1 - us]
	var diff = me.goals - op.goals
	if kind >= 0:
		var good = diff >= 0 if kind == 0 else ((diff < 0 or (diff == 0 and me.club.rep > op.club.rep + 2)) if kind == 1 else diff > 0)
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
	if ht_panel != null and is_instance_valid(ht_panel):
		ht_panel.queue_free()
	ht_panel = null
	stage = "live"
	paused = false
	sim.recalc(us)
	sim.resume()
	_build_ctrl()


# ---------------------------------------------------------------- simming part of a match

func _flush():
	# anything waiting on a staged move lands now, and the move is dropped
	if not deferred.is_empty():
		var evs = deferred
		deferred = []
		_apply(evs)
	if view3d != null and is_instance_valid(view3d) and view3d.playing():
		view3d.cancel()
	hold = 0.0
	if banner != null:
		banner.visible = false


func _sim_sheet():
	if sim == null or stage == "ft":
		return
	var was = paused
	paused = true
	UI.sheet("Sim ahead", func(v):
		var m = sim.minute
		var row = UI.hb(6)
		var opts = []
		if m < 45 and stage != "ht":
			opts.append(["Half-time", 45])
		for t in [60, 75]:
			if m < t - 4:
				opts.append(["To %d'" % t, t])
		opts.append(["Full time", 999])
		for o in opts:
			var tgt = o[1]
			var b = UI.btn(o[0], func():
				UI.close_sheet()
				_sim_to(tgt, false), "secondary", "skip-forward", 54)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(b)
		v.add_child(row)
		v.add_child(UI.btn("Until something happens", func():
			UI.close_sheet()
			_sim_to(999, true), "primary", "fast-forward", 54))
		v.add_child(UI.wrap("Your assistant makes the substitutions while you sim. It stops early for anything ticked in the rules, and shows you what you missed.", 16, UI.MUTED))
		var h2 = UI.hb(6)
		var rb = UI.btn("Sim rules", _sim_rules, "ghost", "sliders-horizontal", 44)
		rb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h2.add_child(rb)
		var cb = UI.btn("Cancel", func():
			UI.close_sheet()
			paused = was
			if stage == "live":
				_build_ctrl(), "ghost", "x", 44)
		cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h2.add_child(cb)
		v.add_child(h2))


func _sim_to(target: int, until_event: bool):
	# run the match on without showing it; stop at the target, at the break, or for a ticked event
	if sim == null:
		return
	_flush()
	if stage == "ht":
		if ht_panel != null and is_instance_valid(ht_panel):
			ht_panel.queue_free()
		ht_panel = null
		sim.resume()
		stage = "live"
	var st = G.settings
	var from = sim.minute
	var missed = []
	var me = sim.sd[us]
	var op = sim.sd[1 - us]
	var was_auto = me.auto
	me.auto = true
	var why = ""
	while sim.phase != 4:
		var evs = sim.step()
		for e in evs:
			_add_event(e)
			if e.t in ["goal", "red", "injury", "sub"] or (e.t == "info" and str(e.x).begins_with("Penalty")):
				missed.append(e)
			if e.t == "goal":
				if until_event or st.get("ss_goal", true):
					why = "Goal"
				elif st.get("ss_behind", true) and me.goals < op.goals and int(e.s) != us:
					why = "You are behind"
			elif e.t == "red" and (until_event or st.get("ss_red", true)):
				why = "Red card"
			elif e.t == "injury" and int(e.s) == us and (until_event or st.get("ss_inj", true)):
				why = "Injury"
		if sim.phase == 2:
			break
		if why != "" or sim.minute >= target:
			break
	me.auto = was_auto
	if view3d != null and is_instance_valid(view3d):
		view3d.cancel()
		view3d.tick()
	_update()
	_refresh_tab()
	if sim.phase == 4:
		stage = "ft"
		_build_ctrl()
		_show_ft()
	elif sim.phase == 2:
		stage = "ht"
		paused = true
		_show_ht()
	else:
		stage = "live"
		paused = true
		_build_ctrl()
	_missed(missed, from, why)


func _missed(missed: Array, from: int, why: String):
	var goals = []
	for e in missed:
		if e.t == "goal" and e.has("k"):
			goals.append(e)
	UI.sheet("What you missed", func(v):
		v.add_child(UI.lbl_fill("%s to %s · %s" % [_mtxt(from), "full time" if sim.phase == 4 else ("half-time" if sim.phase == 2 else _mtxt(sim.minute)), sim.score_text()], 20, UI.TEXT, "disp"))
		if why != "":
			v.add_child(UI.lbl_fill("Stopped for: %s" % why, 17, UI.AMBER, "semi"))
		if missed.is_empty():
			v.add_child(UI.wrap("Nothing of note: no goals, cards or injuries.", 18, UI.MUTED))
		for e in missed:
			var meta = EV.get(e.t, EV["info"])
			var r = UI.hb(8)
			var ml = UI.lbl(_mtxt(int(e.m)), 17, Color(meta[1]), "disp")
			ml.custom_minimum_size = Vector2(40, 0)
			r.add_child(ml)
			r.add_child(UI.icon(meta[0], 18, Color(meta[1])))
			r.add_child(UI.wrap(str(e.x), 17, UI.TEXT if e.t == "goal" else UI.MUTED))
			v.add_child(r)
		var h2 = UI.hb(6)
		if view3d != null and is_instance_valid(view3d) and view3d.visible and not goals.is_empty():
			var wb = UI.btn("Watch the goal%s" % ("" if goals.size() == 1 else "s"), func():
				UI.close_sheet()
				replays = goals.duplicate()
				_next_replay(), "secondary", "play", 50)
			wb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			h2.add_child(wb)
		var ok = UI.btn("Carry on", func(): UI.close_sheet(), "primary", "check", 50)
		ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h2.add_child(ok)
		v.add_child(h2))


func _next_replay():
	if replays.is_empty() or view3d == null or not is_instance_valid(view3d):
		replays = []
		replaying = false
		return
	var e = replays.pop_front()
	replaying = true
	banner.visible = true
	if ht_panel != null and is_instance_valid(ht_panel):
		ht_panel.visible = false
	view3d.process_mode = Node.PROCESS_MODE_INHERIT
	banner_l.text = "REPLAY"
	banner_s.text = "%s  %s" % [_mtxt(int(e.m)), sim.nm(int(e.p)) if e.has("p") and int(e.p) >= 0 else ""]
	view3d.play(e)
	if not view3d.seq_done.is_connected(_replay_done):
		view3d.seq_done.connect(_replay_done)


func _replay_done():
	if not replaying:
		return
	if replays.is_empty():
		replaying = false
		banner.visible = false
		if ht_panel != null and is_instance_valid(ht_panel):
			ht_panel.visible = true
		return
	_next_replay()


func _second(c: Dictionary, shirt: Color) -> Color:
	# shorts colour: the club's other colour, unless that is the shirt colour
	var c2 = Color(str(c.c2))
	if abs(c2.r - shirt.r) + abs(c2.g - shirt.g) + abs(c2.b - shirt.b) < 0.25:
		c2 = Color(str(c.c1))
	return c2


func _on_impact():
	var evs = deferred
	deferred = []
	if not evs.is_empty() and sim != null:
		_apply(evs)


func _process(delta):
	if replaying:
		return   # a goal replay is running
	if view3d != null and stage == "live":
		view3d.process_mode = Node.PROCESS_MODE_DISABLED if (paused or UI.main.sheet_node != null) else Node.PROCESS_MODE_INHERIT
	if stage != "live" or paused or sim == null or UI.main.sheet_node != null:
		return
	if view3d != null and (view3d.playing() or not deferred.is_empty()):
		return
	if view3d != null and vmode == 1:
		# key moments: the clock runs quickly between chances, each chance is played out on the pitch
		acc += delta
		if hold > 0.0:
			hold -= delta
			if hold <= 0.0 and banner != null:
				banner.visible = false
			return
		if acc >= 0.05:
			acc = 0.0
			_tick()
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
	if view3d != null:
		for e in evs:
			if e.has("k"):
				# a chance: show it first; the score, sounds and commentary follow when the ball gets there
				deferred = evs
				view3d.play(e)
				return true
	return _apply(evs)


func _apply(evs: Array) -> bool:
	var notable = false
	for e in evs:
		_add_event(e)
		if e.t != "info" and e.t != "sub":
			notable = true
		if e.t == "ht":
			_show_ht.call_deferred()
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
	if view3d != null:
		view3d.tick()
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
	for e in deferred:
		_add_event(e)
	deferred = []
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
	elif sim.et:
		min_l.text = "ET " + _mtxt(sim.minute)
	else:
		min_l.text = "%d'" % min(sim.minute, 90) if sim.minute <= 90 else "90+%d'" % (sim.minute - 90)
	if sim.agg[0] + sim.agg[1] > 0 or int(f.get("leg", 0)) == 2:
		min_l.text += "  ·  agg %d–%d" % [h.goals + sim.agg[0], a.goals + sim.agg[1]]
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


func _mtxt(m: int) -> String:
	if sim != null and sim.et and m > sim.et_at:
		return "%d'" % min(120, 90 + m - sim.et_at)
	return "%d'" % min(m, 90)


func _add_event(e: Dictionary):
	if e.x == "" or feed == null or not is_instance_valid(feed):
		return
	var meta = EV.get(e.t, EV["info"])
	var col = Color(meta[1])
	var big = e.t == "goal" or e.t == "red" or e.t == "ht" or e.t == "ft"
	var r = UI.panel(Color(col, 0.12) if big else Color(1, 1, 1, 0.03), 12, 10, 6, Color(col, 0.4) if big else Color(0, 0, 0, 0))
	var h = UI.hb(8)
	var ml = UI.lbl(_mtxt(int(e.m)), 18, col if big else UI.DIM, "disp")
	ml.custom_minimum_size = Vector2(38, 0)
	h.add_child(ml)
	h.add_child(UI.icon(meta[0], 20, col))
	h.add_child(UI.wrap(e.x, 18, UI.TEXT if big or e.t == "save" else UI.MUTED, "semi" if big else "body"))
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
		v.add_child(UI.caps("Touchline shouts", 15, UI.MUTED))
		var shh = UI.hb(6)
		for k in sim.SHOUTS.keys():
			var on = t.shout == k
			var ch = UI.chip(sim.SHOUTS[k].to_upper(), Color(UI.accent, 0.2) if on else Color(1, 1, 1, 0.06), UI.accent if on else UI.TEXT, 18)
			ch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			ch.custom_minimum_size = Vector2(0, 46)
			var kk = k
			UI.tap(ch, func():
				if sim.shout(us, kk):
					_add_event(sim.ev("info", us, "%s's manager shouts from the touchline: \"%s!\"" % [t.club.name, sim.SHOUTS[kk]]))
				else:
					UI.toast("You can only demand more once per match", UI.RED)
				_team_sheet(), true)
			shh.add_child(ch)
		v.add_child(shh)
		v.add_child(UI.caps("Mentality", 15, UI.MUTED))
		v.add_child(UI.seg(MENT_SHORT, t.ment, func(i):
			t.ment = i
			sim.recalc(us)
			_team_sheet(), 20))
		v.add_child(UI.caps("Pressing", 15, UI.MUTED))
		v.add_child(UI.seg(G.PRESSING, t.press, func(i):
			t.press = i
			sim.recalc(us)
			_team_sheet(), 20))
		v.add_child(UI.caps("Tempo", 15, UI.MUTED))
		v.add_child(UI.seg(G.TEMPO, t.tempo, func(i):
			t.tempo = i
			sim.recalc(us)
			_team_sheet(), 20))
		var have = false
		for pr in c.presets:
			if pr != null:
				have = true
		if have:
			v.add_child(UI.caps("Switch to preset", 15, UI.MUTED))
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
		v.add_child(UI.btn("Substitutions and full tactics (%d of 5 subs used)" % t.subs, func():
			UI.close_sheet()
			_open_tactics(), "secondary", "layout-grid", 54))
		v.add_child(UI.btn("Done", func():
			UI.close_sheet()
			paused = false
			if stage == "live":
				_build_ctrl(), "primary", "check", 54))
	UI.sheet("Shouts and quick changes", build_sheet)


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
	_restore()
	UI.ambience(false)
	UI.music_duck(false)


func _show_ft():
	if view3d != null and is_instance_valid(view3d) and pitch.get_parent() == null:
		# full time: the flat pitch takes over to show the shot map
		var host = view3d.get_parent()
		view3d.visible = false
		view3d.process_mode = Node.PROCESS_MODE_DISABLED
		pitch.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		host.add_child(pitch)
		host.move_child(pitch, 0)
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
	_restore()
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

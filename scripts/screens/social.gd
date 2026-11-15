extends "res://scripts/screens/screen.gd"
# Social: your profile, a composer and what is trending on the left; the timeline on the right with four tabs
# (For you, Your club, World, Mentions). Posts from rival managers, your players, journalists and fans can be
# answered, and every answer moves something real (see G.SOC.reply).

const TABS = ["For you", "Your club", "World", "Mentions"]

var tab := 0
var q := ""


func build():
	var s = G.s
	var d = G.SOC.data()
	UI.main.t_title = "Social"
	UI.main.t_sub = "@%s · %s followers" % [G.SOC.handle(), G.OPS._thousands(int(d.followers))]
	if str(d.handle) == "":
		_ask_handle.call_deferred()
	var h = panes(12, 20)
	var a = pane(330, 6)
	h.add_child(a[0])
	_left(a[1])
	var b = pane(0, 6)
	h.add_child(b[0])
	_feed(b[1])


func _ask_handle():
	var d = G.SOC.data()
	var pick = G.SOC.handle()
	var build = func(v):
		v.add_child(UI.wrap("Pick the name fans, players and rival managers will see on your posts.", 18, UI.MUTED))
		var le = UI.input(pick, "your_name", func(t): pick = t)
		le.custom_minimum_size = Vector2(0, 54)
		v.add_child(le)
		v.add_child(UI.btn("Use this name", func():
			var t = pick.strip_edges().replace("@", "").replace(" ", "_")
			if t.length() < 3:
				UI.toast("At least three characters", UI.RED)
				return
			d.handle = t.substr(0, 20)
			UI.close_sheet()
			refresh(), "primary", "check", 52))
	UI.sheet("Your social name", build)


func _left(v: VBoxContainer):
	var s = G.s
	var c = G.uc()
	var d = G.SOC.data()
	var pr = UI.hb(10)
	pr.add_child(UI.badge(c, 44))
	var pv = UI.vb(-4)
	pv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pv.add_child(UI.lbl_fill(str(s.user.name), 20, UI.TEXT, "bold"))
	var hl = UI.lbl_fill("@%s" % G.SOC.handle(), 16, UI.accent)
	pv.add_child(hl)
	pr.add_child(pv)
	var ed = UI.chip("EDIT", Color(1, 1, 1, 0.06), UI.MUTED, 14)
	UI.tap(ed, _ask_handle, true)
	pr.add_child(ed)
	v.add_child(pr)
	var st = UI.hb(8)
	st.add_child(UI.stat_tile("Followers", G.OPS._thousands(int(d.followers)), UI.TEXT))
	st.add_child(UI.stat_tile("Fans", "%d%%" % int(s.user.get("fans", 55.0)), UI.cond_color(s.user.get("fans", 55.0))))
	v.add_child(st)
	# composer
	var can = d.last < s.day
	if can:
		var le = UI.input(q, "Write a post…", func(t): q = t)
		le.custom_minimum_size = Vector2(0, 46)
		v.add_child(le)
		var row = UI.hb(6)
		var pb = UI.btn("Post", func():
			if q.strip_edges() == "":
				return
			var r = G.SOC.post(q.strip_edges())
			q = ""
			UI.sfx("message", -8.0)
			UI.toast(r, UI.accent)
			refresh(), "primary", "megaphone", 42)
		pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(pb)
		var qb = UI.btn("Quick post", func(): _quick(), "secondary", "", 42)
		qb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(qb)
		v.add_child(row)
	else:
		v.add_child(UI.wrap("You have posted today. Replies are still open.", 16, UI.DIM))
	# trending
	v.add_child(UI.caps("Trending", 15, UI.accent))
	var tr = []
	if str(d.trend) != "":
		tr.append(str(d.trend))
	for t in d.trends:
		if not (t in tr):
			tr.append(t)
	if tr.is_empty():
		v.add_child(UI.lbl_fill("Nothing yet.", 16, UI.DIM))
	for i in tr.size():
		var r = UI.hb(8)
		r.add_child(UI.lbl("%d" % (i + 1), 16, UI.DIM, "disp"))
		r.add_child(UI.lbl_fill(tr[i], 18, UI.TEXT, "semi"))
		v.add_child(r)
	# rivals you are feuding with
	var feuds = []
	for cid in s.get("mgrs", {}):
		var m = s.mgrs[cid]
		if float(m.feud) >= 25:
			feuds.append([cid, m])
	feuds.sort_custom(func(x, y): return x[1].feud > y[1].feud)
	if not feuds.is_empty():
		v.add_child(UI.caps("Rival managers", 15, UI.accent))
		for f in feuds.slice(0, 3):
			var r2 = UI.hb(8)
			r2.add_child(UI.badge(s.clubs[f[0]], 22))
			r2.add_child(UI.lbl_fill(G.MG.nm(f[1]), 16, UI.TEXT))
			r2.add_child(UI.lbl(G.MG.feud_word(float(f[1].feud)), 15, UI.RED if f[1].feud >= 50 else UI.AMBER, "semi"))
			v.add_child(r2)


func _quick():
	var s = G.s
	var c = G.uc()
	var best = null
	for pid in c.xi:
		if pid >= 0 and (best == null or s.players[pid].form > best.form):
			best = s.players[pid]
	var nf = G.next_user_fixture()
	var quick = [["Thank you to every fan who backs this team. We feel it.", "good"], ["We go again. Heads up, work hard, together.", "good"]]
	if best != null:
		quick.append(["%s has been brilliant in training. Proud of him." % G.pname(best), "good"])
	if nf != null:
		var on = s.clubs[nf.a if nf.h == c.id else nf.h].name
		quick.append(["%s next. They know what's coming." % on, "neutral"])
	var build = func(v):
		for qk in quick:
			var txt = qk[0]
			var tn = qk[1]
			v.add_child(UI.btn(txt, func():
				UI.close_sheet()
				var r = G.SOC.post(txt, tn)
				UI.sfx("message", -8.0)
				UI.toast(r, UI.accent)
				refresh(), "secondary", "", 50))
	UI.sheet("Quick post", build)


func _in_tab(p: Dictionary) -> bool:
	var uc = G.s.user.club
	match tab:
		1: return int(p.get("cid", -1)) == uc or p.mine
		2: return int(p.get("cid", -1)) != uc and not p.mine
		3: return p.get("at", false) or (p.mine and p.replies.size() > 0)
	return true


func _feed(v: VBoxContainer):
	var d = G.SOC.data()
	var sg = UI.seg(TABS, tab, func(i):
		tab = i
		refresh(), 15, 5)
	v.add_child(sg)
	var shown = 0
	for p in d.posts:
		if shown >= 30:
			break
		if not _in_tab(p):
			continue
		shown += 1
		v.add_child(_post(p))
	if shown == 0:
		v.add_child(UI.wrap("Nothing here yet. The feed fills up as matches are played and the news breaks.", 18, UI.MUTED))


func _post(p: Dictionary) -> Control:
	var kind = str(p.kind)
	var col = {"me": UI.accent, "press": UI.GOLD, "world": UI.GOLD, "journo": UI.AMBER, "mgr": UI.RED, "player": UI.GREEN, "club": UI.TEXT}.get(kind, UI.LINE)
	var pc = UI.panel(UI.CARD, 12, 12, 8, Color(col, 0.5) if kind != "fan" else UI.LINE)
	var pv = UI.vb(3)
	var ph = UI.hb(8)
	var cid = int(p.get("cid", -1))
	if kind == "me":
		ph.add_child(load("res://scripts/face_editor.gd").make(G.s.user.get("face", {}), 30))
	elif kind == "mgr" and cid >= 0:
		ph.add_child(load("res://scripts/face_editor.gd").make(G.MG.face(G.MG.of(cid)), 30))
	if cid >= 0 and kind in ["club", "mgr", "player"]:
		ph.add_child(UI.badge(G.s.clubs[cid], 22))
	ph.add_child(UI.lbl(str(p.who), 18, UI.TEXT, "bold"))
	var tag = {"mgr": "MANAGER", "journo": "TRANSFER NEWS", "player": "PLAYER", "club": "CLUB", "press": "MEDIA", "world": "MEDIA"}.get(kind, "")
	if tag != "":
		ph.add_child(UI.chip(tag, Color(col, 0.16), col, 13))
	ph.add_child(UI.lbl_fill("@%s · %s" % [p.handle, G.fmt_date(int(p.day)).substr(4)], 14, UI.DIM))
	pv.add_child(ph)
	pv.add_child(UI.wrap(str(p.text), 18, UI.TEXT))
	var st = UI.hb(12)
	st.add_child(UI.icon("heart", 15, UI.RED))
	st.add_child(UI.lbl(G.OPS._thousands(int(p.likes)), 14, UI.MUTED))
	st.add_child(UI.icon("repeat", 15, UI.GREEN))
	st.add_child(UI.lbl(G.OPS._thousands(int(p.reposts)), 14, UI.MUTED))
	st.add_child(UI.sp())
	# answer it: every reply has a consequence
	for o in G.SOC.reply_opts(p):
		var code = o[1]
		var pp = p
		var ch = UI.chip(str(o[0]).to_upper(), Color(UI.accent, 0.14) if code != "ignore" else Color(1, 1, 1, 0.05), UI.accent if code != "ignore" else UI.MUTED, 14)
		UI.tap(ch, func():
			var r = G.SOC.reply(pp, code)
			UI.sfx("message", -10.0)
			UI.toast(r, UI.accent)
			refresh(), true)
		st.add_child(ch)
	pv.add_child(st)
	for r in p.replies.slice(0, 3):
		var rr = UI.panel(Color(1, 1, 1, 0.04), 8, 10, 4)
		rr.add_child(UI.wrap("@%s  %s" % [r[0], r[1]], 15, UI.MUTED))
		pv.add_child(rr)
	pc.add_child(pv)
	return pc

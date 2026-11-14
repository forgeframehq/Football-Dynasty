extends "res://scripts/screens/screen.gd"
# Tactical plans: saved tactics as a carousel of pitch cards, team sheets for rotation,
# set-piece assignments, and in-match triggers that switch plan for you.

const MINI = preload("res://scripts/widgets/mini_pitch.gd")
const TABS = ["Plans", "Team sheets", "Assignments", "Triggers"]
const TRIG = [["lead75", "Leading after 75 minutes"], ["trail60", "Trailing after 60 minutes"], ["level80", "Level after 80 minutes"], ["red", "Down to ten men"]]

var tab := 0


func build():
	var c = G.uc()
	G.TC.plans_init(c)
	title = "Tactical plans"
	subtitle = "%d saved · %s active" % [c.plans.size(), _active_name(c)]
	body.add_child(UI.topbar("Tactical plans", true))
	UI.main.t_sub = subtitle
	var top = UI.hb(8)
	var sg = UI.seg(TABS, tab, func(i):
		tab = i
		refresh(), 16, 6)
	sg.custom_minimum_size = Vector2(560, 0)
	top.add_child(sg)
	top.add_child(UI.sp())
	if tab == 0:
		top.add_child(UI.btn("Save current as new", func():
			if c.plans.size() >= 8:
				UI.toast("Eight plans is the limit: delete one first", UI.AMBER)
				return
			c.plans.append({"n": "%s %s" % [c.formation, G.TC.STYLES[G.TC.style_of(c)].s], "pr": G.make_preset(c)})
			c["plan"] = c.plans.size() - 1
			refresh(), "secondary", "plus", 42))
		top.add_child(UI.btn("Open tactics", func(): UI.main.root("tactics"), "secondary", "layout-grid", 42))
	body.add_child(UI.margin(top, 20, 0, 20, 6))
	match tab:
		0: _plans(c)
		1: _sheets(c)
		2: _assign(c)
		3: _triggers(c)


func _active_name(c: Dictionary) -> String:
	var i = int(c.get("plan", -1))
	return str(c.plans[i].n) if i >= 0 and i < c.plans.size() else "none"


func _plans(c: Dictionary):
	var nf = G.next_user_fixture()
	var oid = -1
	if nf != null:
		oid = int(nf.a) if int(nf.h) == c.id else int(nf.h)
	var nets = []
	var best = -1
	for i in c.plans.size():
		var n = G.TC.plan_net(c, c.plans[i].pr, oid) if oid >= 0 else 0.0
		nets.append(n)
		if best < 0 or n > nets[best]:
			best = i
	var row = UI.hb(10)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var scr = ScrollContainer.new()
	scr.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scr.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scr.add_child(row)
	var m = UI.margin(scr, 20, 0, 20, 12)
	m.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(m)
	var act = int(c.get("plan", -1))
	for i in c.plans.size():
		var pl = c.plans[i]
		var pr = pl.pr
		var on = i == act
		var card = UI.panel(UI.CARD, 16, 12, 10, UI.accent if on else UI.LINE)
		card.custom_minimum_size = Vector2(292, 0)
		var v = UI.vb(4)
		var hd = UI.hb(6)
		hd.add_child(UI.lbl_fill(str(pl.n), 20, UI.TEXT, "bold"))
		if on:
			hd.add_child(UI.chip("ACTIVE", UI.accent, UI.on_color(UI.accent), 13))
		v.add_child(hd)
		var mp = MINI.new()
		mp.slots = pr.slots
		mp.col = Color(str(c.c1))
		mp.rim = Color(str(c.c2))
		mp.size_flags_vertical = Control.SIZE_EXPAND_FILL
		mp.custom_minimum_size = Vector2(0, 150)
		v.add_child(mp)
		v.add_child(UI.lbl_fill("%s · %s" % [pr.formation, G.TC.STYLES[int(pr.get("pstyle", 0))].n], 17, UI.TEXT, "semi"))
		v.add_child(UI.lbl_fill("%s · %s press · %s tempo" % [G.MENTALITY[int(pr.ment)], G.PRESSING[int(pr.press)].to_lower(), G.TEMPO[int(pr.tempo)].to_lower()], 14, UI.MUTED))
		if oid >= 0:
			var n = nets[i]
			var col = UI.MUTED if abs(n) < 0.03 else (UI.GREEN if n > 0 else UI.RED)
			var vt = "Even" if abs(n) < 0.03 else ("In your favour" if n > 0 else "Against you")
			var vh = UI.hb(6)
			vh.add_child(UI.caps("v %s" % G.s.clubs[oid].short, 13, UI.DIM))
			vh.add_child(UI.lbl_fill(vt, 15, col, "semi"))
			if i == best and c.plans.size() > 1 and n >= 0.03:
				vh.add_child(UI.chip("SCOUT'S PICK", Color(UI.GOLD, 0.2), UI.GOLD, 12))
			v.add_child(vh)
		var bh = UI.hb(5)
		var idx = i
		var ab = UI.btn("Active" if on else "Activate", func():
			G.TC.plan_use(c, idx)
			UI.toast("%s is now your plan" % str(c.plans[idx].n), UI.GREEN)
			refresh(), "primary" if not on else "ghost", "", 40)
		ab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bh.add_child(ab)
		var eb = UI.btn("Edit", func():
			G.TC.plan_use(c, idx)
			UI.main.root("tactics"), "secondary", "pencil", 40)
		eb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bh.add_child(eb)
		var mb = UI.panel(Color(1, 1, 1, 0.07), 12, 9, 8)
		mb.add_child(UI.icon("ellipsis", 22, UI.TEXT))
		UI.tap(mb, func(): _plan_menu(c, idx), true)
		bh.add_child(mb)
		v.add_child(bh)
		card.add_child(v)
		row.add_child(card)
	if c.plans.is_empty():
		var e = UI.panel(UI.CARD, 16, 20, 16, UI.LINE)
		e.custom_minimum_size = Vector2(520, 0)
		e.add_child(UI.wrap("No plans saved yet. Set your team up on the Tactics screen, then press “Save current as new”. Each plan keeps the formation, roles, playstyle and every instruction, so you can switch between them in one tap, before or during a match.", 19, UI.MUTED))
		row.add_child(e)


func _plan_menu(c: Dictionary, idx: int):
	UI.sheet(str(c.plans[idx].n), func(v):
		var le = UI.input(str(c.plans[idx].n), "Plan name", func(t): c.plans[idx].n = t if t.strip_edges() != "" else c.plans[idx].n)
		le.custom_minimum_size = Vector2(0, 46)
		le.max_length = 22
		v.add_child(le)
		v.add_child(UI.btn("Overwrite with the tactics on screen now", func():
			c.plans[idx].pr = G.make_preset(c)
			c["plan"] = idx
			UI.close_sheet()
			refresh(), "secondary", "save", 50))
		v.add_child(UI.btn("Copy this plan", func():
			if c.plans.size() < 8:
				c.plans.append({"n": str(c.plans[idx].n) + " 2", "pr": c.plans[idx].pr.duplicate(true)})
			UI.close_sheet()
			refresh(), "secondary", "copy", 50))
		v.add_child(UI.btn("Delete", func():
			c.plans.remove_at(idx)
			if int(c.get("plan", -1)) == idx:
				c["plan"] = -1
			elif int(c.get("plan", -1)) > idx:
				c["plan"] = int(c.plan) - 1
			for t in c.get("trig", {}).keys():
				if int(c.trig[t]) == idx:
					c.trig.erase(t)
				elif int(c.trig[t]) > idx:
					c.trig[t] = int(c.trig[t]) - 1
			UI.close_sheet()
			refresh(), "danger", "trash", 50))
		v.add_child(UI.btn("Done", func():
			UI.close_sheet()
			refresh(), "primary", "check", 50)))


func _sheets(c: Dictionary):
	var s = G.s
	var h = panes(10, 20)
	for i in 3:
		var pn = pane(0, 3)
		h.add_child(pn[0])
		var v = pn[1]
		var sh = c.sheets[i]
		var hd = UI.hb(6)
		hd.add_child(UI.lbl_fill(str(sh.n) if sh != null else ["First team", "Rotation", "Cup side"][i], 20, UI.TEXT, "bold"))
		if sh != null:
			var tot = 0
			var cnd = 0.0
			var n = 0
			for pid in sh.xi:
				if s.players.has(pid) and pid in c.players:
					tot += s.players[pid].ovr
					cnd += s.players[pid].cond
					n += 1
			hd.add_child(UI.chip("%d" % (tot / max(1, n)), Color(1, 1, 1, 0.07), UI.TEXT, 15))
			hd.add_child(UI.chip("%d%%" % int(cnd / max(1, n)), Color(1, 1, 1, 0.07), UI.cond_color(cnd / max(1, n)), 15))
		v.add_child(hd)
		if sh == null:
			v.add_child(UI.wrap("Empty. Pick a team on the Tactics screen, then save it here. Use it to switch your whole XI and bench in one tap.", 16, UI.MUTED))
		else:
			var slots = G.slots_of(c)
			for k in min(11, sh.xi.size()):
				var pid = int(sh.xi[k])
				var r = UI.hb(6)
				var pl = UI.caps(str(slots[k][0]) if k < slots.size() else "", 13, UI.DIM)
				pl.custom_minimum_size = Vector2(36, 0)
				r.add_child(pl)
				if s.players.has(pid) and pid in c.players:
					var p = s.players[pid]
					r.add_child(UI.lbl_fill(G.pname(p), 16, UI.TEXT if G.available(p) else UI.RED))
					r.add_child(UI.caps("%d%%" % int(p.cond), 13, UI.cond_color(p.cond)))
					r.add_child(UI.lbl(str(p.ovr), 16, UI.ovr_color(p.ovr), "disp"))
				else:
					r.add_child(UI.lbl_fill("left the club", 16, UI.DIM))
				v.add_child(r)
		var bh = UI.hb(5)
		var idx = i
		var sb = UI.btn("Save current XI", func():
			c.sheets[idx] = {"n": ["First team", "Rotation", "Cup side"][idx], "xi": c.xi.duplicate(), "bench": c.bench.duplicate()}
			UI.toast("Saved", UI.GREEN)
			refresh(), "secondary", "save", 40)
		sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bh.add_child(sb)
		if sh != null:
			var ub = UI.btn("Use", func():
				G.TC.sheet_use(c, idx)
				UI.toast("%s picked" % str(c.sheets[idx].n), UI.GREEN)
				refresh(), "primary", "check", 40)
			ub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			bh.add_child(ub)
		v.add_child(bh)
	var pn2 = pane(300, 5)
	h.add_child(pn2[0])
	var w = pn2[1]
	w.add_child(UI.caps("Auto-rotate", 15, UI.accent))
	var on = bool(c.get("autorot", false))
	var tg = UI.panel(Color(UI.accent, 0.14) if on else Color(1, 1, 1, 0.04), 10, 12, 8)
	var th = UI.hb(8)
	th.add_child(UI.icon("square-check" if on else "square", 22, UI.accent if on else UI.DIM))
	th.add_child(UI.lbl_fill("Rest tired players", 19, UI.TEXT if on else UI.MUTED, "semi"))
	tg.add_child(th)
	UI.tap(tg, func():
		c["autorot"] = not bool(c.get("autorot", false))
		refresh(), true)
	w.add_child(tg)
	w.add_child(UI.wrap("Before each match, any starter under %d%% condition is swapped for the best fit player in his position, if one is close enough in quality. You are told who was rested." % G.TC.ROT_COND, 15, UI.MUTED))
	w.add_child(UI.caps("Rest below", 15, UI.accent))
	w.add_child(UI.seg(["65%", "75%", "85%"], [65, 75, 85].find(int(c.get("rot_at", 75))), func(i):
		c["rot_at"] = [65, 75, 85][i]
		refresh(), 16, 6))
	w.add_child(UI.caps("Current XI", 15, UI.accent))
	var tired = 0
	for pid in c.xi:
		if pid >= 0 and s.players[pid].cond < int(c.get("rot_at", 75)):
			tired += 1
	w.add_child(UI.lbl_fill("%d starter%s below the line right now" % [tired, "" if tired == 1 else "s"], 16, UI.AMBER if tired > 0 else UI.MUTED))
	w.add_child(UI.btn("Rotate now", func():
		var ch = G.TC.auto_rotate(c, true)
		UI.toast("%d change%s made" % [ch.size(), "" if ch.size() == 1 else "s"] if ch.size() > 0 else "Nobody needs a rest", UI.GREEN if ch.size() > 0 else UI.MUTED)
		refresh(), "secondary", "repeat", 44))


func _assign(c: Dictionary):
	var s = G.s
	var h = panes(10, 20)
	var a = pane(0, 6)
	h.add_child(a[0])
	var v = a[1]
	v.add_child(UI.caps("Who takes what · tap to change", 15, UI.accent))
	for row in [["capt", "Captain", 13, "Leadership lifts the team a little"], ["pk", "Penalties", 17, "Penalty taking"], ["fk", "Free kicks", 16, "Free kicks"], ["ck", "Corners", 3, "Crossing"]]:
		var pid = int(c.get(row[0], -1))
		var ok = pid >= 0 and s.players.has(pid) and pid in c.players
		var r = UI.panel(Color(1, 1, 1, 0.045), 10, 12, 7)
		var rh = UI.hb(10)
		var l = UI.lbl(row[1], 19, UI.MUTED)
		l.custom_minimum_size = Vector2(120, 0)
		rh.add_child(l)
		rh.add_child(UI.lbl_fill(G.pname(s.players[pid]) if ok else "Best available on the day", 19, UI.TEXT if ok else UI.DIM, "semi"))
		if ok:
			rh.add_child(UI.caps("%s %d" % [G.RL.ATTR[row[2]], int(s.players[pid].at[row[2]])], 14, UI.MUTED))
			if not (pid in c.xi):
				rh.add_child(UI.chip("NOT IN XI", Color(UI.AMBER, 0.2), UI.AMBER, 12))
		rh.add_child(UI.icon("chevron-right", 16, UI.DIM))
		r.add_child(rh)
		var key = row[0]
		var at = row[2]
		var ttl = row[1]
		UI.tap(r, func(): _pick(c, key, at, ttl), true)
		v.add_child(r)
	var b = pane(0, 6)
	h.add_child(b[0])
	var w = b[1]
	w.add_child(UI.caps("Marking jobs", 15, UI.accent))
	var tm = int(c.get("tm_pid", -1))
	w.add_child(UI.kv("Tight-mark", G.pname(s.players[tm]) if tm >= 0 and s.players.has(tm) else "Nobody", UI.TEXT, 18))
	w.add_child(UI.wrap("Chosen under Tactics > Defence. It takes most of the sting out of one opposition star, and lasts for the next match only.", 15, UI.MUTED))
	w.add_child(UI.btn("Open Defence", func():
		UI.main.root("tactics", {"tab": 2}), "secondary", "shield", 44))
	w.add_child(UI.caps("Individual instructions", 15, UI.accent))
	var n = 0
	for pn in c.get("pins", []):
		if str(pn) != "":
			n += 1
	w.add_child(UI.kv("Players with their own orders", str(n), UI.TEXT, 18))


func _pick(c: Dictionary, key: String, at: int, ttl: String):
	var s = G.s
	UI.sheet(ttl, func(v):
		var ids = (c.xi + c.bench).filter(func(pid): return pid >= 0)
		ids.sort_custom(func(x, y): return s.players[x].at[at] > s.players[y].at[at])
		var g = GridContainer.new()
		g.columns = 2
		g.add_theme_constant_override("h_separation", 8)
		g.add_theme_constant_override("v_separation", 4)
		for pid in ids.slice(0, 12):
			var p = s.players[pid]
			var on = int(c.get(key, -1)) == pid
			var r = UI.panel(Color(UI.accent, 0.18) if on else Color(1, 1, 1, 0.05), 10, 10, 6)
			r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var rh = UI.hb(8)
			rh.add_child(UI.pos(p.pos, 15))
			rh.add_child(UI.lbl_fill(G.pname(p), 18, UI.TEXT, "semi"))
			rh.add_child(UI.lbl(str(int(p.at[at])), 18, UI.ovr_color(int(p.at[at])), "disp"))
			r.add_child(rh)
			var pp = pid
			UI.tap(r, func():
				c[key] = pp
				UI.close_sheet()
				refresh(), true)
			g.add_child(r)
		v.add_child(g))


func _triggers(c: Dictionary):
	var h = panes(10, 20)
	var a = pane(0, 6)
	a[0].size_flags_stretch_ratio = 1.6
	h.add_child(a[0])
	var v = a[1]
	v.add_child(UI.caps("Switch plan automatically during a match", 15, UI.accent))
	if c.plans.is_empty():
		v.add_child(UI.wrap("Save at least one plan first.", 18, UI.MUTED))
	var tr = c.get("trig", {})
	for t in TRIG:
		var cur = int(tr.get(t[0], -1))
		var r = UI.panel(Color(UI.accent, 0.1) if cur >= 0 else Color(1, 1, 1, 0.045), 10, 12, 7)
		var rh = UI.hb(10)
		rh.add_child(UI.lbl_fill(t[1], 19, UI.TEXT if cur >= 0 else UI.MUTED, "semi"))
		rh.add_child(UI.lbl("→ %s" % str(c.plans[cur].n) if cur >= 0 and cur < c.plans.size() else "Do nothing", 17, UI.accent.lightened(0.3) if cur >= 0 else UI.DIM, "semi"))
		rh.add_child(UI.icon("chevron-right", 16, UI.DIM))
		r.add_child(rh)
		var key = t[0]
		var ttl = t[1]
		UI.tap(r, func(): _pick_trig(c, key, ttl), true)
		v.add_child(r)
	var b = pane(0, 6)
	h.add_child(b[0])
	var w = b[1]
	w.add_child(UI.caps("How it works", 15, UI.accent))
	w.add_child(UI.wrap("Each trigger fires once per match, the first time its condition is true. The team changes shape, roles and instructions to the plan you chose; the players on the pitch stay the same. It works whether you watch, sim ahead or take a quick result, and the commentary tells you when it happens.", 16, UI.MUTED))
	w.add_child(UI.wrap("Leave them all on “Do nothing” to make every change yourself.", 16, UI.MUTED))


func _pick_trig(c: Dictionary, key: String, ttl: String):
	UI.sheet(ttl, func(v):
		if not c.has("trig"):
			c["trig"] = {}
		var none = UI.panel(Color(1, 1, 1, 0.05), 10, 12, 8)
		none.add_child(UI.lbl_fill("Do nothing", 19, UI.TEXT, "semi"))
		UI.tap(none, func():
			c.trig.erase(key)
			UI.close_sheet()
			refresh(), true)
		v.add_child(none)
		for i in c.plans.size():
			var r = UI.panel(Color(UI.accent, 0.16) if int(c.trig.get(key, -1)) == i else Color(1, 1, 1, 0.05), 10, 12, 8)
			var rh = UI.hb(8)
			rh.add_child(UI.lbl_fill(str(c.plans[i].n), 19, UI.TEXT, "semi"))
			rh.add_child(UI.caps("%s · %s" % [c.plans[i].pr.formation, G.MENTALITY[int(c.plans[i].pr.ment)]], 14, UI.MUTED))
			r.add_child(rh)
			var idx = i
			UI.tap(r, func():
				c.trig[key] = idx
				UI.close_sheet()
				refresh(), true)
			v.add_child(r))

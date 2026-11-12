extends "res://scripts/screens/screen.gd"
# News and messages: list on the left, story in the middle, subject card on the right.

const ICONS = {"info": "mail", "board": "landmark", "offer": "handshake", "contract": "file-text", "result": "flag"}

var sel := -1


func build():
	var s = G.s
	var n = G.unread()
	var right = UI.panel(Color(1, 1, 1, 0.06), 12, 14, 8)
	right.add_child(UI.caps("Mark all read", 18, UI.TEXT))
	UI.tap(right, func():
		for m in s.inbox:
			m.read = true
		refresh(), true)
	body.add_child(UI.topbar("News", true, right))
	UI.main.t_sub = "%d unread item%s" % [n, "" if n == 1 else "s"]
	var h = panes()
	var lp = pane(430, 6)
	h.add_child(lp[0])
	if s.inbox.size() == 0:
		lp[1].add_child(UI.wrap("No messages yet.", 22, UI.MUTED))
		return
	if sel < 0 or sel >= s.inbox.size():
		sel = 0
		for i in s.inbox.size():
			if not s.inbox[i].read:
				sel = i
				break
	s.inbox[sel].read = true
	for i in s.inbox.size():
		var m = s.inbox[i]
		var on = i == sel
		var r = UI.panel(Color(UI.accent, 0.16) if on else Color(0, 0, 0, 0), 12, 10, 8, Color(UI.accent, 0.55) if on else Color(0, 0, 0, 0))
		var rh = UI.hb(10)
		rh.add_child(UI.icon(ICONS.get(m.kind, "mail"), 24, UI.accent if not m.read or on else UI.DIM))
		var tv = UI.vb(-3)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UI.lbl_fill(m.title, 22, UI.TEXT if (not m.read or on) else UI.MUTED, "semi"))
		tv.add_child(UI.lbl_fill(G.fmt_date(m.day), 16, UI.DIM))
		rh.add_child(tv)
		if not m.read:
			var dot = UI.panel(UI.accent, 6, 0, 0)
			dot.custom_minimum_size = Vector2(12, 12)
			dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			rh.add_child(dot)
		r.add_child(rh)
		var idx = i
		UI.tap(r, func():
			sel = idx
			refresh())
		lp[1].add_child(r)
	var m = s.inbox[sel]
	var mp = pane(0, 12)
	h.add_child(mp[0])
	var v = mp[1]
	v.add_child(UI.wrap(m.title.to_upper(), 30, UI.accent, "xbold"))
	v.add_child(UI.caps(G.fmt_date(m.day, true), 17, UI.DIM))
	v.add_child(UI.wrap(m.body, 23, UI.TEXT))
	# tags and actions
	var subj = _subject(m)
	var tags = UI.hb(8)
	tags.add_child(_tag(G.uc().name, func(): UI.main.open("clubview", {"cid": G.uc().id})))
	if subj != null:
		var pid = subj.id
		tags.add_child(_tag(G.pname(subj), func(): UI.main.open("player", {"pid": pid})))
	v.add_child(tags)
	var acts = UI.hb(10)
	if m.kind == "offer":
		acts.add_child(_act("Respond", "handshake", func():
			G.ui.tr_tab = 2
			UI.main.root("transfers")))
	if m.kind == "contract":
		acts.add_child(_act("Contracts", "file-text", func(): UI.main.root("lists", {"kind": "contracts", "grp": "club"})))
	if m.kind == "board":
		acts.add_child(_act("Board room", "landmark", func(): UI.main.root("board")))
	if subj != null:
		var pid2 = subj.id
		acts.add_child(_act("View player", "user", func(): UI.main.open("player", {"pid": pid2})))
	if m.title.begins_with("Injury") or m.title.ends_with("suspended"):
		acts.add_child(_act("Pick team", "layout-grid", func(): UI.main.root("tactics")))
	if acts.get_child_count() > 0:
		v.add_child(acts)
	var nav = UI.hb(10)
	nav.add_child(UI.sp())
	if sel > 0:
		nav.add_child(_act("Newer", "chevron-left", func():
			sel -= 1
			refresh(), "secondary"))
	if sel < s.inbox.size() - 1:
		nav.add_child(_act("Older", "chevron-right", func():
			sel += 1
			refresh(), "secondary"))
	v.add_child(UI.sp())
	v.add_child(nav)
	# subject card
	var cp = UI.panel(UI.CARD, 18, 0, 0, Color(UI.accent, 0.6))
	cp.custom_minimum_size = Vector2(300, 0)
	cp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var cv = UI.vb(0)
	var c = G.uc()
	var hero = UI.panel(Color(UI.accent, 0.12), 0, 16, 18)
	var hv = UI.vb(8)
	if subj != null:
		var oh = UI.hb(12)
		oh.alignment = BoxContainer.ALIGNMENT_CENTER
		oh.add_child(UI.ovr(subj.ovr, 34))
		oh.add_child(UI.pos(subj.pos, 22))
		oh.add_child(UI.flag(subj.nat, 40))
		hv.add_child(oh)
		var nl = UI.lbl(G.pname(subj).to_upper(), 28, UI.TEXT, "xbold")
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hv.add_child(nl)
	else:
		hv.add_child(UI.center(UI.badge(c, 84)))
		var nl2 = UI.lbl(s.user.name.to_upper(), 28, UI.TEXT, "xbold")
		nl2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hv.add_child(nl2)
	hero.add_child(hv)
	cv.add_child(hero)
	var kv = UI.vb(8)
	if subj != null:
		kv.add_child(UI.kv("Age", str(G.age(subj))))
		kv.add_child(UI.kv("Value", G.money(G.value(subj))))
		kv.add_child(UI.kv("Wage", "%s / wk" % G.money(subj.wage)))
		kv.add_child(UI.kv("Contract", "June %d" % subj.cend))
		kv.add_child(UI.kv("Morale", str(int(subj.mor)), UI.cond_color(subj.mor)))
	else:
		kv.add_child(UI.kv("Club", c.name))
		kv.add_child(UI.kv("Job status", "Secure" if s.user.conf >= 55 else ("Stable" if s.user.conf >= 35 else "Under pressure"), UI.cond_color(s.user.conf + 20)))
		kv.add_child(UI.kv("Confidence", "%d%%" % int(s.user.conf)))
		kv.add_child(UI.kv("League", G.LG.ordinal(G.LG.position(c.id))))
		kv.add_child(UI.kv("Reputation", "%d / 100" % int(s.user.rep)))
	cv.add_child(UI.margin(kv, 16, 14, 16, 14))
	cp.add_child(cv)
	h.add_child(cp)


func _subject(m: Dictionary):
	var s = G.s
	if m.kind == "offer":
		for o in s.offers:
			if o.id == m.ref and s.players.has(o.pid):
				return s.players[o.pid]
	for pid in G.uc().players:
		var p = s.players[pid]
		if m.title.contains(G.pname(p)) or m.body.contains(G.pfull(p)):
			return p
	return null


func _tag(text: String, cb: Callable) -> Control:
	var p = UI.panel(Color(1, 1, 1, 0.08), 8, 12, 5)
	p.add_child(UI.lbl(text, 18, UI.TEXT, "semi"))
	UI.tap(p, cb, true)
	return p


func _act(text: String, icon_name: String, cb: Callable, kind := "primary") -> Control:
	var b = UI.btn(text, cb, kind, icon_name, 52)
	b.custom_minimum_size = Vector2(170, 52)
	return b

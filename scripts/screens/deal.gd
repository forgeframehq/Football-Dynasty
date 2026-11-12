extends "res://scripts/screens/screen.gd"
# Transfer and contract talks. One screen, three panes: the player, the current stage, the record of talks.
# Modes: buy (enquiry > club fee > personal terms), free and renew (personal terms only), sell (answer a bid).

const SHORT_ROLE = ["Star", "First team", "Rotation", "Backup", "Prospect"]
const SELLON = [0, 10, 15, 20, 25]
const RC_MULT = [0.0, 1.5, 2.0, 3.0]

var d = null
var fee := 0
var inst := 0
var addon := 0
var sellon := 0
var t := {}
var rc_i := 0
var reply := ""
var reply_col := UI.MUTED
var hint := {}
var sum_lbl: Label
var view_lbl: Label
var inited := false
var bidding := false
var foot: Control
var cfee := 0
var csell := 0


func _init_state(p: Dictionary):
	inited = true
	if args.mode == "sell":
		var o = _offer()
		if o != null:
			cfee = int(o.get("counter", G.nice(o.fee * 1.15)))
			csell = int(o.get("csell", 0))
		return
	d = G.DL.start(p, args.mode)
	if d.stage == "club" or d.stage == "new":
		_seed_bid(p)
	if d.stage == "talks" or d.stage == "new":
		t = G.DL.default_terms(d)


func _seed_bid(p: Dictionary):
	fee = d.fee if d.fee > 0 else int(G.value(p))
	if d.counter.has("fee") and d.fee > 0:
		fee = G.nice((d.fee + int(d.counter.fee)) / 2.0)
	inst = d.inst
	addon = d.addon
	sellon = d.sellon


func _offer():
	for o in G.s.offers:
		if o.id == args.get("oid", -1):
			return o
	return null


func on_resume():
	refresh()


func build():
	if not G.s.players.has(args.pid):
		UI.main.call_deferred("back")
		return
	var p = G.s.players[args.pid]
	if not inited:
		_init_state(p)
	if args.mode != "sell" and d.stage == "club" and fee == 0:
		_seed_bid(p)
	if args.mode != "sell" and d.stage == "talks" and t.is_empty():
		t = G.DL.default_terms(d)
	body.add_child(UI.topbar({"buy": "Transfer talks", "free": "Contract talks", "renew": "New contract", "sell": "Offer received"}[args.mode]))
	UI.main.t_sub = "%s · %s · %d · %s" % [G.pfull(p), p.pos, G.age(p), "Free agent" if p.club < 0 else G.s.clubs[p.club].name]
	var h = panes(12, 20)
	_left(h, p)
	var midp = UI.panel(UI.CARD, 18, 16, 12, UI.LINE)
	midp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	midp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var mv = UI.vb(8)
	var v = UI.vb(7)
	var scr = UI.scroll(v)
	scr.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mv.add_child(scr)
	foot = UI.vb(0)
	mv.add_child(foot)
	midp.add_child(mv)
	h.add_child(midp)
	if args.mode == "sell":
		_sell(v, p)
	else:
		_steps(v)
		if reply != "":
			var rp = UI.panel(Color(reply_col, 0.12), 12, 14, 9, Color(reply_col, 0.4))
			rp.add_child(UI.wrap(reply, 20, UI.TEXT))
			v.add_child(rp)
		match d.stage:
			"new": _new(v, p)
			"enq_wait", "bid_wait": _waiting(v, p)
			"club": _club(v, p)
			"talks": _talks(v, p)
			"done": _done(v, p)
			_: _dead(v, p)
	_right(h, p)


# ---------------------------------------------------------------- panes

func _left(h: Control, p: Dictionary):
	var a = pane(250, 6)
	h.add_child(a[0])
	var v = a[1]
	var top = UI.hb(10)
	top.add_child(UI.ovr(p.ovr, 30))
	top.add_child(UI.pos(p.pos, 20))
	top.add_child(UI.flag(p.nat, 36))
	v.add_child(top)
	v.add_child(UI.lbl_fill(G.pname(p).to_upper(), 24, UI.TEXT, "xbold"))
	v.add_child(UI.kv("Age", str(G.age(p))))
	v.add_child(UI.kv("Value", G.money(G.value(p))))
	v.add_child(UI.kv("Wage now", "%s/wk" % G.money(p.wage)))
	v.add_child(UI.kv("Contract", "—" if p.club < 0 else "June %d" % p.cend))
	if p.get("rc", 0) > 0:
		v.add_child(UI.kv("Release clause", G.money(p.rc), UI.AMBER))
	v.add_child(UI.kv("Personality", G.PS.personality(p)))
	v.add_child(UI.kv("Favoured club", G.PS.favoured_name(p)))
	if args.mode != "sell":
		v.add_child(UI.kv("Sees himself as", SHORT_ROLE[G.DL.expected_role(p)], UI.accent))
		v.add_child(UI.kv("Speaks the language", "Yes" if G.PS.speaks_local(p, G.uc().id) else "No", UI.GREEN if G.PS.speaks_local(p, G.uc().id) else UI.AMBER))
	var b = UI.btn("Full profile", func(): UI.main.open("player", {"pid": p.id}), "secondary", "user", 50)
	v.add_child(UI.sp(0, 2))
	v.add_child(b)


func _right(h: Control, p: Dictionary):
	var a = pane(270, 6)
	h.add_child(a[0])
	var v = a[1]
	var c = G.uc()
	v.add_child(UI.caps("Your money", 16, UI.accent))
	v.add_child(UI.kv("Transfer budget", G.money(c.budget), UI.GREEN))
	v.add_child(UI.kv("Wage room", "%s/wk" % G.money(c.wage_budget - G.squad_wages(c) + (p.wage if p.club == c.id else 0))))
	var ow = G.DL.owed_total(c.id)
	if ow > 0:
		v.add_child(UI.kv("Instalments owed", G.money(ow), UI.AMBER))
	v.add_child(UI.kv("Squad size", "%d / %d" % [c.players.size(), G.TR.MAX_SQUAD]))
	v.add_child(UI.kv("Window", "Open" if G.window_open() else "Closed", UI.GREEN if G.window_open() else UI.RED))
	if d == null:
		return
	if d.rival >= 0:
		v.add_child(UI.kv("Rival bidder", G.s.clubs[d.rival].short, UI.RED))
	v.add_child(UI.divider())
	v.add_child(UI.caps("Record of talks", 16, UI.accent))
	if d.log.size() == 0:
		v.add_child(UI.wrap("Nothing yet.", 18, UI.DIM))
	for i in range(d.log.size() - 1, -1, -1):
		var e = d.log[i]
		var col = {"you": UI.accent, "club": UI.AMBER, "agent": UI.GREEN, "news": UI.RED}.get(e[1], UI.MUTED)
		var who = {"you": "You", "club": "Club", "agent": "Agent", "news": "News"}.get(e[1], "")
		v.add_child(UI.caps("%s · %s" % [who, G.fmt_date(e[0])], 14, col))
		v.add_child(UI.wrap(e[2], 17, UI.TEXT))


func _steps(v: Control):
	var names = ["Enquiry", "Club fee", "Personal terms", "Signed"] if d.mode == "buy" else ["Personal terms", "Signed"]
	var at = {"new": 0, "enq_wait": 0, "club": 1, "bid_wait": 1, "talks": 2, "done": 3, "dead": -1}[d.stage]
	if d.mode != "buy":
		at = max(-1, at - 2)
	var sh = UI.hb(6)
	for i in names.size():
		var done = at > i or d.stage == "done"
		var col = UI.GREEN if done else (UI.accent if i == at else UI.DIM)
		var pn = UI.panel(Color(col, 0.13), 10, 8, 6, Color(col, 0.45))
		pn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var l = UI.caps("%d  %s" % [i + 1, names[i]], 15, col)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pn.add_child(l)
		sh.add_child(pn)
	v.add_child(sh)


func _srow(label: String, minv: float, maxv: float, val: float, step: float, fmt: Callable, cb: Callable) -> Control:
	var h = UI.hb(8)
	var l = UI.lbl(label, 18, UI.MUTED)
	l.custom_minimum_size = Vector2(118, 0)
	h.add_child(l)
	var vl = UI.lbl(fmt.call(val), 21, UI.TEXT, "bold")
	vl.custom_minimum_size = Vector2(104, 0)
	vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var sl = UI.slider(minv, max(maxv, minv + step), val, step, func(x):
		cb.call(x)
		vl.text = fmt.call(x)
		_summary())
	sl.custom_minimum_size = Vector2(0, 40)
	var minus = _nudge("minus", func(): sl.value -= step)
	var plus = _nudge("plus", func(): sl.value += step)
	h.add_child(minus)
	h.add_child(sl)
	h.add_child(plus)
	h.add_child(vl)
	return h


func _nudge(ic: String, cb: Callable) -> Control:
	var b = UI.panel(Color(1, 1, 1, 0.08), 10, 9, 9)
	b.add_child(UI.icon(ic, 20, UI.TEXT))
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UI.tap(b, cb, true)
	return b


func _opt(label: String, options: Array, sel: int, cb: Callable) -> Control:
	var h = UI.hb(8)
	var l = UI.lbl(label, 18, UI.MUTED)
	l.custom_minimum_size = Vector2(118, 0)
	h.add_child(l)
	var sg = UI.seg(options, sel, cb, 17)
	sg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(sg)
	return h


func _m(x) -> String:
	return G.money(int(x))


# ---------------------------------------------------------------- stages

func _new(v: Control, p: Dictionary):
	var c = G.s.clubs[p.club]
	var w = G.TR.willing(p)
	v.add_child(UI.wrap("%s is under contract at %s until June %d. Nothing can happen until %s agree a fee — then you may talk to the player and his agent." % [G.pname(p), c.name, p.cend, c.short], 20, UI.TEXT))
	var g = UI.hb(8)
	g.add_child(UI.stat_tile("Market value", G.money(G.value(p))))
	g.add_child(UI.stat_tile("Club stance", "Listed" if p.listed else ("Not for sale" if G.DL.untouchable(p) else "Has a price"), UI.GREEN if p.listed else (UI.RED if G.DL.untouchable(p) else UI.AMBER)))
	g.add_child(UI.stat_tile("Player interest", "Open" if w.ok else "Doubtful", UI.GREEN if w.ok else UI.RED))
	v.add_child(g)
	if not w.ok:
		v.add_child(UI.wrap(w.why, 18, UI.AMBER))
	if not G.window_open():
		v.add_child(UI.wrap("The transfer window is closed. You can enquire now, but bids must wait until it opens.", 18, UI.AMBER))
	var bh = UI.hb(10)
	var b1 = UI.btn("Ask the price", func():
		G.DL.enquire(d)
		reply = "Enquiry sent. %s will answer by message — press Continue." % c.name
		reply_col = UI.accent
		UI.sfx("message")
		refresh(), "primary", "mail", 60)
	var b2 = UI.btn("Bid now", func():
		d.stage = "club"
		reply = ""
		refresh(), "secondary", "handshake", 60)
	for b in [b1, b2]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bh.add_child(b)
	foot.add_child(bh)
	v.add_child(UI.wrap("Asking first costs a day but tells you their price. Bidding blind is quicker, and each rejected offer uses up their patience.", 17, UI.DIM))


func _waiting(v: Control, p: Dictionary):
	var c = G.s.clubs[p.club]
	var card = UI.panel(Color(UI.accent, 0.1), 14, 18, 16, Color(UI.accent, 0.4))
	var cv = UI.vb(6)
	cv.add_child(UI.lbl("WAITING FOR %s" % c.short.to_upper(), 26, UI.TEXT, "xbold"))
	if d.stage == "bid_wait":
		cv.add_child(UI.wrap("Your bid of %s%s is with their board." % [G.money(d.fee), G.DL.extras(d)], 20, UI.TEXT))
	else:
		cv.add_child(UI.wrap("You have asked whether %s is available." % G.pname(p), 20, UI.TEXT))
	cv.add_child(UI.wrap("Their answer will arrive in your inbox on %s. Press Continue to move on a day." % G.fmt_date(d.wait), 19, UI.MUTED))
	card.add_child(cv)
	v.add_child(card)
	v.add_child(UI.btn("Withdraw", func():
		G.DL.all().erase(p.id)
		UI.main.back(), "danger", "x", 54))


func _club(v: Control, p: Dictionary):
	var c = G.s.clubs[p.club]
	var val = float(G.value(p))
	var maxv = max(val * 2.8, float(d.ask) * 1.3)
	if p.get("rc", 0) > 0:
		maxv = max(maxv, p.rc * 1.05)
	var step = max(1000.0, float(G.nice(val / 50.0)))
	var top = UI.hb(8)
	top.add_child(UI.caps("Offer to %s" % c.name, 16, UI.accent))
	top.add_child(UI.sp())
	top.add_child(UI.caps("Patience", 14, UI.DIM))
	for i in 3:
		var dot = UI.panel(UI.GREEN if i < d.pat else Color(1, 1, 1, 0.12), 6, 0, 0)
		dot.custom_minimum_size = Vector2(12, 12)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		top.add_child(dot)
	v.add_child(top)
	v.add_child(_srow("Transfer fee", 0.0, maxv, fee, step, _m, func(x): fee = int(x)))
	v.add_child(_opt("Payment", ["Up front", "2 payments", "3 payments"], inst, func(i):
		inst = i
		refresh()))
	v.add_child(_srow("After %d apps" % G.DL.ADDON_APPS, 0.0, val * 0.5, addon, step, _m, func(x): addon = int(x)))
	v.add_child(_opt("Sell-on clause", ["None", "10%", "15%", "20%", "25%"], SELLON.find(sellon), func(i):
		sellon = SELLON[i]
		refresh()))
	sum_lbl = UI.wrap("", 18, UI.TEXT)
	view_lbl = UI.lbl("", 18, UI.MUTED, "bold")
	v.add_child(sum_lbl)
	v.add_child(view_lbl)
	_summary()
	var bh = UI.hb(8)
	var sb = UI.btn("Submit bid", func():
		var r = G.DL.submit_bid(d, fee, inst, addon, sellon)
		reply = r.text
		reply_col = UI.accent if r.ok else UI.RED
		UI.sfx("message" if r.ok else "error")
		refresh(), "primary", "handshake", 58)
	sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bh.add_child(sb)
	if d.counter.has("fee"):
		var mb = UI.btn("Meet %s" % G.money(d.counter.fee), func():
			fee = int(d.counter.fee)
			inst = 0
			addon = 0
			sellon = 0
			refresh(), "secondary", "", 58)
		bh.add_child(mb)
	if p.get("rc", 0) > 0:
		bh.add_child(UI.btn("Pay clause", func():
			fee = int(p.rc)
			inst = 0
			refresh(), "secondary", "", 58))
	foot.add_child(bh)


func _summary():
	if d == null or not is_instance_valid(sum_lbl):
		return
	var p = G.s.players[d.pid]
	if d.stage == "club":
		var now = G.DL.pay_now(fee, inst)
		sum_lbl.text = "Due on signing %s · later %s%s" % [G.money(now), G.money(fee - now), (" · bonus %s" % G.money(addon)) if addon > 0 else ""]
		if d.ask > 0:
			var r = G.DL.package(p, fee, inst, addon, sellon) / float(d.ask)
			var words = "Acceptable" if r >= 0.95 else ("Close — expect a counter" if r >= 0.82 else ("Low" if r >= 0.72 else "Insulting"))
			view_lbl.text = "Their price %s · this offer looks: %s" % [G.money(d.ask), words]
			view_lbl.add_theme_color_override("font_color", UI.GREEN if r >= 0.95 else (UI.AMBER if r >= 0.72 else UI.RED))
		else:
			view_lbl.text = "Their price is unknown — you have not asked."
	elif d.stage == "talks":
		var dm = G.DL.demand(d, t)
		var span = 52.0 * t.years
		var r2 = (t.wage + t.sign / span) / (dm.wage + dm.sign / span)
		sum_lbl.text = "Due today %s · total cost of the contract %s" % [G.money(G.DL.upfront(d, t)), G.money(int(t.wage * span) + int(t.sign) + int(t.agent) + (d.fee if d.mode == "buy" else 0))]
		var words2 = "Should be accepted" if r2 >= 0.97 else ("Close" if r2 >= 0.88 else ("Some way off" if r2 >= 0.8 else "Far apart"))
		if dm.blocked != "":
			words2 = "Role is a deal-breaker"
		elif t.agent < dm.agent * 0.5:
			words2 = "Agent wants a bigger fee"
		view_lbl.text = "Your read of the room: %s" % words2
		view_lbl.add_theme_color_override("font_color", UI.GREEN if words2 == "Should be accepted" else (UI.AMBER if r2 >= 0.8 and dm.blocked == "" else UI.RED))


func _talks(v: Control, p: Dictionary):
	var dm = G.DL.demand(d, t)
	var base = float(G.TR.wage_demand(p))
	var top = UI.hb(8)
	var head = "Terms for %s" % G.pname(p)
	if d.mode == "buy":
		head += " · fee %s agreed · %d days left" % [G.money(d.fee), max(0, d.exp - G.s.day)]
	top.add_child(UI.caps(head, 16, UI.accent))
	top.add_child(UI.sp())
	top.add_child(UI.caps("Agent", 14, UI.DIM))
	for i in 4:
		var dot = UI.panel(UI.GREEN if i < d.ppat else Color(1, 1, 1, 0.12), 6, 0, 0)
		dot.custom_minimum_size = Vector2(12, 12)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		top.add_child(dot)
	v.add_child(top)
	var wstep = max(50.0, float(G.nice(base / 60.0)))
	v.add_child(_srow("Weekly wage", G.nice(base * 0.5), base * 2.0, t.wage, wstep, func(x): return _m(x) + "/wk", func(x): t.wage = int(x)))
	v.add_child(_opt("Length", ["1 yr", "2", "3", "4", "5"], t.years - 1, func(i):
		t.years = i + 1
		refresh()))
	v.add_child(_opt("Squad role", SHORT_ROLE, t.role, func(i):
		t.role = i
		refresh()))
	v.add_child(_srow("Signing-on fee", 0.0, dm.sign * 2.5, t.sign, max(500.0, float(G.nice(dm.sign / 25.0))), _m, func(x): t.sign = int(x)))
	v.add_child(_srow("Agent fee", 0.0, dm.agent * 2.5, t.agent, max(500.0, float(G.nice(dm.agent / 25.0))), _m, func(x): t.agent = int(x)))
	v.add_child(_opt("Release clause", ["None", "1.5× value", "2×", "3×"], rc_i, func(i):
		rc_i = i
		t.rc = G.nice(G.value(p) * RC_MULT[i]) if i > 0 else 0
		refresh()))
	sum_lbl = UI.wrap("", 18, UI.TEXT)
	view_lbl = UI.lbl("", 18, UI.MUTED, "bold")
	v.add_child(sum_lbl)
	v.add_child(view_lbl)
	_summary()
	if dm.notes.size() > 0:
		v.add_child(UI.wrap("Scout's note: " + " · ".join(dm.notes), 16, UI.DIM))
	var bh = UI.hb(8)
	var ob = UI.btn("Offer contract", func(): _offer_terms(p), "primary", "handshake", 58)
	ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bh.add_child(ob)
	if hint.has("wage"):
		bh.add_child(UI.btn("Meet demands", func():
			t.wage = int(hint.wage)
			t.sign = int(hint.sign)
			t.agent = int(hint.agent)
			hint = {}
			refresh(), "secondary", "", 58))
	foot.add_child(bh)


func _offer_terms(p: Dictionary):
	var r = G.DL.offer_terms(d, t)
	reply = "“%s”" % r.text if r.res in ["counter", "reject"] else r.text
	hint = {}
	match r.res:
		"accept":
			reply = ""
			UI.sfx("sting_news")
			UI.sfx("cash")
		"counter":
			reply_col = UI.AMBER
			hint = {"wage": r.wage, "sign": r.sign, "agent": r.agent}
			UI.sfx("message")
		_:
			reply_col = UI.RED
			UI.sfx("error")
	refresh()


func _ink(text: String, size: int, font := "body", col := Color("15161a")) -> Label:
	var l = UI.wrap(text, size, col, font)
	return l


func _done(v: Control, p: Dictionary):
	var c = G.uc()
	var tm = d.terms
	var paper = UI.panel(Color("efe7d6"), 4, 20, 12, Color("cfc5ae"))
	if ResourceLoader.exists("res://assets/scenes/newspaper.jpg"):
		var tex = StyleBoxTexture.new()
		tex.texture = load("res://assets/scenes/newspaper.jpg")
		tex.content_margin_left = 22
		tex.content_margin_right = 22
		tex.content_margin_top = 12
		tex.content_margin_bottom = 14
		paper.add_theme_stylebox_override("panel", tex)
	var pv = UI.vb(2)
	var top = UI.hb(8)
	top.add_child(UI.lbl("THE FOOTBALL GAZETTE", 20, Color("15161a"), "xbold"))
	top.add_child(UI.sp())
	top.add_child(UI.lbl(G.fmt_date(G.s.day, true).to_upper(), 13, Color("5b564b"), "semi"))
	pv.add_child(top)
	var rule = ColorRect.new()
	rule.color = Color("15161a")
	rule.custom_minimum_size = Vector2(0, 3)
	pv.add_child(rule)
	var surname = G.pname(p).to_upper()
	if d.mode == "renew":
		pv.add_child(_ink("%s COMMITS FUTURE TO %s" % [surname, c.short.to_upper()], 34, "xbold"))
		pv.add_child(_ink("The %d-year-old has signed a new contract that runs until June %d, ending talk of a move away." % [G.age(p), p.cend], 18, "body", Color("3a372f")))
	else:
		pv.add_child(_ink("DONE DEAL: %s JOINS %s" % [surname, c.short.to_upper()], 34, "xbold"))
		var feetxt = "a free transfer" if d.fee <= 0 else "a deal worth %s" % G.money(d.fee)
		pv.add_child(_ink("%s have completed the signing of %s on %s. The %s %s has agreed a %d-year contract and is expected to be a %s player." % [c.name, G.pfull(p), feetxt, p.nat, p.pos, tm.years, G.DL.ROLES[tm.role].to_lower()], 18, "body", Color("3a372f")))
	paper.add_child(pv)
	paper.pivot_offset = Vector2(260, 80)
	paper.scale = Vector2(0.6, 0.6)
	paper.rotation = -0.12
	paper.modulate.a = 0.0
	var tw = paper.create_tween().set_parallel(true)
	tw.tween_property(paper, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(paper, "rotation", 0.0, 0.35)
	tw.tween_property(paper, "modulate:a", 1.0, 0.2)
	v.add_child(paper)
	var g = UI.hb(8)
	g.add_child(UI.stat_tile("Wage", "%s/wk" % G.money(tm.wage)))
	g.add_child(UI.stat_tile("Until", "June %d" % p.cend))
	g.add_child(UI.stat_tile("Role", SHORT_ROLE[tm.role], UI.accent))
	if d.mode == "buy":
		g.add_child(UI.stat_tile("Paid today", G.money(G.DL.pay_now(d.fee, d.inst) + tm.sign + tm.agent), UI.AMBER))
	v.add_child(g)
	var bh = UI.hb(8)
	var b1 = UI.btn("Done", func(): UI.main.back(), "gold", "check", 58)
	b1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bh.add_child(b1)
	if d.mode != "renew":
		bh.add_child(UI.btn("Pick team", func(): UI.main.root("tactics"), "secondary", "layout-grid", 58))
	foot.add_child(bh)


func _dead(v: Control, p: Dictionary):
	var card = UI.panel(Color(UI.RED, 0.1), 14, 18, 16, Color(UI.RED, 0.4))
	var cv = UI.vb(6)
	cv.add_child(UI.lbl("TALKS ARE OFF", 26, UI.TEXT, "xbold"))
	cv.add_child(UI.wrap("Negotiations for %s have broken down.%s" % [G.pname(p), (" You may try again after %s." % G.fmt_date(d.block)) if d.block > G.s.day else " You may start again."], 20, UI.TEXT))
	card.add_child(cv)
	v.add_child(card)
	var bh = UI.hb(8)
	if d.block <= G.s.day and (p.club != G.uc().id or d.mode == "renew"):
		bh.add_child(UI.btn("Start again", func():
			G.DL.all().erase(p.id)
			inited = false
			reply = ""
			fee = 0
			t = {}
			refresh(), "primary", "", 58))
	bh.add_child(UI.btn("Back", func(): UI.main.back(), "secondary", "", 58))
	foot.add_child(bh)


# ---------------------------------------------------------------- selling

func _sell(v: Control, p: Dictionary):
	var o = _offer()
	if o == null or p.club != G.uc().id:
		v.add_child(UI.wrap("This offer is no longer on the table.", 22, UI.MUTED))
		v.add_child(UI.btn("Back", func(): UI.main.back(), "secondary", "", 58))
		return
	var c = G.s.clubs[o.from]
	var val = float(G.value(p))
	var head = UI.hb(12)
	head.add_child(UI.badge(c, 54))
	var hv = UI.vb(-2)
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hv.add_child(UI.caps("%s bid for %s" % [c.name, G.pname(p)], 16, UI.accent))
	hv.add_child(UI.lbl(G.money(o.fee) + ((" + %d%% sell-on" % o.sellon) if o.get("sellon", 0) > 0 else ""), 34, UI.GREEN, "xbold"))
	head.add_child(hv)
	v.add_child(head)
	var g = UI.hb(8)
	g.add_child(UI.stat_tile("Value", G.money(val)))
	g.add_child(UI.stat_tile("Offer vs value", "%d%%" % int(o.fee / max(1.0, val) * 100), UI.GREEN if o.fee >= val else UI.AMBER))
	g.add_child(UI.stat_tile("Expires in", "%d days" % (o.exp - G.s.day + 1)))
	g.add_child(UI.stat_tile("Squad after", str(G.uc().players.size() - 1)))
	v.add_child(g)
	if reply != "":
		var rp = UI.panel(Color(reply_col, 0.12), 12, 14, 9, Color(reply_col, 0.4))
		rp.add_child(UI.wrap(reply, 20, UI.TEXT))
		v.add_child(rp)
	if o.has("wait"):
		v.add_child(UI.wrap("You have asked for %s%s. %s will reply by message on %s." % [G.money(o.counter), (" plus %d%% of a future sale" % o.csell) if o.get("csell", 0) > 0 else "", c.short, G.fmt_date(o.wait)], 20, UI.TEXT))
	else:
		v.add_child(UI.caps("Ask for more", 16, UI.accent))
		v.add_child(_srow("Your price", float(o.fee), max(val * 2.4, o.fee * 1.6), cfee, max(1000.0, float(G.nice(val / 50.0))), _m, func(x): cfee = int(x)))
		v.add_child(_opt("Sell-on clause", ["None", "10%", "15%", "20%", "25%"], SELLON.find(csell), func(i):
			csell = SELLON[i]
			refresh()))
	var bh = UI.hb(8)
	var a = UI.btn("Accept %s" % G.money(o.fee), func():
		if G.uc().players.size() <= 18:
			UI.toast("You need at least 18 players", UI.RED)
			return
		G.TR.accept_offer(o)
		UI.sfx("cash")
		UI.toast("%s sold for %s" % [G.pname(p), G.money(o.fee)], UI.GREEN)
		UI.main.back(), "primary", "check", 58)
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bh.add_child(a)
	if not o.has("wait"):
		bh.add_child(UI.btn("Send counter", func():
			G.DL.counter_sale(o, cfee, csell)
			reply = "Counter-offer sent."
			reply_col = UI.accent
			UI.sfx("message")
			refresh(), "secondary", "mail", 58))
	bh.add_child(UI.btn("Reject", func():
		G.s.offers.erase(o)
		UI.main.back(), "danger", "x", 58))
	foot.add_child(bh)

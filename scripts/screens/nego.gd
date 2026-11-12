extends "res://scripts/screens/screen.gd"
# Negotiation: transfer fee with the selling club, then contract with the player.

var stage := ""      # fee, contract, done, blocked
var fee := 0
var wage := 0
var years := 3
var reply := ""
var reply_col := UI.MUTED
var agreed_fee := 0
var tries := 0
var fee_lbl: Label
var wage_lbl: Label
var inited := false


func _start():
	inited = true
	var p = G.s.players[args.pid]
	var mode = args.mode
	if mode == "buy":
		var w = G.TR.willing(p)
		if not w.ok:
			stage = "blocked"
			reply = w.why
			return
		var n = G.TR.nego(p.id)
		if n.fee >= 0:
			agreed_fee = n.fee
			stage = "contract"
		else:
			stage = "fee"
			fee = min(G.value(p), max(0, G.uc().budget))
	elif mode == "free":
		var w = G.TR.willing(p)
		if not w.ok:
			stage = "blocked"
			reply = w.why
			return
		stage = "contract"
	else:
		stage = "contract"
		years = clampi(p.cend - G.s.season + 2, 1, 5)
	wage = G.TR.wage_demand(p)


func build():
	if not G.s.players.has(args.pid):
		UI.main.call_deferred("back")
		return
	if not inited:
		_start()
	var p = G.s.players[args.pid]
	var c = G.uc()
	body.add_child(UI.topbar("Contract talks" if args.mode != "buy" else "Transfer talks"))
	var v = content(14)
	# player summary
	var head = UI.card()
	var h = UI.hb(14)
	h.add_child(UI.pos(p.pos))
	var hv = UI.vb(0)
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hv.add_child(UI.lbl_fill(G.pfull(p), 30, UI.TEXT, "disp"))
	hv.add_child(UI.lbl_fill("%d yrs · %s · value %s" % [G.age(p), "Free agent" if p.club < 0 else G.s.clubs[p.club].name, G.money(G.value(p))], 20, UI.MUTED))
	h.add_child(hv)
	h.add_child(UI.ovr(p.ovr, 30))
	head.add_child(h)
	v.add_child(head)
	var bt = UI.hb(10)
	bt.add_child(UI.stat_tile("Transfer budget", G.money(c.budget), UI.GREEN))
	bt.add_child(UI.stat_tile("Wage room / wk", G.money(c.wage_budget - G.squad_wages(c) + (p.wage if p.club == c.id else 0))))
	v.add_child(bt)
	# steps
	if args.mode == "buy":
		var sh = UI.hb(8)
		sh.add_child(_step("1  Club fee", stage == "fee", stage == "contract" or stage == "done"))
		sh.add_child(_step("2  Player contract", stage == "contract", stage == "done"))
		v.add_child(sh)
	if reply != "":
		var rp = UI.panel(Color(reply_col, 0.1), 20, 20, 16, Color(reply_col, 0.35))
		rp.add_child(UI.wrap(reply, 24, reply_col if reply_col != UI.MUTED else UI.TEXT))
		v.add_child(rp)
	if stage == "fee":
		var card = UI.card()
		var cv = UI.vb(10)
		cv.add_child(UI.caps("Your offer to %s" % G.s.clubs[p.club].name, 21, UI.MUTED))
		fee_lbl = UI.lbl(G.money(fee), 72, UI.TEXT, "xbold")
		fee_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(fee_lbl)
		var val = float(G.value(p))
		var ask = float(G.TR.asking_price(p))
		var maxv = max(val * 2.6, ask * 1.4)
		var step = max(1000.0, G.nice(val / 40.0))
		cv.add_child(UI.slider(0.0, maxv, fee, step, func(x):
			fee = int(x)
			fee_lbl.text = G.money(fee)))
		var sh2 = UI.hb(0)
		sh2.add_child(UI.caps("Value %s" % G.money(val), 19, UI.DIM))
		sh2.add_child(UI.sp())
		sh2.add_child(UI.caps("Asking ≈ %s" % G.money(ask), 19, UI.DIM))
		cv.add_child(sh2)
		card.add_child(cv)
		v.add_child(card)
		v.add_child(UI.btn("Submit bid", _bid, "primary", "handshake"))
	elif stage == "contract":
		var card = UI.card()
		var cv = UI.vb(10)
		cv.add_child(UI.caps("Weekly wage", 21, UI.MUTED))
		wage_lbl = UI.lbl(G.money(wage), 72, UI.TEXT, "xbold")
		wage_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(wage_lbl)
		var dem = float(G.TR.wage_demand(p))
		cv.add_child(UI.slider(dem * 0.5, dem * 1.8, wage, max(50.0, G.nice(dem / 50.0)), func(x):
			wage = int(x)
			wage_lbl.text = G.money(wage)))
		if p.club == c.id:
			cv.add_child(UI.caps("Current deal: %s / wk until June %d" % [G.money(p.wage), p.cend], 19, UI.DIM))
		cv.add_child(UI.sp(0, 4))
		cv.add_child(UI.caps("Contract length (years)", 21, UI.MUTED))
		cv.add_child(UI.seg(["1", "2", "3", "4", "5"], years - 1, func(i):
			years = i + 1
			refresh()))
		card.add_child(cv)
		v.add_child(card)
		if agreed_fee > 0:
			v.add_child(UI.kv("Agreed fee", G.money(agreed_fee), UI.GREEN))
		v.add_child(UI.btn("Offer contract", _contract, "primary", "handshake"))
	elif stage == "done":
		v.add_child(UI.btn("Done", func(): UI.main.back(), "gold", "check"))
	else:
		v.add_child(UI.btn("Back", func(): UI.main.back(), "secondary"))


func _step(text: String, on: bool, done: bool) -> Control:
	var col = UI.GREEN if done else (UI.accent if on else UI.DIM)
	var p = UI.panel(Color(col, 0.12), 14, 14, 10, Color(col, 0.4))
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var l = UI.caps(text, 20, col)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p


func _bid():
	var p = G.s.players[args.pid]
	var r = G.TR.bid(p, fee)
	reply = r.text
	match r.res:
		"accept":
			reply_col = UI.GREEN
			agreed_fee = fee
			stage = "contract"
			reply += " Now agree personal terms with the player."
		"counter":
			reply_col = UI.AMBER
			fee = min(int(r.fee), int(max(fee, G.uc().budget)))
		"error":
			reply_col = UI.RED
		_:
			reply_col = UI.RED
	refresh()


func _contract():
	var p = G.s.players[args.pid]
	var r = G.TR.contract_offer(p, wage, years)
	reply = r.text
	match r.res:
		"accept":
			reply_col = UI.GREEN
			if args.mode == "renew":
				G.TR.renew(p, wage, years)
				reply += " The new contract runs until June %d." % p.cend
			else:
				if agreed_fee > G.uc().budget:
					reply = "You no longer have the budget to pay the agreed %s fee." % G.money(agreed_fee)
					reply_col = UI.RED
					refresh()
					return
				G.TR.move(p, G.uc().id, agreed_fee, wage, years)
				reply = "DEAL DONE! %s is now a %s player." % [G.pfull(p), G.uc().name]
			stage = "done"
			G.save_game()
		"counter":
			reply_col = UI.AMBER
			wage = int(r.wage)
			tries += 1
		"error":
			reply_col = UI.RED
		_:
			reply_col = UI.RED
			tries += 1
	if tries >= 4 and stage == "contract":
		stage = "blocked"
		reply = "%s's agent has broken off talks." % G.pname(p)
		reply_col = UI.RED
		if args.mode == "buy":
			var n = G.TR.nego(p.id)
			n.fee = -1
			n.block = G.s.day + 14
	refresh()

extends "res://scripts/screens/screen.gd"
# Investments: a trading screen. Ticker tape across the top, the market on the left, the chosen company's chart
# and order ticket in the middle, and the manager's money on the right (portfolio, news, savings, property, work).
# Prices tick live while the screen is open (G.OPS.market_tick) and move properly once a day (market_day).

const CHART = preload("res://scripts/widgets/stock_chart.gd")
const TAPE = preload("res://scripts/widgets/ticker.gd")
const HUB = preload("res://scripts/screens/hub.gd")
const RANGES = [["1W", 6], ["1M", 22], ["3M", 64], ["6M", 128], ["1Y", 260]]
const QTY = [10, 100, 1000, 10000, -1]

var sel := 4
var rng_i := 1
var filt := 0
var qty_i := 2
var side := 0
var tape: Control
var rows := {}          # index -> [price label, change chip label, chip panel, spark]
var live := {}          # labels refreshed every tick
var chart: Control
var timer: Timer


func _ready():
	super._ready()
	UI.enter3d(true)     # the tape moves every frame: cap the frame rate as a 3D view does
	timer = Timer.new()
	timer.wait_time = 1.6
	timer.autostart = true
	timer.timeout.connect(_tick)
	add_child(timer)


func _exit_tree():
	UI.enter3d(false)


func lf() -> Dictionary:
	var l = G.OPS.life()
	if not l.has("savings"):
		G.OPS.invest_week(l)
	G.OPS.market_init(l)
	return l


func cur(v: float) -> String:
	# share prices keep two decimals, in the chosen currency
	var c = str(G.settings.get("cur", "€"))
	return "%s%.2f" % [c, v * float(G.CUR_RATE.get(c, 1.0))]


func pct(v: float) -> String:
	return "%s%.2f%%" % ["+" if v >= 0 else "", v * 100.0]


func signed(v: float) -> String:
	return ("+" if v >= 0 else "") + G.money(v)


func build():
	var l = lf()
	rows = {}
	live = {}
	UI.main.t_title = "Investments"
	UI.main.t_sub = "Cash %s · net worth %s · market %s" % [G.money(l.cash), G.money(G.OPS.net_worth(l)), "open" if G.cur.weekday in [1, 2, 3, 4, 5] else "closed for the weekend"]
	tape = TAPE.new()
	tape.custom_minimum_size = Vector2(0, 34)
	tape.on_tap = func(i):
		sel = i
		refresh()
	body.add_child(UI.margin(tape, 20, 2, 20, 6))
	_tape_items()
	var h = panes(10, 20)
	var a = pane(322, 0)
	h.add_child(a[0])
	_market(a[1])
	var b = pane(0, 8)
	h.add_child(b[0])
	_stock(b[1])
	var c = pane(392, 6)
	c[0].clip_contents = true
	h.add_child(c[0])
	_side(c[1])


func _tape_items():
	var l = G.OPS.life()
	var it = []
	for i in l.px.size():
		it.append([G.OPS.TICK[i], l.px[i], G.OPS.day_change(l, i)])
	tape.set_items(it)


# ---------------------------------------------------------------- market list

func _market(v: VBoxContainer):
	var l = G.OPS.life()
	var top = UI.hb(6)
	top.add_child(UI.caps("Market", 18, UI.accent))
	top.add_child(UI.sp())
	var sg = UI.seg(["All", "Mine", "Up", "Down"], filt, func(i):
		filt = i
		refresh(), 14, 4)
	sg.custom_minimum_size = Vector2(196, 0)
	top.add_child(sg)
	v.add_child(top)
	v.add_child(UI.trow(["Company", "7 days", "Price", "Today"], [0, 58, -70, -66], {"head": true, "size": 16, "pad": 1}))
	var idx = range(l.px.size())
	if filt == 1:
		idx = idx.filter(func(i): return int(l.shares.get(i, 0)) > 0)
	elif filt == 2:
		idx = idx.filter(func(i): return G.OPS.day_change(l, i) >= 0)
		idx.sort_custom(func(x, y): return G.OPS.day_change(l, x) > G.OPS.day_change(l, y))
	elif filt == 3:
		idx = idx.filter(func(i): return G.OPS.day_change(l, i) < 0)
		idx.sort_custom(func(x, y): return G.OPS.day_change(l, x) < G.OPS.day_change(l, y))
	if idx.is_empty():
		v.add_child(UI.wrap("Nothing here yet." if filt != 1 else "You hold no shares. Pick a company and buy from the order ticket.", 17, UI.DIM))
	for i in idx:
		# one line per company: code (gold when you hold it), the name, a 7-day line, price and today's move
		var nm = UI.hb(6)
		var mine = int(l.shares.get(i, 0)) > 0
		var code = UI.lbl(G.OPS.TICK[i], 17, UI.GOLD if mine else UI.TEXT, "disp")
		code.custom_minimum_size = Vector2(46, 0)
		nm.add_child(code)
		var sp = CHART.new()
		sp.spark = true
		sp.custom_minimum_size = Vector2(58, 18)
		var h7 = l.ph[i].slice(-8)
		sp.set_data(h7, UI.GREEN if float(h7[-1]) >= float(h7[0]) else UI.RED)
		var pl = UI.lbl(cur(l.px[i]), 16, UI.TEXT, "semi")
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		var chg = _chg_chip(G.OPS.day_change(l, i))
		var ii = i
		var r = UI.trow([nm, sp, pl, chg[0]], [0, 58, -70, -66], {"hi": i == sel, "pad": 1, "tap": func():
			sel = ii
			refresh()})
		rows[i] = [pl, chg[1], chg[0], sp]
		v.add_child(r)


func _chg_chip(ch: float) -> Array:
	var c = UI.GREEN if ch >= 0 else UI.RED
	var p = UI.panel(Color(c, 0.16), 6, 4, 1)
	var t = UI.lbl(pct(ch), 14, c, "disp")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(t)
	p.custom_minimum_size = Vector2(66, 0)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return [p, t]


func _paint_chip(p: PanelContainer, t: Label, ch: float):
	var c = UI.GREEN if ch >= 0 else UI.RED
	t.text = pct(ch)
	t.add_theme_color_override("font_color", c)
	var sb = p.get_theme_stylebox("panel")
	if sb is StyleBoxFlat:
		sb.bg_color = Color(c, 0.16)


# ---------------------------------------------------------------- one company

func _stock(v: VBoxContainer):
	var l = G.OPS.life()
	var i = sel
	var px = float(l.px[i])
	var ch = G.OPS.day_change(l, i)
	var held = int(l.shares.get(i, 0))
	var head = UI.hb(10)
	head.add_child(UI.chip(G.OPS.TICK[i], UI.accent, UI.on_color(UI.accent), 18))
	var nv = UI.vb(-5)
	nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nv.add_child(UI.lbl_fill(HUB.SPONSORS[i][0], 24, UI.TEXT, "bold"))
	var sp = G.OPS.sponsor_now()
	var shirt = sp != null and str(sp.get("name", "")) == HUB.SPONSORS[i][0]
	nv.add_child(UI.lbl_fill("%s · dividend %.1f%% a year%s" % [HUB.SPONSORS[i][1], G.OPS.yld(i) * 100.0, " · your shirt sponsor" if shirt else ""], 15, UI.GOLD if shirt else UI.MUTED))
	head.add_child(nv)
	var pr = UI.vb(-6)
	var big = UI.lbl(cur(px), 40, UI.TEXT, "xbold")
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pr.add_child(big)
	var cl = UI.lbl("%s  %s today" % [signed_price(px - G.OPS.prev_close(l, i)), pct(ch)], 17, UI.GREEN if ch >= 0 else UI.RED, "semi")
	cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pr.add_child(cl)
	head.add_child(pr)
	live["big"] = big
	live["chg"] = cl
	v.add_child(head)
	# chart with its range
	var bar = UI.hb(8)
	var n = RANGES[rng_i][1]
	var hist = l.ph[i].slice(-(n + 1))
	var rch = float(hist[-1]) / float(hist[0]) - 1.0
	bar.add_child(UI.lbl("%s over %s" % [pct(rch), ["the week", "the month", "3 months", "6 months", "the year"][rng_i]], 16, UI.GREEN if rch >= 0 else UI.RED, "semi"))
	bar.add_child(UI.sp())
	var rs = UI.seg(RANGES.map(func(x): return x[0]), rng_i, func(k):
		rng_i = k
		refresh(), 14, 4)
	rs.custom_minimum_size = Vector2(250, 0)
	bar.add_child(rs)
	v.add_child(bar)
	chart = CHART.new()
	chart.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chart.custom_minimum_size = Vector2(0, 150)
	chart.set_data(hist, UI.GREEN if rch >= 0 else UI.RED, float(l.cost.get(i, -1.0)) if held > 0 else -1.0)
	v.add_child(chart)
	# key numbers
	var lo = INF
	var hi = -INF
	for x in l.ph[i]:
		lo = min(lo, float(x))
		hi = max(hi, float(x))
	var g = GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 18)
	g.add_theme_constant_override("v_separation", 0)
	var cells = [["Previous close", cur(G.OPS.prev_close(l, i)), UI.TEXT], ["Year low", cur(lo), UI.TEXT], ["Year high", cur(hi), UI.TEXT]]
	if held > 0:
		var cost = float(l.cost.get(i, px))
		var gain = (px - cost) * held
		cells += [["You hold", "%s shares" % G.OPS._n(held), UI.GOLD], ["Your average price", cur(cost), UI.TEXT], ["Profit / loss", "%s (%s)" % [signed(gain), pct(px / cost - 1.0)], UI.GREEN if gain >= 0 else UI.RED]]
	else:
		cells += [["You hold", "None", UI.DIM], ["Dividend a week", "%s per 1,000" % G.money(px * 1000 * G.OPS.yld(i) / 52.0), UI.TEXT], ["Volatility", ["Calm", "Steady", "Lively", "Wild"][clampi(int((G.OPS.vol(i) - 0.008) / 0.005), 0, 3)], UI.TEXT]]
	for c in cells:
		var kv = UI.kv(c[0], c[1], c[2], 16)
		kv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g.add_child(kv)
		if c[0] == "Profit / loss":
			live["pl"] = kv.get_child(2)
	v.add_child(g)
	# order ticket
	var tk = UI.panel(Color(1, 1, 1, 0.04), 14, 12, 10, UI.LINE)
	var tv = UI.vb(8)
	tk.add_child(tv)
	var r1 = UI.hb(8)
	r1.add_child(UI.caps("Order", 16, UI.accent))
	var qs = UI.seg(["10", "100", "1K", "10K", "Max"], qty_i, func(k):
		qty_i = k
		refresh(), 15, 5)
	qs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r1.add_child(qs)
	tv.add_child(r1)
	var q = _qty(l, i)
	var r2 = UI.hb(8)
	var ol = UI.lbl_fill("", 16, UI.MUTED)
	live["order"] = ol
	r2.add_child(ol)
	var bb = UI.btn("Buy %s" % G.OPS._n(q), func(): _do(l, i, _qty(l, i)), "primary", "trending-up", 46)
	bb.custom_minimum_size = Vector2(150, 46)
	r2.add_child(bb)
	var sq = min(q, held) if QTY[qty_i] > 0 else held
	var sb = UI.btn("Sell %s" % (G.OPS._n(sq) if held > 0 else ""), func(): _do(l, i, -(min(_qty(l, i), held) if QTY[qty_i] > 0 else held)), "secondary", "", 46)
	sb.custom_minimum_size = Vector2(130, 46)
	if held <= 0:
		sb.modulate = Color(1, 1, 1, 0.4)
	r2.add_child(sb)
	tv.add_child(r2)
	v.add_child(tk)
	_order_text()


func signed_price(d: float) -> String:
	return ("+" if d >= 0 else "-") + cur(absf(d)).substr(0)


func _qty(l: Dictionary, i: int) -> int:
	return QTY[qty_i] if QTY[qty_i] > 0 else max(1, G.OPS.max_buy(l, i))


func _order_text():
	if not live.has("order"):
		return
	var l = G.OPS.life()
	var q = _qty(l, sel)
	var cost = float(l.px[sel]) * q
	live.order.text = "Total %s · fee %s" % [G.money(cost), G.money(cost * G.OPS.FEE)]


func _do(l: Dictionary, i: int, q: int):
	if q == 0:
		return
	var why = G.OPS.trade(l, i, q)
	if why != "":
		UI.sfx("error", -8.0)
		UI.toast(why, UI.RED)
		return
	UI.sfx("cash", -8.0)
	UI.toast("%s %s %s shares at %s" % ["Bought" if q > 0 else "Sold", G.OPS._n(absi(q)), G.OPS.TICK[i], cur(l.px[i])], UI.GREEN if q > 0 else UI.TEXT)
	refresh()


# ---------------------------------------------------------------- the manager's money

func _side(v: VBoxContainer):
	var sg = UI.seg(["Shares", "News", "Savings", "Property", "Work"], side, func(k):
		side = k
		refresh(), 13, 4)
	v.add_child(sg)
	v.add_child(UI.sp(0, 2))
	call(["_portfolio", "_news", "_savings", "_property", "_work"][side], v)


func _portfolio(v: VBoxContainer):
	var l = G.OPS.life()
	var pf = G.OPS.portfolio(l)
	v.add_child(UI.caps("Shares you hold", 15, UI.MUTED))
	var tot = UI.lbl(G.money(pf.value), 36, UI.TEXT, "xbold")
	live["pval"] = tot
	v.add_child(tot)
	var r = UI.hb(8)
	var td = UI.stat_tile("Today", signed(pf.today), UI.GREEN if pf.today >= 0 else UI.RED)
	var al = UI.stat_tile("All time", signed(pf.pl), UI.GREEN if pf.pl >= 0 else UI.RED)
	live["ptoday"] = td.get_child(0).get_child(0)
	live["pall"] = al.get_child(0).get_child(0)
	r.add_child(td)
	r.add_child(al)
	v.add_child(r)
	v.add_child(UI.kv("Cash to invest", G.money(l.cash), UI.GREEN, 17))
	v.add_child(UI.kv("Dividends a week", G.money(G.OPS.dividends(l)), UI.TEXT, 17))
	v.add_child(UI.kv("Savings · property", "%s · %s" % [G.money(l.savings), G.money(_prop_value(l))], UI.TEXT, 17))
	if l.shares.is_empty():
		v.add_child(UI.wrap("No shares yet. Steady payers: telecoms, drinks and insurance. Tech and airlines move fastest, both ways.", 16, UI.DIM))
		return
	v.add_child(UI.trow(["Holding", "Value", "P/L"], [0, -84, -70], {"head": true, "size": 17}))
	var keys = l.shares.keys()
	keys.sort_custom(func(x, y): return float(l.shares[x]) * float(l.px[int(x)]) > float(l.shares[y]) * float(l.px[int(y)]))
	for k in keys:
		var i = int(k)
		var q = int(l.shares[k])
		var cost = float(l.cost.get(k, l.px[i]))
		var g = float(l.px[i]) / cost - 1.0
		var nm = UI.hb(6)
		nm.add_child(UI.lbl(G.OPS.TICK[i], 17, UI.TEXT, "disp"))
		nm.add_child(UI.lbl_fill(G.OPS._n(q), 15, UI.DIM))
		var ii = i
		v.add_child(UI.trow([nm, G.money(q * float(l.px[i])), pct(g)], [0, -84, -70], {"hi": i == sel, "pad": 3, "size": 17, "cols": {2: UI.GREEN if g >= 0 else UI.RED}, "tap": func():
			sel = ii
			refresh()}))
	if not l.trades.is_empty():
		v.add_child(UI.sp(0, 4))
		v.add_child(UI.caps("Recent orders", 15, UI.MUTED))
		for t in l.trades.slice(0, 4):
			v.add_child(UI.lbl_fill("%s  %s %s %s at %s" % [G.fmt_date(int(t.d)), "Bought" if int(t.q) > 0 else "Sold", G.OPS._n(absi(int(t.q))), G.OPS.TICK[int(t.i)], cur(float(t.p))], 15, UI.DIM))


func _news(v: VBoxContainer):
	var l = G.OPS.life()
	v.add_child(UI.caps("Market news", 15, UI.MUTED))
	if l.mnews.is_empty():
		v.add_child(UI.wrap("A quiet market so far. Company news (results, contracts, recalls) moves a price by 4-14% in a day.", 16, UI.DIM))
	for nw in l.mnews.slice(0, 12):
		var i = int(nw.i)
		var p = UI.panel(Color(1, 1, 1, 0.03), 8, 10, 6)
		var pv = UI.vb(0)
		var t1 = UI.hb(6)
		t1.add_child(UI.lbl(G.OPS.TICK[i], 16, UI.TEXT, "disp"))
		t1.add_child(UI.lbl_fill(G.fmt_date(int(nw.d)), 14, UI.DIM))
		var mv = float(nw.mv)
		t1.add_child(UI.lbl(pct(mv), 16, UI.GREEN if mv >= 0 else UI.RED, "disp"))
		pv.add_child(t1)
		pv.add_child(UI.wrap(str(nw.t), 16, UI.TEXT))
		p.add_child(pv)
		var ii = i
		UI.tap(p, func():
			sel = ii
			refresh())
		v.add_child(p)


func _savings(v: VBoxContainer):
	var l = G.OPS.life()
	v.add_child(UI.caps("Savings account · safe", 15, UI.MUTED))
	v.add_child(UI.lbl(G.money(l.savings), 36, UI.GREEN, "xbold"))
	v.add_child(UI.lbl("About 3.7% a year, paid weekly. It never falls.", 16, UI.MUTED))
	v.add_child(UI.kv("Cash", G.money(l.cash), UI.TEXT, 17))
	for row in [[50000, 500000], [-1, 0]]:
		var h = UI.hb(8)
		for amt in row:
			if amt == 0:
				var w = UI.btn("Withdraw all", func():
					l.cash += l.savings
					l.savings = 0
					UI.sfx("cash", -8.0)
					refresh(), "ghost", "", 44)
				w.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				h.add_child(w)
				continue
			var x = amt
			var b = UI.btn("Pay in all cash" if x < 0 else "Pay in %s" % G.money(x), func():
				var y = int(l.cash) if x < 0 else x
				if y <= 0 or l.cash < y:
					UI.toast("Not enough cash", UI.RED)
					return
				l.cash -= y
				l.savings += y
				UI.sfx("cash", -8.0)
				refresh(), "secondary", "", 44)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			h.add_child(b)
		v.add_child(h)


func _prop_value(l: Dictionary) -> int:
	var pv = 0
	for pr in l.props:
		pv += int(pr.value)
	return pv


func _property(v: VBoxContainer):
	var l = G.OPS.life()
	var rent = 0
	for pr in l.props:
		rent += int(pr.rent)
	v.add_child(UI.caps("Property · steady", 15, UI.MUTED))
	var r = UI.hb(8)
	r.add_child(UI.stat_tile("Value", G.money(_prop_value(l)), UI.TEXT))
	r.add_child(UI.stat_tile("Rent a week", G.money(rent), UI.GREEN))
	v.add_child(r)
	for i in HUB.PROPS.size():
		var n = 0
		for pr in l.props:
			if pr.k == i:
				n += 1
		var row = UI.hb(8)
		row.add_child(_pic("prop_%d" % (i + 1), 64, 42))
		var tv = UI.vb(-5)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UI.lbl_fill("%s%s" % [HUB.PROPS[i][0], "  × %d" % n if n > 0 else ""], 17, UI.TEXT, "semi"))
		tv.add_child(UI.lbl_fill("Rent %s a week" % G.money(HUB.PROPS[i][2]), 14, UI.MUTED))
		row.add_child(tv)
		var idx = i
		var b = UI.chip("BUY " + G.money(HUB.PROPS[i][1]), UI.accent, UI.on_color(UI.accent), 15)
		UI.tap(b, func():
			var cost = HUB.PROPS[idx][1]
			if l.cash < cost:
				UI.sfx("error", -8.0)
				UI.toast("You need %s; you have %s" % [G.money(cost), G.money(l.cash)], UI.RED)
				return
			l.cash -= cost
			l.props.append({"k": idx, "rent": HUB.PROPS[idx][2], "value": cost})
			UI.sfx("cash", -8.0)
			UI.toast("Bought: %s" % HUB.PROPS[idx][0], UI.GREEN)
			refresh(), true)
		row.add_child(b)
		v.add_child(row)
	if not l.props.is_empty():
		v.add_child(UI.btn("Sell all property for %s" % G.money(_prop_value(l)), func():
			l.cash += _prop_value(l)
			l.props = []
			UI.sfx("cash", -8.0)
			refresh(), "ghost", "", 42))


func _pic(nm: String, w: float, h: float) -> Control:
	var p = UI.panel(Color("14171f"), 8, 0, 0)
	p.custom_minimum_size = Vector2(w, h)
	p.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var path = "res://assets/life/%s.jpg" % nm
	if ResourceLoader.exists(path):
		var t = TextureRect.new()
		t.texture = load(path)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(t)
	return p


func _work(v: VBoxContainer):
	var l = G.OPS.life()
	v.add_child(UI.caps("Work off the pitch", 15, UI.MUTED))
	v.add_child(UI.btn("Agent: %s (%s a week)" % ["hired" if l.agent else "none", G.money(2000)], func():
		l.agent = not l.agent
		refresh(), "primary" if l.agent else "secondary", "briefcase", 46))
	v.add_child(UI.wrap("An agent makes the board more likely to agree a pay rise.", 15, UI.DIM))
	v.add_child(UI.btn("TV and newspaper work: %s" % ("on" if l.media else "off"), func():
		l.media = not l.media
		refresh(), "primary" if l.media else "secondary", "megaphone", 46))
	v.add_child(UI.wrap("Pays %s a week and builds reputation, but the board likes it less each week." % G.money(8000), 15, UI.DIM))
	v.add_child(UI.sp(0, 4))
	v.add_child(UI.caps("Your week", 15, UI.MUTED))
	for row in G.OPS.life_ledger(l):
		v.add_child(UI.kv(row[0], signed(row[1]) if row[1] < 0 else G.money(row[1]), UI.RED if row[1] < 0 else UI.TEXT, 16))


# ---------------------------------------------------------------- live prices

func _tick():
	if not is_inside_tree() or G.s == null:
		return
	var l = G.OPS.life()
	if G.cur.weekday == 0 or G.cur.weekday == 6:
		return     # the market is shut at the weekend: the tape keeps rolling, prices stay put
	G.OPS.market_tick(l)
	_tape_items()
	for i in rows:
		var rw = rows[i]
		if is_instance_valid(rw[0]):
			rw[0].text = cur(l.px[i])
			_paint_chip(rw[2], rw[1], G.OPS.day_change(l, i))
	var px = float(l.px[sel])
	var ch = G.OPS.day_change(l, sel)
	if live.has("big") and is_instance_valid(live.big):
		live.big.text = cur(px)
		live.chg.text = "%s  %s today" % [signed_price(px - G.OPS.prev_close(l, sel)), pct(ch)]
		live.chg.add_theme_color_override("font_color", UI.GREEN if ch >= 0 else UI.RED)
	if chart != null and is_instance_valid(chart):
		var n = RANGES[rng_i][1]
		var hist = l.ph[sel].slice(-(n + 1))
		chart.set_data(hist, chart.col, chart.base)
	if live.has("pl") and is_instance_valid(live.pl):
		var held = int(l.shares.get(sel, 0))
		var cost = float(l.cost.get(sel, px))
		var gain = (px - cost) * held
		live.pl.text = "%s (%s)" % [signed(gain), pct(px / cost - 1.0)]
		live.pl.add_theme_color_override("font_color", UI.GREEN if gain >= 0 else UI.RED)
	if live.has("pval") and is_instance_valid(live.pval):
		var pf = G.OPS.portfolio(l)
		live.pval.text = G.money(pf.value)
		for k in [["ptoday", pf.today], ["pall", pf.pl]]:
			var lb = live[k[0]]
			lb.text = signed(k[1])
			lb.add_theme_color_override("font_color", UI.GREEN if k[1] >= 0 else UI.RED)
	_order_text()

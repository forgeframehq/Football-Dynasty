extends "res://scripts/screens/screen.gd"
# The manager's life away from the touchline: where he lives, what he drives, what he owns and where the money goes.

const TABS = ["Overview", "Homes", "Garage", "Business", "Money"]
# name, price, blurb, bedrooms, floor area m2, district
const HOMES = [
	["Club flat", 0, "A small furnished flat the club lends its staff. Fine for now.", 1, 48, "Next to the training ground"],
	["City apartment", 180000, "Two bedrooms, a balcony and a ten-minute walk to the stadium.", 2, 95, "Stadium quarter"],
	["Riverside penthouse", 900000, "The whole top floor, glass on three sides and a view of the skyline.", 3, 210, "Old docks"],
	["Country villa", 3500000, "Gardens, a pool and a long gravel drive. Nobody bothers you here.", 5, 480, "Half an hour out of town"],
	["Mansion estate", 12000000, "Gates, grounds, a private pitch and a wing for guests. The home of a football great.", 9, 1400, "Private estate"]]
# class, model, price, power bhp, top speed km/h, 0-100 seconds, picture
const CARS = [
	["Club car", "Vento Estate 1.6", 0, 120, 195, 10.8, "car_1"],
	["Executive saloon", "Aurel S5 Hybrid", 45000, 300, 250, 5.6, "car_1"],
	["Sports coupe", "Kestrel GT", 160000, 480, 295, 3.9, "car_2"],
	["Supercar", "Fulmine V12", 600000, 800, 345, 2.8, "car_3"],
	["Classic collection", "1962 Corsa Rossa and four more", 2500000, 300, 260, 6.4, "car_4"]]
const BIZ = [["Local restaurant", 250000, 1800, "Forty covers, full most nights when the team wins."], ["Football academy school", 1200000, 9500, "Fee-paying coaching for local children, with your name over the door."],
	["Boutique hotel", 5000000, 42000, "Thirty rooms in the city centre. Away fans book it out."]]

var tab := 0
var pick := -1


func build():
	var s = G.s
	var u = s.user
	var lf = G.OPS.life()
	G.OPS.invest_init(lf)
	var country = s.leagues[G.uc().lg].country
	if lf.country != country:
		lf.country = country
		lf.settled = 10.0
	body.add_child(UI.topbar("Lifestyle"))
	UI.main.t_sub = "%s in the bank · net worth %s · living in %s" % [G.money(lf.cash), G.money(G.OPS.net_worth(lf)), country]
	body.add_child(UI.margin(UI.seg(TABS, tab, func(i):
		tab = i
		pick = -1
		refresh(), 19), 20, 0, 20, 6))
	var h = panes(10, 20)
	match tab:
		0: _overview(h, lf, country)
		1: _showroom(h, lf, true)
		2: _showroom(h, lf, false)
		3: _business(h, lf)
		4: _money(h, lf)


func _pic(nm: String, w: float, hh: float) -> Control:
	var path = "res://assets/life/%s.jpg" % nm
	var p = UI.panel(Color("14171f"), 10, 0, 0)
	p.custom_minimum_size = Vector2(w, hh)
	p.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(path):
		var t = TextureRect.new()
		t.texture = load(path)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(t)
	if w <= 0:
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return p


func _buy(lf: Dictionary, cost: int, what: String, apply: Callable):
	if lf.cash < cost:
		UI.sfx("error", -8.0)
		UI.toast("You need %s; you have %s" % [G.money(cost), G.money(lf.cash)], UI.RED)
		return
	lf.cash -= cost
	apply.call()
	UI.sfx("cash", -8.0)
	UI.toast(what, UI.GREEN)
	G.save_game()
	refresh()


func _overview(h: Control, lf: Dictionary, country: String):
	var u = G.s.user
	var home = HOMES[lf.home]
	var car = CARS[lf.car]
	for it in [["Where you live", "home_%d" % (lf.home + 1), home[0], "%d bed · %d m² · %s" % [home[3], home[4], home[5]], home[2], "Upkeep %s a week" % G.money(G.OPS.HOME_UP[lf.home]), 1],
			["What you drive", car[6], car[1], "%s · %d bhp · %d km/h · 0-100 in %.1fs" % [car[0], car[3], car[4], car[5]], "Provided by the club while you work here." if lf.car == 0 else "Yours, paid in full. %d car%s in the garage." % [lf.cars.size(), "" if lf.cars.size() == 1 else "s"], "Running costs %s a week" % G.money(G.OPS.CAR_UP[lf.car]), 2]]:
		var a = pane(0, 4)
		h.add_child(a[0])
		var v = a[1]
		v.add_child(UI.caps(it[0], 15, UI.accent))
		var pc = _pic(it[1], 0, 170)
		v.add_child(pc)
		v.add_child(UI.lbl_fill(it[2], 26, UI.TEXT, "xbold"))
		v.add_child(UI.lbl_fill(it[3], 16, UI.GOLD))
		v.add_child(UI.wrap(it[4], 17, UI.MUTED))
		v.add_child(UI.lbl_fill(it[5], 16, UI.DIM))
		var tb = it[6]
		v.add_child(UI.btn("Visit the %s" % ("estate agent" if tb == 1 else "showroom"), func():
			tab = tb
			refresh(), "secondary", "house" if tb == 1 else "zap", 48))
	var c = pane(300, 4)
	h.add_child(c[0])
	var v2 = c[1]
	v2.add_child(UI.caps("Your money", 15, UI.accent))
	v2.add_child(UI.lbl(G.money(lf.cash), 36, UI.GREEN, "xbold"))
	var led = G.OPS.life_ledger(lf)
	var net = 0
	for r in led:
		net += r[1]
	v2.add_child(UI.kv("Weekly salary", G.money(G.OPS.salary())))
	v2.add_child(UI.kv("Net each week", ("+" if net >= 0 else "") + G.money(net), UI.GREEN if net >= 0 else UI.RED))
	v2.add_child(UI.kv("Net worth", G.money(G.OPS.net_worth(lf))))
	v2.add_child(UI.caps("Life in %s" % country, 15, UI.accent))
	var ch = UI.hb(8)
	ch.add_child(UI.flag(country, 34))
	ch.add_child(UI.lbl_fill("Settled", 18, UI.MUTED))
	ch.add_child(UI.lbl("%d%%" % int(lf.settled), 19, UI.TEXT, "bold"))
	v2.add_child(ch)
	v2.add_child(UI.bar(lf.settled / 100.0, UI.accent, 8))
	var lang = G.PS.LANGS.get(country, "English")
	var native = G.PS.LANGS.get(u.nat, "") == lang
	var prog = float(lf.lang.get(lang, 100.0 if native else 0.0))
	lf.lang[lang] = prog
	v2.add_child(UI.kv(lang, "Fluent" if prog >= 100 else ("%d%% · studying" % int(prog) if lf.study == lang else "%d%%" % int(prog)), UI.GREEN if prog >= 100 else UI.TEXT))
	if prog < 100:
		v2.add_child(UI.btn("Stop lessons" if lf.study == lang else "%s lessons · %s/wk" % [lang, G.money(400)], func():
			lf.study = "" if lf.study == lang else lang
			refresh(), "secondary", "book-open", 46))
	v2.add_child(UI.btn("Give %s to a local cause" % G.money(25000), func(): _buy(lf, 25000, "The fans noticed your donation", func():
		u["fans"] = min(100.0, float(u.get("fans", 55.0)) + 3.0)), "secondary", "heart", 46))
	var m = G.cur.month
	if m == 6 or m == 7 or m == 12:
		var went = int(lf.get("holiday", -1)) == G.s.season * 100 + m
		v2.add_child(UI.btn("Holiday taken" if went else "Take a holiday · %s" % G.money(15000), func():
			if went:
				return
			_buy(lf, 15000, "A week away. You come back fresh.", func():
				lf["holiday"] = G.s.season * 100 + m
				lf.settled = min(100.0, lf.settled + 6.0)
				u.conf = min(100.0, u.conf + 2.0)), "secondary", "tree-palm", 46))


func _showroom(h: Control, lf: Dictionary, homes: bool):
	var u = G.s.user
	var items = HOMES if homes else CARS
	var cur = lf.home if homes else lf.car
	if pick < 0:
		pick = min(cur + 1, items.size() - 1) if homes else cur
	# list
	var a = pane(330, 4)
	h.add_child(a[0])
	var v = a[1]
	v.add_child(UI.caps("Estate agent" if homes else "Showroom", 15, UI.accent))
	for i in items.size():
		var it = items[i]
		var on = i == pick
		var owned = (i == lf.home) if homes else (i in lf.cars)
		var r = UI.panel(Color(UI.accent, 0.16) if on else Color(1, 1, 1, 0.03), 10, 8, 6, Color(UI.accent, 0.55) if on else Color(0, 0, 0, 0))
		var rh = UI.hb(10)
		rh.add_child(_pic(("home_%d" % (i + 1)) if homes else it[6], 74, 46))
		var tv = UI.vb(-4)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UI.lbl_fill(it[0] if homes else it[1], 19, UI.TEXT, "semi"))
		tv.add_child(UI.lbl_fill(("Lives here" if homes else ("Driving" if i == lf.car else "In your garage")) if owned else (G.money(it[1] if homes else it[2]) if (it[1] if homes else it[2]) > 0 else "Club property"), 15, UI.GOLD if owned else UI.MUTED))
		rh.add_child(tv)
		r.add_child(rh)
		var idx = i
		UI.tap(r, func():
			pick = idx
			refresh())
		v.add_child(r)
	# detail
	var b = pane(0, 6)
	h.add_child(b[0])
	v = b[1]
	var it2 = items[pick]
	var price = int(it2[1] if homes else it2[2])
	v.add_child(_pic(("home_%d" % (pick + 1)) if homes else it2[6], 0, 165))
	var th = UI.hb(10)
	var tv2 = UI.vb(-4)
	tv2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv2.add_child(UI.lbl_fill(it2[0] if homes else it2[1], 30, UI.TEXT, "xbold"))
	tv2.add_child(UI.lbl_fill(it2[5] if homes else it2[0], 17, UI.GOLD))
	th.add_child(tv2)
	th.add_child(UI.lbl(G.money(price) if price > 0 else "—", 30, UI.GREEN if lf.cash >= price else UI.RED, "xbold"))
	v.add_child(th)
	var g = UI.hb(8)
	if homes:
		g.add_child(UI.stat_tile("Bedrooms", str(it2[3])))
		g.add_child(UI.stat_tile("Floor area", "%d m²" % it2[4]))
		g.add_child(UI.stat_tile("Upkeep / wk", G.money(G.OPS.HOME_UP[pick])))
		g.add_child(UI.stat_tile("Settling in", "+%.1f / wk" % (1.5 + pick * 0.8), UI.accent))
	else:
		g.add_child(UI.stat_tile("Power", "%d bhp" % it2[3]))
		g.add_child(UI.stat_tile("Top speed", "%d km/h" % it2[4]))
		g.add_child(UI.stat_tile("0-100", "%.1f s" % it2[5]))
		g.add_child(UI.stat_tile("Running / wk", G.money(G.OPS.CAR_UP[pick])))
	v.add_child(g)
	if homes:
		v.add_child(UI.wrap(it2[2], 18, UI.MUTED))
	var bh = UI.hb(8)
	var idx2 = pick
	if homes:
		if pick == lf.home:
			bh.add_child(UI.btn("You live here", func(): pass, "secondary", "house", 52))
		else:
			var back = int(HOMES[lf.home][1] * 0.9)
			var cost = price - back
			var lab = ("Buy · %s after selling your %s" % [G.money(cost), HOMES[lf.home][0].to_lower()]) if back > 0 and cost > 0 else ("Buy for %s" % G.money(price) if cost > 0 else "Move here · get %s back" % G.money(-cost))
			if pick == 0:
				lab = "Move back to the club flat · get %s back" % G.money(back)
			bh.add_child(UI.btn(lab, func(): _buy(lf, cost, "The keys to the %s are yours" % HOMES[idx2][0].to_lower(), func():
				if idx2 > lf.home:
					u.rep = min(100.0, u.rep + 0.5 * (idx2 - lf.home))
				lf.home = idx2), "primary", "house", 52))
	else:
		if pick in lf.cars:
			if pick == lf.car:
				bh.add_child(UI.btn("You are driving this", func(): pass, "secondary", "check", 52))
			else:
				bh.add_child(UI.btn("Drive this one", func():
					lf.car = idx2
					refresh(), "primary", "check", 52))
			if pick > 0 and pick != lf.car:
				bh.add_child(UI.btn("Sell · %s" % G.money(int(price * 0.7)), func():
					lf.cars.erase(idx2)
					lf.cash += int(price * 0.7)
					UI.sfx("cash", -8.0)
					refresh(), "danger", "", 52))
		else:
			bh.add_child(UI.btn("Buy for %s" % G.money(price), func(): _buy(lf, price, "The %s is in your garage" % CARS[idx2][1], func():
				lf.cars.append(idx2)
				lf.car = idx2
				u.rep = min(100.0, u.rep + 0.2 * idx2)), "primary", "zap", 52))
	for bb in bh.get_children():
		bb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(bh)
	# side: what you have
	var c = pane(240, 4)
	h.add_child(c[0])
	v = c[1]
	v.add_child(UI.caps("In the bank", 15, UI.accent))
	v.add_child(UI.lbl(G.money(lf.cash), 28, UI.GREEN, "xbold"))
	v.add_child(UI.kv("After buying", G.money(lf.cash - price), UI.TEXT if lf.cash >= price else UI.RED))
	v.add_child(UI.caps("Home" if homes else "Garage", 15, UI.accent))
	if homes:
		v.add_child(UI.lbl_fill(HOMES[lf.home][0], 19, UI.TEXT, "semi"))
		v.add_child(UI.wrap("A better home helps you settle in the country faster and adds a little to your reputation.", 15, UI.DIM))
	else:
		for ci in lf.cars:
			v.add_child(UI.kv(CARS[ci][1], "Driving" if ci == lf.car else "", UI.GOLD))
		v.add_child(UI.wrap("Cars can be sold back for 70% of their price.", 15, UI.DIM))


func _business(h: Control, lf: Dictionary):
	for i in BIZ.size():
		var a = pane(0, 4)
		h.add_child(a[0])
		var v = a[1]
		var own = i in lf.biz
		v.add_child(_pic("biz_%d" % (i + 1), 0, 170))
		v.add_child(UI.lbl_fill(BIZ[i][0], 24, UI.TEXT, "xbold"))
		v.add_child(UI.wrap(BIZ[i][3], 17, UI.MUTED))
		v.add_child(UI.kv("Price", G.money(BIZ[i][1])))
		v.add_child(UI.kv("Pays", "%s a week" % G.money(BIZ[i][2]), UI.GREEN))
		v.add_child(UI.kv("Pays for itself in", "%.1f years" % (BIZ[i][1] / float(BIZ[i][2]) / 52.0)))
		var idx = i
		if own:
			v.add_child(UI.btn("Owned", func(): pass, "secondary", "check", 50))
		else:
			v.add_child(UI.btn("Buy", func(): _buy(lf, BIZ[idx][1], "You now own the %s" % BIZ[idx][0].to_lower(), func():
				lf.biz.append(idx)
				lf.income += BIZ[idx][2]), "primary", "briefcase", 50))
	var c = pane(250, 4)
	h.add_child(c[0])
	var v2 = c[1]
	v2.add_child(UI.caps("More ways to invest", 15, UI.accent))
	v2.add_child(UI.wrap("Savings, rental property, shares and stakes in football clubs are on the Investments page.", 16, UI.MUTED))
	v2.add_child(UI.btn("Investments", func(): UI.main.root("hub", {"kind": "invest", "grp": "manager"}), "secondary", "trending-up", 48))
	v2.add_child(UI.btn("Club ownership", func(): UI.main.root("hub", {"kind": "owner", "grp": "manager"}), "secondary", "landmark", 48))
	v2.add_child(UI.kv("Business income", "%s/wk" % G.money(lf.income), UI.GREEN))


func _money(h: Control, lf: Dictionary):
	var a = pane(0, 3)
	h.add_child(a[0])
	var v = a[1]
	v.add_child(UI.caps("Every week", 15, UI.accent))
	var net = 0
	var led = G.OPS.life_ledger(lf)
	for i in led.size():
		var r = led[i]
		net += r[1]
		v.add_child(UI.trow([r[0], ("+" if r[1] >= 0 else "") + G.money(r[1])], [0, -110], {"alt": i % 2 == 0, "cols": {1: UI.GREEN if r[1] >= 0 else UI.RED}}))
	v.add_child(UI.trow(["Net each week", ("+" if net >= 0 else "") + G.money(net)], [0, -110], {"hi": true, "cols": {1: UI.GREEN if net >= 0 else UI.RED}}))
	v.add_child(UI.kv("In a year", G.money(net * 52)))
	var b = pane(0, 3)
	h.add_child(b[0])
	v = b[1]
	v.add_child(UI.caps("What you are worth", 15, UI.accent))
	var rows = G.OPS.worth_rows(lf)
	var tot = 0
	for i in rows.size():
		tot += rows[i][1]
		v.add_child(UI.trow([rows[i][0], G.money(rows[i][1])], [0, -110], {"alt": i % 2 == 0}))
	v.add_child(UI.trow(["Net worth", G.money(tot)], [0, -110], {"hi": true, "cols": {1: UI.GOLD}}))
	var c = pane(280, 4)
	h.add_child(c[0])
	v = c[1]
	v.add_child(UI.caps("Your contract", 15, UI.accent))
	v.add_child(UI.kv("Salary", "%s/wk" % G.money(G.OPS.salary())))
	v.add_child(UI.kv("Club", G.uc().short))
	v.add_child(UI.btn("My contract", func(): UI.main.root("hub", {"kind": "contract", "grp": "manager"}), "secondary", "file-text", 48))
	v.add_child(UI.wrap("Win bonuses and title bonuses are paid straight into your account.", 15, UI.DIM))

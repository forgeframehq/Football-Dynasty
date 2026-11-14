extends "res://scripts/screens/screen.gd"
# Kit & Sponsors: a 3D kit you can turn round on the left, the design of each kit in the middle,
# and every sponsor deal (shirt front, back, sleeve, training kit, stadium name) on the right.

const SHIRT = preload("res://scripts/widgets/shirt.gd")
const KITVIEW = preload("res://scripts/widgets/kit_view.gd")
const SWATCH = ["ffffff", "111111", "d0021b", "8b0000", "f5a623", "f8e71c", "1e8e3e", "0b6e4f", "6cabdd", "1f4fbf", "0a1a5c", "6b2fb3", "ff6fb1", "7a4a1e", "9aa3ad", "e9c46a"]
const WHICH = ["home", "away", "third", "gk"]

var preview := ""       # shirt sponsor being looked at before signing
var which := 0
var kv = null
var facing_back := false


func build():
	title = "Kit & Sponsors"
	var c = G.uc()
	var sp = G.OPS.sponsor_now()
	var extra = G.OPS.spx_week()
	subtitle = "%s%s" % ["%s on the shirt" % sp.name if sp != null else "No shirt sponsor yet", " · other deals %s a week" % G.money(extra) if extra > 0 else ""]
	var row = panes(10, 20)
	_shirt(row, c, sp)
	_design(row, c)
	_sponsor(row, c, sp)


func _kit(c: Dictionary) -> Dictionary:
	return G.OPS.kit(c, WHICH[which])


func _put(c: Dictionary, key: String, val):
	if which == 0:
		c[{"c1": "c1", "c2": "c2", "p": "kitp"}[key]] = val
	else:
		G.OPS.kit(c, WHICH[which])[key] = val


func _shirt(row: Control, c: Dictionary, sp):
	var pn = pane(330, 4)
	var v = pn[1]
	row.add_child(pn[0])
	v.add_child(UI.seg(["Home", "Away", "Third", "Keeper"], which, func(i):
		which = i
		refresh(), 15, 6))
	var nm = sp.name if sp != null else preview
	var best = null
	for pid in c.players:
		var p = G.s.players[pid]
		if best == null or p.ovr > best.ovr:
			best = p
	var kt = _kit(c)
	if G.settings.get("lowgfx", false):
		var sh = SHIRT.new()
		sh.custom_minimum_size = Vector2(0, 300)
		sh.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sh.setup(Color(str(kt.c1)), Color(str(kt.c2)), int(kt.p), nm, G.OPS.sponsor_logo(nm) if nm != "" else null, UI.CARD)
		v.add_child(sh)
	else:
		kv = KITVIEW.new()
		kv.kit = kt
		kv.gk = which == 3
		kv.front = G.OPS.sponsor_logo(nm) if nm != "" else null
		var bk = G.OPS.spx_now("back")
		kv.back = G.OPS.sponsor_logo(bk.name) if bk != null else null
		var sl = G.OPS.spx_now("sleeve")
		kv.sleeve = G.OPS.sponsor_logo(sl.name) if sl != null else null
		if best != null:
			kv.pname = str(best.ln if best.get("cn", "") == "" else best.cn)
			kv.number = int(best.get("num", 10))
		kv.custom_minimum_size = Vector2(0, 390)
		kv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		kv.size_flags_vertical = Control.SIZE_EXPAND_FILL
		kv.start_back = facing_back
		v.add_child(kv)
		var bh = UI.hb(6)
		for o in [["Front", false], ["Back", true]]:
			var b = UI.btn(o[0], func():
				facing_back = o[1]
				kv.show_back(o[1]), "ghost", "", 36)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			bh.add_child(b)
		v.add_child(bh)
	v.add_child(UI.lbl_fill("%s kit · %s%s" % [G.OPS.KIT_NAMES[WHICH[which]], SHIRT.PATTERNS[int(kt.p)], " · drag to turn" if kv != null else ""], 15, UI.MUTED))
	if sp == null and preview != "":
		v.add_child(UI.caps("Preview: not signed yet", 14, UI.AMBER))


func _design(row: Control, c: Dictionary):
	var pn = pane(0, 5)
	var v = pn[1]
	row.add_child(pn[0])
	var kt = _kit(c)
	v.add_child(UI.caps("%s kit · pattern" % G.OPS.KIT_NAMES[WHICH[which]], 15, UI.accent))
	var g = GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 6)
	g.add_theme_constant_override("v_separation", 6)
	for i in SHIRT.PATTERNS.size():
		var on = i == int(kt.p)
		var p = UI.panel(Color(UI.accent, 0.18) if on else Color(1, 1, 1, 0.04), 10, 8, 4, Color(UI.accent, 0.6) if on else Color(0, 0, 0, 0))
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var ph = UI.hb(8)
		var mini = SHIRT.new()
		mini.custom_minimum_size = Vector2(36, 40)
		mini.setup(Color(str(kt.c1)), Color(str(kt.c2)), i, "", null, UI.CARD)
		ph.add_child(mini)
		ph.add_child(UI.lbl_fill(SHIRT.PATTERNS[i], 18, UI.TEXT if on else UI.MUTED, "semi"))
		p.add_child(ph)
		var idx = i
		UI.tap(p, func():
			_put(c, "p", idx)
			refresh(), true)
		g.add_child(p)
	v.add_child(g)
	for key in ["c1", "c2"]:
		v.add_child(UI.caps("Main colour" if key == "c1" else "Second colour (pattern, shorts)", 15, UI.accent))
		var sw = GridContainer.new()
		sw.columns = 8
		sw.add_theme_constant_override("h_separation", 6)
		sw.add_theme_constant_override("v_separation", 6)
		for hex in SWATCH:
			var on2 = str(kt[key]).to_lower().trim_prefix("#") == hex
			var chip_ = UI.panel(Color(hex), 8, 0, 0, UI.TEXT if on2 else Color(1, 1, 1, 0.2))
			chip_.get_theme_stylebox("panel").set_border_width_all(3 if on2 else 1)
			chip_.custom_minimum_size = Vector2(0, 34)
			chip_.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var k = key
			var hx = hex
			UI.tap(chip_, func():
				_put(c, k, hx)
				refresh()
				UI.main.refresh_nav(), true)
			sw.add_child(chip_)
		v.add_child(sw)
	v.add_child(UI.wrap("Home colours also set the club shield and the stadium seats. Away from home the team changes into whichever kit clashes least with the hosts." if which == 0 else
		("Worn away from home when your home kit clashes with the hosts." if which < 3 else "Your goalkeeper's kit, home and away."), 15, UI.DIM))


func _sponsor(row: Control, c: Dictionary, sp):
	var pn = pane(380, 4)
	var v = pn[1]
	row.add_child(pn[0])
	v.add_child(UI.caps("Shirt front · season %d/%02d" % [G.s.season, (G.s.season + 1) % 100], 15, UI.accent))
	if sp != null:
		var h0 = UI.hb(8)
		h0.add_child(_logo(sp.name, 40))
		h0.add_child(UI.sp())
		var tv = UI.vb(-4)
		var l1 = UI.lbl("%s a week" % G.money(sp.weekly), 19, UI.GREEN, "semi")
		l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		tv.add_child(l1)
		var l2 = UI.lbl("%s a win · %d wins" % [G.money(sp.win), _wins()] if sp.win > 0 else sp.type, 14, UI.MUTED)
		l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		tv.add_child(l2)
		h0.add_child(tv)
		v.add_child(h0)
	else:
		v.add_child(UI.wrap("Tap an offer to see it on the shirt, then sign. It lasts all season.", 15, UI.AMBER))
		for o in G.OPS.sponsor_offers():
			var on = preview == o.name
			var card = UI.panel(Color(UI.accent, 0.14) if on else Color(1, 1, 1, 0.04), 10, 10, 4, Color(UI.accent, 0.6) if on else UI.LINE)
			var h = UI.hb(8)
			h.add_child(_logo(o.name, 26))
			var tv2 = UI.vb(-4)
			tv2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tv2.add_child(UI.lbl_fill("%s a week" % G.money(o.weekly), 17, UI.TEXT, "semi"))
			tv2.add_child(UI.lbl_fill("%s%s" % [o.type, " · %s a win" % G.money(o.win) if o.win > 0 else ""], 14, UI.MUTED))
			h.add_child(tv2)
			var deal = o
			if on:
				var b = UI.chip("SIGN", UI.accent, UI.on_color(UI.accent), 16, 60)
				UI.tap(b, func(): _sign(deal), true)
				h.add_child(b)
			card.add_child(h)
			UI.tap(card, func():
				preview = deal.name
				facing_back = false
				refresh())
			v.add_child(card)
	v.add_child(UI.caps("Other deals", 15, UI.accent))
	for r in G.OPS.SPX:
		var d = G.OPS.spx_now(r[0])
		var card2 = UI.panel(Color(1, 1, 1, 0.045), 10, 10, 5, Color(UI.GREEN, 0.3) if d != null else Color(0, 0, 0, 0))
		var h2 = UI.hb(8)
		var tv3 = UI.vb(-4)
		tv3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv3.add_child(UI.lbl_fill(r[1], 18, UI.TEXT, "semi"))
		tv3.add_child(UI.lbl_fill("%s · until %d" % [d.name, int(d.until) + 1] if d != null else "No deal: tap to see the offers", 14, UI.MUTED if d != null else UI.AMBER))
		h2.add_child(tv3)
		if d != null:
			h2.add_child(UI.lbl("%s / wk" % G.money(d.weekly), 17, UI.GREEN, "disp"))
		else:
			h2.add_child(UI.icon("chevron-right", 18, UI.DIM))
		card2.add_child(h2)
		if d == null:
			var kind = r[0]
			var ttl = r[1]
			UI.tap(card2, func(): _offers(kind, ttl), true)
		v.add_child(card2)
	v.add_child(UI.wrap("A better commercial building brings bigger offers. A stadium-name deal renames the ground until it runs out.", 14, UI.DIM))


func _offers(kind: String, ttl: String):
	UI.sheet("%s: offers" % ttl, func(v):
		for o in G.OPS.spx_offers(kind):
			var card = UI.panel(Color(1, 1, 1, 0.05), 12, 12, 8, UI.LINE)
			var h = UI.hb(10)
			h.add_child(_logo(o.name, 34))
			var tv = UI.vb(-3)
			tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tv.add_child(UI.lbl_fill("%s a week" % G.money(o.weekly), 20, UI.TEXT, "semi"))
			tv.add_child(UI.lbl_fill("%s · %s · runs to summer %d" % [o.name, o.sector, int(o.until) + 1], 15, UI.MUTED))
			h.add_child(tv)
			var deal = o
			h.add_child(UI.btn("Sign", func():
				UI.close_sheet()
				UI.confirm("Sign with %s?" % deal.name, "%s: %s a week until summer %d. It cannot be changed once signed.%s" % [ttl, G.money(deal.weekly), int(deal.until) + 1,
					"\n\nYour ground will carry their name for the length of the deal." if kind == "stadium" else ""], "Sign the deal", func():
					G.OPS.spx_sign(kind, deal)
					UI.sfx("sign", -4.0)
					facing_back = kind == "back"
					refresh()
					UI.main.refresh_nav()), "primary", "", 46))
			card.add_child(h)
			v.add_child(card))


func _sign(deal: Dictionary):
	UI.confirm("Sign with %s?" % deal.name, "%s deal: %s a week%s. It runs for the whole season and cannot be changed once signed." % [deal.type, G.money(deal.weekly), " and %s for every win" % G.money(deal.win) if deal.win > 0 else ""], "Sign the deal", func():
		G.s.user["sponsor"] = deal
		UI.sfx("sign", -4.0)
		UI.toast("%s are your shirt sponsor" % deal.name, UI.GREEN)
		refresh()
		UI.main.refresh_nav())


func _wins() -> int:
	var n = 0
	for f in G.club_fixtures(G.uc().id):
		if f.played and not f.get("fr", false):
			var mine = f.hg if f.h == G.uc().id else f.ag
			var theirs = f.ag if f.h == G.uc().id else f.hg
			if mine > theirs:
				n += 1
	return n


func _logo(nm: String, h: float) -> Control:
	var tex = G.OPS.sponsor_logo(nm)
	if tex == null:
		return UI.lbl(nm.to_upper(), int(h * 0.6), UI.TEXT, "xbold")
	var t = TextureRect.new()
	t.texture = tex
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	t.custom_minimum_size = Vector2(h * 3.6, h)
	t.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t

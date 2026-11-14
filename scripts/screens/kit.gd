extends "res://scripts/screens/screen.gd"
# Kit & Sponsors: the shirt on the left changes as you edit it; kit design in the middle,
# this season's shirt sponsor on the right.

const SHIRT = preload("res://scripts/widgets/shirt.gd")
const SWATCH = ["ffffff", "111111", "d0021b", "8b0000", "f5a623", "f8e71c", "1e8e3e", "0b6e4f", "6cabdd", "1f4fbf", "0a1a5c", "6b2fb3", "ff6fb1", "7a4a1e", "9aa3ad", "e9c46a"]

var preview := ""       # sponsor name being looked at before signing


func build():
	title = "Kit & Sponsors"
	var c = G.uc()
	var sp = G.OPS.sponsor_now()
	subtitle = "%s on the shirt" % sp.name if sp != null else "No shirt sponsor yet"
	var row = panes(12, 20)
	_shirt(row, c, sp)
	_design(row, c)
	_sponsor(row, c, sp)


func _shirt(row: Control, c: Dictionary, sp):
	var pn = pane(300, 6)
	var v = pn[1]
	row.add_child(pn[0])
	v.add_child(UI.caps("Home shirt", 16, UI.accent))
	var sh = SHIRT.new()
	sh.custom_minimum_size = Vector2(0, 330)
	sh.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nm = sp.name if sp != null else preview
	sh.setup(Color(str(c.c1)), Color(str(c.c2)), int(c.get("kitp", 0)), nm, G.OPS.sponsor_logo(nm) if nm != "" else null, UI.CARD)
	v.add_child(sh)
	var h = UI.hb(10)
	h.add_child(UI.badge(c, 44))
	var tv = UI.vb(-3)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(UI.lbl_fill(c.name, 22, UI.TEXT, "disp"))
	tv.add_child(UI.lbl_fill("%s · %s" % [SHIRT.PATTERNS[int(c.get("kitp", 0))], nm if nm != "" else "no sponsor"], 16, UI.MUTED))
	h.add_child(tv)
	v.add_child(h)
	if sp == null and preview != "":
		v.add_child(UI.caps("Preview: not signed yet", 14, UI.AMBER))


func _design(row: Control, c: Dictionary):
	var pn = pane(0, 6)
	var v = pn[1]
	row.add_child(pn[0])
	v.add_child(UI.caps("Pattern", 16, UI.accent))
	var g = GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 6)
	g.add_theme_constant_override("v_separation", 6)
	for i in SHIRT.PATTERNS.size():
		var on = i == int(c.get("kitp", 0))
		var p = UI.panel(Color(UI.accent, 0.18) if on else Color(1, 1, 1, 0.04), 10, 8, 6, Color(UI.accent, 0.6) if on else Color(0, 0, 0, 0))
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var ph = UI.hb(8)
		var mini = SHIRT.new()
		mini.custom_minimum_size = Vector2(40, 44)
		mini.setup(Color(str(c.c1)), Color(str(c.c2)), i, "", null, UI.CARD)
		ph.add_child(mini)
		ph.add_child(UI.lbl_fill(SHIRT.PATTERNS[i], 19, UI.TEXT if on else UI.MUTED, "semi"))
		p.add_child(ph)
		var idx = i
		UI.tap(p, func():
			c["kitp"] = idx
			refresh(), true)
		g.add_child(p)
	v.add_child(g)
	for key in ["c1", "c2"]:
		v.add_child(UI.sp(0, 2))
		v.add_child(UI.caps("Main colour" if key == "c1" else "Second colour", 16, UI.accent))
		var sw = GridContainer.new()
		sw.columns = 8
		sw.add_theme_constant_override("h_separation", 6)
		sw.add_theme_constant_override("v_separation", 6)
		for hex in SWATCH:
			var on2 = str(c[key]).to_lower().trim_prefix("#") == hex
			var chip_ = UI.panel(Color(hex), 8, 0, 0, UI.TEXT if on2 else Color(1, 1, 1, 0.2))
			chip_.get_theme_stylebox("panel").set_border_width_all(3 if on2 else 1)
			chip_.custom_minimum_size = Vector2(0, 36)
			chip_.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var k = key
			var hx = hex
			UI.tap(chip_, func():
				c[k] = hx
				refresh()
				UI.main.refresh_nav(), true)
			sw.add_child(chip_)
		v.add_child(sw)
	v.add_child(UI.wrap("Colours also change the club shield, the team's markers in matches and the stadium seats.", 16, UI.DIM))


func _sponsor(row: Control, c: Dictionary, sp):
	var pn = pane(360, 6)
	var v = pn[1]
	row.add_child(pn[0])
	v.add_child(UI.caps("Shirt sponsor · season %d/%02d" % [G.s.season, (G.s.season + 1) % 100], 16, UI.accent))
	if sp != null:
		var lg = _logo(sp.name, 64)
		v.add_child(lg)
		v.add_child(UI.kv("Company", "%s · %s" % [sp.name, sp.sector], UI.TEXT, 20))
		v.add_child(UI.kv("Deal", sp.type, UI.TEXT, 20))
		v.add_child(UI.kv("Every week", G.money(sp.weekly), UI.GREEN, 20))
		v.add_child(UI.kv("Every win", G.money(sp.win) if sp.win > 0 else "-", UI.GREEN if sp.win > 0 else UI.MUTED, 20))
		v.add_child(UI.kv("Wins so far", str(_wins()), UI.TEXT, 20))
		v.add_child(UI.sp(0, 4))
		v.add_child(UI.wrap("Signed for the season. New offers arrive in your inbox when next season starts; a better commercial building brings bigger ones.", 16, UI.DIM))
		return
	v.add_child(UI.wrap("Pick one. Tap an offer to see it on the shirt, then sign. The deal lasts all season and cannot be changed.", 17, UI.AMBER))
	for o in G.OPS.sponsor_offers():
		var on = preview == o.name
		var card = UI.panel(Color(UI.accent, 0.14) if on else Color(1, 1, 1, 0.04), 12, 12, 8, Color(UI.accent, 0.6) if on else UI.LINE)
		var cv = UI.vb(2)
		var h = UI.hb(8)
		h.add_child(_logo(o.name, 34))
		h.add_child(UI.sp())
		h.add_child(UI.caps(o.type, 14, UI.GOLD))
		cv.add_child(h)
		cv.add_child(UI.lbl_fill("%s · %s" % [o.name, o.sector], 17, UI.MUTED))
		var h2 = UI.hb(8)
		h2.add_child(UI.lbl_fill("%s a week%s" % [G.money(o.weekly), " · %s a win" % G.money(o.win) if o.win > 0 else ""], 19, UI.TEXT, "semi"))
		var deal = o
		if on:
			var b = UI.chip("SIGN", UI.accent, UI.on_color(UI.accent), 18, 70)
			UI.tap(b, func(): _sign(deal), true)
			h2.add_child(b)
		cv.add_child(h2)
		card.add_child(cv)
		UI.tap(card, func():
			preview = deal.name
			refresh())
		v.add_child(card)


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

extends "res://scripts/screens/screen.gd"
# Player profile with attributes, contract, season stats and actions.


const PAGES = ["Profile", "Personal", "Positions", "Contract", "Stats", "Manage"]
const POS_XY = {"GK": [.5, .06], "CB": [.5, .2], "LB": [.14, .26], "RB": [.86, .26], "CDM": [.5, .37], "CM": [.5, .5], "LM": [.12, .52], "RM": [.88, .52],
	"CAM": [.5, .65], "LW": [.15, .78], "RW": [.85, .78], "ST": [.5, .89]}

var page := 0
var sw = null


class PosMap extends Control:
	var p: Dictionary
	var xy: Dictionary

	func _draw():
		var w = size.x
		var h = size.y
		draw_rect(Rect2(0, 0, w, h), Color("1f6b3f"))
		var ln = Color(1, 1, 1, 0.5)
		draw_rect(Rect2(6, 6, w - 12, h - 12), ln, false, 2.0)
		draw_line(Vector2(6, h / 2), Vector2(w - 6, h / 2), ln, 2.0)
		draw_arc(Vector2(w / 2, h / 2), h * 0.09, 0, TAU, 32, ln, 2.0)
		draw_rect(Rect2(w * 0.28, 6, w * 0.44, h * 0.13), ln, false, 2.0)
		draw_rect(Rect2(w * 0.28, h - 6 - h * 0.13, w * 0.44, h * 0.13), ln, false, 2.0)
		for k in xy:
			var f = G.fit(p, k)
			var col = Color("7dff5a") if f >= 0.99 else (Color("c9d94a") if f >= 0.92 else (Color("f1b53a") if f >= 0.84 else Color(1, 1, 1, 0.28)))
			var at = Vector2(xy[k][0] * w, (1.0 - xy[k][1]) * h)
			draw_circle(at, 11 if f >= 0.99 else 9, col)
			if f >= 0.99:
				draw_arc(at, 13, 0, TAU, 24, Color.WHITE, 2.0)


func _input(e: InputEvent):
	# swipe left and right between the profile pages
	if not is_visible_in_tree() or UI.main.sheet_node != null or UI.main.menu_node != null:
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			sw = e.position
		elif sw != null:
			var d = e.position - sw
			sw = null
			if absf(d.x) > 110 and absf(d.x) > absf(d.y) * 2.2:
				page = clampi(page + (1 if d.x < 0 else -1), 0, PAGES.size() - 1)
				refresh()


func _cell(text: String, val: String, col: Color, hi := false) -> Control:
	var r = UI.panel(Color(UI.accent, 0.16) if hi else Color(1, 1, 1, 0.03), 4, 10, 2)
	var h = UI.hb(8)
	h.add_child(UI.lbl_fill(text, 20, UI.TEXT if hi else UI.MUTED))
	var b = UI.panel(Color(col, 0.9), 4, 0, 0)
	b.custom_minimum_size = Vector2(48, 26)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var l = UI.lbl(val, 20, Color("0a0e17"), "xbold")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	b.add_child(l)
	h.add_child(b)
	r.add_child(h)
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return r


func _hrow(cells: Array, col: Color, head := false, hi := false) -> Control:
	var r = UI.panel(Color(UI.accent, 0.14) if hi else Color(1, 1, 1, 0.0 if head else 0.03), 4, 8, 3)
	var h = UI.hb(6)
	var widths = [92, 0, 46, 42, 42, 54]
	for i in cells.size():
		var l = UI.lbl(cells[i], 15 if head else 18, col, "semi" if head else "body")
		if widths[i] == 0:
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			l.clip_text = true
		else:
			l.custom_minimum_size = Vector2(widths[i], 0)
			if i >= 2:
				l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		h.add_child(l)
	r.add_child(h)
	return r


func _info(k: String, v: String, col := UI.TEXT) -> Control:
	var b = UI.vb(-4)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var a = UI.lbl(v, 24, col, "bold")
	a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	a.clip_text = true
	var c = UI.lbl(k, 15, UI.MUTED)
	c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.add_child(a)
	b.add_child(c)
	return b


func _page(p: Dictionary, own: bool, free: bool):
	var s = G.s
	var uc = G.uc()
	var club = s.clubs[p.club] if not free else null
	var known = G.OPS.knows(p) or p.get("loan", -1) == uc.id
	var h = panes(12, 20)
	var roles = []
	for rid in G.RL.BY_POS[p.pos]:
		roles.append([G.RL.suit(p, rid), rid])
	roles.sort_custom(func(x, y): return x[0] > y[0])
	var best_role = G.RL.ROLES[roles[0][1]]
	var status = ["Key player", "Rotation", "Backup", "Prospect"][G.status_of(p)]
	if page == 0:
		var col = UI.vb(8)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(col)
		var top = UI.hb(10)
		var card = UI.panel(Color(UI.ovr_color(p.ovr), 0.16), 12, 14, 8, UI.ovr_color(p.ovr))
		card.custom_minimum_size = Vector2(170, 0)
		var cv = UI.vb(-4)
		cv.alignment = BoxContainer.ALIGNMENT_CENTER
		var big = UI.lbl(str(p.ovr), 62, UI.ovr_color(p.ovr), "xbold")
		big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(big)
		var nm = UI.lbl((p.ln if p.cn == "" else p.cn).to_upper(), 22, UI.TEXT, "xbold")
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.clip_text = true
		cv.add_child(nm)
		var pt = UI.lbl("Potential %s" % (str(p.pot) if known else G.OPS.pot_text(p)), 15, UI.MUTED)
		pt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(pt)
		card.add_child(cv)
		top.add_child(card)
		# facts on the first line, how he is doing right now on the second: nothing to scroll for
		var info = UI.panel(UI.CARD, 12, 12, 6, UI.LINE)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var iv = UI.vb(4)
		iv.alignment = BoxContainer.ALIGNMENT_CENTER
		var r1 = UI.hb(6)
		r1.add_child(_info("%d/%d/%d" % [p.bd, p.bm, p.by], "%d yrs" % G.age(p)))
		r1.add_child(_info("Value", G.money(G.value(p))))
		r1.add_child(_info("Wage a week", G.money(p.wage)))
		r1.add_child(_info("Contract to", "—" if free else "June %d" % p.cend, UI.AMBER if (not free and p.cend <= s.season + 1) else UI.TEXT))
		var nb = UI.vb(-4)
		nb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var fl = UI.hb(0)
		fl.alignment = BoxContainer.ALIGNMENT_CENTER
		fl.add_child(UI.flag(p.nat, 30))
		nb.add_child(fl)
		var nl = UI.lbl(p.nat, 15, UI.MUTED)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.clip_text = true
		nb.add_child(nl)
		r1.add_child(nb)
		iv.add_child(r1)
		iv.add_child(UI.divider())
		var played = p.ss.ap > 0
		var r2 = UI.hb(6)
		r2.add_child(_info("Condition", "%d%%" % int(p.cond), UI.cond_color(p.cond)))
		r2.add_child(_info("Morale", str(int(p.mor)), UI.cond_color(p.mor + 10)))
		r2.add_child(_info("Form", "%.1f" % p.form if played else "-", (UI.GREEN if p.form >= 7.0 else UI.TEXT) if played else UI.DIM))
		r2.add_child(_info("Av. rating", "%.2f" % G.avg_rating(p) if played else "-", UI.TEXT if played else UI.DIM))
		r2.add_child(_info("Apps · goals", "%d · %d" % [p.ss.ap, p.ss.g]))
		iv.add_child(r2)
		info.add_child(iv)
		top.add_child(info)
		var pm = PosMap.new()
		pm.p = p
		pm.xy = POS_XY
		pm.custom_minimum_size = Vector2(124, 146)
		pm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top.add_child(pm)
		col.add_child(top)
		var strip = UI.hb(8)
		strip.add_child(UI.lbl(best_role.n, 21, UI.TEXT, "bold"))
		strip.add_child(UI.chip(status.to_upper(), Color(UI.GREEN, 0.14), UI.GREEN, 14))
		if p.inj > 0:
			strip.add_child(UI.chip("INJURED · %s" % G.inj_text(p.inj).to_upper(), Color(UI.RED, 0.16), UI.RED, 14))
		elif p.susp > 0:
			strip.add_child(UI.chip("SUSPENDED", Color(UI.RED, 0.16), UI.RED, 14))
		strip.add_child(UI.sp())
		strip.add_child(UI.lbl("%s%s · %s foot · %d★ skills · %d★ weak foot" % [p.pos, (" / " + " / ".join(p.alt)) if p.alt.size() > 0 else "", "Left" if p.foot == "L" else "Right", p.sm, p.wf], 16, UI.MUTED))
		col.add_child(strip)
		# every attribute on screen at once: three columns that share whatever height is left
		var grid = UI.hb(8)
		grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var keys = best_role.k
		for ci in 3:
			var gv = UI.vb(3)
			gv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if p.pos == "GK":
				for i in range(ci * 2, ci * 2 + 2):
					gv.add_child(_cell(G.GK_STAT_NAMES[i], str(p.st[i]), UI.ovr_color(p.st[i])))
			else:
				for i in range(ci * 6, ci * 6 + 6):
					var cell = _cell(G.RL.ATTR[i], str(p.at[i]), UI.ovr_color(p.at[i]), i in keys)
					cell.size_flags_vertical = Control.SIZE_EXPAND_FILL
					gv.add_child(cell)
			grid.add_child(gv)
		col.add_child(grid)
	elif page == 1:
		var a = pane(0, 8)
		h.add_child(a[0])
		var v = a[1]
		v.add_child(UI.kv("Date of birth", "%d/%d/%d (%d)" % [p.bd, p.bm, p.by, G.age(p)]))
		v.add_child(UI.kv("Nationality", p.nat))
		v.add_child(UI.kv("Preferred foot", "Left" if p.foot == "L" else "Right"))
		v.add_child(UI.kv("Skill moves · weak foot", "%d★ · %d★" % [p.sm, p.wf]))
		v.add_child(UI.kv("Squad status", status))
		v.add_child(UI.kv("Career", "%d apps · %d goals" % G.PS.career(p)))
		v.add_child(UI.kv("Shirt number", str(p.get("num", "-"))))
		var cp = G.PS.caps(p)
		v.add_child(UI.kv("International", "%d caps · %d goals" % [cp[0], cp[1]] if cp[0] > 0 else "Uncapped"))
		v.add_child(UI.kv("Languages", ", ".join(G.PS.languages(p))))
		v.add_child(UI.kv("Favoured club", G.PS.favoured_name(p)))
		if p.get("sellon", []).size() == 2:
			v.add_child(UI.kv("Sell-on clause", "%d%% to %s" % [p.sellon[1], s.clubs[int(p.sellon[0])].short], UI.AMBER))
		var b = pane(0, 8)
		h.add_child(b[0])
		v = b[1]
		var unhappy = p.get("unhappy", 0) > 0
		var mood = "Wants to leave" if unhappy else ("Happy at the club" if p.mor >= 62 else ("Fairly content" if p.mor >= 42 else "Unsettled"))
		var mc = UI.RED if unhappy or p.mor < 42 else (UI.GREEN if p.mor >= 62 else UI.AMBER)
		var banner = UI.panel(Color(mc, 0.85), 8, 14, 8)
		var bl = UI.lbl(mood, 24, Color("0a0e17"), "xbold")
		bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		banner.add_child(bl)
		v.add_child(banner)
		var lines = []
		lines.append([p.ss.ap >= 3 or G.status_of(p) >= 2, "Getting the games his status calls for" if (p.ss.ap >= 3 or G.status_of(p) >= 2) else "Wants more time on the pitch"])
		lines.append([p.cend > s.season + 1, "Settled on a long contract" if p.cend > s.season + 1 else "His contract is running down"])
		lines.append([p.form >= 6.8 or p.ss.ap == 0, "Playing well" if p.form >= 6.8 else ("Yet to play this season" if p.ss.ap == 0 else "Out of form")])
		if p.listed:
			lines.append([false, "Knows he is on the transfer list"])
		if p.inj > 0:
			lines.append([false, "Injured for around %s" % G.inj_text(p.inj)])
		if p.has("rolep") and own:
			lines.append([p.get("rolew", -1) != s.season, "Promised a %s role when he signed" % G.DL.ROLES[p.rolep].to_lower()])
		if not G.PS.speaks_local(p, p.club) and p.club >= 0:
			lines.append([false, "Still learning the language"])
		var pc = UI.panel(Color(1, 1, 1, 0.04), 8, 12, 8)
		var pcv = UI.vb(0)
		pcv.add_child(UI.caps("Personality", 14, UI.accent))
		pcv.add_child(UI.lbl(G.PS.personality(p), 22, UI.TEXT, "bold"))
		pcv.add_child(UI.wrap(G.PS.blurb(p), 17, UI.MUTED))
		pc.add_child(pcv)
		v.add_child(pc)
		for ln in lines:
			var r = UI.hb(10)
			r.add_child(UI.icon("check" if ln[0] else "x", 22, UI.GREEN if ln[0] else UI.AMBER))
			r.add_child(UI.lbl_fill(ln[1], 20, UI.GREEN if ln[0] else UI.TEXT))
			v.add_child(r)
	elif page == 2:
		var a = pane(0, 6)
		h.add_child(a[0])
		var v = a[1]
		v.add_child(UI.caps("Position", 17, UI.accent))
		v.add_child(UI.lbl("%s · natural" % p.pos, 24, UI.TEXT, "bold"))
		if p.alt.size() > 0:
			v.add_child(UI.lbl("Also plays: %s" % ", ".join(p.alt), 19, UI.MUTED))
		v.add_child(UI.caps("Roles", 17, UI.accent))
		for r in roles:
			var rd = G.RL.ROLES[r[1]]
			var rh = UI.hb(10)
			rh.add_child(UI.lbl_fill(rd.n, 21, UI.TEXT, "semi"))
			rh.add_child(UI.stars(40 + G.RL.stars(p, r[1]) * 12, 15))
			v.add_child(rh)
			v.add_child(UI.lbl_fill(rd.d, 15, UI.MUTED))
		var pm = PosMap.new()
		pm.p = p
		pm.xy = POS_XY
		pm.custom_minimum_size = Vector2(330, 0)
		pm.size_flags_vertical = Control.SIZE_EXPAND_FILL
		pm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(pm)
	elif page == 3:
		var paper = UI.panel(Color("e2ddcf"), 6, 22, 16, Color("b9b29f"))
		paper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		paper.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var ink = Color("4a4020")
		var pv = UI.vb(10)
		var g = GridContainer.new()
		g.columns = 2
		g.add_theme_constant_override("h_separation", 30)
		g.add_theme_constant_override("v_separation", 10)
		for it in [["Club", club.name if club != null else "None"], ["Role", status], ["Wage (p/w)", G.money(p.wage)], ["Contract expiry", "—" if free else "30/6/%d" % p.cend],
				["Release clause", G.money(p.rc) if p.get("rc", 0) > 0 else "None"], ["Loan", ("From %s" % s.clubs[p.loan].name) if p.get("loan", -1) >= 0 else "None"]]:
			var b = UI.vb(-2)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.add_child(UI.lbl(it[0], 16, Color("8a8470")))
			b.add_child(UI.lbl(str(it[1]), 24, ink, "bold"))
			g.add_child(b)
		pv.add_child(g)
		paper.add_child(pv)
		h.add_child(paper)
		var a = pane(0, 8)
		h.add_child(a[0])
		var v = a[1]
		v.add_child(UI.kv("Value", G.money(G.value(p))))
		v.add_child(UI.kv("Transfer status", "Listed for sale" if p.listed else ("Not for sale" if (club != null and not own and G.TR.squad_rank(p) < 3) else "Open to offers")))
		if not own and not free:
			v.add_child(UI.kv("Asking price", "around %s" % G.money(G.TR.asking_price(p))))
		v.add_child(UI.kv("Wants (if he moved)", "%s / wk" % G.money(G.wage_for(p.ovr, G.age(p)))))
		var offers = 0
		for o in s.offers:
			if o.pid == p.id:
				offers += 1
		v.add_child(UI.kv("Transfer offers", str(offers) if offers > 0 else "None"))
		v.add_child(UI.kv("Years left", str(max(0, p.cend - s.season - 1)) if not free else "-"))
	else:
		var a = pane(0, 8)
		h.add_child(a[0])
		var v = a[1]
		v.add_child(UI.caps("Season %s" % G.season_name(), 17, UI.accent))
		for it in [["Appearances", p.ss.ap], ["Goals", p.ss.g], ["Assists", p.ss.a], ["Man of the match", p.ss.mom], ["Clean sheets", p.ss.cs], ["Yellow cards", p.ss.yc], ["Red cards", p.ss.rc]]:
			v.add_child(UI.kv(it[0], str(it[1])))
		v.add_child(UI.kv("Average rating", "%.2f" % G.avg_rating(p) if p.ss.ap > 0 else "-"))
		var b = pane(0, 8)
		h.add_child(b[0])
		v = b[1]
		v.add_child(UI.caps("Career", 17, UI.accent))
		var car = G.PS.career(p)
		v.add_child(UI.kv("Appearances", str(car[0])))
		v.add_child(UI.kv("Goals", str(car[1])))
		v.add_child(UI.kv("Goals per game", "%.2f" % (car[1] / float(max(1, car[0])))))
		v.add_child(UI.caps("Match eligibility", 17, UI.accent))
		v.add_child(UI.kv("Selection", "Available" if G.available(p) else "Unavailable", UI.GREEN if G.available(p) else UI.RED))
		v.add_child(UI.kv("Injuries", "Out for %s" % G.inj_text(p.inj) if p.inj > 0 else "None"))
		v.add_child(UI.kv("Suspensions", "%d match%s" % [p.susp, "" if p.susp == 1 else "es"] if p.susp > 0 else "None"))
		v.add_child(UI.kv("Fitness", "%d%%" % int(p.cond), UI.cond_color(p.cond)))
		var cc = pane(0, 2)
		cc[0].size_flags_stretch_ratio = 1.5
		h.add_child(cc[0])
		v = cc[1]
		v.add_child(UI.caps("Season by season", 17, UI.accent))
		v.add_child(_hrow(["Season", "Club", "Apps", "Gls", "Ast", "Avg"], UI.MUTED, true))
		var hist = G.PS.history(p)
		var cn = "—" if free else club.short
		v.add_child(_hrow([G.season_name(), cn, str(p.ss.ap), str(p.ss.g), str(p.ss.a), "%.2f" % G.avg_rating(p) if p.ss.ap > 0 else "-"], UI.TEXT, false, true))
		for i in range(hist.size() - 1, -1, -1):
			var r = hist[i]
			v.add_child(_hrow([G.season_name(r[0]), str(r[1]), str(r[2]), str(r[3]), str(r[4]), "%.2f" % r[5]], UI.TEXT))
		if p.has("pre") and p.pre[0] > 0:
			v.add_child(_hrow(["Earlier", "Career to 2026", str(p.pre[0]), str(p.pre[1]), "", ""], UI.MUTED))
		var cp2 = G.PS.caps(p)
		if cp2[0] > 0:
			v.add_child(_hrow(["Intl", p.nat, str(cp2[0]), str(cp2[1]), "", ""], UI.accent))


func build():
	var s = G.s
	if not s.players.has(args.pid):
		body.add_child(UI.topbar("Player"))
		return
	var p = s.players[args.pid]
	var uc = G.uc()
	var own = p.club == uc.id
	var free = p.club < 0
	var short = p.id in s.shortlist
	var star = UI.panel(Color(1, 1, 1, 0.06), 18, 14, 14)
	star.add_child(UI.icon("star-f" if short else "star", 30, UI.GOLD if short else UI.MUTED))
	UI.tap(star, func():
		if short:
			s.shortlist.erase(p.id)
		else:
			s.shortlist.append(p.id)
		refresh(), true)
	body.add_child(UI.topbar(G.pname(p), true, null if own else star))
	body.add_child(UI.margin(UI.seg(PAGES, page, func(i):
		page = i
		refresh(), 17), 20, 0, 20, 6))
	if page < 5:
		_page(p, own, free)
		_bar(p)
		return
	var v = content(14)
	# actions
	v.add_child(UI.sp(0, 4))
	var loaned_in = own and p.get("loan", -1) >= 0
	var loaned_out = (not own) and p.get("loan", -1) == uc.id
	if loaned_in:
		v.add_child(_note("clock", "On loan from %s until the end of the season." % s.clubs[p.loan].name, UI.BLUE))
	if loaned_out:
		v.add_child(_note("clock", "Your player — on loan at %s until the end of the season." % s.clubs[p.club].name, UI.BLUE))
	if own and not loaned_in:
		if p.get("youth", false):
			v.add_child(UI.btn("Promote to first team", func():
				p.erase("youth")
				UI.toast("%s joins the first-team squad" % G.pname(p), UI.GREEN)
				refresh(), "gold", "arrow-up"))
		v.add_child(UI.section("Squad status", "how he reacts to being left out"))
		v.add_child(UI.seg(["Key", "Rotation", "Backup", "Prospect"], G.status_of(p), func(i):
			p["status"] = i
			refresh(), 20))
		var tf = p.get("tr", "")
		var rt = p.get("rt", null)
		var th = UI.hb(10)
		var tb = UI.btn("Training: %s" % (tf if tf != "" else "general"), func(): _indiv(p), "secondary", "activity", 68)
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		th.add_child(tb)
		var rb0 = UI.btn("Learning %s" % rt[0] if rt != null else "New position", func(): _retrain(p), "secondary", "repeat", 68)
		rb0.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		th.add_child(rb0)
		v.add_child(th)
	v.add_child(UI.btn("Compare with…", func(): _compare(p), "secondary", "users", 68))
	v.add_child(UI.btn("Find similar players", func(): UI.main.open("lists", {"kind": "similar", "pid": p.id, "grp": "search"}), "secondary", "search", 56))
	if G.settings.get("editor", false):
		var eh = UI.hb(8)
		for d in [-1, 1]:
			var eb = UI.btn("Rating %+d" % d, func():
				G.change_ovr(p, d)
				p.pot = max(p.pot, p.ovr)
				refresh(), "ghost", "pencil", 52)
			eb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			eh.add_child(eb)
		v.add_child(eh)
	if own and not loaned_in:
		v.add_child(UI.btn("Offer new contract", func(): UI.main.open("nego", {"pid": p.id, "mode": "renew"}), "primary", "handshake"))
		var hb2 = UI.hb(10)
		var lb = UI.btn("Unlist" if p.listed else "Transfer list", func():
			p.listed = not p.listed
			UI.toast("%s %s the transfer list" % [G.pname(p), "added to" if p.listed else "removed from"])
			refresh(), "secondary", "flag", 72)
		lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb2.add_child(lb)
		var lo = UI.btn("Loan out", func(): _loan_out(p), "secondary", "arrow-left-right", 72)
		lo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb2.add_child(lo)
		var rb = UI.btn("Release", func(): _release(p), "danger", "log-out", 72)
		rb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb2.add_child(rb)
		v.add_child(hb2)
	elif free:
		_scout_btn(v, p)
		v.add_child(UI.btn("Offer contract", func(): UI.main.open("nego", {"pid": p.id, "mode": "free"}), "primary", "handshake"))
	elif not own and not loaned_out:
		_scout_btn(v, p)
		v.add_child(UI.btn("Approach %s" % s.clubs[p.club].short, func(): UI.main.open("nego", {"pid": p.id, "mode": "buy"}), "primary", "handshake"))
		if G.window_open():
			var ap = UI.caps("Asking price around %s%s" % [G.money(G.TR.asking_price(p)), (" · release clause %s" % G.money(p.rc)) if p.get("rc", 0) > 0 else ""], 19, UI.MUTED)
			ap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			v.add_child(ap)
			v.add_child(UI.btn("Ask for a season loan", func():
				var r = G.OPS.can_loan_in(p)
				if not r.ok:
					UI.toast(r.why, UI.RED)
					return
				G.OPS.loan_in(p)
				UI.toast("%s joins on loan" % G.pname(p), UI.GREEN)
				refresh(), "secondary", "arrow-left-right", 68))
		else:
			v.add_child(_note("clock", "The transfer window is closed. You can approach %s when it reopens." % G.pname(p), UI.MUTED))


	_bar(p)


func _bar(p: Dictionary):
	var s = G.s
	var own = p.club == G.uc().id
	var free = p.club < 0
	var short = p.id in s.shortlist
	# fixed action bar: the main things you can do with this player, always in reach
	var bar = UI.hb(8)
	var acts: Array = []
	if own:
		acts.append(["New contract", "handshake", "primary", func(): UI.main.open("nego", {"pid": p.id, "mode": "renew"})])
	elif free:
		acts.append(["Offer contract", "handshake", "primary", func(): UI.main.open("nego", {"pid": p.id, "mode": "free"})])
	else:
		var dl = G.DL.find(p.id)
		var lab = "Approach club"
		if dl != null and dl.mode == "buy" and dl.stage != "dead" and dl.stage != "done":
			lab = {"new": "Approach club", "enq_wait": "Awaiting reply", "bid_wait": "Bid pending", "club": "Make bid", "talks": "Agree terms"}[dl.stage]
		acts.append([lab, "handshake", "primary", func(): UI.main.open("nego", {"pid": p.id, "mode": "buy"})])
	acts.append(["Compare", "users", "secondary", func(): _compare(p)])
	acts.append(["Similar", "search", "secondary", func(): UI.main.open("lists", {"kind": "similar", "pid": p.id, "grp": "search"})])
	if not own:
		acts.append(["Shortlisted" if short else "Shortlist", "star", "secondary", func():
			if p.id in s.shortlist:
				s.shortlist.erase(p.id)
			else:
				s.shortlist.append(p.id)
			refresh()])
	for a in acts:
		var b = UI.btn(a[0], a[3], a[2], a[1], 50)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.add_child(b)
	body.add_child(UI.margin(bar, 20, 2, 20, 8))
	if UI.main.uses_chrome():
		UI.main.t_sub = "%s · %s · %d yrs · %s" % [s.clubs[p.club].name if p.club >= 0 else "Free agent", p.pos, G.age(p), p.nat]
		UI.main.refresh_nav.call_deferred()


func _scout_btn(v: Control, p: Dictionary):
	if G.OPS.knows(p):
		return
	var watching = false
	for q in G.s.scout.queue:
		if q.pid == p.id:
			watching = true
			v.add_child(_note("search", "Your scouts are watching him — report in %d day%s." % [max(1, q.done - G.s.day), "" if q.done - G.s.day == 1 else "s"], UI.accent))
	if not watching:
		v.add_child(UI.btn("Scout player (%d days)" % G.OPS.scout_days(), func():
			var err = G.OPS.scout_player(p)
			if err != "":
				UI.toast(err, UI.RED)
			refresh(), "secondary", "search", 68))


func _loan_out(p: Dictionary):
	UI.confirm("Loan out %s?" % G.pname(p), "Your staff will find him a club where he should play regularly. He returns at the end of the season.", "Send on loan", func():
		var err = G.OPS.loan_out(p)
		if err != "":
			UI.toast(err, UI.RED)
		else:
			UI.main.back())


func _indiv(p: Dictionary):
	var build_sheet = func(v):
		v.add_child(UI.wrap("Extra work on one area each month. It does not raise his overall directly, but sharpens the attributes his role relies on.", 21, UI.MUTED))
		for k in [""] + G.OPS.INDIV.keys():
			var on = p.get("tr", "") == k
			var r = UI.panel(Color(UI.accent, 0.14) if on else UI.CARD, 16, 18, 12, UI.accent if on else UI.LINE)
			var h = UI.hb(10)
			h.add_child(UI.lbl(k if k != "" else "General training", 26, UI.TEXT, "disp"))
			h.add_child(UI.sp())
			if k != "":
				var names = []
				for a in G.OPS.INDIV[k]:
					names.append(G.RL.ATTR[a])
				h.add_child(UI.caps(", ".join(names), 16, UI.DIM))
			r.add_child(h)
			var key = k
			UI.tap(r, func():
				if key == "":
					p.erase("tr")
				else:
					p["tr"] = key
				UI.close_sheet()
				refresh())
			v.add_child(r)
	UI.sheet("Individual training", build_sheet)


func _retrain(p: Dictionary):
	if p.pos == "GK":
		UI.toast("Goalkeepers cannot retrain", UI.RED)
		return
	var build_sheet = func(v):
		v.add_child(UI.wrap("He will learn the position over about three months and can then play there without a penalty.", 21, UI.MUTED))
		for pos in ["CB", "LB", "RB", "CDM", "CM", "CAM", "LM", "RM", "LW", "RW", "ST"]:
			if pos == p.pos or pos in p.alt:
				continue
			var r = UI.panel(UI.CARD, 16, 18, 10, UI.LINE)
			var h = UI.hb(12)
			h.add_child(UI.pos(pos))
			h.add_child(UI.lbl_fill("Current fit %d%%" % int(G.fit(p, pos) * 100), 23, UI.MUTED))
			h.add_child(UI.caps("Best as %s" % G.RL.ROLES[G.RL.best(p, pos)].n, 17, UI.DIM))
			r.add_child(h)
			var np = pos
			UI.tap(r, func():
				G.OPS.start_retrain(p, np)
				UI.close_sheet()
				UI.toast("%s starts learning %s" % [G.pname(p), np], UI.GREEN)
				refresh())
			v.add_child(r)
	UI.sheet("Retrain position", build_sheet)


func _compare(p: Dictionary):
	var build_sheet = func(v):
		var pool = []
		for pid in G.uc().players + G.s.shortlist:
			if pid != p.id and G.s.players.has(pid):
				pool.append(G.s.players[pid])
		pool.sort_custom(func(a, b): return (0 if G.LINE[a.pos] == G.LINE[p.pos] else 1) * 1000 - a.ovr < (0 if G.LINE[b.pos] == G.LINE[p.pos] else 1) * 1000 - b.ovr)
		v.add_child(UI.caps("Your squad and shortlist", 19, UI.DIM))
		for q in pool:
			var qid = q.id
			v.add_child(UI.player_row(q, func():
				UI.close_sheet()
				UI.main.open("compare", {"a": p.id, "b": qid})))
	UI.sheet("Compare %s with" % G.pname(p), build_sheet)


func _note(icon_name: String, text: String, color: Color) -> Control:
	var p = UI.panel(Color(color, 0.1), 18, 18, 14, Color(color, 0.3))
	var h = UI.hb(12)
	h.add_child(UI.icon(icon_name, 26, color))
	h.add_child(UI.wrap(text, 22, color))
	p.add_child(h)
	return p


func _release(p: Dictionary):
	if G.uc().players.size() <= 18:
		UI.toast("You need at least 18 players", UI.RED)
		return
	UI.confirm("Release %s?" % G.pname(p), "His contract will be terminated and he will become a free agent. This cannot be undone.", "Release player", func():
		G.LG.release(p)
		G.fix_lineup()
		G.news("%s release %s." % [G.uc().name, G.pfull(p)])
		UI.main.back(), true)

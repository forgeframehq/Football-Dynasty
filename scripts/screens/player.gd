extends "res://scripts/screens/screen.gd"
# Player profile with attributes, contract, season stats and actions.


const PAGES = ["Profile", "Personal", "Roles & Skills", "Contract", "Stats", "Manage"]
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
		var av = G.TC.arrow(p)
		r2.add_child(_info(G.TC.arrow_text(av) if av != 0 else "Form", "%.1f" % p.form if played else "-", G.TC.arrow_col(av) if av != 0 else ((UI.GREEN if p.form >= 7.0 else UI.TEXT) if played else UI.DIM)))
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
		var sks = G.TC.skill_names(p)
		if sks.size() > 0 or own:
			var sr = UI.hb(5)
			sr.add_child(UI.caps("Skills", 13, UI.DIM))
			for nm2 in sks:
				sr.add_child(UI.chip(nm2, Color(UI.accent, 0.14), UI.TEXT, 13))
			if sks.is_empty():
				sr.add_child(UI.lbl("None yet", 14, UI.DIM))
			if p.get("lsk", null) != null:
				sr.add_child(UI.chip("LEARNING %s · %d WK" % [G.TC.SKILLS[p.lsk[0]].n.to_upper(), int(p.lsk[1])], Color(UI.AMBER, 0.14), UI.AMBER, 12))
			sr.add_child(UI.sp())
			if own:
				var fam = int(p.get("fam", 50))
				sr.add_child(UI.caps("Knows your style %d%%" % fam, 13, UI.cond_color(fam + 10)))
			col.add_child(sr)
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
		var ir = G.TC.inj_res(p)
		v.add_child(UI.kv("Injury resistance", ["Fragile", "Normal", "Robust"][ir - 1] if known else "Unknown until scouted", [UI.RED, UI.TEXT, UI.GREEN][ir - 1] if known else UI.DIM))
		v.add_child(UI.kv("Form type", "Streaky" if G.TC.form_type(p) == 1 else "Steady"))
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
			if G.TC.role_fits(r[1], G.TC.style_of(uc)):
				rh.add_child(UI.chip("FITS YOUR STYLE", Color(UI.GREEN, 0.14), UI.GREEN, 12))
			rh.add_child(UI.stars(40 + G.RL.stars(p, r[1]) * 12, 15))
			v.add_child(rh)
			v.add_child(UI.lbl_fill(rd.d, 15, UI.MUTED))
		var b = pane(0, 4)
		h.add_child(b[0])
		v = b[1]
		v.add_child(UI.caps("Skills · %d of %d" % [p.get("sk", []).size(), G.TC.MAX_SKILLS], 17, UI.accent))
		for id in p.get("sk", []):
			if G.TC.SKILLS.has(id):
				v.add_child(UI.lbl(G.TC.SKILLS[id].n, 20, UI.TEXT, "semi"))
				v.add_child(UI.wrap(G.TC.SKILLS[id].d, 15, UI.MUTED))
		if p.get("sk", []).is_empty():
			v.add_child(UI.lbl("No special skills.", 17, UI.DIM))
		if own:
			var l = p.get("lsk", null)
			if l != null:
				v.add_child(UI.kv("Learning", "%s · %d weeks" % [G.TC.SKILLS[l[0]].n, int(l[1])], UI.AMBER, 17))
			elif G.TC.learnable(p).size() > 0:
				v.add_child(UI.btn("Teach him a skill", func(): _learn(p), "secondary", "graduation-cap", 44))
			var fam = int(p.get("fam", 50))
			v.add_child(UI.divider())
			v.add_child(UI.kv("Knows your playstyle", "%d%%" % fam, UI.cond_color(fam + 10), 17))
			if fam < 100:
				v.add_child(UI.lbl_fill("About %d more matches to settle fully." % G.TC.settle_matches(p), 14, UI.DIM))
		else:
			v.add_child(UI.divider())
			v.add_child(UI.wrap(G.TC.fit_text(p), 16, UI.MUTED))
		var mine = []
		for lid in s.user.links:
			if G.TC.LINKS.has(lid):
				for sl in [G.TC.LINKS[lid].a, G.TC.LINKS[lid].b]:
					var can = p.pos in sl.pos
					for ap in p.alt:
						can = can or ap in sl.pos
					if can and G.TC.fits_slot(sl, p):
						mine.append("%s (%s)" % [G.TC.LINKS[lid].n, sl.t.to_lower()])
		if mine.size() > 0:
			v.add_child(UI.wrap("Fits your link-up: " + ", ".join(mine), 16, UI.GREEN))
		var pm = PosMap.new()
		pm.p = p
		pm.xy = POS_XY
		pm.custom_minimum_size = Vector2(250, 0)
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
		if p.has("bon"):
			var bits = []
			if int(p.bon.ab) > 0: bits.append("%s an appearance" % G.money(int(p.bon.ab)))
			if int(p.bon.gb) > 0: bits.append("%s a goal" % G.money(int(p.bon.gb)))
			if int(p.bon.cs) > 0: bits.append("%s a clean sheet" % G.money(int(p.bon.cs)))
			v.add_child(UI.kv("Bonuses", ", ".join(bits), UI.TEXT, 18))
			v.add_child(UI.kv("Bonuses paid this spell", G.money(int(p.get("bonp", 0))), UI.TEXT, 18))
		if p.has("bb"):
			v.add_child(UI.kv("Buy-back clause", "%s for %s" % [s.clubs[int(p.bb.club)].short, G.money(int(p.bb.fee))], UI.AMBER, 18))
		if int(p.get("mr", -1)) >= 0:
			v.add_child(UI.kv("Matching right", s.clubs[int(p.mr)].short, UI.AMBER, 18))
		if p.has("prec"):
			v.add_child(UI.kv("Pre-contract", "Joins %s in June" % s.clubs[int(p.prec.club)].short, UI.RED if own else UI.GREEN, 18))
		if p.has("lterms") and own:
			v.add_child(UI.kv("Loan terms", "%s%s" % [G.MK.OPT_TXT[int(p.lterms.opt)], (" at %s" % G.money(int(p.lterms.fee))) if int(p.lterms.opt) > 0 else ""], UI.TEXT, 18))
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
		if p.has("prec") and p.prec[0] > 0:
			v.add_child(_hrow(["Earlier", "Career to 2026", str(p.prec[0]), str(p.prec[1]), "", ""], UI.MUTED))
		var cp2 = G.PS.caps(p)
		if cp2[0] > 0:
			v.add_child(_hrow(["Intl", p.nat, str(cp2[0]), str(cp2[1]), "", ""], UI.accent))


func build():
	var s = G.s
	if not s.players.has(args.pid):
		body.add_child(UI.topbar("Player"))
		return
	var p = s.players[args.pid]
	if args.has("page"):
		page = int(args.page)
		args.erase("page")
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
	_manage(p, own, free)
	if UI.main.uses_chrome():
		UI.main.t_sub = "%s · %s · %d yrs · %s" % [s.clubs[p.club].name if p.club >= 0 else "Free agent", p.pos, G.age(p), p.nat]
		UI.main.refresh_nav.call_deferred()


func _act(v: Control, text: String, sub: String, ic: String, cb: Callable, col := Color(0, 0, 0, 0), on := true):
	# one action row: icon, name, what it does. Greyed when it cannot be used now.
	var hot = col.a > 0
	var r = UI.panel(Color(col, 0.16) if hot else Color(1, 1, 1, 0.045), 10, 12, 6, Color(col, 0.5) if hot else Color(0, 0, 0, 0))
	var h = UI.hb(10)
	h.add_child(UI.icon(ic, 22, (col.lightened(0.25) if hot else UI.accent) if on else UI.DIM))
	var tv = UI.vb(-4)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(UI.lbl_fill(text, 19, UI.TEXT if on else UI.DIM, "semi"))
	if sub != "":
		tv.add_child(UI.lbl_fill(sub, 14, UI.MUTED if on else UI.DIM))
	h.add_child(tv)
	if on:
		h.add_child(UI.icon("chevron-right", 16, UI.DIM))
	r.add_child(h)
	if on:
		UI.tap(r, cb, true)
	v.add_child(r)


func _manage(p: Dictionary, own: bool, free: bool):
	# three panes, nothing repeated: his place in the squad and talks, his development, his future
	var s = G.s
	var uc = G.uc()
	var h = panes(10, 20)
	var loaned_in = own and p.get("loan", -1) >= 0
	var loaned_out = (not own) and p.get("loan", -1) == uc.id
	var a = pane(0, 5)
	h.add_child(a[0])
	var v = a[1]
	var b = pane(0, 5)
	h.add_child(b[0])
	var w = b[1]
	var d = pane(0, 5)
	h.add_child(d[0])
	var x = d[1]
	if own:
		# ---- pane 1: squad place and conversations
		v.add_child(UI.caps("Place in the squad", 15, UI.accent))
		if not loaned_in:
			v.add_child(UI.seg(["Key", "Rotation", "Backup", "Prospect"], G.status_of(p), func(i):
				p["status"] = i
				refresh(), 16, 6))
		var better = 0
		var same = 0
		for pid in uc.players:
			var q = s.players[pid]
			if q.pos == p.pos:
				same += 1
				if q.ovr > p.ovr:
					better += 1
		var played = 0
		for pid in uc.players:
			played = max(played, int(s.players[pid].ss.ap))
		v.add_child(UI.kv("Depth at %s" % p.pos, "%s of %d" % [G.LG.ordinal(better + 1), same], UI.TEXT, 18))
		v.add_child(UI.kv("Games this season", "%d of %d" % [int(p.ss.ap), played], UI.TEXT, 18))
		v.add_child(UI.kv("Morale", "%d%%" % int(p.mor), UI.cond_color(p.mor), 18))
		v.add_child(UI.kv("Mood", "Unhappy" if p.get("unhappy", 0) > 0 else ("Promised more games" if p.has("pg") else "Settled"), UI.RED if p.get("unhappy", 0) > 0 else UI.TEXT, 18))
		v.add_child(UI.caps("Talk to him", 15, UI.accent))
		var wait = int(p.get("talk", -99)) + 14 - s.day
		if wait > 0:
			v.add_child(UI.wrap("You spoke %d day%s ago. Give it %d more before another word." % [14 - wait, "" if 14 - wait == 1 else "s", wait], 15, UI.MUTED))
		for t in G.OPS.TALKS:
			var tk = t
			_act(v, t.n, t.d, t.i, func(): _talk(p, tk), Color(0, 0, 0, 0), wait <= 0 and G.OPS.talk_ok(p, t.k))
		# ---- pane 2: development
		w.add_child(UI.caps("Development", 15, UI.accent))
		var tf = p.get("tr", "")
		_act(w, "Individual training", "Now: %s" % (tf if tf != "" else "general"), "activity", func(): _indiv(p))
		var rt = p.get("rt", null)
		_act(w, "New position", "Learning %s" % rt[0] if rt != null else "Plays %s%s" % [p.pos, (", " + ", ".join(p.alt)) if p.alt.size() > 0 else ""], "repeat", func(): _retrain(p))
		var lr = p.get("lsk", null)
		_act(w, "Learn a skill", "Working on one now" if lr != null else "%d of %d skills" % [p.get("sk", []).size(), G.TC.MAX_SKILLS], "sparkles", func(): _learn(p))
		var ag = G.age(p)
		var men = int(p.get("mentor", -1))
		if ag <= 23:
			_act(w, "Mentor", ("Learning from %s" % G.pname(s.players[men])) if men >= 0 and s.players.has(men) and s.players[men].club == uc.id else "Pair him with a senior player: faster growth", "graduation-cap", func(): _mentor(p))
		else:
			var pupils = 0
			for pid in uc.players:
				if int(s.players[pid].get("mentor", -1)) == p.id:
					pupils += 1
			w.add_child(UI.kv("Mentoring", "%d young player%s" % [pupils, "" if pupils == 1 else "s"] if pupils > 0 else "Nobody", UI.TEXT, 18))
		w.add_child(UI.caps("Duties and number", 15, UI.accent))
		var duty = UI.hb(6)
		for k in [["capt", "Captain"], ["pk", "Penalties"], ["fk", "Free kicks"], ["ck", "Corners"]]:
			var on = int(uc.get(k[0], -1)) == p.id
			var ch = UI.panel(Color(UI.accent, 0.25) if on else Color(1, 1, 1, 0.05), 10, 8, 7, UI.accent if on else Color(0, 0, 0, 0))
			ch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var cl = UI.lbl(k[1], 15, UI.TEXT if on else UI.MUTED, "semi")
			cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			ch.add_child(cl)
			var kk = k[0]
			UI.tap(ch, func():
				uc[kk] = -1 if int(uc.get(kk, -1)) == p.id else p.id
				refresh(), true)
			duty.add_child(ch)
		w.add_child(duty)
		_act(w, "Shirt number", "Wears %d" % int(p.get("num", 0)), "hash", func(): _number(p))
		# ---- pane 3: future
		x.add_child(UI.caps("Future", 15, UI.accent))
		if loaned_in:
			x.add_child(_note("clock", "On loan from %s until the end of the season." % s.clubs[p.loan].name, UI.BLUE))
		else:
			var yrs = max(0, p.cend - s.season - 1)
			_act(x, "Offer new contract", "%s a week · %s" % [G.money(p.wage), "ends this June" if yrs == 0 else "%d year%s left" % [yrs, "" if yrs == 1 else "s"]], "handshake", func(): UI.main.open("nego", {"pid": p.id, "mode": "renew"}), UI.AMBER if yrs == 0 else Color(0, 0, 0, 0))
			if p.get("youth", false):
				_act(x, "Promote to first team", "He is in the youth squad", "arrow-up", func():
					p.erase("youth")
					UI.toast("%s joins the first-team squad" % G.pname(p), UI.GREEN)
					refresh(), UI.GOLD)
			_act(x, "Take off the transfer list" if p.listed else "Transfer list", "Clubs are being told he is for sale" if p.listed else "Worth about %s" % G.money(G.value(p)), "flag", func():
				p.listed = not p.listed
				UI.toast("%s %s the transfer list" % [G.pname(p), "added to" if p.listed else "removed from"])
				refresh(), UI.GREEN if p.listed else Color(0, 0, 0, 0))
			_act(x, "Loan out", "Games elsewhere, wages shared", "arrow-left-right", func(): _loan_out(p))
			_act(x, "Release", "Ends his contract now", "log-out", func(): _release(p), UI.RED)
		x.add_child(UI.caps("Tools", 15, UI.accent))
		_act(x, "Compare with another player", "", "users", func(): _compare(p))
		_act(x, "Find similar players", "", "search", func(): UI.main.open("search", {"list": "similar", "pid": p.id, "grp": "search"}))
	else:
		# ---- someone else's player (or a free agent)
		v.add_child(UI.caps("What we know", 15, UI.accent))
		v.add_child(UI.kv("Value", G.money(G.value(p)), UI.TEXT, 18))
		if not free:
			v.add_child(UI.kv("Asking price", "about %s" % G.money(G.TR.asking_price(p)), UI.GOLD, 18))
			v.add_child(UI.kv("Club's stance", "Listed for sale" if p.listed else ("Not for sale" if G.TR.squad_rank(p) < 3 else "Open to offers"), UI.GREEN if p.listed else UI.TEXT, 18))
			v.add_child(UI.kv("Contract", "Until June %d" % p.cend, UI.AMBER if p.cend <= s.season + 1 else UI.TEXT, 18))
		v.add_child(UI.kv("Would want", "%s a week" % G.money(G.wage_for(p.ovr, G.age(p))), UI.TEXT, 18))
		if p.get("rc", 0) > 0:
			v.add_child(UI.kv("Release clause", G.money(p.rc), UI.AMBER, 18))
		_scout_btn(v, p)
		w.add_child(UI.caps("Deal", 15, UI.accent))
		if loaned_out:
			w.add_child(_note("clock", "Your player, on loan at %s until the end of the season.%s" % [s.clubs[p.club].name, " You kept a recall clause." if p.get("lrecall", false) else ""], UI.BLUE))
			if G.MK.can_recall(p):
				_act(w, "Recall from loan", "Bring him back now", "repeat", func():
					G.MK.recall(p)
					UI.toast("%s is back" % G.pname(p), UI.GREEN)
					refresh(), UI.GREEN)
		elif free:
			_act(w, "Offer contract", "No fee: agree wages and role", "handshake", func(): UI.main.open("nego", {"pid": p.id, "mode": "free"}), UI.accent)
		else:
			var dl = G.DL.find(p.id)
			var lab = "Approach %s" % s.clubs[p.club].short
			if dl != null and dl.mode == "buy" and dl.stage != "dead" and dl.stage != "done":
				lab = {"new": lab, "club": "Continue fee talks", "deleg": "Your assistant is talking", "meet": "He meets you tomorrow", "talks": "Agree personal terms"}.get(dl.stage, lab)
			_act(w, lab, "Open the talks", "handshake", func(): UI.main.open("nego", {"pid": p.id, "mode": "buy"}), UI.accent)
			if G.window_open():
				_act(w, "Ask about a loan", "A season or half-season", "arrow-left-right", func(): _loan_in(p))
			else:
				w.add_child(UI.wrap("The transfer window is closed: a fee can be agreed, the move waits for it to open.", 15, UI.MUTED))
			_special(w, p)
		x.add_child(UI.caps("Tools", 15, UI.accent))
		var short = p.id in s.shortlist
		_act(x, "On your shortlist" if short else "Add to shortlist", "Tap to remove" if short else "Keep an eye on him", "star", func():
			if p.id in s.shortlist:
				s.shortlist.erase(p.id)
			else:
				s.shortlist.append(p.id)
			refresh(), UI.GOLD if short else Color(0, 0, 0, 0))
		_act(x, "Compare with another player", "", "users", func(): _compare(p))
		_act(x, "Find similar players", "", "search", func(): UI.main.open("search", {"list": "similar", "pid": p.id, "grp": "search"}))
	if G.settings.get("editor", false):
		var eh = UI.hb(8)
		for dd in [-1, 1]:
			var eb = UI.btn("Rating %+d" % dd, func():
				G.change_ovr(p, dd)
				p.pot = max(p.pot, p.ovr)
				refresh(), "ghost", "pencil", 44)
			eb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			eh.add_child(eb)
		x.add_child(eh)


func _talk(p: Dictionary, t: Dictionary):
	var res = G.OPS.talk(p, t.k)
	UI.sheet(t.n, func(v):
		v.add_child(UI.wrap("You: “%s”" % res.you, 20, UI.MUTED))
		v.add_child(UI.wrap("%s: “%s”" % [G.pname(p), res.reply], 22, UI.TEXT))
		v.add_child(UI.lbl_fill("Morale %+d%s" % [res.mor, " · " + res.note if res.note != "" else ""], 18, UI.GREEN if res.mor > 0 else (UI.RED if res.mor < 0 else UI.MUTED), "semi"))
		v.add_child(UI.btn("Done", func():
			UI.close_sheet()
			refresh(), "primary", "check", 50)))


func _mentor(p: Dictionary):
	var s = G.s
	var uc = G.uc()
	UI.sheet("Mentor for %s" % G.pname(p), func(v):
		v.add_child(UI.wrap("A senior player in the same part of the pitch. The better and more professional he is, the more it helps. Each senior takes up to two.", 17, UI.MUTED))
		var cands = []
		for pid in uc.players:
			var q = s.players[pid]
			if q.id != p.id and G.age(q) >= 27 and G.LINE.get(q.pos, 2) == G.LINE.get(p.pos, 2) and q.ovr >= p.ovr:
				cands.append(q)
		cands.sort_custom(func(a, b): return a.ovr > b.ovr)
		if cands.is_empty():
			v.add_child(UI.wrap("Nobody suitable: he needs someone 27 or older, in his line, at least as good as he is.", 18, UI.AMBER))
		for q in cands:
			var n = 0
			for pid in uc.players:
				if int(s.players[pid].get("mentor", -1)) == q.id:
					n += 1
			var on = int(p.get("mentor", -1)) == q.id
			var r = UI.panel(Color(UI.accent, 0.16) if on else Color(1, 1, 1, 0.05), 10, 12, 6)
			var rh = UI.hb(8)
			rh.add_child(UI.pos(q.pos, 16))
			rh.add_child(UI.lbl_fill("%s · %d · %s" % [G.pname(q), G.age(q), G.PS.personality(q)], 19, UI.TEXT, "semi"))
			rh.add_child(UI.lbl("%d pupil%s" % [n, "" if n == 1 else "s"], 15, UI.MUTED))
			rh.add_child(UI.ovr(q.ovr, 17))
			r.add_child(rh)
			var qq = q
			if n < 2 or on:
				UI.tap(r, func():
					if on:
						p.erase("mentor")
					else:
						p["mentor"] = qq.id
					UI.close_sheet()
					refresh(), true)
			else:
				r.modulate.a = 0.5
			v.add_child(r))


func _number(p: Dictionary):
	var s = G.s
	var uc = G.uc()
	var used = {}
	for pid in uc.players:
		if pid != p.id:
			used[int(s.players[pid].get("num", 0))] = G.pname(s.players[pid])
	UI.sheet("Shirt number", func(v):
		v.add_child(UI.wrap("Taken numbers are dimmed. Tap a free one.", 16, UI.MUTED))
		var g = GridContainer.new()
		g.columns = 11
		g.add_theme_constant_override("h_separation", 5)
		g.add_theme_constant_override("v_separation", 5)
		for n in range(1, 56):
			var taken = used.has(n)
			var on = int(p.get("num", 0)) == n
			var c = UI.panel(UI.accent if on else Color(1, 1, 1, 0.03 if taken else 0.08), 8, 0, 6)
			c.custom_minimum_size = Vector2(52, 0)
			var l = UI.lbl(str(n), 19, UI.on_color(UI.accent) if on else (UI.DIM if taken else UI.TEXT), "disp")
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			c.add_child(l)
			if not taken:
				var nn = n
				UI.tap(c, func():
					p["num"] = nn
					UI.close_sheet()
					refresh(), true)
			g.add_child(c)
		v.add_child(g))


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
			lab = {"new": "Approach club", "club": "Fee talks", "deleg": "Assistant talking", "meet": "Meets tomorrow", "talks": "Agree terms"}.get(dl.stage, "Approach club")
		acts.append([lab, "handshake", "primary", func(): UI.main.open("nego", {"pid": p.id, "mode": "buy"})])
		if p.has("mrh") and int(p.get("mr", -1)) == s.user.club:
			acts.append(["Match %s" % G.money(int(p.mrh.fee)), "", "gold", func(): _match_bid(p)])
		elif G.MK.can_buy_back(p):
			acts.append(["Buy back %s" % G.money(int(p.bb.fee)), "", "gold", func(): _buy_back(p)])
		elif G.MK.can_pre(p).ok:
			acts.append(["Pre-contract", "", "gold", func(): UI.main.open("nego", {"pid": p.id, "mode": "pre"})])
	acts.append(["Compare", "users", "secondary", func(): _compare(p)])
	acts.append(["Similar", "search", "secondary", func(): UI.main.open("search", {"list": "similar", "pid": p.id, "grp": "search"})])
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


func _special(v: Control, p: Dictionary):
	# the routes to a player that are not an ordinary bid: matched bid, buy-back, pre-contract
	var s = G.s
	if p.has("mrh") and int(p.get("mr", -1)) == s.user.club:
		v.add_child(_note("clock", "%s have agreed to buy him for %s. Your matching right lets you take him instead until %s." % [s.clubs[int(p.mrh.club)].name, G.money(int(p.mrh.fee)), G.fmt_date(int(p.mrh.exp))], UI.AMBER))
		v.add_child(UI.btn("Match the bid: %s" % G.money(int(p.mrh.fee)), func(): _match_bid(p), "gold", "handshake", 60))
	elif int(p.get("mr", -1)) == s.user.club:
		v.add_child(_note("info", "You hold a matching right on him: if his club accepts a bid, you get three days to match it.", UI.MUTED))
	if G.MK.can_buy_back(p):
		v.add_child(UI.btn("Use your buy-back clause: %s" % G.money(int(p.bb.fee)), func(): _buy_back(p), "gold", "repeat", 60))
	var pc = G.MK.can_pre(p)
	if pc.ok:
		v.add_child(_note("file-text", "His contract ends in June. You can agree a pre-contract now and he joins on a free transfer in the summer.", UI.GREEN))
		v.add_child(UI.btn("Offer a pre-contract", func(): UI.main.open("nego", {"pid": p.id, "mode": "pre"}), "gold", "file-text", 60))
	elif pc.why != "":
		v.add_child(_note("file-text", pc.why, UI.MUTED))


func _match_bid(p: Dictionary):
	var fee = int(p.mrh.fee)
	if fee > G.uc().budget:
		UI.toast("You need %s in the transfer budget" % G.money(fee), UI.RED)
		return
	p.erase("mrh")
	p.erase("mr")
	G.MK.agreed_deal(p, fee, "Matched the accepted bid of %s under your matching right." % G.money(fee))
	UI.main.open("nego", {"pid": p.id, "mode": "buy"})


func _buy_back(p: Dictionary):
	var fee = int(p.bb.fee)
	if not G.window_open():
		UI.toast("The transfer window is closed", UI.RED)
		return
	if fee > G.uc().budget:
		UI.toast("You need %s in the transfer budget" % G.money(fee), UI.RED)
		return
	UI.confirm("Buy back %s?" % G.pname(p), "Your clause lets you sign him for %s whatever his club thinks. He and his agent come in tomorrow to talk terms." % G.money(fee), "Use the clause", func():
		p.erase("bb")
		G.MK.agreed_deal(p, fee, "Buy-back clause used at %s." % G.money(fee))
		UI.main.open("nego", {"pid": p.id, "mode": "buy"}))


func _loan_in(p: Dictionary):
	# a loan is a small negotiation of its own: wages, what happens next summer, and how much he plays
	var lv = G.MK.loan_view(p)
	if not lv.ok:
		UI.toast(lv.why, UI.RED)
		return
	var val = float(G.value(p))
	var st = {"share": 2, "opt": 0, "fee": float(G.nice(val * 1.1)), "starter": lv.young, "msg": ""}
	var club = G.s.clubs[p.club]
	var build_sheet: Callable
	build_sheet = func(v):
		v.add_child(UI.wrap("%s %s" % [club.name, "see him as part of their plans, so only a loan you must make permanent will interest them." if lv.core else ("want their young player to get games." if lv.young else "are open to a loan.")], 19, UI.MUTED))
		if st.msg != "":
			var rp = UI.panel(Color(UI.AMBER, 0.12), 10, 12, 6, Color(UI.AMBER, 0.4))
			rp.add_child(UI.wrap(st.msg, 18, UI.TEXT))
			v.add_child(rp)
		v.add_child(UI.caps("You pay · %s a week" % G.money(int(p.wage * G.MK.SHARE[st.share])), 16, UI.accent))
		v.add_child(UI.seg(["Half his wages", "Three quarters", "All of them"], st.share, func(i):
			st.share = i
			UI.close_sheet()
			UI.sheet("Loan: %s" % G.pname(p), build_sheet), 17, 6))
		v.add_child(UI.caps("Next summer", 16, UI.accent))
		v.add_child(UI.seg(G.MK.OPT_TXT, st.opt, func(i):
			st.opt = i
			st.fee = float(G.nice(val * (1.1 if i == 1 else 0.95)))
			UI.close_sheet()
			UI.sheet("Loan: %s" % G.pname(p), build_sheet), 17, 6))
		if st.opt > 0:
			var fl = UI.lbl("%s %s" % ["You may buy him for" if st.opt == 1 else "You will buy him for", G.money(int(st.fee))], 22, UI.TEXT, "semi")
			v.add_child(fl)
			var sl = UI.slider(val * 0.6, val * 2.0, st.fee, max(1000.0, float(G.nice(val / 50.0))), func(x):
				st.fee = x
				fl.text = "%s %s" % ["You may buy him for" if st.opt == 1 else "You will buy him for", G.money(int(x))], true)
			sl.custom_minimum_size = Vector2(0, 40)
			v.add_child(sl)
		v.add_child(UI.caps("Playing time", 16, UI.accent))
		v.add_child(UI.seg(["No promise", "Promise first-team football"], 1 if st.starter else 0, func(i):
			st.starter = i == 1
			UI.close_sheet()
			UI.sheet("Loan: %s" % G.pname(p), build_sheet), 17, 6))
		if st.starter:
			v.add_child(UI.lbl_fill("If he plays under 40% of league matches, they will recall him.", 15, UI.DIM))
		v.add_child(UI.btn("Propose the loan", func():
			var r = G.MK.loan_offer(p, st.share, st.opt, int(st.fee), st.starter)
			if r.ok:
				UI.close_sheet()
				UI.sfx("cash")
				UI.toast("%s joins on loan" % G.pname(p), UI.GREEN)
				G.msg("%s joins on loan" % G.pname(p), r.text, "info")
				refresh()
			else:
				st.msg = r.text
				UI.sfx("error")
				UI.close_sheet()
				UI.sheet("Loan: %s" % G.pname(p), build_sheet), "primary", "handshake", 56))
	UI.sheet("Loan: %s" % G.pname(p), build_sheet)


func _loan_out(p: Dictionary):
	var st = {"pay": 2, "recall": true}
	var build_sheet: Callable
	build_sheet = func(v):
		v.add_child(UI.wrap("Your staff will find him a club where he should play regularly. He returns at the end of the season. Paying part of his wages yourself opens the door to better clubs.", 19, UI.MUTED))
		v.add_child(UI.caps("The other club pays", 16, UI.accent))
		v.add_child(UI.seg(["Half his wages", "Three quarters", "All of them"], st.pay, func(i):
			st.pay = i
			UI.close_sheet()
			UI.sheet("Loan out %s" % G.pname(p), build_sheet), 17, 6))
		if st.pay < 2:
			v.add_child(UI.lbl_fill("You keep paying %s a week." % G.money(int(p.wage * (1.0 - G.MK.SHARE[st.pay]))), 16, UI.AMBER))
		v.add_child(UI.caps("Recall clause", 16, UI.accent))
		v.add_child(UI.seg(["None", "I can recall him in January"], 1 if st.recall else 0, func(i):
			st.recall = i == 1
			UI.close_sheet()
			UI.sheet("Loan out %s" % G.pname(p), build_sheet), 17, 6))
		v.add_child(UI.btn("Send on loan", func():
			var err = G.MK.loan_out(p, st.pay, st.recall)
			UI.close_sheet()
			if err != "":
				UI.toast(err, UI.RED)
			else:
				UI.main.back(), "primary", "arrow-left-right", 56))
	UI.sheet("Loan out %s" % G.pname(p), build_sheet)


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


func _learn(p: Dictionary):
	var build_sheet = func(v):
		v.add_child(UI.wrap("He works on one new skill at a time on the training ground. Skills close to what he can already do come quicker. A player can hold %d." % G.TC.MAX_SKILLS, 20, UI.MUTED))
		for it in G.TC.learnable(p):
			var sk = G.TC.SKILLS[it[0]]
			var r = UI.panel(UI.CARD, 14, 16, 10, UI.LINE)
			var h = UI.hb(10)
			var tv = UI.vb(0)
			tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tv.add_child(UI.lbl(sk.n, 24, UI.TEXT, "disp"))
			tv.add_child(UI.wrap(sk.d, 17, UI.MUTED))
			h.add_child(tv)
			h.add_child(UI.caps("%d weeks" % it[1], 17, UI.accent))
			r.add_child(h)
			var id = it[0]
			var wk = it[1]
			UI.tap(r, func():
				p["lsk"] = [id, wk]
				UI.close_sheet()
				UI.toast("%s starts work on %s" % [G.pname(p), G.TC.SKILLS[id].n], UI.GREEN)
				refresh())
			v.add_child(r)
	UI.sheet("Teach a skill", build_sheet)


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

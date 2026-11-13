extends "res://scripts/screens/screen.gd"
# Player search: a dense sortable table with club, nation, positions, age, rating, value and wage.

const PER = 9
const GROUPS = ["All", "GK", "DEF", "MID", "ATT"]
const VIEWS = ["General", "Contract", "Attributes", "Skills"]

var pg := 0
var grp := 0
var view := 0
var afford := false
var skill := ""        # only players with this skill
var fitstyle := false  # only players with a role for the user's playstyle
var linkfit := false   # only players who fit a slot in one of the user's link-up plays
var q := ""
var key := "val"
var desc := true
var rows: Array = []


func _collect():
	var s = G.s
	var c = G.uc()
	rows = []
	var st = G.TC.style_of(c)
	var ql = q.strip_edges().to_lower()
	for p in s.players.values():
		if p.club == c.id:
			continue
		if p.club >= 0 and s.leagues[s.clubs[p.club].lg].roe and ql == "":
			continue
		if grp > 0 and G.LINE.get(p.pos, 2) != grp - 1:
			continue
		if afford and G.value(p) > c.budget:
			continue
		if skill != "" and not (skill in p.get("sk", [])):
			continue
		if fitstyle and G.TC.best_fit_role(p, p.pos, st) == "":
			continue
		if linkfit and not _fits_link(p):
			continue
		if ql != "" and not G.pfull(p).to_lower().contains(ql) and not (p.club >= 0 and s.clubs[p.club].name.to_lower().contains(ql)):
			continue
		rows.append(p)
	var f = func(p):
		match key:
			"name": return -float(G.pfull(p).unicode_at(0))
			"age": return float(G.age(p))
			"ovr": return float(p.ovr)
			"wage": return float(p.wage)
			"cend": return float(p.cend)
			"pac": return float(p.st[0])
			"sho": return float(p.st[1])
			"pas": return float(p.st[2])
			"dri": return float(p.st[3])
			"def": return float(p.st[4])
			"phy": return float(p.st[5])
		return float(G.value(p))
	rows.sort_custom(func(a, b): return f.call(a) > f.call(b) if desc else f.call(a) < f.call(b))


func _fits_link(p: Dictionary) -> bool:
	for lid in G.s.user.links:
		if not G.TC.LINKS.has(lid):
			continue
		for sl in [G.TC.LINKS[lid].a, G.TC.LINKS[lid].b]:
			if p.pos in sl.pos and G.TC.fits_slot(sl, p):
				return true
	return false


func _pick_skill():
	var build_sheet = func(v):
		var none = UI.panel(UI.CARD, 12, 16, 8, UI.accent if skill == "" else UI.LINE)
		none.add_child(UI.lbl("Any skill", 22, UI.TEXT, "semi"))
		UI.tap(none, func():
			skill = ""
			pg = 0
			UI.close_sheet()
			refresh())
		v.add_child(none)
		for id in G.TC.SKILLS:
			var sk = G.TC.SKILLS[id]
			var r = UI.panel(UI.CARD, 12, 16, 6, UI.accent if skill == id else UI.LINE)
			var h = UI.hb(10)
			h.add_child(UI.lbl(sk.n, 21, UI.TEXT, "semi"))
			h.add_child(UI.lbl_fill(sk.d, 15, UI.MUTED))
			r.add_child(h)
			var sid = id
			UI.tap(r, func():
				skill = sid
				pg = 0
				UI.close_sheet()
				refresh())
			v.add_child(r)
	UI.sheet("Filter by skill", build_sheet)


func build():
	var s = G.s
	var c = G.uc()
	_collect()
	var pages = max(1, int(ceil(rows.size() / float(PER))))
	pg = clampi(pg, 0, pages - 1)
	var nav = UI.hb(6)
	for d in [-1, 1]:
		var b = UI.panel(Color(1, 1, 1, 0.07), 10, 12, 8)
		b.add_child(UI.icon("chevron-left" if d < 0 else "chevron-right", 26, UI.TEXT))
		UI.tap(b, func():
			pg = clampi(pg + d, 0, pages - 1)
			refresh(), true)
		nav.add_child(b)
		if d < 0:
			var pl = UI.lbl("Pg. %d/%d" % [pg + 1, pages], 20, UI.TEXT, "semi")
			pl.custom_minimum_size = Vector2(120, 0)
			pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			nav.add_child(pl)
	body.add_child(UI.topbar("Player Search", true, nav))
	UI.main.t_sub = "%d players found" % rows.size()
	# budget strip and filters
	var strip = UI.panel(Color(UI.accent, 0.85), 8, 14, 5)
	var fg = UI.on_color(UI.accent)
	var sh = UI.hb(14)
	sh.add_child(UI.lbl("Transfer budget", 19, fg, "semi"))
	sh.add_child(UI.lbl(G.money(c.budget), 21, fg, "xbold"))
	sh.add_child(UI.lbl("Wage room", 19, fg, "semi"))
	sh.add_child(UI.lbl("%s (p/w)" % G.money(max(0, c.wage_budget - G.squad_wages(c))), 21, fg, "xbold"))
	sh.add_child(UI.sp())
	var vw = UI.lbl("View: %s ▸" % VIEWS[view], 20, fg, "bold")
	UI.tap(vw, func():
		view = (view + 1) % VIEWS.size()
		refresh(), true)
	sh.add_child(vw)
	strip.add_child(sh)
	body.add_child(UI.margin(strip, 16, 0, 16, 4))
	var fh = UI.hb(6)
	for i in GROUPS.size():
		var on = grp == i
		var ch = UI.chip(GROUPS[i], Color(UI.accent, 0.2) if on else Color(1, 1, 1, 0.06), UI.accent if on else UI.MUTED, 17, 58)
		var idx = i
		UI.tap(ch, func():
			grp = idx
			pg = 0
			refresh(), true)
		fh.add_child(ch)
	var ac = UI.chip("IN BUDGET", Color(UI.GREEN, 0.2) if afford else Color(1, 1, 1, 0.06), UI.GREEN if afford else UI.MUTED, 17)
	UI.tap(ac, func():
		afford = not afford
		pg = 0
		refresh(), true)
	fh.add_child(ac)
	var skc = UI.chip(G.TC.SKILLS[skill].n.to_upper() if skill != "" else "SKILL", Color(UI.accent, 0.2) if skill != "" else Color(1, 1, 1, 0.06), UI.accent if skill != "" else UI.MUTED, 17)
	UI.tap(skc, func(): _pick_skill(), true)
	fh.add_child(skc)
	var fsc = UI.chip("FITS STYLE", Color(UI.GREEN, 0.2) if fitstyle else Color(1, 1, 1, 0.06), UI.GREEN if fitstyle else UI.MUTED, 17)
	UI.tap(fsc, func():
		fitstyle = not fitstyle
		pg = 0
		refresh(), true)
	fh.add_child(fsc)
	if s.user.links.size() > 0:
		var lkc = UI.chip("FITS LINK-UP", Color(UI.GREEN, 0.2) if linkfit else Color(1, 1, 1, 0.06), UI.GREEN if linkfit else UI.MUTED, 17)
		UI.tap(lkc, func():
			linkfit = not linkfit
			pg = 0
			refresh(), true)
		fh.add_child(lkc)
	var le = UI.input(q, "Name or club…", func(t): q = t)
	le.custom_minimum_size = Vector2(0, 40)
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	le.text_submitted.connect(func(_t):
		pg = 0
		refresh())
	fh.add_child(le)
	var go = UI.chip("SEARCH", UI.accent, UI.on_color(UI.accent), 17)
	UI.tap(go, func():
		pg = 0
		refresh(), true)
	fh.add_child(go)
	body.add_child(UI.margin(fh, 16, 0, 16, 4))
	# columns for this view
	var cols = [["name", "Name", 0], ["", "Club", 250], ["", "Nat", 46], ["", "Pos", 130], ["age", "Age", 50], ["ovr", "Rtg", 54]]
	if view == 0:
		cols += [["val", "Value", 96]]
	elif view == 1:
		cols += [["wage", "Wage", 90], ["cend", "Until", 70], ["val", "Value", 96]]
	elif view == 3:
		cols = [["name", "Name", 260], ["", "Pos", 60], ["age", "Age", 50], ["ovr", "Rtg", 54], ["", "Skills", 0], ["val", "Value", 96]]
	else:
		cols = [["name", "Name", 0], ["", "Pos", 70], ["ovr", "Rtg", 54], ["pac", "Pac", 50], ["sho", "Sho", 50], ["pas", "Pas", 50], ["dri", "Dri", 50], ["def", "Def", 50], ["phy", "Phy", 50], ["val", "Value", 96]]
	var head = UI.panel(Color(UI.accent, 0.5), 6, 14, 3)
	var hh = UI.hb(8)
	for cd in cols:
		var on = cd[0] != "" and cd[0] == key
		var l = UI.lbl(cd[1] + (" ▾" if on and desc else (" ▴" if on else "")), 19, UI.GOLD if on else UI.TEXT, "semi")
		if cd[2] > 0:
			l.custom_minimum_size = Vector2(cd[2], 0)
			l.clip_text = true
		else:
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if cd[0] != "":
			var k = cd[0]
			UI.tap(l, func():
				if key == k:
					desc = not desc
				else:
					key = k
					desc = true
				pg = 0
				refresh(), true)
		hh.add_child(l)
	head.add_child(hh)
	body.add_child(UI.margin(head, 16, 0, 16, 2))
	var list = UI.vb(2)
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(UI.margin(list, 16, 0, 16, 8))
	body.get_child(body.get_child_count() - 1).size_flags_vertical = Control.SIZE_EXPAND_FILL
	for p in rows.slice(pg * PER, pg * PER + PER):
		var r = UI.panel(Color(1, 1, 1, 0.035), 6, 14, 0)
		r.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var h = UI.hb(8)
		for cd in cols:
			var w = cd[2]
			var node: Control
			match cd[1]:
				"Name":
					node = UI.lbl_fill(G.pfull(p), 22, UI.TEXT, "semi")
				"Club":
					var ch2 = UI.hb(8)
					if p.club >= 0:
						ch2.add_child(UI.badge(s.clubs[p.club], 28))
						ch2.add_child(UI.lbl_fill(s.clubs[p.club].name, 20, UI.TEXT))
					else:
						ch2.add_child(UI.lbl_fill("Free agent", 20, UI.GREEN))
					node = ch2
				"Nat":
					node = UI.center(UI.flag(p.nat, 34))
				"Pos":
					node = UI.lbl(p.pos + ((", " + ", ".join(p.alt)) if p.alt.size() > 0 else ""), 19, UI.TEXT)
					node.clip_text = true
				"Age":
					node = UI.lbl(str(G.age(p)), 21, UI.TEXT, "disp")
				"Rtg":
					node = UI.ovr(p.ovr, 19)
				"Value":
					node = UI.lbl(G.money(G.value(p)), 21, UI.GOLD if G.value(p) <= c.budget else UI.TEXT, "disp")
				"Wage":
					node = UI.lbl(G.money(p.wage), 20, UI.MUTED, "disp")
				"Until":
					node = UI.lbl(str(p.cend) if p.club >= 0 else "-", 20, UI.AMBER if p.cend <= s.season + 1 else UI.MUTED, "disp")
				"Skills":
					node = UI.lbl_fill(", ".join(G.TC.skill_names(p)) if p.get("sk", []).size() > 0 else "-", 16, UI.MUTED)
				_:
					var i = ["Pac", "Sho", "Pas", "Dri", "Def", "Phy"].find(cd[1])
					node = UI.lbl(str(int(p.st[i])), 21, UI.ovr_color(int(p.st[i])), "disp")
			if w > 0:
				node.custom_minimum_size = Vector2(w, 0)
				node.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			node.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			h.add_child(node)
		r.add_child(h)
		var pid = p.id
		UI.tap(r, func(): UI.main.open("player", {"pid": pid}))
		list.add_child(r)
	if rows.is_empty():
		list.add_child(UI.wrap("No players match. Clear the filters or search for another name.", 21, UI.MUTED))

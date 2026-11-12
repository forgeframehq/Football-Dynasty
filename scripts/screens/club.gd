extends "res://scripts/screens/screen.gd"
# Club hub: navigation to tables, fixtures, stats, finances, board and more.


func _init():
	show_nav = true


func build():
	var c = G.uc()
	body.add_child(UI.clubbar())
	var v = content(12)
	var items = [
		["list-ordered", "League table", "%s in the %s" % [G.LG.ordinal(G.LG.position(c.id)), G.s.leagues[c.lg].name], func(): UI.main.open("table", {"lg": c.lg})],
		["landmark", "Club & facilities", "Stadium %s · tap to upgrade" % G.OPS._thousands(G.OPS.capacity(c)), func(): UI.main.open("campus")],
		["activity", "Training", "%s focus · %s intensity" % [G.OPS.FOCUS[c.train.focus], G.OPS.INTENSITY[c.train.inten].to_lower()], func(): UI.main.open("training")],
		["search", "Scouting", "%d player%s being watched" % [G.s.scout.queue.size(), "" if G.s.scout.queue.size() == 1 else "s"], func(): UI.main.open("scouting")],
		["trophy", "Competitions", "Cups and European football", func(): UI.main.open("comps")],
		["calendar", "Fixtures & results", "Your season schedule", func(): UI.main.open("fixtures")],
		["chart-bar", "Player stats", "Top scorers, assists and ratings", func(): UI.main.open("stats", {"lg": c.lg})],
		["wallet", "Finances", "%s budget · %s/wk wages" % [G.money(c.budget), G.money(G.squad_wages(c))], func(): UI.main.open("finances")],
		["user", "Manager & board", "%s · confidence %d%%" % [G.s.user.obj.text, int(G.s.user.conf)], func(): UI.main.open("board")],
		["mail", "Inbox", "%d unread" % G.unread(), func(): UI.main.open("inbox")],
		["briefcase", "Job market", "Clubs interested in you", func(): UI.main.open("jobs")],
	]
	for it in items:
		var r = UI.panel(UI.CARD, 22, 20, 18, UI.LINE)
		var h = UI.hb(18)
		var ic = UI.panel(Color(UI.accent, 0.12), 18, 14, 14)
		ic.add_child(UI.icon(it[0], 32, UI.accent))
		h.add_child(ic)
		var tv = UI.vb(0)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UI.lbl_fill(it[1].to_upper(), 30, UI.TEXT, "disp"))
		tv.add_child(UI.lbl_fill(it[2], 21, UI.MUTED))
		h.add_child(tv)
		h.add_child(UI.icon("chevron-right", 28, UI.DIM))
		r.add_child(h)
		UI.tap(r, it[3])
		v.add_child(r)
	v.add_child(UI.sp(0, 6))
	v.add_child(UI.btn("Save & exit to menu", func():
		G.save_game()
		G.active = false
		UI.main.root("menu"), "secondary", "save", 76))

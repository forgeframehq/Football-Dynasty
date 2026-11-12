extends "res://scripts/screens/screen.gd"
# Title screen.


func build():
	var v = UI.vb(0)
	var m = UI.margin(v, 44, 0, 44, 40)
	m.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(m)
	v.add_child(UI.sp())
	var emblem = UI.panel(Color(UI.GOLD, 0.1), 40, 26, 26, Color(UI.GOLD, 0.35))
	emblem.add_child(UI.icon("trophy", 76, UI.GOLD))
	emblem.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	v.add_child(emblem)
	v.add_child(UI.sp(0, 34))
	var t = UI.vb(-34)
	t.add_child(UI.lbl("FOOTBALL", 132, UI.TEXT, "xbold"))
	t.add_child(UI.lbl("DYNASTY", 132, UI.GOLD, "xbold"))
	v.add_child(t)
	v.add_child(UI.sp(0, 10))
	v.add_child(UI.caps("Career manager  ·  Season 2026/27", 26, UI.MUTED))
	v.add_child(UI.sp(0, 14))
	v.add_child(UI.wrap("Take charge of any club across the top five leagues and their lower divisions. Build the squad, set the tactics, win it all.", 25, UI.MUTED))
	v.add_child(UI.sp())
	var meta = G.save_meta() if G.has_save() else null
	if meta != null:
		var c = UI.panel(UI.CARD, 24, 20, 18, UI.LINE)
		var h = UI.hb(16)
		h.add_child(UI.badge({"c1": meta.c1, "c2": meta.c2, "short": meta.short, "id": meta.cid}, 72))
		var cv = UI.vb(0)
		cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cv.add_child(UI.caps("Continue career", 20, UI.GOLD))
		cv.add_child(UI.lbl_fill(meta.club, 32, UI.TEXT, "disp"))
		cv.add_child(UI.lbl_fill("%s · %s" % [meta.manager, meta.date], 21, UI.MUTED))
		h.add_child(cv)
		h.add_child(UI.icon("chevron-right", 36, UI.GOLD))
		c.add_child(h)
		UI.tap(c, _continue, true)
		v.add_child(c)
		v.add_child(UI.sp(0, 14))
	v.add_child(UI.btn("New career", _new, "gold" if meta == null else "secondary", "plus"))
	v.add_child(UI.sp(0, 18))
	var foot = UI.lbl("v0.1 · personal build · not for distribution", 18, UI.DIM)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(foot)


func _continue():
	if G.load_game():
		UI.main.root("home")
	else:
		UI.toast("Could not load the save file", UI.RED)


func _new():
	if G.has_save():
		UI.confirm("Start over?", "Starting a new career replaces your current save.", "Start new career", func(): UI.main.open("new_career"), true)
	else:
		UI.main.open("new_career")

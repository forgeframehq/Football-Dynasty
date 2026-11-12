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
	var any = false
	for i in 3:
		var meta = G.save_meta(i) if G.has_save(i) else null
		var idx = i
		if meta != null:
			any = true
			var c = UI.panel(UI.CARD, 24, 20, 16, UI.LINE)
			var h = UI.hb(16)
			h.add_child(UI.badge({"c1": meta.c1, "c2": meta.c2, "short": meta.short, "id": meta.cid}, 68))
			var cv = UI.vb(0)
			cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cv.add_child(UI.caps("Career %d · continue" % (i + 1), 19, UI.GOLD))
			cv.add_child(UI.lbl_fill(meta.club, 30, UI.TEXT, "disp"))
			cv.add_child(UI.lbl_fill("%s · %s" % [meta.manager, meta.date], 20, UI.MUTED))
			h.add_child(cv)
			var del = UI.panel(Color(1, 1, 1, 0.06), 14, 12, 12)
			del.add_child(UI.icon("x", 24, UI.MUTED))
			UI.tap(del, func(): UI.confirm("Delete career %d?" % (idx + 1), "This permanently deletes the save for %s." % meta.club, "Delete save", func():
				G.delete_save(idx)
				refresh(), true), true)
			h.add_child(del)
			c.add_child(h)
			UI.tap(c, func(): _continue(idx))
			v.add_child(c)
		else:
			var e = UI.panel(Color(1, 1, 1, 0.03), 24, 20, 18, Color(1, 1, 1, 0.1))
			var h = UI.hb(14)
			h.add_child(UI.icon("plus", 30, UI.GOLD))
			var ev = UI.vb(0)
			ev.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			ev.add_child(UI.lbl("NEW CAREER", 28, UI.TEXT, "disp"))
			ev.add_child(UI.lbl("Slot %d · empty" % (i + 1), 19, UI.DIM))
			h.add_child(ev)
			h.add_child(UI.icon("chevron-right", 26, UI.DIM))
			e.add_child(h)
			UI.tap(e, func(): UI.main.open("new_career", {"slot": idx}))
			v.add_child(e)
		v.add_child(UI.sp(0, 10))
	v.add_child(UI.sp(0, 18))
	var foot = UI.lbl("v0.2 · personal build · not for distribution", 18, UI.DIM)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(foot)


func _continue(i: int):
	if G.load_game(i):
		UI.main.root("home")
	else:
		UI.toast("Could not load the save file", UI.RED)

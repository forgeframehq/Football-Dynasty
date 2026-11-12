extends "res://scripts/screens/screen.gd"
# Title screen: stadium at night, continue / new / load.

var art: TextureRect


func build():
	chrome = false
	var holder = Control.new()
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.clip_contents = true
	body.add_child(holder)
	# stadium art on the right
	var glow = UI.panel(Color(0.35, 0.55, 1.0, 0.1), 400, 0, 0)
	glow.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	glow.offset_left = -860
	glow.offset_right = -60
	glow.offset_top = -400
	glow.offset_bottom = 400
	holder.add_child(glow)
	art = TextureRect.new()
	art.texture = load("res://assets/iso/stadium_level_5.png")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.modulate = Color(0.72, 0.8, 1.0)
	art.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	art.offset_left = -840
	art.offset_right = -40
	art.offset_top = -400
	art.offset_bottom = 400
	holder.add_child(art)
	var tw = create_tween().set_loops()
	tw.tween_property(art, "position:y", art.position.y - 10, 2.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(art, "position:y", art.position.y, 2.6).set_trans(Tween.TRANS_SINE)
	# left column
	var v = UI.vb(0)
	v.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	v.offset_left = 56
	v.offset_right = 56 + 520
	v.offset_top = 34
	v.offset_bottom = -26
	holder.add_child(v)
	var t = UI.vb(-30)
	t.add_child(UI.lbl("FOOTBALL", 104, UI.TEXT, "xbold"))
	t.add_child(UI.lbl("DYNASTY", 104, UI.GOLD, "xbold"))
	v.add_child(t)
	v.add_child(UI.caps("Career manager  ·  Season 2026/27", 22, UI.MUTED))
	v.add_child(UI.sp())
	var newest = -1
	var newest_t = 0
	for i in 3:
		if G.has_save(i):
			var mt = FileAccess.get_modified_time(G.save_path(i))
			if newest < 0 or mt > newest_t:
				newest = i
				newest_t = mt
	if newest >= 0:
		var meta = G.save_meta(newest)
		var cp = UI.panel(UI.GOLD, 18, 18, 10)
		var h = UI.hb(14)
		h.add_child(UI.badge({"c1": meta.c1, "c2": meta.c2, "short": meta.short, "id": meta.cid}, 56))
		var cv = UI.vb(-4)
		cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cv.add_child(UI.lbl("CONTINUE", 32, Color("0a0e17"), "xbold"))
		cv.add_child(UI.lbl_fill("%s · %s · %s" % [meta.club, meta.manager, meta.date], 18, Color(0.04, 0.05, 0.09, 0.75), "semi"))
		h.add_child(cv)
		h.add_child(UI.icon("play", 30, Color("0a0e17")))
		cp.add_child(h)
		var idx = newest
		UI.tap(cp, func(): _continue(idx), true)
		v.add_child(cp)
		v.add_child(UI.sp(0, 10))
	v.add_child(_item("New Career", "plus", "Take charge of any club", _new))
	if newest >= 0:
		v.add_child(UI.sp(0, 10))
		v.add_child(_item("Load Career", "save", "Three save slots", _load))
	v.add_child(UI.sp(0, 10))
	var snd = G.settings.get("sound", true)
	v.add_child(_item("Sound", "volume-2" if snd else "volume-x", "On" if snd else "Off", func():
		G.settings["sound"] = not snd
		G.save_settings()
		refresh()))
	v.add_child(UI.sp(0, 16))
	v.add_child(UI.lbl("v0.3 · personal build · not for distribution", 16, UI.DIM))
	if not G.ui.get("sting", false):
		G.ui["sting"] = true
		UI.sfx("sting_start", -10.0)


func _item(text: String, icon_name: String, sub: String, cb: Callable) -> Control:
	var p = UI.panel(Color(1, 1, 1, 0.06), 18, 18, 10, Color(1, 1, 1, 0.12))
	var h = UI.hb(14)
	h.add_child(UI.icon(icon_name, 30, UI.GOLD))
	var cv = UI.vb(-4)
	cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cv.add_child(UI.lbl(text.to_upper(), 28, UI.TEXT, "disp"))
	cv.add_child(UI.lbl(sub, 17, UI.MUTED))
	h.add_child(cv)
	h.add_child(UI.icon("chevron-right", 24, UI.DIM))
	p.add_child(h)
	UI.tap(p, cb, true)
	return p


func _new():
	for i in 3:
		if not G.has_save(i):
			UI.main.open("new_career", {"slot": i})
			return
	var build_sheet = func(v):
		v.add_child(UI.wrap("All three slots are in use. Pick one to replace.", 21, UI.MUTED))
		for i in 3:
			var meta = G.save_meta(i)
			var idx = i
			v.add_child(_slot_row(i, meta, func():
				UI.close_sheet()
				UI.main.open("new_career", {"slot": idx}), false))
	UI.sheet("New career", build_sheet)


func _load():
	var build_sheet = func(v):
		for i in 3:
			if not G.has_save(i):
				continue
			var idx = i
			v.add_child(_slot_row(i, G.save_meta(i), func():
				UI.close_sheet()
				_continue(idx), true))
	UI.sheet("Load career", build_sheet)


func _slot_row(i: int, meta: Dictionary, cb: Callable, can_delete: bool) -> Control:
	var c = UI.panel(UI.CARD, 16, 16, 10, UI.LINE)
	var h = UI.hb(14)
	h.add_child(UI.badge({"c1": meta.c1, "c2": meta.c2, "short": meta.short, "id": meta.cid}, 52))
	var cv = UI.vb(-3)
	cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cv.add_child(UI.caps("Career %d" % (i + 1), 17, UI.GOLD))
	cv.add_child(UI.lbl_fill(meta.club, 26, UI.TEXT, "disp"))
	cv.add_child(UI.lbl_fill("%s · %s" % [meta.manager, meta.date], 18, UI.MUTED))
	h.add_child(cv)
	if can_delete:
		var del = UI.panel(Color(1, 1, 1, 0.06), 12, 10, 10)
		del.add_child(UI.icon("x", 22, UI.MUTED))
		UI.tap(del, func(): UI.confirm("Delete career %d?" % (i + 1), "This permanently deletes the save for %s." % meta.club, "Delete save", func():
			G.delete_save(i)
			refresh(), true), true)
		h.add_child(del)
	c.add_child(h)
	UI.tap(c, cb)
	return c


func _continue(i: int):
	if G.load_game(i):
		UI.main.root("home")
	else:
		UI.toast("Could not load the save file", UI.RED)

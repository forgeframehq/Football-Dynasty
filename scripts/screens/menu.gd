extends "res://scripts/screens/screen.gd"
# Title screen: stadium at night, continue / new / load.

var art: TextureRect
var song_box: VBoxContainer = null


func build():
	chrome = false
	var holder = Control.new()
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.clip_contents = true
	body.add_child(holder)
	# background scene if one is supplied, otherwise the stadium art on the right
	if ResourceLoader.exists("res://assets/scenes/title.jpg"):
		var bg = TextureRect.new()
		bg.texture = load("res://assets/scenes/title.jpg")
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(bg)
		var shade = TextureRect.new()
		var g = Gradient.new()
		g.set_color(0, Color(0.02, 0.03, 0.06, 0.94))
		g.set_color(1, Color(0.02, 0.03, 0.06, 0.0))
		var gt = GradientTexture2D.new()
		gt.gradient = g
		gt.fill_to = Vector2(0.75, 0)
		shade.texture = gt
		shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		shade.stretch_mode = TextureRect.STRETCH_SCALE
		shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(shade)
	else:
		var box = CenterContainer.new()
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		box.offset_left = 520
		holder.add_child(box)
		art = TextureRect.new()
		art.texture = load("res://assets/iso/stadium_level_5.png")
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.modulate = Color(0.78, 0.84, 1.0)
		art.custom_minimum_size = Vector2(600, 600)
		box.add_child(art)
	# left column
	var v = UI.vb(0)
	v.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	v.offset_left = 56
	v.offset_right = 56 + 520
	v.offset_top = 20
	v.offset_bottom = -16
	holder.add_child(v)
	if ResourceLoader.exists("res://assets/wordmark.png"):
		var wm = TextureRect.new()
		wm.texture = load("res://assets/wordmark.png")
		wm.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		wm.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		wm.custom_minimum_size = Vector2(500, 185)
		wm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(wm)
	else:
		var t = UI.vb(-30)
		t.add_child(UI.lbl("FOOTBALL", 92, UI.TEXT, "xbold"))
		t.add_child(UI.lbl("DYNASTY", 92, UI.GOLD, "xbold"))
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
	v.add_child(_item("Settings", "settings", "Sound, soundtrack, skins", func(): UI.main.open("settings")))
	v.add_child(UI.sp(0, 16))
	v.add_child(UI.lbl("v%s · personal build · not for distribution" % ProjectSettings.get_setting("application/config/version", ""), 16, UI.DIM))
	_soundtrack(holder)
	if not G.ui.get("sting", false):
		G.ui["sting"] = true
		UI.sfx("sting_start", -10.0)


func _soundtrack(holder: Control):
	# the song list, bottom right: what is playing, previous / pause / next, tap any song to play it
	if UI.songs().is_empty():
		return
	var p = UI.panel(Color(0.03, 0.02, 0.07, 0.82), 16, 14, 10, Color(1, 1, 1, 0.12))
	p.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	p.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	p.grow_vertical = Control.GROW_DIRECTION_BEGIN
	p.offset_right = -24
	p.offset_bottom = -16
	p.custom_minimum_size = Vector2(330, 0)
	holder.add_child(p)
	song_box = UI.vb(3)
	p.add_child(song_box)
	_fill_songs()
	if not UI.song_changed.is_connected(_fill_songs):
		UI.song_changed.connect(_fill_songs)


func _fill_songs():
	if song_box == null or not is_instance_valid(song_box):
		return
	for c in song_box.get_children():
		song_box.remove_child(c)
		c.queue_free()
	var tr = UI.songs()
	var now = UI.now_playing()
	var h = UI.hb(6)
	var tv = UI.vb(-4)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(UI.caps("Soundtrack", 15, UI.GOLD))
	tv.add_child(UI.lbl_fill(tr[now].title if now >= 0 else "Music off", 22, UI.TEXT, "disp"))
	h.add_child(tv)
	for it in [["chevron-left", func(): UI.music_step(-1)], ["pause" if now >= 0 else "play", _play_pause], ["chevron-right", func(): UI.music_step(1)]]:
		var b = UI.panel(Color(1, 1, 1, 0.08), 10, 9, 7)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.add_child(UI.icon(it[0], 20, UI.TEXT))
		UI.tap(b, it[1], true)
		h.add_child(b)
	song_box.add_child(h)
	song_box.add_child(UI.sp(0, 2))
	for i in tr.size():
		var playing = i == now
		var r = UI.panel(Color(UI.accent, 0.22) if playing else Color(0, 0, 0, 0), 8, 8, 3)
		var rh = UI.hb(8)
		rh.add_child(UI.lbl("%d" % (i + 1), 16, UI.accent if playing else UI.DIM, "disp"))
		rh.add_child(UI.lbl_fill(tr[i].title, 18, UI.TEXT if playing else (UI.MUTED if UI.song_on(tr[i].id) else UI.DIM), "semi" if playing else "body"))
		rh.add_child(UI.lbl(tr[i].len, 15, UI.DIM, "cond"))
		r.add_child(rh)
		var idx = i
		UI.tap(r, func(): UI.music_play(idx), true)
		song_box.add_child(r)


func _play_pause():
	if UI.now_playing() >= 0:
		UI.music_pl.stop()
		UI.song_changed.emit()
	else:
		UI.music_play(UI.music_i)


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

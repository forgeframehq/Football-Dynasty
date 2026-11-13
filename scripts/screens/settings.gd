extends "res://scripts/screens/screen.gd"
# Settings: sound levels, the soundtrack, skins and a few game options. Opened from the title screen
# and from the in-game Options menu. Everything here is stored in G.settings, not in the career save.

var songs_box: VBoxContainer = null


func build():
	title = "Settings"
	subtitle = "Sound, soundtrack and look"
	chrome = G.active
	if not G.active:
		var h = UI.hb(12)
		var b = UI.panel(Color(1, 1, 1, 0.07), 14, 12, 8)
		b.add_child(UI.icon("chevron-left", 28, UI.TEXT))
		UI.tap(b, func(): UI.main.back(), true)
		h.add_child(b)
		h.add_child(UI.lbl("SETTINGS", 32, UI.TEXT, "xbold"))
		body.add_child(UI.margin(h, 20, 10, 20, 6))
	var row = panes(12, 20)
	_audio(row)
	_soundtrack(row)
	_look(row)
	if not UI.song_changed.is_connected(_fill_songs):
		UI.song_changed.connect(_fill_songs)


func _put(key: String, val):
	G.settings[key] = val
	G.save_settings()


func _head(v: Control, text: String):
	v.add_child(UI.caps(text, 16, UI.accent))


# ---------------------------------------------------------------- sound

func _vol(v: Control, label: String, key: String):
	var h = UI.hb(8)
	h.add_child(UI.lbl(label, 20, UI.TEXT, "semi"))
	h.add_child(UI.sp())
	var cur = int(G.settings.get(key, 70))
	var val = UI.lbl("Off" if cur <= 0 else "%d" % cur, 20, UI.MUTED if cur <= 0 else UI.GOLD, "disp")
	h.add_child(val)
	v.add_child(h)
	var sl = UI.slider(0, 100, cur, 5, func(x):
		G.settings[key] = int(x)
		val.text = "Off" if x <= 0 else "%d" % int(x)
		val.add_theme_color_override("font_color", UI.MUTED if x <= 0 else UI.GOLD)
		UI.apply_volumes()
		if key == "vol_music" and x > 0 and UI.now_playing() < 0:
			UI.music(true), true)
	sl.custom_minimum_size = Vector2(0, 40)
	sl.drag_ended.connect(func(_c):
		G.save_settings()
		if key == "vol_sfx":
			UI.sfx("open", -10.0))
	v.add_child(sl)


func _audio(row: Control):
	var pn = pane(300, 4)
	var v = pn[1]
	row.add_child(pn[0])
	_head(v, "Volume")
	_vol(v, "Music", "vol_music")
	_vol(v, "Effects", "vol_sfx")
	_vol(v, "Match crowd", "vol_crowd")
	v.add_child(UI.sp(0, 4))
	_head(v, "Play order")
	var sh = 1 if G.settings.get("shuffle", false) else 0
	v.add_child(UI.seg(["In order", "Shuffle"], sh, func(i):
		_put("shuffle", i == 1)
		refresh(), 19, 5))
	v.add_child(UI.sp(0, 4))
	_head(v, "Intro film")
	var it = 0 if G.settings.get("intro", true) else 1
	v.add_child(UI.seg(["Play at start", "Skip it"], it, func(i):
		_put("intro", i == 0)
		refresh(), 19, 5))


# ---------------------------------------------------------------- soundtrack

func _soundtrack(row: Control):
	var pn = pane(0, 4)
	var v = pn[1]
	row.add_child(pn[0])
	songs_box = UI.vb(4)
	v.add_child(songs_box)
	_fill_songs()


func _fill_songs():
	if songs_box == null or not is_instance_valid(songs_box):
		return
	for c in songs_box.get_children():
		songs_box.remove_child(c)
		c.queue_free()
	var tr = UI.songs()
	var now = UI.now_playing()
	var h = UI.hb(8)
	h.add_child(UI.caps("Soundtrack", 16, UI.accent))
	h.add_child(UI.sp())
	h.add_child(UI.caps("Tap a song to play it  ·  tick = in rotation", 14, UI.DIM))
	songs_box.add_child(h)
	if tr.is_empty():
		songs_box.add_child(UI.wrap("No music is installed in this build.", 20, UI.MUTED))
		return
	for i in tr.size():
		var sg = tr[i]
		var on = UI.song_on(sg.id)
		var playing = i == now
		var r = UI.panel(Color(UI.accent, 0.16) if playing else Color(1, 1, 1, 0.035), 10, 10, 5, Color(UI.accent, 0.55) if playing else Color(0, 0, 0, 0))
		var rh = UI.hb(10)
		rh.add_child(UI.icon("pause" if playing else "play", 20, UI.accent if playing else UI.MUTED))
		var nm = UI.lbl_fill(sg.title, 21, UI.TEXT if on or playing else UI.DIM, "semi")
		rh.add_child(nm)
		if playing:
			rh.add_child(UI.caps("Playing", 14, UI.accent))
		rh.add_child(UI.lbl(sg.len, 18, UI.MUTED, "cond"))
		var tk = UI.panel(Color(UI.GREEN, 0.16) if on else Color(1, 1, 1, 0.05), 8, 8, 4)
		tk.add_child(UI.icon("check" if on else "x", 18, UI.GREEN if on else UI.DIM))
		var id = sg.id
		UI.tap(tk, func(): _toggle_song(id), true)
		rh.add_child(tk)
		r.add_child(rh)
		var idx = i
		UI.tap(r, func():
			if idx == UI.now_playing():
				_put("vol_music", G.settings.get("vol_music", 70))
				UI.music_pl.stop()
				UI.song_changed.emit()
			else:
				UI.music_play(idx))
		songs_box.add_child(r)


func _toggle_song(id: String):
	var off: Array = G.settings.get("songs_off", []).duplicate()
	if id in off:
		off.erase(id)
	else:
		if off.size() >= UI.songs().size() - 1:
			UI.toast("Keep at least one song in the rotation", UI.AMBER)
			return
		off.append(id)
	_put("songs_off", off)
	_fill_songs()


# ---------------------------------------------------------------- look and game

func _look(row: Control):
	var pn = pane(330, 4)
	var v = pn[1]
	row.add_child(pn[0])
	_head(v, "Skin")
	var cur = UI.skin().id
	for k in UI.SKINS:
		var on = k.id == cur
		var r = UI.panel(Color(UI.accent, 0.16) if on else Color(1, 1, 1, 0.035), 10, 10, 5, Color(UI.accent, 0.55) if on else Color(0, 0, 0, 0))
		var h = UI.hb(8)
		for col in [k.bg, k.card2, k.brand]:
			var dot = UI.panel(Color(col), 6, 0, 0, Color(1, 1, 1, 0.18))
			dot.custom_minimum_size = Vector2(18, 18)
			dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			h.add_child(dot)
		h.add_child(UI.lbl(k.name, 20, UI.TEXT, "semi"))
		h.add_child(UI.lbl_fill(k.sub, 16, UI.MUTED))
		if on:
			h.add_child(UI.icon("check", 18, UI.accent))
		r.add_child(h)
		var id = k.id
		UI.tap(r, func():
			_put("skin", id)
			UI.main.reskin())
		v.add_child(r)
	v.add_child(UI.sp(0, 2))
	_head(v, "Accent colour")
	v.add_child(UI.seg(["From skin", "My club's"], 1 if G.settings.get("club_accent", false) else 0, func(i):
		_put("club_accent", i == 1)
		UI.main.reskin(), 19, 5))
	v.add_child(UI.sp(0, 2))
	_head(v, "Currency  ·  €1 = £0.85 = $1.15")
	var curs = ["€", "£", "$"]
	v.add_child(UI.seg(curs, max(0, curs.find(G.settings.get("cur", "€"))), func(i):
		_put("cur", curs[i])
		refresh(), 19, 5))
	v.add_child(UI.sp(0, 2))
	_head(v, "Match speed at kick-off")
	v.add_child(UI.seg(["1x", "2x", "4x", "Key"], int(G.settings.get("speed", 0)), func(i):
		_put("speed", i)
		refresh(), 19, 5))

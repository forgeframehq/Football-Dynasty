extends Node
# Design system: colours, fonts and widget factories shared by every screen.

const BADGE = preload("res://scripts/widgets/badge.gd")
const BAR = preload("res://scripts/widgets/bar.gd")
const FLAG = preload("res://scripts/widgets/flag.gd")

# The default look comes from the Football Dynasty 26 logo: deep purple-navy surfaces, a purple accent,
# gold for highlights. Settings offers other skins; these seven are the colours a skin changes.
var BG: Color = Color("0a0816")
var BG2: Color = Color("110d22")
var CARD: Color = Color("17132b")
var CARD2: Color = Color("201a3b")
var BRAND: Color = Color("9a5cff")
var MUTED: Color = Color("958fb0")
var DIM: Color = Color("625c82")
var RAIL: Color = Color("0b0919")
const SKINS = [
	{"id": "dynasty", "name": "Dynasty", "sub": "Purple, gold", "bg": "0a0816", "bg2": "110d22", "card": "17132b", "card2": "201a3b", "brand": "9a5cff", "muted": "958fb0", "dim": "625c82", "rail": "0b0919"},
	{"id": "midnight", "name": "Midnight", "sub": "Navy and blue", "bg": "070b15", "bg2": "0c1220", "card": "121a2c", "card2": "1b2640", "brand": "4da3ff", "muted": "8c98b0", "dim": "5a657c", "rail": "080d18"},
	{"id": "pitch", "name": "Pitch", "sub": "Dark green", "bg": "06110c", "bg2": "0a1912", "card": "10231a", "card2": "183326", "brand": "2ee59d", "muted": "8aa89a", "dim": "587265", "rail": "07140e"},
	{"id": "crimson", "name": "Crimson", "sub": "Deep red", "bg": "130608", "bg2": "1c0a0e", "card": "271016", "card2": "381720", "brand": "ff5c72", "muted": "b0909a", "dim": "7c5c66", "rail": "16070a"},
	{"id": "graphite", "name": "Graphite", "sub": "Black, gold", "bg": "0b0b0d", "bg2": "121215", "card": "1a1a1f", "card2": "26262d", "brand": "e9c46a", "muted": "9a9aa6", "dim": "66666f", "rail": "0d0d10"},
]
const LINE = Color(1, 1, 1, 0.07)
const TEXT = Color("f3f6fb")
const GOLD = Color("e9c46a")
const GREEN = Color("2ee59d")
const RED = Color("ff5c72")
const AMBER = Color("f6ad3c")
const BLUE = Color("4da3ff")
const LINE_COL = [Color("f6ad3c"), Color("4da3ff"), Color("2ee59d"), Color("ff6b81")]

var accent: Color = Color("9a5cff")
var fonts: Dictionary = {}
var icon_src: Dictionary = {}
var icon_cache: Dictionary = {}
var main = null
var players: Dictionary = {}


func _ready():
	fonts = {
		"body": load("res://assets/fonts/Barlow-Medium.ttf"),
		"semi": load("res://assets/fonts/Barlow-SemiBold.ttf"),
		"bold": load("res://assets/fonts/Barlow-Bold.ttf"),
		"cond": load("res://assets/fonts/BarlowCondensed-SemiBold.ttf"),
		"disp": load("res://assets/fonts/BarlowCondensed-Bold.ttf"),
		"xbold": load("res://assets/fonts/BarlowCondensed-ExtraBold.ttf"),
	}
	var f = FileAccess.open("res://data/icons.json", FileAccess.READ)
	if f != null:
		icon_src = JSON.parse_string(f.get_as_text())
		f.close()


signal song_changed

# The soundtrack. Each entry is [file name in assets/music, title, length].
const SONGS = [
	["golden_hour", "Golden Hour", "4:37"],
	["fever_dream", "Fever Dream", "4:22"],
	["hands_up_tonight", "Hands Up Tonight", "4:04"],
	["running_in_colour", "Running in Colour", "3:48"],
	["after_the_lights", "After the Lights", "4:46"],
	["we_own_the_night", "We Own the Night", "4:40"],
	["no_saints", "No Saints", "4:47"],
]
var music_pl: AudioStreamPlayer = null
var music_i := 0
var song_cache: Array = []
var song_cached := false


func skin() -> Dictionary:
	var id = G.settings.get("skin", "dynasty")
	for k in SKINS:
		if k.id == id:
			return k
	return SKINS[0]


func apply_skin():
	var k = skin()
	BG = Color(k.bg)
	BG2 = Color(k.bg2)
	CARD = Color(k.card)
	CARD2 = Color(k.card2)
	BRAND = Color(k.brand)
	MUTED = Color(k.muted)
	DIM = Color(k.dim)
	RAIL = Color(k.rail)
	apply_accent()


func apply_accent():
	# the accent is the skin's colour, or the club's own colour when that option is on
	accent = BRAND
	if G.settings.get("club_accent", false) and G.active and G.s.has("user"):
		var c = G.uc()
		if c is Dictionary and c.has("c1"):
			var col = Color(c.c1)
			if col.get_luminance() < 0.16 and c.has("c2"):
				col = Color(c.c2)
			if col.get_luminance() < 0.16:
				col = col.lightened(0.45)
			accent = col


var in3d := 0        # how many 3D views are on screen


func apply_perf():
	# Frame rate and idle behaviour, to keep the phone cool. "fps": 0 automatic (60 on menus, 30 while a 3D
	# view is showing), 1 always 30, 2 always 60. Battery saver lets the screen idle when nothing is moving.
	var mode = int(G.settings.get("fps", 0))
	Engine.max_fps = 30 if (mode == 1 or (mode == 0 and in3d > 0)) else 60
	OS.low_processor_usage_mode = bool(G.settings.get("saver", true)) and in3d == 0


func enter3d(on: bool):
	in3d = max(0, in3d + (1 if on else -1))
	apply_perf()


func vol_db(key: String, full_db: float) -> float:
	# sliders run 0-100; the default of 70 sits about 3 dB under full
	var v = float(G.settings.get(key, 70))
	if v <= 0.0:
		return -80.0
	return full_db + linear_to_db(v / 100.0)


func songs() -> Array:
	# every track shipped with the game: the named soundtrack, then any extra track_N.mp3 files
	if song_cached:
		return song_cache
	song_cached = true
	for sg in SONGS:
		var path = "res://assets/music/%s.mp3" % sg[0]
		if ResourceLoader.exists(path):
			song_cache.append({"id": sg[0], "title": sg[1], "len": sg[2], "path": path})
	for i in range(1, 13):
		var p2 = "res://assets/music/track_%d.mp3" % i
		if ResourceLoader.exists(p2):
			song_cache.append({"id": "track_%d" % i, "title": "Track %d" % i, "len": "", "path": p2})
	return song_cache


func song_on(id: String) -> bool:
	return not (id in G.settings.get("songs_off", []))


func music_tracks() -> Array:
	return songs()


func music_on() -> bool:
	return G.settings.get("music", true) and float(G.settings.get("vol_music", 70)) > 0.0


func now_playing() -> int:
	# index into songs() of the track playing, or -1
	if music_pl == null or not music_pl.playing or songs().is_empty():
		return -1
	return music_i % songs().size()


func _music_pl() -> AudioStreamPlayer:
	if music_pl == null:
		music_pl = AudioStreamPlayer.new()
		add_child(music_pl)
		music_pl.finished.connect(func(): music_step(1))
	return music_pl


var music_tw: Tween = null
var ducked := false


func _fade_to(db: float, t: float, then := Callable()):
	# glide the music volume; used for every start, stop and the match duck
	if music_pl == null:
		return
	if music_tw != null and music_tw.is_valid():
		music_tw.kill()
	music_tw = create_tween()
	music_tw.tween_property(music_pl, "volume_db", db, t)
	if then.is_valid():
		music_tw.tween_callback(then)


func _start_song(path: String):
	var pl = _music_pl()
	pl.stream = load(path)
	pl.volume_db = -50.0
	pl.stream_paused = false
	pl.play()
	if ducked:
		pl.stream_paused = true
	else:
		_fade_to(vol_db("vol_music", -17.0), 1.6)
	song_changed.emit()


func music_duck(on: bool):
	# matches: the soundtrack fades away at kick-off and returns afterwards
	ducked = on
	if music_pl == null or not music_pl.playing:
		return
	if on:
		_fade_to(-50.0, 1.4, func(): music_pl.stream_paused = true)
	else:
		music_pl.stream_paused = false
		_fade_to(vol_db("vol_music", -17.0), 2.2)


var first_song := true


func _launch_song(tr: Array):
	# each launch opens on a different song: the one after last launch's opener (or a random other one on shuffle)
	first_song = false
	var live = []
	for i in tr.size():
		if song_on(tr[i].id):
			live.append(i)
	if live.is_empty():
		return
	var last = str(G.settings.get("last_song", ""))
	var li = -1
	for i in tr.size():
		if tr[i].id == last:
			li = i
	var nxt = live[0]
	if G.settings.get("shuffle", false) and live.size() > 1:
		nxt = live[randi() % live.size()]
		while nxt == li:
			nxt = live[randi() % live.size()]
	elif li >= 0:
		for k in range(1, tr.size() + 1):
			var j = posmod(li + k, tr.size())
			if j in live:
				nxt = j
				break
	music_i = nxt
	G.settings["last_song"] = tr[nxt].id
	G.save_settings()


func music(on: bool):
	var tr = songs()
	if tr.is_empty():
		return
	var pl = _music_pl()
	if on and music_on():
		if not pl.playing:
			if first_song:
				_launch_song(tr)
			music_i = posmod(music_i, tr.size())
			if not song_on(tr[music_i].id):
				music_step(1)
				return
			_start_song(tr[music_i].path)
	elif pl.playing:
		_fade_to(-50.0, 0.8, func():
			pl.stop()
			song_changed.emit())


func music_play(i: int):
	# play one named track now, whether or not it is in the rotation
	var tr = songs()
	if tr.is_empty():
		return
	G.settings["music"] = true
	if float(G.settings.get("vol_music", 70)) <= 0.0:
		G.settings["vol_music"] = 70
	G.save_settings()
	music_i = posmod(i, tr.size())
	_start_song(tr[music_i].path)


func music_step(dir: int):
	# next or previous track in the rotation; shuffle picks any other enabled track
	var tr = songs()
	var live = []
	for i in tr.size():
		if song_on(tr[i].id):
			live.append(i)
	if live.is_empty() or not music_on():
		if music_pl != null:
			music_pl.stop()
		song_changed.emit()
		return
	var cur = posmod(music_i, tr.size())
	var nxt = live[0]
	if G.settings.get("shuffle", false) and live.size() > 1:
		nxt = cur
		while nxt == cur:
			nxt = live[randi() % live.size()]
	else:
		for k in range(1, tr.size() + 1):
			var j = posmod(cur + k * dir, tr.size())
			if j in live:
				nxt = j
				break
	music_i = nxt
	var pl = _music_pl()
	if pl.playing and not ducked:
		_fade_to(-50.0, 0.5, func(): _start_song(tr[nxt].path))
	else:
		_start_song(tr[nxt].path)


func apply_volumes():
	if music_pl != null:
		if not ducked and (music_tw == null or not music_tw.is_running()):
			music_pl.volume_db = vol_db("vol_music", -17.0)
		if not music_on() and music_pl.playing:
			music_pl.stop()
			song_changed.emit()
	if players.has("crowd"):
		players["crowd"].volume_db = vol_db("vol_crowd", -13.0)
		if not G.settings.get("sound", true):
			players["crowd"].stop()


func _stream(nm: String):
	for ext in ["mp3", "wav"]:
		var path = "res://assets/sfx/%s.%s" % [nm, ext]
		if ResourceLoader.exists(path):
			return load(path)
	return null


func sfx(nm: String, db := -6.0):
	if not G.settings.get("sound", true) or nm == "sting_news":
		return
	if nm.begins_with("vo_") and not G.settings.get("voice", true):
		return
	if not players.has(nm):
		var st = _stream(nm)
		if st == null:
			return
		var pl = AudioStreamPlayer.new()
		pl.stream = st
		add_child(pl)
		players[nm] = pl
	var d = vol_db("vol_sfx", db + 3.0)
	if d <= -79.0:
		return
	players[nm].volume_db = d
	players[nm].play()


func ambience(on: bool):
	if not players.has("crowd"):
		var st = _stream("crowd")
		if st == null:
			return
		if st is AudioStreamMP3:
			st.loop = true
		elif st is AudioStreamWAV:
			st.loop_mode = AudioStreamWAV.LOOP_FORWARD
			st.loop_begin = 0
			st.loop_end = int(st.get_length() * st.mix_rate)
		var pl = AudioStreamPlayer.new()
		pl.stream = st
		add_child(pl)
		players["crowd"] = pl
	players["crowd"].volume_db = vol_db("vol_crowd", -13.0)
	if on and G.settings.get("sound", true) and float(G.settings.get("vol_crowd", 70)) > 0.0:
		if not players["crowd"].playing:
			players["crowd"].play()
	else:
		players["crowd"].stop()


func set_accent_from(_c: Dictionary):
	# kept for callers; the accent follows the skin (or the club, if that option is on)
	apply_accent()


func on_color(c: Color) -> Color:
	return Color("0a0e17") if c.get_luminance() > 0.45 else Color.WHITE


# ---------------------------------------------------------------- basic nodes

func lbl(text, size := 24, color := TEXT, font := "body") -> Label:
	var l = Label.new()
	l.text = str(text)
	l.add_theme_font_override("font", fonts[font])
	l.add_theme_font_size_override("font_size", max(int(size), 14))   # nothing smaller than 14: it has to read on a phone
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func lbl_fill(text, size := 24, color := TEXT, font := "body") -> Label:
	# label that takes the remaining row width and truncates with an ellipsis
	var l = lbl(text, size, color, font)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.clip_text = true
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return l


func wrap(text, size := 24, color := TEXT, font := "body") -> Label:
	var l = lbl(text, size, color, font)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func caps(text, size := 20, color := MUTED) -> Label:
	var l = lbl(str(text).to_upper(), size, color, "cond")
	l.add_theme_constant_override("outline_size", 0)
	return l


func vb(sep := 12) -> VBoxContainer:
	var b = VBoxContainer.new()
	b.add_theme_constant_override("separation", sep)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


func hb(sep := 12) -> HBoxContainer:
	var b = HBoxContainer.new()
	b.add_theme_constant_override("separation", sep)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.alignment = BoxContainer.ALIGNMENT_BEGIN
	return b


func sp(w := 0, h := 0) -> Control:
	var c = Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if w == 0 and h == 0:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	else:
		c.custom_minimum_size = Vector2(w, h)
	return c


func sbox(color: Color, radius := 22, border := Color(0, 0, 0, 0), bw := 1) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.corner_detail = 10
	sb.anti_aliasing = true
	if border.a > 0:
		sb.border_color = border
		sb.set_border_width_all(bw)
	return sb


func panel(color: Color, radius := 22, pad_h := 22, pad_v := 20, border := Color(0, 0, 0, 0)) -> PanelContainer:
	var p = PanelContainer.new()
	var sb = sbox(color, radius, border)
	sb.content_margin_left = pad_h
	sb.content_margin_right = pad_h
	sb.content_margin_top = pad_v
	sb.content_margin_bottom = pad_v
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


func card(pad_h := 22, pad_v := 20) -> PanelContainer:
	return panel(CARD, 24, pad_h, pad_v, LINE)


func margin(node: Control, l := 24, t := 0, r := 24, b := 0) -> MarginContainer:
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", l)
	m.add_theme_constant_override("margin_right", r)
	m.add_theme_constant_override("margin_top", t)
	m.add_theme_constant_override("margin_bottom", b)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(node)
	return m


func center(node: Control) -> CenterContainer:
	var c = CenterContainer.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(node)
	return c


func scroll(inner: Control) -> ScrollContainer:
	var s = ScrollContainer.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.add_child(inner)
	return s


func tap(c: Control, cb: Callable, stop := false):
	c.set_meta("tap", true)
	c.mouse_filter = Control.MOUSE_FILTER_STOP if stop else Control.MOUSE_FILTER_PASS
	c.set_meta("tp", null)
	c.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				c.set_meta("tp", e.global_position)
				c.modulate = Color(1, 1, 1, 0.65)
			else:
				var st = c.get_meta("tp")
				c.set_meta("tp", null)
				c.modulate = Color.WHITE
				if st != null and st.distance_to(e.global_position) < 22:
					sfx("click", -16.0)
					cb.call())
	c.mouse_exited.connect(func(): c.modulate = Color.WHITE)


func icon(nm: String, size := 28, color := TEXT) -> TextureRect:
	var t = TextureRect.new()
	if not icon_cache.has(nm) and icon_src.has(nm):
		var img = Image.new()
		if img.load_svg_from_string(icon_src[nm], 3.0) == OK:
			icon_cache[nm] = ImageTexture.create_from_image(img)
	t.texture = icon_cache.get(nm, null)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(size, size)
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	t.modulate = color
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


# ---------------------------------------------------------------- composite widgets

func btn(text: String, cb: Callable, kind := "primary", icon_name := "", height := 66) -> PanelContainer:
	var bg = accent
	var fg = on_color(accent)
	var border = Color(0, 0, 0, 0)
	if kind == "secondary":
		bg = CARD2
		fg = TEXT
		border = Color(1, 1, 1, 0.1)
	elif kind == "ghost":
		bg = Color(1, 1, 1, 0.04)
		fg = MUTED
	elif kind == "danger":
		bg = Color(RED, 0.16)
		fg = RED
		border = Color(RED, 0.4)
	elif kind == "gold":
		bg = GOLD
		fg = Color("0a0e17")
	var p = panel(bg, 20, 22, 0, border)
	p.custom_minimum_size = Vector2(0, height)
	var h = hb(10)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	if icon_name != "":
		h.add_child(icon(icon_name, 30, fg))
	var l = lbl(text.to_upper(), 30 if height >= 80 else 24, fg, "disp")
	h.add_child(l)
	p.add_child(h)
	tap(p, cb, true)
	return p


func chip(text: String, bg: Color, fg: Color, size := 20, minw := 0) -> PanelContainer:
	var p = panel(bg, 10, 10, 3)
	var l = lbl(text, size, fg, "disp")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	if minw > 0:
		p.custom_minimum_size = Vector2(minw, 0)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return p


func ovr_color(v: int) -> Color:
	if v >= 85: return GOLD
	if v >= 78: return GREEN
	if v >= 70: return Color("b6e354")
	if v >= 62: return AMBER
	return Color("f08a5d")


func ovr(v: int, size := 26) -> PanelContainer:
	var c = ovr_color(v)
	var p = chip(str(v), Color(c, 0.16), c, size, int(size * 2.1))
	p.get_theme_stylebox("panel").border_color = Color(c, 0.45)
	p.get_theme_stylebox("panel").set_border_width_all(1)
	return p


func pos(pos_name: String, size := 20) -> PanelContainer:
	var c = LINE_COL[G.LINE.get(pos_name, 2)]
	return chip(pos_name, Color(c, 0.14), c, size, int(size * 2.9))


func badge(c: Dictionary, size := 64) -> Control:
	var b = BADGE.new()
	b.setup(c, size)
	return b


func trophy(title: String, h := 96.0) -> Control:
	# picture for a trophy, chosen from its name; falls back to the icon
	var n = 5
	if title.contains("Champions League"):
		n = 6
	elif title.contains("Europa"):
		n = 7
	elif title.contains("Conference"):
		n = 3
	elif title.contains("League Cup") or title.contains("EFL"):
		n = 3
	elif title.contains("Cup") or title.contains("Copa") or title.contains("Coppa") or title.contains("Pokal") or title.contains("Coupe"):
		n = 2
	elif title.contains("Golden Boot"):
		n = 8
	elif title.contains("Player of"):
		n = 9
	elif title.contains("Manager of"):
		n = 10
	var path = "res://assets/trophies/trophy_%02d.png" % n
	if not ResourceLoader.exists(path):
		return icon("trophy", int(h * 0.6), GOLD)
	var t = TextureRect.new()
	t.texture = load(path)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(h, h)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


func flag(nat: String, w := 34.0) -> Control:
	var f = FLAG.new()
	f.setup(nat, w)
	return f


func bar(frac: float, color: Color, h := 8, bg := Color(1, 1, 1, 0.08)) -> Control:
	var b = BAR.new()
	b.frac = clamp(frac, 0.0, 1.0)
	b.color = color
	b.bg = bg
	b.custom_minimum_size = Vector2(40, h)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


func cond_color(v: float) -> Color:
	if v >= 80: return GREEN
	if v >= 60: return AMBER
	return RED


func seg(options: Array, sel: int, cb: Callable, size := 22, vpad := 9) -> PanelContainer:
	var p = panel(Color(1, 1, 1, 0.05), 16 if vpad >= 9 else 10, 5 if vpad >= 9 else 3, 5 if vpad >= 9 else 3)
	var h = hb(4)
	for i in options.size():
		var on = i == sel
		var it = panel(accent if on else Color(0, 0, 0, 0), 12 if vpad >= 9 else 8, 8 if vpad >= 9 else 4, vpad)
		it.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var l = lbl(str(options[i]).to_upper(), size, on_color(accent) if on else MUTED, "disp")
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		it.add_child(l)
		var idx = i
		tap(it, func(): cb.call(idx), true)
		h.add_child(it)
	p.add_child(h)
	return p


func section(text: String, right := "") -> HBoxContainer:
	var h = hb(8)
	h.set_meta("glue", true)
	h.add_child(caps(text, 22, MUTED))
	h.add_child(sp())
	if right != "":
		h.add_child(caps(right, 20, DIM))
	return h


func stat_tile(label: String, value: String, color := TEXT) -> PanelContainer:
	var p = panel(Color(1, 1, 1, 0.04), 16, 14, 12)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v = vb(0)
	var a = lbl(value, 34, color, "disp")
	a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var b = caps(label, 17, MUTED)
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(a)
	v.add_child(b)
	p.add_child(v)
	return p


func kv(k: String, v: String, vc := TEXT, size := 23) -> HBoxContainer:
	var h = hb(8)
	h.add_child(lbl(k, size, MUTED))
	h.add_child(sp())
	h.add_child(lbl(v, size, vc, "semi"))
	return h


func divider() -> ColorRect:
	var r = ColorRect.new()
	r.color = LINE
	r.custom_minimum_size = Vector2(0, 1)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func form_dots(form: Array, size := 14) -> HBoxContainer:
	var h = hb(5)
	for r in form:
		var c = GREEN if r == "W" else (RED if r == "L" else DIM)
		var d = panel(c, size / 2, 0, 0)
		d.custom_minimum_size = Vector2(size, size)
		d.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(d)
	return h


func player_row(p: Dictionary, cb: Callable, extra := "") -> PanelContainer:
	# standard list row: position, name, meta line, overall
	var row = panel(CARD, 18, 16, 12, LINE)
	var h = hb(14)
	h.add_child(pos(p.pos))
	var v = vb(0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var n = hb(8)
	n.add_child(lbl_fill(G.pname(p), 26, TEXT, "semi"))
	v.add_child(n)
	var meta = extra if extra != "" else "%d yrs · %s" % [G.age(p), G.money(G.value(p))]
	v.add_child(lbl_fill(meta, 20, MUTED))
	h.add_child(v)
	if p.inj > 0:
		h.add_child(icon("bandage", 24, RED))
	if p.susp > 0:
		h.add_child(icon("square", 22, RED))
	if p.listed:
		h.add_child(icon("flag", 22, AMBER))
	h.add_child(ovr(p.ovr))
	row.add_child(h)
	tap(row, cb)
	return row


func trow(cells: Array, widths: Array, opt := {}) -> PanelContainer:
	# compact table row. cells: strings or Controls; widths: px, 0 = stretch, negative = right-aligned px
	var head = opt.get("head", false)
	var hi = opt.get("hi", false)
	var r = panel(Color(accent, 0.16) if hi else Color(1, 1, 1, 0.0 if head else (0.045 if opt.get("alt", false) else 0.02)), 5, 8, opt.get("pad", 4))
	var h = hb(opt.get("sep", 6))
	var size = opt.get("size", 19)
	for i in cells.size():
		var c = cells[i]
		var w = widths[i] if i < widths.size() else 0
		var node: Control
		if c is Control:
			node = c
		else:
			var col = opt.get("cols", {}).get(i, MUTED if head else TEXT)
			var l = lbl(str(c), size - 4 if head else size, col, "semi" if head or (hi and i == opt.get("bold", -1)) else "body")
			l.clip_text = true
			l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			if w < 0:
				l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			node = l
		if w == 0:
			node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		else:
			node.custom_minimum_size = Vector2(abs(w), node.custom_minimum_size.y)
		h.add_child(node)
	r.add_child(h)
	if opt.has("tap"):
		tap(r, opt.tap)
	return r


func topbar(title: String, back := true, right: Control = null) -> Control:
	if main != null and main.uses_chrome():
		main.set_title(title, "", right)
		var z = Control.new()
		z.mouse_filter = Control.MOUSE_FILTER_IGNORE
		z.custom_minimum_size = Vector2(0, 4)
		return z
	var h = hb(12)
	h.custom_minimum_size = Vector2(0, 76)
	if back:
		var b = panel(Color(1, 1, 1, 0.06), 18, 14, 14)
		b.add_child(icon("chevron-left", 30, TEXT))
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tap(b, func(): main.back(), true)
		h.add_child(b)
	var l = lbl_fill(title.to_upper(), 40, TEXT, "xbold")
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(l)
	if right != null:
		right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(right)
	return margin(h, 24, 10, 24, 10)


func toast(text: String, color := TEXT):
	if main != null:
		main.toast(text, color)


func sheet(title: String, build: Callable):
	if main != null:
		main.open_sheet(title, build)


func close_sheet():
	if main != null:
		main.close_sheet()


func confirm(title: String, text: String, yes: String, cb: Callable, danger := false, no := Callable()):
	# no: called when the player backs out, e.g. to reopen the list they were choosing from
	var on_yes = func():
		close_sheet()
		cb.call()
	var on_no = func():
		close_sheet()
		if no.is_valid():
			no.call()
	var build = func(v):
		v.add_child(self.wrap(text, 24, MUTED))   # bare wrap() inside a lambda resolves to the built-in maths function
		v.add_child(sp(0, 8))
		v.add_child(btn(yes, on_yes, "danger" if danger else "primary"))
		v.add_child(btn("Go back" if no.is_valid() else "Cancel", on_no, "ghost", "", 68))
	sheet(title, build)


func stars(rep: float, size := 22) -> HBoxContainer:
	var n = int(round(clamp((rep - 50.0) / 7.0, 0.5, 5.0)))
	var h = hb(2)
	for i in 5:
		h.add_child(icon("star-f", size, GOLD if i < n else Color(1, 1, 1, 0.12)))
	return h


func input(text: String, placeholder: String, cb: Callable) -> LineEdit:
	var le = LineEdit.new()
	le.text = text
	le.placeholder_text = placeholder
	le.max_length = 24
	le.custom_minimum_size = Vector2(0, 80)
	le.add_theme_font_override("font", fonts["semi"])
	le.add_theme_font_size_override("font_size", 28)
	le.add_theme_color_override("font_color", TEXT)
	le.add_theme_color_override("font_placeholder_color", DIM)
	le.add_theme_color_override("caret_color", accent)
	var sb = sbox(Color(1, 1, 1, 0.05), 18, Color(1, 1, 1, 0.1))
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	le.add_theme_stylebox_override("normal", sb)
	var sf = sbox(Color(1, 1, 1, 0.07), 18, Color(accent, 0.7), 2)
	sf.content_margin_left = 22
	sf.content_margin_right = 22
	le.add_theme_stylebox_override("focus", sf)
	le.text_changed.connect(cb)
	return le


func slider(minv: float, maxv: float, value: float, step: float, cb: Callable, small := false) -> HSlider:
	var sl = HSlider.new()
	sl.min_value = minv
	sl.max_value = maxv
	sl.step = step
	sl.value = value
	sl.custom_minimum_size = Vector2(0, 64)
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var track = sbox(Color(1, 1, 1, 0.1), 6)
	track.content_margin_top = 6
	track.content_margin_bottom = 6
	sl.add_theme_stylebox_override("slider", track)
	var fill = sbox(accent, 6)
	sl.add_theme_stylebox_override("grabber_area", fill)
	sl.add_theme_stylebox_override("grabber_area_highlight", fill)
	if not icon_cache.has("_grab"):
		var img = Image.create(56, 56, false, Image.FORMAT_RGBA8)
		for y in 56:
			for x in 56:
				var d = Vector2(x - 27.5, y - 27.5).length()
				var a = clamp(26.0 - d, 0.0, 1.0)
				img.set_pixel(x, y, Color(1, 1, 1, a))
		icon_cache["_grab"] = ImageTexture.create_from_image(img)
	if small and not icon_cache.has("_grab_s"):
		# a smaller handle for dense forms, where plus and minus buttons do the fine work
		var im2 = Image.create(38, 38, false, Image.FORMAT_RGBA8)
		for y in 38:
			for x in 38:
				var d2 = Vector2(x - 18.5, y - 18.5).length()
				im2.set_pixel(x, y, Color(1, 1, 1, clamp(17.5 - d2, 0.0, 1.0)))
		icon_cache["_grab_s"] = ImageTexture.create_from_image(im2)
	var gk = "_grab_s" if small else "_grab"
	sl.add_theme_icon_override("grabber", icon_cache[gk])
	sl.add_theme_icon_override("grabber_highlight", icon_cache[gk])
	sl.value_changed.connect(cb)
	return sl


func clubbar(right: Control = null) -> Control:
	var c = G.uc()
	if main != null and main.uses_chrome():
		main.set_title(c.name, "%s · %s" % [G.s.user.name, G.s.leagues[c.lg].name], right)
		var z = Control.new()
		z.mouse_filter = Control.MOUSE_FILTER_IGNORE
		z.custom_minimum_size = Vector2(0, 4)
		return z
	var h = hb(16)
	h.add_child(badge(c, 76))
	var v = vb(0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(lbl_fill(c.name.to_upper(), 38, TEXT, "xbold"))
	v.add_child(lbl_fill("%s · %s" % [G.s.user.name, G.s.leagues[c.lg].name], 22, MUTED))
	h.add_child(v)
	if right != null:
		right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(right)
	return margin(h, 24, 8, 24, 12)

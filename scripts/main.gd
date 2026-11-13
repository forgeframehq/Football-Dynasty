extends Control
# Application shell (landscape): icon rail, slide-out menus, top bar with Continue,
# screen stack, sheets and toasts.

const SCREENS = {
	"menu": preload("res://scripts/screens/menu.gd"),
	"new_career": preload("res://scripts/screens/new_career.gd"),
	"intro": preload("res://scripts/screens/intro.gd"),
	"home": preload("res://scripts/screens/home.gd"),
	"squad": preload("res://scripts/screens/squad.gd"),
	"tactics": preload("res://scripts/screens/tactics.gd"),
	"transfers": preload("res://scripts/screens/transfers.gd"),
	"club": preload("res://scripts/screens/club.gd"),
	"player": preload("res://scripts/screens/player.gd"),
	"nego": preload("res://scripts/screens/deal.gd"),
	"life": preload("res://scripts/screens/life.gd"),
	"match": preload("res://scripts/screens/match.gd"),
	"table": preload("res://scripts/screens/table.gd"),
	"fixtures": preload("res://scripts/screens/fixtures.gd"),
	"stats": preload("res://scripts/screens/stats.gd"),
	"finances": preload("res://scripts/screens/finances.gd"),
	"board": preload("res://scripts/screens/board.gd"),
	"inbox": preload("res://scripts/screens/inbox.gd"),
	"jobs": preload("res://scripts/screens/jobs.gd"),
	"review": preload("res://scripts/screens/review.gd"),
	"clubview": preload("res://scripts/screens/clubview.gd"),
	"compare": preload("res://scripts/screens/compare.gd"),
	"comps": preload("res://scripts/screens/comps.gd"),
	"campus": preload("res://scripts/screens/campus.gd"),
	"training": preload("res://scripts/screens/training.gd"),
	"trophies": preload("res://scripts/screens/trophies.gd"),
	"scouting": preload("res://scripts/screens/scouting.gd"),
	"deadline": preload("res://scripts/screens/deadline.gd"),
	"settings": preload("res://scripts/screens/settings.gd"),
	"kit": preload("res://scripts/screens/kit.gd"),
	"lists": preload("res://scripts/screens/lists.gd"),
	"hub": preload("res://scripts/screens/hub.gd"),
	"search": preload("res://scripts/screens/search.gd"),
}
const RAIL_ICON = {"inbox": "mail", "home": "house", "club": "", "manager": "user", "world": "globe", "search": "search", "options": "settings"}
const RAIL = [["inbox", "mail"], ["home", "house"], ["club", ""], ["manager", "user"], ["world", "globe"], ["search", "search"], ["options", "settings"]]
const RAIL_W = 84
var hole := Vector2(-1, -1)   # top and bottom of the camera cut-out on the left edge, in rail units (-1 = none known)
var notch_l := 0            # width of the camera cut-out strip on the left, in viewport units
const TOP_H = 70
const NATIONS = ["England", "Spain", "Italy", "Germany", "France"]

var holder: Control
var rail: PanelContainer
var topbar: PanelContainer
var safe: MarginContainer
var overlay: Control
var glow: TextureRect
var bg: ColorRect
var stack: Array = []
var sheet_node: Control = null
var menu_node: Control = null
var menu_key := ""
var dev = null
var t_title := ""
var t_sub := ""
var t_right: Control = null
var busy := false
var press_t := 0.0
var pressing := false


func _ready():
	UI.main = self
	var ua = OS.get_cmdline_user_args()
	if "--prof" in ua:
		load("res://dev/prof.gd").run(self)
		return
	if "--tactest" in ua:
		load("res://dev/tactest.gd").run(self)
		get_tree().quit()
		return
	if "--mktest" in ua:
		load("res://dev/mktest.gd").run(self)
		get_tree().quit()
		return
	if "--selftest" in ua:
		load("res://dev/selftest.gd").run(self)
		return
	_build()
	root("menu")
	if ("--shots" in ua or "--uitest" in ua) and not ("--intro" in ua):
		UI.music(true)
	elif not _play_intro():
		UI.music(true)
	if "--uitest" in ua:
		dev = load("res://dev/uitest.gd").new()
		dev.run(self)
	if "--shots" in ua:
		dev = load("res://dev/shots.gd").new()
		dev.run(self)


# ---------------------------------------------------------------- intro film

const INTRO_PATH = "res://assets/video/intro.ogv"
const INTRO_LEN = 11.5
var intro_node: Control = null


func _play_intro() -> bool:
	# studio card, then the film, the game's title over its last shot, then the menu. Skip at any time.
	if not ResourceLoader.exists(INTRO_PATH) or not G.settings.get("intro", true):
		return false
	var o = Control.new()
	o.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	o.mouse_filter = Control.MOUSE_FILTER_STOP
	o.z_index = 100
	var black = ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	o.add_child(black)
	var ar = AspectRatioContainer.new()
	ar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ar.ratio = 736.0 / 400.0
	ar.stretch_mode = AspectRatioContainer.STRETCH_COVER
	ar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vp = VideoStreamPlayer.new()
	vp.stream = load(INTRO_PATH)
	vp.expand = true
	vp.volume_db = UI.vol_db("vol_sfx", -1.0)
	vp.modulate.a = 0.0
	vp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ar.add_child(vp)
	o.add_child(ar)
	# studio card
	var card = UI.vb(2)
	card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.grow_vertical = Control.GROW_DIRECTION_BOTH
	if ResourceLoader.exists("res://assets/forgeframe.png"):
		var sl = TextureRect.new()
		sl.texture = load("res://assets/forgeframe.png")
		sl.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sl.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sl.custom_minimum_size = Vector2(460, 420)
		sl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(sl)
	else:
		var c1 = UI.lbl("FORGEFRAME", 54, UI.TEXT, "xbold")
		c1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(c1)
	var c2 = UI.caps("presents", 18, UI.MUTED)
	c2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(c2)
	card.modulate.a = 0.0
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	o.add_child(card)
	# the title, shown over the last shot
	var wm = TextureRect.new()
	if ResourceLoader.exists("res://assets/wordmark.png"):
		wm.texture = load("res://assets/wordmark.png")
	wm.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wm.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	wm.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wm.offset_left = 240
	wm.offset_right = -240
	wm.offset_top = 90
	wm.offset_bottom = -170
	wm.modulate.a = 0.0
	wm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	o.add_child(wm)
	var skip = UI.btn("Skip", _end_intro, "ghost", "fast-forward", 46)
	skip.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	skip.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	skip.grow_vertical = Control.GROW_DIRECTION_BEGIN
	skip.offset_right = -28 - safe.get_theme_constant("margin_right")
	skip.offset_bottom = -22
	skip.offset_left = skip.offset_right - 150
	skip.offset_top = skip.offset_bottom - 46
	o.add_child(skip)
	add_child(o)
	intro_node = o
	var tw = o.create_tween()
	tw.tween_property(card, "modulate:a", 1.0, 0.5)
	tw.tween_interval(1.7)
	tw.tween_property(card, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func():
		vp.play()
		vp.modulate.a = 1.0)
	tw.tween_interval(INTRO_LEN - 3.4)
	tw.tween_property(wm, "modulate:a", 1.0, 0.9)
	tw.tween_interval(3.0)
	tw.tween_callback(_end_intro)
	return true


func play_pending_film():
	# a trophy or promotion was won: play its film once, if one has been added to the game
	if not G.active or intro_node != null:
		return
	var kind = str(G.s.user.get("film", ""))
	if kind == "":
		return
	G.s.user.erase("film")
	var path = "res://assets/video/win_%s.ogv" % kind
	if not ResourceLoader.exists(path):
		return
	var o = Control.new()
	o.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	o.mouse_filter = Control.MOUSE_FILTER_STOP
	o.z_index = 100
	var black = ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	o.add_child(black)
	var ar = AspectRatioContainer.new()
	ar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ar.ratio = 16.0 / 9.0
	ar.stretch_mode = AspectRatioContainer.STRETCH_COVER
	ar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vp = VideoStreamPlayer.new()
	vp.stream = load(path)
	vp.expand = true
	vp.volume_db = UI.vol_db("vol_sfx", -1.0)
	vp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ar.add_child(vp)
	o.add_child(ar)
	var skip = UI.btn("Skip", _end_intro, "ghost", "fast-forward", 46)
	skip.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	skip.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	skip.grow_vertical = Control.GROW_DIRECTION_BEGIN
	skip.offset_right = -28 - safe.get_theme_constant("margin_right")
	skip.offset_bottom = -22
	skip.offset_left = skip.offset_right - 150
	skip.offset_top = skip.offset_bottom - 46
	o.add_child(skip)
	add_child(o)
	intro_node = o
	UI.music(false)
	vp.finished.connect(_end_intro)
	vp.play()


func _end_intro():
	if intro_node == null or not is_instance_valid(intro_node):
		return
	var o = intro_node
	intro_node = null
	o.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw = create_tween()
	tw.tween_property(o, "modulate:a", 0.0, 0.45)
	tw.tween_callback(func():
		o.queue_free()
		UI.music(true))


func _build():
	bg = ColorRect.new()
	bg.color = UI.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	glow = TextureRect.new()
	var g = Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0.22))
	g.set_color(1, Color(1, 1, 1, 0.0))
	var gt = GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.0)
	gt.fill_to = Vector2(0.5, 1.0)
	gt.width = 128
	gt.height = 128
	glow.texture = gt
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	glow.offset_bottom = 520
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)
	safe = MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(safe)
	var frame = UI.hb(0)
	safe.add_child(frame)
	rail = UI.panel(UI.RAIL, 0, 0, 0)
	rail.custom_minimum_size = Vector2(RAIL_W, 0)
	rail.get_theme_stylebox("panel").border_color = UI.LINE
	rail.get_theme_stylebox("panel").border_width_right = 1
	frame.add_child(rail)
	var right = UI.vb(0)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.add_child(right)
	topbar = UI.panel(Color(0, 0, 0, 0), 0, 20, 0)
	topbar.custom_minimum_size = Vector2(0, TOP_H)
	right.add_child(topbar)
	holder = Control.new()
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.clip_contents = true
	right.add_child(holder)
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	_safe_area()
	get_viewport().size_changed.connect(_safe_area)


func _safe_area():
	var win = DisplayServer.window_get_size()
	var sa = DisplayServer.get_display_safe_area()
	var l = 0.0
	var r = 0.0
	var t = 0.0
	var b = 0.0
	if OS.has_feature("mobile") and win.x > 0 and sa.size.x > 0:
		var k = size.y / float(win.y)
		l = max(0.0, sa.position.x * k)
		r = max(0.0, (win.x - sa.end.x) * k)
		t = max(0.0, sa.position.y * k)
		b = max(0.0, (win.y - sa.end.y) * k)
	hole = Vector2(-1, -1)
	if l > 16 and win.y > 0:
		var k2 = size.y / float(win.y)
		for rc in DisplayServer.get_display_cutouts():
			if rc.position.x < win.x * 0.2 and rc.size.y > 0:
				hole = Vector2(rc.position.y * k2 - t - 8, rc.end.y * k2 - t + 8)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("notch="):
			l = float(arg.substr(6))      # dev: pretend there is a camera cut-out on the left
			if hole.x < 0:
				hole = Vector2(272, 348)
		if arg.begins_with("hole="):
			var hp = arg.substr(5).split("-")
			hole = Vector2(float(hp[0]), float(hp[1]))
	# with the rail showing, its background runs under the camera cut-out and only the icons stay clear of it
	notch_l = int(l)
	_apply_left()
	safe.add_theme_constant_override("margin_right", int(r))
	safe.add_theme_constant_override("margin_top", int(t))
	safe.add_theme_constant_override("margin_bottom", int(b))


func rail_wide() -> bool:
	# a long notch (or a cut-out we cannot locate) leaves no room for icons beside it: they sit to its right.
	# A small camera hole does: the icons use the whole strip and simply skip the hole.
	return notch_l > 16 and (hole.x < 0 or hole.y - hole.x > 190)


func rail_col() -> int:
	return 66 if rail_wide() else rail_w()


func rail_w() -> int:
	if rail_wide():
		return notch_l + 66
	return max(RAIL_W, notch_l + 6) if notch_l > 16 else RAIL_W


func _apply_left():
	if safe == null or rail == null:
		return
	safe.add_theme_constant_override("margin_left", 0 if rail.visible else notch_l)
	if int(rail.custom_minimum_size.x) != rail_w():
		rail.custom_minimum_size = Vector2(rail_w(), 0)
		if rail.visible and uses_chrome():
			_build_rail()


func _notification(what):
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		back()
	elif what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if G.active and (stack.size() == 0 or stack[-1].sname != "match"):
			G.save_game()


func _process(dt):
	if pressing:
		press_t += dt
		if press_t > 0.65:
			pressing = false
			press_t = 0.0
			_continue(true)


func _mk(sname: String, args: Dictionary) -> Control:
	var scr = SCREENS[sname].new()
	scr.args = args
	scr.sname = sname
	return scr


func _enter(scr: Control, dx := 26.0):
	# short slide-and-fade when a screen appears
	scr.modulate.a = 0.0
	var tw = create_tween().set_parallel(true)
	tw.tween_property(scr, "modulate:a", 1.0, 0.16)
	scr.position.x = dx
	tw.tween_property(scr, "position:x", 0.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func uses_chrome() -> bool:
	return G.active and stack.size() > 0 and stack[-1].chrome


func set_title(title: String, sub := "", right: Control = null):
	t_title = title
	t_sub = sub
	t_right = right


func root(sname: String, args := {}):
	close_sheet()
	close_menu()
	for old in stack:
		old.queue_free()
	stack = []
	t_right = null
	var scr = _mk(sname, args)
	stack.append(scr)
	holder.add_child(scr)
	_enter(scr, 0.0)
	_update_chrome()


func open(sname: String, args := {}):
	close_sheet()
	close_menu()
	if stack.size() > 0:
		stack[-1].visible = false
	t_right = null
	var scr = _mk(sname, args)
	stack.append(scr)
	holder.add_child(scr)
	_enter(scr)
	_update_chrome()


func back():
	if intro_node != null:
		_end_intro()
		return
	if sheet_node != null:
		close_sheet()
		return
	if menu_node != null:
		close_menu()
		return
	if stack.size() == 0:
		return
	if stack[-1].has_method("can_leave") and not stack[-1].can_leave():
		return
	if stack.size() <= 1:
		var nm = stack[-1].sname
		if nm == "menu":
			get_tree().quit()
		elif nm == "home":
			UI.confirm("Leave the game?", "Your career is saved automatically.", "Save & exit to menu", func():
				G.save_game()
				G.active = false
				root("menu"))
		elif G.active:
			root("home")
		return
	var top = stack.pop_back()
	top.queue_free()
	t_right = null
	stack[-1].visible = true
	stack[-1].on_resume()
	_update_chrome()


func tab(sname: String):
	root(sname)


func refresh_nav():
	_update_chrome()


# ---------------------------------------------------------------- chrome

func _clear(n: Node):
	for c in n.get_children():
		n.remove_child(c)
		c.queue_free()


func reskin():
	# a new skin or accent was chosen: recolour the frame and redraw what is on screen
	UI.apply_skin()
	bg.color = UI.BG
	rail.get_theme_stylebox("panel").bg_color = UI.RAIL
	if stack.size() > 0:
		stack[-1].refresh()
	_update_chrome()


func _update_chrome():
	UI.apply_accent()
	glow.modulate = UI.accent
	var on = uses_chrome()
	rail.visible = on
	topbar.visible = on
	_apply_left()
	if not on:
		return
	_build_rail()
	_build_top()


func _rail_key() -> String:
	if menu_key != "":
		return menu_key
	if stack.size() == 0:
		return ""
	var nm = stack[0].sname
	var groups = {"inbox": ["inbox"], "home": ["home"],
		"club": ["squad", "tactics", "training", "fixtures", "finances", "campus", "lists", "kit"],
		"manager": ["board", "trophies", "jobs", "life"], "world": ["table", "comps", "stats", "clubview"],
		"search": ["search", "transfers", "scouting", "player", "nego", "compare"]}
	if nm == "lists" or nm == "hub" or nm == "settings":
		return str(stack[0].args.get("grp", "club"))
	for k in groups:
		if nm in groups[k]:
			return k
	return ""


const RAIL_LABEL = {"inbox": "Inbox", "home": "Home", "club": "Club", "manager": "You", "world": "World", "search": "Market", "options": "Settings"}
const RAIL_GROUPS = [["inbox", "home"], ["club", "manager"], ["world", "search"]]   # Settings sits alone at the bottom


func _build_rail():
	# laid out by hand so the icons can use the strip beside the camera and step over the hole itself
	_clear(rail)
	var lay = Control.new()
	lay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rail.add_child(lay)
	var cur = _rail_key()
	var w = rail_w()
	var pad_l = notch_l if rail_wide() else 0
	var H = size.y - safe.get_theme_constant("margin_top") - safe.get_theme_constant("margin_bottom")
	var h0 = hole.x if not rail_wide() and hole.x >= 0 else -1.0
	var h1 = hole.y if h0 >= 0 else -1.0
	var back_h = 46.0
	var div_h = 11.0
	var cell = clamp(floor((H - back_h - div_h * RAIL_GROUPS.size() - (h1 - h0 if h0 >= 0 else 0.0)) / 7.0), 44.0, 64.0)
	var labels = cell >= 56.0
	var step = func(y: float, h: float) -> float:
		# the first position at or below y where something h tall clears the camera
		return h1 if h0 >= 0 and y < h1 and y + h > h0 else y
	var y = step.call(0.0, back_h)
	var bk = Control.new()
	bk.position = Vector2(pad_l, y)
	bk.size = Vector2(w - pad_l, back_h)
	var can_back = stack.size() > 1 or (stack.size() == 1 and stack[0].sname != "home")
	var bi = UI.center(UI.icon("chevron-left", 32, UI.TEXT if can_back else UI.DIM))
	bi.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bk.add_child(bi)
	UI.tap(bk, back, true)
	lay.add_child(bk)
	y += back_h
	var n = G.unread()
	var place = func(key: String, at: float):
		var sel = key == cur
		var c = Control.new()
		c.position = Vector2(pad_l, at)
		c.size = Vector2(w - pad_l, cell)
		var pill = UI.panel(Color(UI.accent, 0.95) if sel else Color(0, 0, 0, 0), 14, 0, 0)
		pill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		pill.offset_left = 7
		pill.offset_right = -7
		pill.offset_top = 2
		pill.offset_bottom = -2
		pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var fg = UI.on_color(UI.accent) if sel else (UI.MUTED if key == "options" else UI.TEXT)
		var iv = UI.vb(-1)
		iv.alignment = BoxContainer.ALIGNMENT_CENTER
		var isz = 30 if labels else 32
		var ic: Control = UI.badge(G.uc(), isz + 6) if key == "club" else UI.icon(RAIL_ICON[key], isz, fg)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		iv.add_child(ic)
		if labels:
			var lb = UI.caps(RAIL_LABEL[key], 12, fg if sel else UI.MUTED)
			lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			iv.add_child(lb)
		pill.add_child(iv)
		c.add_child(pill)
		if key == "inbox" and n > 0:
			var bd = UI.chip(str(n), UI.RED, Color.WHITE, 14)
			bd.position = Vector2((w - pad_l) * 0.5 + 6, 1)
			c.add_child(bd)
		UI.tap(c, func(): _rail_tap(key), true)
		lay.add_child(c)
	for gi in RAIL_GROUPS.size():
		if gi > 0:
			var dy = step.call(y, div_h)
			if dy == y:
				var ln = ColorRect.new()
				ln.color = Color(1, 1, 1, 0.1)
				ln.position = Vector2(pad_l + 18, y + 5)
				ln.size = Vector2(w - pad_l - 36, 1)
				ln.mouse_filter = Control.MOUSE_FILTER_IGNORE
				lay.add_child(ln)
				y += div_h
		for key in RAIL_GROUPS[gi]:
			y = step.call(y, cell)
			place.call(key, y)
			y += cell
	# Settings: pinned to the bottom, clear of the camera
	var yo = max(y, H - cell - 2)
	if h0 >= 0 and yo < h1 and yo + cell > h0:
		yo = h0 - cell if h0 - cell >= y else h1
	place.call("options", yo)


func _rail_tap(key: String):
	if key == "inbox" or key == "home":
		root(key)
		return
	if menu_key == key:
		close_menu()
	else:
		open_menu(key)


func cont_state() -> Dictionary:
	var s = G.s
	if s.review != null:
		return {"label": "Season review", "sub": "", "icon": "trophy"}
	if s.user.sacked:
		return {"label": "Find a job", "sub": "", "icon": "briefcase"}
	var f = G.next_user_fixture()
	if f != null and f.day == s.day:
		return {"label": "Match day", "sub": "%s (%s)" % [s.clubs[f.a if f.h == s.user.club else f.h].short, "H" if f.h == s.user.club else "A"], "icon": "play"}
	var sub = ""
	if f != null:
		var d = f.day - s.day
		sub = "%s (%s) in %d day%s" % [s.clubs[f.a if f.h == s.user.club else f.h].short, "H" if f.h == s.user.club else "A", d, "" if d == 1 else "s"]
	return {"label": "Continue", "sub": sub, "icon": "fast-forward"}


func _build_top():
	_clear(topbar)
	var h = UI.hb(14)
	var c = G.uc()
	var b = UI.badge(c, 48)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(b)
	var tv = UI.vb(-4)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tv.add_child(UI.lbl_fill(t_title.to_upper() if t_title != "" else c.name.to_upper(), 30, UI.TEXT, "xbold"))
	var sub = t_sub if t_sub != "" else c.name
	tv.add_child(UI.lbl_fill(sub, 18, UI.MUTED))
	h.add_child(tv)
	if t_right != null and is_instance_valid(t_right):
		if t_right.get_parent() != null:
			t_right.get_parent().remove_child(t_right)
		t_right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(t_right)
	if G.window_open():
		var wc = UI.chip("WINDOW OPEN", Color(UI.GREEN, 0.14), UI.GREEN, 16)
		h.add_child(wc)
	var d = G.date(G.s.day)
	var dv = UI.vb(-6)
	dv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var d1 = UI.caps(["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][d.weekday], 16, UI.MUTED)
	d1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var d2 = UI.lbl("%d %s %d" % [d.day, G.MONTHS[d.month - 1].to_upper(), d.year], 22, UI.TEXT, "disp")
	d2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dv.add_child(d1)
	dv.add_child(d2)
	var dp = UI.panel(Color(1, 1, 1, 0.05), 12, 14, 6)
	dp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dp.add_child(dv)
	h.add_child(dp)
	var st = cont_state()
	var cb = UI.panel(UI.accent, 12, 18, 4)
	cb.custom_minimum_size = Vector2(210, 54)
	cb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var fg = UI.on_color(UI.accent)
	var ch = UI.hb(10)
	ch.alignment = BoxContainer.ALIGNMENT_CENTER
	ch.add_child(UI.icon(st.icon, 26, fg))
	var cv = UI.vb(-6)
	cv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cv.add_child(UI.lbl(st.label.to_upper(), 26, fg, "xbold"))
	if st.sub != "":
		cv.add_child(UI.lbl(st.sub, 15, Color(fg, 0.75), "semi"))
	ch.add_child(cv)
	cb.add_child(ch)
	cb.mouse_filter = Control.MOUSE_FILTER_STOP
	cb.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				pressing = true
				press_t = 0.0
				cb.modulate = Color(1, 1, 1, 0.7)
			else:
				cb.modulate = Color.WHITE
				if pressing:
					pressing = false
					_continue(false))
	if st.label == "Match day":
		var pt = cb.create_tween().set_loops()
		pt.tween_property(cb, "modulate", Color(1.25, 1.25, 1.25), 0.7).set_trans(Tween.TRANS_SINE)
		pt.tween_property(cb, "modulate", Color.WHITE, 0.7).set_trans(Tween.TRANS_SINE)
	cb.mouse_exited.connect(func():
		pressing = false
		cb.modulate = Color.WHITE)
	h.add_child(cb)
	topbar.add_child(h)


func _continue(to_match: bool):
	if busy or not G.active:
		return
	var s = G.s
	if s.review != null:
		root("review")
		return
	if s.user.sacked:
		root("jobs", {"sacked": true})
		return
	var f = G.user_fixture_today()
	if f != null:
		root("match", {"fx": f})
		return
	busy = true
	UI.sfx("continue", -10.0)
	UI.toast("Simulating to the next match…" if to_match else "Simulating…", UI.MUTED)
	await get_tree().process_frame
	await get_tree().process_frame
	var before = G.unread()
	var first_id = s.inbox[0].id if s.inbox.size() > 0 else -1
	for i in (8 if to_match else 1):
		G.advance()
		if G.user_fixture_today() != null or s.review != null or s.user.sacked:
			break
	busy = false
	if s.review != null:
		root("review")
		return
	if s.user.sacked:
		root("jobs", {"sacked": true})
		return
	if stack.size() > 0:
		stack[-1].refresh()
	_update_chrome()
	if G.unread() > before and s.inbox.size() > 0 and s.inbox[0].id != first_id:
		UI.sfx("message", -8.0)
		UI.toast("New message: %s" % s.inbox[0].title, UI.accent)


# ---------------------------------------------------------------- slide-out menus

func _row(icon_name: String, label: String, info: String, cb: Callable, flag := "") -> Array:
	return [icon_name, label, info, cb, flag]


func menu_items(key: String) -> Array:
	var s = G.s
	var c = G.uc()
	var a: Array = []
	if key == "club":
		var youth = 0
		var inj = 0
		var loaned = 0
		var expiring = 0
		for pid in c.players:
			var p = s.players[pid]
			if p.get("youth", false): youth += 1
			if p.inj > 0: inj += 1
			if p.cend <= s.season + 1: expiring += 1
		for p in s.players.values():
			if p.get("loan", -1) == c.id and p.club != c.id: loaned += 1
		var f = G.next_user_fixture()
		a.append(_row("shirt", "First Team", "%d players" % (c.players.size() - youth), func(): root("squad", {"tab": 0})))
		a.append(_row("graduation-cap", "Youth & Reserves", "%d players" % youth, func(): root("squad", {"tab": 1})))
		a.append(_row("layout-grid", "Tactics", "%s · %s" % [c.formation, G.MENTALITY[c.ment]], func(): root("tactics")))
		a.append(_row("dumbbell", "Development Hub", "%s focus" % G.OPS.FOCUS[c.train.focus], func(): root("training")))
		a.append(_row("stethoscope", "Medical Centre", "%d injured" % inj if inj > 0 else "All fit", func(): root("lists", {"kind": "medical", "grp": "club"})))
		a.append(_row("file-text", "Contracts", "%d expiring" % expiring if expiring > 0 else "None expiring", func(): root("lists", {"kind": "contracts", "grp": "club"})))
		a.append(_row("repeat", "Loan Watch", "%d out on loan" % loaned, func(): root("squad", {"tab": 2})))
		a.append(_row("calendar", "Fixtures", "Next: %s" % s.clubs[f.a if f.h == c.id else f.h].short if f != null else "Season over", func(): root("fixtures")))
		a.append(_row("wallet", "Finances", "%s budget" % G.money(c.budget), func(): root("finances")))
		a.append(_row("clipboard-list", "Team Report", "Strengths and gaps", func(): root("hub", {"kind": "report", "grp": "club"})))
		a.append(_row("users", "Dressing Room", "Hierarchy and morale", func(): root("hub", {"kind": "dressing", "grp": "club"})))
		a.append(_row("megaphone", "Fans", "%d%% confidence" % int(s.user.get("fans", 55.0)), func(): root("hub", {"kind": "fans", "grp": "club"})))
		var spn = G.OPS.sponsor_now()
		a.append(_row("shirt", "Kit & Sponsors", str(spn.name) if spn != null else "Choose a shirt sponsor", func(): root("kit")))
		a.append(_row("chart-bar", "Match Analysis", "Goals, home and away", func(): root("hub", {"kind": "analysis", "grp": "club"})))
		a.append(_row("shield", "Club Records", "Your record and top scorers", func(): root("hub", {"kind": "identity", "grp": "club"})))
		a.append(_row("building", "Club City", "Stadium %s" % G.OPS._thousands(G.OPS.capacity(c)), func(): root("campus")))
	elif key == "manager":
		a.append(_row("user", "Manager Profile", s.user.name, func(): root("board")))
		a.append(_row("target", "Board Confidence", "%d%% · %s" % [int(s.user.conf), s.user.obj.text], func(): root("board")))
		a.append(_row("trophy", "Trophy Cabinet", "%d won" % s.user.trophies.size(), func(): root("trophies")))
		a.append(_row("briefcase", "Jobs", "%d club%s interested" % [s.user.jobs.size(), "" if s.user.jobs.size() == 1 else "s"], func(): root("jobs")))
		a.append(_row("megaphone", "Social", "%s followers" % G.OPS._thousands(G.SOC.data().followers), func(): root("hub", {"kind": "social", "grp": "manager"})))
		a.append(_row("house", "Lifestyle", "%s in the bank" % G.money(G.OPS.life().cash), func(): root("life")))
		a.append(_row("trending-up", "Investments", "Savings, property, shares", func(): root("hub", {"kind": "invest", "grp": "manager"})))
		a.append(_row("landmark", "Club Ownership", "Buy shares in clubs", func(): root("hub", {"kind": "owner", "grp": "manager"})))
		a.append(_row("file-text", "My Contract", "%s a week" % G.money(G.OPS.salary()), func(): root("hub", {"kind": "contract", "grp": "manager"})))
		a.append(_row("scroll-text", "Career Timeline", "%d season%s" % [s.history.size(), "" if s.history.size() == 1 else "s"], func(): root("hub", {"kind": "timeline", "grp": "manager"})))
		a.append(_row("book-open", "Philosophy", "Your club identity", func(): root("hub", {"kind": "philosophy", "grp": "manager"})))
		a.append(_row("circle-question-mark", "Board Request", "Ask for backing", func(): root("hub", {"kind": "request", "grp": "manager"})))
		a.append(_row("info", "Game Status", G.fmt_date(s.day, true), func(): root("hub", {"kind": "status", "grp": "manager"})))
	elif key == "world":
		a.append(_row("list-ordered", "Club Division", "%s in the %s" % [G.LG.ordinal(G.LG.position(c.id)), s.leagues[c.lg].name], func(): root("table", {"lg": c.lg})))
		a.append(_row("trophy", "Cups & Continental", "%d competitions" % G.CP.club_comps(c.id).size(), func(): root("comps")))
		for nat in NATIONS:
			for i in s.leagues.size():
				var l = s.leagues[i]
				if l.get("country", "") == nat and int(l.get("tier", 1)) == 1:
					var lid = i
					a.append(_row("", nat, l.name, func(): root("table", {"lg": lid}), nat))
					break
		a.append(_row("arrow-left-right", "Transfer Centre", "%d deals this season" % s.tx_log.size(), func(): root("hub", {"kind": "tcentre", "grp": "world"})))
		a.append(_row("award", "Awards", "Golden boot and more", func(): root("hub", {"kind": "awards", "grp": "world"})))
		a.append(_row("goal", "Live Scores", "Latest league results", func(): root("hub", {"kind": "scores", "grp": "world"})))
		a.append(_row("list", "League Standards", "Leagues ranked", func(): root("hub", {"kind": "standards", "grp": "world"})))
		a.append(_row("chart-bar", "Player Stats", "Scorers, assists, ratings", func(): root("stats", {"lg": c.lg})))
		a.append(_row("award", "Team of the Week", "The best eleven of the last seven days", func(): root("lists", {"kind": "totw", "grp": "world"})))
		a.append(_row("crown", "Top 50 Players", "Best in the world", func(): root("lists", {"kind": "top50", "grp": "world"})))
		a.append(_row("sparkles", "Wonderkids", "Best aged 21 or under", func(): root("lists", {"kind": "wonderkids", "grp": "world"})))
	elif key == "search":
		a.append(_row("search", "Player Search", "Every player, sortable", func(): root("search")))
		a.append(_row("handshake", "Transfer Market", "Offers, shortlist, your deals", func(): root("transfers")))
		a.append(_row("binoculars", "Scouting", "%d being watched" % s.scout.queue.size(), func(): root("scouting")))
		a.append(_row("tags", "Bargains", "Good players, low prices", func(): root("lists", {"kind": "bargains", "grp": "search"})))
		a.append(_row("clock", "Expiring Contracts", "Out of contract in June", func(): root("lists", {"kind": "expiring", "grp": "search"})))
		a.append(_row("users", "Free Agents", "Available now", func(): root("lists", {"kind": "free", "grp": "search"})))
		a.append(_row("flag", "Transfer Listed", "Clubs want to sell", func(): root("lists", {"kind": "listed", "grp": "search"})))
		a.append(_row("target", "Role Finder", "Players for your roles", func(): root("hub", {"kind": "rolefinder", "grp": "search"})))
		a.append(_row("shield", "Find Club", "Search every club", func(): root("hub", {"kind": "findclub", "grp": "search"})))
		a.append(_row("briefcase", "Jobs", "Clubs interested in you", func(): root("jobs")))
	elif key == "options":
		a.append(_row("save", "Save Game", "Saved automatically each day", func():
			G.save_game()
			close_menu()
			UI.toast("Game saved", UI.GREEN)))
		a.append(_row("settings", "Settings", "Sound, soundtrack, skins", func(): root("settings", {"grp": "options"})))
		a.append(_row("award", "Achievements", "Career milestones", func(): root("hub", {"kind": "achieve", "grp": "options"})))
		a.append(_row("play", "Season Documentary", "Your season, replayed", func(): root("hub", {"kind": "doc", "grp": "options"})))
		a.append(_row("crown", "Hall of Fame", "Honours and scrapbook", func(): root("hub", {"kind": "fame", "grp": "options"})))
		a.append(_row("pencil", "Editor", "On" if G.settings.get("editor", false) else "Off", func(): root("hub", {"kind": "editor", "grp": "options"})))
		a.append(_row("book-open", "Manual", "How to play", func(): root("hub", {"kind": "manual", "grp": "options"})))
		a.append(_row("log-out", "Exit to Menu", "Saves first", func():
			G.save_game()
			G.active = false
			root("menu")))
	return a


# Menu layout: headings with the rows under them, "|" starts the second column. Rows not named land in the last group.
const MENU_GROUPS = {
	"club": [["Squad", ["First Team", "Youth & Reserves", "Tactics", "Loan Watch"]], ["Players", ["Development Hub", "Medical Centre", "Contracts", "Dressing Room"]], "|",
		["Club", ["Kit & Sponsors", "Finances", "Club City", "Fans", "Club Records"]], ["Season", ["Fixtures", "Team Report", "Match Analysis"]]],
	"manager": [["Job", ["Manager Profile", "Board Confidence", "My Contract", "Board Request", "Jobs", "Philosophy"]], "|",
		["Money and life", ["Lifestyle", "Investments", "Club Ownership", "Social"]], ["Career", ["Trophy Cabinet", "Career Timeline", "Game Status"]]],
	"world": [["Competitions", ["Club Division", "Cups & Continental"]], ["Leagues", []], "|",
		["News", ["Live Scores", "Transfer Centre", "League Standards"]], ["Best players", ["Player Stats", "Team of the Week", "Awards", "Top 50 Players", "Wonderkids"]]],
	"search": [["Find", ["Player Search", "Role Finder", "Find Club", "Scouting"]], ["Deals", ["Transfer Market", "Jobs"]], "|",
		["Quick lists", ["Bargains", "Free Agents", "Transfer Listed", "Expiring Contracts"]]],
	"options": [["Game", ["Save Game", "Settings", "Manual", "Editor", "Exit to Menu"]], "|", ["Your story", ["Achievements", "Season Documentary", "Hall of Fame"]]],
}


func menu_columns(key: String) -> Array:
	# -> [[ [heading, rows], ... ], ...] one entry per column
	var rows = menu_items(key)
	var spec = MENU_GROUPS.get(key, [])
	var named = {}
	for g in spec:
		if g is Array:
			for nm in g[1]:
				named[nm] = true
	var cols = [[]]
	var spare = []
	for r in rows:
		if not named.has(r[1]):
			spare.append(r)
	var catch_all = -1
	for g in spec:
		if g is String:
			cols.append([])
			continue
		var got = []
		for nm in g[1]:
			for r in rows:
				if r[1] == nm:
					got.append(r)
		if g[1].is_empty():
			got = spare
			catch_all = 1
		if not got.is_empty():
			cols[-1].append([g[0], got])
	if catch_all < 0 and not spare.is_empty():
		cols[-1].append(["More", spare])
	return cols.filter(func(c): return not c.is_empty())


func open_menu(key: String):
	close_menu()
	UI.sfx("open", -14.0)
	menu_key = key
	var root_c = Control.new()
	root_c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var left = rail_w()
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.offset_left = left
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			close_menu())
	root_c.add_child(dim)
	var cols = menu_columns(key)
	var p = UI.panel(UI.BG2, 0, 0, 0)
	p.get_theme_stylebox("panel").border_color = Color(UI.accent, 0.8)
	p.get_theme_stylebox("panel").border_width_left = 3
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	p.offset_left = left
	p.offset_right = left + min(380.0 * cols.size() + 12, size.x - left - 60)
	p.offset_top = safe.get_theme_constant("margin_top")
	var v = UI.vb(0)
	var head = UI.hb(12)
	head.add_child(UI.badge(G.uc(), 36))
	head.add_child(UI.lbl(G.uc().name, 22, UI.TEXT, "bold"))
	head.add_child(UI.caps({"club": "Club", "manager": "Manager", "world": "World", "search": "Market", "options": "Options"}[key], 17, UI.accent))
	v.add_child(UI.margin(head, 18, 8, 18, 6))
	v.add_child(UI.divider())
	var ch = UI.hb(0)
	ch.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for ci in cols.size():
		var lv = UI.vb(0)
		for g in cols[ci]:
			lv.add_child(UI.margin(UI.caps(g[0], 14, UI.accent), 18, 8, 18, 2))
			for it in g[1]:
				var r = UI.panel(Color(0, 0, 0, 0), 0, 18, 8)
				var h = UI.hb(12)
				if it[4] != "":
					h.add_child(UI.flag(it[4], 28))
				else:
					h.add_child(UI.icon(it[0], 24, UI.TEXT))
				var tv = UI.vb(-4)
				tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				tv.add_child(UI.lbl_fill(it[1], 22, UI.TEXT, "semi"))
				if it[2] != "":
					tv.add_child(UI.lbl_fill(it[2], 15, UI.MUTED))
				h.add_child(tv)
				h.add_child(UI.icon("chevron-right", 16, UI.DIM))
				r.add_child(h)
				UI.tap(r, it[3])
				lv.add_child(r)
		var sc2 = UI.scroll(lv)
		sc2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ch.add_child(sc2)
		if ci < cols.size() - 1:
			var vl = ColorRect.new()
			vl.color = UI.LINE
			vl.custom_minimum_size = Vector2(1, 0)
			ch.add_child(vl)
	v.add_child(ch)
	p.add_child(v)
	root_c.add_child(p)
	overlay.add_child(root_c)
	menu_node = root_c
	p.modulate.a = 0.0
	p.position.x -= 30
	var tw = create_tween().set_parallel(true)
	tw.tween_property(p, "modulate:a", 1.0, 0.12)
	tw.tween_property(p, "position:x", p.position.x + 30, 0.12)
	_build_rail()


func close_menu():
	if menu_node != null:
		menu_node.queue_free()
		menu_node = null
	if menu_key != "":
		menu_key = ""
		if rail != null and rail.visible:
			_build_rail()


# ---------------------------------------------------------------- overlays

func open_sheet(title: String, build: Callable):
	close_sheet()
	var root_c = Control.new()
	root_c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			close_sheet())
	root_c.add_child(dim)
	var p = UI.panel(UI.BG2, 26, 24, 20, Color(1, 1, 1, 0.1))
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.custom_minimum_size = Vector2(min(680.0, size.x - 80), 0)
	var outer = UI.vb(12)
	var head = UI.hb(8)
	head.add_child(UI.lbl_fill(title.to_upper(), 30, UI.TEXT, "xbold"))
	var x = UI.panel(Color(1, 1, 1, 0.07), 14, 9, 9)
	x.add_child(UI.icon("x", 24, UI.MUTED))
	UI.tap(x, close_sheet, true)
	head.add_child(x)
	outer.add_child(head)
	var v = UI.vb(10)
	var s = UI.scroll(v)
	s.size_flags_vertical = Control.SIZE_FILL
	outer.add_child(s)
	p.add_child(outer)
	var cc = CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(p)
	root_c.add_child(cc)
	overlay.add_child(root_c)
	sheet_node = root_c
	build.call(v)
	_layout_sheet(s, v)


func _layout_sheet(s: ScrollContainer, v: Control):
	for i in 2:
		await get_tree().process_frame
		if not is_instance_valid(s):
			return
		s.custom_minimum_size = Vector2(0, min(v.get_combined_minimum_size().y, size.y - 150))


func close_sheet():
	if sheet_node != null:
		sheet_node.queue_free()
		sheet_node = null


func toast(text: String, color := UI.TEXT):
	var p = UI.panel(Color("1d2740"), 16, 20, 12, Color(1, 1, 1, 0.14))
	p.add_child(UI.lbl(text, 22, color, "semi"))
	var c = CenterContainer.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	c.offset_top = 84
	c.add_child(p)
	overlay.add_child(c)
	var tw = create_tween()
	tw.tween_interval(1.8)
	tw.tween_property(c, "modulate:a", 0.0, 0.4)
	tw.tween_callback(c.queue_free)

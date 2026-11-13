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
	"lists": preload("res://scripts/screens/lists.gd"),
	"hub": preload("res://scripts/screens/hub.gd"),
	"search": preload("res://scripts/screens/search.gd"),
}
const RAIL = [["inbox", "mail"], ["home", "house"], ["club", ""], ["manager", "user"], ["world", "globe"], ["search", "search"], ["options", "settings"]]
const RAIL_W = 92
var notch_l := 0            # width of the camera cut-out strip on the left, in viewport units
const TOP_H = 70
const NATIONS = ["England", "Spain", "Italy", "Germany", "France"]

var holder: Control
var rail: PanelContainer
var topbar: PanelContainer
var safe: MarginContainer
var overlay: Control
var glow: TextureRect
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
	if not ResourceLoader.exists(INTRO_PATH):
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
	vp.volume_db = -4.0 if G.settings.get("sound", true) else -80.0
	vp.modulate.a = 0.0
	vp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ar.add_child(vp)
	o.add_child(ar)
	# studio card
	var card = UI.vb(2)
	card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.grow_vertical = Control.GROW_DIRECTION_BOTH
	var c1 = UI.lbl("FORGEFRAME", 54, UI.TEXT, "xbold")
	c1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var c2 = UI.caps("presents", 18, UI.MUTED)
	c2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(c1)
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
	tw.tween_property(card, "modulate:a", 1.0, 0.45)
	tw.tween_interval(1.1)
	tw.tween_property(card, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func():
		vp.play()
		vp.modulate.a = 1.0)
	tw.tween_interval(INTRO_LEN - 3.4)
	tw.tween_property(wm, "modulate:a", 1.0, 0.9)
	tw.tween_interval(3.0)
	tw.tween_callback(_end_intro)
	return true


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
	var bg = ColorRect.new()
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
	rail = UI.panel(Color("0b101a"), 0, 0, 0)
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
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("notch="):
			l = float(arg.substr(6))      # dev: pretend there is a camera cut-out on the left
	# with the rail showing, its background runs under the camera cut-out and only the icons stay clear of it
	notch_l = int(l)
	_apply_left()
	safe.add_theme_constant_override("margin_right", int(r))
	safe.add_theme_constant_override("margin_top", int(t))
	safe.add_theme_constant_override("margin_bottom", int(b))


func rail_col() -> int:
	return 66 if notch_l > 16 else RAIL_W


func rail_w() -> int:
	return notch_l + rail_col()


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


func _update_chrome():
	UI.accent = UI.BRAND
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
		"club": ["squad", "tactics", "training", "fixtures", "finances", "campus", "lists"],
		"manager": ["board", "trophies", "jobs", "life"], "world": ["table", "comps", "stats", "clubview"],
		"search": ["search", "transfers", "scouting", "player", "nego", "compare"]}
	if nm == "lists" or nm == "hub":
		return str(stack[0].args.get("grp", "club"))
	for k in groups:
		if nm in groups[k]:
			return k
	return ""


func _build_rail():
	_clear(rail)
	var v = UI.vb(0)
	var cur = _rail_key()
	var bk = UI.panel(Color(0, 0, 0, 0), 0, 0, 0)
	bk.custom_minimum_size = Vector2(rail_w(), 66)
	var can_back = stack.size() > 1 or (stack.size() == 1 and stack[0].sname != "home")
	bk.add_child(UI.margin(UI.center(UI.icon("chevron-left", 40, UI.TEXT if can_back else UI.DIM)), notch_l, 0, 0, 0))
	UI.tap(bk, back, true)
	v.add_child(bk)
	var n = G.unread()
	for it in RAIL:
		var key = it[0]
		var sel = key == cur
		var cell = UI.panel(Color(UI.accent, 0.92) if sel else Color(0, 0, 0, 0), 0, 0, 0)
		cell.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cell.custom_minimum_size = Vector2(rail_w(), 60)
		var fg = UI.on_color(UI.accent) if sel else UI.TEXT
		var inner: Control
		if key == "club":
			inner = UI.badge(G.uc(), 46)
		else:
			inner = UI.icon(it[1], 36, fg)
		var cc = UI.margin(UI.center(inner), notch_l, 0, 0, 0)
		cell.add_child(cc)
		if key == "inbox" and n > 0:
			var bd = UI.chip(str(n), UI.RED, Color.WHITE, 17)
			bd.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
			var holder2 = Control.new()
			holder2.mouse_filter = Control.MOUSE_FILTER_IGNORE
			holder2.add_child(bd)
			bd.position = Vector2(rail_w() - (40 if notch_l <= 16 else 30), 6)
			cell.add_child(holder2)
		UI.tap(cell, func(): _rail_tap(key), true)
		v.add_child(cell)
	rail.add_child(v)


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
		a.append(_row("hand-coins", "Sponsors", str(s.user.sponsor.name) if s.user.get("sponsor") != null and s.user.sponsor.season == s.season else "No shirt sponsor", func(): root("hub", {"kind": "sponsors", "grp": "club"})))
		a.append(_row("chart-bar", "Match Analysis", "Goals, home and away", func(): root("hub", {"kind": "analysis", "grp": "club"})))
		a.append(_row("shield", "Club Identity", "Colours and records", func(): root("hub", {"kind": "identity", "grp": "club"})))
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
		var snd = G.settings.get("sound", true)
		a.append(_row("save", "Save Game", "Saved automatically each day", func():
			G.save_game()
			close_menu()
			UI.toast("Game saved", UI.GREEN)))
		a.append(_row("volume-2" if snd else "volume-x", "Sound", "On" if snd else "Off", func():
			G.settings["sound"] = not snd
			G.save_settings()
			if not G.settings["sound"]:
				UI.ambience(false)
			open_menu("options")))
		a.append(_row("award", "Achievements", "Career milestones", func(): root("hub", {"kind": "achieve", "grp": "options"})))
		a.append(_row("play", "Season Documentary", "Your season, replayed", func(): root("hub", {"kind": "doc", "grp": "options"})))
		a.append(_row("crown", "Hall of Fame", "Honours and scrapbook", func(): root("hub", {"kind": "fame", "grp": "options"})))
		a.append(_row("pencil", "Editor", "On" if G.settings.get("editor", false) else "Off", func(): root("hub", {"kind": "editor", "grp": "options"})))
		a.append(_row("book-open", "Manual", "How to play", func(): root("hub", {"kind": "manual", "grp": "options"})))
		if not UI.music_tracks().is_empty():
			var mus = G.settings.get("music", true)
			a.append(_row("volume-2" if mus else "volume-x", "Music", "On" if mus else "Off", func():
				G.settings["music"] = not mus
				G.save_settings()
				UI.music(not mus)
				open_menu("options")))
		a.append(_row("log-out", "Exit to Menu", "Saves first", func():
			G.save_game()
			G.active = false
			root("menu")))
	return a


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
	var p = UI.panel(Color("111827"), 0, 0, 0)
	p.get_theme_stylebox("panel").border_color = Color(UI.accent, 0.8)
	p.get_theme_stylebox("panel").border_width_left = 3
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	p.offset_left = left
	p.offset_right = left + 400
	p.offset_top = safe.get_theme_constant("margin_top")
	var v = UI.vb(0)
	var head = UI.hb(12)
	head.add_child(UI.badge(G.uc(), 44))
	var hv = UI.vb(-4)
	hv.add_child(UI.lbl(G.uc().name, 24, UI.TEXT, "bold"))
	hv.add_child(UI.caps({"club": "Club", "manager": "Manager", "world": "World", "search": "Search", "options": "Options"}[key], 18, UI.accent))
	head.add_child(hv)
	v.add_child(UI.margin(head, 18, 12, 18, 10))
	v.add_child(UI.divider())
	var lv = UI.vb(0)
	for it in menu_items(key):
		var r = UI.panel(Color(0, 0, 0, 0), 0, 18, 9)
		var h = UI.hb(14)
		if it[4] != "":
			h.add_child(UI.flag(it[4], 34))
		else:
			h.add_child(UI.icon(it[0], 28, UI.TEXT))
		var tv = UI.vb(-3)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UI.lbl_fill(it[1], 25, UI.TEXT, "semi"))
		if it[2] != "":
			tv.add_child(UI.lbl_fill(it[2], 17, UI.MUTED))
		h.add_child(tv)
		h.add_child(UI.icon("chevron-right", 20, UI.DIM))
		r.add_child(h)
		UI.tap(r, it[3])
		lv.add_child(r)
		lv.add_child(UI.divider())
	v.add_child(UI.scroll(lv))
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

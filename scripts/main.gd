extends Control
# Application shell: background, screen stack, bottom navigation, sheets and toasts.

const SCREENS = {
	"menu": preload("res://scripts/screens/menu.gd"),
	"new_career": preload("res://scripts/screens/new_career.gd"),
	"home": preload("res://scripts/screens/home.gd"),
	"squad": preload("res://scripts/screens/squad.gd"),
	"tactics": preload("res://scripts/screens/tactics.gd"),
	"transfers": preload("res://scripts/screens/transfers.gd"),
	"club": preload("res://scripts/screens/club.gd"),
	"player": preload("res://scripts/screens/player.gd"),
	"nego": preload("res://scripts/screens/nego.gd"),
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
}
const TABS = [["home", "Home", "house"], ["squad", "Squad", "shirt"], ["tactics", "Tactics", "layout-grid"], ["transfers", "Market", "arrow-left-right"], ["club", "Club", "trophy"]]

var holder: Control
var nav: PanelContainer
var overlay: Control
var glow: TextureRect
var top_sp: Control
var stack: Array = []
var cur_tab := ""
var sheet_node: Control = null
var dev = null


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
	if "--uitest" in ua:
		dev = load("res://dev/uitest.gd").new()
		dev.run(self)
	if "--shots" in ua:
		dev = load("res://dev/shots.gd").new()
		dev.run(self)


func _build():
	var bg = ColorRect.new()
	bg.color = UI.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	glow = TextureRect.new()
	var g = Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0.26))
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
	glow.offset_left = -260
	glow.offset_right = 260
	glow.offset_bottom = 560
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)
	var frame = UI.vb(0)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(frame)
	top_sp = UI.sp(0, 12)
	frame.add_child(top_sp)
	holder = Control.new()
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.clip_contents = true
	frame.add_child(holder)
	nav = UI.panel(Color("0c111c"), 0, 8, 8, Color(0, 0, 0, 0))
	nav.get_theme_stylebox("panel").border_color = UI.LINE
	nav.get_theme_stylebox("panel").border_width_top = 1
	frame.add_child(nav)
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	_safe_area()
	get_viewport().size_changed.connect(_safe_area)


func _safe_area():
	var win = DisplayServer.window_get_size()
	var safe = DisplayServer.get_display_safe_area()
	var top = 12.0
	var bot = 8.0
	if OS.has_feature("mobile") and win.y > 0 and safe.size.y > 0:
		var k = size.y / float(win.y)
		top = max(12.0, safe.position.y * k + 6.0)
		bot = max(8.0, (win.y - safe.end.y) * k + 6.0)
	top_sp.custom_minimum_size = Vector2(0, top)
	nav.get_theme_stylebox("panel").content_margin_bottom = bot


func _notification(what):
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		back()
	elif what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if G.active and (stack.size() == 0 or stack[-1].sname != "match"):
			G.save_game()


func _mk(sname: String, args: Dictionary) -> Control:
	var scr = SCREENS[sname].new()
	scr.args = args
	scr.sname = sname
	return scr


func _is_tab(sname: String) -> bool:
	for t in TABS:
		if t[0] == sname:
			return true
	return false


func root(sname: String, args := {}):
	close_sheet()
	for old in stack:
		old.queue_free()
	stack = []
	cur_tab = sname if _is_tab(sname) else ""
	var scr = _mk(sname, args)
	stack.append(scr)
	holder.add_child(scr)
	_update_chrome()


func open(sname: String, args := {}):
	close_sheet()
	if stack.size() > 0:
		stack[-1].visible = false
	var scr = _mk(sname, args)
	stack.append(scr)
	holder.add_child(scr)
	_update_chrome()


func back():
	if sheet_node != null:
		close_sheet()
		return
	if stack.size() <= 1:
		return
	if stack[-1].has_method("can_leave") and not stack[-1].can_leave():
		return
	var top = stack.pop_back()
	top.queue_free()
	stack[-1].visible = true
	stack[-1].on_resume()
	_update_chrome()


func tab(sname: String):
	root(sname)


func refresh_nav():
	_update_chrome()


func _update_chrome():
	if G.active:
		UI.set_accent_from(G.uc())
	else:
		UI.accent = UI.GOLD
	glow.modulate = UI.accent
	var vis = stack.size() > 0 and stack[-1].show_nav
	nav.visible = vis
	if not vis:
		return
	for c in nav.get_children():
		nav.remove_child(c)
		c.queue_free()
	var h = UI.hb(0)
	for t in TABS:
		var on = t[0] == cur_tab
		var it = UI.panel(Color(0, 0, 0, 0), 14, 4, 8)
		it.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var v = UI.vb(4)
		var ic = UI.icon(t[2], 34, UI.accent if on else UI.DIM)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(ic)
		var l = UI.lbl(t[1].to_upper(), 18, UI.TEXT if on else UI.DIM, "cond")
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
		it.add_child(v)
		var nm = t[0]
		UI.tap(it, func(): tab(nm), true)
		h.add_child(it)
	nav.add_child(h)


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
	var p = UI.panel(UI.BG2, 32, 26, 24, Color(1, 1, 1, 0.1))
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	var outer = UI.vb(14)
	var head = UI.hb(8)
	head.add_child(UI.lbl_fill(title.to_upper(), 34, UI.TEXT, "xbold"))
	var x = UI.panel(Color(1, 1, 1, 0.07), 16, 10, 10)
	x.add_child(UI.icon("x", 26, UI.MUTED))
	UI.tap(x, close_sheet, true)
	head.add_child(x)
	outer.add_child(head)
	var v = UI.vb(12)
	var s = UI.scroll(v)
	s.size_flags_vertical = Control.SIZE_FILL
	outer.add_child(s)
	p.add_child(outer)
	root_c.add_child(p)
	p.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	p.grow_vertical = Control.GROW_DIRECTION_BEGIN
	p.offset_left = 12
	p.offset_right = -12
	p.offset_bottom = -14
	p.offset_top = -14
	overlay.add_child(root_c)
	sheet_node = root_c
	build.call(v)
	_layout_sheet(p, s, v)


func _layout_sheet(p: Control, s: ScrollContainer, v: Control):
	await get_tree().process_frame
	if not is_instance_valid(p):
		return
	var h = min(v.get_combined_minimum_size().y, size.y * 0.7)
	s.custom_minimum_size = Vector2(0, h)
	p.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	p.grow_vertical = Control.GROW_DIRECTION_BEGIN
	p.offset_left = 12
	p.offset_right = -12
	p.offset_bottom = -14
	p.offset_top = -14


func close_sheet():
	if sheet_node != null:
		sheet_node.queue_free()
		sheet_node = null


func toast(text: String, color := UI.TEXT):
	var p = UI.panel(Color("1d2740"), 18, 22, 14, Color(1, 1, 1, 0.14))
	p.add_child(UI.lbl(text, 24, color, "semi"))
	var c = CenterContainer.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	c.offset_top = top_sp.custom_minimum_size.y + 90
	c.add_child(p)
	overlay.add_child(c)
	var tw = create_tween()
	tw.tween_interval(1.8)
	tw.tween_property(c, "modulate:a", 0.0, 0.4)
	tw.tween_callback(c.queue_free)

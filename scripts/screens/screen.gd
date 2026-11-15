extends Control
# Base class for every screen. Subclasses override build().

const FLOW = preload("res://scripts/widgets/flow.gd")
const PAGER = preload("res://scripts/widgets/pager.gd")

var args: Dictionary = {}
var sname := ""
var show_nav := false
var chrome := true          # rail and top bar shown around this screen
var title := ""
var subtitle := ""
var cols := 0               # 0 = automatic column count for content()
var max_w := 0.0
var body: VBoxContainer
var sc: ScrollContainer = null
var pager: Control = null
var keep_page := 0


func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	body = UI.vb(0)
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(body)
	build()
	_push_title()


func _push_title():
	# screens that only set title/subtitle get them shown in the top bar
	if title != "" and UI.main != null and UI.main.t_title == "":
		UI.main.t_title = title
		UI.main.t_sub = subtitle


func build():
	pass


func refresh():
	var y = sc.scroll_vertical if sc != null and is_instance_valid(sc) else 0
	sc = null
	keep_page = pager.page if pager != null and is_instance_valid(pager) else 0
	pager = null
	for c in body.get_children():
		body.remove_child(c)
		c.queue_free()
	if UI.main != null and UI.main.stack.size() > 0 and UI.main.stack[-1] == self:
		UI.main.t_title = ""
		UI.main.t_sub = ""
	build()
	_push_title()
	if UI.main != null:
		UI.main.refresh_nav()
	if y > 0:
		for i in 2:
			await get_tree().process_frame
			if sc != null and is_instance_valid(sc):
				sc.scroll_vertical = y


func on_resume():
	refresh()


func backdrop(scene: String, dim := 0.6):
	# full-screen scene image behind the screen's content
	var path = "res://assets/scenes/%s.jpg" % scene
	if has_node("backdrop") or not ResourceLoader.exists(path):
		return
	var t = TextureRect.new()
	t.name = "backdrop"
	t.texture = load(path)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var d = ColorRect.new()
	d.color = Color(0.03, 0.04, 0.07, dim)
	d.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.add_child(d)
	add_child(t)
	move_child(t, 0)


func content(sep := 14, pad := 20) -> Container:
	# content flows into columns; what does not fit goes onto further pages you swipe between
	var v = FLOW.new()
	v.sep = sep
	v.cols = cols
	v.max_w = max_w
	v.pad = pad
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pager = PAGER.new()
	pager.setup(v)
	pager.page = keep_page
	body.add_child(pager)
	return v


func column(sep := 12, pad := 0) -> VBoxContainer:
	# plain scrolling column, for panes placed side by side
	var v = UI.vb(sep)
	var s = UI.scroll(UI.margin(v, pad, 0, pad, 12))
	set_meta("last_scroll", s)
	return v


func pane(w := 0.0, sep := 12) -> Array:
	# card-backed scrolling pane: returns [panel node, inner VBox]
	var p = UI.panel(UI.CARD, 18, 16, 14, UI.LINE)
	var v = UI.vb(sep)
	var s = UI.scroll(v)
	p.add_child(s)
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if w > 0:
		p.custom_minimum_size = Vector2(w, 0)
	else:
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return [p, v]


func panes(sep := 14, pad := 20) -> HBoxContainer:
	var h = UI.hb(sep)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(UI.margin(h, pad, 4, pad, 14))
	body.get_child(body.get_child_count() - 1).size_flags_vertical = Control.SIZE_EXPAND_FILL
	return h

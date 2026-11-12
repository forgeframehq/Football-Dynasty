extends Control
# Base class for every screen. Subclasses override build().

const FLOW = preload("res://scripts/widgets/flow.gd")

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


func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	body = UI.vb(0)
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(body)
	build()


func build():
	pass


func refresh():
	var y = sc.scroll_vertical if sc != null and is_instance_valid(sc) else 0
	sc = null
	for c in body.get_children():
		body.remove_child(c)
		c.queue_free()
	build()
	if UI.main != null:
		UI.main.refresh_nav()
	if y > 0:
		for i in 2:
			await get_tree().process_frame
			if sc != null and is_instance_valid(sc):
				sc.scroll_vertical = y


func on_resume():
	refresh()


func content(sep := 14, pad := 20) -> Container:
	# scrolling area whose children flow into balanced columns
	var v = FLOW.new()
	v.sep = sep
	v.cols = cols
	v.max_w = max_w
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m = UI.margin(v, pad, 6, pad, 20)
	sc = UI.scroll(m)
	body.add_child(sc)
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

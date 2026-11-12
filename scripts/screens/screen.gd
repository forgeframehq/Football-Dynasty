extends Control
# Base class for every screen. Subclasses override build().

var args: Dictionary = {}
var sname := ""
var show_nav := false
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
	if y > 0:
		for i in 2:
			await get_tree().process_frame
			if sc != null and is_instance_valid(sc):
				sc.scroll_vertical = y


func on_resume():
	refresh()


func content(sep := 14, pad := 24) -> VBoxContainer:
	var v = UI.vb(sep)
	var m = UI.margin(v, pad, 6, pad, 28)
	sc = UI.scroll(m)
	body.add_child(sc)
	return v

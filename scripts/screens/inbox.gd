extends "res://scripts/screens/screen.gd"
# Messages from the board, staff and other clubs.

const ICONS = {"info": "mail", "board": "landmark", "offer": "handshake", "contract": "briefcase", "result": "flag"}


func build():
	var s = G.s
	var right = UI.panel(Color(1, 1, 1, 0.06), 18, 16, 12)
	right.add_child(UI.caps("Read all", 20, UI.TEXT))
	UI.tap(right, func():
		for m in s.inbox:
			m.read = true
		refresh(), true)
	body.add_child(UI.topbar("Inbox", true, right))
	var v = content(8)
	if s.inbox.size() == 0:
		v.add_child(UI.wrap("No messages yet.", 23, UI.MUTED))
	for m in s.inbox:
		var r = UI.panel(UI.CARD, 18, 16, 14, Color(UI.accent, 0.5) if not m.read else UI.LINE)
		var h = UI.hb(14)
		var ic = UI.panel(Color(UI.accent if not m.read else UI.DIM, 0.14), 16, 12, 12)
		ic.add_child(UI.icon(ICONS.get(m.kind, "mail"), 26, UI.accent if not m.read else UI.DIM))
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(ic)
		var tv = UI.vb(0)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UI.lbl_fill(m.title, 25, UI.TEXT if not m.read else UI.MUTED, "semi"))
		tv.add_child(UI.lbl_fill(m.body.replace("\n", " "), 20, UI.DIM))
		h.add_child(tv)
		h.add_child(UI.caps(G.fmt_date(m.day).substr(4), 17, UI.DIM))
		r.add_child(h)
		UI.tap(r, func(): _open(m))
		v.add_child(r)


func _open(m: Dictionary):
	m.read = true
	var build_sheet = func(v):
		v.add_child(UI.caps(G.fmt_date(m.day, true), 19, UI.DIM))
		v.add_child(UI.wrap(m.body, 24, UI.TEXT))
		v.add_child(UI.sp(0, 6))
		if m.kind == "offer":
			v.add_child(UI.btn("View offers", func():
				UI.close_sheet()
				G.ui.tr_tab = 2
				UI.main.tab("transfers"), "primary", "handshake", 76))
		v.add_child(UI.btn("Close", func():
			UI.close_sheet()
			refresh()
			UI.main.refresh_nav(), "ghost", "", 68))
	UI.sheet(m.title, build_sheet)

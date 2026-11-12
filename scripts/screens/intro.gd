extends "res://scripts/screens/screen.gd"
# Scenes shown when a job starts: the breaking-news appointment, then the board meeting.


class Sil extends Control:
	# manager silhouette
	func _draw():
		var w = size.x
		var h = size.y
		var cx = w / 2.0
		var dark = Color("06080d")
		var rim = Color(1, 1, 1, 0.5)
		var sh = PackedVector2Array([Vector2(cx - w * 0.5, h), Vector2(cx - w * 0.46, h * 0.78), Vector2(cx - w * 0.2, h * 0.66), Vector2(cx - w * 0.1, h * 0.56),
			Vector2(cx + w * 0.1, h * 0.56), Vector2(cx + w * 0.2, h * 0.66), Vector2(cx + w * 0.46, h * 0.78), Vector2(cx + w * 0.5, h)])
		draw_colored_polygon(sh, dark)
		draw_polyline(sh, Color(rim, 0.25), 2.0, true)
		draw_set_transform(Vector2(cx, h * 0.34), 0.0, Vector2(1.0, 1.25))
		draw_circle(Vector2.ZERO, w * 0.21, dark)
		draw_arc(Vector2.ZERO, w * 0.21, -PI * 0.9, -PI * 0.1, 30, rim, 3.0, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func build():
	chrome = false
	if args.get("kind", "appoint") == "board":
		_board()
	else:
		_appoint()


func _appoint():
	var s = G.s
	var c = G.uc()
	var c1 = Color(c.c1)
	var c2 = Color(c.c2)
	if c1.get_luminance() < 0.08:
		c1 = c1.lightened(0.18)
	var holder = UI.vb(12)
	holder.alignment = BoxContainer.ALIGNMENT_CENTER
	var m = UI.margin(holder, 40, 20, 40, 20)
	m.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(m)
	var tv = UI.panel(Color("05070b"), 10, 10, 10, Color(1, 1, 1, 0.18))
	tv.custom_minimum_size = Vector2(900, 470)
	tv.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var inner = Control.new()
	inner.clip_contents = true
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tv.add_child(inner)
	# sponsor wall
	var wall = GridContainer.new()
	wall.columns = 6
	wall.add_theme_constant_override("h_separation", 4)
	wall.add_theme_constant_override("v_separation", 4)
	wall.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in 30:
		var k = (i + int(i / 6)) % 3
		var col = c1 if k == 0 else (Color("10151f") if k == 1 else c2.darkened(0.1))
		var cell = UI.panel(col, 0, 0, 0)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.size_flags_vertical = Control.SIZE_EXPAND_FILL
		if k == 1:
			var t = UI.vb(-8)
			t.alignment = BoxContainer.ALIGNMENT_CENTER
			var a = UI.lbl("FOOTBALL", 19, UI.TEXT, "xbold")
			a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			var b = UI.lbl("DYNASTY", 19, UI.GOLD, "xbold")
			b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			t.add_child(a)
			t.add_child(b)
			cell.add_child(t)
		elif k == 2:
			cell.add_child(UI.center(UI.badge(c, 44)))
		wall.add_child(cell)
	inner.add_child(wall)
	var sil = Sil.new()
	sil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sil.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	sil.offset_left = 90
	sil.offset_right = 430
	sil.offset_top = -400
	sil.offset_bottom = -46
	inner.add_child(sil)
	var tag = UI.panel(Color("f5c518"), 0, 18, 6)
	tag.add_child(UI.lbl("BREAKING NEWS", 26, Color("0a0e17"), "xbold"))
	tag.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	tag.offset_left = -230
	tag.offset_top = 14
	tag.offset_right = 0
	tag.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	inner.add_child(tag)
	var ticker = UI.panel(Color("f5c518"), 0, 16, 6)
	ticker.add_child(UI.lbl_fill("%s APPOINT %s AS MANAGER" % [c.name.to_upper(), str(s.user.name).to_upper()], 30, Color("0a0e17"), "xbold"))
	ticker.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	ticker.grow_vertical = Control.GROW_DIRECTION_BEGIN
	inner.add_child(ticker)
	holder.add_child(tv)
	var foot = UI.hb(18)
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	var lg = UI.vb(-10)
	lg.add_child(UI.lbl("FOOTBALL", 26, UI.TEXT, "xbold"))
	lg.add_child(UI.lbl("DYNASTY", 26, UI.GOLD, "xbold"))
	foot.add_child(lg)
	foot.add_child(UI.badge(c, 64))
	var lv = UI.vb(-4)
	lv.add_child(UI.lbl(s.leagues[c.lg].name, 24, UI.TEXT, "bold"))
	lv.add_child(UI.lbl("%s · season %s" % [s.leagues[c.lg].country, G.season_name()], 17, UI.MUTED))
	foot.add_child(lv)
	foot.add_child(UI.sp(40, 0))
	var bt = UI.btn("Meet the board", func(): UI.main.root("intro", {"kind": "board"}), "gold", "chevron-right", 58)
	bt.custom_minimum_size = Vector2(280, 58)
	foot.add_child(bt)
	holder.add_child(foot)
	tv.modulate.a = 0.0
	tv.scale = Vector2(0.94, 0.94)
	tv.pivot_offset = Vector2(450, 235)
	var tw = create_tween().set_parallel(true)
	tw.tween_property(tv, "modulate:a", 1.0, 0.5)
	tw.tween_property(tv, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	UI.sfx("sting_news", -6.0)
	UI.sfx("vo_news", -2.0)


func _board():
	var s = G.s
	var c = G.uc()
	var h0 = UI.hb(14)
	h0.add_child(UI.badge(c, 60))
	var tv = UI.vb(-4)
	tv.add_child(UI.lbl("BOARD MEETING", 38, UI.TEXT, "xbold"))
	tv.add_child(UI.lbl("%s · %s" % [c.name, G.fmt_date(s.day, true)], 18, UI.MUTED))
	h0.add_child(tv)
	body.add_child(UI.margin(h0, 28, 18, 28, 10))
	var h = panes(16, 28)
	var a = pane(430, 12)
	h.add_child(a[0])
	var v = a[1]
	var base = G.LG.objective(c)
	v.add_child(UI.caps("The chairman", 18, UI.GOLD))
	v.add_child(UI.wrap("Welcome to %s, %s. Before the season starts we need to agree what success looks like." % [c.name, s.user.name], 22, UI.TEXT))
	v.add_child(UI.wrap("Our view is that this squad should %s. Promise more and we will back you with a bigger budget, but we will be less patient. Play it safe and you get more time, with less to spend." % base.text.to_lower(), 21, UI.MUTED))
	v.add_child(UI.divider())
	v.add_child(UI.kv("Squad rating", str(int(round(c.rep)))))
	v.add_child(UI.kv("Wage budget", "%s / wk" % G.money(c.wage_budget)))
	v.add_child(UI.kv("Stadium", G.OPS._thousands(G.OPS.capacity(c))))
	v.add_child(UI.kv("Your reputation", "%d / 100" % int(s.user.rep)))
	var col = UI.vb(12)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(col)
	var opts = [["Play it safe", 3, 0.82, 10.0, "More patience from the board"], ["Accept the target", 0, 1.0, 0.0, "What the board expects"], ["Promise more", -3, 1.22, -8.0, "A bigger budget, less patience"]]
	var seen = []
	for o in opts:
		var ob = G.LG.objective(c, o[1])
		if o[1] != 0 and ob.target == base.target:
			if o[1] < 0 and base.target > 1:
				ob = {"exp": base.exp, "target": max(1, base.target - 1), "text": "Win the league" if base.target - 1 <= 1 else "Finish in the top %d" % (base.target - 1)}
			else:
				continue
		if ob.text in seen:
			continue
		seen.append(ob.text)
		var budget = G.nice(c.budget * o[2])
		var card = UI.panel(UI.CARD, 18, 18, 12, Color(UI.GOLD, 0.5) if o[1] == 0 else UI.LINE)
		card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var ch = UI.hb(14)
		var cv = UI.vb(-2)
		cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		cv.add_child(UI.caps(o[0], 18, UI.GOLD))
		cv.add_child(UI.lbl(ob.text, 30, UI.TEXT, "disp"))
		cv.add_child(UI.lbl(o[4], 18, UI.MUTED))
		ch.add_child(cv)
		var bv = UI.vb(-4)
		bv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var bl = UI.lbl(G.money(budget), 34, UI.GREEN, "xbold")
		bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		bv.add_child(bl)
		var bc = UI.caps("Transfer budget", 15, UI.DIM)
		bc.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		bv.add_child(bc)
		ch.add_child(bv)
		ch.add_child(UI.icon("chevron-right", 26, UI.DIM))
		card.add_child(ch)
		var conf = o[3]
		UI.tap(card, func():
			s.user.obj = ob
			c.budget = budget
			s.user.conf = clamp(s.user.conf + conf, 20.0, 80.0)
			if s.inbox.size() > 0:
				s.inbox[0].body = "The board welcomes you as the new manager of %s.\n\nAgreed objective: %s.\n\nYou have a transfer budget of %s and the transfer window is open until 31 August. Set up your tactics, shape the squad and press Continue when you are ready." % [c.name, ob.text, G.money(budget)]
			G.save_game()
			UI.sfx("confirm", -8.0)
			UI.main.root("home"))
		col.add_child(card)

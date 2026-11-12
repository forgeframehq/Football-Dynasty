extends "res://scripts/screens/screen.gd"
# Scenes shown when a job starts: the breaking-news appointment, then the board meeting.


class Sil extends Control:
	# manager silhouette
	func _draw():
		var w = size.x
		var h = size.y
		var cx = w / 2.0
		var dark = Color("06080d")
		var rim = Color(1, 1, 1, 0.3)
		# shoulders and suit
		var sh = PackedVector2Array([Vector2(cx - w * 0.47, h), Vector2(cx - w * 0.45, h * 0.8), Vector2(cx - w * 0.36, h * 0.7), Vector2(cx - w * 0.14, h * 0.63),
			Vector2(cx - w * 0.075, h * 0.6), Vector2(cx + w * 0.075, h * 0.6), Vector2(cx + w * 0.14, h * 0.63), Vector2(cx + w * 0.36, h * 0.7),
			Vector2(cx + w * 0.45, h * 0.8), Vector2(cx + w * 0.47, h)])
		draw_colored_polygon(sh, dark)
		draw_polyline(sh, rim, 2.0, true)
		# neck
		draw_rect(Rect2(cx - w * 0.07, h * 0.48, w * 0.14, h * 0.14), dark)
		# head: taller than wide, with ears and a hair line
		draw_set_transform(Vector2(cx, h * 0.33), 0.0, Vector2(0.8, 1.0))
		draw_circle(Vector2.ZERO, h * 0.2, dark)
		draw_arc(Vector2.ZERO, h * 0.2, -PI * 0.85, -PI * 0.15, 30, Color(1, 1, 1, 0.45), 2.5, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for sx in [-1.0, 1.0]:
			draw_circle(Vector2(cx + sx * h * 0.165, h * 0.35), h * 0.03, dark)
		# collar and tie hint
		draw_colored_polygon(PackedVector2Array([Vector2(cx - w * 0.07, h * 0.6), Vector2(cx, h * 0.72), Vector2(cx + w * 0.07, h * 0.6)]), Color("1b2233"))
		draw_colored_polygon(PackedVector2Array([Vector2(cx - w * 0.018, h * 0.66), Vector2(cx + w * 0.018, h * 0.66), Vector2(cx + w * 0.03, h * 0.9), Vector2(cx, h * 0.96), Vector2(cx - w * 0.03, h * 0.9)]), Color("0e1320"))


func build():
	chrome = false
	if args.get("kind", "appoint") == "board":
		backdrop("boardroom", 0.72)
		_board()
	else:
		backdrop("press_room", 0.45)
		_appoint()


func _ink(text: String, size: int, font := "body", col := Color("15161a")) -> Label:
	var l = UI.wrap(text, size, col, font)
	return l


func _appoint():
	# newspaper front page announcing the appointment
	var s = G.s
	var c = G.uc()
	var u = s.user
	var holder = UI.vb(10)
	holder.alignment = BoxContainer.ALIGNMENT_CENTER
	var m = UI.margin(holder, 40, 14, 40, 14)
	m.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(m)
	var paper = UI.panel(Color("efe7d6"), 4, 26, 16, Color("cfc5ae"))
	paper.custom_minimum_size = Vector2(880, 0)
	paper.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if ResourceLoader.exists("res://assets/scenes/newspaper.jpg"):
		var tex = StyleBoxTexture.new()
		tex.texture = load("res://assets/scenes/newspaper.jpg")
		tex.content_margin_left = 30
		tex.content_margin_right = 30
		tex.content_margin_top = 18
		tex.content_margin_bottom = 20
		paper.add_theme_stylebox_override("panel", tex)
	var pv = UI.vb(4)
	paper.add_child(pv)
	var top = UI.hb(8)
	top.add_child(UI.lbl(G.fmt_date(s.day, true).to_upper(), 14, Color("5b564b"), "semi"))
	top.add_child(UI.sp())
	top.add_child(UI.lbl("%s EDITION · €2" % s.leagues[c.lg].country.to_upper(), 14, Color("5b564b"), "semi"))
	pv.add_child(top)
	var mast = UI.lbl("THE FOOTBALL GAZETTE", 50, Color("15161a"), "xbold")
	mast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pv.add_child(mast)
	var rule = ColorRect.new()
	rule.color = Color("15161a")
	rule.custom_minimum_size = Vector2(0, 4)
	pv.add_child(rule)
	var kicker = UI.hb(8)
	kicker.add_child(UI.chip("EXCLUSIVE", Color(c.c1) if Color(c.c1).get_luminance() < 0.6 else Color("15161a"), Color.WHITE, 15))
	kicker.add_child(UI.lbl(s.leagues[c.lg].name.to_upper(), 15, Color("5b564b"), "semi"))
	pv.add_child(kicker)
	var surname = str(u.name).split(" ")[-1].to_upper()
	pv.add_child(_ink("%s APPOINT %s" % [c.name.to_upper(), surname], 58, "xbold"))
	pv.add_child(_ink("New manager %s takes charge at %s with the board demanding: %s" % [u.name, c.stadium if c.stadium != "" else c.name, s.user.obj.text.to_lower()], 21, "semi", Color("3a372f")))
	var cols_ = UI.hb(18)
	var art = UI.vb(6)
	art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art.add_child(_ink("%s have named %s as their new manager, the club confirmed last night. The %d-year-old from %s arrives with a %s licence and a reputation still to be made at this level." % [c.name, u.name, int(u.get("age", 38)), u.nat, G.OPS.BADGES[u.badge]], 17))
	art.add_child(_ink("Supporters will expect a fast start. The transfer window is open and the new manager has %s to spend. A club source said: \"He knows what this club demands.\"" % G.money(c.budget), 17))
	cols_.add_child(art)
	var side = UI.panel(Color(c.c1), 2, 12, 10)
	side.custom_minimum_size = Vector2(220, 0)
	var sv = UI.vb(4)
	sv.alignment = BoxContainer.ALIGNMENT_CENTER
	sv.add_child(UI.center(UI.badge(c, 86)))
	var fg = UI.on_color(Color(c.c1))
	var cn = UI.lbl(c.short, 30, fg, "xbold")
	cn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sv.add_child(cn)
	var f = G.next_user_fixture()
	if f != null:
		var fl = UI.wrap("First up: %s (%s), %s" % [s.clubs[f.a if f.h == c.id else f.h].name, "H" if f.h == c.id else "A", G.fmt_date(f.day)], 15, Color(fg, 0.85), "semi")
		fl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sv.add_child(fl)
	side.add_child(sv)
	cols_.add_child(side)
	pv.add_child(cols_)
	holder.add_child(paper)
	var bt = UI.btn("Meet the board", func(): UI.main.root("intro", {"kind": "board"}), "gold", "chevron-right", 54)
	bt.custom_minimum_size = Vector2(300, 54)
	bt.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	holder.add_child(bt)
	paper.pivot_offset = Vector2(440, 200)
	paper.rotation = -0.5
	paper.scale = Vector2(0.2, 0.2)
	paper.modulate.a = 0.0
	var tw = create_tween().set_parallel(true)
	tw.tween_property(paper, "rotation", -0.012, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(paper, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(paper, "modulate:a", 1.0, 0.3)
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

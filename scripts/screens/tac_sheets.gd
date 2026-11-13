extends RefCounted
# Pop-up sheets shared by Tactics and the first-day setup: choosing a playstyle and a link-up play.


static func pick_best_style(done: Callable):
	# first day in the job (or the first load of an older career): what kind of football is this manager known for?
	var u = G.s.user
	var c = G.uc()
	var build_sheet = func(v):
		v.add_child(UI.wrap("Every manager has a way of playing he knows best. Choose yours: you start highly rated in it and average in the rest. All five improve as you use them and with each coaching badge.", 19, UI.MUTED))
		for i in G.TC.STYLES.size():
			var sd = G.TC.STYLES[i]
			var card = UI.panel(UI.CARD, 14, 16, 10, UI.LINE)
			var h = UI.hb(12)
			var tv = UI.vb(0)
			tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tv.add_child(UI.lbl(sd.n, 25, UI.TEXT, "disp"))
			tv.add_child(UI.wrap(sd.d, 17, UI.MUTED))
			h.add_child(tv)
			var n = 0
			for k in range(1, 11):
				if c.xi[k] >= 0 and G.TC.best_fit_role(G.s.players[c.xi[k]], c.slots[k][0], i) != "":
					n += 1
			h.add_child(UI.caps("%d of 10 in your XI\nhave a role for it" % n, 14, UI.GREEN if n >= 8 else (UI.AMBER if n >= 6 else UI.MUTED)))
			card.add_child(h)
			var idx = i
			UI.tap(card, func():
				UI.confirm("%s as your best playstyle?" % sd.n, "This is permanent. You start highly rated in %s and average in the other four; the others still improve with use and with coaching badges, but your best style cannot be picked again." % sd.n, "Lock it in", func():
					u.prof = G.TC.start_prof(idx, int(u.get("badge", 2)))
					G.TC.set_style(c, idx)
					done.call(), false, func(): pick_best_style.call_deferred(done)))
			v.add_child(card)
	UI.sheet("Your best playstyle", build_sheet)


static func pick_link(replace: int, done: Callable, intro := ""):
	var c = G.uc()
	var u = G.s.user
	var st = G.TC.style_of(c)
	var build_sheet = func(v):
		v.add_child(UI.wrap(intro if intro != "" else "A link-up play is your signature move. It switches on when two players who fit its slots are in your XI, and gets stronger the more they play together.", 19, UI.MUTED))
		for id in G.TC.LINK_ORDER:
			if id in u.links:
				continue
			var L = G.TC.LINKS[id]
			var pr = G.TC.user_pair(id, c)
			var card = UI.panel(UI.CARD, 14, 16, 10, UI.GREEN if not pr.is_empty() else UI.LINE)
			var cv = UI.vb(2)
			var th = UI.hb(8)
			th.add_child(UI.lbl(L.n, 24, UI.TEXT, "disp"))
			if st in L.style:
				th.add_child(UI.chip("SUITS YOUR STYLE", Color(UI.GREEN, 0.14), UI.GREEN, 13))
			cv.add_child(th)
			cv.add_child(UI.wrap(L.d, 17, UI.MUTED))
			cv.add_child(UI.lbl_fill("%s: %s at %s   ·   %s: %s at %s" % [L.a.t, G.TC.slot_need(L.a), "/".join(L.a.pos), L.b.t, G.TC.slot_need(L.b), "/".join(L.b.pos)], 14, UI.DIM))
			if not pr.is_empty():
				cv.add_child(UI.lbl_fill("Ready now: %s to %s" % [G.pname(G.s.players[pr[0]]), G.pname(G.s.players[pr[1]])], 17, UI.GREEN, "semi"))
			else:
				var fa = G.TC.slot_fits(L.a, c).size()
				var fb = G.TC.slot_fits(L.b, c).size()
				cv.add_child(UI.lbl_fill("Not in this XI · %d in the squad fit %s, %d fit %s" % [fa, L.a.t.to_lower(), fb, L.b.t.to_lower()], 16, UI.AMBER if fa > 0 and fb > 0 else UI.RED))
			card.add_child(cv)
			var lid = id
			UI.tap(card, func():
				UI.confirm("Take %s?" % L.n, "This is permanent. Link-up plays cannot be swapped for another later; you only gain more with each coaching badge." if replace < 0 else "This replaces the link-up play in that slot.", "Lock it in", func():
					if replace >= 0 and replace < u.links.size():
						u.links[replace] = lid
					else:
						u.links.append(lid)
					done.call(), false, func(): pick_link.call_deferred(replace, done, intro)))
			v.add_child(card)
	UI.sheet("Choose a link-up play", build_sheet)


static func first_setup(done: Callable):
	# two questions, asked once: best playstyle, then first link-up play
	pick_best_style(func():
		pick_link.call_deferred(-1, func():
			G.s.user["tac_set"] = true
			G.msg("Your football", "You have set out how you want to play: %s, with the %s link-up play.\n\nTactics has the detail: the Playstyle tab shows how well the squad fits and how familiar they are, and Link-ups shows which players switch your move on. Your proficiency grows as you use a style, and each coaching badge unlocks another link-up play." % [G.TC.STYLES[G.TC.style_of(G.uc())].n, G.TC.LINKS[G.s.user.links[-1]].n], "info")
			done.call(), "Now your signature move. Pick one link-up play; each coaching badge unlocks another. Green ones already have a pair in your XI."))

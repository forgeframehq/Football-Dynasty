extends "res://scripts/screens/screen.gd"
# Another club's squad (scouting view).


func build():
	var c = G.s.clubs[args.cid]
	body.add_child(UI.topbar(c.name))
	var v = content(8)
	var head = UI.card()
	var h = UI.hb(18)
	h.add_child(UI.badge(c, 92))
	var hv = UI.vb(4)
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lgd = G.s.leagues[c.lg]
	hv.add_child(UI.caps(lgd.name if lgd.roe else "%s · %s" % [lgd.name, G.LG.ordinal(G.LG.position(c.id))], 21, UI.accent))
	hv.add_child(UI.stars(c.rep))
	if c.stadium != "":
		hv.add_child(UI.lbl_fill(c.stadium, 21, UI.MUTED))
	hv.add_child(UI.lbl_fill("%s · %s" % [c.formation, G.money(c.budget) + " budget"], 21, UI.MUTED))
	h.add_child(hv)
	var tr = G.team_ratings(c.id)
	h.add_child(UI.ovr(tr.ovr, 34))
	head.add_child(h)
	v.add_child(head)
	v.add_child(UI.sp(0, 4))
	var list = []
	for pid in c.players:
		list.append(G.s.players[pid])
	list.sort_custom(func(a, b): return a.ovr > b.ovr)
	for p in list:
		var pid = p.id
		v.add_child(UI.player_row(p, func(): UI.main.open("player", {"pid": pid})))

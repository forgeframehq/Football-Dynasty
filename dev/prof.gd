extends RefCounted
static func run(node):
	G.new_game("T", 1)
	var fx = G.s.fixtures.slice(0, 300)
	var t = Time.get_ticks_usec()
	for f in fx:
		G.lineup(f.h, f.a); G.lineup(f.a, f.h)
	print("lineups us/match: ", (Time.get_ticks_usec() - t) / 300)
	t = Time.get_ticks_usec()
	var sims = []
	for f in fx:
		sims.append(G.new_sim(f, false))
	print("setup us/match: ", (Time.get_ticks_usec() - t) / 300)
	t = Time.get_ticks_usec()
	for sm in sims:
		sm.run_to_end()
	print("run us/match: ", (Time.get_ticks_usec() - t) / 300)
	t = Time.get_ticks_usec()
	for sm in sims:
		G.apply_match(sm)
	print("apply us/match: ", (Time.get_ticks_usec() - t) / 300)
	t = Time.get_ticks_usec()
	for i in 30:
		G.s.day += 1
		G.start_of_day()
	print("start_of_day us: ", (Time.get_ticks_usec() - t) / 30)
	t = Time.get_ticks_usec()
	G.save_game()
	print("save us: ", (Time.get_ticks_usec() - t))
	node.get_tree().quit()

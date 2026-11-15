extends RefCounted
# Managers of the other clubs (G.MG). Each has a name, a reputation and a memory of you: the results between
# you, and a feud level (0-100) that rises with heavy defeats, derbies and what you say about him, and cools with
# time and respect. Feuds bring mind games before matches, digs on social media and a fired-up opponent.
# Struggling clubs sack their managers from October to April; the replacement may be a sacked manager or one of
# your former staff.
#
# Save: s.mgrs {cid: mgr}, s.mgr_free [mgr] (out of work), s.mgr_log [{d, t}] (sackings and appointments).
# mgr: fn, ln, nat, by, rep, since (season), feud, vs [won, drawn, lost against you, from his side], sacked.

const LOG_MAX = 40


static func ensure():
	var s = G.s
	if not s.has("mgrs"):
		s["mgrs"] = {}
		s["mgr_free"] = []
		s["mgr_log"] = []


static func gen(c: Dictionary) -> Dictionary:
	var s = G.s
	var rng = G.rng
	var nat = s.leagues[c.lg].country if rng.randf() < 0.65 else s.leagues[rng.randi() % s.leagues.size()].country
	var nm = DB.random_name(nat, rng)
	return {"fn": nm[0], "ln": nm[1], "nat": nat, "by": G.cur.year - rng.randi_range(38, 66), "rep": clampi(int(c.rep) + rng.randi_range(-8, 4), 30, 95),
		"since": s.season - rng.randi_range(0, 4), "feud": 0, "vs": [0, 0, 0], "sacked": 0}


static func of(cid: int) -> Dictionary:
	# the manager of a club, made the first time anyone asks
	ensure()
	var s = G.s
	if not s.mgrs.has(cid):
		s.mgrs[cid] = gen(s.clubs[cid])
	return s.mgrs[cid]


static func face(m: Dictionary) -> Dictionary:
	# every AI manager gets a face from the face creator's parts, fixed by his name
	if not m.has("face"):
		m["face"] = load("res://scripts/widgets/face.gd").random(("%s %s" % [m.fn, m.ln]).hash())
	return m.face


static func nm(m: Dictionary) -> String:
	return "%s %s" % [m.fn, m.ln]


static func age(m: Dictionary) -> int:
	return G.cur.year - int(m.by)


static func feud_word(f: float) -> String:
	if f >= 75: return "Bitter rivals"
	if f >= 50: return "Feud"
	if f >= 25: return "Needle"
	return "Cordial"


static func _log(t: String):
	var s = G.s
	s.mgr_log.push_front({"d": s.day, "t": t})
	while s.mgr_log.size() > LOG_MAX:
		s.mgr_log.pop_back()


# ---------------------------------------------------------------- you and him

static func after_match(oid: int, gf: int, ga: int, derby: bool):
	# gf/ga from your side
	var m = of(oid)
	var d = gf - ga
	if d > 0:
		m.vs[2] += 1
	elif d < 0:
		m.vs[0] += 1
	else:
		m.vs[1] += 1
	var add = 0.0
	if d >= 3:
		add += 14.0          # a hiding is not forgotten
	elif d > 0:
		add += 5.0
	elif d <= -3:
		add -= 4.0           # he is gracious when he wins big
	if derby:
		add += 8.0
	if G.rng.randf() < 0.3 and d > 0:
		add += 6.0           # a row on the touchline
	m.feud = clamp(float(m.feud) + add, 0.0, 100.0)
	# a sore loser has his say
	if d > 0 and m.feud >= 45 and G.rng.randf() < 0.6:
		var lines = ["We were the better side for long spells. The officials will want to watch it back.", "They will not play like that every week. We move on.",
			"I did not see a team that deserved three points. I saw a team that got lucky.", "Some people talk a lot. Today they were fortunate."]
		var line = lines[G.rng.randi() % lines.size()]
		G.msg("%s hits out" % m.ln, "%s, manager of %s, after the match: \"%s\"" % [nm(m), G.s.clubs[oid].name, line], "info")
		G.SOC.manager_post(oid, line)


static func press(kind: String):
	# your answer to "what do you make of the opposition manager's comments?"
	var f = G.next_user_fixture()
	if f == null:
		return
	var oid = f.a if f.h == G.s.user.club else f.h
	var m = of(oid)
	if kind == "bold":
		m.feud = min(100.0, float(m.feud) + 15.0)
		G.SOC.manager_post(oid, ["Interesting words from %s. We will answer on the pitch." % G.s.user.name, "I don't do talking in the papers. Saturday will do the talking."][G.rng.randi() % 2])
	elif kind == "calm":
		m.feud = max(0.0, float(m.feud) - 10.0)


static func cool_down():
	# feuds fade a little every month
	for cid in G.s.mgrs:
		var m = G.s.mgrs[cid]
		if float(m.feud) > 0:
			m.feud = max(0.0, float(m.feud) - 3.0)


static func pre_match():
	# two days before a match against a feuding manager, the mind games start
	var s = G.s
	var f = G.next_user_fixture()
	if f == null or f.day - s.day != 2 or f.get("fr", false):
		return
	var oid = f.a if f.h == s.user.club else f.h
	var m = of(oid)
	if float(m.feud) < 40 or int(s.user.get("mind_day", -9)) == f.day:
		return
	s.user["mind_day"] = f.day
	var lines = ["Everyone knows what %s is like. My players know what to do." % s.user.name, "They have spent a lot of money. Now let us see if they can handle a proper game.",
		"I have nothing to prove to %s. He has plenty to prove to me." % s.user.name, "Their fans will be nervous. They should be."]
	var line = lines[G.rng.randi() % lines.size()]
	G.msg("Mind games from %s" % m.ln, "Ahead of the game, %s (%s) said: \"%s\"\n\nYou can answer him at your press conference." % [nm(m), s.clubs[oid].name, line], "info")
	G.SOC.manager_post(oid, line)


static func fired_up(oid: int) -> float:
	# a manager with a grudge gets a little more out of his players against you
	if not G.s.has("mgrs") or not G.s.mgrs.has(oid):
		return 0.0
	return 0.012 if float(G.s.mgrs[oid].feud) >= 60 else (0.005 if float(G.s.mgrs[oid].feud) >= 35 else 0.0)


# ---------------------------------------------------------------- the sack race

static func pressure(cid: int) -> float:
	# 0 calm, 1 gone: how far below expectations the club is (league rank of reputation v table position)
	var s = G.s
	var c = s.clubs[cid]
	if c.t.p < 6:
		return 0.0
	var lg = s.leagues[c.lg]
	var reps = lg.clubs.map(func(x): return s.clubs[x].rep)
	reps.sort()
	reps.reverse()
	var exp = reps.find(c.rep) + 1
	var pos = G.LG.position(cid)
	var n = float(lg.clubs.size())
	var p = (pos - exp) / n
	p += 0.08 * c.form.slice(-5).count("L") - 0.05 * c.form.slice(-5).count("W")
	return clamp(p * 1.6, 0.0, 1.0)


static func hot_seat(lg := -1) -> Array:
	# [cid, pressure] for every club with a manager under pressure, worst first
	var s = G.s
	var out = []
	for c in s.clubs:
		if c.id == s.user.club or (lg >= 0 and c.lg != lg):
			continue
		var p = pressure(c.id)
		if p > 0.15:
			out.append([c.id, p])
	out.sort_custom(func(a, b): return a[1] > b[1])
	return out


static func monthly():
	var s = G.s
	ensure()
	cool_down()
	if not (G.cur.month >= 10 or G.cur.month <= 4):
		return
	var sacks = 0
	for c in s.clubs:
		if c.id == s.user.club or sacks >= 3:
			continue
		var p = pressure(c.id)
		if p > 0.45 and G.rng.randf() < (p - 0.4) * 0.5:
			sack(c.id)
			sacks += 1


static func sack(cid: int):
	var s = G.s
	var c = s.clubs[cid]
	var old = of(cid)
	old.sacked = int(old.sacked) + 1
	old.feud = float(old.feud) * 0.5
	old["cid_was"] = cid
	s.mgr_free.append(old)
	_log("%s sacked by %s" % [nm(old), c.name])
	# who comes in: an out-of-work manager, or one of your former staff with the right profile
	var pick = null
	var best = -1.0
	for i in s.mgr_free.size():
		var m = s.mgr_free[i]
		if m == old:
			continue
		var v = float(m.rep) - abs(float(m.rep) - c.rep) * 0.6 + G.rng.randf() * 6.0
		if v > best:
			best = v
			pick = i
	var new_m
	var note = ""
	if pick != null and G.rng.randf() < 0.6:
		new_m = s.mgr_free[pick]
		s.mgr_free.remove_at(pick)
	else:
		new_m = gen(c)
		# sometimes a familiar face: a well-known former player gets his first job
		if G.s.has("staff") and G.rng.randf() < 0.35:
			for sid in s.staff_free:
				var st = s.staff[sid]
				if st.ex != null and int(st.ex.ovr) >= 74:
					new_m.fn = st.fn
					new_m.ln = st.ln
					new_m.nat = st.nat
					new_m.by = st.by
					note = " The former %s gets his first job in management." % st.ex.pos
					s.staff_free.erase(sid)
					break
	new_m.since = s.season
	new_m.feud = 0.0
	new_m.vs = [0, 0, 0]
	s.mgrs[cid] = new_m
	while s.mgr_free.size() > 30:
		s.mgr_free.pop_front()
	_log("%s appoint %s" % [c.name, nm(new_m)])
	var mine = s.leagues[c.lg].id == G.uc().lg
	G.msg("%s sack %s" % [c.short, old.ln], "%s have dismissed %s after a poor run (%s in the table). %s takes over.%s" % [c.name, nm(old), G.LG.ordinal(G.LG.position(cid)), nm(new_m), note], "info", null, false)
	G.SOC.news_post("%s have sacked %s. %s is the new manager.%s" % [c.name, nm(old), nm(new_m), note], mine)

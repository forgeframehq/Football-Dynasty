extends RefCounted
# Backroom staff (G.SF). Eight jobs at the manager's club, each filled by a person with ratings 1-20. They change
# real numbers: player growth, goalkeeper training, recovery, injury length, youth intakes, scouting speed, the
# assistant's half-time read and weekly notes, and a small match boost. Retired players can become staff.
#
# Save: s.staff {sid: person}, s.staff_free [sid] (the job market), s.staff_next, s.staff_tried {sid: day}.
# Club: c.staff {role: sid}. Person: id, fn, ln, nat, by (birth year), a {coach, tac, mot, gkc, fit, med, youth,
# judge}, spec (the job he trained for), wage (a week), cend (season his contract ends), club, ex (former player:
# {ovr, pos, club, own}), until (day an ex-player waits for you).

const ROLES = ["ass", "coach1", "coach2", "gk", "fit", "phys", "youth", "scout"]
const ROLE = {
	"ass": ["Assistant manager", ["tac", "mot"], "user-round-search"],
	"coach1": ["First-team coach", ["coach", "tac"], "clipboard-list"],
	"coach2": ["First-team coach", ["coach", "mot"], "clipboard-list"],
	"gk": ["Goalkeeping coach", ["gkc", "coach"], "shield"],
	"fit": ["Fitness coach", ["fit", "coach"], "dumbbell"],
	"phys": ["Head physio", ["med"], "stethoscope"],
	"youth": ["Head of youth", ["youth", "judge"], "graduation-cap"],
	"scout": ["Chief scout", ["judge"], "eye"],
}
const ATTR = ["coach", "tac", "mot", "gkc", "fit", "med", "youth", "judge"]
const ATTR_NAME = {"coach": "Coaching", "tac": "Tactics", "mot": "Motivation", "gkc": "Goalkeeping", "fit": "Fitness", "med": "Medical", "youth": "Youth work", "judge": "Judging talent"}
const EMPTY = 6.0    # an empty job counts as a poor stand-in


static func ensure():
	var s = G.s
	if not s.has("staff"):
		s["staff"] = {}
		s["staff_free"] = []
		s["staff_next"] = 1
		s["staff_tried"] = {}
	var c = G.uc()
	if c != null and not c.has("staff"):
		c["staff"] = {}
		var q = clampi(int((c.rep - 42.0) / 3.2), 6, 17)
		for r in ROLES:
			var p = gen(r, q + G.rng.randi_range(-2, 1), s.leagues[c.lg].country)
			hire(p, r, 2 + G.rng.randi_range(0, 1), true)
	if s.staff_free.size() < 30:
		refill(60 - s.staff_free.size())


static func gen(spec: String, q: int, nat := "") -> Dictionary:
	var s = G.s
	var rng = G.rng
	q = clampi(q, 3, 20)
	if nat == "":
		nat = s.leagues[rng.randi() % s.leagues.size()].country
	var nm = DB.random_name(nat, rng)
	var a = {}
	for k in ATTR:
		a[k] = clampi(q - 5 + rng.randi_range(-4, 3), 1, 20)
	for k in ROLE[spec][1]:
		a[k] = clampi(q + rng.randi_range(-2, 2), 1, 20)
	var age = rng.randi_range(34, 64)
	var p = {"id": s.staff_next, "fn": nm[0], "ln": nm[1], "nat": nat, "by": G.cur.year - age, "a": a, "spec": spec,
		"wage": 0, "cend": s.season + 2, "club": -1, "ex": null}
	s.staff_next += 1
	p.wage = wage_for(p)
	s.staff[p.id] = p
	return p


static func wage_for(p: Dictionary) -> int:
	var q = rating(p, p.spec)
	var w = 900.0 * pow(1.28, q - 8.0)
	if p.ex != null:
		w *= 1.0 + max(0.0, float(p.ex.ovr) - 75.0) * 0.04   # a big name costs more
	return G.nice(int(w))


static func refill(n: int):
	var s = G.s
	for i in n:
		var r = ROLES[G.rng.randi() % ROLES.size()]
		var q = int(clamp(G.rng.randfn(10.5, 3.2), 4, 19))
		var p = gen(r, q)
		s.staff_free.append(p.id)


static func age(p: Dictionary) -> int:
	return G.cur.year - int(p.by)


static func nm(p: Dictionary) -> String:
	return "%s %s" % [p.fn, p.ln]


static func rating(p: Dictionary, role: String) -> float:
	var t = 0.0
	var ks = ROLE[role][1]
	for k in ks:
		t += float(p.a[k])
	return t / ks.size()


static func best_role(p: Dictionary) -> String:
	var best = p.spec
	for r in ROLES:
		if rating(p, r) > rating(p, best) + 0.5:
			best = r
	return best


static func who(role: String):
	# the person in this job at the manager's club, or null
	var c = G.uc()
	if c == null or not c.has("staff"):
		return null
	var sid = c.staff.get(role, -1)
	return G.s.staff.get(sid, null)


static func r(role: String) -> float:
	# rating used by the game for a job; an empty job is a poor stand-in
	var p = who(role)
	return rating(p, role) if p != null else EMPTY


static func wage_bill() -> int:
	var t = 0
	var c = G.uc()
	if c == null or not c.has("staff"):
		return 0
	for role in c.staff:
		var p = G.s.staff.get(c.staff[role], null)
		if p != null:
			t += int(p.wage)
	return t


static func hire(p: Dictionary, role: String, years: int, quiet := false):
	var s = G.s
	var c = G.uc()
	var old = who(role)
	if old != null:
		release(old, true)
	# the same person cannot hold two jobs
	for k in c.staff.keys():
		if c.staff[k] == p.id:
			c.staff.erase(k)
	c.staff[role] = p.id
	p.club = c.id
	p.cend = s.season + years
	s.staff_free.erase(p.id)
	p.erase("until")
	if not quiet:
		G.msg("%s joins as %s" % [nm(p), ROLE[role][0].to_lower()], "%s (%d, %s) has signed a %d-year deal at %s a week.%s" % [nm(p), age(p), p.nat, years, G.money(p.wage), (" He played as a %s, peaking at %d." % [p.ex.pos, int(p.ex.ovr)]) if p.ex != null else ""], "info")


static func payoff(p: Dictionary) -> int:
	# compensation to end a contract early: half of what is left
	var yrs = max(0, int(p.cend) - G.s.season)
	return int(p.wage * 52 * max(0.25, yrs) * 0.5)


static func release(p: Dictionary, replaced := false):
	var s = G.s
	var c = G.uc()
	for k in c.staff.keys():
		if c.staff[k] == p.id:
			c.staff.erase(k)
	var pay = payoff(p)
	c.budget = max(0, c.budget - pay)
	p.club = -1
	if not (p.id in s.staff_free):
		s.staff_free.append(p.id)
	if not replaced:
		G.msg("%s leaves the club" % nm(p), "His contract has been ended. Compensation of %s comes out of the transfer budget." % G.money(pay), "info")


static func ask(p: Dictionary, role: String) -> Dictionary:
	# what he wants and how likely he is to say yes: big names prefer big clubs
	var c = G.uc()
	var q = rating(p, role)
	var want = q * 3.4 + 22.0
	if p.ex != null:
		want += (float(p.ex.ovr) - 70.0) * 0.4
	var chance = clamp(0.92 - max(0.0, want - c.rep) * 0.035, 0.12, 0.95)
	if p.ex != null and p.ex.get("own", false):
		chance = min(0.98, chance + 0.35)      # your own former player wants to stay
	var wage = int(p.wage * (1.0 + (0.12 if role != p.spec else 0.0)))
	return {"wage": G.nice(wage), "chance": chance}


static func offer(p: Dictionary, role: String, years: int) -> String:
	# "" when hired, or the reason he said no
	var s = G.s
	var t = int(s.staff_tried.get(p.id, -99))
	if s.day - t < 14:
		return "%s turned you down recently. Try again in %d days." % [p.ln, 14 - (s.day - t)]
	var a = ask(p, role)
	var h = float((p.id * 7919 + s.day * 31 + G.uc().id) % 1000) / 1000.0
	if h > a.chance:
		s.staff_tried[p.id] = s.day
		return "%s has turned the job down. He wants a bigger club." % nm(p)
	p.wage = a.wage
	hire(p, role, years)
	return ""


# ---------------------------------------------------------------- effects

static func growth_mult(p: Dictionary) -> float:
	if p.get("pos", "") == "GK":
		return 1.0 + (r("gk") - 10.0) * 0.025
	var m = 1.0 + ((r("coach1") + r("coach2")) / 2.0 - 10.0) * 0.02
	if G.age(p) <= 21:
		m *= 1.0 + (r("youth") - 10.0) * 0.01
	return m


static func recover_bonus() -> int:
	return int(round((r("fit") - 10.0) / 4.0))


static func injury_mult() -> float:
	return clamp(1.1 - (r("phys") - 10.0) * 0.025, 0.8, 1.25)


static func youth_bonus() -> Array:
	# [rating points now, potential points, extra prospects]
	var y = r("youth")
	return [int((y - 10.0) / 3.0), int((y - 10.0) / 2.0), 1 if y >= 16 else 0]


static func scout_bonus() -> int:
	return int((r("scout") - 10.0) / 4.0)


static func match_boost() -> float:
	return (r("ass") - 10.0) * 0.0008


static func effect_text(role: String) -> String:
	var v = r(role)
	match role:
		"ass": return "Half-time reads and weekly notes · match %+.1f%%" % (match_boost() * 100.0)
		"coach1", "coach2": return "Player growth %+d%%" % int(round(((r("coach1") + r("coach2")) / 2.0 - 10.0) * 2.0))
		"gk": return "Goalkeeper growth %+d%%" % int(round((v - 10.0) * 2.5))
		"fit": return "Recovery %+d a day" % recover_bonus()
		"phys": return "Injuries %d%% %s" % [abs(int(round((injury_mult() - 1.0) * 100))), "longer" if injury_mult() > 1.0 else "shorter"]
		"youth":
			var yb = youth_bonus()
			return "Intake %+d now, %+d potential%s" % [yb[0], yb[1], " · extra prospect" if yb[2] > 0 else ""]
		"scout": return "Reports %+d days%s" % [-scout_bonus(), " · 4 names" if v >= 15 else ""]
	return ""


# ---------------------------------------------------------------- retired players

static func from_player(p: Dictionary, own: bool) -> Dictionary:
	# a retiring footballer becomes someone you can hire, with ratings that follow how he played
	var s = G.s
	var o = float(p.ovr)
	var at = p.get("at", [])
	var base = clamp((o - 58.0) / 2.6, 5.0, 17.0)
	var spec = "coach1"
	if p.pos == "GK":
		spec = "gk"
	elif G.LINE[p.pos] == 2:
		spec = "ass" if G.rng.randf() < 0.5 else "coach2"
	elif G.rng.randf() < 0.25:
		spec = "youth"
	var st = gen(spec, int(base), p.nat)
	st.fn = p.fn
	st.ln = p.ln
	st.by = int(p.by)
	if at.size() >= 18:
		st.a.tac = clampi(int(base - 2 + (float(at[9]) - 60.0) / 8.0 + G.rng.randi_range(-1, 2)), 3, 20)
	st.a.mot = clampi(st.a.mot + int(G.age(p) >= 35) + G.rng.randi_range(0, 2), 1, 20)
	st.ex = {"ovr": int(p.ovr), "pos": p.pos, "club": s.clubs[p.club].name if p.club >= 0 else "", "own": own}
	st.wage = wage_for(st)
	if own:
		st.wage = G.nice(int(st.wage * 0.8))
	st["until"] = s.day + (90 if own else 200)
	s.staff_free.append(st.id)
	return st


static func on_retire(p: Dictionary, mine: bool):
	if not G.s.has("staff"):
		return
	if mine and p.get("staff_offer", false):
		var st = from_player(p, true)
		var role = best_role(st)
		var free = ""
		for k in ROLES:
			if who(k) == null and (free == "" or k == role):
				free = k
		if free != "":
			st.wage = ask(st, free).wage
			hire(st, free, 2, true)
			G.msg("%s joins your staff" % nm(st), "%s has retired and, as you offered, stays at the club as %s on %s a week." % [nm(st), ROLE[free][0].to_lower(), G.money(st.wage)], "info")
		else:
			G.msg("%s wants to coach" % nm(st), "%s has retired and would love a job on your staff. Every job is filled; he waits in Staff > Find staff for three months, at a lower wage than anyone else would charge." % nm(st), "info")
		return
	if mine and p.ovr >= 62:
		var st2 = from_player(p, true)
		G.msg("%s retires" % nm(st2), "%s has hung up his boots and would consider a role on your staff (best as %s, rating %.0f). He is in Staff > Find staff for three months." % [nm(st2), ROLE[best_role(st2)][0].to_lower(), rating(st2, best_role(st2))], "info")
	elif p.ovr >= 70 and G.rng.randf() < 0.5:
		from_player(p, false)


# ---------------------------------------------------------------- time

static func weekly():
	ensure()
	var s = G.s
	# ex-players stop waiting; the market turns over a little
	for i in range(s.staff_free.size() - 1, -1, -1):
		var p = s.staff.get(s.staff_free[i], null)
		if p == null:
			s.staff_free.remove_at(i)
		elif p.has("until") and s.day > int(p.until):
			s.staff_free.remove_at(i)
			s.staff.erase(p.id)
	if G.rng.randf() < 0.5 and s.staff_free.size() > 40:
		var k = s.staff_free[G.rng.randi() % s.staff_free.size()]
		if not s.staff[k].has("until"):
			s.staff_free.erase(k)
			s.staff.erase(k)
	if s.staff_free.size() < 55:
		refill(2)
	# keep the market a sensible size: the oldest names that are not your own former players drop off first
	var i = 0
	while s.staff_free.size() > 90 and i < s.staff_free.size():
		var p2 = s.staff[s.staff_free[i]]
		if p2.ex != null and p2.ex.get("own", false):
			i += 1
			continue
		s.staff_free.remove_at(i)
		s.staff.erase(p2.id)
	notes()


static func season_end():
	# contracts that run out end; the person goes back on the market
	var s = G.s
	var c = G.uc()
	if not c.has("staff"):
		return
	var gone = []
	for role in c.staff.keys():
		var p = s.staff.get(c.staff[role], null)
		if p != null and int(p.cend) <= s.season:
			gone.append("%s (%s)" % [nm(p), ROLE[role][0].to_lower()])
			c.staff.erase(role)
			p.club = -1
			s.staff_free.append(p.id)
	if gone.size() > 0:
		G.msg("Staff contracts ended", "These staff have left at the end of their contracts: %s. Find replacements in Staff." % ", ".join(gone), "contract", null, true)


static func expiring() -> Array:
	var out = []
	var c = G.uc()
	for role in c.get("staff", {}):
		var p = G.s.staff.get(c.staff[role], null)
		if p != null and int(p.cend) <= G.s.season:
			out.append(p)
	return out


# ---------------------------------------------------------------- the assistant

static func notes():
	# every Monday the assistant writes up what he has noticed; a better assistant notices more
	var a = who("ass")
	if a == null:
		return
	var s = G.s
	var c = G.uc()
	var q = rating(a, "ass")
	var tips = []
	var avg = 0.0
	var n = 0
	for pid in c.xi:
		if pid >= 0:
			avg += s.players[pid].ovr
			n += 1
	avg /= max(1, n)
	for i in 11:
		var pid = c.xi[i]
		if pid < 0:
			tips.append([3, "There is an empty place in the starting XI."])
			continue
		var p = s.players[pid]
		if p.inj > 0:
			tips.append([3, "%s is injured but still in the XI." % G.pname(p)])
		elif p.cond < 78:
			tips.append([2, "%s is at %d%% fitness. I would rest him for the next match." % [G.pname(p), int(p.cond)]])
		var st = G.RL.stars(p, c.roles[i])
		if st <= 2:
			tips.append([1, "%s does not suit the %s role. Another role, or another player, would get more out of the position." % [G.pname(p), G.RL.ROLES[c.roles[i]].n]])
	# better players waiting on the bench
	for pid in c.bench:
		var b = s.players[pid]
		if b.ovr >= avg + 2 and G.available(b):
			tips.append([1, "%s (%d) is on the bench and better than most of the XI." % [G.pname(b), b.ovr]])
			break
	for pid in c.players:
		var p = s.players[pid]
		if p.mor < 45 and p.ovr >= avg - 4:
			tips.append([2, "%s is unhappy (morale %d). A word from you would help." % [G.pname(p), int(p.mor)]])
		if p.cend <= s.season and p.ovr >= avg and G.cur.month in [1, 2, 3]:
			tips.append([1, "%s's contract ends this summer. Other clubs will be circling." % G.pname(p)])
	for role in ROLES:
		if who(role) == null:
			tips.append([1, "We have no %s. It costs us: open Staff to find one." % ROLE[role][0].to_lower()])
	if expiring().size() > 0 and G.cur.month in [3, 4, 5]:
		tips.append([1, "%d of the staff are out of contract this summer." % expiring().size()])
	if tips.is_empty():
		return
	tips.sort_custom(func(x, y): return x[0] > y[0])
	# a weak assistant misses things
	var keep = clampi(int(q / 4.0), 1, 5)
	var seen = []
	for t in tips:
		if seen.size() >= keep:
			break
		if G.rng.randf() < 0.45 + q * 0.03 and not (t[1] in seen):
			seen.append(t[1])
	if seen.is_empty():
		return
	var last = int(s.user.get("notes_day", -99))
	if s.day - last < 6:
		return
	s.user["notes_day"] = s.day
	G.msg("Assistant's notes", "From %s:\n\n• %s" % [nm(a), "\n• ".join(seen)], "info")


static func ht_lines(me: Dictionary, op: Dictionary, sim) -> Array:
	# extra half-time lines from a good assistant: who hurts us, and where they are tiring
	var a = who("ass")
	if a == null:
		return []
	var q = rating(a, "ass")
	var out = []
	if q >= 11:
		var best = -1
		var bs = -1.0
		for k in 11:
			var pid = op.xi[k]
			if pid >= 0 and sim.pm.has(pid):
				var v = sim.pm[pid].sh * 2.0 + sim.pm[pid].g * 4.0 + float(G.s.players[pid].ovr) * 0.05
				if v > bs:
					bs = v
					best = pid
		if best >= 0:
			out.append(["Their danger is %s. Tight marking from Tactics > Defence would quieten him." % G.pname(G.s.players[best]), UI.AMBER])
	if q >= 14:
		var tired = []
		for k in 11:
			var pid2 = op.xi[k]
			if pid2 >= 0 and sim.pm.has(pid2) and sim.pm[pid2].cond < 66:
				tired.append(G.pname(G.s.players[pid2]))
		if tired.size() > 0:
			out.append(["They are tiring: %s. Fresh legs or a faster tempo could hurt them." % ", ".join(tired.slice(0, 2)), UI.GREEN])
	return out

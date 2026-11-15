extends RefCounted
# Player stories (G.STY): things that happen in the dressing room and arrive as a message with choices. Each
# choice has real effects (morale, fan and board feeling, a player's form, money, a promise you must keep).
# A story message carries m.sty = {k: kind, p: player id, q: second player id} and m.ch = [labels]; the inbox
# shows the choices until one is picked (m.done = the chosen index).
#
# Save: s.user.sty_next (day the next story may come), s.user.sty_seen {kind+pid: day}, player keys
# st_prom {until, need, from} (a playing-time promise).

const GAP = [6, 12]


static func daily():
	var s = G.s
	var u = s.user
	_check_promises()
	if G.perk("Motivator"):
		for pid in G.uc().players:
			s.players[pid].mor = max(45.0, float(s.players[pid].mor))
	if s.day < int(u.get("sty_next", 0)):
		return
	if G.rng.randf() > 0.35:
		return
	var open = 0
	for m in s.inbox.slice(0, 20):
		if m.has("sty") and not m.has("done"):
			open += 1
	if open >= 2:
		return
	var tries = ["time", "hype", "home", "clash", "agent", "late", "veteran"]
	tries.shuffle()
	for k in tries:
		if _try(k):
			u["sty_next"] = s.day + G.rng.randi_range(GAP[0], GAP[1])
			return


static func _try(k: String) -> bool:
	match k:
		"time": return _time()
		"hype": return _hype()
		"home": return _home()
		"clash": return _clash()
		"agent": return _agent()
		"late": return _late()
		"veteran": return _veteran()
	return false


static func _seen(k: String, pid: int, days: int) -> bool:
	var seen = G.s.user.get("sty_seen", {})
	return G.s.day - int(seen.get("%s%d" % [k, pid], -999)) < days


static func _post(title: String, body: String, k: String, pid: int, choices: Array, q := -1):
	var s = G.s
	if not s.user.has("sty_seen"):
		s.user["sty_seen"] = {}
	s.user.sty_seen["%s%d" % [k, pid]] = s.day
	G.msg(title, body, "story", pid, false)
	var m = s.inbox[0]
	m["sty"] = {"k": k, "p": pid, "q": q}
	m["ch"] = choices


static func _squad() -> Array:
	var c = G.uc()
	var out = []
	for pid in c.players:
		var p = G.s.players[pid]
		if not p.get("youth", false):
			out.append(p)
	return out


static func _avg() -> float:
	var c = G.uc()
	var t = 0.0
	var n = 0
	for pid in c.xi:
		if pid >= 0:
			t += G.s.players[pid].ovr
			n += 1
	return t / max(1, n)


# ---------------------------------------------------------------- the stories

static func _time() -> bool:
	# a good player who is not playing wants answers
	var c = G.uc()
	var avg = _avg()
	for p in _squad():
		if p.id in c.xi or p.ovr < avg - 5 or G.age(p) < 19 or not G.available(p) or _seen("time", p.id, 120) or p.has("st_prom"):
			continue
		if p.mor < 68 and G.s.day > 30:
			_post("%s wants to play" % G.pname(p), "%s has knocked on your door. He feels he is good enough to start and is frustrated on the bench.\n\n\"I want to be part of this. If I'm not, I need to know.\"" % G.pfull(p), "time", p.id,
				["Promise him games (3 starts in 6 weeks)", "Tell him to fight for his place", "Say you'd listen to loan offers"])
			return true
	return false


static func _hype() -> bool:
	# a young player is flying and the media love him
	for p in _squad():
		if G.age(p) <= 21 and p.ss.ap >= 4 and float(p.form) >= 7.2 and not _seen("hype", p.id, 200):
			_post("The hype around %s" % G.pname(p), "Everyone is talking about %s. Pundits call him the best young player in the country, and a few big clubs have sent scouts.\n\nHow do you handle it?" % G.pfull(p), "hype", p.id,
				["Shield him: \"He has done nothing yet\"", "Talk him up: \"He can go all the way\"", "Say nothing"])
			return true
	return false


static func _home() -> bool:
	# a young player from abroad is struggling to settle
	var c = G.uc()
	var country = G.s.leagues[c.lg].country
	for p in _squad():
		if p.nat != country and G.age(p) <= 24 and p.mor < 72 and not _seen("home", p.id, 300):
			_post("%s is homesick" % G.pname(p), "%s is finding life away from %s hard. He has gone quiet in training and his family are worried.\n\nWhat do you do?" % [G.pfull(p), p.nat], "home", p.id,
				["Fly his family over (€25K from the budget)", "Arrange language lessons and a mentor", "He needs to adapt"])
			return true
	return false


static func _clash() -> bool:
	# two players fall out in training
	var c = G.uc()
	var pool = _squad().filter(func(x): return x.mor < 75 and G.age(x) >= 20)
	if pool.size() < 2 or c.form.slice(-3).count("L") < 1:
		return false
	pool.shuffle()
	var a = pool[0]
	var b = pool[1]
	if _seen("clash", a.id, 120):
		return false
	var sen = a if G.age(a) >= G.age(b) else b
	var jun = b if sen == a else a
	_post("Bust-up in training", "%s and %s had to be pulled apart at training this morning after a heated row. The rest of the squad are waiting to see what you do." % [G.pfull(a), G.pfull(b)], "clash", sen.id,
		["Fine them both", "Back the senior man (%s)" % G.pname(sen), "Clear-the-air meeting"], jun.id)
	return true


static func _agent() -> bool:
	# a top player's agent stirs interest from a bigger club
	var c = G.uc()
	var sq = _squad()
	sq.sort_custom(func(x, y): return x.ovr > y.ovr)
	var big = []
	for o in G.s.clubs:
		if o.rep > c.rep + 5 and o.lg != c.lg or (o.rep > c.rep + 8):
			big.append(o)
	if big.is_empty():
		return false
	for p in sq.slice(0, 3):
		if _seen("agent", p.id, 240) or G.age(p) > 30:
			continue
		var o = big[G.rng.randi() % big.size()]
		_post("%s's agent is talking" % G.pname(p), "%s's agent has told journalists his client \"would listen\" if %s came calling. The story is everywhere.\n\nYour response?" % [G.pfull(p), o.name], "agent", p.id,
			["He is not for sale", "Every player has a price", "Offer him a new contract"])
		return true
	return false


static func _late() -> bool:
	# someone keeps turning up late
	var sq = _squad()
	if sq.is_empty() or G.rng.randf() < 0.5:
		return false
	var p = sq[G.rng.randi() % sq.size()]
	if _seen("late", p.id, 200):
		return false
	_post("%s late again" % G.pname(p), "%s was late for training for the third time this month. The coaches want to know how you want it handled." % G.pfull(p), "late", p.id,
		["Fine him a week's wages", "A quiet word", "Drop him for the next match"])
	return true


static func _veteran() -> bool:
	# an older player in his last contract year thinks about stopping
	if not (G.cur.month in [2, 3, 4]):
		return false
	for p in _squad():
		var limit = 36 if p.pos == "GK" else 33
		if G.age(p) >= limit and p.cend <= G.s.season and not _seen("veteran", p.id, 300):
			_post("%s thinking of retiring" % G.pname(p), "%s (%d) has told you this could be his last season. He wants to know where he stands." % [G.pfull(p), G.age(p)], "veteran", p.id,
				["Persuade him to play one more year", "Offer him a staff role when he stops", "Let him decide"])
			return true
	return false


# ---------------------------------------------------------------- choices

static func choose(m: Dictionary, k: int) -> String:
	# applies the effects of a choice and returns the outcome line shown under the message
	var s = G.s
	var u = s.user
	if m.has("done") or not s.players.has(int(m.sty.p)):
		return ""
	m["done"] = k
	var p = s.players[int(m.sty.p)]
	var q = s.players.get(int(m.sty.get("q", -1)), null)
	var c = G.uc()
	var out = ""
	match str(m.sty.k):
		"time":
			if k == 0:
				p.mor = min(100.0, p.mor + 14.0)
				p["st_prom"] = {"until": s.day + 42, "need": 3, "from": int(p.ss.get("st", p.ss.ap))}
				out = "He leaves happy. You promised three starts in the next six weeks."
			elif k == 1:
				var tough = G.rng.randf() < 0.5
				p.mor = clamp(p.mor + (6.0 if tough else -10.0), 0.0, 100.0)
				out = "He takes it on the chin and trains harder." if tough else "He is not happy with that answer."
			else:
				p.mor = max(0.0, p.mor - 4.0)
				p.listed = true
				out = "He is on the transfer list. Clubs can now bid, loan offers included."
		"hype":
			if k == 0:
				p.form = clamp(float(p.form) + 0.1, 3.0, 10.0)
				out = "The pressure is off. He keeps his head down."
			elif k == 1:
				p.mor = min(100.0, p.mor + 10.0)
				u["fans"] = min(100.0, float(u.get("fans", 55.0)) + 2.0)
				if G.rng.randf() < 0.35:
					p.form = clamp(float(p.form) - 0.4, 3.0, 10.0)
					out = "The fans love it, but it may have gone to his head."
				else:
					out = "The fans love it, and he feels ten feet tall."
			else:
				out = "You leave the talking to others."
		"home":
			if k == 0:
				c.budget = max(0, c.budget - 25000)
				p.mor = min(100.0, p.mor + 18.0)
				out = "His family are here. He is smiling again."
			elif k == 1:
				p.mor = min(100.0, p.mor + 9.0)
				out = "Lessons are booked and a senior player is looking after him."
			else:
				p.mor = max(0.0, p.mor - 8.0)
				out = "He nods, but he is still struggling."
		"clash":
			if k == 0:
				p.mor = max(0.0, p.mor - 5.0)
				if q != null:
					q.mor = max(0.0, q.mor - 5.0)
				_squad_mor(2.0)
				out = "Both fined. The squad respects a firm hand."
			elif k == 1:
				p.mor = min(100.0, p.mor + 8.0)
				if q != null:
					q.mor = max(0.0, q.mor - 15.0)
				out = "The senior man is backed. The younger one feels hard done by."
			else:
				var ok = G.rng.randf() < 0.6
				for x in [p, q]:
					if x != null:
						x.mor = clamp(x.mor + (6.0 if ok else -3.0), 0.0, 100.0)
				out = "They shake hands. Water under the bridge." if ok else "The meeting goes badly; the atmosphere is still frosty."
		"agent":
			if k == 0:
				p.mor = clamp(p.mor + (4.0 if p.mor >= 60 else -6.0), 0.0, 100.0)
				u["fans"] = min(100.0, float(u.get("fans", 55.0)) + 3.0)
				out = "The fans cheer. He stays, for now."
			elif k == 1:
				p.listed = true
				u["fans"] = max(0.0, float(u.get("fans", 55.0)) - 4.0)
				out = "He is on the transfer list. Bids will follow, and the fans are unhappy."
			else:
				out = "Contract talks are open from his player page."
				UI.main.open("nego", {"pid": p.id, "mode": "renew"})
		"late":
			if k == 0:
				p.mor = max(0.0, p.mor - 8.0)
				_squad_mor(1.0)
				out = "Fined. The message is clear."
			elif k == 1:
				out = "A quiet word. He promises it won't happen again." if G.rng.randf() < 0.7 else "A quiet word, but he is late again the next day."
			else:
				p.mor = max(0.0, p.mor - 12.0)
				var i = c.xi.find(p.id)
				if i >= 0:
					c.xi[i] = -1
					G.fix_lineup()
				out = "Dropped. Nobody will be late again."
		"veteran":
			if k == 0:
				p["noret"] = true
				if G.rng.randf() < 0.65:
					p.cend = s.season + 1
					p.wage = int(p.wage * 0.75)
					out = "He agrees to one more year on reduced wages."
				else:
					p.erase("noret")
					out = "He thanks you, but his mind is made up."
			elif k == 1:
				p["staff_offer"] = true
				p.mor = min(100.0, p.mor + 6.0)
				out = "He is delighted. When he retires he joins your staff."
			else:
				out = "He will decide in the summer."
	m["out"] = out
	return out


static func _squad_mor(v: float):
	for pid in G.uc().players:
		G.s.players[pid].mor = clamp(G.s.players[pid].mor + v, 0.0, 100.0)


static func _check_promises():
	var s = G.s
	for pid in G.uc().players:
		var p = s.players[pid]
		if not p.has("st_prom"):
			continue
		var pr = p.st_prom
		var starts = int(p.ss.get("st", p.ss.ap)) - int(pr.from)
		if starts >= int(pr.need):
			p.erase("st_prom")
			p.mor = min(100.0, p.mor + 6.0)
			G.msg("%s: promise kept" % G.pname(p), "%s has had the games you promised him and is happy." % G.pfull(p), "story", pid)
		elif s.day >= int(pr.until):
			p.erase("st_prom")
			p.mor = max(0.0, p.mor - 25.0)
			G.msg("%s: promise broken" % G.pname(p), "You promised %s three starts in six weeks. He got %d. He feels let down, and the squad noticed." % [G.pfull(p), starts], "story", pid, true)
			_squad_mor(-2.0)


static func after_match(pts: int):
	# a captain who backs you after a bad run
	var c = G.uc()
	if c.form.slice(-3).count("L") >= 3 and int(c.get("capt", -1)) >= 0 and G.s.players.has(c.capt) and not _seen("capt", c.capt, 90):
		var p = G.s.players[c.capt]
		if not G.s.user.has("sty_seen"):
			G.s.user["sty_seen"] = {}
		G.s.user.sty_seen["capt%d" % p.id] = G.s.day
		G.s.user.conf = min(100.0, G.s.user.conf + 3.0)
		_squad_mor(3.0)
		G.msg("%s backs you" % G.pname(p), "Your captain %s, after a third straight defeat: \"The lads are behind the manager one hundred percent. We'll turn it round together.\"\n\nThe board noticed: confidence +3." % G.pfull(p), "story", p.id)
		G.SOC.player_post(p, "Tough run but this group sticks together. Behind the gaffer 100%. We go again.")

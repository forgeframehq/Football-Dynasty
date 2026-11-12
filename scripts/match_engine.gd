extends RefCounted
# Minute-by-minute match simulation used for every fixture in the game world.

# role -> [attack, midfield, defence] contribution weights
const ROLE_W = {"GK": [0.0, 0.0, 0.0], "CB": [.02, .1, 1.0], "LB": [.15, .25, .8], "RB": [.15, .25, .8], "CDM": [.1, .7, .6], "CM": [.3, 1.0, .3],
	"CAM": [.7, .8, .1], "LM": [.55, .6, .2], "RM": [.55, .6, .2], "LW": [.9, .3, .05], "RW": [.9, .3, .05], "ST": [1.0, .15, .02]}
const MENT = [[0.90, 1.08], [0.95, 1.04], [1.0, 1.0], [1.05, 0.96], [1.10, 0.90]]
const PRESS_MID = [0.98, 1.0, 1.03]
const PRESS_DRAIN = [0.9, 1.0, 1.2]
const TEMPO_SHOT = [0.94, 1.0, 1.06]
const TEMPO_DRAIN = [0.95, 1.0, 1.1]

const T_GOAL = ["GOAL! %s finds the net for %s!", "GOAL! %s makes no mistake — %s score!", "GOAL! A clinical finish from %s. %s celebrate!", "GOAL! %s buries it! The %s fans erupt!"]
const T_GOAL_LONG = ["GOAL! What a strike from %s! An unstoppable effort from distance for %s!", "GOAL! %s lets fly from range and it flies in for %s!"]
const T_WIDE = ["%s drags the shot wide.", "%s fires over the bar.", "%s snatches at it — well off target.", "%s can't keep the effort down."]
const T_BLOCK = ["%s's shot is blocked by a brave defender.", "%s shoots — charged down at the last moment.", "A crowd of bodies gets in the way of %s's strike."]
const T_BIG = ["What a chance! %s should have scored!", "Huge opportunity for %s — and it goes begging!"]
const T_FILL = ["%s are knocking it around patiently.", "%s probing for an opening.", "A good spell of possession for %s.", "%s win it back in midfield.", "The %s supporters are making themselves heard.", "%s build from the back.", "%s push men forward."]


var fx: Dictionary
var detailed := false
var sd: Array = []
var pm: Dictionary = {}
var minute := 0
var total := 90
var tick := 5
var phase := 0   # 0 pre, 1 first half, 2 half-time, 3 second half, 4 full-time
var events: Array = []
var ball := Vector2(0.5, 0.5)
var ball_side := 0
var ball_state := ""
var pens = null
var motm := -1
var rng: RandomNumberGenerator
var pl: Dictionary


func setup(f: Dictionary, lu_h: Dictionary, lu_a: Dictionary, det: bool):
	fx = f
	detailed = det
	tick = 5 if det else 15
	rng = G.rng
	pl = G.s.players
	sd = [_side(lu_h, true), _side(lu_a, false)]
	total = 90 + rng.randi_range(2, 6)
	recalc(0)
	recalc(1)


func _side(lu: Dictionary, home: bool) -> Dictionary:
	var d = {"club": G.s.clubs[lu.club], "cid": lu.club, "home": home, "xi": lu.xi.duplicate(), "bench": lu.bench.duplicate(), "formation": lu.formation, "roles": [],
		"ment": lu.ment, "press": lu.press, "tempo": lu.tempo, "att": 60.0, "mid": 60.0, "def": 60.0, "gk": 60.0, "goals": 0, "shots": 0, "sot": 0, "xg": 0.0,
		"corners": 0, "fouls": 0, "yc": 0, "rc": 0, "poss": 0, "subs": 0, "scorers": [], "user": lu.user, "auto": not lu.user, "midp": 1.0, "ps": 0.25, "w0": [], "w1": [], "t0": 0.0, "t1": 0.0}
	for sl in G.FORMATIONS[lu.formation]:
		d.roles.append(sl[0])
	for pid in d.xi:
		if pid >= 0:
			_pm(pid, true)
	for pid in d.bench:
		_pm(pid, false)
	return d


func _pm(pid: int, starter: bool):
	pm[pid] = {"cond": float(pl[pid].cond), "g": 0, "a": 0, "yc": 0, "rc": 0, "sv": 0, "sh": 0, "on": starter, "tin": 0 if starter else -1, "tout": -1, "inj": 0, "r": 6.0}


func set_formation(i: int, formation: String):
	var t = sd[i]
	t.formation = formation
	t.roles = []
	for sl in G.FORMATIONS[formation]:
		t.roles.append(sl[0])
	recalc(i)


func recalc(i: int):
	var t = sd[i]
	var a = 0.0
	var m = 0.0
	var d = 0.0
	var wa = 0.0
	var wm = 0.0
	var wd = 0.0
	t.gk = 30.0
	var w0 = []
	var w1 = []
	var t0 = 0.0
	var t1 = 0.0
	for k in 11:
		var role = t.roles[k]
		var w = ROLE_W[role]
		wa += w[0]
		wm += w[1]
		wd += w[2]
		var pid = t.xi[k]
		if pid < 0:
			w0.append(0.0)
			w1.append(0.0)
			continue
		var p = pl[pid]
		var x0 = 0.0 if k == 0 else (w[0] * 0.75 + 0.14) * pow(max(p.st[1], 30) / 65.0, 1.3)
		var x1 = 0.004 if k == 0 else (0.7 * w[0] + 0.5 * w[1] + 0.03) * pow(p.st[2] / 65.0, 3.0)
		w0.append(x0)
		w1.append(x1)
		t0 += x0
		t1 += x1
		var f = G.fit(p, role) * (0.86 + 0.14 * pm[pid].cond / 100.0) * (0.975 + 0.0005 * p.mor)
		var e = p.ovr * f
		if role == "GK":
			t.gk = e
			continue
		var st = p.st
		a += w[0] * (0.65 * e + 0.35 * f * (st[1] + st[3] + st[0]) / 3.0)
		m += w[1] * (0.65 * e + 0.35 * f * (st[2] + st[3]) / 2.0)
		d += w[2] * (0.65 * e + 0.35 * f * (st[4] + st[5]) / 2.0)
	var h = 1.03 if t.home else 1.0
	t.att = max(20.0, a / wa * MENT[t.ment][0] * h)
	t.mid = max(20.0, m / wm * PRESS_MID[t.press] * h)
	t.def = max(20.0, d / wd * MENT[t.ment][1] * h)
	t.midp = pow(t.mid, 2.6)
	t.w0 = w0
	t.w1 = w1
	t.t0 = t0
	t.t1 = t1
	if sd.size() == 2:
		for j in 2:
			sd[j].ps = clamp(0.252 * pow(sd[j].att / sd[1 - j].def, 2.1) * TEMPO_SHOT[sd[j].tempo], 0.05, 0.6)


func nm(pid: int) -> String:
	return G.pname(pl[pid])


func ev(type: String, side: int, text: String, pid := -1) -> Dictionary:
	var e = {"m": minute, "t": type, "s": side, "x": text, "p": pid}
	events.append(e)
	return e


func score_text() -> String:
	return "%s %d–%d %s" % [sd[0].club.name, sd[0].goals, sd[1].goals, sd[1].club.name]


func run_to_end():
	while phase != 4:
		step()


func resume():
	if phase == 2:
		phase = 3


func step() -> Array:
	var out = []
	if phase == 4:
		return out
	if phase == 0:
		phase = 1
		if detailed:
			out.append(ev("info", 0, "Kick-off at %s! %s get us under way." % [sd[0].club.stadium if sd[0].club.stadium != "" else "the home ground", sd[0].club.name]))
	if phase == 2:
		phase = 3
	minute += 1
	if minute % tick == 0:
		for i in 2:
			var t = sd[i]
			var dr = 0.27 * tick * PRESS_DRAIN[t.press] * TEMPO_DRAIN[t.tempo]
			for k in 11:
				var pid = t.xi[k]
				if pid >= 0:
					var q = pm[pid]
					q.cond = max(15.0, q.cond - dr * (1.25 - pl[pid].st[5] / 250.0) * (0.3 if k == 0 else 1.0))
			recalc(i)
	var ph = sd[0].midp
	var ai = 0 if rng.randf() < ph / (ph + sd[1].midp) else 1
	var at = sd[ai]
	var df = sd[1 - ai]
	at.poss += 1
	ball_side = ai
	var r = rng.randf()
	var ps = at.ps
	if rng.randf() < 0.0028:
		_shot(ai, out, true)
	elif r < ps:
		_shot(ai, out, false)
	else:
		var adv = 0.0
		if r < ps + 0.28:
			ball_state = "ATTACK"
			adv = rng.randf_range(0.64, 0.8)
		else:
			ball_state = ""
			adv = rng.randf_range(0.36, 0.6)
		ball = Vector2(adv if ai == 0 else 1.0 - adv, rng.randf_range(0.15, 0.85))
		if detailed and rng.randf() < 0.07:
			out.append(ev("info", ai, T_FILL[rng.randi() % T_FILL.size()] % at.club.name))
	if rng.randf() < 0.24:
		_foul(1 - ai if rng.randf() < 0.62 else ai, out)
	if rng.randf() < 0.0022:
		_injury(out)
	if minute >= 58:
		for i in 2:
			if sd[i].auto:
				_ai_manage(i, out)
	if minute == 45:
		phase = 2
		if detailed:
			out.append(ev("ht", 0, "Half-time: %s" % score_text()))
	elif minute >= total:
		_finish(out)
	return out


func _pick(t: Dictionary, mode: int, exclude := -1) -> int:
	if mode == 2:
		return t.xi[rng.randi_range(1, 10)]
	var ws = t.w0 if mode == 0 else t.w1
	var tot = t.t0 if mode == 0 else t.t1
	if tot <= 0.0:
		return -1
	for _try in 6:
		var x = rng.randf() * tot
		for k in 11:
			x -= ws[k]
			if x <= 0.0 and ws[k] > 0.0:
				if t.xi[k] != exclude:
					return t.xi[k]
				break
	return -1


func _shot(ai: int, out: Array, pen: bool):
	var at = sd[ai]
	var df = sd[1 - ai]
	var sh = _pick(at, 0)
	if sh < 0:
		return
	var p = pl[sh]
	var q = 0.77
	var kind = "pen"
	if pen:
		# best finisher on the pitch takes it
		var bs = -1
		for k in range(1, 11):
			if at.xi[k] >= 0 and pl[at.xi[k]].st[1] > bs:
				bs = pl[at.xi[k]].st[1]
				sh = at.xi[k]
		p = pl[sh]
		if detailed:
			out.append(ev("info", ai, "PENALTY to %s! %s steps up..." % [at.club.name, nm(sh)]))
	else:
		var r = rng.randf()
		if r < 0.12:
			q = 0.38
			kind = "big"
		elif r < 0.55:
			q = 0.11
			kind = "box"
		else:
			q = 0.035
			kind = "long"
		var se = (0.5 * p.st[1] + 0.5 * p.ovr) * (0.86 + 0.14 * pm[sh].cond / 100.0)
		q = min(0.9, q * pow(se / max(30.0, df.gk), 1.3))
	at.shots += 1
	at.xg += q
	pm[sh].sh += 1
	ball_state = "SHOT"
	ball = Vector2(0.93 if ai == 0 else 0.07, rng.randf_range(0.38, 0.62))
	var gk = df.xi[0]
	if rng.randf() < q:
		at.goals += 1
		at.sot += 1
		pm[sh].g += 1
		at.scorers.append({"pid": sh, "m": minute, "pen": pen})
		var asst = -1
		if not pen and rng.randf() < 0.72:
			asst = _pick(at, 1, sh)
			if asst >= 0:
				pm[asst].a += 1
		ball_state = "GOAL"
		if detailed:
			var tx = ""
			if pen:
				tx = "GOAL! %s sends the keeper the wrong way from the spot!" % nm(sh)
			elif kind == "long":
				tx = T_GOAL_LONG[rng.randi() % T_GOAL_LONG.size()] % [nm(sh), at.club.name]
			else:
				tx = T_GOAL[rng.randi() % T_GOAL.size()] % [nm(sh), at.club.name]
			if asst >= 0:
				tx += " Assist: %s." % nm(asst)
			out.append(ev("goal", ai, tx, sh))
		else:
			events.append({"m": minute, "t": "goal", "s": ai, "x": "", "p": sh})
		return
	var r3 = rng.randf()
	if r3 < (0.7 if pen else 0.42):
		at.sot += 1
		if gk >= 0:
			pm[gk].sv += 1
		if not pen and rng.randf() < 0.4:
			at.corners += 1
		if detailed:
			var tx = "SAVED! %s keeps out %s's penalty!" % [nm(gk) if gk >= 0 else "The keeper", nm(sh)] if pen else _save_text(sh, gk)
			out.append(ev("save", ai, tx, sh))
	elif r3 < 0.62 and not pen:
		if rng.randf() < 0.35:
			at.corners += 1
		if detailed:
			out.append(ev("miss", ai, T_BLOCK[rng.randi() % T_BLOCK.size()] % nm(sh), sh))
	else:
		if detailed:
			var tx = ""
			if pen:
				tx = "MISSED! %s puts the penalty wide!" % nm(sh)
			elif kind == "big":
				tx = T_BIG[rng.randi() % T_BIG.size()] % nm(sh)
			else:
				tx = T_WIDE[rng.randi() % T_WIDE.size()] % nm(sh)
			out.append(ev("miss", ai, tx, sh))


func _save_text(sh: int, gk: int) -> String:
	var g = nm(gk) if gk >= 0 else "the keeper"
	match rng.randi() % 3:
		0: return "%s tests the keeper — good save by %s." % [nm(sh), g]
		1: return "Big stop! %s is denied by %s." % [nm(sh), g]
	return "%s gets the shot away but %s holds on." % [nm(sh), g]


func _foul(i: int, out: Array):
	var t = sd[i]
	t.fouls += 1
	var r = rng.randf()
	if r >= 0.16:
		return
	var pid = _pick(t, 2)
	if pid < 0:
		return
	var q = pm[pid]
	if r < 0.005:
		_send_off(i, pid, out, "RED CARD! %s is sent off for a reckless challenge! %s are down to ten." % [nm(pid), t.club.name])
	elif r < 0.16:
		q.yc += 1
		t.yc += 1
		if q.yc >= 2:
			_send_off(i, pid, out, "Second yellow! %s is off — %s must finish with ten men." % [nm(pid), t.club.name])
		elif detailed:
			out.append(ev("yellow", i, "Yellow card for %s after a late challenge." % nm(pid), pid))


func _send_off(i: int, pid: int, out: Array, text: String):
	var t = sd[i]
	var q = pm[pid]
	q.rc = 1
	q.on = false
	q.tout = minute
	t.rc += 1
	t.xi[t.xi.find(pid)] = -1
	recalc(i)
	if detailed:
		out.append(ev("red", i, text, pid))


func _injury(out: Array):
	var i = rng.randi() % 2
	var t = sd[i]
	var k = rng.randi_range(0, 10)
	var pid = t.xi[k]
	if pid < 0 or (k == 0 and rng.randf() < 0.7):
		return
	var r = rng.randf()
	var days = rng.randi_range(3, 10)
	if r > 0.9:
		days = rng.randi_range(36, 120)
	elif r > 0.6:
		days = rng.randi_range(11, 35)
	pm[pid].inj = days
	var cands = _sub_candidates(i, k)
	if t.subs < 5 and cands.size() > 0:
		if detailed:
			out.append(ev("injury", i, "%s is down injured and can't continue." % nm(pid), pid))
		do_sub(i, k, cands[0], out)
	else:
		pm[pid].on = false
		pm[pid].tout = minute
		t.xi[k] = -1
		recalc(i)
		if detailed:
			out.append(ev("injury", i, "%s is injured and %s have no substitutes left — down to ten." % [nm(pid), t.club.name], pid))


func _sub_candidates(i: int, k: int) -> Array:
	var t = sd[i]
	var role = t.roles[k]
	var c = []
	for pid in t.bench:
		var p = pl[pid]
		if (p.pos == "GK") != (role == "GK"):
			continue
		c.append(pid)
	c.sort_custom(func(x, y): return pl[x].ovr * G.fit(pl[x], role) > pl[y].ovr * G.fit(pl[y], role))
	return c


func do_sub(i: int, k: int, in_pid: int, out = null):
	var t = sd[i]
	var o = t.xi[k]
	if o >= 0:
		pm[o].on = false
		pm[o].tout = minute
	t.xi[k] = in_pid
	t.bench.erase(in_pid)
	pm[in_pid].on = true
	pm[in_pid].tin = minute
	t.subs += 1
	recalc(i)
	if detailed:
		var e = ev("sub", i, "Substitution for %s: %s replaces %s." % [t.club.name, nm(in_pid), nm(o) if o >= 0 else "—"], in_pid)
		if out != null:
			out.append(e)


func swap_slots(i: int, k1: int, k2: int):
	var t = sd[i]
	var x = t.xi[k1]
	t.xi[k1] = t.xi[k2]
	t.xi[k2] = x
	recalc(i)


func _ai_manage(i: int, out: Array):
	var t = sd[i]
	var o = sd[1 - i]
	if minute == 70 and t.goals < o.goals:
		t.ment = min(4, t.ment + 1)
		recalc(i)
	elif minute == 80 and t.goals > o.goals:
		t.ment = max(1, t.ment - 1)
		recalc(i)
	if t.subs >= 3 or minute < 58 or minute % 9 != 4:
		return
	var worst = -1
	var wc = 200.0
	for k in range(1, 11):
		var pid = t.xi[k]
		if pid >= 0 and pm[pid].cond < wc:
			wc = pm[pid].cond
			worst = k
	if worst < 0:
		return
	var cands = _sub_candidates(i, worst)
	if cands.size() == 0:
		return
	var role = t.roles[worst]
	var cur_p = pl[t.xi[worst]]
	var cur_e = cur_p.ovr * G.fit(cur_p, role) * (0.86 + 0.14 * wc / 100.0)
	var np = pl[cands[0]]
	if np.ovr * G.fit(np, role) >= cur_e * 0.93:
		do_sub(i, worst, cands[0], out)


func winner() -> int:
	if sd[0].goals > sd[1].goals:
		return 0
	if sd[1].goals > sd[0].goals:
		return 1
	if pens != null:
		return 0 if pens[0] > pens[1] else 1
	return -1


func _finish(out: Array):
	phase = 4
	ball_state = ""
	if detailed:
		out.append(ev("ft", 0, "Full-time: %s" % score_text()))
	if fx.ko and sd[0].goals == sd[1].goals:
		var a = 0
		var b = 0
		for _k in 5:
			if rng.randf() < 0.76: a += 1
			if rng.randf() < 0.76: b += 1
		while a == b:
			if rng.randf() < 0.76: a += 1
			if rng.randf() < 0.76: b += 1
		pens = [a, b]
		if detailed:
			out.append(ev("info", 0 if a > b else 1, "PENALTY SHOOT-OUT: %s win %d–%d on penalties!" % [sd[0 if a > b else 1].club.name, max(a, b), min(a, b)]))
	var tot = 0.0
	var n = 0
	for pid in pm:
		if pm[pid].tin >= 0:
			tot += pl[pid].ovr
			n += 1
	var avg = tot / max(1, n)
	var best = -1.0
	for i in 2:
		var t = sd[i]
		var o = sd[1 - i]
		var gd = t.goals - o.goals
		var team = 0.35 if gd > 0 else (0.05 if gd == 0 else -0.25)
		var ids = t.xi.duplicate()
		for pid in pm:
			if pm[pid].tin >= 0 and not (pid in ids) and pl[pid].club == t.cid:
				ids.append(pid)
		for pid in ids:
			if pid < 0 or not pm.has(pid):
				continue
			var q = pm[pid]
			if q.tin < 0:
				continue
			var p = pl[pid]
			var mins = (q.tout if q.tout >= 0 else total) - q.tin
			var r = 6.3 + 0.95 * q.g + 0.55 * q.a + 0.12 * q.sv - 0.25 * q.yc - 1.4 * q.rc + 0.05 * q.sh + team
			if G.LINE[p.pos] <= 1:
				r += 0.45 if o.goals == 0 else (0.1 - 0.14 * o.goals)
			r += (p.ovr - avg) * 0.025 + rng.randfn(0.0, 0.35)
			if mins < 30:
				r = 6.3 + (r - 6.3) * (0.4 + mins / 50.0)
			q.r = clamp(snapped(r, 0.1), 4.0, 10.0)
			if q.r > best:
				best = q.r
				motm = pid

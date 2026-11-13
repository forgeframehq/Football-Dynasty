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
const REF = [3.9, 4.2, 4.9]
const SHOUTS = {"push": "Push forward", "calm": "Calm down", "waste": "Waste time", "demand": "Demand more"}

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
var shots: Array = []      # [side, x, y, goal, xg]
var momentum: Array = []   # per minute, + home / - away
var carrier := -1          # pid on the ball (for the 2D view)
var last_pass := -1


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
	recalc(0)   # again, so side 0 knows who side 1 is marking


func _side(lu: Dictionary, home: bool) -> Dictionary:
	var d = {"club": G.s.clubs[lu.club], "cid": lu.club, "home": home, "xi": lu.xi.duplicate(), "bench": lu.bench.duplicate(), "formation": lu.formation, "roles": [],
		"rids": lu.rids.duplicate(), "slots": lu.slots.duplicate(true), "instr": lu.instr.duplicate(), "pk": lu.pk, "fk": lu.fk, "ck": lu.ck, "capt": lu.capt,
		"ment": lu.ment, "press": lu.press, "tempo": lu.tempo, "att": 60.0, "mid": 60.0, "def": 60.0, "gk": 60.0, "goals": 0, "shots": 0, "sot": 0, "xg": 0.0,
		"corners": 0, "fouls": 0, "yc": 0, "rc": 0, "poss": 0, "subs": 0, "scorers": [], "user": lu.user, "auto": not lu.user, "midp": 1.0, "ps": 0.25,
		"w0": [], "w1": [], "t0": 0.0, "t1": 0.0, "shout": "", "shout_until": 0, "demand_used": false, "boost": lu.get("boost", 1.0), "drain": 1.0}
	for sl in d.slots:
		d.roles.append(sl[0])
	for pid in d.xi:
		if pid >= 0:
			_pm(pid, true)
	for pid in d.bench:
		_pm(pid, false)
	if d.capt >= 0 and d.capt in d.xi and pl[d.capt].at[13] >= 75:
		d.boost *= 1.008
	d["tc"] = G.TC.side_setup(lu, d)
	return d


func _retac(i: int):
	# instructions changed during the match: rebuild the tactical modifiers, keep what has already happened
	var t = sd[i]
	var old = t.tc
	t.tc = G.TC.side_setup({"user": old.user, "pins": t.club.pins if old.user and t.club.has("pins") else old.pins, "tm_pid": old.tm_pid}, t)
	t.tc.links0 = old.links0
	t.tc.link_goals = old.link_goals
	t.tc["first"] = false


func _pm(pid: int, starter: bool):
	var pp = pl[pid]
	pm[pid] = {"rid": "", "sf": 1.0, "p0": pow(max(pp.at[0], 30) / 65.0, 1.3), "p1": pow((pp.at[4] * 0.6 + pp.at[5] * 0.4) / 65.0, 3.0), "cond": float(pp.cond), "g": 0, "a": 0, "yc": 0, "rc": 0, "sv": 0, "sh": 0, "on": starter, "tin": 0 if starter else -1, "tout": -1, "inj": 0, "r": 6.0}


func set_shape(i: int, slots: Array, rids: Array, instr = null):
	var t = sd[i]
	t.slots = slots.duplicate(true)
	t.rids = rids.duplicate()
	t.roles = []
	for sl in t.slots:
		t.roles.append(sl[0])
	if instr != null:
		t.instr = instr.duplicate()
	_retac(i)
	recalc(i)
	if sd.size() == 2:
		recalc(1 - i)


func shout(i: int, kind: String) -> bool:
	var t = sd[i]
	if kind == "demand":
		if t.demand_used:
			return false
		t.demand_used = true
	t.shout = kind
	t.shout_until = minute + 12
	recalc(i)
	return true


func live_rating(pid: int) -> float:
	var q = pm[pid]
	return clamp(6.3 + 0.95 * q.g + 0.55 * q.a + 0.12 * q.sv - 0.25 * q.yc - 1.4 * q.rc + 0.05 * q.sh, 4.0, 10.0)


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
	var ins = t.instr
	var tc = t.tc
	var md = tc.m
	var opp = sd[1 - i] if sd.size() == 2 else null
	if tc.get("dirty", true):
		G.TC.refresh_side(t, opp)
		tc["dirty"] = false
	var wide_f = [0.9, 1.0, 1.08][ins.width] * md.wide
	var cen_f = [1.06, 1.0, 0.96][ins.width] * md.cen
	for k in 11:
		var pid = t.xi[k]
		if pid < 0:
			w0.append(0.0)
			w1.append(0.0)
			continue
		var role = t.roles[k]
		var base = ROLE_W[role]
		var rd = G.RL.ROLES[t.rids[k]]
		var p = pl[pid]
		var q = pm[pid]
		if q.rid != t.rids[k]:
			q.rid = t.rids[k]
			q.sf = 0.955 + 0.07 * G.RL.suit(p, q.rid)
		var pmod = G.TC.pl_mods(t, k, p, q, minute, opp)
		var f = G.fit(p, role) * (0.86 + 0.14 * q.cond / 100.0) * (0.975 + 0.0005 * p.mor) * q.sf * pmod[0]
		var e = p.ovr * f
		if k == 0:
			t.gk = e
			w0.append(0.0)
			w1.append(0.004)
			t1 += 0.004
			continue
		var aw = base[0] * rd.m[0] * (wide_f if G.RL.WIDE.has(role) else cen_f) * pmod[1]
		var mw = base[1] * rd.m[1] * pmod[2]
		var dw = base[2] * rd.m[2] * pmod[3]
		wa += aw
		wm += mw
		wd += dw
		var st = p.st
		a += aw * (0.65 * e + 0.35 * f * (st[1] + st[3] + st[0]) / 3.0)
		m += mw * (0.65 * e + 0.35 * f * (st[2] + st[3]) / 2.0)
		d += dw * (0.65 * e + 0.35 * f * (st[4] + st[5]) / 2.0)
		var x0 = (base[0] * 0.75 + 0.14) * q.p0 * rd.sh * pmod[4]
		var x1 = (0.7 * base[0] + 0.5 * base[1] + 0.03) * q.p1 * rd["as"] * pmod[5]
		w0.append(x0)
		w1.append(x1)
		t0 += x0
		t1 += x1
	var h = (1.03 if t.home else 1.0) * t.boost * tc.sx.cap
	var sa = 1.0
	var sdf = 1.0
	if t.shout == "push":
		sa = 1.06
		sdf = 0.95
	elif t.shout == "calm":
		sa = 0.98
		sdf = 1.02
	elif t.shout == "demand":
		sa = 1.03
		sdf = 1.03
	var line_m = [0.97, 1.0, 1.035][ins.line]
	var line_d = [1.035, 1.0, 0.97][ins.line]
	var pass_m = [1.03, 1.0, 0.97][ins["pass"]]
	t.att = max(20.0, a / max(0.01, wa) * pow(wa / REF[0], 0.35) * MENT[t.ment][0] * h * sa * md.att * G.TC.link_att(tc)) if wa > 0.0 else 20.0
	t.mid = max(20.0, m / max(0.01, wm) * pow(wm / REF[1], 0.35) * PRESS_MID[t.press] * h * line_m * pass_m * md.mid * tc.sx.mid) if wm > 0.0 else 20.0
	t.def = max(20.0, d / max(0.01, wd) * pow(wd / REF[2], 0.35) * MENT[t.ment][1] * h * sdf * line_d * (0.99 if ins.counter else 1.0) * md.def * tc.sx.def) if wd > 0.0 else 20.0
	t.midp = pow(t.mid, 2.6)
	t.w0 = w0
	t.w1 = w1
	t.t0 = t0
	t.t1 = t1
	if sd.size() == 2:
		for j in 2:
			var x = sd[j]
			var ps = 0.268 * pow(x.att / sd[1 - j].def, 2.1) * TEMPO_SHOT[x.tempo] * [0.95, 1.0, 1.05][x.instr["pass"]] * x.tc.m.ps
			if x.instr.counter:
				ps *= 1.07 if x.mid < sd[1 - j].mid else 0.97
			if x.tc.m.cb > 0.0 and x.mid < sd[1 - j].mid:
				ps *= 1.0 + x.tc.m.cb
			x.ps = clamp(ps, 0.05, 0.6)


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
			var dr = 0.27 * tick * PRESS_DRAIN[t.press] * TEMPO_DRAIN[t.tempo] * t.tc.m.drain
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
	for j in 2:
		var x = sd[j]
		if x.shout != "":
			if minute >= x.shout_until:
				x.shout = ""
				recalc(j)
			elif x.shout == "waste" and x.goals > sd[1 - j].goals:
				ps *= 0.78
		if x.shout != "waste" and x.goals > sd[1 - j].goals and (x.tc.waste == 2 or (x.tc.waste == 1 and minute >= 75)):
			ps *= 0.82
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
		carrier = -1
		if detailed and rng.randf() < 0.07:
			out.append(ev("info", ai, T_FILL[rng.randi() % T_FILL.size()] % at.club.name))
	if detailed:
		momentum.append((1 if ai == 0 else -1) * (3 if ball_state == "SHOT" or ball_state == "GOAL" else (2 if ball_state == "ATTACK" else 1)))
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


func _crosser(t: Dictionary) -> int:
	# the wide player most likely to deliver a cross; -1 if the side has no width
	var b = -1
	var bw = -1.0
	for k in range(1, 11):
		var c = t.xi[k]
		if c < 0 or not G.RL.WIDE.has(t.roles[k]):
			continue
		var w = pow(pl[c].at[3] / 60.0, 3.0) * rng.randf()
		if t.tc.pins[k] in ["ht", "afb"]:
			w *= 1.5
		if G.TC.has(pl[c], "pc"):
			w *= 1.3
		if w > bw:
			bw = w
			b = c
	return b


func _best_at(t: Dictionary, idx: int, pref: int) -> int:
	if pref >= 0 and pref in t.xi:
		return pref
	var b = -1
	var bs = -1
	for k in range(1, 11):
		if t.xi[k] >= 0 and pl[t.xi[k]].at[idx] > bs:
			bs = pl[t.xi[k]].at[idx]
			b = t.xi[k]
	return b


func _shot(ai: int, out: Array, pen: bool):
	var at = sd[ai]
	var df = sd[1 - ai]
	var sh = _pick(at, 0)
	if sh < 0:
		return
	var q = 0.77
	var kind = "pen"
	var asst = -1
	var loc = Vector2(0.89, 0.5)
	var gkr = max(30.0, df.gk)
	var header = false
	var md = at.tc.m
	var b_big = 0.15 + max(0.04, 0.11 + md.big + df.tc.m.opp_big)
	var b_cross = b_big + md.cross + at.tc.sx.cross
	var b_box = max(b_cross + 0.05, 1.0 - (0.40 + md.long))
	var crosser = -1
	if pen:
		sh = _best_at(at, 17, at.pk)
		q = clamp(0.74 + (pl[sh].at[17] - 70) * 0.004, 0.6, 0.9)
		if G.TC.has(pl[sh], "pen"):
			q += 0.06
		if df.xi[0] >= 0 and G.TC.has(pl[df.xi[0]], "psv"):
			q -= 0.06
		if detailed:
			out.append(ev("info", ai, "PENALTY to %s! %s steps up..." % [at.club.name, nm(sh)]))
	else:
		var r = rng.randf()
		if r < 0.05:
			kind = "fk"
			sh = _best_at(at, 16, at.fk)
			q = 0.065 * pow(pl[sh].at[16] / 70.0, 2.2) * 72.0 / gkr * G.TC.shot_mult(pl[sh], "fk", false)
			loc = Vector2(rng.randf_range(0.72, 0.8), rng.randf_range(0.3, 0.7))
		elif r < 0.15:
			kind = "corner"
			asst = _best_at(at, 3, at.ck)
			var bw = -1.0
			for k in range(1, 11):
				var c = at.xi[k]
				if c >= 0 and c != asst:
					var w = pow(pl[c].at[2] / 60.0, 3.0) * (1.0 if at.roles[k] in ["CB", "ST"] else 0.45) * rng.randf()
					if w > bw:
						bw = w
						sh = c
			q = 0.095 * pow(pl[sh].at[2] / 72.0, 1.5) * pow((pl[asst].at[3] if asst >= 0 else 65) / 70.0, 0.8) * 72.0 / gkr * G.TC.shot_mult(pl[sh], "corner", true)
			header = true
			at.corners += 1
			loc = Vector2(rng.randf_range(0.9, 0.95), rng.randf_range(0.42, 0.58))
		else:
			if r >= b_big and r < b_cross:
				crosser = _crosser(at)
			if crosser >= 0:
				# a cross from wide: who gets on the end of it depends on the kind of cross asked for
				kind = "cross"
				asst = crosser
				var ct = at.tc.cross_type
				var idx = 0 if ct == 1 else (12 if ct == 3 else 2)
				header = idx == 2
				var bw = -1.0
				for k in range(1, 11):
					var c = at.xi[k]
					if c >= 0 and c != asst:
						var rw = 1.0 if at.roles[k] == "ST" else (0.75 if at.roles[k] in ["CAM", "LW", "RW", "LM", "RM"] else (0.5 if at.roles[k] == "CM" else 0.12))
						var w = pow(pl[c].at[idx] / 60.0, 2.0) * rw * rng.randf()
						if w > bw:
							bw = w
							sh = c
				q = 0.085 * pow(pl[sh].at[idx] / 72.0, 1.5) * pow(pl[asst].at[3] / 70.0, 0.8) * 72.0 / gkr * G.TC.shot_mult(pl[sh], "cross", header)
				if G.TC.has(pl[asst], "pc"):
					q *= 1.15
				loc = Vector2(rng.randf_range(0.88, 0.94), rng.randf_range(0.4, 0.6))
		if kind == "pen" and not pen and r >= 0.15:
			var p = pl[sh]
			var skill = p.at[0]
			if r < b_big:
				q = 0.38
				kind = "big"
				loc = Vector2(rng.randf_range(0.88, 0.93), rng.randf_range(0.42, 0.58))
			elif r < b_box:
				q = 0.11
				kind = "box"
				loc = Vector2(rng.randf_range(0.82, 0.9), rng.randf_range(0.32, 0.68))
			else:
				q = 0.035
				kind = "long"
				skill = p.at[1]
				loc = Vector2(rng.randf_range(0.7, 0.78), rng.randf_range(0.28, 0.72))
			var se = (0.5 * skill + 0.5 * p.ovr) * (0.86 + 0.14 * pm[sh].cond / 100.0)
			q *= pow(se / gkr, 1.3) * G.TC.shot_mult(p, kind, false)
		q = min(0.9, q)
	at.shots += 1
	at.xg += q
	pm[sh].sh += 1
	ball_state = "SHOT"
	carrier = sh
	if ai == 1:
		loc = Vector2(1.0 - loc.x, 1.0 - loc.y)
	ball = loc
	var gk = df.xi[0]
	var scored = rng.randf() < q
	shots.append([ai, loc.x, loc.y, scored, q])
	if scored:
		at.goals += 1
		at.sot += 1
		pm[sh].g += 1
		at.scorers.append({"pid": sh, "m": minute, "pen": pen})
		if kind in ["big", "box", "long"]:
			var partner = G.TC.link_partner(at.tc, sh)
			if partner >= 0 and partner in at.xi and rng.randf() < 0.4:
				asst = partner
			elif rng.randf() < 0.75:
				asst = _pick(at, 1, sh)
		if asst >= 0:
			pm[asst].a += 1
		var lk = G.TC.link_for(at.tc, sh, asst)
		if lk != null:
			at.tc.link_goals += 1
		ball_state = "GOAL"
		last_pass = asst
		if detailed:
			var tx = ""
			match kind:
				"pen": tx = "GOAL! %s sends the keeper the wrong way from the spot!" % nm(sh)
				"fk": tx = "GOAL! What a free kick from %s — up and over the wall for %s!" % [nm(sh), at.club.name]
				"corner": tx = "GOAL! %s rises highest from the corner and powers it home for %s!" % [nm(sh), at.club.name]
				"cross":
					if header:
						tx = "GOAL! %s gets up to meet the cross and heads %s in front!" % [nm(sh), at.club.name] if at.goals > df.goals else "GOAL! %s gets up to meet the cross and heads it in for %s!" % [nm(sh), at.club.name]
					else:
						tx = "GOAL! The ball is whipped in and %s turns it home for %s!" % [nm(sh), at.club.name]
				"long": tx = T_GOAL_LONG[rng.randi() % T_GOAL_LONG.size()] % [nm(sh), at.club.name]
				_: tx = T_GOAL[rng.randi() % T_GOAL.size()] % [nm(sh), at.club.name]
			var sks = pl[sh].get("sk", [])
			if kind == "long" and "lr" in sks:
				tx += " That is the Long Ranger in him."
			elif kind == "fk" and "fk" in sks:
				tx += " A specialist's free kick."
			elif kind == "cross" and not header and "acr" in sks:
				tx += " An acrobatic finish!"
			elif header and "hd" in sks:
				tx += " Nobody beats him in the air."
			elif kind in ["big", "box"] and "fts" in sks and rng.randf() < 0.5:
				tx += " First time, no hesitation."
			if asst >= 0:
				tx += " Assist: %s." % nm(asst)
			if lk != null:
				tx += " That is the %s link-up at work!" % G.TC.LINKS[lk.id].n
			var e = ev("goal", ai, tx, sh)
			e["a"] = asst
			if lk != null:
				e["link"] = lk.id
			out.append(e)
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
			var tx = ""
			if pen:
				tx = "SAVED! %s keeps out %s's penalty!" % [nm(gk) if gk >= 0 else "The keeper", nm(sh)]
			elif kind == "fk":
				tx = "%s curls the free kick on target — %s tips it away." % [nm(sh), nm(gk) if gk >= 0 else "the keeper"]
			elif kind == "corner":
				tx = "%s meets the corner with a header — saved by %s." % [nm(sh), nm(gk) if gk >= 0 else "the keeper"]
			elif kind == "cross":
				tx = "%s gets on the end of the cross — %s keeps it out." % [nm(sh), nm(gk) if gk >= 0 else "the keeper"]
			else:
				tx = _save_text(sh, gk)
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
			elif kind == "fk":
				tx = "%s's free kick clears the wall — and the bar." % nm(sh)
			elif kind == "corner":
				tx = "%s gets up well at the corner but heads over." % nm(sh)
			elif kind == "cross":
				tx = "The cross comes in and %s cannot keep it down." % nm(sh)
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
	var r = rng.randf() / t.tc.m.foul
	if t.shout == "calm":
		r *= 2.0
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
	t.tc["dirty"] = true
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
	var res = G.TC.inj_res(pl[pid])
	if res == 3 and rng.randf() < 0.4:
		return
	var r = rng.randf()
	var days = rng.randi_range(3, 10)
	if r > 0.9:
		days = rng.randi_range(36, 120)
	elif r > 0.6:
		days = rng.randi_range(11, 35)
	if res == 1:
		days = int(days * 1.3)
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
		t.tc["dirty"] = true
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
	t.tc["dirty"] = true
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
	t.tc["dirty"] = true
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

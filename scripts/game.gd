extends Node
# Global career state and core game logic.

const ME = preload("res://scripts/match_engine.gd")
const LG = preload("res://scripts/leagues.gd")
const TR = preload("res://scripts/transfers.gd")
const RL = preload("res://scripts/roles.gd")
const CP = preload("res://scripts/comps.gd")
const OPS = preload("res://scripts/club_ops.gd")
const PS = preload("res://scripts/persona.gd")
const DL = preload("res://scripts/deals.gd")
const TC = preload("res://scripts/tac.gd")
const MK = preload("res://scripts/market.gd")

const SAVE_V = 2
var slot := 0
var settings: Dictionary = {"sound": true}


func save_path(i = null) -> String:
	if i == null:
		i = slot
	return "user://career.sav" if i == 0 else "user://career%d.sav" % i


func meta_path(i = null) -> String:
	if i == null:
		i = slot
	return "user://career.meta" if i == 0 else "user://career%d.meta" % i


func delete_save(i: int):
	for p in [save_path(i), meta_path(i)]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


func load_settings():
	if FileAccess.file_exists("user://settings.dat"):
		var f = FileAccess.open("user://settings.dat", FileAccess.READ)
		var d = f.get_var()
		f.close()
		if typeof(d) == TYPE_DICTIONARY:
			settings.merge(d, true)


func save_settings():
	var f = FileAccess.open("user://settings.dat", FileAccess.WRITE)
	if f != null:
		f.store_var(settings)
		f.close()
const LINE = {"GK": 0, "CB": 1, "LB": 1, "RB": 1, "CDM": 2, "CM": 2, "CAM": 2, "LM": 2, "RM": 2, "LW": 3, "RW": 3, "ST": 3}
const LINE_NAMES = ["Goalkeepers", "Defenders", "Midfielders", "Attackers"]
const STAT_NAMES = ["PAC", "SHO", "PAS", "DRI", "DEF", "PHY"]
const GK_STAT_NAMES = ["DIV", "HAN", "KIC", "REF", "SPD", "POS"]
const MENTALITY = ["Park the Bus", "Defensive", "Balanced", "Attacking", "All-Out Attack"]
const PRESSING = ["Low Block", "Standard", "High Press"]
const TEMPO = ["Patient", "Normal", "Fast"]
const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
const WDAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

const FORMATIONS = {
	"4-3-3": [["GK", .5, .05], ["LB", .12, .27], ["CB", .36, .21], ["CB", .64, .21], ["RB", .88, .27], ["CM", .27, .52], ["CDM", .5, .42], ["CM", .73, .52], ["LW", .16, .78], ["ST", .5, .86], ["RW", .84, .78]],
	"4-2-3-1": [["GK", .5, .05], ["LB", .12, .27], ["CB", .36, .21], ["CB", .64, .21], ["RB", .88, .27], ["CDM", .35, .43], ["CDM", .65, .43], ["LM", .14, .67], ["CAM", .5, .66], ["RM", .86, .67], ["ST", .5, .87]],
	"4-4-2": [["GK", .5, .05], ["LB", .12, .27], ["CB", .36, .21], ["CB", .64, .21], ["RB", .88, .27], ["LM", .12, .56], ["CM", .37, .5], ["CM", .63, .5], ["RM", .88, .56], ["ST", .36, .84], ["ST", .64, .84]],
	"4-1-2-1-2": [["GK", .5, .05], ["LB", .12, .27], ["CB", .36, .21], ["CB", .64, .21], ["RB", .88, .27], ["CDM", .5, .38], ["CM", .28, .54], ["CM", .72, .54], ["CAM", .5, .68], ["ST", .36, .86], ["ST", .64, .86]],
	"4-5-1": [["GK", .5, .05], ["LB", .12, .27], ["CB", .36, .21], ["CB", .64, .21], ["RB", .88, .27], ["LM", .1, .6], ["CM", .3, .52], ["CDM", .5, .42], ["CM", .7, .52], ["RM", .9, .6], ["ST", .5, .86]],
	"3-5-2": [["GK", .5, .05], ["CB", .25, .22], ["CB", .5, .2], ["CB", .75, .22], ["LM", .08, .54], ["CM", .3, .52], ["CDM", .5, .41], ["CM", .7, .52], ["RM", .92, .54], ["ST", .36, .84], ["ST", .64, .84]],
	"3-4-3": [["GK", .5, .05], ["CB", .25, .22], ["CB", .5, .2], ["CB", .75, .22], ["LM", .1, .52], ["CM", .37, .47], ["CM", .63, .47], ["RM", .9, .52], ["LW", .18, .8], ["ST", .5, .87], ["RW", .82, .8]],
	"5-3-2": [["GK", .5, .05], ["LB", .08, .34], ["CB", .28, .22], ["CB", .5, .2], ["CB", .72, .22], ["RB", .92, .34], ["CM", .27, .54], ["CDM", .5, .46], ["CM", .73, .54], ["ST", .36, .84], ["ST", .64, .84]],
}
const AI_INSTR = {"width": 1, "line": 1, "pass": 1, "counter": false}
const AI_FORMATIONS = ["4-3-3", "4-2-3-1", "4-4-2", "4-2-3-1", "4-3-3", "3-5-2", "5-3-2", "3-4-3", "4-1-2-1-2", "4-5-1", "4-4-2"]
const FIT_PAIRS = [["CB", "CDM", .9], ["CB", "LB", .86], ["CB", "RB", .86], ["LB", "RB", .9], ["LB", "LM", .9], ["RB", "RM", .9], ["LB", "LW", .82], ["RB", "RW", .82],
	["CDM", "CM", .94], ["CM", "CAM", .93], ["CDM", "CAM", .84], ["CM", "LM", .86], ["CM", "RM", .86], ["CAM", "LM", .88], ["CAM", "RM", .88], ["CAM", "LW", .88], ["CAM", "RW", .88], ["CAM", "ST", .87],
	["LM", "LW", .96], ["RM", "RW", .96], ["LM", "RM", .92], ["LW", "RW", .93], ["LM", "RW", .9], ["RM", "LW", .9], ["LW", "ST", .88], ["RW", "ST", .88], ["LM", "ST", .8], ["RM", "ST", .8]]
# stat offsets from overall for generated players: PAC SHO PAS DRI DEF PHY
const GEN_STATS = {"ST": [2, 3, -8, 0, -35, -2], "LW": [6, -3, -4, 4, -35, -12], "RW": [6, -3, -4, 4, -35, -12], "LM": [5, -6, -2, 3, -22, -8], "RM": [5, -6, -2, 3, -22, -8],
	"CAM": [-2, -2, 3, 4, -28, -12], "CM": [-4, -6, 3, 2, -6, -2], "CDM": [-6, -14, -1, -3, 2, 4], "LB": [5, -22, -5, -2, -1, -2], "RB": [5, -22, -5, -2, -1, -2], "CB": [-6, -32, -12, -12, 2, 4]}

var s: Dictionary = {}
var fx_by_day: Dictionary = {}
var cur: Dictionary = {}
var rng = RandomNumberGenerator.new()
var stop_flag := false
var active := false
var fit_table: Dictionary = {}
var lu_cache: Dictionary = {}
var ui: Dictionary = {"sq_filter": 0, "sq_sort": 0, "tr_tab": 0, "tr_pos": 0, "tr_name": "", "tr_afford": false, "tr_u23": false, "tr_listed": false, "tr_free": false}


func _ready():
	for p in FIT_PAIRS:
		fit_table[p[0] + p[1]] = p[2]
		fit_table[p[1] + p[0]] = p[2]
	rng.randomize()
	load_settings()


# ---------------------------------------------------------------- helpers

func ymd(y: int, m: int, d: int) -> int:
	return int(Time.get_unix_time_from_datetime_dict({"year": y, "month": m, "day": d, "hour": 12, "minute": 0, "second": 0}) / 86400)


func date(dy: int) -> Dictionary:
	return Time.get_date_dict_from_unix_time(dy * 86400 + 43200)


func fmt_date(dy: int, with_year := false) -> String:
	var d = date(dy)
	var t = "%s %d %s" % [WDAYS[d.weekday], d.day, MONTHS[d.month - 1]]
	if with_year:
		t += " %d" % d.year
	return t


func set_date():
	cur = date(s.day)


func season_name(y = null) -> String:
	if y == null:
		y = s.season
	return "%d/%02d" % [y, (y + 1) % 100]


func uc() -> Dictionary:
	return s.clubs[s.user.club]


func P(pid: int) -> Dictionary:
	return s.players[pid]


func pname(p: Dictionary) -> String:
	if p.cn != "":
		return p.cn
	if p.fn == "":
		return p.ln
	return "%s. %s" % [p.fn.substr(0, 1), p.ln]


func pfull(p: Dictionary) -> String:
	if p.cn != "":
		return p.cn
	return ("%s %s" % [p.fn, p.ln]).strip_edges()


func age(p: Dictionary) -> int:
	var a = cur.year - p.by
	if cur.month < p.bm or (cur.month == p.bm and cur.day < p.bd):
		a -= 1
	return a


func fit(p: Dictionary, role: String) -> float:
	if p.pos == role:
		return 1.0
	if role in p.alt:
		return 0.98
	if p.pos == "GK" or role == "GK":
		return 0.35
	return fit_table.get(p.pos + role, 0.72)


func value(p: Dictionary) -> int:
	var a = age(p)
	var v = 500000.0 * pow(1.21, p.ovr - 60)
	var af = 0.12
	if a <= 21: af = 1.15
	elif a <= 24: af = 1.2
	elif a <= 27: af = 1.1
	elif a <= 34: af = [0.95, 0.85, 0.7, 0.55, 0.42, 0.3, 0.2][a - 28]
	v *= af
	v *= 1.0 + max(0, p.pot - p.ovr) * (0.07 if a <= 23 else 0.03)
	if p.pos == "GK":
		v *= 0.7
	if p.cend - s.season <= 1:
		v *= 0.8
	return nice(v)


func wage_for(ovr: int, a: int) -> int:
	var w = 1500.0 * pow(1.17, ovr - 60)
	if a < 21:
		w *= 0.7
	return nice(max(w, 250.0))


func nice(v: float) -> int:
	if v <= 0:
		return 0
	var mag = pow(10.0, floor(log(v) / log(10.0)) - 1)
	return int(round(v / mag) * mag)


func money(v) -> String:
	var n = float(v)
	var sg = "-" if n < 0 else ""
	n = abs(n)
	if n >= 1e9:
		return "%s€%.2fB" % [sg, n / 1e9]
	if n >= 1e6:
		var t = "%.1f" % (n / 1e6)
		if t.ends_with(".0") or n >= 1e8:
			t = "%d" % int(round(n / 1e6))
		return "%s€%sM" % [sg, t]
	if n >= 1e3:
		return "%s€%dK" % [sg, int(round(n / 1e3))]
	return "%s€%d" % [sg, int(n)]


func available(p: Dictionary) -> bool:
	return p.inj <= 0 and p.susp <= 0


func squad_wages(c: Dictionary) -> int:
	var t = 0
	for pid in c.players:
		var p = s.players[pid]
		# a loanee costs only the share of his wages agreed with his club
		t += int(p.wage * float(p.lw)) if p.has("lw") else int(p.wage)
	return t


func new_table() -> Dictionary:
	return {"p": 0, "w": 0, "d": 0, "l": 0, "gf": 0, "ga": 0, "pts": 0}


func new_stats() -> Dictionary:
	return {"ap": 0, "g": 0, "a": 0, "rs": 0.0, "yc": 0, "rc": 0, "cs": 0, "mom": 0}


func avg_rating(p: Dictionary) -> float:
	return p.ss.rs / p.ss.ap if p.ss.ap > 0 else 0.0


func window_open() -> bool:
	var m = cur.month
	return m == 7 or m == 8 or m == 1 or (m == 6 and cur.day >= 12)


func msg(title: String, body: String, kind := "info", ref = null, important := false):
	s.inbox.push_front({"id": s.msg_id, "day": s.day, "title": title, "body": body, "kind": kind, "ref": ref, "read": false})
	s.msg_id += 1
	if s.inbox.size() > 60:
		s.inbox.resize(60)
	if important:
		stop_flag = true


const SOC = preload("res://scripts/social.gd")
const DERBIES = [["Manchester United", "Manchester City"], ["Liverpool", "Everton"], ["Arsenal", "Tottenham"], ["Liverpool", "Manchester United"], ["Chelsea", "Arsenal"],
	["Newcastle", "Sunderland"], ["Aston Villa", "Birmingham"], ["Real Madrid", "Barcelona"], ["Real Madrid", "Atlético"], ["Sevilla", "Betis"], ["Athletic", "Real Sociedad"],
	["Milan", "Inter"], ["Roma", "Lazio"], ["Juventus", "Torino"], ["Juventus", "Inter"], ["Napoli", "Roma"], ["Bayern", "Dortmund"], ["Dortmund", "Schalke"],
	["Hamburg", "Bremen"], ["Paris", "Marseille"], ["Lyon", "Saint-Étienne"], ["Nice", "Monaco"], ["Sheffield United", "Sheffield Wednesday"], ["Leeds", "Manchester United"]]


func is_derby(a: int, b: int) -> bool:
	var na = s.clubs[a].name
	var nb = s.clubs[b].name
	for d in DERBIES:
		if (na.contains(d[0]) and nb.contains(d[1])) or (na.contains(d[1]) and nb.contains(d[0])):
			return na != nb
	return false


func scrap(title: String, text: String):
	var u = s.user
	if not u.has("scrap"):
		u["scrap"] = []
	u.scrap.push_front({"day": s.day, "title": title, "text": text})
	if u.scrap.size() > 60:
		u.scrap.resize(60)


func news(text: String):
	s.news.push_front({"day": s.day, "text": text})
	if s.news.size() > 40:
		s.news.resize(40)


func unread() -> int:
	var n = 0
	for m in s.inbox:
		if not m.read:
			n += 1
	return n


# ---------------------------------------------------------------- new game

func new_game(profile, club_id: int):
	if typeof(profile) == TYPE_STRING:
		var nm = profile
		profile = OPS.default_profile()
		profile.name = nm
	var mname = profile.name
	var raw = DB.load_db()
	rng.randomize()
	lu_cache = {}
	var season = int(raw.season)
	s = {"v": 1, "season": season, "day": ymd(season, 7, 1), "players": {}, "clubs": [], "leagues": [], "fixtures": [], "inbox": [], "news": [],
		"offers": [], "shortlist": [], "free": [], "playoffs": [], "negos": {}, "next_id": 900000, "msg_id": 1, "offer_id": 1, "history": [], "champs": [], "tx_log": [], "review": null, "recov": {}, "user": {}}
	set_date()
	for i in raw.leagues.size():
		var l = raw.leagues[i]
		s.leagues.append({"id": i, "name": l.name, "short": l.short, "country": l.country, "tier": int(l.tier), "clubs": [], "roe": l.get("roe", false)})
	for i in raw.clubs.size():
		var c = raw.clubs[i]
		s.clubs.append(raw_club(i, c))
		s.leagues[int(c.lg)].clubs.append(i)
	var prng = RandomNumberGenerator.new()
	for r in raw.players:
		add_raw_player(r, prng)
	for c in s.clubs:
		init_club(c)
	s.user = {"name": mname, "club": club_id, "rep": 0.0, "conf": 60.0, "obj": {}, "p": 0, "w": 0, "d": 0, "l": 0, "trophies": [], "sacked": false, "jobs": []}
	var mc = uc()
	for k in ["nat", "badge", "bg", "attr"]:
		s.user[k] = profile[k]
	s.user["points"] = 0
	s.user["study"] = 0
	s.user.rep = 22.0 + profile.badge * 11.0 + profile.bg * 5.0
	s.user.conf = clamp(60.0 - max(0.0, (mc.rep - 25.0) - s.user.rep) * 0.9, 30.0, 60.0)
	s.user.obj = LG.objective(mc)
	init_user_tactics(mc)
	if profile.has("pstyle"):
		# chosen on the new-career screens: the manager's best playstyle and first link-up
		s.user["prof"] = TC.start_prof(int(profile.pstyle), int(profile.badge))
		s.user["links"] = [profile.link] if profile.get("link", "") != "" else []
		s.user["tac_set"] = true
		mc["instr"] = TC.INSTR_DEF.duplicate()
		TC.set_style(mc, int(profile.pstyle))
	LG.generate_fixtures()
	ensure_state()
	active = true
	msg("Welcome to %s" % mc.name, "The board welcomes you as the new manager of %s.\n\nSeason objective: %s.\n\nYou have a transfer budget of %s and the transfer window is open until 31 August. Set up your tactics, shape the squad and press Continue when you are ready." % [mc.name, s.user.obj.text, money(mc.budget)], "board")
	save_game()


func raw_club(i: int, c: Dictionary) -> Dictionary:
	return {"id": i, "name": c.name, "short": c.short, "lg": int(c.lg), "c1": c.c1, "c2": c.c2, "stadium": c.stadium, "players": [], "xi": [], "bench": [],
		"formation": "4-3-3", "ment": 2, "press": 1, "tempo": 1, "rep": 60.0, "budget": 0, "wage_budget": 0, "t": new_table(), "form": [], "spent": 0, "earned": 0}


func add_raw_player(r: Array, prng: RandomNumberGenerator):
	var p = raw_player(r)
	prng.seed = p.id * 7919 + 13
	var a = age(p)
	p.pot = gen_potential(p.ovr, a, prng)
	p.wage = wage_for(p.ovr, a)
	p.cend = s.season + 1 + (prng.randi() % 2 if a >= 32 else prng.randi() % 4)
	s.players[p.id] = p
	s.clubs[p.club].players.append(p.id)


func init_club(c: Dictionary):
	ensure_squad(c)
	c.rep = calc_rep(c)
	c.formation = best_formation(c)
	c.budget = nice(900000.0 * pow(1.2, c.rep - 60.0))
	c.wage_budget = nice(squad_wages(c) * 1.15)


func ensure_state():
	# idempotent: brings older saves up to date and fills in defaults for newer features
	var raw = DB.load_db()
	for l in s.leagues:
		if not l.has("roe"):
			l["roe"] = false
	if s.leagues.size() < raw.leagues.size():
		var by_id = {}
		for r in raw.players:
			by_id[int(r[0])] = r
		for pid in s.players:
			var p = s.players[pid]
			if not p.has("at"):
				if by_id.has(pid):
					var at = []
					for i in range(21, 39):
						at.append(int(by_id[pid][i]))
					p["at"] = at
				else:
					p["at"] = RL.derive_attrs(p.pos, p.ovr, p.st, rng)
		var first_new = s.clubs.size()
		for i in range(s.leagues.size(), raw.leagues.size()):
			var l = raw.leagues[i]
			s.leagues.append({"id": i, "name": l.name, "short": l.short, "country": l.country, "tier": int(l.tier), "clubs": [], "roe": l.get("roe", false)})
		for i in range(first_new, raw.clubs.size()):
			s.clubs.append(raw_club(i, raw.clubs[i]))
			s.leagues[int(raw.clubs[i].lg)].clubs.append(i)
		var prng = RandomNumberGenerator.new()
		for r in raw.players:
			if int(r[4]) >= first_new and not s.players.has(int(r[0])):
				add_raw_player(r, prng)
		for i in range(first_new, s.clubs.size()):
			init_club(s.clubs[i])
	for pid in s.players:
		var p = s.players[pid]
		if not p.has("at"):
			p["at"] = RL.derive_attrs(p.pos, p.ovr, p.st, rng)
	if not s.has("recov"):
		s["recov"] = {}
	if not s.has("comps"):
		s["comps"] = []
		if s.day < ymd(s.season, 8, 10):
			CP.setup_season()
	for cl in s.clubs:
		if cl.players.size() > 0 and not s.players[cl.players[0]].has("num"):
			number_squad(cl)
	if not s.has("rc_done"):
		s["rc_done"] = true
		for pid in s.players:
			var rp = s.players[pid]
			if rp.club >= 0 and (s.leagues[s.clubs[rp.club].lg].country == "Spain" or pid % 5 == 0):
				rp["rc"] = nice(value(rp) * (2.4 if rp.ovr >= 80 else 1.8))
	var c = uc()
	OPS.ensure(c)
	if not c.has("slots") or c.slots.size() != 11:
		if not FORMATIONS.has(c.formation):
			c.formation = "4-3-3"
		init_user_tactics(c)
	TC.ensure()
	s.v = SAVE_V


func raw_player(r: Array) -> Dictionary:
	var at = []
	for i in range(21, 39):
		at.append(int(r[i]))
	return {"id": int(r[0]), "fn": r[1], "ln": r[2], "cn": r[3], "club": int(r[4]), "pos": r[5], "alt": Array(r[6].split(" ", false)) if r[6] != "" else [], "nat": r[7],
		"by": int(r[8]), "bm": int(r[9]), "bd": int(r[10]), "ovr": int(r[11]), "pot": 0, "st": [int(r[12]), int(r[13]), int(r[14]), int(r[15]), int(r[16]), int(r[17])],
		"foot": r[18], "sm": int(r[19]), "wf": int(r[20]), "at": at, "wage": 0, "cend": 0, "cond": 100, "mor": 70, "inj": 0, "susp": 0, "ycs": 0, "listed": false, "form": 6.5, "ss": new_stats(), "cg": 0, "cap": 0}


func gen_potential(ovr: int, a: int, r: RandomNumberGenerator) -> int:
	var head = 0
	if a <= 17: head = r.randi_range(12, 22)
	elif a <= 19: head = r.randi_range(8, 18)
	elif a <= 21: head = r.randi_range(5, 13)
	elif a <= 23: head = r.randi_range(2, 8)
	elif a <= 25: head = r.randi_range(0, 4)
	elif a <= 27: head = r.randi_range(0, 1)
	var pot = float(ovr + head)
	if pot > 88:
		pot = 88 + (pot - 88) * 0.6
	return clampi(int(round(pot)), ovr, 97)


func calc_rep(c: Dictionary) -> float:
	var ov = []
	for pid in c.players:
		ov.append(s.players[pid].ovr)
	ov.sort()
	ov.reverse()
	var n = min(16, ov.size())
	var t = 0.0
	for i in n:
		t += ov[i]
	return t / max(1, n)


func gen_player(club_id: int, pos: String, a: int, ovr: int, pot: int, nat: String) -> Dictionary:
	var nm = DB.random_name(nat, rng)
	var st = []
	if pos == "GK":
		st = [ovr + 1, ovr - 1, ovr - 4, ovr + 2, 45, ovr]
	else:
		for o in GEN_STATS[pos]:
			st.append(ovr + o)
	for i in 6:
		st[i] = clampi(st[i] + rng.randi_range(-3, 3), 20, 97)
	var pid = s.next_id
	s.next_id += 1
	var p = {"id": pid, "fn": nm[0], "ln": nm[1], "cn": "", "club": club_id, "pos": pos, "alt": [], "nat": nat,
		"by": cur.year - a - (1 if cur.month < 7 else 0), "bm": rng.randi_range(7, 12), "bd": rng.randi_range(1, 28), "ovr": ovr, "pot": max(pot, ovr), "st": st,
		"foot": "L" if rng.randf() < 0.24 else "R", "sm": rng.randi_range(2, 3), "wf": rng.randi_range(2, 4), "wage": 0, "cend": s.season + rng.randi_range(2, 4),
		"cond": 100, "mor": 70, "inj": 0, "susp": 0, "ycs": 0, "listed": false, "form": 6.5, "ss": new_stats(), "cg": 0, "cap": 0}
	p["at"] = RL.derive_attrs(pos, ovr, st, rng)
	p.wage = wage_for(ovr, age(p))
	s.players[pid] = p
	if club_id >= 0:
		s.clubs[club_id].players.append(pid)
	else:
		s.free.append(pid)
	return p


func ensure_squad(c: Dictionary):
	var cnt = [0, 0, 0, 0]
	var tot = 0.0
	for pid in c.players:
		var p = s.players[pid]
		cnt[LINE[p.pos]] += 1
		tot += p.ovr
	var base = int(tot / max(1, c.players.size())) - 4 if c.players.size() > 0 else 55
	var need = [2, 7, 7, 5]
	var opts = [["GK"], ["CB", "CB", "LB", "RB"], ["CM", "CDM", "CAM", "LM", "RM", "CM"], ["ST", "ST", "LW", "RW"]]
	var country = s.leagues[c.lg].country
	for l in 4:
		while cnt[l] < need[l]:
			var o = base + rng.randi_range(-4, 2)
			gen_player(c.id, opts[l][rng.randi() % opts[l].size()], rng.randi_range(18, 23), o, o + rng.randi_range(3, 12), country)
			cnt[l] += 1


# ---------------------------------------------------------------- lineups

func slots_of(c: Dictionary) -> Array:
	if c.has("slots") and c.slots.size() == 11:
		return c.slots
	return FORMATIONS[c.formation]


func set_formation(c: Dictionary, fname: String):
	# applies a stock formation to the user's club (copies the slots so they can be customised)
	c.formation = fname
	c.slots = FORMATIONS[fname].duplicate(true)
	c.roles = []
	for sl in c.slots:
		c.roles.append(RL.BY_POS[sl[0]][0])


func init_user_tactics(c: Dictionary):
	set_formation(c, c.formation)
	if not c.has("instr"):
		c.instr = {"width": 1, "line": 1, "pass": 1, "counter": false}
	if not c.has("presets"):
		c.presets = [null, null, null]
	for k in ["pk", "fk", "ck", "capt"]:
		if not c.has(k):
			c[k] = -1
	auto_pick(c)
	auto_roles(c)


const STATUS = ["Key player", "Rotation", "Backup", "Prospect"]
const NUM_PREF = {"GK": [1, 13, 12], "RB": [2, 22], "LB": [3, 23], "CB": [4, 5, 6, 15], "CDM": [6, 4, 16], "CM": [8, 6, 14, 18], "CAM": [10, 8, 20], "RM": [7, 17], "RW": [7, 17, 11], "LM": [11, 21], "LW": [11, 7, 21], "ST": [9, 19, 10]}


func status_of(p: Dictionary) -> int:
	var st = p.get("status", -1)
	if st >= 0:
		return st
	if p.club < 0:
		return 2
	var rank = TR.squad_rank(p)
	if age(p) <= 20 and rank >= 14:
		return 3
	if rank < 11:
		return 0
	return 1 if rank < 18 else 2


func give_number(c: Dictionary, p: Dictionary):
	var used = {}
	for pid in c.players:
		if pid != p.id:
			used[s.players[pid].get("num", 0)] = true
	for n in NUM_PREF[p.pos]:
		if not used.has(n):
			p["num"] = n
			return
	for n in range(12, 100):
		if not used.has(n):
			p["num"] = n
			return
	p["num"] = 99


func number_squad(c: Dictionary):
	var arr = []
	for pid in c.players:
		s.players[pid]["num"] = 0
		arr.append(s.players[pid])
	arr.sort_custom(func(a, b): return a.ovr > b.ovr)
	for p in arr:
		give_number(c, p)


func make_preset(c: Dictionary) -> Dictionary:
	return {"formation": c.formation, "slots": c.slots.duplicate(true), "roles": c.roles.duplicate(), "instr": c.instr.duplicate(), "ment": c.ment, "press": c.press, "tempo": c.tempo,
		"pins": c.pins.duplicate(), "pstyle": c.pstyle}


func apply_preset(c: Dictionary, pr: Dictionary):
	c.formation = pr.formation
	c.slots = pr.slots.duplicate(true)
	c.roles = pr.roles.duplicate()
	c.instr = pr.instr.duplicate()
	c.ment = pr.ment
	c.press = pr.press
	c.tempo = pr.tempo
	for k in TC.INSTR_DEF:
		if not c.instr.has(k):
			c.instr[k] = TC.INSTR_DEF[k]
	c.pins = pr.pins.duplicate() if pr.has("pins") else ["", "", "", "", "", "", "", "", "", "", ""]
	if pr.has("pstyle"):
		TC.set_style(c, int(pr.pstyle), false)
	for i in 11:
		if c.xi[i] >= 0:
			c.roles[i] = RL.valid(c.roles[i], c.slots[i][0])
	TC.pins_valid(c)


func auto_roles(c: Dictionary):
	var sl = slots_of(c)
	for i in 11:
		if c.xi[i] >= 0:
			c.roles[i] = RL.best(s.players[c.xi[i]], sl[i][0])
		else:
			c.roles[i] = RL.BY_POS[sl[i][0]][0]


func pick_xi(c: Dictionary, slots: Array) -> Dictionary:
	var avail = []
	for pid in c.players:
		var p = s.players[pid]
		if p.inj <= 0 and p.susp <= 0 and not p.get("youth", false):
			avail.append(p)
	var xi = []
	xi.resize(11)
	xi.fill(-1)
	var used = {}
	# pass 1: natural positions
	for i in 11:
		var role = slots[i][0]
		var best = null
		var bs = -1.0
		for p in avail:
			if used.has(p.id) or (p.pos != role and not (role in p.alt)):
				continue
			var sc = p.ovr * (1.0 if p.pos == role else 0.98) * (0.8 + 0.2 * p.cond / 100.0)
			if sc > bs:
				bs = sc
				best = p
		if best != null:
			xi[i] = best.id
			used[best.id] = bs
	# pass 2: fill gaps / upgrade with out-of-position players
	for i in 11:
		var role = slots[i][0]
		var cs = used.get(xi[i], -1.0) if xi[i] >= 0 else -1.0
		var best = null
		var bs = cs + 1.5
		for p in avail:
			if used.has(p.id):
				continue
			var sc = p.ovr * fit(p, role) * (0.8 + 0.2 * p.cond / 100.0)
			if sc > bs:
				bs = sc
				best = p
		if best != null:
			if xi[i] >= 0:
				used.erase(xi[i])
			xi[i] = best.id
			used[best.id] = bs
	var rest = []
	for p in avail:
		if not used.has(p.id):
			rest.append(p)
	rest.sort_custom(func(a, b): return a.ovr > b.ovr)
	var bench = []
	for l in [0, 1, 2, 3]:
		for p in rest:
			if LINE[p.pos] == l and not (p.id in bench):
				bench.append(p.id)
				break
	for p in rest:
		if bench.size() >= 7:
			break
		if not (p.id in bench) and p.pos != "GK":
			bench.append(p.id)
	return {"xi": xi, "bench": bench}


func best_formation(c: Dictionary) -> String:
	var best = "4-3-3"
	var bs = -1.0
	for f in FORMATIONS.keys():
		var slots = FORMATIONS[f]
		var xi = pick_xi(c, slots).xi
		var t = 0.0
		for i in 11:
			if xi[i] >= 0:
				t += s.players[xi[i]].ovr * fit(s.players[xi[i]], slots[i][0])
		t += rng.randf() * 4.0
		if t > bs:
			bs = t
			best = f
	return best


func auto_pick(c: Dictionary):
	var r = pick_xi(c, slots_of(c))
	c.xi = r.xi
	c.bench = r.bench


func fix_lineup() -> Array:
	# make sure the user's XI and bench only contain available squad players
	var c = uc()
	var changes = []
	if c.xi.size() != 11:
		auto_pick(c)
		return changes
	var slots = slots_of(c)
	var bench2 = []
	for pid in c.bench:
		if pid in c.players and available(s.players[pid]) and not (pid in c.xi) and not (pid in bench2):
			bench2.append(pid)
	c.bench = bench2
	for i in 11:
		var pid = c.xi[i]
		if pid >= 0 and pid in c.players and available(s.players[pid]) and c.xi.find(pid) == i:
			continue
		var best = null
		var bs = -1.0
		for q in c.players:
			var p = s.players[q]
			if q in c.xi or not available(p) or p.get("youth", false):
				continue
			var sc = p.ovr * fit(p, slots[i][0])
			if sc > bs:
				bs = sc
				best = p
		if pid >= 0 and s.players.has(pid) and pid in c.players and best != null:
			changes.append("%s replaces %s" % [pname(best), pname(s.players[pid])])
		c.xi[i] = best.id if best != null else -1
		if best != null:
			c.bench.erase(best.id)
	# top up the bench
	if c.bench.size() < 7:
		var rest = []
		for q in c.players:
			if not (q in c.xi) and not (q in c.bench) and available(s.players[q]) and not s.players[q].get("youth", false):
				rest.append(s.players[q])
		rest.sort_custom(func(a, b): return a.ovr > b.ovr)
		var has_gk = false
		for q in c.bench:
			if s.players[q].pos == "GK":
				has_gk = true
		for p in rest:
			if c.bench.size() >= 7:
				break
			if p.pos == "GK":
				if has_gk:
					continue
				has_gk = true
			c.bench.append(p.id)
	return changes


func lineup(cid: int, opp: int) -> Dictionary:
	var c = s.clubs[cid]
	if cid == s.user.club:
		fix_lineup()
		for i in 11:
			c.roles[i] = RL.valid(c.roles[i], c.slots[i][0])
		TC.pins_valid(c)
		return {"club": cid, "xi": c.xi, "bench": c.bench, "formation": c.formation, "ment": c.ment, "press": c.press, "tempo": c.tempo, "user": true, "boost": 1.0 + (s.user.attr.tac - 10) * 0.0015,
			"slots": c.slots, "rids": c.roles, "instr": c.instr, "pk": c.pk, "fk": c.fk, "ck": c.ck, "capt": c.capt, "pins": c.pins, "tm_pid": c.tm_pid}
	var r = lu_cache.get(cid, null)
	if r != null:
		for pid in r.xi:
			if pid < 0 or not s.players.has(pid):
				r = null
				break
			var p = s.players[pid]
			if p.club != cid or p.inj > 0 or p.susp > 0 or p.cond < 86:
				r = null
				break
	if r != null:
		for pid in r.bench:
			if not s.players.has(pid) or s.players[pid].club != cid or not available(s.players[pid]):
				r = null
				break
	if r == null or r.day < s.day - 28:
		r = pick_xi(c, FORMATIONS[c.formation])
		r["day"] = s.day
		var rids = []
		var fs = FORMATIONS[c.formation]
		for i in 11:
			rids.append(RL.best(s.players[r.xi[i]], fs[i][0]) if r.xi[i] >= 0 else RL.BY_POS[fs[i][0]][0])
		r["rids"] = rids
		lu_cache[cid] = r
	var d = c.rep - s.clubs[opp].rep
	var ment = 3 if d >= 4 else (1 if d <= -6 else 2)
	var sty = TC.STYLES[TC.style_of(c)].set
	return {"club": cid, "xi": r.xi, "bench": r.bench, "formation": c.formation, "ment": ment, "press": sty.press, "tempo": sty.tempo, "user": false,
		"slots": FORMATIONS[c.formation], "rids": r.rids, "instr": TC.ai_instr(c), "pk": -1, "fk": -1, "ck": -1, "capt": -1}


func team_ratings(cid: int) -> Dictionary:
	# quick attack / midfield / defence summary for display
	var c = s.clubs[cid]
	var slots = slots_of(c)
	var xi = c.xi if cid == s.user.club and c.xi.size() == 11 else pick_xi(c, slots).xi
	var sum = [0.0, 0.0, 0.0, 0.0]
	var n = [0, 0, 0, 0]
	for i in 11:
		if xi[i] < 0:
			continue
		var p = s.players[xi[i]]
		var l = LINE[slots[i][0]]
		sum[l] += p.ovr * fit(p, slots[i][0])
		n[l] += 1
	var ovr = (sum[0] + sum[1] + sum[2] + sum[3]) / max(1, n[0] + n[1] + n[2] + n[3])
	return {"att": int(round(sum[3] / max(1, n[3]))), "mid": int(round(sum[2] / max(1, n[2]))), "def": int(round((sum[1] + sum[0]) / max(1, n[1] + n[0]))), "ovr": int(round(ovr))}


# ---------------------------------------------------------------- matches

func build_index():
	fx_by_day = {}
	for i in s.fixtures.size():
		var d = s.fixtures[i].day
		if not fx_by_day.has(d):
			fx_by_day[d] = []
		fx_by_day[d].append(i)


func user_fixture_today():
	for i in fx_by_day.get(s.day, []):
		var f = s.fixtures[i]
		if not f.played and (f.h == s.user.club or f.a == s.user.club):
			return f
	return null


func next_user_fixture():
	var best = null
	for f in s.fixtures:
		if not f.played and (f.h == s.user.club or f.a == s.user.club):
			if best == null or f.day < best.day:
				best = f
	return best


func fx_caption(f: Dictionary) -> String:
	if f.get("comp", "") != "" or f.ko:
		return f.label
	return "%s · Round %d" % [s.leagues[f.lg].name, f.rd]


func club_fixtures(cid: int) -> Array:
	var out = []
	for f in s.fixtures:
		if f.h == cid or f.a == cid:
			out.append(f)
	out.sort_custom(func(a, b): return a.day < b.day)
	return out


func new_sim(f: Dictionary, detailed: bool):
	var sim = ME.new()
	sim.setup(f, lineup(f.h, f.a), lineup(f.a, f.h), detailed)
	return sim


func sim_fixture(f: Dictionary):
	var sim = new_sim(f, false)
	sim.sd[0].auto = true
	sim.sd[1].auto = true
	sim.run_to_end()
	apply_match(sim)
	return sim


func play_day_fixtures():
	for i in fx_by_day.get(s.day, []):
		var f = s.fixtures[i]
		if f.played or f.h == s.user.club or f.a == s.user.club:
			continue
		sim_fixture(f)


func apply_match(sim):
	var f = sim.fx
	var ucid = s.user.club
	f.played = true
	f.hg = sim.sd[0].goals
	f.ag = sim.sd[1].goals
	if sim.pens != null:
		f.pens = sim.pens
	var involved = f.h == ucid or f.a == ucid
	if involved:
		var sc = [[], []]
		for i in 2:
			for g in sim.sd[i].scorers:
				sc[i].append([pname(s.players[g.pid]), g.m, g.pen])
		f.sc = sc
	if f.get("fr", false):
		# friendlies only cost fitness
		for pid in sim.pm:
			if sim.pm[pid].tin >= 0:
				s.players[pid].cond = int(sim.pm[pid].cond)
				s.recov[pid] = true
		if involved:
			TC.after_match(sim, 0 if f.h == ucid else 1)
		return
	for i in 2:
		var t = sim.sd[i]
		var o = sim.sd[1 - i]
		var c = t.club
		for pid in c.players:
			var p = s.players[pid]
			if p.susp > 0:
				p.susp -= 1
		var res = "D"
		if t.goals > o.goals: res = "W"
		elif t.goals < o.goals: res = "L"
		if not f.ko and f.get("comp", "") == "":
			var tb = c.t
			tb.p += 1
			tb.gf += t.goals
			tb.ga += o.goals
			if res == "W":
				tb.w += 1
				tb.pts += 3
			elif res == "D":
				tb.d += 1
				tb.pts += 1
			else:
				tb.l += 1
		c.form.append(res)
		if c.form.size() > 5:
			c.form.pop_front()
		var md = 3 if res == "W" else (-3 if res == "L" else 0)
		for pid in c.players:
			var p = s.players[pid]
			if not sim.pm.has(pid) or sim.pm[pid].tin < 0:
				if c.id == ucid and available(p) and not f.get("fr", false):
					var stt = status_of(p)
					if stt == 0:
						p.mor = max(20, p.mor - 2)
					elif stt == 1 and p.mor > 45:
						p.mor -= 1
				continue
			var q = sim.pm[pid]
			p.cond = int(q.cond)
			s.recov[pid] = true
			var ss = p.ss
			ss.ap += 1
			ss.g += q.g
			ss.a += q.a
			ss.rs += q.r
			ss.yc += q.yc
			ss.rc += q.rc
			p.cg += q.g
			p.cap += 1
			p.form = lerp(p.form, q.r, 0.4)
			p.mor = clampi(p.mor + md + int((q.r - 6.5) * 2.0), 20, 100)
			if q.rc > 0:
				p.susp = 1 if q.yc >= 2 else rng.randi_range(1, 3)
				if c.id == ucid:
					msg("%s suspended" % pname(p), "%s was sent off and will miss the next %d match%s." % [pfull(p), p.susp, "" if p.susp == 1 else "es"])
			elif q.yc > 0:
				p.ycs += q.yc
				if p.ycs >= 5:
					p.ycs = 0
					p.susp = 1
					if c.id == ucid:
						msg("%s suspended" % pname(p), "%s has picked up five yellow cards and is banned for the next match." % pfull(p))
			if q.inj > 0:
				p.inj = OPS.injury_days(q.inj) if c.id == ucid else q.inj
				if c.id == ucid:
					msg("Injury: %s" % pname(p), "%s picked up an injury and will be out for around %s." % [pfull(p), inj_text(q.inj)])
		if o.goals == 0 and t.xi[0] >= 0:
			s.players[t.xi[0]].ss.cs += 1
	if sim.motm >= 0:
		s.players[sim.motm].ss.mom += 1
	TC.totw_note(sim)
	if f.get("comp", "") != "":
		CP.on_result(f)
	if f.h == ucid:
		OPS.on_home_match(uc())
	if involved:
		var ui = 0 if f.h == ucid else 1
		var t = sim.sd[ui]
		var o = sim.sd[1 - ui]
		var u = s.user
		TC.after_match(sim, ui)
		MK.pay_bonuses(sim, ui)
		u.p += 1
		var pts = 1
		if t.goals > o.goals:
			u.w += 1
			pts = 3
		elif t.goals < o.goals:
			u.l += 1
			pts = 0
		else:
			u.d += 1
		var ex = clamp(1.35 + (t.club.rep - o.club.rep) * 0.05 + (0.25 if ui == 0 else -0.15), 0.3, 2.6)
		u.conf = clamp(u.conf + (pts - ex) * 3.0, 0.0, 100.0)
		if f.ko and sim.winner() == ui:
			u.conf = min(100.0, u.conf + 6)
		u["fans"] = clamp(u.get("fans", 55.0) + (pts - ex) * 2.2 + (1.5 if t.goals - o.goals >= 3 else 0.0), 0.0, 100.0)
		var sp = u.get("sponsor")
		if sp != null and pts == 3:
			uc().budget += int(sp.win)
		if pts == 3:
			OPS.life().cash += int(OPS.salary() * 0.25)
		if not f.get("fr", false):
			var star = t.club.short
			if sim.motm >= 0 and s.players.has(sim.motm) and s.players[sim.motm].club == t.club.id:
				star = pname(s.players[sim.motm])
			SOC.on_result(t.club, o.club, t.goals, o.goals, star, is_derby(f.h, f.a))
		if is_derby(f.h, f.a):
			u.fans = clamp(u.fans + (pts - 1.2) * 3.0, 0.0, 100.0)
			if pts == 3:
				scrap("Derby day", "%s beat %s %d-%d" % [t.club.name, o.club.name, t.goals, o.goals])
		if t.goals - o.goals >= 4:
			scrap("Big win", "%s %d-%d %s" % [t.club.name, t.goals, o.goals, o.club.name])
		elif o.club.rep - t.club.rep >= 8 and pts == 3:
			scrap("Giant killing", "%s beat %s %d-%d" % [t.club.name, o.club.name, t.goals, o.goals])
		if u.conf < 6.0 and uc().t.p >= 10 and not u.sacked and float(OPS.life().get("stakes", {}).get(ucid, 0)) < 51.0:
			u.sacked = true
			stop_flag = true


func inj_text(days: int) -> String:
	if days < 10:
		return "%d days" % days
	if days < 50:
		return "%d weeks" % int(round(days / 7.0))
	return "%d months" % int(round(days / 30.0))


# ---------------------------------------------------------------- time

func advance() -> void:
	# moves time forward until something needs the manager's attention
	stop_flag = false
	for i in 7:
		play_day_fixtures()
		s.day += 1
		start_of_day()
		if user_fixture_today() != null or stop_flag or s.review != null or s.user.sacked:
			break
	save_game()


func start_of_day():
	set_date()
	var rec = s.recov
	for pid in rec.keys():
		if not s.players.has(pid):
			rec.erase(pid)
			continue
		var p = s.players[pid]
		if p.cond < 100:
			p.cond = min(100, p.cond + (OPS.recover_rate(p) if p.club == s.user.club else 6))
		if p.inj > 0:
			p.inj -= 1
		if p.cond >= 100 and p.inj <= 0:
			rec.erase(pid)
	if cur.day == 1 and (cur.month >= 9 or cur.month <= 5):
		develop_all()
	if cur.day == 1 and cur.month == 1:
		contract_warning()
	if window_open():
		TR.daily()
		if cur.day == 31 and (cur.month == 8 or cur.month == 1):
			MK.dd_start()
			msg("Deadline day", "It is the last day of the transfer window, and it runs hour by hour until 23:00. Open Deadline Day from your to-do list or the Transfer Centre to follow it live: late bids for your players, agents with cut-price offers, and deals going through everywhere.\n\nAny business you want to do has to happen today. A fee agreed today brings the player in to talk terms the same evening.", "info", null, true)
	DL.tick()
	TR.expire_offers()
	LG.update_playoffs()
	CP.daily()
	if cur.day == 1 and (cur.month == 9 or cur.month == 2):
		msg("Transfer window closed", "The transfer window has closed. You can still sign free agents and agree new contracts with your own players.")
	if cur.day == 1 and cur.month == 1:
		msg("Transfer window open", "The January transfer window is open until the end of the month.", "info", null, true)
	if cur.day == 15:
		refresh_jobs()
	OPS.daily()
	MK.daily()
	if s.day == ymd(s.season + 1, 6, 12):
		LG.rollover()
		stop_flag = true


func develop_all():
	var up = []
	var down = []
	var ucid = s.user.club
	for pid in s.players:
		var p = s.players[pid]
		var a = age(p)
		var ch = 0
		if p.ovr < p.pot and a <= 29:
			var pr = 0.05
			if a <= 19: pr = 0.5
			elif a <= 21: pr = 0.42
			elif a <= 23: pr = 0.3
			elif a <= 26: pr = 0.15
			pr *= 0.75 + min(0.5, p.ss.ap * 0.03)
			if p.club == ucid:
				pr *= OPS.growth_mult(p)
			if rng.randf() < pr:
				ch = 1
		elif a >= 31:
			if rng.randf() < (a - 30) * 0.06:
				ch = -1
		if ch != 0:
			change_ovr(p, ch)
			if p.club == ucid:
				if ch > 0:
					up.append("%s (%d)" % [pname(p), p.ovr])
				else:
					down.append("%s (%d)" % [pname(p), p.ovr])
	OPS.monthly_training()
	if up.size() + down.size() > 0:
		var body = ""
		if up.size() > 0:
			body += "Improved: " + ", ".join(up) + "."
		if down.size() > 0:
			body += ("\n\n" if body != "" else "") + "Declined: " + ", ".join(down) + "."
		msg("Monthly development report", body, "info")


func change_ovr(p: Dictionary, ch: int):
	p.ovr = clampi(p.ovr + ch, 30, 99)
	for i in 6:
		if ch > 0:
			if rng.randf() < 0.65:
				p.st[i] = min(99, p.st[i] + 1)
		else:
			if rng.randf() < (0.8 if (i == 0 or i == 5) else 0.45):
				p.st[i] = max(20, p.st[i] - 1)
	for i in p.at.size():
		if ch > 0:
			if rng.randf() < 0.45:
				p.at[i] = min(99, p.at[i] + 1)
		elif rng.randf() < (0.7 if (i == 7 or i == 8) else 0.3):
			p.at[i] = max(10, p.at[i] - 1)
	if p.pot < p.ovr:
		p.pot = p.ovr


func contract_warning():
	var names = []
	for pid in uc().players:
		var p = s.players[pid]
		if p.cend <= s.season + 1:
			names.append(pname(p))
	if names.size() > 0:
		msg("Contracts expiring", "These players are out of contract at the end of the season and will leave for free unless you agree new deals:\n\n" + ", ".join(names) + ".", "contract", null, true)


func refresh_jobs():
	var u = s.user
	var cands = []
	for c in s.clubs:
		if c.id != u.club and not s.leagues[c.lg].roe and c.rep <= u.rep + 26.5 and c.rep >= u.rep + 13:
			cands.append(c.id)
	cands.shuffle()
	u.jobs = cands.slice(0, 4)


func take_job(cid: int):
	var u = s.user
	var old = uc()
	old.formation = best_formation(old)
	old.erase("slots")
	old.erase("roles")
	lu_cache.erase(old.id)
	u.club = cid
	u.conf = 60.0
	u.sacked = false
	u.jobs = []
	s.offers = []
	s.negos = {}
	s.deals = {}
	var c = uc()
	u.obj = LG.objective(c)
	init_user_tactics(c)
	OPS.ensure(c)
	msg("Welcome to %s" % c.name, "You have been appointed manager of %s.\n\nObjective: %s." % [c.name, u.obj.text], "board")
	save_game()


# ---------------------------------------------------------------- save / load

func has_save(i = null) -> bool:
	return FileAccess.file_exists(save_path(i))


func save_game():
	var f = FileAccess.open(save_path(), FileAccess.WRITE)
	if f == null:
		return
	f.store_var(s)
	f.close()
	var m = FileAccess.open(meta_path(), FileAccess.WRITE)
	if m != null:
		m.store_var({"club": uc().name, "manager": s.user.name, "date": fmt_date(s.day, true), "season": season_name(), "cid": s.user.club, "c1": uc().c1, "c2": uc().c2, "short": uc().short})
		m.close()


func load_game(i = null) -> bool:
	if i != null:
		slot = i
	if not has_save():
		return false
	var f = FileAccess.open(save_path(), FileAccess.READ)
	var d = f.get_var()
	f.close()
	if typeof(d) != TYPE_DICTIONARY or not d.has("players"):
		return false
	DB.load_db()
	s = d
	set_date()
	build_index()
	ensure_state()
	lu_cache = {}
	active = true
	return true


func save_meta(i = null):
	if not FileAccess.file_exists(meta_path(i)):
		return null
	var f = FileAccess.open(meta_path(i), FileAccess.READ)
	var d = f.get_var()
	f.close()
	return d if typeof(d) == TYPE_DICTIONARY else null

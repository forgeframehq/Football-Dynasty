extends RefCounted
# Tactics depth: team playstyles and manager proficiency, extra team and individual instructions,
# player skills, manager link-up plays, style fit and familiarity, form arrows.
# Everything the match engine needs is prepared once per side in side_setup() and read back in pl_mods().

# ------------------------------------------------------------------ playstyles

# set: the instructions a style applies when chosen; roles: role ids that suit it
const STYLES = [
	{"n": "Possession Game", "s": "POS", "d": "Keep the ball, move the opposition around and wait for the opening.",
		"set": {"ment": 2, "press": 2, "tempo": 0, "width": 1, "line": 2, "pass": 0, "counter": false, "eng": 2, "compact": 1, "build": 1, "final": 1, "cross": 1, "overlap": false},
		"roles": ["sk", "bpd", "ifb", "dlp", "ply", "cm", "ap", "am", "wp", "f9", "if"]},
	{"n": "Quick Counter", "s": "QC", "d": "Win it back high up the pitch and attack at once, at speed.",
		"set": {"ment": 3, "press": 2, "tempo": 2, "width": 1, "line": 2, "pass": 1, "counter": true, "eng": 2, "compact": 1, "build": 0, "final": 0, "cross": 1, "overlap": false},
		"roles": ["sk", "stp", "wb", "bwm", "b2b", "dm", "ss", "if", "wf", "pf", "st", "poa"]},
	{"n": "Long Ball Counter", "s": "LBC", "d": "Defend deep in numbers, then hit the space behind with one long pass.",
		"set": {"ment": 1, "press": 0, "tempo": 2, "width": 0, "line": 0, "pass": 2, "counter": true, "eng": 0, "compact": 0, "build": 0, "final": 0, "cross": 0, "overlap": false},
		"roles": ["gk", "cd", "fb", "anc", "dm", "bwm", "wm", "wf", "poa", "tm", "st"]},
	{"n": "Out Wide", "s": "OW", "d": "Stretch the pitch, get the ball to the flanks and fill the box with crosses.",
		"set": {"ment": 2, "press": 1, "tempo": 1, "width": 2, "line": 1, "pass": 1, "counter": false, "eng": 1, "compact": 2, "build": 2, "final": 3, "cross": 2, "overlap": true},
		"roles": ["gk", "cd", "fb", "wb", "cm", "b2b", "wng", "wm", "wf", "tm", "st"]},
	{"n": "Long Ball", "s": "LB", "d": "Miss out midfield: go long to the front men early and fight for the second ball.",
		"set": {"ment": 2, "press": 1, "tempo": 2, "width": 1, "line": 1, "pass": 2, "counter": false, "eng": 1, "compact": 1, "build": 0, "final": 2, "cross": 2, "overlap": false},
		"roles": ["gk", "cd", "stp", "anc", "bwm", "b2b", "wm", "tm", "poa", "ss", "pf"]},
]

# ------------------------------------------------------------------ team instructions

const INSTR_DEF = {"width": 1, "line": 1, "pass": 1, "counter": false, "eng": 1, "compact": 1, "mark": 0, "tackle": 1, "trap": false,
	"build": 0, "final": 0, "cross": 0, "overlap": false, "waste": 0}

# key, title, options, what it does (shown under the title), where it lives ("c" = on the club, "i" = in instr)
const DEF_OPTS = [
	["line", "Defensive line", ["Deep", "Balanced", "High"], "High squeezes play, leaves space behind", "i"],
	["press", "Closing down", ["Sit back", "Own half", "All over"], "More pressing wins it early, costs legs", "c"],
	["eng", "Line of engagement", ["Low", "Mid", "High"], "Where your forwards start to press", "i"],
	["compact", "Compactness", ["Tight", "Normal", "Loose"], "Tight protects the middle, slows your breaks", "i"],
	["mark", "Marking", ["Zonal", "Tight"], "Tight marking is safer and more tiring", "i"],
	["tackle", "Tackling", ["Stay up", "Normal", "Hard"], "Hard wins more balls and more cards", "i"],
	["trap", "Offside trap", ["No", "Yes"], "Needs a line that is not deep; risky when beaten", "i"],
]
const ATT_OPTS = [
	["pass", "Passing", ["Short", "Mixed", "Direct"], "Short keeps it, direct gets it forward", "i"],
	["tempo", "Tempo", ["Patient", "Normal", "Fast"], "Fast makes chances and gives it away", "c"],
	["counter", "Counter-attack", ["No", "Yes"], "Break at speed when they have the ball more", "i"],
	["build", "Build-up", ["Mixed", "Middle", "Flanks"], "Which players see most of the ball", "i"],
	["final", "Final third", ["Mixed", "Work it in", "Shoot", "Cross early"], "Fewer better chances, or more of them", "i"],
	["cross", "Crossing", ["Mixed", "Low", "High", "Far post"], "Low wants finishers, high wants headers", "i"],
	["overlap", "Overlaps", ["No", "Yes"], "Full-backs join in and leave gaps", "i"],
	["waste", "Time-wasting", ["Never", "Late on", "When ahead"], "Kills the game when you lead", "i"],
]

# ------------------------------------------------------------------ individual instructions

const PINS = {
	"ct": {"n": "Counter Target", "k": "att", "pos": ["ST", "LW", "RW", "CAM"], "d": "Stays up the pitch when you defend and is the first pass on the break."},
	"afb": {"n": "Attacking Full-back", "k": "att", "pos": ["LB", "RB"], "d": "Pushes on at every chance. More crosses, more space behind him."},
	"ht": {"n": "Hug the Touchline", "k": "att", "pos": ["LM", "RM", "LW", "RW"], "d": "Stays wide to stretch the back line and supply the box."},
	"anc": {"n": "Anchoring", "k": "def", "pos": ["CDM", "CM"], "d": "Holds his position in front of the defence and does not go forward."},
	"tm": {"n": "Tight Marking", "k": "def", "pos": ["CB", "CDM", "CM", "LB", "RB"], "d": "Follows their danger man everywhere. Takes that player out of the game, and himself with him."},
	"dl": {"n": "Deep Line", "k": "def", "pos": ["CB", "LB", "RB", "CDM"], "d": "Drops off and covers rather than stepping up."},
	"dfb": {"n": "Defensive Full-back", "k": "def", "pos": ["LB", "RB"], "d": "Stays back and keeps the defence at four."},
}

# ------------------------------------------------------------------ player skills

# req: [attribute index, minimum] (detailed attributes); gk: [headline stat index, minimum] for goalkeepers
# lines: where the skill can appear (0 GK, 1 DEF, 2 MID, 3 ATT); luck: only one player in N gets it even when eligible
const SKILLS = {
	"thr": {"n": "Through Passing", "d": "Slides passes between defenders. More assists.", "req": [[4, 80], [5, 78]]},
	"otp": {"n": "One-touch Pass", "d": "Moves it on first time. Helps you keep the ball.", "req": [[4, 82], [13, 76]]},
	"lp": {"n": "Long Passer", "d": "Finds a runner from forty yards.", "req": [[15, 81]]},
	"pc": {"n": "Pinpoint Crossing", "d": "His crosses land on a team-mate's head.", "req": [[3, 81]]},
	"fts": {"n": "First-time Shot", "d": "Finishes without a touch. Better with clear chances.", "req": [[0, 82], [13, 76]]},
	"lr": {"n": "Long Ranger", "d": "A real threat from outside the box.", "req": [[1, 82]]},
	"oc": {"n": "Outside Curler", "d": "Bends shots round defenders and keepers.", "req": [[1, 78], [0, 78], [6, 80]]},
	"acr": {"n": "Acrobatic Finish", "d": "Volleys and overhead kicks from crosses and corners.", "req": [[0, 80], [6, 76]], "lines": [3]},
	"hd": {"n": "Heading", "d": "Wins and scores headers from crosses and set pieces.", "req": [[2, 81]]},
	"drb": {"n": "Dribbler", "d": "Beats his man one against one.", "req": [[6, 85]]},
	"spd": {"n": "Speed Merchant", "d": "Deadly on the break when there is space to run into.", "req": [[7, 88]]},
	"int": {"n": "Interception", "d": "Reads passes and steps in front.", "req": [[11, 80], [10, 76]]},
	"mm": {"n": "Man Marking", "d": "Sticks to his man. Makes Tight Marking stronger.", "req": [[11, 83]]},
	"blk": {"n": "Blocker", "d": "Throws himself in the way of shots.", "req": [[10, 82], [14, 74]], "lines": [1, 2]},
	"aer": {"n": "Aerial Superiority", "d": "Clears everything in the air at the back.", "req": [[2, 78], [9, 80]], "lines": [1, 2]},
	"tb": {"n": "Track Back", "d": "A forward who works for the team without the ball.", "req": [[8, 80], [14, 68]], "lines": [3]},
	"lt": {"n": "Long Throw", "d": "His throw-ins near the box are as good as a corner.", "req": [[9, 76]], "lines": [1], "luck": 6},
	"pen": {"n": "Penalty Specialist", "d": "Rarely misses from the spot.", "req": [[17, 84]]},
	"fk": {"n": "Free-kick Specialist", "d": "Dangerous from any free kick in range.", "req": [[16, 83]]},
	"cap": {"n": "Captaincy", "d": "Lifts the team more when he wears the armband.", "req": [[13, 78], [14, 62]], "age": 27, "luck": 3},
	"sub": {"n": "Super-sub", "d": "Plays above himself when he comes off the bench late.", "req": [[7, 76]], "lines": [2, 3], "luck": 9},
	"fs": {"n": "Fighting Spirit", "d": "Keeps his level when the team is behind or the legs are gone.", "req": [[13, 80], [8, 74]], "luck": 2},
	"psv": {"n": "Penalty Saver", "d": "Gets to more penalties than he should.", "gk": [[3, 84]]},
	"gkd": {"n": "Quick Distribution", "d": "Starts attacks from the back with his kicking and throwing.", "gk": [[2, 80]]},
}
const MAX_GEN = 5
const MAX_SKILLS = 8

# ------------------------------------------------------------------ link-up plays

# a / b: the two slots. pos = slot positions; a player fits with one of the skills (sk) or by meeting all attributes (at); gk = headline stats for a keeper
const LINKS = {
	"ott": {"n": "Over-the-Top Pass", "style": [2, 1], "d": "A passer from deep drops the ball over the defence for a quick forward to run onto.",
		"a": {"t": "Passer", "pos": ["CB", "CDM", "CM"], "sk": ["lp", "thr"], "at": [[15, 78]]}, "b": {"t": "Runner", "pos": ["ST", "LW", "RW"], "sk": ["spd"], "at": [[7, 82]]}},
	"one": {"n": "One-Two", "style": [0], "d": "A quick wall pass on the edge of the box puts the runner through.",
		"a": {"t": "Wall", "pos": ["CAM", "CM", "ST"], "sk": ["otp"], "at": [[4, 80]]}, "b": {"t": "Runner", "pos": ["ST", "CAM", "LW", "RW", "LM", "RM"], "sk": ["drb"], "at": [[6, 80]]}},
	"ovl": {"n": "Overlap", "style": [3], "same_side": true, "d": "The full-back runs outside his winger and takes the ball to the byline.",
		"a": {"t": "Full-back", "pos": ["LB", "RB"], "sk": ["pc"], "at": [[3, 72], [8, 74]]}, "b": {"t": "Winger", "pos": ["LM", "RM", "LW", "RW"], "sk": [], "at": [[4, 72]]}},
	"kd": {"n": "Knock-Down", "style": [4], "d": "The big man wins the long ball and nods it down for his partner.",
		"a": {"t": "Target", "pos": ["ST"], "sk": ["hd"], "at": [[2, 78], [9, 76]]}, "b": {"t": "Finisher", "pos": ["ST", "CAM", "LW", "RW"], "sk": ["fts"], "at": [[0, 78]]}},
	"cut": {"n": "Cut-Back", "style": [1, 3], "d": "The wide man beats his full-back and pulls it back for a late arrival.",
		"a": {"t": "Wide man", "pos": ["LW", "RW", "LM", "RM"], "sk": ["drb"], "at": [[7, 80], [6, 77]]}, "b": {"t": "Arriver", "pos": ["CM", "CAM", "ST"], "sk": ["fts", "lr"], "at": [[0, 76]]}},
	"sw": {"n": "Switch of Play", "style": [0, 3], "d": "A long diagonal finds the far-side wide man in space.",
		"a": {"t": "Switcher", "pos": ["CM", "CDM", "CB"], "sk": ["lp"], "at": [[15, 80]]}, "b": {"t": "Wide man", "pos": ["LW", "RW", "LM", "RM", "LB", "RB"], "sk": ["spd"], "at": [[7, 78]]}},
	"tc": {"n": "Target Cross", "style": [3, 4], "d": "Every cross from one man is aimed at one head.",
		"a": {"t": "Crosser", "pos": ["LB", "RB", "LM", "RM", "LW", "RW"], "sk": ["pc"], "at": [[3, 79]]}, "b": {"t": "Target", "pos": ["ST"], "sk": ["hd", "acr"], "at": [[2, 78]]}},
	"cl": {"n": "Counter Launch", "style": [2, 1], "d": "The moment you win it, the ball goes long from the back for your quickest forward.",
		"a": {"t": "Launcher", "pos": ["GK", "CB", "CDM"], "sk": ["lp", "gkd"], "at": [[15, 76]], "gk": [[2, 78]]}, "b": {"t": "Outlet", "pos": ["ST", "LW", "RW"], "sk": ["spd"], "at": [[7, 85]]}},
}
const LINK_ORDER = ["ott", "one", "ovl", "kd", "cut", "sw", "tc", "cl"]
const LEVELS = ["Bronze", "Silver", "Gold"]
const LEVEL_AT = [0, 10, 25]
const LEVEL_COL = ["c98b53", "c9d3de", "f6c945"]


# ------------------------------------------------------------------ state

static func ensure():
	# brings a save up to date; safe to call on every load
	var s = G.s
	var u = s.user
	var c = G.uc()
	if not c.has("instr"):
		c["instr"] = {}
	for k in INSTR_DEF:
		if not c.instr.has(k):
			c.instr[k] = INSTR_DEF[k]
	if not c.has("pins") or c.pins.size() != 11:
		c["pins"] = ["", "", "", "", "", "", "", "", "", "", ""]
	if not c.has("tm_pid"):
		c["tm_pid"] = -1
	if not u.has("prof"):
		# an existing career: read the manager's best style off the way he already plays
		var best = guess_style(c)
		u["prof"] = start_prof(best, int(u.get("badge", 2)))
		u["tac_set"] = false
		c["pstyle"] = best
	if not c.has("pstyle"):
		c["pstyle"] = best_style()
	if not u.has("links"):
		u["links"] = []
	if not u.has("pairs"):
		u["pairs"] = {}
	if not u.has("link_goals"):
		u["link_goals"] = 0
	if not s.has("sk_done"):
		s["sk_done"] = true
		for pid in s.players:
			var p = s.players[pid]
			if not p.has("sk"):
				p["sk"] = gen_skills(p)
	for pid in c.players:
		ensure_fam(s.players[pid])


static func start_prof(best: int, badge: int) -> Array:
	var out = []
	for i in STYLES.size():
		out.append(float(clampi(42 + badge * 4 + ((i * 7 + best * 3) % 11), 30, 75)))
	out[best] = float(min(90, 76 + badge * 3))
	return out


static func best_style() -> int:
	var pr = G.s.user.prof
	var b = 0
	for i in pr.size():
		if pr[i] > pr[b]:
			b = i
	return b


static func guess_style(c: Dictionary) -> int:
	var ins = c.get("instr", {})
	if ins.get("counter", false):
		return 2 if int(ins.get("pass", 1)) == 2 or int(ins.get("line", 1)) == 0 else 1
	if int(ins.get("pass", 1)) == 0:
		return 0
	if int(ins.get("width", 1)) == 2:
		return 3
	if int(ins.get("pass", 1)) == 2:
		return 4
	return 0


static func link_slots() -> int:
	return 1 + clampi(int(G.s.user.get("badge", 0)), 0, 4)


static func set_style(c: Dictionary, idx: int, apply_defaults := true):
	# the user changes playstyle: instructions move to the style's defaults and the squad has to learn it
	var s = G.s
	var changed = int(c.get("pstyle", -1)) != idx
	c["pstyle"] = idx
	if apply_defaults:
		var st = STYLES[idx].set
		for k in st:
			if k in ["ment", "press", "tempo"]:
				c[k] = st[k]
			else:
				c.instr[k] = st[k]
	if changed and s.user.get("tac_set", false):
		for pid in c.players:
			var p = s.players[pid]
			p["fam"] = max(30.0, float(p.get("fam", 55.0)) * 0.55)


static func style_of(c: Dictionary) -> int:
	if c.has("pstyle"):
		return int(c.pstyle)
	return (c.id * 7 + int(c.rep)) % STYLES.size()


static func ai_link(c: Dictionary) -> String:
	return LINK_ORDER[(c.id * 3 + 1 + style_of(c)) % LINK_ORDER.size()]


static func ai_prof(c: Dictionary) -> float:
	return clamp(55.0 + (c.rep - 50.0) * 0.5, 50.0, 78.0)


static func ensure_fam(p: Dictionary):
	var ucid = G.s.user.club
	if p.club != ucid:
		return
	if int(p.get("famc", -1)) == ucid and p.has("fam"):
		return
	var first = not G.s.user.has("fam_init")
	var v = 58.0 + (p.id % 9)
	if not first:
		# a new signing: quicker to settle if his old club played the same way
		v = 34.0 + (p.id % 11)
		var prev = int(p.get("prevc", -1))
		if prev >= 0 and prev < G.s.clubs.size() and style_of(G.s.clubs[prev]) == style_of(G.uc()):
			v += 30.0
	p["fam"] = v
	p["famc"] = ucid


static func settle_rate(p: Dictionary) -> float:
	# familiarity gained for a full match; about twelve games from a cold start
	var a = G.age(p)
	var af = 1.25 if a <= 23 else (0.85 if a >= 31 else 1.0)
	return 5.6 * af * (0.85 + p.at[13] / 400.0)


static func settle_matches(p: Dictionary, from_fam := -1.0) -> int:
	var f = float(p.get("fam", 40.0)) if from_fam < 0.0 else from_fam
	return int(ceil(max(0.0, 100.0 - f) / settle_rate(p)))


static func role_fits(rid: String, style: int) -> bool:
	return rid in STYLES[style].roles


static func best_fit_role(p: Dictionary, pos: String, style: int) -> String:
	# the role in this position that suits the style and still suits the player; "" if none does
	var b = ""
	var bs = 0.34
	for rid in G.RL.BY_POS[pos]:
		if role_fits(rid, style):
			var sc = G.RL.suit(p, rid)
			if sc > bs:
				bs = sc
				b = rid
	return b


static func style_fit(c: Dictionary) -> int:
	# one number for how settled the user's XI is in the playstyle
	var s = G.s
	var st = style_of(c)
	var tot = 0.0
	var n = 0
	for i in range(1, 11):
		if c.xi[i] < 0:
			continue
		var p = s.players[c.xi[i]]
		tot += float(p.get("fam", 50.0)) * (1.0 if role_fits(c.roles[i], st) else 0.6)
		n += 1
	return int(round(tot / max(1, n)))


static func avg_fam(c: Dictionary) -> float:
	var tot = 0.0
	var n = 0
	for i in 11:
		if c.xi[i] >= 0:
			tot += float(G.s.players[c.xi[i]].get("fam", 50.0))
			n += 1
	return tot / max(1, n)


# ------------------------------------------------------------------ skills

static func _hash(p: Dictionary, salt: int) -> int:
	return abs((int(p.id) * 2654435761 + salt * 40503) >> 7)


static func skill_margin(p: Dictionary, id: String) -> float:
	# how far above (or below) the requirement he is; -999 when the skill is not for his position
	var sk = SKILLS[id]
	var gk = p.pos == "GK"
	if sk.has("gk") != gk:
		return -999.0
	var m = 99.0
	if gk:
		for r in sk.gk:
			m = min(m, float(p.st[r[0]] - r[1]))
		return m
	if sk.has("lines") and not (G.LINE[p.pos] in sk.lines):
		return -999.0
	for r in sk.req:
		m = min(m, float(p.at[r[0]] - r[1]))
	if sk.has("age") and G.age(p) < sk.age:
		m = min(m, float(G.age(p) - sk.age) * 2.0)
	return m


static func gen_skills(p: Dictionary) -> Array:
	var c = []
	for id in SKILLS:
		var m = skill_margin(p, id)
		if m < 0.0:
			continue
		var sk = SKILLS[id]
		if sk.has("luck") and _hash(p, id.hash() % 97) % int(sk.luck) != 0:
			continue
		c.append([m, id])
	c.sort_custom(func(x, y): return x[0] > y[0])
	var out = []
	for i in min(MAX_GEN, c.size()):
		out.append(c[i][1])
	return out


static func has(p: Dictionary, id: String) -> bool:
	return id in p.get("sk", [])


static func learnable(p: Dictionary) -> Array:
	# skills he could pick up in training: close to the requirement and not owned yet
	var out = []
	var own = p.get("sk", [])
	if own.size() >= MAX_SKILLS:
		return out
	for id in SKILLS:
		if id in own:
			continue
		var m = skill_margin(p, id)
		if m >= -8.0:
			out.append([id, learn_weeks(m)])
	out.sort_custom(func(x, y): return x[1] < y[1])
	return out


static func learn_weeks(margin: float) -> int:
	return 8 + int(max(0.0, -margin)) + (0 if margin >= 0.0 else 2)


static func weekly():
	# Mondays: skills being learned, squad familiarity from training, form arrows
	var s = G.s
	var c = G.uc()
	s.user["fam_init"] = true
	for pid in c.players:
		var p = s.players[pid]
		ensure_fam(p)
		p.fam = min(100.0, float(p.fam) + 1.2)
		var l = p.get("lsk", null)
		if l != null:
			l[1] = int(l[1]) - (2 if c.fac.training >= 5 and G.rng.randf() < 0.35 else 1)
			if l[1] <= 0:
				p.erase("lsk")
				if not (l[0] in p.sk) and p.sk.size() < MAX_SKILLS:
					p.sk.append(l[0])
					G.msg("%s has learned %s" % [G.pname(p), SKILLS[l[0]].n], "%s has finished his work on the training ground and now has the %s skill.\n\n%s" % [G.pfull(p), SKILLS[l[0]].n, SKILLS[l[0]].d])
	roll_arrows()
	totw_build()


static func roll_arrows():
	# weekly form arrow for every player: steady players stay near the middle, streaky ones swing
	var s = G.s
	var rng = G.rng
	for pid in s.players:
		var p = s.players[pid]
		var streaky = form_type(p) == 1
		var base = clamp((float(p.form) - 6.6) * 1.6, -1.2, 1.2)
		var v = base + rng.randfn(0.0, 1.1 if streaky else 0.55)
		p["arw"] = clampi(int(round(v)), -2 if streaky else -1, 2 if streaky else 1)


static func totw_note(sim):
	# remember the week's best performances in the top divisions
	var s = G.s
	var f = sim.fx
	if f.get("fr", false) or f.lg < 0 or f.lg >= s.leagues.size() or s.leagues[f.lg].tier != 1 or s.leagues[f.lg].get("roe", false):
		return
	if not s.has("totw_pool"):
		s["totw_pool"] = []
	for pid in sim.pm:
		var q = sim.pm[pid]
		if q.tin >= 0 and q.r >= 7.4:
			s.totw_pool.append([pid, q.r, q.g, q.a])


static func totw_build():
	# Mondays: the best eleven of the last seven days, one keeper, four defenders, three midfielders, three forwards
	var s = G.s
	var pool = s.get("totw_pool", [])
	s["totw_pool"] = []
	if pool.size() < 30:
		return
	pool.sort_custom(func(x, y): return x[1] > y[1])
	var need = [1, 4, 3, 3]
	var got = [0, 0, 0, 0]
	var xi = []
	var seen = {}
	for e in pool:
		if seen.has(e[0]) or not s.players.has(e[0]):
			continue
		var p = s.players[e[0]]
		var l = G.LINE[p.pos]
		if got[l] >= need[l]:
			continue
		got[l] += 1
		seen[e[0]] = true
		xi.append([e[0], e[1], e[2], e[3], l])
		if xi.size() == 11:
			break
	if xi.size() < 11:
		return
	xi.sort_custom(func(x, y): return x[4] < y[4] if x[4] != y[4] else x[1] > y[1])
	s["totw"] = {"day": s.day, "xi": xi}
	var best = xi[0]
	for e in xi:
		if e[1] > best[1]:
			best = e
	G.news("Team of the Week: %s leads the way with a %.1f rating." % [G.pname(s.players[best[0]]), best[1]])
	var mine = []
	for e in xi:
		var p = s.players[e[0]]
		if p.club == s.user.club:
			mine.append(G.pname(p))
			p.mor = min(100, p.mor + 6)
	if mine.size() > 0:
		G.msg("Team of the Week", "%s %s been named in the Team of the Week. It has given the dressing room a lift.\n\nThe full eleven is under World > Team of the Week." % [" and ".join(mine), "has" if mine.size() == 1 else "have"], "info")


static func form_type(p: Dictionary) -> int:
	# 0 steady, 1 streaky
	return 1 if _hash(p, 5) % 3 == 0 else 0


static func arrow(p: Dictionary) -> int:
	return int(p.get("arw", 0))


static func inj_res(p: Dictionary) -> int:
	# 1 fragile, 2 normal, 3 robust
	var v = _hash(p, 11) % 10 + (1 if p.st[5] >= 80 else 0) - (1 if G.age(p) >= 32 else 0)
	return 1 if v <= 1 else (3 if v >= 8 else 2)


# ------------------------------------------------------------------ link-ups

static func _slot_ok(sl: Dictionary, p: Dictionary, role: String) -> bool:
	if not (role in sl.pos):
		return false
	return fits_slot(sl, p)


static func fits_slot(sl: Dictionary, p: Dictionary) -> bool:
	# has the quality the slot asks for, wherever he is playing
	for id in sl.sk:
		if has(p, id):
			return true
	if p.pos == "GK":
		if not sl.has("gk"):
			return false
		for r in sl.gk:
			if p.st[r[0]] < r[1]:
				return false
		return true
	for r in sl.at:
		if p.at[r[0]] < r[1]:
			return false
	return true


static func _slot_score(sl: Dictionary, p: Dictionary) -> float:
	var t = float(p.ovr)
	if p.pos != "GK":
		for r in sl.at:
			t += p.at[r[0]] * 0.5
	for id in sl.sk:
		if has(p, id):
			t += 6.0
	return t


static func _same_side(ra: String, rb: String) -> bool:
	return ra.begins_with("L") == rb.begins_with("L")


static func link_pair(id: String, xi: Array, roles: Array, taken := {}) -> Array:
	# best pair in this XI for a link-up: [a pid, b pid], or [] when nobody fits
	var L = LINKS[id]
	var pl = G.s.players
	var best = []
	var bs = -1.0
	for i in 11:
		if xi[i] < 0 or not _slot_ok(L.a, pl[xi[i]], roles[i]):
			continue
		for j in 11:
			if j == i or xi[j] < 0 or not _slot_ok(L.b, pl[xi[j]], roles[j]):
				continue
			if L.get("same_side", false) and not _same_side(roles[i], roles[j]):
				continue
			var sc = _slot_score(L.a, pl[xi[i]]) + _slot_score(L.b, pl[xi[j]])
			# spread link-ups across the team rather than stacking them on the same pair
			if taken.has(xi[i]) or taken.has(xi[j]):
				sc -= 40.0
			if sc > bs:
				bs = sc
				best = [xi[i], xi[j]]
	return best


static func pair_key(id: String, a: int, b: int) -> String:
	return "%s:%d:%d" % [id, a, b]


static func pair_level(id: String, a: int, b: int) -> int:
	var n = int(G.s.user.pairs.get(pair_key(id, a, b), 0))
	return 2 if n >= LEVEL_AT[2] else (1 if n >= LEVEL_AT[1] else 0)


static func pair_games(id: String, a: int, b: int) -> int:
	return int(G.s.user.pairs.get(pair_key(id, a, b), 0))


static func active_links(c: Dictionary, xi: Array, roles: Array, user: bool) -> Array:
	# [{id, a, b, lvl, m}] for the link-ups that are switched on with this XI
	var out = []
	var ids = G.s.user.links if user else [ai_link(c)]
	var st = style_of(c)
	var taken = {}
	for id in ids:
		if not LINKS.has(id):
			continue
		var pr = link_pair(id, xi, roles, taken)
		if pr.is_empty():
			continue
		taken[pr[0]] = true
		taken[pr[1]] = true
		var lvl = pair_level(id, pr[0], pr[1]) if user else 1
		out.append({"id": id, "a": pr[0], "b": pr[1], "lvl": lvl, "m": 1.25 if st in LINKS[id].style else 1.0})
	return out


static func slot_pos(c: Dictionary) -> Array:
	var out = []
	for sl in G.slots_of(c):
		out.append(sl[0])
	return out


static func user_links(c: Dictionary) -> Array:
	return active_links(c, c.xi, slot_pos(c), true)


static func user_pair(id: String, c: Dictionary) -> Array:
	return link_pair(id, c.xi, slot_pos(c))


static func slot_fits(sl: Dictionary, c: Dictionary) -> Array:
	# squad players who could fill a link-up slot (right quality and can play one of its positions)
	var out = []
	for pid in c.players:
		var p = G.s.players[pid]
		if not fits_slot(sl, p):
			continue
		var can = p.pos in sl.pos
		for a in p.alt:
			can = can or a in sl.pos
		if can:
			out.append(p)
	out.sort_custom(func(x, y): return x.ovr > y.ovr)
	return out


static func after_match(sim, ui: int):
	# the user's side has played a competitive match: familiarity, pair levels, proficiency
	var s = G.s
	var t = sim.sd[ui]
	var tc = t.tc
	for l in tc.links0:
		if sim.pm.has(l.a) and sim.pm.has(l.b) and sim.pm[l.a].tin == 0 and sim.pm[l.b].tin == 0:
			var k = pair_key(l.id, l.a, l.b)
			var before = pair_level(l.id, l.a, l.b)
			s.user.pairs[k] = int(s.user.pairs.get(k, 0)) + 1
			var now = pair_level(l.id, l.a, l.b)
			if now > before:
				G.msg("%s link-up is now %s" % [LINKS[l.id].n, LEVELS[now]], "%s and %s have played %d matches together in your %s link-up. The understanding between them has reached %s level and the move is more dangerous for it." % [G.pname(s.players[l.a]), G.pname(s.players[l.b]), s.user.pairs[k], LINKS[l.id].n, LEVELS[now]])
	s.user.link_goals = int(s.user.get("link_goals", 0)) + int(tc.link_goals)
	var st = int(tc.style)
	s.user.prof[st] = min(99.0, float(s.user.prof[st]) + 0.25)
	s.user["mp"] = int(s.user.get("mp", 0)) + 1
	s.user["style_streak"] = int(s.user.get("style_streak", 0)) + 1 if int(s.user.get("style_last", -1)) == st else 1
	s.user["style_last"] = st
	for pid in sim.pm:
		var q = sim.pm[pid]
		if q.tin < 0 or not s.players.has(pid):
			continue
		var p = s.players[pid]
		if p.club != s.user.club:
			continue
		ensure_fam(p)
		var mins = (q.tout if q.tout >= 0 else sim.total) - q.tin
		p.fam = min(100.0, float(p.fam) + settle_rate(p) * clamp(mins / 90.0, 0.2, 1.0))


static func on_badge():
	# a new coaching badge: better at every style, and room for one more link-up
	var u = G.s.user
	for i in u.prof.size():
		u.prof[i] = min(99.0, float(u.prof[i]) + 4.0)


# ------------------------------------------------------------------ match engine

static func pins_valid(c: Dictionary):
	for i in 11:
		var pn = c.pins[i]
		if pn != "" and (not PINS.has(pn) or not (c.slots[i][0] in PINS[pn].pos) or c.xi[i] < 0):
			c.pins[i] = ""


static func pin_count(c: Dictionary, kind: String) -> int:
	var n = 0
	for pn in c.pins:
		if pn != "" and PINS[pn].k == kind:
			n += 1
	return n


static func ai_instr(c: Dictionary) -> Dictionary:
	var d = INSTR_DEF.duplicate()
	var st = STYLES[style_of(c)].set
	for k in st:
		if not (k in ["ment", "press", "tempo"]):
			d[k] = st[k]
	return d


static func side_setup(lu: Dictionary, d: Dictionary) -> Dictionary:
	# everything tactical about one side, worked out once at kick-off (and again when the shape changes)
	var c = d.club
	var user = lu.user
	var pl = G.s.players
	var ins = d.instr
	for k in INSTR_DEF:
		if not ins.has(k):
			ins[k] = INSTR_DEF[k]
	var style = int(lu.get("pstyle", style_of(c)))
	var prof = float(G.s.user.prof[style]) if user else ai_prof(c) - (12.0 if style != style_of(c) else 0.0)
	var fam = 80.0
	if user:
		var tot = 0.0
		var n = 0
		for pid in d.xi:
			if pid >= 0:
				tot += float(pl[pid].get("fam", 50.0))
				n += 1
		fam = tot / max(1, n)
	var m = {"att": 1.0, "mid": 1.0, "def": 1.0, "ps": 1.0, "drain": 1.0, "foul": 1.0, "cen": 1.0, "wide": 1.0, "big": 0.0, "long": 0.0, "cross": 0.05, "fba": 1.0, "fbd": 1.0, "opp_big": 0.0, "cb": 0.0}
	match int(ins.eng):
		0:
			m.def *= 1.015
			m.mid *= 0.985
		2:
			m.mid *= 1.015
			m.def *= 0.985
			m.drain *= 1.05
	match int(ins.compact):
		0:
			m.def *= 1.015
			m.att *= 0.99
		2:
			m.mid *= 1.012
			m.def *= 0.985
	if int(ins.mark) == 1:
		m.def *= 1.012
		m.drain *= 1.04
		m.foul *= 1.1
	match int(ins.tackle):
		0:
			m.def *= 0.99
			m.foul *= 0.7
		2:
			m.def *= 1.015
			m.foul *= 1.4
	if ins.trap:
		if int(ins.line) == 0:
			m.def *= 0.99
		else:
			m.def *= 1.02
			m.opp_big += 0.03
	match int(ins.build):
		1:
			m.cen *= 1.03
			m.wide *= 0.97
		2:
			m.wide *= 1.03
			m.cen *= 0.97
	match int(ins.final):
		1:
			m.ps *= 0.94
			m.big += 0.035
			m.long -= 0.08
		2:
			m.ps *= 1.07
			m.long += 0.1
			m.big -= 0.015
		3:
			m.cross += 0.07
	if ins.overlap:
		m.fba = 1.3
		m.fbd = 0.93
	match style:
		0:
			m.mid *= 1.025
			m.ps *= 0.98
			m.drain *= 0.97
		1:
			m.cb += 0.05
			m.drain *= 1.03
		2:
			m.def *= 1.02
			m.mid *= 0.98
			m.cb += 0.06
		3:
			m.wide *= 1.04
			m.cen *= 0.985
			m.cross += 0.04
		4:
			m.mid *= 0.975
			m.att *= 1.025
	# proficiency and familiarity: a few percent either way
	var q = clamp((prof - 50.0) / 50.0 * 0.035 + (fam - 60.0) / 100.0 * 0.04, -0.06, 0.055)
	m.att *= 1.0 + q
	m.mid *= 1.0 + q
	m.def *= 1.0 + q
	var pins = lu.get("pins", ["", "", "", "", "", "", "", "", "", "", ""]).duplicate()
	var tc = {"m": m, "style": style, "prof": prof, "fam": fam, "user": user, "pins": pins, "tm_pid": int(lu.get("tm_pid", -1)), "tm_target": -1, "tm_marker": -1,
		"links": [], "links0": [], "link_goals": 0, "cross_type": int(ins.cross), "waste": int(ins.waste)}
	return tc


static func refresh_side(t: Dictionary, opp):
	# after the XI or shape changes: which link-ups are live, who is being marked, squad-wide skill effects
	var tc = t.tc
	var pl = G.s.players
	tc.links = active_links(t.club, t.xi, t.roles, tc.user)
	if tc.links0.is_empty() and tc.get("first", true):
		tc.links0 = tc.links.duplicate(true)
		tc["first"] = false
	tc.tm_target = -1
	tc.tm_marker = -1
	for k in 11:
		if tc.pins[k] == "tm" and t.xi[k] >= 0 and opp != null:
			tc.tm_marker = t.xi[k]
			var tg = tc.tm_pid
			if tg < 0 or not (tg in opp.xi):
				var bs = -1.0
				for j in range(1, 11):
					var op = opp.xi[j]
					if op >= 0 and opp.roles[j] in ["ST", "LW", "RW", "CAM"] and pl[op].ovr > bs:
						bs = pl[op].ovr
						tg = op
			tc.tm_target = tg
	var sx = {"def": 1.0, "mid": 1.0, "cross": 0.0, "cap": 1.0}
	var blk = 0
	for k in 11:
		var pid = t.xi[k]
		if pid < 0:
			continue
		var p = pl[pid]
		if has(p, "blk") and blk < 2:
			blk += 1
			sx.def *= 1.004
		if has(p, "lt"):
			sx.cross = 0.015
		if k == 0 and has(p, "gkd"):
			sx.mid *= 1.004
	if t.capt >= 0 and t.capt in t.xi and has(pl[t.capt], "cap"):
		sx.cap = 1.006
	tc["sx"] = sx


static func pl_mods(t: Dictionary, k: int, p: Dictionary, q: Dictionary, minute: int, opp) -> Array:
	# [effective rating, attack weight, midfield weight, defence weight, shooting share, assist share] multipliers for one player
	var tc = t.tc
	var role = t.roles[k]
	var rid = t.rids[k]
	var e = 1.0 + 0.012 * int(p.get("arw", 0))
	var aw = 1.0
	var mw = 1.0
	var dw = 1.0
	var x0 = 1.0
	var x1 = 1.0
	# style fit: a bonus for a suitable role that grows with familiarity, never a penalty
	if role_fits(rid, tc.style):
		e *= 1.0 + 0.02 * (float(p.get("fam", 50.0)) if tc.user else 80.0) / 100.0
	# weak foot on the wrong flank
	if int(p.get("wf", 3)) <= 2 and role in ["LB", "LM", "LW", "RB", "RM", "RW"] and not (rid in ["if", "ifb", "wp"]):
		if role.begins_with("L") != (str(p.foot) == "L"):
			e *= 0.985
	var sk = p.get("sk", [])
	if sk.size() > 0:
		if "thr" in sk:
			x1 *= 1.12
		if "otp" in sk:
			x1 *= 1.06
			mw *= 1.03
		if "lp" in sk:
			x1 *= 1.03
		if "drb" in sk:
			aw *= 1.04
		if "int" in sk:
			dw *= 1.05
		if "mm" in sk:
			dw *= 1.02
		if "aer" in sk:
			dw *= 1.03
		if "tb" in sk and G.LINE[role] == 3:
			dw *= 1.5
			mw *= 1.05
		if "spd" in sk and tc.m.cb > 0.0:
			x0 *= 1.04
		if "sub" in sk and q.tin >= 55:
			e *= 1.06
			x0 *= 1.15
		if "fs" in sk and opp != null and (t.goals < opp.goals or minute >= 75):
			e *= 1.02
	match tc.pins[k]:
		"ct":
			aw *= 1.12
			mw *= 0.6
			dw *= 0.6
			x0 *= 1.15
		"afb":
			aw *= 1.5
			dw *= 0.85
			x1 *= 1.15
		"dfb":
			aw *= 0.5
			dw *= 1.1
		"ht":
			aw *= 1.08
			x1 *= 1.15
			x0 *= 0.9
		"anc":
			dw *= 1.2
			aw *= 0.5
			mw *= 0.95
		"dl":
			dw *= 1.08
			mw *= 0.8
		"tm":
			if tc.tm_target >= 0:
				aw *= 0.75
				mw *= 0.75
	if role in ["LB", "RB"] and tc.pins[k] == "":
		aw *= tc.m.fba
		dw *= tc.m.fbd
	# marked out of the game by their man-marker
	if opp != null and opp.has("tc") and opp.tc.tm_target == p.id:
		var f = 0.62 if (opp.tc.tm_marker >= 0 and has(G.s.players[opp.tc.tm_marker], "mm")) else 0.72
		x0 *= f
		x1 *= f
		aw *= 0.9
	for l in tc.links:
		var lm = [1.10, 1.16, 1.22][l.lvl]
		if l.a == p.id:
			x1 *= 1.0 + (lm - 1.0) * l.m
		elif l.b == p.id:
			x0 *= 1.0 + (lm - 1.0) * 0.5 * l.m
	return [e, aw, mw, dw, x0, x1]


# ------------------------------------------------------------------ match-ups
# How one side's plan fares against the other's. Every rule looks at both sets of instructions and, where it
# matters, at the players who have to carry them out. MU scales the whole system (tuned with dev/tactest.gd).

const MU = 0.68
# the style an AI manager switches to when he sets up to stop a given style
const COUNTER_STYLE = [2, 2, 3, 0, 0]


static func side_view(lu: Dictionary) -> Dictionary:
	# a line-up as the match-up rules want it (the engine's own side dictionaries already have this shape)
	var roles = []
	for sl in lu.slots:
		roles.append(sl[0])
	return {"xi": lu.xi, "roles": roles, "instr": lu.instr, "press": lu.press, "tempo": lu.tempo, "ment": lu.ment}


static func traits(t: Dictionary) -> Dictionary:
	# what the eleven on the pitch are like, by unit
	var pl = G.s.players
	var acc = {"pa": [0.0, 0], "pd": [0.0, 0], "pass": [0.0, 0], "press": [0.0, 0], "aa": [0.0, 0], "ad": [0.0, 0]}
	for k in range(1, 11):
		var pid = t.xi[k]
		if pid < 0:
			continue
		var p = pl[pid]
		var role = t.roles[k]
		var ln = G.LINE[role]
		if ln == 3 or role in ["CAM", "LM", "RM"]:
			acc.pa[0] += p.st[0]
			acc.pa[1] += 1
		if ln == 1:
			acc.pd[0] += p.st[0]
			acc.pd[1] += 1
			acc.ad[0] += p.at[2] if role == "CB" else p.at[2] * 0.5 + 30.0
			acc.ad[1] += 1
		if ln <= 2:
			acc["pass"][0] += p.st[2]
			acc["pass"][1] += 1
		if ln >= 2:
			acc.press[0] += (p.st[5] + p.st[4] * 0.5 + p.st[0] * 0.5) / 2.0
			acc.press[1] += 1
		if role == "ST":
			acc.aa[0] += p.at[2]
			acc.aa[1] += 1
	var out = {}
	for key in acc:
		out[key] = acc[key][0] / acc[key][1] if acc[key][1] > 0 else 65.0
	return out


static func matchup(a: Dictionary, b: Dictionary) -> Dictionary:
	# -> multipliers for side a against side b, and the reasons. In a note, {A} is a's "Your/Their" and {b} is b's "their/your".
	var ia = a.instr
	var ib = b.instr
	var ta = traits(a)
	var tb = traits(b)
	var m = {"att": 0.0, "mid": 0.0, "def": 0.0, "ps": 0.0}
	var notes = []
	var add = func(key: String, v: float, text: String):
		m[key] += v * MU
		if abs(v) >= 0.012 and text != "":
			notes.append([v, text])
	var pace = clamp((tb.pa - ta.pd) / 10.0, -1.0, 1.0)          # their runners against our back line
	var a_line = int(ia.get("line", 1))
	var b_line = int(ib.get("line", 1))
	var a_pass = int(ia.get("pass", 1))
	var b_pass = int(ib.get("pass", 1))
	var a_counter = bool(ia.get("counter", false))
	var b_counter = bool(ib.get("counter", false))
	# 1. a high line against a side that breaks or goes long
	if a_line == 2:
		if b_counter:
			add.call("def", -(0.035 + 0.045 * clamp(pace + 0.4, 0.0, 1.0)), "{A} high line leaves space behind for {b} counter-attacks")
		elif b_pass == 2:
			add.call("def", -(0.02 + 0.025 * clamp(pace + 0.4, 0.0, 1.0)), "{A} high line can be turned by {b} long passing")
		elif pace > 0.25:
			add.call("def", -0.03 * pace, "{A} high line is up against quicker forwards")
		elif pace < -0.25:
			add.call("mid", 0.02 * -pace, "{A} high line squeezes forwards who cannot run in behind")
	# 2. a deep line
	if a_line == 0:
		if b_pass == 0:
			add.call("def", 0.038, "{A} deep block gives {b} short passing nowhere to go")
		var air = clamp((tb.aa - ta.ad) / 10.0, -1.0, 1.0)
		if int(ib.get("final", 0)) == 3 or int(ib.get("build", 0)) == 2:
			add.call("def", -(0.02 + 0.035 * max(0.0, air)) if air > -0.2 else 0.02, "{A} deep block invites {b} crosses into the box" if air > -0.2 else "{A} centre-backs win everything {b} put into the box")
		if int(ib.get("final", 0)) == 2:
			add.call("def", -0.02, "{A} deep block gives {b} shooters time from distance")
	# 3. pressing high against their way of playing out
	if int(a.press) == 2:
		if b_pass == 2:
			add.call("mid", -0.03, "{A} press is bypassed by {b} long passing")
			add.call("def", -0.015, "")
		else:
			var q = clamp((ta.press - tb["pass"]) / 8.0 + 0.35, -1.0, 1.0)
			var w = 1.0 if b_pass == 0 else 0.55
			if q >= 0.0:
				add.call("mid", (0.02 + 0.045 * q) * w, "{A} press wins the ball from defenders who are not comfortable on it")
			else:
				add.call("mid", 0.035 * q * w, "{A} press is played through by better passers")
	# 4. breaking at speed
	if a_counter:
		if b_line == 2 or int(b.ment) >= 3:
			var mypace = clamp((ta.pa - tb.pd) / 10.0, -1.0, 1.0)
			add.call("ps", 0.06 + 0.06 * max(0.0, mypace), "{A} counter-attacks have space to run into")
		elif b_line == 0:
			add.call("ps", -0.08, "{A} counter-attacks find no space behind a deep defence")
	# 5. where the attacks go against how the defence is set
	var a_wide = int(ia.get("build", 0)) == 2 or int(ia.get("width", 1)) == 2
	var a_centre = int(ia.get("build", 0)) == 1 or int(ia.get("width", 1)) == 0
	var b_compact = int(ib.get("compact", 1))
	if a_wide and b_compact == 0:
		add.call("att", 0.045, "{A} wide play stretches a narrow defence")
	elif a_wide and b_compact == 2:
		add.call("att", -0.025, "{A} wide play runs into a defence that is already spread out")
	elif a_centre and b_compact == 0:
		add.call("att", -0.045, "{A} play through the middle runs into a packed centre")
	elif a_centre and b_compact == 2:
		add.call("att", 0.035, "{A} play through the middle finds gaps in a stretched defence")
	# 6. keeping the ball against a side that neither presses high nor sits deep
	if a_pass == 0 and int(a.tempo) <= 1 and int(b.press) <= 1 and b_line >= 1:
		add.call("mid", 0.045, "{A} possession game makes them chase the ball")
	# 7. going long
	if a_pass == 2:
		if b_pass == 0 and int(b.tempo) <= 1:
			add.call("mid", -0.035, "{A} long balls give possession straight back to a side that keeps it")
		if b_line == 0:
			var air2 = clamp((ta.aa - tb.ad) / 10.0, -1.0, 1.0)
			add.call("att", 0.04 * air2, "{A} target man %s in the air against a deep defence" % ("wins" if air2 > 0 else "loses"))
	notes.sort_custom(func(x, y): return abs(x[0]) > abs(y[0]))
	return {"att": 1.0 + m.att, "mid": 1.0 + m.mid, "def": 1.0 + m.def, "ps": 1.0 + m.ps, "notes": notes, "net": m.att + m.mid + m.def + m.ps * 0.5}


static func ai_plan(c: Dictionary, opp: Dictionary) -> int:
	# the playstyle an AI manager uses in this match. Against the user he may set up to stop the style the user
	# has been relying on: more likely the longer the user has stuck with it, and the better the manager.
	var native = style_of(c)
	var u = G.s.user
	if opp.id != u.club:
		return native
	var streak = int(u.get("style_streak", 0))
	if streak < 3:
		return native
	var chance = clamp(0.1 + 0.07 * (streak - 2) + (c.rep - 60.0) * 0.004, 0.0, 0.65)
	var roll = float((G.s.season * 131 + c.id * 977 + int(u.get("mp", 0)) * 37) % 1000) / 1000.0
	if roll < chance:
		return COUNTER_STYLE[style_of(opp)]
	return native


static func plan_instr(style: int) -> Dictionary:
	var d = INSTR_DEF.duplicate()
	var st = STYLES[style].set
	for k in st:
		if not (k in ["ment", "press", "tempo"]):
			d[k] = st[k]
	return d


static func link_att(tc: Dictionary) -> float:
	var f = 1.0
	for l in tc.links:
		f *= 1.0 + [0.008, 0.013, 0.019][l.lvl] * l.m
	return f


static func link_for(tc: Dictionary, scorer: int, asst: int):
	for l in tc.links:
		if l.b == scorer and l.a == asst:
			return l
	return null


static func link_partner(tc: Dictionary, scorer: int) -> int:
	for l in tc.links:
		if l.b == scorer:
			return l.a
	return -1


static func shot_mult(p: Dictionary, kind: String, header: bool) -> float:
	var sk = p.get("sk", [])
	if sk.is_empty():
		return 1.0
	var f = 1.0
	match kind:
		"big", "box":
			if "fts" in sk:
				f *= 1.06
			if kind == "box" and "oc" in sk:
				f *= 1.05
		"long":
			if "lr" in sk:
				f *= 1.3
			if "oc" in sk:
				f *= 1.05
		"fk":
			if "fk" in sk:
				f *= 1.25
		"corner", "cross":
			if header and "hd" in sk:
				f *= 1.12
			if not header and "acr" in sk:
				f *= 1.12
	return f


# ------------------------------------------------------------------ text helpers

static func skill_names(p: Dictionary) -> Array:
	var out = []
	for id in p.get("sk", []):
		if SKILLS.has(id):
			out.append(SKILLS[id].n)
	return out


static func slot_need(sl: Dictionary) -> String:
	var parts = []
	for id in sl.sk:
		parts.append(SKILLS[id].n)
	var at = []
	for r in sl.at:
		at.append("%s %d+" % [G.RL.ATTR[r[0]], r[1]])
	var t = " or ".join(parts)
	if at.size() > 0:
		t += (" or " if t != "" else "") + " and ".join(at)
	return t


static func fit_text(p: Dictionary) -> String:
	# for scout reports and the transfer screens: how a target would fit the user's style
	var c = G.uc()
	var st = style_of(c)
	var rid = best_fit_role(p, p.pos, st)
	var start = 34.0 + (p.id % 11)
	if p.club >= 0 and style_of(G.s.clubs[p.club]) == st:
		start += 30.0
	var n = settle_matches(p, start)
	if rid == "":
		return "No role of his suits %s. He would play at his normal level, with no style bonus." % STYLES[st].n
	return "Would fit %s as a %s. About %d matches to settle." % [STYLES[st].n, G.RL.ROLES[rid].n, n]


static func arrow_icon(v: int) -> String:
	return ["arrow-down", "trending-down", "arrow-right", "trending-up", "arrow-up"][clampi(v, -2, 2) + 2]


static func arrow_text(v: int) -> String:
	return ["Badly out of form", "Off the pace", "Normal", "In good form", "On fire"][clampi(v, -2, 2) + 2]


static func arrow_col(v: int) -> Color:
	return [Color("ff5d6c"), Color("f1a13a"), Color("c9d3de"), Color("9bdc5a"), Color("32d17e")][clampi(v, -2, 2) + 2]


static func report(uid: int, oid: int) -> Dictionary:
	# how the user's current plan meets this opponent: verdict, reasons for and against, their danger man and link-up
	var s = G.s
	var opp = s.clubs[oid]
	var olu = G.lineup(oid, uid)
	var ulu = G.lineup(uid, oid)
	var mine = matchup(side_view(ulu), side_view(olu))
	var theirs = matchup(side_view(olu), side_view(ulu))
	var good = []
	var bad = []
	for nt in mine.notes:
		var tx = str(nt[1]).replace("{A}", "Your").replace("{b}", "their")
		if nt[0] > 0:
			good.append([abs(nt[0]), tx])
		else:
			bad.append([abs(nt[0]), tx])
	for nt in theirs.notes:
		var tx2 = str(nt[1]).replace("{A}", "Their").replace("{b}", "your")
		if nt[0] > 0:
			bad.append([abs(nt[0]), tx2])
		else:
			good.append([abs(nt[0]), tx2])
	good.sort_custom(func(x, y): return x[0] > y[0])
	bad.sort_custom(func(x, y): return x[0] > y[0])
	var net = mine.net - theirs.net
	var verdict = "Even" if abs(net) < 0.03 else (("Strongly " if abs(net) >= 0.1 else "") + ("in your favour" if net > 0 else "against you")).capitalize()
	var col = UI.MUTED if abs(net) < 0.03 else (UI.GREEN if net > 0 else UI.RED)
	var ps = int(olu.get("pstyle", style_of(opp)))
	var opos = []
	for sl in olu.slots:
		opos.append(sl[0])
	var olk = ai_link(opp)
	var opr = link_pair(olk, olu.xi, opos)
	var stars = []
	for pid in olu.xi:
		if pid >= 0:
			stars.append(s.players[pid])
	stars.sort_custom(func(x, y): return x.ovr + x.form > y.ovr + y.form)
	return {"net": net, "verdict": verdict, "col": col, "good": good, "bad": bad, "style": STYLES[ps].n, "changed": ps != style_of(opp), "usual": STYLES[style_of(opp)].n,
		"link": LINKS[olk].n if LINKS.has(olk) else "", "pair": opr, "stars": stars, "olu": olu, "ulu": ulu}


# ------------------------------------------------------------------ saved plans, team sheets, rotation
const ROT_COND = 75


static func plans_init(c: Dictionary):
	if not c.has("plans"):
		c["plans"] = []
		for pr in c.get("presets", []):
			if pr != null:
				c.plans.append({"n": "%s %s" % [pr.formation, STYLES[int(pr.get("pstyle", 0))].s], "pr": pr})
		c["plan"] = -1
	if not c.has("sheets") or c.sheets.size() != 3:
		c["sheets"] = [null, null, null]
	if not c.has("trig"):
		c["trig"] = {}


static func plan_use(c: Dictionary, idx: int):
	if idx < 0 or idx >= c.plans.size():
		return
	G.apply_preset(c, c.plans[idx].pr)
	c["plan"] = idx
	if G.live != null:
		G.live_sync()


static func plan_net(c: Dictionary, pr: Dictionary, oid: int) -> float:
	# how a saved plan would meet this opponent, without changing anything for good
	var keep = G.make_preset(c)
	G.apply_preset(c, pr)
	var olu = G.lineup(oid, c.id)
	var ulu = G.lineup(c.id, oid)
	var net = matchup(side_view(ulu), side_view(olu)).net - matchup(side_view(olu), side_view(ulu)).net
	G.apply_preset(c, keep)
	return net


static func sheet_use(c: Dictionary, idx: int):
	var sh = c.sheets[idx]
	if sh == null:
		return
	var xi = []
	for pid in sh.xi:
		xi.append(int(pid) if int(pid) in c.players else -1)
	c.xi = xi
	c.bench = sh.bench.filter(func(pid): return pid in c.players and not (pid in xi))
	G.fix_lineup()
	for i in 11:
		if c.xi[i] >= 0:
			c.roles[i] = G.RL.valid(c.roles[i], c.slots[i][0])


static func auto_rotate(c: Dictionary, force := false) -> Array:
	# rest tired starters for the best fit player in the same position, if he is close enough in quality
	var out = []
	if not force and not c.get("autorot", false):
		return out
	var s = G.s
	var line = int(c.get("rot_at", ROT_COND))
	var slots = G.slots_of(c)
	for k in 11:
		var pid = int(c.xi[k])
		if pid < 0:
			continue
		var p = s.players[pid]
		if p.cond >= line:
			continue
		var best = null
		var bs = 0.0
		for q in c.players:
			var r = s.players[q]
			if q in c.xi or not G.available(r) or r.get("youth", false) or r.cond < line + 8:
				continue
			if (r.pos == "GK") != (slots[k][0] == "GK"):
				continue
			var sc = r.ovr * G.fit(r, slots[k][0])
			if sc > bs:
				bs = sc
				best = r
		if best != null and bs >= p.ovr * G.fit(p, slots[k][0]) - 7.0:
			c.xi[k] = best.id
			c.bench.erase(best.id)
			if not (pid in c.bench) and c.bench.size() < 7:
				c.bench.append(pid)
			out.append("%s rested for %s" % [G.pname(p), G.pname(best)])
	return out

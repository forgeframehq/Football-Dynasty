extends RefCounted
# Detailed attributes, player roles and pitch zones.

const ATTR = ["Finishing", "Long Shots", "Heading", "Crossing", "Passing", "Vision", "Dribbling", "Pace", "Stamina", "Strength", "Tackling", "Marking", "Off the Ball", "Composure", "Aggression", "Long Passing", "Free Kicks", "Penalties"]
const ATTR_GROUPS = [["Attacking", [0, 1, 2, 12]], ["Technical", [4, 5, 6, 3, 15]], ["Defending", [10, 11, 14]], ["Physical & mental", [7, 8, 9, 13]], ["Set pieces", [16, 17]]]

# n: name, k: key attributes, m: [attack, midfield, defence] weight multipliers, sh / as: shooting and assist share, d: description
const ROLES = {
	"gk": {"n": "Goalkeeper", "k": [], "m": [1, 1, 1], "sh": 1.0, "as": 1.0, "d": "Stays on his line and keeps it simple."},
	"sk": {"n": "Sweeper Keeper", "k": [4, 7, 13], "m": [1, 1, 1], "sh": 1.0, "as": 1.0, "d": "Sweeps behind a high line and starts attacks."},
	"cd": {"n": "Central Defender", "k": [10, 11, 9, 2], "m": [1, 1, 1], "sh": 1.0, "as": 1.0, "d": "Defends first, plays it safe."},
	"bpd": {"n": "Ball-Playing Defender", "k": [4, 15, 13, 10, 11], "m": [1.0, 1.6, 0.96], "sh": 1.0, "as": 1.3, "d": "Steps out and builds play from the back."},
	"stp": {"n": "Stopper", "k": [10, 14, 9], "m": [1.0, 0.8, 1.05], "sh": 1.0, "as": 0.8, "d": "Steps up aggressively to win the ball early."},
	"fb": {"n": "Full-Back", "k": [10, 11, 7, 8], "m": [1, 1, 1], "sh": 1.0, "as": 1.0, "d": "Balanced defending and support."},
	"wb": {"n": "Wing-Back", "k": [3, 7, 8, 6], "m": [1.7, 1.2, 0.88], "sh": 1.1, "as": 1.4, "d": "Bombs forward to provide width and crosses."},
	"ifb": {"n": "Inverted Full-Back", "k": [4, 5, 13, 10], "m": [0.6, 1.8, 0.95], "sh": 0.8, "as": 1.1, "d": "Tucks into midfield to help control the ball."},
	"dm": {"n": "Defensive Midfielder", "k": [10, 11, 4, 8], "m": [1, 1, 1], "sh": 1.0, "as": 1.0, "d": "Screens the defence and keeps play moving."},
	"anc": {"n": "Anchor", "k": [10, 11, 9], "m": [0.5, 0.9, 1.15], "sh": 0.6, "as": 0.7, "d": "Sits in front of the back line and never leaves."},
	"dlp": {"n": "Deep Playmaker", "k": [4, 5, 15, 13], "m": [1.0, 1.15, 0.92], "sh": 0.8, "as": 1.3, "d": "Dictates the tempo from deep."},
	"bwm": {"n": "Ball Winner", "k": [10, 14, 8], "m": [0.8, 1.0, 1.08], "sh": 0.8, "as": 0.8, "d": "Hunts the ball and breaks up play."},
	"cm": {"n": "Central Midfielder", "k": [4, 8, 10, 5], "m": [1, 1, 1], "sh": 1.0, "as": 1.0, "d": "A bit of everything in the middle."},
	"b2b": {"n": "Box-to-Box", "k": [8, 4, 10, 12], "m": [1.25, 0.95, 1.1], "sh": 1.2, "as": 1.0, "d": "Covers every blade of grass, arrives late in the box."},
	"ply": {"n": "Playmaker", "k": [4, 5, 13, 6], "m": [1.05, 1.12, 0.8], "sh": 0.9, "as": 1.35, "d": "The creative hub - everything goes through him."},
	"am": {"n": "Attacking Midfielder", "k": [4, 5, 6, 12], "m": [1, 1, 1], "sh": 1.0, "as": 1.0, "d": "Links midfield and attack."},
	"ap": {"n": "Advanced Playmaker", "k": [4, 5, 13, 6], "m": [0.92, 1.15, 1.0], "sh": 0.8, "as": 1.4, "d": "Finds pockets of space and plays the final ball."},
	"ss": {"n": "Shadow Striker", "k": [0, 12, 7, 13], "m": [1.2, 0.8, 1.0], "sh": 1.4, "as": 0.8, "d": "Runs beyond the striker to score."},
	"wm": {"n": "Wide Midfielder", "k": [3, 8, 4, 7], "m": [1, 1, 1], "sh": 1.0, "as": 1.0, "d": "Works up and down the flank."},
	"wf": {"n": "Wide Forward", "k": [7, 6, 0, 3], "m": [1, 1, 1], "sh": 1.0, "as": 1.0, "d": "A balanced threat from the flank."},
	"wng": {"n": "Winger", "k": [7, 6, 3], "m": [1.1, 0.92, 0.9], "sh": 0.85, "as": 1.3, "d": "Hugs the touchline, beats his man and crosses."},
	"if": {"n": "Inside Forward", "k": [0, 6, 7, 1], "m": [1.12, 0.9, 0.9], "sh": 1.35, "as": 0.85, "d": "Cuts inside to shoot."},
	"wp": {"n": "Wide Playmaker", "k": [4, 5, 6], "m": [0.95, 1.3, 0.9], "sh": 0.8, "as": 1.25, "d": "Drifts inside to create from wide areas."},
	"st": {"n": "Striker", "k": [0, 12, 7, 13], "m": [1, 1, 1], "sh": 1.0, "as": 1.0, "d": "Leads the line."},
	"poa": {"n": "Poacher", "k": [0, 12, 13], "m": [1.06, 0.5, 0.5], "sh": 1.3, "as": 0.55, "d": "Lives on the last defender's shoulder. Only cares about goals."},
	"tm": {"n": "Target Man", "k": [2, 9, 0], "m": [1.0, 1.3, 1.0], "sh": 0.95, "as": 1.3, "d": "Holds the ball up and wins everything in the air."},
	"f9": {"n": "False 9", "k": [4, 5, 6, 0], "m": [0.9, 2.2, 1.0], "sh": 0.8, "as": 1.45, "d": "Drops deep to overload midfield and create."},
	"pf": {"n": "Pressing Forward", "k": [8, 14, 7, 0], "m": [0.97, 1.3, 3.0], "sh": 0.95, "as": 1.0, "d": "First line of defence - never stops running."},
}
const BY_POS = {"GK": ["gk", "sk"], "CB": ["cd", "bpd", "stp"], "LB": ["fb", "wb", "ifb"], "RB": ["fb", "wb", "ifb"], "CDM": ["dm", "anc", "dlp", "bwm"], "CM": ["cm", "b2b", "ply", "bwm"],
	"CAM": ["am", "ap", "ss"], "LM": ["wm", "wng", "if", "wp"], "RM": ["wm", "wng", "if", "wp"], "LW": ["wf", "wng", "if", "wp"], "RW": ["wf", "wng", "if", "wp"], "ST": ["st", "poa", "tm", "f9", "pf"]}
const WIDE = {"LB": 1, "RB": 1, "LM": 1, "RM": 1, "LW": 1, "RW": 1}


static func score(p: Dictionary, rid: String) -> float:
	var k = ROLES[rid].k
	if k.size() == 0 or p.pos == "GK":
		return float(p.ovr)
	var t = 0.0
	for i in k:
		t += p.at[i]
	return t / k.size()


static func suit(p: Dictionary, rid: String) -> float:
	if ROLES[rid].k.size() == 0:
		return 0.7
	if p.pos == "GK":
		return 0.7 if rid == "sk" and p.st[2] >= p.ovr - 6 else (0.4 if rid == "sk" else 0.7)
	return clamp((score(p, rid) - (p.ovr - 12.0)) / 15.0, 0.0, 1.0)


static func stars(p: Dictionary, rid: String) -> int:
	return 1 + int(round(suit(p, rid) * 4.0))


static func best(p: Dictionary, pos: String) -> String:
	var opts = BY_POS[pos]
	var b = opts[0]
	var bs = suit(p, b) + 0.08
	for i in range(1, opts.size()):
		var sc = suit(p, opts[i])
		if sc > bs:
			bs = sc
			b = opts[i]
	return b


static func valid(rid: String, pos: String) -> String:
	return rid if rid in BY_POS[pos] else BY_POS[pos][0]


static func zone_pos(x: float, y: float) -> String:
	# position implied by where a player stands (x: left to right, y: own goal to opposition goal)
	if y < 0.33:
		return "LB" if x < 0.22 else ("RB" if x > 0.78 else "CB")
	if y < 0.47:
		return "LB" if x < 0.18 else ("RB" if x > 0.82 else "CDM")
	if y < 0.62:
		return "LM" if x < 0.24 else ("RM" if x > 0.76 else "CM")
	if y < 0.76:
		return "LM" if x < 0.2 else ("RM" if x > 0.8 else "CAM")
	return "LW" if x < 0.3 else ("RW" if x > 0.7 else "ST")


static func derive_attrs(pos: String, ovr: int, st: Array, rng: RandomNumberGenerator) -> Array:
	# detailed attributes for generated players from the six headline stats
	var a = []
	if pos == "GK":
		for i in 18:
			a.append(clampi(25 + rng.randi_range(-8, 8), 10, 60))
		a[4] = clampi(st[2] - 8, 20, 90)
		a[13] = clampi(ovr - 4, 20, 95)
		return a
	var src = [st[1] + 1, st[1] - 3, (st[5] + st[4]) / 2 if pos in ["CB", "ST", "CDM"] else st[5] - 14, st[2] - 2 if WIDE.has(pos) else st[2] - 10, st[2] + 2, st[2] - 1, st[3], st[0], st[5] + 2, st[5], st[4],
		st[4] - 1, st[1] if pos in ["ST", "LW", "RW", "CAM"] else st[1] - 6, ovr - 4, st[5] - 6, st[2] - 3, st[2] - 12, st[1] - 6]
	for v in src:
		a.append(clampi(int(v) + rng.randi_range(-4, 4), 15, 97))
	return a

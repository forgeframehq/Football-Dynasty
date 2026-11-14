extends RefCounted
# Match commentary. The engine supplies what happened; this adds how it came about (a build-up line that fits
# the kind of chance), some variety in the telling, and a closing remark that knows the state of the match:
# an equaliser, a late winner, a hat-trick, an upset on the cards, a tactical plan paying off or being punished.

const BUILD = {
	"cross": ["{a} gets to the byline and stands one up.", "{a} has time out wide and whips it in.", "Early ball in from {a}.", "{a} beats his man and delivers."],
	"cross0": ["The ball is worked wide and swung in.", "A deep cross from the flank."],
	"corner": ["{a} swings the corner in.", "Corner to {t}. {a} takes it long.", "{a} curls the corner towards the penalty spot."],
	"corner0": ["The corner is swung in.", "Corner to {t}, played into the mixer."],
	"big": ["{a} slides it through and {s} is in behind!", "A lovely ball from {a} splits them open.", "{a} spots the run and plays it first time.", "{o} are caught square. {a} threads it through."],
	"big0": ["{s} is clean through!", "A loose ball breaks kindly and {s} is away."],
	"box": ["{t} work it neatly around the area and {a} lays it off.", "{a} cuts it back from the edge of the box.", "Patient from {t}. {a} finds a pocket of space and feeds {s}.", "One-two on the edge of the area, {a} with the return."],
	"box0": ["{s} picks it up on the edge of the box.", "The ball drops to {s} in the area."],
	"long": ["{s} has room thirty yards out and decides to hit it.", "Nobody closes {s} down, so he lets fly.", "{a} rolls it into {s}'s path, a long way out."],
	"long0": ["{s} tries his luck from distance.", "{s} has a sight of goal from range."],
	"fk": ["{s} stands over the free kick. The wall is set.", "Free kick in a dangerous spot. {s} fancies it."],
	"pen": ["{s} puts the ball on the spot. A long wait for the whistle.", "Penalty to {t}. {s} against the keeper."],
}
const GOAL_ALT = ["GOAL! {s} scores for {t}!", "GOAL! {s} tucks it away and {t} have it!", "GOAL! In it goes! {s} for {t}!", "GOAL! {s} sends the keeper the wrong way. {t} score!", "GOAL! Low and hard from {s}, and it is in for {t}!"]
const SAVE_ALT = ["{s} hits it well, and {g} gets down to push it away.", "{s} shoots! {g} is equal to it.", "Good hands from {g} to hold {s}'s effort.", "{s} goes for the corner. {g} reads it and saves."]
const MISS_ALT = ["{s} leans back and it sails over.", "{s} pulls it across the face of goal and wide.", "{s} gets it all wrong. Goal kick.", "Just the wrong side of the post from {s}."]
const FILL_GEN = ["{t} are knocking it around patiently.", "{t} probing for an opening.", "A good spell of possession for {t}.", "{t} win it back in midfield.", "{t} switch the play, looking for space.", "Throw-in to {t}, deep in the other half.", "{t} keep the ball moving. No way through yet."]


static func _f(line: String, v: Dictionary) -> String:
	for k in v:
		line = line.replace("{" + k + "}", str(v[k]))
	return line


static func _pick(sim, arr: Array) -> String:
	return arr[sim.rng.randi() % arr.size()]


static func shot(sim, type: String, side: int, base: String, pid: int, kind: String, asst: int, header: bool, blocked: bool) -> String:
	var at = sim.sd[side]
	var df = sim.sd[1 - side]
	var gk = df.xi[0]
	var v = {"s": sim.nm(pid), "a": sim.nm(asst) if asst >= 0 else "", "t": at.club.name, "o": df.club.name, "g": sim.nm(gk) if gk >= 0 else "the keeper"}
	var out = ""
	# how it came about
	var key = kind if (asst >= 0 or kind in ["fk", "pen"]) else kind + "0"
	if BUILD.has(key) and sim.rng.randf() < 0.8:
		out = _f(_pick(sim, BUILD[key]), v) + " "
	# what happened: the engine's own line most of the time, a plainer alternative otherwise
	var body = base
	if not blocked and kind in ["box", "big"] and sim.rng.randf() < 0.4:
		if type == "goal" and not base.contains("link-up"):
			body = _f(_pick(sim, GOAL_ALT), v)
			if asst >= 0:
				body += " Assist: %s." % v.a
		elif type == "save":
			body = _f(_pick(sim, SAVE_ALT), v)
		elif type == "miss":
			body = _f(_pick(sim, MISS_ALT), v)
	out += body
	# what it means
	var tail = ""
	var m = sim.minute
	if type == "goal":
		var mine = at.goals
		var theirs = df.goals
		var n = 0
		for g in at.scorers:
			if g.pid == pid:
				n += 1
		if n == 3:
			tail = "A hat-trick! He takes the match ball home."
		elif n == 2:
			tail = "That is two for him today."
		elif mine == theirs:
			tail = "%s are level!" % at.club.name if m < 80 else "%s are level, and what a time to do it!" % at.club.name
		elif mine == theirs + 1 and m >= 85:
			tail = "And there may not be time to answer it!"
		elif mine == theirs + 1 and at.get("under", false):
			tail = "The upset is on."
		elif mine == theirs + 1 and mine > 1:
			tail = "%s lead again." % at.club.name
		elif mine - theirs >= 3:
			tail = "This is turning into a long afternoon for %s." % df.club.name
		elif mine == theirs - 1:
			tail = "%s have one back. Game on." % at.club.name
		if tail == "" or sim.rng.randf() < 0.35:
			var why = _why(sim, at, df, kind, pid)
			if why != "":
				tail = why
	elif type == "save" and gk >= 0 and sim.pm.has(gk) and sim.pm[gk].get("sv", 0) >= 4:
		tail = "%s is having one of those days." % v.g
	elif type == "miss" and kind == "big" and at.goals < df.goals and m >= 75:
		tail = "That might be the chance gone."
	elif type == "miss" and blocked and df.goals > at.goals and m >= 70:
		tail = "%s are throwing bodies in front of everything." % df.club.name
	if tail != "":
		out += " " + tail
	return out


static func _why(sim, at: Dictionary, df: Dictionary, kind: String, pid: int) -> String:
	# a tactical or personal reason for the goal, when there is a clear one
	var di = df.instr
	if kind == "big" and int(di.get("line", 1)) == 2:
		return "That high line has been asking for it."
	if kind == "long" and int(di.get("line", 1)) == 0:
		return "Sit that deep and he has all the time he wants."
	if kind in ["cross", "corner"] and int(di.get("compact", 1)) == 0:
		return "They are too narrow to stop those balls into the box."
	if kind == "big" and bool(at.instr.get("counter", false)):
		return "Hit on the break, exactly as planned."
	if sim.pm.has(pid) and float(sim.pm[pid].get("star", 0.0)) >= 0.5:
		return "He is playing a different game from everyone else out there."
	if at.get("lift", false):
		return "The home crowd is lifting them."
	if df.get("flat", false):
		return "%s have not turned up today." % df.club.name
	return ""


static func fill(sim, side: int) -> String:
	# a line for a quiet minute, shaped by how the match is going
	var at = sim.sd[side]
	var df = sim.sd[1 - side]
	var v = {"t": at.club.name, "o": df.club.name}
	var m = sim.minute
	var r = sim.rng.randf()
	var tp = max(1, at.poss + df.poss)
	var share = int(round(100.0 * at.poss / tp))
	var wk = str(sim.wx.get("k", "clear"))
	if r > 0.9 and wk not in ["clear", "cloud"]:
		var wl = {"rain": ["The ball zips off the wet surface.", "A slip there on the greasy turf."], "heavy": ["The rain is hammering down now.", "Standing water is slowing the passing."],
			"wind": ["The wind takes that pass away from its man.", "Hard to judge anything in the air in this wind."], "snow": ["Heavy going out there in the snow.", "The orange ball is out, and the pitch is turning white."],
			"heat": ["The players take on water during a break in play.", "It is draining out there in this heat."]}
		if wl.has(wk):
			return wl[wk][sim.rng.randi() % 2]
	if r < 0.16 and m >= 15 and share >= 60:
		return "%s have had %d%% of the ball so far." % [at.club.name, share]
	if r < 0.3 and at.has("mu") and not at.mu.notes.is_empty():
		var nt = at.mu.notes[sim.rng.randi() % min(2, at.mu.notes.size())]
		var txt: String = nt[1].replace("{A}", at.club.name + "'s").replace("{b}", df.club.name + "'s")
		return txt + ("." if nt[0] > 0 else ", and it is hurting them.")
	if r < 0.42 and m >= 60 and at.goals > df.goals:
		return _pick(sim, ["%s are in no hurry now." % at.club.name, "%s take the sting out of it, keeping the ball near the corner." % at.club.name, "%s slow it right down. The lead is theirs to protect." % at.club.name])
	if r < 0.54 and m >= 60 and at.goals < df.goals:
		return _pick(sim, ["%s are committing men forward." % at.club.name, "%s need a goal and the clock is against them." % at.club.name, "All %s now. %s are camped on the edge of their own box." % [at.club.name, df.club.name]])
	if r < 0.6 and m in [43, 44, 45]:
		return "Not long until the break."
	if r < 0.66 and m >= 88:
		return "Into the last moments. %s have the ball." % at.club.name
	if r < 0.72 and at.get("flat", false):
		return "%s look a yard off the pace today." % at.club.name
	if r < 0.78 and at.get("under", false) and at.goals >= df.goals and m >= 30:
		return "%s are more than holding their own." % at.club.name
	return _f(_pick(sim, FILL_GEN), v)

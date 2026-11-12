extends RefCounted
# In-game social feed: invented fans, journalists and pundits react to results and to the manager's posts.

const FANS = ["terrace_tom", "northstand_nia", "away_days_ali", "matchday_mo", "season_ticket_sam", "kopite_kay", "ultra_uma", "pie_and_pint", "block_109", "the_12th_fan",
	"club_till_i_die", "sunday_league_sid", "goal_hanger_gus", "tifo_tess", "old_school_olu", "big_game_ben"]
const PRESS = [["Gazette Sport", "gazettesport"], ["The Touchline", "thetouchline"], ["Back Page Daily", "backpagedaily"], ["Final Whistle FM", "finalwhistlefm"]]
const WIN = ["WHAT a result! %s %d-%d. This team!", "%d-%d!! I'm losing my voice. Get in %s!", "Three points and deserved. %s looked sharp today.", "That's the %s I pay to watch. %d-%d.", "%s running the show again. Class."]
const DRAW = ["A point is a point I suppose. %d-%d.", "Should be winning those. %d-%d and two dropped.", "Frustrating. %s had the chances."]
const LOSS = ["%d-%d. Not good enough, simple as that.", "Shambles at the back again. %d-%d.", "I've seen enough. Changes needed after that.", "We go again, but that hurt. %d-%d."]
const AMBIENT = ["Who needs to start at the weekend? Wrong answers only.", "Transfer rumours doing my head in. Sign someone!", "Matchday can't come soon enough.", "Underrated: our away end. Loudest in the league.",
	"Hearing good things from the training ground this week.", "The academy lads deserve a chance, I'm saying it."]
const GOOD = ["proud", "great", "thank", "love", "brilliant", "win", "amazing", "superb", "together", "believe", "well done", "class"]
const BAD = ["referee", "ref ", "disgrace", "rubbish", "blame", "useless", "robbed", "joke", "terrible", "pathetic", "awful"]


static func data() -> Dictionary:
	var u = G.s.user
	if not u.has("social"):
		u["social"] = {"followers": int(2000 + u.rep * 400), "posts": [], "last": -9, "trend": ""}
	return u.social


static func _add(who: String, handle: String, text: String, likes: int, mine := false, kind := "fan") -> Dictionary:
	var d = data()
	var p = {"day": G.s.day, "who": who, "handle": handle, "text": text, "likes": likes, "reposts": int(likes * G.rng.randf_range(0.05, 0.25)), "mine": mine, "kind": kind, "replies": []}
	d.posts.push_front(p)
	if d.posts.size() > 70:
		d.posts.resize(70)
	return p


static func _fan() -> String:
	return FANS[G.rng.randi() % FANS.size()]


static func on_result(us: Dictionary, them: Dictionary, gf: int, ga: int, star: String, derby: bool):
	var d = data()
	var pool = WIN if gf > ga else (DRAW if gf == ga else LOSS)
	var scale = max(1.0, d.followers / 4000.0)
	for i in 2 + (1 if derby else 0):
		var t = pool[G.rng.randi() % pool.size()]
		var n = t.count("%")
		var txt = t
		if t.begins_with("%s") and t.contains("%d-%d"):
			txt = t % [star, gf, ga]
		elif t.find("%d") >= 0 and t.find("%s") > t.find("%d"):
			txt = t % [gf, ga, us.short]
		elif t.find("%s") >= 0 and t.find("%d") > t.find("%s"):
			txt = t % [us.short if not t.contains("WHAT") else us.short, gf, ga]
		elif n == 2:
			txt = t % [gf, ga]
		elif n == 1:
			txt = t % (star if gf >= ga else us.short)
		var h = _fan()
		_add(h.capitalize(), h, txt, int(G.rng.randi_range(20, 400) * scale))
	var pr = PRESS[G.rng.randi() % PRESS.size()]
	var head = "FULL TIME: %s %d-%d %s." % [us.name, gf, ga, them.name]
	if derby:
		head += " Derby day belongs to %s." % (us.short if gf > ga else (them.short if ga > gf else "nobody"))
	_add(pr[0], pr[1], head, int(G.rng.randi_range(300, 2500) * scale), false, "press")
	d.followers = int(max(500, d.followers + (gf - ga) * 180 + (600 if gf > ga else (-250 if gf < ga else 40)) + (900 if derby and gf > ga else 0)))
	var u = G.s.user
	if u.conf < 25:
		d.trend = "#%sOut" % str(u.name).split(" ")[-1]
	elif us.form.count("W") >= 4:
		d.trend = "#%sBall" % str(u.name).split(" ")[-1]
	else:
		d.trend = "#%s" % us.short


static func weekly():
	var d = data()
	var h = _fan()
	_add(h.capitalize(), h, AMBIENT[G.rng.randi() % AMBIENT.size()], G.rng.randi_range(10, 160))


static func post(text: String, tone := "") -> String:
	# the manager posts; returns a one-line summary of the reaction
	var s = G.s
	var u = s.user
	var c = G.uc()
	var d = data()
	var low = text.to_lower()
	if tone == "":
		tone = "neutral"
		for w in BAD:
			if low.contains(w):
				tone = "bad"
		if tone == "neutral":
			for w in GOOD:
				if low.contains(w):
					tone = "good"
	var named = null
	for pid in c.players:
		var p = s.players[pid]
		var ln = str(p.ln if p.cn == "" else p.cn).to_lower()
		if ln.length() >= 4 and low.contains(ln):
			named = p
			break
	var rival = ""
	for o in s.clubs:
		if o.id != c.id and not s.leagues[o.lg].roe and (low.contains(o.name.to_lower()) or (G.is_derby(c.id, o.id) and low.contains(o.short.to_lower()))):
			rival = o.name
			break
	var likes = int(d.followers * G.rng.randf_range(0.02, 0.09) * (1.5 if tone == "good" else (1.8 if rival != "" else 1.0)))
	var p0 = _add(u.name, str(u.name).to_lower().replace(" ", "_"), text, likes, true, "me")
	var out = "The post did steady numbers."
	if named != null:
		if tone == "bad":
			named.mor = max(0.0, named.mor - 5.0)
			p0.replies.append([_fan(), "Calling out %s in public? Not a good look, gaffer." % G.pname(named)])
			out = "%s is unhappy at being singled out." % G.pname(named)
		else:
			named.mor = min(100.0, named.mor + 4.0)
			p0.replies.append([str(G.pname(named)).to_lower().replace(". ", "").replace(" ", ""), "Thanks boss. We keep working."])
			out = "%s liked your post. His morale is up." % G.pname(named)
	if rival != "":
		u["fans"] = min(100.0, float(u.get("fans", 55.0)) + 1.5)
		u.conf = max(0.0, u.conf - 0.5)
		p0.replies.append([_fan(), "Gaffer coming for %s! Love it." % rival])
		p0.replies.append(["rival_fan_%d" % G.rng.randi_range(10, 99), "Screenshotted. See you on matchday."])
		out = "Your fans loved the dig at %s. The board would rather you stayed quiet." % rival
	if tone == "good":
		u["fans"] = min(100.0, float(u.get("fans", 55.0)) + 1.0)
		p0.replies.append([_fan(), "This is why we love you. Onwards!"])
		p0.replies.append([_fan(), "Top man. Behind you all the way."])
		if named == null and rival == "":
			out = "A warm reaction from the fans."
	elif tone == "bad":
		u.conf = max(0.0, u.conf - 1.0)
		p0.replies.append([_fan(), "Just get on with the job mate."])
		p0.replies.append([PRESS[0][1], "Strong words from the manager. We'll have reaction in tomorrow's edition."])
		if named == null and rival == "":
			out = "That post caused a stir, and the board noticed."
	else:
		p0.replies.append([_fan(), ["Noted, boss.", "Come on then!", "Announce a signing while you're here."][G.rng.randi() % 3]])
	d.followers += int(likes * 0.05)
	d.last = s.day
	return out

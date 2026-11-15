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
	var d = u.social
	if not d.has("handle"):
		d["handle"] = ""
		d["seq"] = 1
		d["trends"] = []
	return d


static func handle() -> String:
	var d = data()
	if str(d.handle) != "":
		return str(d.handle)
	return str(G.s.user.name).to_lower().replace(" ", "_")


static func _add(who: String, handle: String, text: String, likes: int, mine := false, kind := "fan", extra := {}) -> Dictionary:
	# kind: me, fan, press, journo (rumours), mgr (rival manager), player, club, world
	# extra: cid (club it is about), pid (player), at (aimed at you), rumour, true
	var d = data()
	var p = {"id": int(d.seq), "day": G.s.day, "who": who, "handle": handle, "text": text, "likes": likes, "reposts": int(likes * G.rng.randf_range(0.05, 0.25)), "mine": mine, "kind": kind, "replies": []}
	d.seq = int(d.seq) + 1
	for k in extra:
		p[k] = extra[k]
	if not p.has("cid"):
		p["cid"] = G.s.user.club if kind in ["me", "fan", "press"] else -1
	d.posts.push_front(p)
	if d.posts.size() > 90:
		d.posts.resize(90)
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


static func on_signing(p: Dictionary, fee: int):
	var d = data()
	var uc = G.uc()
	var scale = max(1.0, d.followers / 4000.0)
	var big = p.ovr >= uc.rep + 2
	var lines = ["%s is a %s player! Welcome!" % [G.pname(p), uc.short], "Announce %s. Oh wait, they did. Buzzing." % G.pname(p), "%s for %s? %s" % [G.pname(p), G.money(fee) if fee > 0 else "nothing", "Bargain." if fee < G.value(p) else "Steep, but I trust the gaffer."],
		"Watched %s a few times. %s" % [G.pname(p), "Proper player." if big else "Squad depth, fair enough."]]
	for i in 2:
		var h = _fan()
		_add(h.capitalize(), h, lines[G.rng.randi() % lines.size()], int(G.rng.randi_range(40, 700) * scale * (2.0 if big else 1.0)))
	var pr = PRESS[G.rng.randi() % PRESS.size()]
	_add(pr[0], pr[1], "DONE DEAL: %s complete the signing of %s%s." % [uc.name, G.pfull(p), (" for " + G.money(fee)) if fee > 0 else " on a free transfer"], int(G.rng.randi_range(500, 4000) * scale), false, "press")
	d.followers += 400 + (2500 if big else 0)


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
	var p0 = _add(u.name, handle(), text, likes, true, "me")
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


# ---------------------------------------------------------------- the wider world

const JOURNOS = [["Fabrizio Marquez", "fab_marquez", 0.85], ["Transfer Tim", "transfer_tim", 0.55], ["ITK Insider", "itk_insider", 0.3], ["Laura Hughes", "laurahughes_sport", 0.8]]
const CRYPTIC = ["Some people just don't see it.", "Silence says more.", "Patience has limits.", "Working hard every day. Not my decision.", "..."]
const HAPPY = ["What a night! Thanks for the support, always.", "Big three points. Proud of this group.", "Never stop working. On to the next one.", "Special feeling scoring in front of these fans."]
const WORLD_FAN = ["Our defending is a crime scene.", "Best team in the league, not even close.", "Sack the board, honestly.", "That keeper deserves a statue.", "Season is long, calm down everyone."]


static func _likes(base: int) -> int:
	return int(base * max(1.0, data().followers / 5000.0) * G.rng.randf_range(0.5, 1.6))


static func manager_post(cid: int, text: String):
	var m = G.MG.of(cid)
	_add(G.MG.nm(m), "%s_%s" % [str(m.ln).to_lower().replace(" ", ""), G.s.clubs[cid].short.to_lower()], text, _likes(900), false, "mgr", {"cid": cid, "at": true})


static func news_post(text: String, mine: bool):
	var pr = PRESS[G.rng.randi() % PRESS.size()]
	_add(pr[0], pr[1], text, _likes(1500), false, "press" if mine else "world", {"cid": -1})
	_trend_add("#" + text.split(" ")[0].replace(",", ""))


static func player_post(p: Dictionary, text: String):
	var h = (str(p.fn).substr(0, 1) + str(p.ln)).to_lower().replace(" ", "").replace("-", "")
	_add(G.pname(p), h, text, _likes(1200), false, "player", {"pid": p.id, "cid": p.club})


static func club_post(c: Dictionary, text: String):
	_add(c.name, c.short.to_lower() + "fc", text, _likes(2000), false, "club", {"cid": c.id})


static func _trend_add(t: String):
	var d = data()
	d.trends.push_front(t)
	while d.trends.size() > 4:
		d.trends.pop_back()


static func daily():
	# a few posts from around the world every day, so the feed lives between your matches
	var s = G.s
	var c = G.uc()
	data()
	# yesterday's notable results from the top leagues
	var picks = []
	for f in s.fixtures:
		if f.played and f.day == s.day - 1 and f.h != c.id and f.a != c.id and not f.get("fr", false):
			var h = s.clubs[f.h]
			var a = s.clubs[f.a]
			if s.leagues[h.lg].tier != 1:
				continue
			var gap = abs(h.rep - a.rep)
			var upset = (f.hg > f.ag and a.rep - h.rep >= 7) or (f.ag > f.hg and h.rep - a.rep >= 7)
			var score = (8.0 if upset else 0.0) + (f.hg + f.ag) * 0.8 + (h.rep + a.rep) * 0.02 - gap * 0.01
			picks.append([score, f, upset])
	picks.sort_custom(func(x, y): return x[0] > y[0])
	for pk in picks.slice(0, 2):
		var f = pk[1]
		var h = s.clubs[f.h]
		var a = s.clubs[f.a]
		var win = h if f.hg > f.ag else (a if f.ag > f.hg else null)
		club_post(win if win != null else h, "FULL TIME: %s %d-%d %s.%s" % [h.name, f.hg, f.ag, a.name, " What a result!" if pk[2] else ""])
		if pk[2]:
			_trend_add("#%sShock" % (win.short if win != null else h.short))
		if G.rng.randf() < 0.5:
			var fh = _fan()
			_add(fh.capitalize(), fh + "_" + h.short.to_lower(), WORLD_FAN[G.rng.randi() % WORLD_FAN.size()], _likes(120), false, "world", {"cid": h.id})
	# transfer rumours: some true, some not
	if G.rng.randf() < 0.22:
		_rumour()
	# an unhappy player of yours says something cryptic: a warning before it lands in your inbox
	for pid in c.players:
		var p = s.players[pid]
		if p.mor < 42 and s.day - int(p.get("cry", -99)) > 25 and G.rng.randf() < 0.25:
			p["cry"] = s.day
			player_post(p, CRYPTIC[G.rng.randi() % CRYPTIC.size()])
			break


static func _rumour():
	var s = G.s
	var c = G.uc()
	var j = JOURNOS[G.rng.randi() % JOURNOS.size()]
	var truth = G.rng.randf() < float(j[2])
	var text = ""
	var pid = -1
	if truth:
		# real: a bid for one of your players, or a deal you are working on
		for o in s.offers:
			if s.players.has(o.pid) and s.players[o.pid].club == c.id:
				var p = s.players[o.pid]
				text = "%s are serious about %s. Talks with %s ongoing. Here we go soon? 🔜" % [s.clubs[o.club].name if o.has("club") else "A club", G.pname(p), c.short]
				pid = p.id
				break
		if text == "" and s.get("deals", {}).size() > 0:
			var k = s.deals.keys()[0]
			if s.players.has(k):
				var p2 = s.players[k]
				text = "%s are pushing to sign %s. Contacts at an advanced stage." % [c.name, G.pname(p2)]
				pid = p2.id
	if text == "":
		truth = false
		var sq = c.players.map(func(x): return s.players[x])
		sq.sort_custom(func(a, b): return a.ovr > b.ovr)
		if sq.is_empty():
			return
		var p3 = sq[G.rng.randi() % min(5, sq.size())]
		var big = s.clubs[G.rng.randi() % s.clubs.size()]
		if big.id == c.id:
			return
		text = "Understand %s are monitoring %s ahead of the next window. Initial contact made. 👀" % [big.name, G.pname(p3)]
		pid = p3.id
	_add(j[0], j[1], text.replace(" 🔜", "").replace(" 👀", ""), _likes(2500), false, "journo", {"pid": pid, "cid": c.id, "at": true, "rumour": true, "true": truth})


# ---------------------------------------------------------------- replying

static func reply_opts(p: Dictionary) -> Array:
	# [label, code] for a post you can answer; [] when you can't
	if p.mine or p.has("rep"):
		return []
	match str(p.kind):
		"mgr": return [["Hit back", "hit"], ["Show respect", "respect"], ["Ignore", "ignore"]]
		"player":
			if int(p.get("cid", -1)) == G.s.user.club:
				if p.text in CRYPTIC:
					return [["Reassure him", "reassure"], ["Call him out", "callout"], ["Ignore", "ignore"]]
				return [["Praise him", "praise"], ["Like", "like"]]
			return []
		"journo": return [["Deny it", "deny"], ["No comment", "ignore"], ["Hint it's true", "hint"]]
		"fan":
			return [["Thank them", "thank"], ["Hit back", "hitfan"], ["Like", "like"]]
		"press": return [["Share it", "like"], ["Hit back at the press", "hitpress"]]
	return []


static func reply(p: Dictionary, code: String) -> String:
	var s = G.s
	var u = s.user
	var d = data()
	p["rep"] = code
	var pl = s.players.get(int(p.get("pid", -1)), null)
	var out = ""
	var line = ""
	match code:
		"hit":
			var m = G.MG.of(int(p.cid))
			m.feud = min(100.0, float(m.feud) + 12.0)
			u["fans"] = min(100.0, float(u.get("fans", 55.0)) + 1.5)
			u.conf = max(0.0, u.conf - 0.5)
			d.followers += 1500
			line = ["Talk is cheap. See you on matchday.", "Worry about your own team, %s." % m.ln, "Scoreboard."][G.rng.randi() % 3]
			out = "The fans love it. The feud with %s just got hotter." % m.ln
		"respect":
			var m2 = G.MG.of(int(p.cid))
			m2.feud = max(0.0, float(m2.feud) - 10.0)
			u.conf = min(100.0, u.conf + 0.5)
			line = "Respect to %s. May the best team win." % m2.ln
			out = "A classy reply. Tensions with %s ease." % m2.ln
		"reassure":
			if pl != null:
				pl.mor = min(100.0, pl.mor + 9.0)
			line = "Door's always open. You're part of this. 🤝".replace(" 🤝", "")
			out = "He appreciates it. His morale is up."
		"callout":
			if pl != null:
				pl.mor = max(0.0, pl.mor - 12.0)
				for pid in G.uc().players:
					s.players[pid].mor = max(0.0, s.players[pid].mor - 1.0)
			line = "Keep it in the dressing room."
			out = "He is angry, and the squad felt the chill."
		"praise":
			if pl != null:
				pl.mor = min(100.0, pl.mor + 5.0)
			line = "Deserved. Keep going."
			out = "He is buzzing. Morale up."
		"deny":
			if pl != null:
				pl.mor = min(100.0, pl.mor + 3.0)
			line = "Nonsense. He's going nowhere."
			out = "Rumour denied. %s" % ("This one was true: expect the bid anyway." if p.get("true", false) else "Fans relieved.")
			u["fans"] = min(100.0, float(u.get("fans", 55.0)) + 1.0)
		"hint":
			if pl != null:
				pl.mor = max(0.0, pl.mor - 6.0)
			u["fans"] = max(0.0, float(u.get("fans", 55.0)) - 2.0)
			line = "Every player has a price."
			out = "The fans are not happy, and nor is he."
		"thank":
			u["fans"] = min(100.0, float(u.get("fans", 55.0)) + 0.5)
			line = "Thanks for the support, means a lot."
			out = "A nice touch. Fans happy."
		"hitfan":
			u["fans"] = max(0.0, float(u.get("fans", 55.0)) - 1.5)
			d.followers += 800
			line = "Plenty of experts online today."
			out = "It went viral, but not in a good way."
		"hitpress":
			u.conf = max(0.0, u.conf - 1.0)
			u["fans"] = min(100.0, float(u.get("fans", 55.0)) + 0.5)
			line = "Write what you like. We'll do our talking on the pitch."
			out = "The papers will remember that. So will the board."
		"like":
			p.likes = int(p.likes) + 1
			out = "Liked."
		_:
			out = "You let it go."
	if line != "":
		p.replies.append([handle(), line])
	return out

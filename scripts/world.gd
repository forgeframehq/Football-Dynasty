extends RefCounted
# The big world (G.WD). Fills the main rest-of-Europe leagues to full size and adds new nations with real club
# names and generated players. These "background" leagues (league.bg = true) play a full season of fixtures with
# quick results (no match engine), so tables, scorers and form move every week. Their generated players are hidden
# (p.hid) from Player Search until a scout reports on them; every transfer window the big clubs buy some of the best.
# A league stops being background when the manager takes a job there.
#
# Catalogue entries: [league name, short, country (as in the name pools), continent, top rep, bottom rep, local share,
# other nationalities, clubs strongest first]. An existing league is matched by name and only topped up.

const CAT = [
	["Eredivisie", "ERE", "Holland", "Europe", 78, 60, 0.6, ["Belgium", "Morocco", "Denmark", "Brazil", "Sweden"],
		["Go Ahead Eagles", "Heerenveen", "Sparta Rotterdam", "Fortuna Sittard", "Groningen", "NAC Breda", "PEC Zwolle", "Heracles Almelo", "Excelsior", "Telstar", "FC Volendam"]],
	["Liga Portugal", "LIG", "Portugal", "Europe", 80, 58, 0.5, ["Brazil", "Spain", "Argentina", "Colombia", "Senegal"],
		["Gil Vicente", "Moreirense", "Rio Ave", "Santa Clara", "Casa Pia", "Nacional", "Estrela Amadora", "AVS", "Tondela", "Alverca"]],
	["Süper Lig", "SÜP", "Turkey", "Europe", 78, 60, 0.55, ["Brazil", "Portugal", "Nigeria", "Serbia", "France"],
		["Göztepe", "Kasımpaşa", "Alanyaspor", "Antalyaspor", "Kayserispor", "Gaziantep FK", "Eyüpspor", "Kocaelispor", "Gençlerbirliği", "Karagümrük"]],
	["Belgian Pro League", "BEL", "Belgium", "Europe", 76, 60, 0.45, ["Holland", "France", "Ghana", "Nigeria", "Japan"],
		["Cercle Brugge", "Westerlo", "Charleroi", "OH Leuven", "Royal Antwerp", "Dender", "Zulte Waregem", "RAAL La Louvière"]],
	["Scottish Premiership", "SCO", "Scotland", "Europe", 75, 58, 0.55, ["England", "Republic of Ireland", "Northern Ireland", "Australia", "Holland"],
		["Aberdeen", "Hibernian", "Motherwell", "Dundee United", "St Mirren", "Kilmarnock", "Dundee", "Livingston", "Falkirk"]],
	["Brasileirão", "BRA", "Brazil", "South America", 77, 63, 0.88, ["Argentina", "Uruguay", "Colombia", "Paraguay", "Ecuador"],
		["Flamengo", "Palmeiras", "Botafogo", "Fluminense", "São Paulo", "Corinthians", "Atlético Mineiro", "Internacional", "Grêmio", "Cruzeiro",
		"Bahia", "Fortaleza", "Vasco da Gama", "Red Bull Bragantino", "Santos", "Vitória", "Juventude", "Sport Recife", "Ceará", "Mirassol"]],
	["Liga Profesional", "ARG", "Argentina", "South America", 74, 60, 0.85, ["Uruguay", "Paraguay", "Colombia", "Chile", "Venezuela"],
		["River Plate", "Boca Juniors", "Racing Club", "Independiente", "San Lorenzo", "Estudiantes", "Vélez Sarsfield", "Talleres", "Rosario Central", "Newell's Old Boys",
		"Lanús", "Argentinos Juniors", "Huracán", "Defensa y Justicia", "Godoy Cruz", "Belgrano", "Unión", "Platense", "Tigre", "Banfield"]],
	["MLS", "MLS", "United States", "North America", 71, 59, 0.45, ["Canada", "Mexico", "Argentina", "Colombia", "Jamaica", "England"],
		["Inter Miami", "LAFC", "LA Galaxy", "Columbus Crew", "FC Cincinnati", "Seattle Sounders", "Philadelphia Union", "New York City FC", "New York Red Bulls", "Atlanta United",
		"Orlando City", "Vancouver Whitecaps", "Minnesota United", "Nashville SC", "Portland Timbers", "Real Salt Lake", "Austin FC", "San Diego FC", "Charlotte FC", "Toronto FC"]],
	["Liga MX", "LMX", "Mexico", "North America", 71, 60, 0.7, ["Argentina", "Colombia", "Uruguay", "Chile", "United States"],
		["América", "Monterrey", "Tigres UANL", "Cruz Azul", "Guadalajara", "Toluca", "Pumas UNAM", "Pachuca", "León", "Santos Laguna",
		"Atlas", "Tijuana", "Puebla", "Necaxa", "Querétaro", "Mazatlán", "Juárez", "Atlético San Luis"]],
	["Saudi Pro League", "SPL", "Saudi Arabia", "Asia", 77, 57, 0.55, ["Brazil", "Portugal", "France", "Morocco", "Senegal", "Spain"],
		["Al Hilal", "Al Nassr", "Al Ittihad", "Al Ahli", "Al Qadsiah", "Al Shabab", "Al Ettifaq", "Al Taawoun", "Al Fateh", "Al Khaleej",
		"Al Kholood", "Al Riyadh", "Damac", "Al Fayha", "Al Okhdood", "Al Hazem", "Al Najma", "NEOM"]],
	["J1 League", "J1", "Japan", "Asia", 68, 58, 0.9, ["Brazil", "Korea Republic", "Australia"],
		["Vissel Kobe", "Kashima Antlers", "Kashiwa Reysol", "Sanfrecce Hiroshima", "Machida Zelvia", "Urawa Reds", "Kawasaki Frontale", "Gamba Osaka", "Cerezo Osaka", "FC Tokyo",
		"Kyoto Sanga", "Nagoya Grampus", "Shimizu S-Pulse", "Avispa Fukuoka", "Yokohama F. Marinos", "Fagiano Okayama", "Tokyo Verdy", "Albirex Niigata"]],
	["Botola Pro", "BOT", "Morocco", "Africa", 65, 54, 0.85, ["Senegal", "Mali", "Côte d'Ivoire", "Guinea"],
		["Wydad AC", "Raja Casablanca", "AS FAR", "RS Berkane", "FUS Rabat", "Maghreb Fès", "Hassania Agadir", "Olympique Safi", "Renaissance Zemamra", "Union Touarga",
		"IR Tanger", "Difaâ El Jadida", "Kawkab Marrakech", "Olympic Dcheira", "CODM Meknès", "Chabab Mohammédia"]],
	["NPFL", "NPF", "Nigeria", "Africa", 60, 50, 0.95, ["Ghana", "Cameroon", "Côte d'Ivoire"],
		["Enyimba", "Rangers International", "Rivers United", "Remo Stars", "Kano Pillars", "Shooting Stars", "Kwara United", "Plateau United", "Lobi Stars", "Abia Warriors",
		"Bendel Insurance", "Niger Tornadoes", "Katsina United", "Ikorodu City", "Bayelsa United", "Nasarawa United"]],
]
const CONTINENTS = ["Europe", "South America", "North America", "Asia", "Africa"]
const POS = ["GK", "GK", "CB", "CB", "CB", "CB", "LB", "LB", "RB", "RB", "CDM", "CDM", "CM", "CM", "CM", "CAM", "LM", "RM", "LW", "RW", "ST", "ST"]
const COLS = [["C8102E", "FFFFFF"], ["034694", "FFFFFF"], ["000000", "FFFFFF"], ["006400", "FFFFFF"], ["FDB913", "000000"], ["6CABDD", "1C2C5B"], ["7A263A", "FFD700"],
	["EF0107", "063672"], ["FFFFFF", "000000"], ["00529F", "FFD100"], ["E30613", "000000"], ["F18A01", "1E3A8A"], ["5C2D91", "FFFFFF"], ["00A650", "000000"]]
# name pool for a league country that is spelt differently in the data
const NAT = {"Netherlands": "Holland", "Türkiye": "Turkey", "Czechia": "Czech Republic"}

static func nat_of(country: String) -> String:
	return NAT.get(country, country)


static func continent_of(lg: Dictionary) -> String:
	for e in CAT:
		if e[0] == lg.name:
			return e[3]
	return "Europe"


static func ensure():
	# builds the world once per career (also for saves from before it existed)
	var s = G.s
	if s.has("world"):
		return
	s["world"] = {"v": 1}
	var rng = G.rng
	var added = []
	for e in CAT:
		var lg = null
		for l in s.leagues:
			if l.name == e[0]:
				lg = l
		if lg == null:
			lg = {"id": s.leagues.size(), "name": e[0], "short": e[1], "country": e[2], "tier": 1, "clubs": [], "roe": false}
			s.leagues.append(lg)
		lg["bg"] = true
		lg["cont"] = e[3]
		var names = e[8]
		var have = {}
		for cid in lg.clubs:
			have[s.clubs[cid].name] = true
		var n_old = lg.clubs.size()
		var todo = names.filter(func(x): return not have.has(x))
		for i in todo.size():
			var nm = todo[i]
			var k = n_old + i
			var n_all = n_old + todo.size()
			var top = float(e[4]) if n_old == 0 else float(e[4]) - 8.0
			var rep = lerp(top, float(e[5]), float(k - (0 if n_old == 0 else n_old)) / max(1.0, float(todo.size() - 1))) + rng.randf_range(-1.5, 1.5)
			var c = _club(nm, lg.id, rep, e)
			added.append(c.id)
	if added.size() > 0:
		G.build_index()
		fixtures(s.day)


static func _short(nm: String) -> String:
	var w = nm.replace("FC ", "").replace("Al ", "").replace("Club ", "").replace(" FC", "").strip_edges()
	var t = w.substr(0, 3).to_upper()
	return t


static func _club(nm: String, lg_id: int, rep: float, e: Array) -> Dictionary:
	var s = G.s
	var rng = G.rng
	var id = s.clubs.size()
	var col = COLS[(nm.hash() & 0x7fffffff) % COLS.size()]
	var c = G.raw_club(id, {"name": nm, "short": _short(nm), "lg": lg_id, "c1": col[0], "c2": col[1], "stadium": "%s Stadium" % nm.split(" ")[-1]})
	s.clubs.append(c)
	s.leagues[lg_id].clubs.append(id)
	for pos in POS:
		var nat = e[2] if rng.randf() < float(e[6]) else e[7][rng.randi() % e[7].size()]
		var a = clampi(int(rng.randfn(26.0, 4.5)), 17, 35)
		var ovr = clampi(int(rng.randfn(rep - 3.0, 4.5)), 40, 86)
		var p = G.gen_player(id, pos, a, ovr, ovr, nat)
		p.pot = G.gen_potential(ovr, a, rng)
		# no wonderkid loophole: generated potential is capped, with the rare exception
		if p.pot > 86 and rng.randf() > 0.15:
			p.pot = 86
		p["hid"] = true
		G.give_number(c, p)
	G.init_club(c)
	c.budget = G.nice(c.budget * 0.6)
	return c


static func hidden(p: Dictionary) -> bool:
	# a generated player nobody at your club knows about yet
	return p.get("hid", false) and not G.OPS.knows(p) and G.SN.report_for(p.id) == null


# ---------------------------------------------------------------- fixtures and quick results

static func fixtures(from_day: int):
	# a double round robin for every background league, from from_day to late May
	var s = G.s
	var last = G.ymd(s.season + 1, 5, 24)
	var start = max(from_day + 1, G.ymd(s.season, 8, 8))
	for lg in s.leagues:
		# every world league (background or, once you manage there, fully simulated) gets its fixtures here
		if not lg.has("cont") or lg.clubs.size() < 4:
			continue
		# leagues that already have fixtures this season keep them
		var has = false
		for f in s.fixtures:
			if f.get("lg", -1) == lg.id and not f.get("ko", false) and f.get("comp", "") == "":
				has = true
				break
		if has:
			continue
		var ids = lg.clubs.duplicate()
		ids.shuffle()
		if ids.size() % 2 == 1:
			ids.append(-1)
		var n = ids.size()
		var half = []
		for r in n - 1:
			var rd = []
			for i in n / 2:
				var a = ids[i]
				var b = ids[n - 1 - i]
				if a >= 0 and b >= 0:
					rd.append([b, a] if r % 2 == 1 else [a, b])
			half.append(rd)
			var lst = ids.pop_back()
			ids.insert(1, lst)
		var rounds = half.duplicate()
		for rd in half:
			rounds.append(rd.map(func(m): return [m[1], m[0]]))
		# weekends first (Sundays, so they don't clash with the Saturday programme), then midweeks if needed
		var days = []
		var d = start
		while d <= last:
			if G.date(d).weekday == 0:
				days.append(d)
			d += 1
		if days.size() < rounds.size():
			d = start
			while d <= last and days.size() < rounds.size():
				if G.date(d).weekday == 3:
					days.append(d)
				d += 1
			days.sort()
		var step = float(days.size()) / rounds.size()
		for r in rounds.size():
			var day = days[min(days.size() - 1, int(r * step))]
			for m in rounds[r]:
				s.fixtures.append({"id": s.fixtures.size(), "lg": lg.id, "rd": r + 1, "day": day, "h": m[0], "a": m[1], "hg": -1, "ag": -1, "played": false, "ko": false, "label": ""})
	G.build_index()


static func _pois(l: float) -> int:
	var k = 0
	var p = 1.0
	var t = exp(-l)
	while true:
		p *= G.rng.randf()
		if p <= t or k > 9:
			return k
		k += 1
	return k


static func quick(f: Dictionary):
	# a background match: goals from the two sides' strength, the table, form, appearances and scorers
	var s = G.s
	var h = s.clubs[f.h]
	var a = s.clubs[f.a]
	var d = (h.rep - a.rep) * 0.045
	var hg = _pois(1.45 * exp(d))
	var ag = _pois(1.12 * exp(-d))
	f.played = true
	f.hg = hg
	f.ag = ag
	for side in [[h, hg, ag], [a, ag, hg]]:
		var c = side[0]
		var gf = side[1]
		var ga = side[2]
		var tb = c.t
		tb.p += 1
		tb.gf += gf
		tb.ga += ga
		var res = "W" if gf > ga else ("L" if gf < ga else "D")
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
		var xi = _xi(c)
		for p in xi:
			p.ss.ap += 1
			p.ss.rs += 6.5 + (0.4 if res == "W" else (-0.3 if res == "L" else 0.0)) + G.rng.randf_range(-0.4, 0.4)
		for g in gf:
			var sc = _pick(xi)
			if sc != null:
				sc.ss.g += 1
				sc.cg += 1
				var asst = _pick(xi)
				if asst != null and asst != sc and G.rng.randf() < 0.7:
					asst.ss.a += 1
		if ga == 0 and xi.size() > 0 and xi[0].pos == "GK":
			xi[0].ss.cs += 1


static func _xi(c: Dictionary) -> Array:
	var s = G.s
	var arr = []
	for pid in c.players:
		var p = s.players[pid]
		if p.inj <= 0:
			arr.append(p)
	arr.sort_custom(func(x, y): return x.ovr > y.ovr)
	var out = []
	var gk = null
	for p in arr:
		if p.pos == "GK":
			if gk == null:
				gk = p
			continue
		if out.size() < 10:
			out.append(p)
	if gk != null:
		out.push_front(gk)
	return out


static func _pick(xi: Array):
	var tot = 0.0
	var w = []
	for p in xi:
		var v = [0.05, 0.5, 1.4, 3.2][G.LINE[p.pos]] * (1.0 + (p.ovr - 60) * 0.03)
		w.append(max(0.01, v))
		tot += max(0.01, v)
	var r = G.rng.randf() * tot
	for i in xi.size():
		r -= w[i]
		if r <= 0:
			return xi[i]
	return null


# ---------------------------------------------------------------- the world keeps moving

static func window_tick():
	# while a window is open, the big clubs of the main leagues buy the best of the background leagues
	var s = G.s
	if not G.window_open() or G.rng.randf() > 0.12:
		return
	var buyers = s.clubs.filter(func(c): return c.id != s.user.club and not s.leagues[c.lg].get("bg", false) and not s.leagues[c.lg].roe and s.leagues[c.lg].tier == 1 and c.rep >= 70)
	if buyers.is_empty():
		return
	var b = buyers[G.rng.randi() % buyers.size()]
	var best = null
	var bv = -1.0
	for i in 60:
		var lg = s.leagues[G.rng.randi() % s.leagues.size()]
		if not lg.get("bg", false) or lg.clubs.is_empty():
			continue
		var c = s.clubs[lg.clubs[G.rng.randi() % lg.clubs.size()]]
		if c.id == s.user.club:
			continue
		for pid in c.players:
			var p = s.players[pid]
			if G.age(p) > 28 or p.ovr < b.rep - 6:
				continue
			var v = p.pot * 1.0 + p.ovr * 0.6 - G.age(p)
			if v > bv:
				bv = v
				best = p
	if best == null or G.value(best) > b.budget * 1.5:
		return
	var from = s.clubs[best.club]
	var fee = G.nice(G.value(best) * G.rng.randf_range(1.0, 1.3))
	var was_known = not hidden(best)
	G.TR.move(best, b.id, fee, G.wage_for(best.ovr, G.age(best)), G.rng.randi_range(3, 5))
	best.erase("hid")
	b.budget = max(0, b.budget - fee)
	from.budget += fee
	G.SOC.club_post(b, "DONE DEAL: %s joins from %s for %s. Welcome! ✍️".replace(" ✍️", "") % [G.pname(best), from.name, G.money(fee)])
	if best.id in s.shortlist or was_known:
		G.msg("%s moves to %s" % [G.pname(best), b.short], "%s (%d, %s) has left %s for %s for %s. You %s." % [G.pfull(best), G.age(best), best.pos, from.name, b.name, G.money(fee),
			"had him on your shortlist" if best.id in s.shortlist else "had a scout report on him"], "deal", best.id)


static func make_playable(lg_id: int):
	# the manager takes a job in a background league: from now on its matches use the full match engine
	var s = G.s
	if lg_id >= 0 and lg_id < s.leagues.size():
		s.leagues[lg_id].bg = false

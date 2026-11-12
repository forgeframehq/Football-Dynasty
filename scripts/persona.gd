extends RefCounted
# Personal details the dataset does not carry: personality, favoured club, languages,
# international caps and the season-by-season record. Everything is worked out once
# from the player's own details and then kept on the player, so it never changes on reload.

const TYPES = ["Model professional", "Determined", "Ambitious", "Loyal", "Spirited", "Leader", "Balanced", "Balanced", "Laid back", "Temperamental", "Mercenary", "Quiet"]
const BLURB = {
	"Model professional": "Trains hard, rarely complains and develops well.",
	"Determined": "Pushes himself and reacts well to setbacks.",
	"Ambitious": "Wants to play at the highest level and will move to get there.",
	"Loyal": "Attached to his club. Easier to keep, harder to prise away.",
	"Spirited": "Lifts the dressing room when results are good.",
	"Leader": "Others follow him. A natural captain.",
	"Balanced": "No strong traits either way.",
	"Laid back": "Unbothered by pressure, and sometimes by training.",
	"Temperamental": "Brilliant when happy, difficult when not.",
	"Mercenary": "Follows the money. Expect a hard wage negotiation.",
	"Quiet": "Keeps to himself and settles slowly at a new club."}
const LANGS = {"England": "English", "Scotland": "English", "Wales": "English", "Ireland": "English", "Northern Ireland": "English", "United States": "English", "Australia": "English",
	"Canada": "English", "New Zealand": "English", "Jamaica": "English", "Nigeria": "English", "Ghana": "English", "South Africa": "English",
	"Spain": "Spanish", "Argentina": "Spanish", "Mexico": "Spanish", "Colombia": "Spanish", "Uruguay": "Spanish", "Chile": "Spanish", "Paraguay": "Spanish", "Peru": "Spanish",
	"Ecuador": "Spanish", "Venezuela": "Spanish", "Bolivia": "Spanish", "Costa Rica": "Spanish", "Honduras": "Spanish", "Panama": "Spanish", "Dominican Republic": "Spanish",
	"France": "French", "Belgium": "French", "Senegal": "French", "Côte d'Ivoire": "French", "Ivory Coast": "French", "Cameroon": "French", "Mali": "French", "Algeria": "French",
	"Morocco": "French", "Tunisia": "French", "Guinea": "French", "Congo DR": "French", "DR Congo": "French", "Burkina Faso": "French", "Gabon": "French", "Togo": "French", "Benin": "French", "Haiti": "French",
	"Germany": "German", "Austria": "German", "Switzerland": "German", "Italy": "Italian", "Portugal": "Portuguese", "Brazil": "Portuguese", "Angola": "Portuguese",
	"Cape Verde": "Portuguese", "Mozambique": "Portuguese", "Guinea-Bissau": "Portuguese", "Netherlands": "Dutch", "Suriname": "Dutch", "Denmark": "Danish", "Sweden": "Swedish",
	"Norway": "Norwegian", "Finland": "Finnish", "Iceland": "Icelandic", "Poland": "Polish", "Czechia": "Czech", "Czech Republic": "Czech", "Slovakia": "Slovak", "Hungary": "Hungarian",
	"Croatia": "Croatian", "Serbia": "Serbian", "Bosnia and Herzegovina": "Bosnian", "Slovenia": "Slovene", "Montenegro": "Serbian", "North Macedonia": "Macedonian",
	"Albania": "Albanian", "Kosovo": "Albanian", "Greece": "Greek", "Cyprus": "Greek", "Türkiye": "Turkish", "Turkey": "Turkish", "Romania": "Romanian", "Bulgaria": "Bulgarian",
	"Ukraine": "Ukrainian", "Russia": "Russian", "Georgia": "Georgian", "Armenia": "Armenian", "Israel": "Hebrew", "Egypt": "Arabic", "Saudi Arabia": "Arabic", "Iraq": "Arabic",
	"Qatar": "Arabic", "United Arab Emirates": "Arabic", "Iran": "Persian", "Japan": "Japanese", "Korea Republic": "Korean", "South Korea": "Korean", "China PR": "Mandarin",
	"China": "Mandarin", "India": "Hindi", "Uzbekistan": "Uzbek"}
const BIG = ["Brazil", "France", "England", "Spain", "Germany", "Argentina", "Italy", "Portugal", "Netherlands", "Belgium"]
const MID = ["Croatia", "Uruguay", "Denmark", "Colombia", "Morocco", "Senegal", "Switzerland", "United States", "Mexico", "Japan", "Serbia", "Sweden", "Poland", "Austria",
	"Norway", "Türkiye", "Turkey", "Ukraine", "Nigeria", "Côte d'Ivoire", "Ivory Coast", "Korea Republic", "Scotland", "Wales", "Ecuador", "Egypt", "Algeria", "Ghana", "Cameroon"]


static func h(p: Dictionary, salt: int) -> int:
	return absi(hash(int(p.id) * 7919 + salt * 104729))


static func personality(p: Dictionary) -> String:
	if not p.has("per"):
		p["per"] = TYPES[h(p, 1) % TYPES.size()]
	return p.per


static func blurb(p: Dictionary) -> String:
	return BLURB.get(personality(p), "")


static func cap_bar(nat: String) -> int:
	# overall rating a player roughly needs to be picked by his country
	if nat in BIG: return 81
	if nat in MID: return 74
	return 66


static func caps(p: Dictionary) -> Array:
	# [caps, international goals]
	if not p.has("caps"):
		var a = G.age(p)
		var edge = p.ovr - cap_bar(p.nat) + 2
		var n = 0
		if edge > 0 and a >= 19:
			n = int(clamp(edge * (a - 18) * (0.3 + (h(p, 2) % 45) / 100.0), 1, 165))
		var rate = {"ST": 0.42, "CF": 0.38, "LW": 0.24, "RW": 0.24, "CAM": 0.2, "LM": 0.13, "RM": 0.13, "CM": 0.1, "CDM": 0.05, "GK": 0.0}.get(p.pos, 0.04)
		p["caps"] = [n, int(n * rate * (0.7 + (h(p, 3) % 60) / 100.0))]
	return p.caps


static func career(p: Dictionary) -> Array:
	# [apps, goals] over his whole career: an estimate of the years before the save began, plus what he has done since
	if not p.has("pre"):
		var yrs = max(0, G.age(p) - 18)
		var share = clamp((p.ovr - 50) / 32.0, 0.25, 0.92)
		var ap = int(yrs * 34 * share * (0.8 + (h(p, 7) % 40) / 100.0))
		var rate = {"ST": 0.4, "CF": 0.34, "LW": 0.22, "RW": 0.22, "CAM": 0.19, "LM": 0.11, "RM": 0.11, "CM": 0.08, "CDM": 0.04, "GK": 0.0}.get(p.pos, 0.035)
		p["pre"] = [ap, int(ap * rate * clamp((p.ovr - 40) / 40.0, 0.4, 1.25))]
	return [p.pre[0] + p.cap, p.pre[1] + p.cg]


static func country_of(club_id: int) -> String:
	if club_id < 0:
		return ""
	return G.s.leagues[G.s.clubs[club_id].lg].country


static func languages(p: Dictionary) -> Array:
	if not p.has("lang"):
		var l = [LANGS.get(p.nat, p.nat)]
		p["lang"] = l
		learn(p, country_of(p.club))
		if not ("English" in l) and h(p, 4) % 100 < 38:
			l.append("English")
	return p.lang


static func learn(p: Dictionary, country: String):
	var lg = LANGS.get(country, "")
	if lg != "" and p.has("lang") and not (lg in p.lang):
		p.lang.append(lg)


static func speaks_local(p: Dictionary, club_id: int) -> bool:
	var lg = LANGS.get(country_of(club_id), "")
	return lg == "" or lg in languages(p)


static func favoured(p: Dictionary) -> int:
	# club id, or -1 when he has no particular attachment
	if not p.has("fav"):
		var r = h(p, 5) % 100
		var fav = -1
		if p.club >= 0 and (r < 30 or personality(p) == "Loyal"):
			fav = p.club
		elif r < 62:
			# a big club from his own country, when that country is in the game
			var best = []
			for c in G.s.clubs:
				if G.s.leagues[c.lg].country == p.nat and G.s.leagues[c.lg].tier == 1:
					best.append(c)
			if best.size() > 0:
				best.sort_custom(func(a, b): return a.rep > b.rep)
				fav = best[h(p, 6) % min(6, best.size())].id
		p["fav"] = fav
	return p.fav


static func favoured_name(p: Dictionary) -> String:
	var f = favoured(p)
	return G.s.clubs[f].name if f >= 0 and f < G.s.clubs.size() else "None"


static func history(p: Dictionary) -> Array:
	return p.get("hist", [])


static func season_end(p: Dictionary):
	# called at rollover, before the season's numbers are wiped
	if p.ss.ap > 0:
		if not p.has("hist"):
			p["hist"] = []
		var cn = "Free agent" if p.club < 0 else G.s.clubs[p.club].short if G.s.clubs[p.club].has("short") else G.s.clubs[p.club].name
		p.hist.append([G.s.season, cn, p.ss.ap, p.ss.g, p.ss.a, snappedf(p.ss.rs / p.ss.ap, 0.01), p.ss.mom])
		if p.hist.size() > 14:
			p.hist.pop_front()
	if p.has("caps") or p.ovr >= cap_bar(p.nat) - 2:
		var c = caps(p)
		if p.ovr >= cap_bar(p.nat) - 2 and G.age(p) < 36:
			var add = 3 + h(p, G.s.season) % 8
			c[0] += add
			c[1] += int(round(add * p.ss.g / max(8.0, p.ss.ap * 2.2)))

extends Control
# Small drawn national flag. Unknown nations get a neutral plate.

const F = {
	"England": ["cross", "ffffff", "ce1124"], "Northern Ireland": ["cross", "ffffff", "ce1124"],
	"Scotland": ["saltire", "0065bd", "ffffff"], "Wales": ["h2", "ffffff", "00ab39", "dot", "d30731"],
	"France": ["v3", "0055a4", "ffffff", "ef4135"], "Italy": ["v3", "009246", "ffffff", "ce2b37"],
	"Germany": ["h3", "111111", "dd0000", "ffce00"], "Spain": ["h3w", "aa151b", "f1bf00", "aa151b"],
	"Holland": ["h3", "ae1c28", "ffffff", "21468b"], "Belgium": ["v3", "111111", "fae042", "ed2939"],
	"Portugal": ["v2p", "006600", "ff0000"], "Brazil": ["plain", "009c3b", "diamond", "ffdf00", "dot", "002776"],
	"Argentina": ["h3", "74acdf", "ffffff", "74acdf"], "Republic of Ireland": ["v3", "169b62", "ffffff", "ff883e"],
	"Turkey": ["plain", "e30a17", "dot", "ffffff"], "Denmark": ["nordic", "c60c30", "ffffff"],
	"Norway": ["nordic", "ba0c2f", "00205b"], "Sweden": ["nordic", "006aa7", "fecc00"],
	"Switzerland": ["plain", "d52b1e", "plus", "ffffff"], "Morocco": ["plain", "c1272d", "dot", "006233"],
	"Poland": ["h2", "ffffff", "dc143c"], "Austria": ["h3", "ed2939", "ffffff", "ed2939"],
	"Croatia": ["h3", "ff0000", "ffffff", "171796"], "Senegal": ["v3", "00853f", "fdef42", "e31b23"],
	"Nigeria": ["v3", "008751", "ffffff", "008751"], "Côte d'Ivoire": ["v3", "f77f00", "ffffff", "009e60"],
	"Czech Republic": ["h2", "ffffff", "d7141a"], "Ukraine": ["h2", "0057b7", "ffd700"],
	"Japan": ["plain", "ffffff", "dot", "bc002d"], "Greece": ["h3", "0d5eaf", "ffffff", "0d5eaf"],
	"Serbia": ["h3", "c6363c", "0c4076", "ffffff"], "United States": ["h3", "b22234", "ffffff", "3c3b6e"],
	"Ghana": ["h3", "ce1126", "fcd116", "006b3f"], "Algeria": ["v2", "006233", "ffffff"],
	"Cameroon": ["v3", "007a5e", "ce1126", "fcd116"], "Mali": ["v3", "14b53a", "fcd116", "ce1126"],
	"Australia": ["plain", "00008b", "dot", "ffffff"], "Hungary": ["h3", "cd2a3e", "ffffff", "436f4d"],
	"Bosnia and Herzegovina": ["plain", "002395", "diamond", "fecb00"], "Albania": ["plain", "e41e20", "dot", "111111"],
	"Uruguay": ["h3", "ffffff", "0038a8", "ffffff"], "Romania": ["v3", "002b7f", "fcd116", "ce1126"],
	"Jamaica": ["saltire", "009b3a", "fed100"], "Congo DR": ["plain", "007fff", "dot", "f7d618"],
	"Slovakia": ["h3", "ffffff", "0b4ea2", "ee1c25"], "Colombia": ["h3w", "fcd116", "003893", "ce1126"],
	"Russia": ["h3", "ffffff", "0039a6", "d52b1e"], "Finland": ["nordic", "ffffff", "003580"],
	"Iceland": ["nordic", "02529c", "dc1e35"], "Slovenia": ["h3", "ffffff", "0000ff", "ff0000"],
	"Bulgaria": ["h3", "ffffff", "00966e", "d62612"], "Mexico": ["v3", "006847", "ffffff", "ce1126"],
	"Canada": ["v3", "ff0000", "ffffff", "ff0000"], "Korea Republic": ["plain", "ffffff", "dot", "cd2e3a"],
	"Egypt": ["h3", "ce1126", "ffffff", "111111"], "Tunisia": ["plain", "e70013", "dot", "ffffff"],
	"Ecuador": ["h3w", "ffdd00", "034ea2", "ed1c24"], "Chile": ["h2", "ffffff", "d52b1e"],
	"Paraguay": ["h3", "d52b1e", "ffffff", "0038a8"], "Peru": ["v3", "d91023", "ffffff", "d91023"],
	"Guinea": ["v3", "ce1126", "fcd116", "009460"], "Gabon": ["h3", "009e60", "fcd116", "3a75c4"],
	"Israel": ["h3", "ffffff", "0038b8", "ffffff"], "Kosovo": ["plain", "244aa5", "dot", "d0a650"],
	"Georgia": ["cross", "ffffff", "ff0000"], "Montenegro": ["plain", "c40308", "dot", "d3ae3b"],
	"North Macedonia": ["plain", "d20000", "dot", "ffe600"], "Luxembourg": ["h3", "ed2939", "ffffff", "00a1de"],
	"Azerbaijan": ["h3", "00b5e2", "ef3340", "509e2f"], "Cyprus": ["plain", "ffffff", "dot", "d57800"],
}
var nat := ""


func setup(n: String, w: float):
	nat = n
	custom_minimum_size = Vector2(w, round(w * 0.66))
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw():
	var w = size.x
	var h = size.y
	var f = F.get(nat, null)
	if f == null:
		draw_rect(Rect2(0, 0, w, h), Color("2a3550"))
		draw_rect(Rect2(0, 0, w, h), Color(1, 1, 1, 0.25), false, 1.0)
		return
	var k = f[0]
	var c = []
	for i in range(1, f.size()):
		c.append(f[i])
	if k == "v3":
		for i in 3:
			draw_rect(Rect2(w * i / 3.0, 0, w / 3.0 + 0.5, h), Color(c[i]))
	elif k == "h3":
		for i in 3:
			draw_rect(Rect2(0, h * i / 3.0, w, h / 3.0 + 0.5), Color(c[i]))
	elif k == "h3w":
		draw_rect(Rect2(0, 0, w, h), Color(c[0]))
		draw_rect(Rect2(0, h * 0.25 if nat == "Spain" else h * 0.5, w, h * 0.5 if nat == "Spain" else h * 0.25), Color(c[1]))
		draw_rect(Rect2(0, h * 0.75, w, h * 0.25), Color(c[2]))
	elif k == "h2":
		draw_rect(Rect2(0, 0, w, h * 0.5), Color(c[0]))
		draw_rect(Rect2(0, h * 0.5, w, h * 0.5), Color(c[1]))
	elif k == "v2":
		draw_rect(Rect2(0, 0, w * 0.5, h), Color(c[0]))
		draw_rect(Rect2(w * 0.5, 0, w * 0.5, h), Color(c[1]))
	elif k == "v2p":
		draw_rect(Rect2(0, 0, w * 0.4, h), Color(c[0]))
		draw_rect(Rect2(w * 0.4, 0, w * 0.6, h), Color(c[1]))
		draw_circle(Vector2(w * 0.4, h * 0.5), h * 0.2, Color("ffe000"))
	elif k == "cross":
		draw_rect(Rect2(0, 0, w, h), Color(c[0]))
		draw_rect(Rect2(w * 0.5 - h * 0.1, 0, h * 0.2, h), Color(c[1]))
		draw_rect(Rect2(0, h * 0.4, w, h * 0.2), Color(c[1]))
	elif k == "nordic":
		draw_rect(Rect2(0, 0, w, h), Color(c[0]))
		draw_rect(Rect2(w * 0.3, 0, h * 0.2, h), Color(c[1]))
		draw_rect(Rect2(0, h * 0.4, w, h * 0.2), Color(c[1]))
	elif k == "saltire":
		draw_rect(Rect2(0, 0, w, h), Color(c[0]))
		draw_line(Vector2(0, 0), Vector2(w, h), Color(c[1]), h * 0.18)
		draw_line(Vector2(w, 0), Vector2(0, h), Color(c[1]), h * 0.18)
	else:
		draw_rect(Rect2(0, 0, w, h), Color(c[0]))
	# overlays
	var i = 0
	while i < c.size():
		if c[i] == "dot":
			draw_circle(Vector2(w * 0.5, h * 0.5), h * 0.26, Color(c[i + 1]))
		elif c[i] == "diamond":
			draw_colored_polygon(PackedVector2Array([Vector2(w * 0.5, h * 0.1), Vector2(w * 0.9, h * 0.5), Vector2(w * 0.5, h * 0.9), Vector2(w * 0.1, h * 0.5)]), Color(c[i + 1]))
		elif c[i] == "plus":
			draw_rect(Rect2(w * 0.5 - h * 0.1, h * 0.2, h * 0.2, h * 0.6), Color(c[i + 1]))
			draw_rect(Rect2(w * 0.5 - h * 0.3, h * 0.4, h * 0.6, h * 0.2), Color(c[i + 1]))
		i += 1
	draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0, 0.35), false, 1.0)

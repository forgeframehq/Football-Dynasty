extends "res://scripts/screens/screen.gd"
# Club city: an isometric town built from sprites. Pan, pinch to zoom, tap a facility to upgrade it.

const FILE = {"stadium": "stadium", "training": "training_ground", "academy": "youth_academy", "medical": "medical_centre", "scouting": "scouting_office", "commercial": "commercial_building"}
const PLOT = {"stadium": [2, 2, 2], "commercial": [4, 3, 1], "scouting": [4, 1, 1], "medical": [0, 3, 1], "training": [1, 4, 1], "academy": [0, 4, 1]}
const GRID = 6
const A = 150.0          # half tile width
const B = 96.0           # half tile height (matches the art's 0.64 slope)
const P = 1.16           # plot pitch in tiles (the rest is road)
# filler buildings per town stage (stadium level); used when the city art is present
const TOWN = [["farm_field", "trees", "terraced_houses", "park", "farm_field", "trees"], ["terraced_houses", "semi_detached", "shops", "pub", "park", "trees"],
	["semi_detached", "apartments_low", "shops", "cafe", "supermarket", "park"], ["apartments_low", "apartments_modern", "hotel", "office_block", "supermarket", "cafe"],
	["apartments_modern", "residential_tower", "hotel", "office_block", "apartments_modern", "shops"]]
const SHADER = """
shader_type canvas_item;
uniform vec3 club = vec3(0.2, 0.4, 0.9);
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float mx = max(c.r, max(c.g, c.b));
	float mn = min(c.r, min(c.g, c.b));
	float d = mx - mn;
	float hue = 0.0;
	if (d > 0.0001) {
		if (mx == c.r) { hue = mod((c.g - c.b) / d, 6.0); }
		else if (mx == c.g) { hue = (c.b - c.r) / d + 2.0; }
		else { hue = (c.r - c.g) / d + 4.0; }
	}
	hue *= 60.0;
	float sat = mx > 0.0 ? d / mx : 0.0;
	float m = smoothstep(203.0, 213.0, hue) * (1.0 - smoothstep(244.0, 256.0, hue)) * smoothstep(0.4, 0.56, sat) * smoothstep(0.16, 0.28, mx);
	vec3 t = clamp(club * clamp(mx / 0.8, 0.2, 1.25), 0.0, 1.0);
	COLOR = vec4(mix(c.rgb, t, m), c.a);
}
"""

static var shader_res: Shader = null

var wrap: Control
var world: Control
var zoom := 0.62
var sel := ""
var dragging := false
var moved := 0.0
var touches: Dictionary = {}
var pinch0 := 0.0
var zoom0 := 1.0
var cam := Vector2.ZERO   # world point at the centre of the view
var inited := false


class Ground extends Control:
	var g = 6
	var a = 150.0
	var b = 96.0
	var p = 1.16
	var plots: Dictionary = {}

	func iso(u: float, v: float) -> Vector2:
		return Vector2((u - v) * a, (u + v) * b)

	func quad(u0: float, v0: float, u1: float, v1: float, col: Color):
		draw_colored_polygon(PackedVector2Array([iso(u0, v0), iso(u1, v0), iso(u1, v1), iso(u0, v1)]), col)

	func _draw():
		# the control covers the whole map so it is never culled; draw relative to the map origin
		draw_set_transform(-position)
		var ext = g * p
		quad(-1.6, -1.6, ext + 1.4, ext + 1.4, Color("2f6b45"))
		quad(-0.5, -0.5, ext + 0.34, ext + 0.34, Color("3a7d50"))
		var road = Color("3b4252")
		var rw = p - 1.0
		for k in range(0, g + 1):
			var r0 = k * p - rw
			quad(r0, -rw, r0 + rw, ext, road)
			quad(-rw, r0, ext, r0 + rw, road)
		# lane markings
		for k in range(0, g + 1):
			var m = k * p - rw / 2.0
			var t = -rw
			while t < ext:
				draw_line(iso(m, t), iso(m, t + 0.12), Color(1, 1, 1, 0.28), 2.0)
				draw_line(iso(t, m), iso(t + 0.12, m), Color(1, 1, 1, 0.28), 2.0)
				t += 0.3
		for key in plots:
			var pl = plots[key]
			var n = pl[2]
			var u0 = pl[0] * p
			var v0 = pl[1] * p
			var span = (n - 1) * p + 1.0
			quad(u0, v0, u0 + span, v0 + span, Color("8b8f99") if n > 1 else Color("44895a"))

	static func tree(ci: CanvasItem, at: Vector2, s: float):
		ci.draw_set_transform(at + Vector2(0, 4), 0.0, Vector2(1.0, 0.5))
		ci.draw_circle(Vector2.ZERO, 16 * s, Color(0, 0, 0, 0.22))
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		ci.draw_rect(Rect2(at + Vector2(-2 * s, -14 * s), Vector2(4 * s, 16 * s)), Color("5b4636"))
		ci.draw_circle(at + Vector2(0, -24 * s), 17 * s, Color("2f7a3f"))
		ci.draw_circle(at + Vector2(-5 * s, -30 * s), 11 * s, Color("46a05a"))


class Trees extends Control:
	var seed_v := 1
	var a = 150.0
	var b = 96.0

	func _draw():
		var rng = RandomNumberGenerator.new()
		rng.seed = seed_v
		var off = Vector2(170, 70)
		var pts = []
		for i in 7:
			var u = rng.randf_range(0.12, 0.88)
			var v = rng.randf_range(0.12, 0.88)
			pts.append(Vector2((u - v) * a, (u + v) * b) + off)
		pts.sort_custom(func(x, y): return x.y < y.y)
		for pt in pts:
			Ground.tree(self, pt, rng.randf_range(0.9, 1.5))


func build():
	var c = G.uc()
	G.OPS.ensure(c)
	body.add_child(UI.topbar("Club City", true, UI.chip(G.money(c.budget), Color(UI.GREEN, 0.14), UI.GREEN, 20)))
	UI.main.t_sub = "Stadium %s · drag to move, pinch to zoom, tap a building" % G.OPS._thousands(G.OPS.capacity(c))
	wrap = Control.new()
	wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	wrap.clip_contents = true
	wrap.mouse_filter = Control.MOUSE_FILTER_STOP
	wrap.gui_input.connect(_wrap_input)
	body.add_child(wrap)
	world = Control.new()
	world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(world)
	var ground = Ground.new()
	ground.plots = PLOT
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ground.position = Vector2(-2600, -700)
	ground.size = Vector2(5200, 3200)
	world.add_child(ground)
	if shader_res == null:
		shader_res = Shader.new()
		shader_res.code = SHADER
	var mat = ShaderMaterial.new()
	mat.shader = shader_res
	var cc = Color(c.c1)
	if cc.get_luminance() < 0.06:
		cc = Color(0.14, 0.14, 0.16)
	mat.set_shader_parameter("club", Vector3(cc.r, cc.g, cc.b))
	# collect sprites, then draw back to front
	var items: Array = []
	var taken = {}
	for k in PLOT:
		var pl = PLOT[k]
		for i in pl[2]:
			for j in pl[2]:
				taken[Vector2i(pl[0] + i, pl[1] + j)] = true
		items.append({"k": k, "u": pl[0], "v": pl[1], "n": pl[2], "file": "%s_level_%d" % [FILE[k], c.fac[k]]})
	var stage = clampi(c.fac.stadium, 1, 5) - 1
	for i in GRID:
		for j in GRID:
			if taken.has(Vector2i(i, j)):
				continue
			var h = (i * 7 + j * 13 + c.id * 3) % 6
			var nm = TOWN[stage][h]
			if i == 4 and j == 2:
				nm = "fan_plaza"
			elif (i == 3 and j == 1) or (i == 2 and j == 4):
				nm = "car_park_full" if G.user_fixture_today() != null else "car_park_empty"
			items.append({"k": "", "u": i, "v": j, "n": 1, "file": nm})
	items.sort_custom(func(x, y): return x.u + x.v + x.n * 2 < y.u + y.v + y.n * 2)
	for it in items:
		var span = (it.n - 1) * P + 1.0
		var anchor = ground.iso(it.u * P + span, it.v * P + span)
		var path = "res://assets/iso/%s.png" % it.file
		if ResourceLoader.exists(path):
			var k = span * 2.0 * A / 600.0
			if it.k == "":
				# town buildings sit a little smaller than club facilities
				k *= 0.84
				anchor = ground.iso(it.u * P + 0.5, it.v * P + 0.5) + Vector2(0, B * 0.84)
			var t = TextureRect.new()
			t.texture = load(path)
			t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			t.stretch_mode = TextureRect.STRETCH_SCALE
			t.size = Vector2(640, 640) * k
			t.position = anchor - Vector2(320, 620) * k
			t.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if it.k != "":
				t.material = mat
			world.add_child(t)
		elif it.k == "":
			var tr = Trees.new()
			tr.seed_v = it.u * 31 + it.v * 17 + 5
			tr.position = ground.iso(it.u * P, it.v * P) - Vector2(170, 70)
			tr.size = Vector2(340, 300)
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			world.add_child(tr)
		if it.k != "":
			var top = ground.iso(it.u * P + span * 0.5, it.v * P + span * 0.5)
			world.add_child(_chip(c, it.k, top - Vector2(0, 150 * span if ResourceLoader.exists(path) else 30)))
	# overlay controls
	var zb = UI.vb(8)
	zb.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	zb.grow_vertical = Control.GROW_DIRECTION_BEGIN
	zb.position = Vector2(16, -16)
	for z in [["plus", 1.25], ["minus", 0.8]]:
		var bt = UI.panel(Color("0b111c"), 14, 12, 12, Color(1, 1, 1, 0.16))
		bt.add_child(UI.icon(z[0], 26, UI.TEXT))
		var f = z[1]
		UI.tap(bt, func(): _zoom(zoom * f, wrap.size / 2.0), true)
		zb.add_child(bt)
	wrap.add_child(zb)
	if c.build != null:
		var st = UI.panel(Color("0b111c"), 14, 14, 8, Color(UI.AMBER, 0.6))
		var sh = UI.hb(8)
		sh.add_child(UI.icon("hammer", 22, UI.AMBER))
		sh.add_child(UI.lbl("Building: %s level %d · %d days to go" % [G.OPS.FAC_NAME[c.build.key], c.fac[c.build.key] + 1, max(0, c.build.done - G.s.day)], 19, UI.TEXT, "semi"))
		st.add_child(sh)
		st.position = Vector2(16, 12)
		wrap.add_child(st)
	if sel != "":
		wrap.add_child(_detail(c, sel))
	if not inited:
		inited = true
		cam = ground.iso(3.0 * P, 3.0 * P)
	wrap.resized.connect(_apply)
	_apply.call_deferred()


func _chip(c: Dictionary, k: String, at: Vector2) -> Control:
	var building = c.build != null and c.build.key == k
	var p = UI.panel(Color("0b111c"), 12, 12, 6, Color(UI.AMBER if building else (UI.accent if sel == k else Color(1, 1, 1, 0.25)), 0.9))
	var v = UI.vb(-2)
	var l = UI.lbl(G.OPS.FAC_NAME[k].to_upper(), 20, UI.TEXT, "disp")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	if building:
		var bl = UI.caps("Building · %d days" % max(0, c.build.done - G.s.day), 15, UI.AMBER)
		bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(bl)
	elif k == "stadium":
		var cl = UI.caps(G.OPS._thousands(G.OPS.capacity(c)) + " seats", 15, UI.GOLD)
		cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(cl)
	else:
		var sh = UI.hb(1)
		sh.alignment = BoxContainer.ALIGNMENT_CENTER
		for i in 5:
			sh.add_child(UI.icon("star-f", 14, UI.GOLD if i < c.fac[k] else Color(1, 1, 1, 0.18)))
		v.add_child(sh)
	p.add_child(v)
	p.position = at - Vector2(70, 30)
	p.custom_minimum_size = Vector2(140, 0)
	UI.tap(p, func():
		sel = "" if sel == k else k
		refresh(), true)
	return p


func _detail(c: Dictionary, k: String) -> Control:
	var l = c.fac[k]
	var p = UI.panel(Color("0f1522"), 18, 16, 14, Color(UI.accent, 0.6))
	p.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	p.offset_left = -400
	p.offset_right = -14
	p.offset_top = 12
	p.offset_bottom = -12
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	var v = UI.vb(8)
	p.add_child(UI.scroll(v))
	var head = UI.hb(8)
	head.add_child(UI.lbl_fill(G.OPS.FAC_NAME[k].to_upper(), 28, UI.TEXT, "xbold"))
	var x = UI.panel(Color(1, 1, 1, 0.07), 12, 8, 8)
	x.add_child(UI.icon("x", 22, UI.MUTED))
	UI.tap(x, func():
		sel = ""
		refresh(), true)
	head.add_child(x)
	v.add_child(head)
	var sh = UI.hb(2)
	for i in 5:
		sh.add_child(UI.icon("star-f", 22, UI.GOLD if i < l else Color(1, 1, 1, 0.15)))
	v.add_child(sh)
	var nxt = min(5, l + 1)
	var path = "res://assets/iso/%s_level_%d.png" % [FILE[k], nxt]
	if ResourceLoader.exists(path):
		var t = TextureRect.new()
		t.texture = load(path)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.custom_minimum_size = Vector2(0, 190)
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(t)
		var cap = UI.caps("Level %d" % nxt if l < 5 else "Top level", 16, UI.accent)
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(cap)
	v.add_child(UI.caps("Now · level %d" % l, 16, UI.MUTED))
	v.add_child(UI.wrap(G.OPS.effect_text(k, l), 20, UI.TEXT))
	if l < 5:
		v.add_child(UI.caps("After the upgrade", 16, UI.MUTED))
		v.add_child(UI.wrap(G.OPS.effect_text(k, l + 1), 20, UI.GREEN))
		v.add_child(UI.kv("Cost", G.money(G.OPS.upgrade_cost(c, k))))
		v.add_child(UI.kv("Build time", "%d days" % G.OPS.upgrade_days(c, k)))
		if c.build != null:
			v.add_child(UI.wrap("Builders are busy with the %s (%d days left)." % [G.OPS.FAC_NAME[c.build.key].to_lower(), max(0, c.build.done - G.s.day)], 19, UI.AMBER))
		else:
			v.add_child(UI.btn("Upgrade", func():
				var err = G.OPS.start_upgrade(k)
				if err != "":
					UI.sfx("error", -8.0)
					UI.toast(err, UI.RED)
				else:
					UI.sfx("cash", -8.0)
					UI.toast("Work has started on the %s" % G.OPS.FAC_NAME[k].to_lower(), UI.GREEN)
					refresh(), "primary", "trending-up", 56))
	else:
		v.add_child(UI.wrap("This facility is at the highest level.", 20, UI.GOLD))
	return p


# ---------------------------------------------------------------- camera

func _apply():
	if world == null or not is_instance_valid(world):
		return
	world.scale = Vector2(zoom, zoom)
	var view = wrap.size - Vector2(400 if sel != "" else 0, 0)
	world.position = view / 2.0 - cam * zoom


func _zoom(z: float, about: Vector2):
	var before = (about - world.position) / zoom
	zoom = clamp(z, 0.34, 1.6)
	var view = wrap.size - Vector2(400 if sel != "" else 0, 0)
	cam = before - (about - view / 2.0) / zoom
	_apply()


func _wrap_input(e: InputEvent):
	if e is InputEventMouseButton:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(zoom * 1.1, e.position)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(zoom / 1.1, e.position)
		elif e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				dragging = true
				moved = 0.0
			else:
				if dragging and moved < 14 and touches.size() < 2:
					_tap_world(e.position)
				dragging = false
	elif e is InputEventMouseMotion and dragging and touches.size() < 2:
		moved += e.relative.length()
		cam -= e.relative / zoom
		_apply()
	elif e is InputEventMagnifyGesture:
		_zoom(zoom * e.factor, e.position)


func _input(e: InputEvent):
	if not is_visible_in_tree():
		return
	if e is InputEventScreenTouch:
		if e.pressed:
			touches[e.index] = e.position
		else:
			touches.erase(e.index)
		if touches.size() == 2:
			var pts = touches.values()
			pinch0 = pts[0].distance_to(pts[1])
			zoom0 = zoom
			moved = 99.0
	elif e is InputEventScreenDrag:
		touches[e.index] = e.position
		if touches.size() == 2 and pinch0 > 10:
			var pts = touches.values()
			var mid = (pts[0] + pts[1]) / 2.0 - wrap.global_position
			_zoom(zoom0 * pts[0].distance_to(pts[1]) / pinch0, mid)


func _tap_world(at: Vector2):
	var w = (at - world.position) / zoom
	var u = (w.x / A + w.y / B) / 2.0
	var v = (w.y / B - w.x / A) / 2.0
	for k in PLOT:
		var pl = PLOT[k]
		var span = (pl[2] - 1) * P + 1.0
		# the building rises above its base, so accept a band above it too
		if u >= pl[0] * P - 0.35 and u <= pl[0] * P + span and v >= pl[1] * P - 0.35 and v <= pl[1] * P + span:
			UI.sfx("click", -16.0)
			sel = "" if sel == k else k
			refresh()
			return
	if sel != "":
		sel = ""
		refresh()

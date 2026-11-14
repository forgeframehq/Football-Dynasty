extends "res://scripts/screens/screen.gd"
# Club City in 3D: the stadium in the middle, the club's facilities around it (each grows with its level),
# and the town beyond. Drag to turn the view, pinch or scroll to zoom, tap a facility to open it.
# Built from the Kenney city kits (CC0) and a CC0 stadium model.

const R = "res://assets/city3d/roads/"
const S = "res://assets/city3d/suburban/"
const C = "res://assets/city3d/commercial/"
const N = 13                       # tiles a side
# where each facility sits (tile x, z of its centre) and the buildings it shows as it grows
const SITE = {
	"stadium": Vector2(6, 6),
	"training": Vector2(2, 6),
	"academy": Vector2(2.5, 2.5),
	"medical": Vector2(6, 2),
	"scouting": Vector2(9.5, 2.5),
	"commercial": Vector2(10, 6),
}
const BUILD = {
	"training": ["building-b", "building-c", "building-f"],
	"academy": ["building-a", "building-d", "building-h"],
	"medical": ["building-e", "building-i", "building-j", "building-k", "building-skyscraper-b"],
	"scouting": ["building-g", "building-l", "building-m", "building-n", "building-skyscraper-d"],
	"commercial": ["building-a", "building-c", "building-skyscraper-a", "building-skyscraper-c", "building-skyscraper-e"],
}

static var cache: Dictionary = {}

var svc: SubViewportContainer
var vp: SubViewport
var cam: Camera3D
var yaw := 0.7
var dist := 17.0
var sel := ""
var tags: Dictionary = {}          # facility key -> world position of its label
var touches: Dictionary = {}
var pinch0 := 0.0
var dist0 := 17.0
var moved := 0.0
var overlay: Control


func build():
	title = "Club City"
	chrome = true
	var c = G.uc()
	G.OPS.ensure(c)
	subtitle = "Stadium %s · drag to turn, pinch to zoom, tap a building" % G.OPS._thousands(G.OPS.capacity(c))
	var holder = Control.new()
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	holder.clip_contents = true
	body.add_child(holder)
	svc = SubViewportContainer.new()
	svc.stretch = true
	svc.stretch_shrink = 2 if G.settings.get("lowgfx", false) else 1
	svc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(svc)
	vp = SubViewport.new()
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_DISABLED if G.settings.get("lowgfx", false) else Viewport.MSAA_2X
	svc.add_child(vp)
	_world(c)
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.gui_input.connect(_input_view)
	holder.add_child(overlay)
	# top-left: money and what the builders are doing
	var info = UI.panel(Color(UI.BG, 0.82), 14, 12, 8, UI.LINE)
	info.position = Vector2(14, 10)
	var iv = UI.vb(0)
	iv.add_child(UI.lbl("Budget %s" % G.money(c.budget), 20, UI.GREEN, "semi"))
	if c.build != null:
		iv.add_child(UI.lbl("Building: %s · %d days left" % [G.OPS.FAC_NAME[c.build.key], max(0, c.build.done - G.s.day)], 16, UI.AMBER))
	else:
		iv.add_child(UI.lbl("Builders are free", 16, UI.MUTED))
	info.add_child(iv)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(info)
	var classic = UI.chip("CLASSIC VIEW", Color(UI.BG, 0.82), UI.TEXT, 15, 130)
	classic.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	classic.position = Vector2(14, -44)
	UI.tap(classic, func(): UI.main.root("campus"), true)
	holder.add_child(classic)
	if sel != "":
		holder.add_child(_detail(c, sel))


func _enter_tree():
	UI.enter3d(true)


func _exit_tree():
	UI.enter3d(false)


# ---------------------------------------------------------------- the scene

func _put(path: String, x: float, z: float, rot := 0.0, sc := 1.0) -> Node3D:
	if not cache.has(path):
		cache[path] = load(path) if ResourceLoader.exists(path) else null
	if cache[path] == null:
		return null
	var n: Node3D = cache[path].instantiate()
	n.position = Vector3(x, 0, z)
	n.rotation_degrees.y = rot
	n.scale = Vector3.ONE * sc
	vp.add_child(n)
	return n


func _flat(col: Color, size: Vector2, at: Vector3, tex: Texture2D = null) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var pm = PlaneMesh.new()
	pm.size = size
	mi.mesh = pm
	var m = StandardMaterial3D.new()
	m.albedo_color = col
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if tex != null:
		m.albedo_texture = tex
	mi.material_override = m
	mi.position = at
	vp.add_child(mi)
	return mi


func _tag(key: String, at: Vector3, lvl: int):
	var lb = Label3D.new()
	lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lb.text = "%s\nLEVEL %d" % [G.OPS.FAC_NAME[key].to_upper(), lvl]
	lb.font = UI.fonts["semi"]
	lb.font_size = 44
	lb.fixed_size = true
	lb.pixel_size = 0.00055
	lb.outline_size = 14
	lb.outline_modulate = Color(0, 0, 0, 0.9)
	lb.modulate = UI.GOLD if key == sel else Color.WHITE
	lb.no_depth_test = true
	lb.position = at
	vp.add_child(lb)
	tags[key] = at


func _world(c: Dictionary):
	tags.clear()
	var env = WorldEnvironment.new()
	var e = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = UI.BG.lerp(Color("203050"), 0.5)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color.WHITE
	e.ambient_light_energy = 0.6
	env.environment = e
	vp.add_child(env)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -60, 0)
	sun.light_energy = 1.05
	sun.shadow_enabled = not G.settings.get("lowgfx", false)
	sun.directional_shadow_max_distance = 40.0
	vp.add_child(sun)
	cam = Camera3D.new()
	cam.fov = 32.0
	vp.add_child(cam)
	# ground and roads: a ring road, two avenues either side of the stadium, grass everywhere else
	_flat(Color("3f7d3a"), Vector2(N + 30.0, N + 30.0), Vector3(N / 2.0 - 0.5, -0.02, N / 2.0 - 0.5))
	var road = {}
	for i in N:
		for line in [0, 4, 8, N - 1]:
			road[Vector2i(i, line)] = true
			road[Vector2i(line, i)] = true
	for cell in road:
		var x = cell.x
		var z = cell.y
		var ew = road.has(Vector2i(x - 1, z)) or road.has(Vector2i(x + 1, z))
		var ns = road.has(Vector2i(x, z - 1)) or road.has(Vector2i(x, z + 1))
		var cnt = 0
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if road.has(cell + d):
				cnt += 1
		if cnt >= 3:
			_put(R + "road-crossroad.glb", x, z)
		elif ew and ns:
			var rot = 0.0
			if road.has(Vector2i(x + 1, z)) and road.has(Vector2i(x, z + 1)):
				rot = 180.0
			elif road.has(Vector2i(x - 1, z)) and road.has(Vector2i(x, z + 1)):
				rot = 270.0
			elif road.has(Vector2i(x + 1, z)) and road.has(Vector2i(x, z - 1)):
				rot = 90.0
			_put(R + "road-bend.glb", x, z, rot)
		else:
			_put(R + "road-straight.glb", x, z, 0.0 if ew else 90.0)
	# the stadium, larger with every level
	var sl = int(c.fac.stadium)
	var st = _put("res://assets/city3d/stadium/Fst_Eng_001.FBX", 6, 6)
	if st != null:
		var bb = _aabb(st)
		var k = (2.3 + 0.16 * sl) / max(1.0, bb.size.x) * 1.25
		st.scale = Vector3.ONE * k
		st.position.y = 0.02 - (bb.position.y + 0.66375 * bb.size.y) * k
	_tag("stadium", Vector3(6, 2.3, 6), sl)
	# the other facilities: one more building per level; training and academy also get pitches
	var grass: Texture2D = load("res://assets/m3d/pitch.jpg")
	for key in BUILD:
		var at: Vector2 = SITE[key]
		var lvl = int(c.fac[key])
		var names: Array = BUILD[key]
		var shown = min(lvl, names.size())
		if key in ["training", "academy"]:
			shown = min(1 + int(lvl / 2), names.size())
			var pitches = lvl if key == "training" else int((lvl + 1) / 2)
			for i in pitches:
				_flat(Color.WHITE, Vector2(1.15, 0.78), Vector3(at.x - 0.6 + (i % 2) * 1.25, 0.03, at.y - 1.0 + int(i / 2) * 0.9), grass)
		for i in shown:
			var px = at.x - 0.55 * (shown - 1) + i * 1.1
			var pz = at.y + (0.95 if key in ["training", "academy"] else 0.0)
			if key == "commercial" or key == "training":
				px = at.x + (0.2 if key == "commercial" else 0.0)
				pz = at.y - 0.55 * (shown - 1) + i * 1.1 + (0.0 if key == "commercial" else 0.0)
				if key == "training":
					px = at.x - 1.3
			_put(C + names[i] + ".glb", px, pz, 90.0 if key in ["commercial", "training"] else 0.0, 0.62)
		if c.build != null and c.build.key == key:
			var sc = MeshInstance3D.new()
			var bm = BoxMesh.new()
			bm.size = Vector3(0.9, 1.0, 0.9)
			sc.mesh = bm
			var m = StandardMaterial3D.new()
			m.albedo_color = Color(1.0, 0.78, 0.2, 0.55)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			sc.material_override = m
			sc.position = Vector3(at.x, 0.5, at.y - 0.2)
			vp.add_child(sc)
		_tag(key, Vector3(at.x, 1.9, at.y), lvl)
	# the town: houses and trees on the outer blocks, thicker as the club's commercial side grows
	var rng = RandomNumberGenerator.new()
	rng.seed = c.id * 7 + 3
	var houses = "abcdefgh"
	var dens = 0.5 + 0.08 * int(c.fac.commercial)
	for x in range(1, N - 1):
		for z in range(1, N - 1):
			if road.has(Vector2i(x, z)):
				continue
			var busy = false
			for key in SITE:
				if abs(SITE[key].x - x) < (2.6 if key == "stadium" else 1.9) and abs(SITE[key].y - z) < (2.6 if key == "stadium" else 1.9):
					busy = true
			if busy:
				continue
			var r = rng.randf()
			if r < dens * 0.7:
				_put(S + "building-type-%s.glb" % houses[rng.randi() % 8], x, z, 90.0 * (rng.randi() % 4), 0.7)
			elif r < dens * 0.7 + 0.25:
				_put(S + ("tree-large.glb" if rng.randf() < 0.6 else "tree-small.glb"), x + rng.randf_range(-0.2, 0.2), z + rng.randf_range(-0.2, 0.2), 0.0, 1.0)
	_aim()


func _aabb(n: Node, xf := Transform3D()) -> AABB:
	var out = AABB()
	var first = true
	var stack = [[n, xf]]
	while not stack.is_empty():
		var it = stack.pop_back()
		var t: Transform3D = it[1]
		if it[0] != n and it[0] is Node3D:
			t = t * it[0].transform
		if it[0] is MeshInstance3D and it[0].mesh != null:
			var bb = t * it[0].mesh.get_aabb()
			out = bb if first else out.merge(bb)
			first = false
		for ch in it[0].get_children():
			stack.append([ch, t])
	return out


func _aim():
	if cam == null:
		return
	var centre = Vector3(N / 2.0 - 0.5, 0.4, N / 2.0 - 0.5)
	cam.position = centre + Vector3(sin(yaw), 0.72, cos(yaw)).normalized() * dist
	cam.look_at(centre)


# ---------------------------------------------------------------- input

func _input_view(e: InputEvent):
	if e is InputEventScreenTouch:
		if e.pressed:
			touches[e.index] = e.position
			moved = 0.0
			if touches.size() == 2:
				var p = touches.values()
				pinch0 = p[0].distance_to(p[1])
				dist0 = dist
		else:
			touches.erase(e.index)
			if moved < 12.0 and touches.is_empty():
				_tap(e.position)
	elif e is InputEventScreenDrag:
		touches[e.index] = e.position
		moved += e.relative.length()
		if touches.size() >= 2:
			var p2 = touches.values()
			if pinch0 > 10.0:
				dist = clamp(dist0 * pinch0 / max(10.0, p2[0].distance_to(p2[1])), 7.0, 26.0)
		else:
			yaw -= e.relative.x * 0.006
		_aim()
	elif e is InputEventMouseButton:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP:
			dist = max(7.0, dist - 1.0)
			_aim()
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			dist = min(26.0, dist + 1.0)
			_aim()
		elif e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				moved = 0.0
			elif moved < 12.0 and not DisplayServer.is_touchscreen_available():
				_tap(e.position)
	elif e is InputEventMouseMotion and e.button_mask & MOUSE_BUTTON_MASK_LEFT and not DisplayServer.is_touchscreen_available():
		moved += e.relative.length()
		yaw -= e.relative.x * 0.006
		_aim()


func _tap(at: Vector2):
	# the facility whose label is nearest the tap
	var best = ""
	var bd = 90.0
	var k = float(svc.stretch_shrink)
	for key in tags:
		if cam.is_position_behind(tags[key]):
			continue
		var sp = cam.unproject_position(tags[key] - Vector3(0, 0.9, 0)) * k
		var d = sp.distance_to(at)
		if d < bd:
			bd = d
			best = key
	if best != sel:
		sel = best
		UI.sfx("click", -14.0)
		refresh()


func _detail(c: Dictionary, k: String) -> Control:
	var l = int(c.fac[k])
	var p = UI.panel(UI.BG2, 18, 16, 12, Color(UI.accent, 0.6))
	p.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	p.offset_left = -390
	p.offset_right = -12
	p.offset_top = 10
	p.offset_bottom = -10
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	var v = UI.vb(6)
	p.add_child(v)
	var head = UI.hb(8)
	head.add_child(UI.lbl_fill(G.OPS.FAC_NAME[k].to_upper(), 26, UI.TEXT, "xbold"))
	var x = UI.panel(Color(1, 1, 1, 0.07), 12, 8, 8)
	x.add_child(UI.icon("x", 22, UI.MUTED))
	UI.tap(x, func():
		sel = ""
		refresh(), true)
	head.add_child(x)
	v.add_child(head)
	var sh = UI.hb(2)
	for i in 5:
		sh.add_child(UI.icon("star-f", 20, UI.GOLD if i < l else Color(1, 1, 1, 0.15)))
	v.add_child(sh)
	v.add_child(UI.caps("Now · level %d" % l, 15, UI.MUTED))
	v.add_child(UI.wrap(G.OPS.effect_text(k, l), 19, UI.TEXT))
	if l < 5:
		v.add_child(UI.caps("After the upgrade", 15, UI.MUTED))
		v.add_child(UI.wrap(G.OPS.effect_text(k, l + 1), 19, UI.GREEN))
		v.add_child(UI.kv("Cost", G.money(G.OPS.upgrade_cost(c, k))))
		v.add_child(UI.kv("Build time", "%d days" % G.OPS.upgrade_days(c, k)))
		if c.build != null:
			v.add_child(UI.wrap("Builders are busy with the %s (%d days left)." % [G.OPS.FAC_NAME[c.build.key].to_lower(), max(0, c.build.done - G.s.day)], 18, UI.AMBER))
		else:
			v.add_child(UI.btn("Upgrade", func():
				var err = G.OPS.start_upgrade(k)
				if err != "":
					UI.sfx("error", -8.0)
					UI.toast(err, UI.RED)
				else:
					UI.sfx("build", -6.0)
					UI.toast("Work has started on the %s" % G.OPS.FAC_NAME[k].to_lower(), UI.GREEN)
					refresh(), "primary", "trending-up", 54))
	else:
		v.add_child(UI.wrap("This facility is at the highest level.", 19, UI.GOLD))
	return p

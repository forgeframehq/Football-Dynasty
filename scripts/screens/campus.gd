extends "res://scripts/screens/screen.gd"
# Club campus: a 3D view of the stadium and facilities that grows as they are upgraded.

const MODEL_FILE = {"stadium": "stadium", "training": "training_ground", "academy": "youth_academy", "medical": "medical_centre", "scouting": "scouting_office", "commercial": "commercial_building"}
const SPOT = {"stadium": Vector3(0, 0, -105), "training": Vector3(74, 0, 78), "academy": Vector3(-82, 0, 70), "medical": Vector3(-88, 0, 205), "scouting": Vector3(0, 0, 250), "commercial": Vector3(88, 0, 205)}
const MODEL_SCALE = {"stadium": 1.0, "training": 0.5, "academy": 0.62, "medical": 1.45, "scouting": 1.6, "commercial": 1.2}

static var mesh_cache: Dictionary = {}

var cam: Camera3D
var view: SubViewportContainer
var chips: Dictionary = {}


func build():
	var c = G.uc()
	G.OPS.ensure(c)
	body.add_child(UI.topbar("Club", true, UI.chip(G.money(c.budget), Color(UI.GREEN, 0.14), UI.GREEN, 22)))
	view = SubViewportContainer.new()
	view.stretch = true
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vp = SubViewport.new()
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_2X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	view.add_child(vp)
	vp.add_child(_world(c))
	var wrap = Control.new()
	wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.clip_contents = true
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrap.add_child(view)
	body.add_child(wrap)
	chips = {}
	for k in G.OPS.FAC:
		var ch = _chip(c, k)
		wrap.add_child(ch)
		chips[k] = ch
	# footer: construction status
	var foot = UI.panel(UI.CARD, 22, 20, 14, UI.LINE)
	var fh = UI.hb(12)
	if c.build != null:
		fh.add_child(UI.icon("clock", 28, UI.AMBER))
		var fv = UI.vb(0)
		fv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fv.add_child(UI.lbl("Building: %s level %d" % [G.OPS.FAC_NAME[c.build.key], c.fac[c.build.key] + 1], 25, UI.TEXT, "semi"))
		fv.add_child(UI.lbl("%d days to go" % max(0, c.build.done - G.s.day), 20, UI.MUTED))
		fh.add_child(fv)
	else:
		fh.add_child(UI.icon("sparkles", 28, UI.accent))
		fh.add_child(UI.wrap("Tap a facility to upgrade it. One project can be built at a time.", 22, UI.MUTED))
	foot.add_child(fh)
	body.add_child(UI.margin(foot, 20, 10, 20, 16))
	_place.call_deferred()
	wrap.resized.connect(_place)


func _chip(c: Dictionary, k: String) -> Control:
	var l = c.fac[k]
	var building = c.build != null and c.build.key == k
	var p = UI.panel(Color("0b111cee"), 14, 12, 8, UI.AMBER if building else Color(1, 1, 1, 0.25))
	var h = UI.hb(8)
	h.add_child(UI.icon(G.OPS.FAC_ICON[k], 24, UI.AMBER if building else UI.accent))
	var v = UI.vb(-2)
	v.add_child(UI.lbl(G.OPS.FAC_NAME[k].to_upper(), 19, UI.TEXT, "disp"))
	if k == "stadium":
		v.add_child(UI.lbl(G.OPS._thousands(G.OPS.capacity(c)), 17, UI.GOLD, "semi"))
	else:
		var sh = UI.hb(1)
		for i in 5:
			sh.add_child(UI.icon("star-f", 14, UI.GOLD if i < l else Color(1, 1, 1, 0.15)))
		v.add_child(sh)
	h.add_child(v)
	p.add_child(h)
	UI.tap(p, func(): _sheet(k), true)
	return p


func _place():
	if cam == null or not is_instance_valid(cam) or view == null:
		return
	await get_tree().process_frame
	if not is_instance_valid(view):
		return
	for k in chips:
		var ch = chips[k]
		var wp = SPOT[k] + Vector3(0, 46 if k == "stadium" else 30, 0)
		var sp = cam.unproject_position(wp)
		ch.reset_size()
		ch.position = Vector2(clamp(sp.x - ch.size.x / 2.0, 6, view.size.x - ch.size.x - 6), clamp(sp.y - ch.size.y, 6, view.size.y - ch.size.y - 6))


func _sheet(k: String):
	var c = G.uc()
	var l = c.fac[k]
	var build_sheet = func(v):
		var sh = UI.hb(2)
		for i in 5:
			sh.add_child(UI.icon("star-f", 26, UI.GOLD if i < l else Color(1, 1, 1, 0.15)))
		v.add_child(sh)
		v.add_child(UI.kv("Now (level %d)" % l, G.OPS.effect_text(k, l)))
		if l < 5:
			v.add_child(UI.kv("Level %d" % (l + 1), G.OPS.effect_text(k, l + 1), UI.GREEN))
			v.add_child(UI.kv("Cost", G.money(G.OPS.upgrade_cost(c, k))))
			v.add_child(UI.kv("Build time", "%d days" % G.OPS.upgrade_days(c, k)))
			v.add_child(UI.sp(0, 4))
			if c.build != null:
				v.add_child(UI.wrap("Builders are busy with the %s (%d days left)." % [G.OPS.FAC_NAME[c.build.key].to_lower(), max(0, c.build.done - G.s.day)], 22, UI.AMBER))
			else:
				v.add_child(UI.btn("Upgrade for %s" % G.money(G.OPS.upgrade_cost(c, k)), func():
					var err = G.OPS.start_upgrade(k)
					UI.close_sheet()
					if err != "":
						UI.toast(err, UI.RED)
					else:
						UI.toast("Work has started on the %s" % G.OPS.FAC_NAME[k].to_lower(), UI.GREEN)
						refresh(), "primary", "trending-up"))
		else:
			v.add_child(UI.wrap("This facility is at the highest level.", 22, UI.GOLD))
	UI.sheet(G.OPS.FAC_NAME[k], build_sheet)


# ---------------------------------------------------------------- 3D world

func _mat(col: Color, rough := 0.9) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	return m


func _box(parent: Node3D, size: Vector3, pos: Vector3, col: Color) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var b = BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.material_override = _mat(col)
	mi.position = pos + Vector3(0, size.y / 2.0, 0)
	parent.add_child(mi)
	return mi


func _world(c: Dictionary) -> Node3D:
	var root = Node3D.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("16281f")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("cfd8ff")
	env.ambient_light_energy = 0.5
	var we = WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, 38, 0)
	sun.light_energy = 0.95
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 900
	root.add_child(sun)
	cam = Camera3D.new()
	cam.fov = 36
	cam.far = 3000
	root.add_child(cam)
	cam.look_at_from_position(Vector3(0, 610, 600), Vector3(0, 0, 76), Vector3.UP)
	_box(root, Vector3(1600, 2, 1600), Vector3(0, -2.2, 0), Color("1c3526"))
	_box(root, Vector3(900, 1, 1100), Vector3(0, -1.2, 70), Color("2a5237"))
	# roads
	for r in [[Vector3(14, 0.4, 1100), Vector3(-8, -0.3, 70)], [Vector3(900, 0.4, 12), Vector3(0, -0.3, 150)], [Vector3(900, 0.4, 12), Vector3(0, -0.3, 8)]]:
		_box(root, r[0], r[1], Color("3a4150"))
	var c1 = Color(c.c1)
	var c2 = Color(c.c2)
	for k in G.OPS.FAC:
		var l = c.fac[k]
		var node = _model(k, l, c1, c2)
		if node == null:
			node = _generated(k, l, c1, c2)
		node.position = SPOT[k]
		root.add_child(node)
		if c.build != null and c.build.key == k:
			# crane marks the building site
			var crane = Node3D.new()
			_box(crane, Vector3(2, 46, 2), Vector3.ZERO, Color("f6ad3c"))
			_box(crane, Vector3(34, 2, 2), Vector3(12, 44, 0), Color("f6ad3c"))
			crane.position = SPOT[k] + Vector3(38 if k != "stadium" else 80, 0, 30)
			root.add_child(crane)
	# trees
	var rng = RandomNumberGenerator.new()
	rng.seed = 7 + c.id
	var cone = CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 5.0
	cone.height = 13.0
	cone.radial_segments = 6
	var tm = [_mat(Color("24633a")), _mat(Color("2c7445")), _mat(Color("1e5231"))]
	for i in 90:
		var p = Vector3(rng.randf_range(-230, 230), 0, rng.randf_range(-260, 400))
		var ok = true
		for k in SPOT:
			var d = Vector2(p.x - SPOT[k].x, p.z - SPOT[k].z)
			if abs(d.x) < (118 if k == "stadium" else 50) and abs(d.y) < (96 if k == "stadium" else 44):
				ok = false
		if not ok or abs(p.x + 8) < 14 or abs(p.z - 150) < 12 or abs(p.z - 8) < 12:
			continue
		var t = MeshInstance3D.new()
		t.mesh = cone
		t.material_override = tm[i % 3]
		var sc = rng.randf_range(0.7, 1.3)
		t.scale = Vector3(sc, sc, sc)
		t.position = p + Vector3(0, 6.5 * sc, 0)
		root.add_child(t)
	return root


func _model(k: String, l: int, c1: Color, c2: Color) -> Node3D:
	var path = "res://assets/models/%s_level_%d.glb" % [MODEL_FILE[k], l]
	if not ResourceLoader.exists(path):
		return null
	var scene = load(path)
	if scene == null:
		return null
	var inst = scene.instantiate()
	var holder = Node3D.new()
	holder.add_child(inst)
	inst.rotation_degrees.x = -90
	var sc = MODEL_SCALE[k]
	holder.scale = Vector3(sc, sc, sc)
	var seat1 = c1 if c1.get_luminance() < 0.85 else c2
	var seat2 = c2 if _far(c2, seat1) and c2.get_luminance() < 0.9 else seat1.darkened(0.3)
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		var key = path + ":" + mi.name
		if not mesh_cache.has(key):
			var st = SurfaceTool.new()
			st.create_from(mi.mesh, 0)
			st.deindex()
			st.generate_normals()
			mesh_cache[key] = st.commit()
		mi.mesh = mesh_cache[key]
		var m = StandardMaterial3D.new()
		m.roughness = 0.9
		var nm = String(mi.name).to_lower()
		if nm.begins_with("blue2"):
			m.albedo_color = seat2
		elif nm.begins_with("blue"):
			m.albedo_color = seat1
		elif nm.begins_with("glass"):
			m.albedo_color = Color("7fb6d9")
			m.roughness = 0.2
			m.metallic = 0.3
		elif nm.begins_with("light") or nm.begins_with("rooflight"):
			m.albedo_color = Color("fff6cf")
			m.emission_enabled = true
			m.emission = Color("fff1b0")
			m.emission_energy_multiplier = 0.6
		else:
			m.vertex_color_use_as_albedo = true
			m.vertex_color_is_srgb = true
		mi.material_override = m
	return holder


func _far(a: Color, b: Color) -> bool:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length() > 0.3


func _generated(k: String, l: int, c1: Color, c2: Color) -> Node3D:
	# simple code-built stand-ins until model files exist for this facility
	var n = Node3D.new()
	var tint = c1 if c1.get_luminance() < 0.85 else c2
	n.scale = Vector3(0.78, 0.78, 0.78)
	_box(n, Vector3(96, 0.8, 80), Vector3(0, -0.4, 0), Color("353d4c"))
	match k:
		"academy":
			_box(n, Vector3(50, 0.6, 34), Vector3(-18, 0.4, 16), Color("3f9a57"))
			_box(n, Vector3(30 + l * 7, 7 + l * 2.5, 20), Vector3(14, 0.4, -18), Color("b9c2d0"))
			_box(n, Vector3(32 + l * 7, 1.5, 22), Vector3(14, 7.4 + l * 2.5, -18), tint)
			if l >= 3:
				_box(n, Vector3(30, 0.6, 22), Vector3(26, 0.4, 20), Color("46a860"))
		"medical":
			var h = 9 + l * 4.0
			_box(n, Vector3(34 + l * 6, h, 28), Vector3(0, 0.4, 0), Color("c5ccd8"))
			_box(n, Vector3(16, 1.2, 4.5), Vector3(0, h + 0.5, 0), Color("e23b4a"))
			_box(n, Vector3(4.5, 1.2, 16), Vector3(0, h + 0.5, 0), Color("e23b4a"))
			if l >= 4:
				_box(n, Vector3(20, h * 0.6, 20), Vector3(34, 0.4, 14), Color("aab3c2"))
		"scouting":
			_box(n, Vector3(30 + l * 4, 8 + l * 3.0, 24), Vector3(0, 0.4, 0), Color("2b3650"))
			_box(n, Vector3(31 + l * 4, 1.2, 25), Vector3(0, 8.4 + l * 3.0, 0), tint)
			var mast = _box(n, Vector3(1.6, 14 + l * 4.0, 1.6), Vector3(10, 8 + l * 3.0, 0), Color("c9d2e0"))
			mast.name = "mast"
		"commercial":
			for i in min(l, 3):
				var h = 22 + l * 9.0 - i * 10.0
				_box(n, Vector3(20, h, 20), Vector3(-26 + i * 26, 0.4, 0), Color("4f86b8") if i % 2 == 0 else Color("3a668f"))
				_box(n, Vector3(21, 1.4, 21), Vector3(-26 + i * 26, h + 0.4, 0), tint)
		_:
			_box(n, Vector3(60, 0.6, 40), Vector3(0, 0.4, 0), Color("3f9a57"))
			_box(n, Vector3(20 + l * 6, 6 + l * 2.0, 14), Vector3(0, 0.4, -30), Color("e7ebf2"))
	return n

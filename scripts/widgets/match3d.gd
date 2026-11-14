extends SubViewportContainer
# The 3D match view: a pitch inside a small stadium, 22 kit-coloured figures and a ball, seen from a raised
# broadcast angle. The match engine decides what happens; this view shows it. In open play the teams hold
# their shape and shift with the ball. Each chance is played out as a short staged move (pass, shot, outcome).

signal impact          # the moment a staged shot reaches its outcome (score, sounds and commentary land here)
signal seq_done        # the staged move, including any celebration, is over

const L := 105.0
const W := 68.0
const FIG := 2.9       # figures are drawn larger than life so they read on a phone

var sim = null
var vp: SubViewport
var cam: Camera3D
var cam_x := 0.0
var cols: Array = [Color.WHITE, Color.RED]
var cols2: Array = [Color.BLACK, Color.WHITE]
var figs: Array = [[], []]        # per side: 11 dictionaries (node, parts, pos, vel, phase, label)
var ball: MeshInstance3D
var ball_sh: MeshInstance3D
var bpos := Vector3(0.5, 0.0, 0.5)     # u (along), height in metres, v (across)
var carrier := Vector2i(-1, -1)
var name_l: Label3D
var t := 0.0
var seq = null
var low := false
const PM = preload("res://scripts/widgets/player_mesh.gd")
const RIG = preload("res://assets/m3d/rig.scn")
static var lib: AnimationLibrary = null
var fig_mat: Material = null
var tiers: Array = []      # crowd sections, for the bounce when a goal goes in
var bounce := 0.0
var kits: Array = []       # set by the match screen before setup: what each side wears


func setup(s, home_col: Color, away_col: Color, home_2: Color, away_2: Color):
	sim = s
	cols = [home_col, away_col]
	cols2 = [home_2, away_2]
	stretch = true
	low = bool(G.settings.get("lowgfx", false))
	stretch_shrink = 2 if low else 1
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	vp = SubViewport.new()
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_DISABLED if low else Viewport.MSAA_2X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	_build_world()
	for i in 2:
		for k in 11:
			figs[i].append(_figure(i, k))
	_snap_shape()


func _enter_tree():
	UI.enter3d(true)


func _exit_tree():
	UI.enter3d(false)


# ---------------------------------------------------------------- world

func _mat(col: Color, tex: Texture2D = null, unshaded := false) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = col
	if tex != null:
		m.albedo_texture = tex
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.roughness = 1.0
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return m


func _box(size: Vector3, pos: Vector3, mat: Material, parent: Node = null) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	(parent if parent != null else vp).add_child(mi)
	return mi


func _build_world():
	var env = WorldEnvironment.new()
	var e = Environment.new()
	e.background_mode = Environment.BG_COLOR
	var wk = str(sim.wx.get("k", "clear"))
	var dd = G.date(int(sim.fx.get("day", G.s.day)))
	var night = dd.weekday in [2, 3] or dd.month in [11, 12, 1]
	var dull = wk in ["rain", "heavy", "snow", "cloud", "wind"]
	e.background_color = Color("0a0f1c") if night else (Color("6f7f95") if dull else Color("7fb0e8"))
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(1, 1, 1)
	e.ambient_light_energy = 1.0 if not dull else 0.92
	env.environment = e
	vp.add_child(env)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-58, 35, 0)
	sun.light_energy = 0.75 if dull or night else 1.05
	sun.light_color = Color("eef2ff") if night else Color("fff6e4")
	sun.shadow_enabled = false
	vp.add_child(sun)
	cam = Camera3D.new()
	cam.fov = 24.0
	cam.far = 600.0
	vp.add_child(cam)
	# pitch: one textured plane (grass, stripes and markings are in the texture, 7 m of grass all round)
	var pm = MeshInstance3D.new()
	var pl = PlaneMesh.new()
	pl.size = Vector2(L + 14.0, W + 14.0)
	pm.mesh = pl
	var ptint = Color(1.0, 1.0, 1.0)
	if wk == "snow":
		ptint = Color(1.25, 1.3, 1.35)
	elif wk in ["rain", "heavy"]:
		ptint = Color(0.9, 0.96, 0.92)
	elif night:
		ptint = Color(0.96, 1.0, 0.98)
	pm.material_override = _mat(ptint, load("res://assets/m3d/pitch.jpg"), true)
	vp.add_child(pm)
	# surround
	var apron = MeshInstance3D.new()
	var ap = PlaneMesh.new()
	ap.size = Vector2(L + 90.0, W + 90.0)
	apron.mesh = ap
	apron.position.y = -0.05
	apron.material_override = _mat(Color("2b3a2e"), null, true)
	vp.add_child(apron)
	# stands on the far side and behind both goals (the near side is left open for the camera)
	var crowd: Texture2D = load("res://assets/m3d/crowd.jpg")
	var home_tint = cols[0].lerp(Color.WHITE, 0.55)
	for st in [[Vector3(0, 0, -(W / 2 + 13.0)), L + 30.0, 0.0], [Vector3(-(L / 2 + 13.0), 0, 0), W + 8.0, 90.0], [Vector3(L / 2 + 13.0, 0, 0), W + 8.0, -90.0]]:
		var holder = Node3D.new()
		holder.position = st[0]
		holder.rotation_degrees.y = st[2]
		vp.add_child(holder)
		var cm = _mat(home_tint, crowd)
		cm.uv1_scale = Vector3(st[1] / 16.0, 1.0, 1.0)
		var tier = MeshInstance3D.new()
		var q = QuadMesh.new()
		q.size = Vector2(st[1], 13.0)
		tier.mesh = q
		tier.material_override = cm
		tier.rotation_degrees.x = -52.0
		tier.position = Vector3(0, 5.2, -2.0)
		holder.add_child(tier)
		tiers.append([tier, 5.2])
		# upper tier, set back and steeper
		var up = MeshInstance3D.new()
		var uq = QuadMesh.new()
		uq.size = Vector2(st[1] + 2.0, 10.0)
		up.mesh = uq
		var um = _mat(home_tint.darkened(0.12), crowd)
		um.uv1_scale = Vector3((st[1] + 2.0) / 16.0, 0.8, 1.0)
		up.material_override = um
		up.rotation_degrees.x = -40.0
		up.position = Vector3(0, 15.6, -12.4)
		holder.add_child(up)
		tiers.append([up, 15.6])
		_box(Vector3(st[1] + 2.0, 1.0, 0.5), Vector3(0, 12.2, -8.9), _mat(cols[0].darkened(0.1)), holder)
		_box(Vector3(st[1] + 4.0, 0.5, 10.0), Vector3(0, 20.6, -14.0), _mat(Color("30343f")), holder)
		_box(Vector3(st[1] + 4.0, 21.0, 0.6), Vector3(0, 10.5, -18.4), _mat(Color("171a22")), holder)
		_box(Vector3(st[1], 1.2, 0.4), Vector3(0, 0.6, 2.2), _mat(cols[0].darkened(0.25)), holder)
		_box(Vector3(st[1] + 2.0, 0.5, 9.0), Vector3(0, 11.6, -5.2), _mat(Color("3a3f4b")), holder)
		_box(Vector3(st[1] + 2.0, 11.6, 0.6), Vector3(0, 5.8, -9.4), _mat(Color("1b1e26")), holder)
	# advertising boards along the far touchline
	var ad = Label3D.new()
	ad.text = "FOOTBALL DYNASTY 26      ·      %s      ·      FOOTBALL DYNASTY 26" % sim.sd[0].club.name.to_upper()
	ad.font = UI.fonts["xbold"]
	ad.font_size = 96
	ad.pixel_size = 0.011
	ad.modulate = Color.WHITE
	ad.outline_size = 0
	ad.position = Vector3(0, 0.62, -(W / 2 + 4.4))
	vp.add_child(ad)
	_box(Vector3(L + 8.0, 1.1, 0.2), Vector3(0, 0.55, -(W / 2 + 4.55)), _mat(cols[0].darkened(0.45)))
	# goals
	var white = _mat(Color.WHITE, null, true)
	var netm = _mat(Color.WHITE, load("res://assets/m3d/net.png"), true)
	netm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	netm.cull_mode = BaseMaterial3D.CULL_DISABLED
	netm.uv1_scale = Vector3(1, 1, 1)
	netm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var grey = _mat(Color("c9ccd2"), null, true)
	for sg in [-1.0, 1.0]:
		var gx = sg * L / 2
		# frame: posts, bar, and the stanchions that hold the net back
		for pz in [-3.66, 3.66]:
			_box(Vector3(0.2, 2.44, 0.2), Vector3(gx, 1.22, pz), white)
			_box(Vector3(0.09, 0.09, 0.09), Vector3(gx + sg * 2.3, 0.05, pz), grey)
			var stn = _box(Vector3(1.5, 0.07, 0.07), Vector3(gx + sg * 0.72, 2.44, pz), grey)
			var bk = _box(Vector3(0.07, 2.75, 0.07), Vector3(gx + sg * 1.9, 1.22, pz), grey)
			bk.rotation.z = sg * 0.33
		_box(Vector3(0.2, 0.2, 7.52), Vector3(gx, 2.44, 0), white)
		_box(Vector3(0.07, 0.07, 7.32), Vector3(gx + sg * 1.45, 2.44, 0), grey)
		_box(Vector3(0.07, 0.07, 7.32), Vector3(gx + sg * 2.3, 0.05, 0), grey)
		# net: flat top, back sloping down to the ground, and two sides
		var x0 = gx + sg * 0.05
		var x1 = gx + sg * 1.45
		var x2 = gx + sg * 2.3
		_net([Vector3(x0, 2.44, -3.66), Vector3(x0, 2.44, 3.66), Vector3(x1, 2.44, 3.66), Vector3(x1, 2.44, -3.66)], netm)
		_net([Vector3(x1, 2.44, -3.66), Vector3(x1, 2.44, 3.66), Vector3(x2, 0.0, 3.66), Vector3(x2, 0.0, -3.66)], netm)
		for pz in [-3.66, 3.66]:
			_net([Vector3(x0, 0.0, pz), Vector3(x0, 2.44, pz), Vector3(x1, 2.44, pz), Vector3(x2, 0.0, pz)], netm)
	# corner flags and floodlights
	var flagm = _mat(Color("f6c945"), null, true)
	for cx in [-1.0, 1.0]:
		for cz in [-1.0, 1.0]:
			_box(Vector3(0.08, 1.6, 0.08), Vector3(cx * L / 2, 0.8, cz * W / 2), white)
			_box(Vector3(0.5, 0.34, 0.04), Vector3(cx * L / 2 + 0.27, 1.42, cz * W / 2), flagm)
		_box(Vector3(0.9, 30.0, 0.9), Vector3(cx * (L / 2 + 24.0), 15.0, -(W / 2 + 24.0)), _mat(Color("2a2e38")))
		_box(Vector3(7.0, 3.6, 0.6), Vector3(cx * (L / 2 + 24.0), 31.0, -(W / 2 + 23.6)), _mat(Color("fffbe8") if night or dull else Color("9aa0ad"), null, true))
	# dugouts on the far touchline
	for dx in [-12.0, 12.0]:
		_box(Vector3(9.0, 1.5, 1.6), Vector3(dx, 0.75, -(W / 2 + 2.6)), _mat(Color("20242e")))
		_box(Vector3(9.2, 0.2, 2.2), Vector3(dx, 1.6, -(W / 2 + 2.4)), _mat(cols[0 if dx < 0 else 1].darkened(0.2)))
	_weather(wk)
	# ball and its shadow
	ball = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = 0.42
	sm.height = 0.84
	sm.radial_segments = 10
	sm.rings = 5
	ball.mesh = sm
	ball.material_override = _mat(Color("fff8d0"), null, true)
	vp.add_child(ball)
	ball_sh = _blob(1.3)
	vp.add_child(ball_sh)
	name_l = Label3D.new()
	name_l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_l.font = UI.fonts["semi"]
	name_l.font_size = 44
	name_l.pixel_size = 0.03
	name_l.outline_size = 10
	name_l.outline_modulate = Color(0, 0, 0, 0.85)
	name_l.no_depth_test = true
	name_l.visible = false
	vp.add_child(name_l)


func _net(p: Array, mat: Material):
	# one net panel from four corners; the texture repeats every 0.5 m so the mesh reads as a net from the stand
	var arr = []
	arr.resize(Mesh.ARRAY_MAX)
	var du = p[0].distance_to(p[1]) / 0.5
	var dv = p[1].distance_to(p[2]) / 0.5
	arr[Mesh.ARRAY_VERTEX] = PackedVector3Array(p)
	arr[Mesh.ARRAY_TEX_UV] = PackedVector2Array([Vector2(0, 0), Vector2(du, 0), Vector2(du, dv), Vector2(0, dv)])
	var nrm = (p[1] - p[0]).cross(p[2] - p[0]).normalized()
	arr[Mesh.ARRAY_NORMAL] = PackedVector3Array([nrm, nrm, nrm, nrm])
	arr[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
	var m = ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mi = MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat
	vp.add_child(mi)


func _weather(wk: String):
	# rain and snow fall over the part of the pitch the camera sees; kept light for phones
	if not (wk in ["rain", "heavy", "snow"]) or low:
		return
	var ps = CPUParticles3D.new()
	ps.amount = 500 if wk == "heavy" else (260 if wk == "rain" else 320)
	ps.lifetime = 1.1 if wk != "snow" else 5.0
	ps.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	ps.emission_box_extents = Vector3(L * 0.62, 1.0, W * 0.75)
	ps.position = Vector3(0, 26.0, 6.0)
	ps.direction = Vector3(0.15, -1, 0.05)
	ps.spread = 3.0 if wk != "snow" else 25.0
	ps.gravity = Vector3(2.0, -30.0 if wk != "snow" else -2.2, 0)
	ps.initial_velocity_min = 22.0 if wk != "snow" else 2.0
	ps.initial_velocity_max = 28.0 if wk != "snow" else 4.0
	var q = QuadMesh.new()
	q.size = Vector2(0.07, 1.5) if wk != "snow" else Vector2(0.32, 0.32)
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.82, 0.88, 1.0, 0.42) if wk != "snow" else Color(1, 1, 1, 0.9)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y if wk != "snow" else BaseMaterial3D.BILLBOARD_ENABLED
	q.material = m
	ps.mesh = q
	vp.add_child(ps)


func _blob(d: float) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var q = PlaneMesh.new()
	q.size = Vector2(d, d)
	mi.mesh = q
	var m = _mat(Color.WHITE, load("res://assets/m3d/shadow.png"), true)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = m
	mi.position.y = 0.03
	return mi


func _figure(i: int, k: int) -> Dictionary:
	# a rigged, animated footballer: a light mesh built around the baked skeleton, in this side's kit
	var sd = sim.sd[i]
	var gk = k == 0
	var club = sd.club
	var shirt = cols[i]
	var shorts = cols2[i]
	var kt = kits[i] if kits.size() == 2 else G.OPS.kit(club)
	var shirt2 = Color(str(kt.c2))
	var pat = int(kt.p)
	if pat == 0:
		shirt2 = shirt
	var socks = shirt
	if gk:
		shirt = Color("38d27a") if i == 0 else Color("b04ad8")
		shirt2 = shirt.darkened(0.25)
		shorts = Color("1c1c22")
		socks = shirt
		pat = 5
	var pid = sd.xi[k]
	var hsh = absi(hash(pid * 2654435 + 17)) if pid >= 0 else k
	var skin = [Color("f1c9a5"), Color("e0ac8c"), Color("c68f65"), Color("8d5a3b"), Color("5e3a25")][hsh % 5]
	var hair = [Color("1a1410"), Color("2a1c12"), Color("4a2f1a"), Color("7a5a2e"), Color("c9a14a"), Color("101010")][(hsh / 7) % 6]
	if hsh % 5 >= 3:
		hair = Color("121010")
	var n = Node3D.new()
	n.scale = Vector3.ONE * FIG
	vp.add_child(n)
	var rig = RIG.instantiate()
	n.add_child(rig)
	var skel: Skeleton3D = rig.get_node("Skeleton3D")
	var mi = MeshInstance3D.new()
	mi.mesh = PM.build(skel, {"shirt": shirt, "shirt2": shirt2, "shorts": shorts, "socks": socks, "skin": skin, "hair": hair,
		"boots": [Color("16161a"), Color("e8e8e8"), Color("d8342c"), Color("2f6fe0"), Color("e0c020")][(hsh / 3) % 5], "pattern": pat, "gloves": gk, "long": gk})
	skel.add_child(mi)
	mi.skin = skel.create_skin_from_rest_transforms()
	mi.skeleton = NodePath("..")
	if fig_mat == null:
		fig_mat = PM.material()
	mi.material_override = fig_mat
	mi.extra_cull_margin = 3.0
	if lib == null:
		lib = load("res://assets/m3d/soccer.res").duplicate()
		lib.add_animation("cheer", PM.cheer(lib, skel))
	var ap = AnimationPlayer.new()
	rig.add_child(ap)
	ap.add_animation_library("", lib)
	var idle = "gk_idle" if gk else "idle"
	ap.play(idle)
	ap.seek(randf() * 4.0, true)
	var sh2 = _blob(1.0)
	sh2.scale = Vector3.ONE
	n.add_child(sh2)
	var lb = Label3D.new()
	lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lb.text = str(G.s.players[pid].get("num", k + 1)) if pid >= 0 else ""
	lb.font = UI.fonts["disp"]
	lb.font_size = 40
	lb.pixel_size = 0.016
	lb.outline_size = 10
	lb.outline_modulate = Color(0, 0, 0, 0.9)
	lb.no_depth_test = true
	lb.position = Vector3(0, 2.25, 0)
	n.add_child(lb)
	n.visible = pid >= 0
	n.rotation.y = PI / 2 if i == 0 else -PI / 2
	return {"n": n, "ap": ap, "idle": idle, "cur": idle, "act": 0.0, "cheer": false, "pos": Vector2(0.5, 0.5), "ph": randf() * 6.0, "face": PI / 2 if i == 0 else -PI / 2, "jump": 0.0, "dive": 0.0, "gk": gk, "hf": PI / 2 if i == 0 else -PI / 2}


func _act(f: Dictionary, anim: String, from := 0.0, speed := 1.0, hold := -1.0):
	# play a one-off action (kick, header, dive); normal running resumes when it is over
	if not lib.has_animation(anim):
		return
	f.ap.play(anim, 0.1, speed)
	if from > 0.0:
		f.ap.seek(from, true)
	f.cur = anim
	f.act = hold if hold > 0.0 else (lib.get_animation(anim).length - from) / speed - 0.12


func _animate(f: Dictionary, delta: float):
	if f.act > 0.0:
		f.act -= delta
		return
	var sp = float(f.get("sp", 0.0))
	var want: String = f.idle
	var rate = 1.0
	if f.cheer:
		want = "cheer"
		rate = 1.25
	elif sp > 1.3:
		want = "jog"
		rate = clamp(sp / 7.0, 0.6, 1.9)
	if f.cur != want:
		f.ap.play(want, 0.22)
		f.cur = want
	f.ap.speed_scale = rate


# ---------------------------------------------------------------- coordinates

func _w(u: float, v: float, h := 0.0) -> Vector3:
	return Vector3((u - 0.5) * L, h, (v - 0.5) * W)


func _att(side: int, u: float, v: float) -> Vector2:
	# a point given from the attacking side's point of view (u runs towards the goal they attack)
	return Vector2(u, v) if side == 0 else Vector2(1.0 - u, 1.0 - v)


func _shape(i: int, k: int, bu: float, bv: float, poss: bool) -> Vector2:
	var sl = sim.sd[i].slots[k]
	var bx = bu if i == 0 else 1.0 - bu
	var by = bv if i == 0 else 1.0 - bv
	var along = 0.035 + 0.04 * bx
	if k > 0:
		along = clamp(0.1 + sl[2] * 0.5 + (bx - 0.5) * 0.44 + (0.07 if poss else -0.03), 0.08, 0.94)
	var across = clamp(sl[1] + (by - 0.5) * (0.1 if k == 0 else 0.24), 0.04, 0.96)
	var wob = Vector2(sin(t * 0.9 + k * 2.1 + i) * 0.006, cos(t * 0.8 + k * 1.7 + i * 3.0) * 0.01)
	return _att(i, along, across) + wob


func _snap_shape():
	for i in 2:
		for k in 11:
			figs[i][k].pos = _shape(i, k, 0.5, 0.5, false)
	bpos = Vector3(0.5, 0.0, 0.5)
	cam_x = 0.0


# ---------------------------------------------------------------- open play

func tick():
	# once per simulated minute: who is on the ball now
	for i in 2:
		for k in 11:
			figs[i][k].n.visible = sim.sd[i].xi[k] >= 0
	if seq != null:
		return
	var side = sim.ball_side
	var best = 1
	var bd = 99.0
	for k in range(1, 11):
		if sim.sd[side].xi[k] < 0:
			continue
		var d = figs[side][k].pos.distance_to(sim.ball)
		if d < bd:
			bd = d
			best = k
	carrier = Vector2i(side, best)


func playing() -> bool:
	return seq != null


func cancel():
	# drop a staged move that is no longer wanted (the match was simmed on, or Tactics was opened)
	seq = null
	for i in 2:
		for k in 11:
			figs[i][k].jump = 0.0
			figs[i][k].dive = 0.0
			figs[i][k].act = 0.0
			figs[i][k].cheer = false
			figs[i][k].n.visible = sim.sd[i].xi[k] >= 0
	_snap_shape()
	carrier = Vector2i(-1, -1)
	name_l.visible = false
	_place(0.016)


func _process(delta):
	if sim == null or not is_visible_in_tree():
		return
	t += delta
	if seq != null:
		_seq_step(delta)
	else:
		var k1 = 1.0 - exp(-delta * 2.6)
		for i in 2:
			for k in 11:
				_move(figs[i][k], _shape(i, k, sim.ball.x, sim.ball.y, sim.ball_side == i), k1, delta)
		if carrier.x >= 0:
			var c = figs[carrier.x][carrier.y].pos + Vector2(0.012 if carrier.x == 0 else -0.012, 0.0)
			var b2 = Vector2(bpos.x, bpos.z).lerp(c, 1.0 - exp(-delta * 7.0))
			bpos = Vector3(b2.x, max(0.0, bpos.y - delta * 8.0), b2.y)
	_place(delta)


func _move(f: Dictionary, target: Vector2, k1: float, delta: float):
	var old: Vector2 = f.pos
	f.pos = old.lerp(target, k1)
	var d = (f.pos - old) * Vector2(L, W)
	var sp = d.length() / max(delta, 0.001)
	f["sp"] = sp
	if f.get("gk", false):
		f.face = lerp_angle(f.face, f.hf, 1.0 - exp(-delta * 6.0))
	elif sp > 1.3:
		f.face = lerp_angle(f.face, atan2(d.x, d.y), 1.0 - exp(-delta * 10.0))
	elif f.act <= 0.0:
		# standing: watch the ball
		var to = Vector2((bpos.x - f.pos.x) * L, (bpos.z - f.pos.y) * W)
		if to.length() > 2.0:
			f.face = lerp_angle(f.face, atan2(to.x, to.y), 1.0 - exp(-delta * 3.0))
	f.ph += delta * clamp(sp, 0.0, 9.0) * 1.5


func _place(delta: float):
	for i in 2:
		for k in 11:
			var f = figs[i][k]
			if not f.n.visible:
				continue
			f.n.position = _w(f.pos.x, f.pos.y, f.jump * FIG)
			f.n.rotation.y = f.face
			_animate(f, delta)
			f.jump = max(0.0, f.jump - delta * 2.4) if f.get("jv", 0.0) <= 0.0 else f.jump
	if bounce > 0.0:
		bounce = max(0.0, bounce - delta)
		for tr in tiers:
			tr[0].position.y = tr[1] + abs(sin(bounce * 9.0)) * 0.45 * min(1.0, bounce)
	ball.position = _w(bpos.x, bpos.z, 0.42 + bpos.y)
	ball_sh.position = _w(bpos.x, bpos.z, 0.03)
	# camera: raised behind the near touchline, sliding along with the ball
	var tx = clamp((bpos.x - 0.5) * L * 0.62, -22.0, 22.0)
	cam_x = lerp(cam_x, tx, 1.0 - exp(-delta * 1.8))
	cam.position = Vector3(cam_x * 0.9 - 6.0, 40.0, W / 2 + 62.0)
	cam.look_at(Vector3(cam_x, 0.0, -1.0))
	if carrier.x >= 0 and seq == null and sim.sd[carrier.x].xi[carrier.y] >= 0:
		_name(carrier.x, carrier.y)
	elif seq == null:
		name_l.visible = false


func _name(i: int, k: int):
	var pid = sim.sd[i].xi[k]
	if pid < 0:
		name_l.visible = false
		return
	name_l.text = G.pname(G.s.players[pid])
	name_l.position = figs[i][k].n.position + Vector3(0, 6.3, 0)
	name_l.visible = true


# ---------------------------------------------------------------- staged moves

func _idx(side: int, pid: int) -> int:
	return sim.sd[side].xi.find(pid)


func play(e: Dictionary):
	# e is a goal, save or miss event from the engine: e.s side, e.p shooter, e.k kind, e.as assister, e.o outcome
	var s: int = e.s
	var o = 1 - s
	var kind: String = e.get("k", "box")
	var ks = _idx(s, e.p)
	if ks < 1:
		ks = 10
	var ka = _idx(s, int(e.get("as", -1)))
	if ka < 1 or ka == ks:
		ka = -1
		for k in [6, 7, 5, 8, 4, 9, 3]:
			if k != ks and sim.sd[s].xi[k] >= 0:
				ka = k
				break
	var sgn = 1.0 if randf() < 0.5 else -1.0
	var P := Vector2(0.8, 0.5 + sgn * 0.2)       # where the pass comes from (attacking view)
	var S0 := Vector2(0.8, 0.5)                  # where the shooter starts
	var S := Vector2(0.88, 0.5 - sgn * 0.06)     # where he shoots from
	var hp := 0.0                                # how high the pass goes
	var has_pass := true
	match kind:
		"cross":
			P = Vector2(0.87, 0.5 + sgn * 0.43)
			S0 = Vector2(0.82, 0.5 - sgn * 0.05)
			S = Vector2(0.925, 0.5 - sgn * 0.04)
			hp = 7.0
		"corner":
			P = Vector2(0.995, 0.5 + sgn * 0.49)
			S0 = Vector2(0.88, 0.5)
			S = Vector2(0.935, 0.5 - sgn * 0.03)
			hp = 9.0
		"big":
			P = Vector2(0.6, 0.5 + sgn * 0.12)
			S0 = Vector2(0.72, 0.5 - sgn * 0.05)
			S = Vector2(0.89, 0.5 - sgn * 0.05)
		"long":
			P = Vector2(0.64, 0.5 + sgn * 0.2)
			S0 = Vector2(0.7, 0.5 - sgn * 0.05)
			S = Vector2(0.745, 0.5 - sgn * 0.08)
		"fk":
			S = Vector2(0.775, 0.5 + sgn * 0.1)
			S0 = S - Vector2(0.03, 0)
			has_pass = false
		"pen":
			S = Vector2(0.895, 0.5)
			S0 = Vector2(0.865, 0.5)
			has_pass = false
	var out: String = e.t if not e.get("blk", false) else "block"
	var G2 := Vector3(1.0, 1.0, 0.5 + randf_range(-0.04, 0.04))      # where the ball ends up: u, height, v
	match out:
		"goal": G2 = Vector3(1.012, randf_range(0.3, 1.9), 0.5 + randf_range(-0.045, 0.045))
		"save": G2 = Vector3(0.992, randf_range(0.4, 1.6), 0.5 + randf_range(-0.035, 0.035))
		"miss": G2 = Vector3(1.03, randf_range(0.5, 4.5), 0.5 + (1.0 if randf() < 0.5 else -1.0) * randf_range(0.07, 0.12))
		"block": G2 = Vector3(S.x + 0.03, 0.4, S.y + randf_range(-0.01, 0.01))
	var gk_at = Vector2(0.988, 0.5 + (S.y - 0.5) * 0.35)
	seq = {"t": 0.0, "s": s, "o": o, "ks": ks, "ka": ka, "P": P, "S0": S0, "S": S, "hp": hp, "pass": has_pass, "out": out, "G": G2, "gk": gk_at,
		"T1": 1.0 if has_pass else 0.9, "T2": 1.9 if has_pass else 1.5, "T3": 2.45 if has_pass else 2.05, "end": 0.0, "kind": kind, "hit": false, "k1": false, "k2": false, "sgn": sgn}
	seq.T3 += 0.25 if kind == "long" or kind == "fk" else 0.0
	seq.end = seq.T3 + (2.6 if out == "goal" else 1.1)
	carrier = Vector2i(-1, -1)
	# the two defenders nearest their own goal mark the shooter
	var ds = []
	for k in range(1, 11):
		if sim.sd[o].xi[k] >= 0:
			ds.append([sim.sd[o].slots[k][2], k])
	ds.sort_custom(func(a, b): return a[0] < b[0])
	seq["marks"] = [ds[0][1] if ds.size() > 0 else -1, ds[1][1] if ds.size() > 1 else -1, ds[2][1] if ds.size() > 2 else -1, ds[3][1] if ds.size() > 3 else -1]
	_name(s, ks)


func _seq_step(delta: float):
	var q = seq
	q.t += delta
	var s: int = q.s
	var o: int = q.o
	var tt: float = q.t
	# the ball
	var bu: Vector2
	var bh := 0.0
	var Pw = _att(s, q.P.x, q.P.y)
	var Sw = _att(s, q.S.x, q.S.y)
	var Gw = _att(s, q.G.x, q.G.z)
	# wind-ups start a little before the ball is struck, so foot and ball meet
	if q.pass and tt >= q.T1 - 0.22 and not q.get("p1", false):
		q["p1"] = true
		_act(figs[s][q.ka], "pass" if q.hp <= 0.0 else "pass2")
	var lead = 0.6 if q.kind == "pen" else (0.5 if q.hp > 0.0 else 0.48)
	if tt >= q.T2 - lead and not q.get("p2", false):
		q["p2"] = true
		if q.kind == "pen":
			_act(figs[s][q.ks], "pen")
		elif q.hp > 0.0:
			_act(figs[s][q.ks], "header", 0.1)
		else:
			_act(figs[s][q.ks], "shoot")
	if tt >= q.T2 - 0.3 and not q.get("p3", false) and q.out != "block":
		q["p3"] = true
		var gkf = figs[o][0]
		var gw = _w(gkf.pos.x, gkf.pos.y)
		var tw3 = _w(Gw.x, Gw.y)
		var leftv = Vector3(cos(gkf.face), 0, -sin(gkf.face))
		var side_l = leftv.dot(tw3 - gw) > 0.0
		var far = abs(q.G.z - q.gk.y) * W > 1.4
		if q.out == "miss":
			_act(gkf, "gk_step", 0.0, 1.0, 0.9)
		elif far:
			_act(gkf, "gk_dive" if side_l else "gk_dive2", 0.55, 1.0)
		elif q.out == "save":
			_act(gkf, "gk_catch" if q.G.y > 0.9 else "gk_block", 0.3, 1.3)
		else:
			_act(gkf, "gk_miss", 0.3, 1.2)
	if q.out == "block" and tt >= q.T2 - 0.1 and not q.get("p4", false):
		q["p4"] = true
		if q.marks[0] >= 0:
			_act(figs[o][q.marks[0]], "pass", 0.0, 1.0)
	if tt < q.T1:
		bu = Pw if q.pass else Sw
	elif tt < q.T2:
		if q.pass:
			var a = (tt - q.T1) / (q.T2 - q.T1)
			bu = Pw.lerp(Sw, a)
			bh = q.hp * 4.0 * a * (1.0 - a) + (1.4 if q.hp > 0.0 else 0.0) * a
			if not q.k1:
				q.k1 = true
				UI.sfx("kick", -14.0)
		else:
			bu = Sw
	elif tt < q.T3:
		var a2 = (tt - q.T2) / (q.T3 - q.T2)
		bu = Sw.lerp(Gw, a2)
		var h0 = 1.4 if q.hp > 0.0 else 0.0
		bh = lerp(h0, q.G.y, a2) + (2.2 if q.kind in ["long", "fk"] else 0.5) * 4.0 * a2 * (1.0 - a2) * (0.0 if q.hp > 0.0 else 1.0)
		if not q.k2:
			q.k2 = true
			UI.sfx("kick", -9.0)
	else:
		var a3 = min(1.0, (tt - q.T3) / 0.6)
		match q.out:
			"goal":
				bu = Gw + (_att(s, 1.0, 0.0) - _att(s, 0.0, 0.0)) * 0.006 * a3
				bh = max(0.0, q.G.y * (1.0 - a3))
			"save":
				bu = Gw.lerp(_att(s, 0.95, q.G.z + q.sgn * 0.09), a3)
				bh = q.G.y * (1.0 - a3) + 1.2 * 4.0 * a3 * (1.0 - a3)
			"block":
				bu = Gw.lerp(_att(s, q.S.x - 0.03, q.S.y + q.sgn * 0.05), a3)
				bh = 0.8 * 4.0 * a3 * (1.0 - a3)
			_:
				bu = Gw + (Gw - Sw).normalized() * 0.03 * a3
				bh = q.G.y
		if not q.hit:
			q.hit = true
			if q.out == "goal":
				bounce = 2.2
			impact.emit()
	bpos = Vector3(bu.x, bh, bu.y)
	# the players
	var k1 = 1.0 - exp(-delta * 3.4)
	var fast = 1.0 - exp(-delta * 6.0)
	var ph = clamp(tt / q.T2, 0.0, 1.0)
	for i in 2:
		for k in 11:
			var f = figs[i][k]
			var tg: Vector2 = _shape(i, k, lerp(Pw.x, Sw.x, ph), lerp(Pw.y, Sw.y, ph), i == s)
			var kk = k1
			if i == s and k == q.ks:
				tg = _att(s, lerp(q.S0.x, q.S.x, ph), lerp(q.S0.y, q.S.y, ph))
				kk = fast
			elif i == s and k == q.ka and q.pass:
				tg = Pw - (_att(s, 0.012, 0.0) - _att(s, 0.0, 0.0))
				kk = fast
			elif i == o and k == 0:
				tg = _att(s, q.gk.x, q.gk.y)
				if tt >= q.T2 and q.out != "block":
					# the dive itself is in the animation; he only shuffles a little on his line
					tg = _att(s, q.gk.x, lerp(q.gk.y, q.G.z, 0.12))
			elif i == o and k in q.marks:
				var mi = q.marks.find(k)
				if q.kind == "pen":
					tg = _att(s, 0.8, 0.3 + mi * 0.13)
				elif q.kind == "fk" and mi < 4:
					tg = _att(s, q.S.x + 0.085, q.S.y + (mi - 1.5) * 0.014)
				elif mi == 0:
					tg = _att(s, lerp(q.S0.x, q.S.x, ph) + 0.022, lerp(q.S0.y, q.S.y, ph) + 0.012)
				elif mi == 1:
					tg = _att(s, 0.93, 0.5 + q.sgn * 0.03)
				elif mi == 2:
					tg = _att(s, 0.9, 0.5 - q.sgn * 0.1)
				else:
					tg = _att(s, lerp(q.P.x, 0.9, 0.4), lerp(q.P.y, 0.5, 0.35))
				kk = fast
			elif i == s and q.kind == "pen":
				tg = _att(s, 0.8, 0.25 + k * 0.05)
			elif i == s and k >= 7 and q.kind in ["cross", "corner"]:
				tg = _att(s, 0.9 + (k - 8) * 0.012, 0.5 + q.sgn * (0.04 * (k - 8)))
			# celebration: the scorer wheels away and his team-mates follow; the others stand
			if tt >= q.T3 and q.out == "goal" and i == s and k > 0:
				var spot = _att(s, 0.93, 0.5 - q.sgn * 0.3)
				tg = spot if k == q.ks else spot + Vector2(sin(k * 2.3) * 0.03, cos(k * 1.9) * 0.05)
				kk = 1.0 - exp(-delta * (3.2 if k == q.ks else 1.6))
				f.cheer = k == q.ks or f.pos.distance_to(spot) < 0.09
				if f.cheer and f.act > 0.0:
					f.act = 0.0
			_move(f, tg, kk, delta)
	_name(s, q.ks)
	if tt >= q.end:
		for i in 2:
			for k in 11:
				figs[i][k].jump = 0.0
				figs[i][k].dive = 0.0
				figs[i][k].cheer = false
		seq = null
		name_l.visible = false
		seq_done.emit()

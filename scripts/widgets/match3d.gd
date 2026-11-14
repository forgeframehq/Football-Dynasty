extends SubViewportContainer
# The 3D match view: a pitch inside a small stadium, 22 kit-coloured figures and a ball, seen from a raised
# broadcast angle. The match engine decides what happens; this view shows it. In open play the teams hold
# their shape and shift with the ball. Each chance is played out as a short staged move (pass, shot, outcome).

signal impact          # the moment a staged shot reaches its outcome (score, sounds and commentary land here)
signal seq_done        # the staged move, including any celebration, is over

const L := 105.0
const W := 68.0
const FIG := 2.5       # figures are drawn larger than life so they read on a phone

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
	e.background_color = Color("0c1220")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(1, 1, 1)
	e.ambient_light_energy = 0.75
	env.environment = e
	vp.add_child(env)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-58, 35, 0)
	sun.light_energy = 0.8
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
	pm.material_override = _mat(Color(0.8, 0.84, 0.8), load("res://assets/m3d/pitch.jpg"), true)
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
	netm.uv1_scale = Vector3(3, 2, 1)
	for sg in [-1.0, 1.0]:
		var gx = sg * L / 2
		for pz in [-3.66, 3.66]:
			_box(Vector3(0.16, 2.44, 0.16), Vector3(gx, 1.22, pz), white)
		_box(Vector3(0.16, 0.16, 7.48), Vector3(gx, 2.44, 0), white)
		var back = MeshInstance3D.new()
		var bq = QuadMesh.new()
		bq.size = Vector2(7.32, 2.44)
		back.mesh = bq
		back.material_override = netm
		back.position = Vector3(gx + sg * 2.0, 1.22, 0)
		back.rotation_degrees.y = 90.0
		vp.add_child(back)
		var top = MeshInstance3D.new()
		var tq = QuadMesh.new()
		tq.size = Vector2(2.0, 7.32)
		top.mesh = tq
		top.material_override = netm
		top.position = Vector3(gx + sg * 1.0, 2.44, 0)
		top.rotation_degrees = Vector3(-90, 0, 0)
		vp.add_child(top)
		for pz in [-3.66, 3.66]:
			var sidep = MeshInstance3D.new()
			var sq = QuadMesh.new()
			sq.size = Vector2(2.0, 2.44)
			sidep.mesh = sq
			sidep.material_override = netm
			sidep.position = Vector3(gx + sg * 1.0, 1.22, pz)
			vp.add_child(sidep)
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
	var sd = sim.sd[i]
	var gk = k == 0
	var shirt = cols[i]
	var shorts = cols2[i]
	if gk:
		shirt = Color("38d27a") if i == 0 else Color("b04ad8")
		shorts = Color("1c1c22")
	var pid = sd.xi[k]
	var skin = Color("e0ac8c")
	if pid >= 0:
		skin = [Color("f1c9a5"), Color("e0ac8c"), Color("c68f65"), Color("8d5a3b"), Color("5e3a25")][pid % 5]
	var n = Node3D.new()
	n.scale = Vector3.ONE * FIG
	vp.add_child(n)
	var body = _box(Vector3(0.52, 0.62, 0.3), Vector3(0, 1.22, 0), _mat(shirt), n)
	_box(Vector3(0.5, 0.26, 0.3), Vector3(0, 0.8, 0), _mat(shorts), n)
	var head = MeshInstance3D.new()
	var hm = SphereMesh.new()
	hm.radius = 0.17
	hm.height = 0.34
	hm.radial_segments = 8
	hm.rings = 4
	head.mesh = hm
	head.material_override = _mat(skin)
	head.position = Vector3(0, 1.72, 0)
	n.add_child(head)
	var legs = []
	var arms = []
	for sx in [-1.0, 1.0]:
		var hip = Node3D.new()
		hip.position = Vector3(sx * 0.14, 0.7, 0)
		n.add_child(hip)
		_box(Vector3(0.17, 0.36, 0.19), Vector3(0, -0.18, 0), _mat(skin), hip)
		_box(Vector3(0.17, 0.34, 0.19), Vector3(0, -0.52, 0), _mat(shirt if not gk else shorts), hip)
		legs.append(hip)
		var sh = Node3D.new()
		sh.position = Vector3(sx * 0.34, 1.48, 0)
		n.add_child(sh)
		_box(Vector3(0.14, 0.26, 0.16), Vector3(0, -0.13, 0), _mat(shirt), sh)
		_box(Vector3(0.12, 0.3, 0.14), Vector3(0, -0.4, 0), _mat(skin), sh)
		arms.append(sh)
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
	lb.position = Vector3(0, 2.3, 0)
	n.add_child(lb)
	n.visible = pid >= 0
	return {"n": n, "legs": legs, "arms": arms, "body": body, "pos": Vector2(0.5, 0.5), "ph": randf() * 6.0, "face": 0.0, "jump": 0.0, "dive": 0.0}


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
	if sp > 0.6:
		f.face = lerp_angle(f.face, atan2(d.x, d.y), 1.0 - exp(-delta * 10.0))
	f.ph += delta * clamp(sp, 0.0, 9.0) * 1.5


func _place(delta: float):
	for i in 2:
		for k in 11:
			var f = figs[i][k]
			if not f.n.visible:
				continue
			f.n.position = _w(f.pos.x, f.pos.y, f.jump * FIG)
			f.n.rotation.y = f.face
			f.n.rotation.x = f.dive
			var sw = sin(f.ph) * clamp(f.get("sp", 0.0) / 5.0, 0.0, 1.0)
			f.legs[0].rotation.x = sw * 0.9
			f.legs[1].rotation.x = -sw * 0.9
			f.arms[0].rotation.x = -sw * 0.7
			f.arms[1].rotation.x = sw * 0.7
			if f.get("kick", 0.0) > 0.0:
				f.kick = max(0.0, f.kick - delta * 3.0)
				f.legs[1].rotation.x = -1.3 * sin(f.kick * PI)
			f.jump = max(0.0, f.jump - delta * 2.4) if f.get("jv", 0.0) <= 0.0 else f.jump
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
	if tt < q.T1:
		bu = Pw if q.pass else Sw
	elif tt < q.T2:
		if q.pass:
			var a = (tt - q.T1) / (q.T2 - q.T1)
			bu = Pw.lerp(Sw, a)
			bh = q.hp * 4.0 * a * (1.0 - a) + (1.4 if q.hp > 0.0 else 0.0) * a
			if not q.k1:
				q.k1 = true
				figs[s][q.ka]["kick"] = 1.0
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
			if q.hp > 0.0:
				figs[s][q.ks].jump = 0.55
			else:
				figs[s][q.ks]["kick"] = 1.0
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
					var reach = 0.75 if q.out == "save" else (0.45 if q.out == "goal" else 0.2)
					tg = _att(s, q.gk.x, lerp(q.gk.y, q.G.z, reach))
					kk = fast
					f.dive = lerp(f.dive, 0.9 * sign(q.G.z - q.gk.y) * (1.0 if s == 0 else -1.0) * (1.0 if q.out != "miss" else 0.3), 1.0 - exp(-delta * 8.0)) if tt < q.T3 + 0.5 else lerp(f.dive, 0.0, 1.0 - exp(-delta * 4.0))
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
				if k == q.ks or f.pos.distance_to(spot) < 0.07:
					f.jump = abs(sin(tt * 7.0 + k)) * 0.35
			_move(f, tg, kk, delta)
	_name(s, q.ks)
	if tt >= q.end:
		for i in 2:
			for k in 11:
				figs[i][k].jump = 0.0
				figs[i][k].dive = 0.0
		seq = null
		name_l.visible = false
		seq_done.emit()

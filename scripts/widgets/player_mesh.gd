extends RefCounted
# Builds a light, fully rigged footballer from tubes around the baked skeleton (assets/m3d/rig.scn).
# About 1,300 vertices each, in kit colours with the club's shirt pattern, so 22 of them animate cheaply on a phone.

const N = 10
const P = "mixamorig_"


static func material() -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.85
	m.metallic = 0.0
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


static func build(skel: Skeleton3D, kit: Dictionary) -> ArrayMesh:
	# kit: shirt, shirt2, shorts, socks, skin, hair, boots, pattern (0 plain, 1 stripes, 2 hoops, 3 halves, 4 sash, 5 sleeves), gloves (bool)
	var st = {"v": PackedVector3Array(), "n": PackedVector3Array(), "c": PackedColorArray(), "b": PackedInt32Array(), "w": PackedFloat32Array(), "i": PackedInt32Array(), "sk": skel}
	var shirt: Color = kit.shirt
	var s2: Color = kit.get("shirt2", shirt)
	var pat = int(kit.get("pattern", 0))
	var skin: Color = kit.skin
	var torso_col = func(j: int, band: int, mid: Vector3) -> Color:
		match pat:
			1: return shirt if j % 2 == 0 else s2
			2: return shirt if band % 2 == 0 else s2
			3: return shirt if mid.x < 0.0 else s2
			4: return s2 if abs((mid.x * 2.2 + (mid.y - 1.28)) ) < 0.07 and mid.z > 0.0 else shirt
		return shirt
	var flat = func(col: Color) -> Callable:
		return func(_j: int, _band: int, _mid: Vector3) -> Color: return col
	# torso: shorts waistband up to the shoulders
	_tube(st, [[Vector3(0, 0.90, 0.0), 0.150, 0.105, "Hips"], [Vector3(0, 1.05, 0.005), 0.158, 0.108, "Hips"]], flat.call(kit.shorts), true, false)
	_tube(st, [[Vector3(0, 1.05, 0.005), 0.160, 0.110, "Hips"], [Vector3(0, 1.13, 0.008), 0.152, 0.104, "Spine"], [Vector3(0, 1.22, 0.004), 0.156, 0.106, "Spine1"], [Vector3(0, 1.31, -0.004), 0.172, 0.112, "Spine1"],
		[Vector3(0, 1.39, -0.014), 0.190, 0.115, "Spine2"], [Vector3(0, 1.455, -0.024), 0.186, 0.104, "Spine2"], [Vector3(0, 1.495, -0.030), 0.075, 0.07, "Spine2"]], torso_col, false, true)
	# neck and head
	_tube(st, [[Vector3(0, 1.48, -0.03), 0.050, 0.05, "Neck"], [Vector3(0, 1.60, -0.018), 0.048, 0.05, "Neck"]], flat.call(skin), false, false)
	var hc = Vector3(0, 1.715, 0.012)
	var rings = []
	for r in 7:
		var a = -PI / 2 + PI * r / 6.0
		rings.append([hc + Vector3(0, sin(a) * 0.125, 0), max(0.012, cos(a) * 0.105), max(0.012, cos(a) * 0.118), "Head"])
	var hair: Color = kit.hair
	_tube(st, rings, func(j: int, band: int, mid: Vector3) -> Color:
		if band >= 4 or (band == 3 and mid.z < 0.04):
			return hair
		if band >= 2 and mid.z < -0.02:
			return hair
		return skin, true, true)
	# arms: sleeve, upper arm, forearm, hand
	var sleeve = s2 if pat == 5 else shirt
	var hand: Color = Color("f2f2f2") if kit.get("gloves", false) else skin
	for sg in [-1.0, 1.0]:
		var side = "Left" if sg > 0 else "Right"
		var y = 1.441
		var z = -0.055
		_tube(st, [[Vector3(sg * 0.125, y, z), 0.062, 0.062, side + "Arm"], [Vector3(sg * 0.30, y, z), 0.052, 0.052, side + "Arm"]], flat.call(sleeve), true, false)
		_tube(st, [[Vector3(sg * 0.30, y, z), 0.044, 0.044, side + "Arm"], [Vector3(sg * 0.44, y, z), 0.040, 0.040, side + "Arm"]], flat.call(skin if not kit.get("long", false) else sleeve), false, false)
		_tube(st, [[Vector3(sg * 0.42, y, z), 0.040, 0.040, side + "ForeArm"], [Vector3(sg * 0.71, y, z), 0.031, 0.031, side + "ForeArm"]], flat.call(skin if not kit.get("long", false) else sleeve), true, false)
		_tube(st, [[Vector3(sg * 0.70, y, z), 0.034, 0.042, side + "Hand"], [Vector3(sg * 0.80, y, z), 0.024, 0.040, side + "Hand"]], flat.call(hand), true, true)
		# legs: shorts, thigh, sock, boot
		var x = sg * 0.082
		_tube(st, [[Vector3(x, 0.99, 0.0), 0.088, 0.092, side + "UpLeg"], [Vector3(x, 0.74, 0.0), 0.082, 0.084, side + "UpLeg"]], flat.call(kit.shorts), false, true)
		_tube(st, [[Vector3(x, 0.76, 0.0), 0.066, 0.068, side + "UpLeg"], [Vector3(x, 0.52, 0.003), 0.055, 0.056, side + "UpLeg"]], flat.call(skin), false, false)
		_tube(st, [[Vector3(x, 0.545, 0.003), 0.056, 0.058, side + "Leg"], [Vector3(x, 0.36, -0.012), 0.058, 0.062, side + "Leg"], [Vector3(x, 0.10, -0.027), 0.040, 0.042, side + "Leg"]], flat.call(kit.socks), true, false)
		_tube(st, [[Vector3(x, 0.045, -0.085), 0.050, 0.048, side + "Foot"], [Vector3(x, 0.045, 0.06), 0.052, 0.046, side + "Foot"], [Vector3(x, 0.035, 0.165), 0.044, 0.032, side + "Foot"]], flat.call(kit.boots), true, true)
	var arr = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = st.v
	arr[Mesh.ARRAY_NORMAL] = st.n
	arr[Mesh.ARRAY_COLOR] = st.c
	arr[Mesh.ARRAY_BONES] = st.b
	arr[Mesh.ARRAY_WEIGHTS] = st.w
	arr[Mesh.ARRAY_INDEX] = st.i
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return mesh


static func _tube(st: Dictionary, rings: Array, colf: Callable, cap0: bool, cap1: bool):
	# rings: [centre, radius a, radius b, bone]; a runs across the body (or up, for arms), b front to back
	var sk: Skeleton3D = st.sk
	var pts = []
	for r in rings.size():
		var c: Vector3 = rings[r][0]
		var ax: Vector3 = (rings[min(r + 1, rings.size() - 1)][0] - rings[max(r - 1, 0)][0]).normalized()
		var u = ax.cross(Vector3(0, 0, 1))
		if u.length() < 0.2:
			u = ax.cross(Vector3(1, 0, 0))
		u = u.normalized()
		var v = ax.cross(u).normalized()
		var ring = []
		for j in N:
			var a = TAU * (j + 0.5) / N
			var off = u * cos(a) * float(rings[r][1]) + v * sin(a) * float(rings[r][2])
			ring.append([c + off, off.normalized()])
		pts.append(ring)
	for r in rings.size() - 1:
		var b0 = sk.find_bone(P + str(rings[r][3]))
		var b1 = sk.find_bone(P + str(rings[r + 1][3]))
		for j in N:
			var j2 = (j + 1) % N
			var q = [pts[r][j], pts[r][j2], pts[r + 1][j2], pts[r + 1][j]]
			var mid: Vector3 = (q[0][0] + q[1][0] + q[2][0] + q[3][0]) / 4.0
			var col: Color = colf.call(j, r, mid)
			var base = st.v.size()
			for k in 4:
				st.v.append(q[k][0])
				st.n.append(q[k][1])
				st.c.append(col)
				var bone = b0 if k < 2 else b1
				st.b.append_array(PackedInt32Array([max(bone, 0), 0, 0, 0]))
				st.w.append_array(PackedFloat32Array([1.0, 0.0, 0.0, 0.0]))
			st.i.append_array(PackedInt32Array([base, base + 2, base + 1, base, base + 3, base + 2]))
	for e in [[cap0, 0, -1.0], [cap1, rings.size() - 1, 1.0]]:
		if not e[0]:
			continue
		var r = int(e[1])
		var bone = max(sk.find_bone(P + str(rings[r][3])), 0)
		var col: Color = colf.call(0, min(r, rings.size() - 2), rings[r][0])
		var base = st.v.size()
		var ax2: Vector3 = (rings[min(r + 1, rings.size() - 1)][0] - rings[max(r - 1, 0)][0]).normalized() * float(e[2])
		st.v.append(rings[r][0])
		st.n.append(ax2)
		st.c.append(col)
		st.b.append_array(PackedInt32Array([bone, 0, 0, 0]))
		st.w.append_array(PackedFloat32Array([1.0, 0.0, 0.0, 0.0]))
		for j in N:
			st.v.append(pts[r][j][0])
			st.n.append(ax2)
			st.c.append(col)
			st.b.append_array(PackedInt32Array([bone, 0, 0, 0]))
			st.w.append_array(PackedFloat32Array([1.0, 0.0, 0.0, 0.0]))
		for j in N:
			st.i.append_array(PackedInt32Array([base, base + 1 + j, base + 1 + (j + 1) % N]))


static func cheer(lib: AnimationLibrary, skel: Skeleton3D) -> Animation:
	# a celebration made from the jog: the same legs, both arms thrown up
	var a: Animation = lib.get_animation("jog").duplicate()
	for sg in [-1.0, 1.0]:
		var side = "Left" if sg > 0 else "Right"
		var bi = skel.find_bone(P + side + "Arm")
		var par = skel.get_bone_parent(bi)
		var g = skel.get_bone_global_rest(bi).basis
		var pg = skel.get_bone_global_rest(par).basis
		var rot = Quaternion(Vector3(sg, 0, 0), Vector3(sg * 0.42, 0.9, 0.05).normalized())
		var local = (pg.inverse() * (Basis(rot) * g)).get_rotation_quaternion()
		for nm in [side + "Arm", side + "ForeArm"]:
			var t = a.find_track(NodePath("Skeleton3D:" + P + nm), Animation.TYPE_ROTATION_3D)
			if t < 0:
				continue
			var q = local if nm.ends_with("Arm") and not nm.ends_with("ForeArm") else skel.get_bone_rest(skel.find_bone(P + nm)).basis.get_rotation_quaternion()
			var n = a.track_get_key_count(t)
			for k in range(n - 1, -1, -1):
				a.track_remove_key(t, k)
			a.rotation_track_insert_key(t, 0.0, q)
			a.rotation_track_insert_key(t, a.length, q)
	return a

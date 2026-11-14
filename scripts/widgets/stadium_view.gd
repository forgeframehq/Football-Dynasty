extends SubViewportContainer
# A still 3D picture of a stadium, rendered once: used as the backdrop of the match-day fixture card.

var model := "res://assets/city3d/stadium/Fst_Eng_001.FBX"
var ground := 0.66375
var night := false
var tint := Color.WHITE


func _ready():
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vp = SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = false
	vp.msaa_3d = Viewport.MSAA_2X
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(vp)
	var env = WorldEnvironment.new()
	var e = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("0b1020") if night else Color("31466e")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("8ea0d8") if night else Color.WHITE
	e.ambient_light_energy = 0.45 if night else 0.7
	env.environment = e
	vp.add_child(env)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, -50, 0)
	sun.light_energy = 0.55 if night else 1.1
	sun.light_color = Color("cfd8ff") if night else Color("fff4e0")
	vp.add_child(sun)
	var ground = MeshInstance3D.new()
	var pm = PlaneMesh.new()
	pm.size = Vector2(60, 60)
	ground.mesh = pm
	var gm = StandardMaterial3D.new()
	gm.albedo_color = Color("1c2a22") if night else Color("3d5a40")
	ground.material_override = gm
	vp.add_child(ground)
	if ResourceLoader.exists(model):
		var st = load(model).instantiate()
		vp.add_child(st)
		var bb = _aabb(st)
		var k = 9.0 / max(1.0, bb.size.x)
		st.scale = Vector3(k, k, k)
		st.position = Vector3(-(bb.position.x + bb.size.x * 0.5) * k, 0.02 - (bb.position.y + ground * bb.size.y) * k, -(bb.position.z + bb.size.z * 0.5) * k)
	if night:
		for p in [Vector3(-4, 3.2, -3), Vector3(4, 3.2, -3), Vector3(-4, 3.2, 3), Vector3(4, 3.2, 3)]:
			var l = OmniLight3D.new()
			l.position = p
			l.omni_range = 9.0
			l.light_energy = 2.2
			l.light_color = Color("fff7e6")
			vp.add_child(l)
	var cam = Camera3D.new()
	cam.fov = 38
	vp.add_child(cam)
	cam.position = Vector3(7.5, 5.2, 9.5)
	cam.look_at(Vector3(0, 0.6, 0))


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

extends SubViewportContainer
# A footballer wearing the kit, in 3D: drag to turn him round. Front sponsor, name, number, back and sleeve sponsors.

const PM = preload("res://scripts/widgets/player_mesh.gd")
const RIG = preload("res://assets/m3d/rig.scn")

var kit: Dictionary = {}
var front: Texture2D = null
var back: Texture2D = null
var sleeve: Texture2D = null
var pname := ""
var number := 10
var gk := false
var holder: Node3D
var spin := 0.35
var dragging := false
var idle_t := 0.0
var start_back := false


func _ready():
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	var vp = SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_4X
	add_child(vp)
	var env = WorldEnvironment.new()
	var e = Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color.WHITE
	e.ambient_light_energy = 0.9
	env.environment = e
	vp.add_child(env)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 25, 0)
	sun.light_energy = 0.9
	vp.add_child(sun)
	var cam = Camera3D.new()
	cam.fov = 30
	vp.add_child(cam)
	cam.position = Vector3(0, 1.3, 2.25)
	cam.look_at(Vector3(0, 1.27, 0))
	holder = Node3D.new()
	vp.add_child(holder)
	var rig = RIG.instantiate()
	holder.add_child(rig)
	var skel: Skeleton3D = rig.get_node("Skeleton3D")
	var c1 = Color(str(kit.c1))
	var c2 = Color(str(kit.c2))
	var shorts = c2 if abs(c2.r - c1.r) + abs(c2.g - c1.g) + abs(c2.b - c1.b) > 0.25 else c1.darkened(0.35)
	var old = PM.N
	PM.N = 20
	var mi = MeshInstance3D.new()
	mi.mesh = PM.build(skel, {"shirt": c1, "shirt2": c2 if int(kit.p) != 0 else c1, "shorts": shorts if not gk else Color("1c1c22"), "socks": c1, "skin": Color("c68f65"), "hair": Color("1a1410"),
		"boots": Color("16161a"), "pattern": int(kit.p), "gloves": gk, "long": gk})
	PM.N = old
	skel.add_child(mi)
	mi.skin = skel.create_skin_from_rest_transforms()
	mi.skeleton = NodePath("..")
	mi.material_override = PM.material()
	# a relaxed standing pose: arms down by the sides, a little away from the body
	for sg in [-1.0, 1.0]:
		var bi = skel.find_bone("mixamorig_%sArm" % ("Left" if sg > 0 else "Right"))
		var g = skel.get_bone_global_rest(bi).basis
		var pg = skel.get_bone_global_rest(skel.get_bone_parent(bi)).basis
		var rot = Quaternion(Vector3(sg, 0, 0), Vector3(sg * 0.42, -0.9, 0.04).normalized())
		skel.set_bone_pose_rotation(bi, (pg.inverse() * (Basis(rot) * g)).get_rotation_quaternion())
	var ink = Color.WHITE if c1.get_luminance() < 0.55 else Color("14161c")
	var chest = BoneAttachment3D.new()
	chest.bone_name = "mixamorig_Spine2"
	skel.add_child(chest)
	if front != null:
		chest.add_child(_logo(front, 0.21, Vector3(0, -0.01, 0.124), 0.0, ink))
	if back != null:
		chest.add_child(_logo(back, 0.17, Vector3(0, -0.18, -0.118), PI, ink))
	if pname != "":
		var nl = _text(pname.to_upper(), 46, ink)
		nl.position = Vector3(0, 0.1, -0.122)
		nl.rotation.y = PI
		chest.add_child(nl)
	var num = _text(str(number), 150, ink)
	num.position = Vector3(0, -0.035, -0.124)
	num.rotation.y = PI
	chest.add_child(num)
	if sleeve != null:
		var arm = BoneAttachment3D.new()
		arm.bone_name = "mixamorig_LeftArm"
		skel.add_child(arm)
		arm.add_child(_logo(sleeve, 0.085, Vector3(0, 0.11, 0.058), 0.0, ink))
	holder.rotation.y = PI + 0.25 if start_back else 0.3


func _text(t: String, size: int, col: Color) -> Label3D:
	var l = Label3D.new()
	l.text = t
	l.font = UI.fonts["xbold"]
	l.font_size = size
	l.pixel_size = 0.0011
	l.modulate = col
	l.outline_size = 0
	l.double_sided = false
	return l


func _logo(tex: Texture2D, w: float, at: Vector3, rot: float, ink: Color) -> Node3D:
	var n = Node3D.new()
	n.position = at
	n.rotation.y = rot
	var sp = Sprite3D.new()
	sp.texture = tex
	sp.pixel_size = w / max(1.0, float(tex.get_width()))
	sp.double_sided = false
	sp.modulate = ink
	sp.shaded = false
	n.add_child(sp)
	return n


func _gui_input(e):
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		dragging = e.pressed
		idle_t = 0.0
	elif e is InputEventMouseMotion and dragging:
		holder.rotation.y += e.relative.x * 0.012
		idle_t = 0.0


func _process(delta):
	if holder == null or dragging:
		return
	idle_t += delta
	if idle_t > 4.0:
		holder.rotation.y += delta * spin


func show_back(b: bool):
	idle_t = 0.0
	var tw = create_tween()
	tw.tween_property(holder, "rotation:y", PI + 0.25 if b else 0.3, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

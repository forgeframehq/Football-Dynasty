extends "res://scripts/screens/screen.gd"
# The manager's home in 3D: a dollhouse you can turn, rooms you can step into, and things you can tap.
# Furniture: Kenney Furniture Kit (CC0). Cars: Kenney Car Kit (CC0). The home grows with the one you own.

const F = "res://assets/home3d/"
const K = 2.0                       # the kit is half scale: a double bed comes out about two metres long
const ROOMS = [
	{"k": "living", "n": "Living room", "eye": Vector3(4.6, 1.5, 4.3), "look": Vector3(2.2, 0.8, 0.6)},
	{"k": "kitchen", "n": "Kitchen", "eye": Vector3(7.0, 1.5, 3.1), "look": Vector3(9.6, 0.9, 0.5)},
	{"k": "bedroom", "n": "Bedroom", "eye": Vector3(4.4, 1.5, 5.6), "look": Vector3(1.6, 0.6, 7.4)},
	{"k": "office", "n": "Office", "eye": Vector3(5.6, 1.5, 5.6), "look": Vector3(7.6, 0.8, 7.6)},
	{"k": "garage", "n": "Drive", "eye": Vector3(13.2, 1.7, 7.6), "look": Vector3(14.4, 0.5, 3.4)},
]

static var cache: Dictionary = {}

var svc: SubViewportContainer
var vp: SubViewport
var cam: Camera3D
var yaw := 0.55
var dist := 19.0
var room := -1                      # -1 dollhouse, otherwise index into ROOMS
var look_yaw := 0.0
var spots: Array = []               # tappable things: {at, n, i, cb}
var moved := 0.0
var touches: Dictionary = {}
var pinch0 := 0.0
var dist0 := 19.0
var tw: Tween = null
var info: Control = null


func build():
	title = "My Home"
	var u = G.s.user
	var lf = G.OPS.life()
	var LIFE = load("res://scripts/screens/life.gd")
	var home = LIFE.HOMES[int(lf.home)]
	subtitle = "%s · %d bed · %s · drag to turn, tap a room or a thing" % [home[0], home[3], home[5]]
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
	_world(int(lf.home), lf)
	var ov = Control.new()
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	ov.gui_input.connect(_input_view)
	holder.add_child(ov)
	var bar = UI.hb(6)
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	bar.position = Vector2(14, -48)
	var mk = func(txt: String, on: bool, cb: Callable):
		var ch = UI.chip(txt.to_upper(), UI.accent if on else Color(UI.BG, 0.85), UI.on_color(UI.accent) if on else UI.TEXT, 15)
		UI.tap(ch, cb, true)
		bar.add_child(ch)
	mk.call("Dollhouse", room < 0, func(): _go(-1))
	for i in ROOMS.size():
		var idx = i
		mk.call(ROOMS[i].n, room == i, func(): _go(idx))
	holder.add_child(bar)
	var top = UI.hb(6)
	top.position = Vector2(14, 10)
	var p1 = UI.panel(Color(UI.BG, 0.85), 12, 12, 6, UI.LINE)
	var pv = UI.vb(-3)
	pv.add_child(UI.lbl(str(home[0]), 19, UI.TEXT, "semi"))
	pv.add_child(UI.lbl("%s in the bank" % G.money(lf.cash), 15, UI.GREEN))
	p1.add_child(pv)
	p1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(p1)
	var mv = UI.chip("MOVE HOUSE", Color(UI.BG, 0.85), UI.GOLD, 15)
	UI.tap(mv, func(): UI.main.root("life", {"grp": "manager"}), true)
	top.add_child(mv)
	holder.add_child(top)
	_aim(false)


func _enter_tree():
	UI.enter3d(true)


func _exit_tree():
	UI.enter3d(false)


func _go(i: int):
	room = i
	look_yaw = 0.0
	UI.sfx("click", -14.0)
	refresh()


# ---------------------------------------------------------------- building the place

func _mat(col: Color, unshaded := false) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.9
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func _box(size: Vector3, at: Vector3, col: Color, unshaded := false) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(col, unshaded)
	mi.position = at
	vp.add_child(mi)
	return mi


func _floor(x0: float, z0: float, x1: float, z1: float, col: Color, y := 0.0):
	_box(Vector3(x1 - x0, 0.06, z1 - z0), Vector3((x0 + x1) / 2.0, y - 0.03, (z0 + z1) / 2.0), col)


func _wall(x0: float, z0: float, x1: float, z1: float, h := 1.3, col := Color("e9e4d8")):
	var len = Vector2(x1 - x0, z1 - z0).length()
	var w = _box(Vector3(len if abs(x1 - x0) > abs(z1 - z0) else 0.12, h, 0.12 if abs(x1 - x0) > abs(z1 - z0) else len), Vector3((x0 + x1) / 2.0, h / 2.0, (z0 + z1) / 2.0), col)
	return w


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


func _put(nm: String, x: float, z: float, rot := 0.0, y := 0.0, sc := 1.0) -> Node3D:
	# places a kit model with its middle at (x, z), standing on y, turned rot degrees about its own middle
	var path = F + nm + ".glb"
	if not cache.has(path):
		cache[path] = load(path) if ResourceLoader.exists(path) else null
	if cache[path] == null:
		return null
	var n: Node3D = cache[path].instantiate()
	var bb = _aabb(n)
	var pivot = Node3D.new()
	pivot.position = Vector3(x, y, z)
	pivot.rotation_degrees.y = rot
	n.scale = Vector3.ONE * K * sc
	n.position = -Vector3(bb.position.x + bb.size.x / 2.0, bb.position.y, bb.position.z + bb.size.z / 2.0) * K * sc
	pivot.add_child(n)
	vp.add_child(pivot)
	return pivot


func _spot(at: Vector3, nm: String, cb: Callable):
	spots.append({"at": at, "n": nm, "cb": cb})
	var lb = Label3D.new()
	lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lb.text = "● " + nm.to_upper()
	lb.font = UI.fonts["semi"]
	lb.font_size = 30
	lb.fixed_size = true
	lb.pixel_size = 0.00055 if room < 0 else 0.0011
	lb.outline_size = 10
	lb.outline_modulate = Color(0, 0, 0, 0.9)
	lb.modulate = UI.GOLD
	lb.no_depth_test = true
	lb.position = at
	vp.add_child(lb)


func _world(lvl: int, lf: Dictionary):
	spots = []
	var env = WorldEnvironment.new()
	var e = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("6f9fd6")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color.WHITE
	e.ambient_light_energy = 0.42
	env.environment = e
	vp.add_child(env)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -40, 0)
	sun.light_energy = 0.62
	sun.shadow_enabled = not G.settings.get("lowgfx", false)
	sun.directional_shadow_max_distance = 45.0
	vp.add_child(sun)
	cam = Camera3D.new()
	cam.fov = 34.0
	vp.add_child(cam)
	var wood = [Color("8a6a48"), Color("8a6a48"), Color("5f4630"), Color("9a7a52"), Color("a88d68")][lvl]
	var tile = Color("9aa3ad")
	var wallc = [Color("b9b3a4"), Color("bdb7aa"), Color("a9b0bc"), Color("c2bcae"), Color("c8c2b4")][lvl]
	# grounds
	_box(Vector3(60, 0.1, 60), Vector3(8, -0.11, 4), Color("4a7a40"))
	_floor(12.0, 0.0, 16.5, 8.0, Color("6c7078"))                          # drive
	# floors: living, kitchen, bedroom, office, bathroom
	_floor(0, 0, 6, 5, wood)
	_floor(6, 0, 12, 3.5, tile)
	_floor(0, 5, 5, 8, wood.darkened(0.08))
	_floor(5, 5, 8.5, 8, wood.lightened(0.06))
	_floor(8.5, 3.5, 12, 8, Color("7fa0ad"))
	# walls, kept low so every room can be seen from above
	var h = 1.35
	_wall(0, 0, 12, 0, h, wallc)
	_wall(0, 8, 12, 8, h, wallc)
	_wall(0, 0, 0, 8, h, wallc)
	_wall(12, 0, 12, 2.2, h, wallc)
	_wall(12, 3.4, 12, 8, h, wallc)                                         # front door gap to the drive
	_wall(0, 5, 2.0, 5, h, wallc)
	_wall(3.2, 5, 5.0, 5, h, wallc)
	_wall(5, 5, 5, 6.0, h, wallc)
	_wall(5, 7.1, 5, 8, h, wallc)
	_wall(6.2, 5, 8.5, 5, h, wallc)
	_wall(8.5, 3.5, 8.5, 5.0, h, wallc)
	_wall(8.5, 6.2, 8.5, 8, h, wallc)
	_wall(6, 0, 6, 1.4, h, wallc)
	_wall(9.7, 3.5, 12, 3.5, h, wallc)
	# ---- living room
	_put("rugRectangle", 2.6, 2.6, 0.0, 0.01)
	_put("loungeSofaCorner" if lvl >= 1 else "loungeSofa", 2.6, 3.9, 180.0)
	if lvl >= 2:
		_put("loungeChairRelax", 4.7, 2.7, -90.0)
		_put("loungeSofaOttoman", 1.0, 2.6, 90.0)
	_put("tableCoffeeGlass" if lvl >= 2 else "tableCoffee", 2.6, 2.4)
	_put("cabinetTelevision", 2.6, 0.45)
	_put("televisionModern" if lvl >= 1 else "televisionVintage", 2.6, 0.42, 0.0, 0.62, 1.25 if lvl >= 3 else 1.0)
	_put("speaker", 1.2, 0.4)
	_put("speaker", 4.0, 0.4)
	_put("pottedPlant", 0.5, 0.5)
	_put("lampRoundFloor", 5.4, 0.5)
	_put("bookcaseOpen", 0.35, 3.2, 90.0)
	_put("books", 0.35, 3.2, 90.0, 0.92)
	_spot(Vector3(2.6, 1.9, 0.45), "Television", func(): UI.main.root("fixtures"))
	_spot(Vector3(0.4, 2.3, 3.2), "Scrapbook", func(): UI.main.root("hub", {"kind": "timeline", "grp": "manager"}))
	# ---- kitchen
	var kx = 6.5
	for nm in ["kitchenFridgeLarge" if lvl >= 2 else "kitchenFridge", "kitchenCabinet", "kitchenStoveElectric" if lvl >= 1 else "kitchenStove", "kitchenCabinetDrawer", "kitchenSink", "kitchenCabinet"]:
		_put(nm, kx, 0.5)
		kx += 0.88
	_put("hoodModern", 6.5 + 0.88 * 2, 0.35, 0.0, 1.75)
	_put("kitchenCoffeeMachine", 6.5 + 0.88, 0.45, 0.0, 0.9)
	_put("kitchenMicrowave", 6.5 + 0.88 * 5, 0.45, 0.0, 0.9)
	for i in 3 if lvl >= 1 else 2:
		_put("kitchenBar", 7.4 + i * 0.86, 2.4)
		_put("stoolBar", 7.4 + i * 0.86, 3.0)
	_spot(Vector3(6.5, 2.3, 0.5), "Fridge", func(): UI.toast(["Leftover pasta and half a lemon.", "Fully stocked. The nutritionist would approve.", "Champagne on ice: just in case."][clampi(lvl, 0, 2)], UI.MUTED))
	# ---- bedroom
	_put("rugRounded", 2.4, 6.6, 0.0, 0.01)
	_put("bedDouble", 2.4, 6.85, 180.0, 0.0, 1.0 if lvl < 3 else 1.15)
	_put("cabinetBedDrawerTable", 0.9, 7.55)
	_put("cabinetBedDrawerTable", 3.9, 7.55)
	_put("lampSquareTable", 0.9, 7.55, 0.0, 0.5)
	_put("bookcaseClosedDoors", 0.35, 5.7, 90.0)
	_put("bookcaseClosedDoors", 0.35, 6.5, 90.0)
	_put("bear", 4.5, 5.5, -45.0, 0.0, 0.7)
	_spot(Vector3(2.4, 1.4, 6.9), "Bed · sleep", func(): UI.main._go("day"))
	_spot(Vector3(0.4, 2.2, 6.1), "Wardrobe · kit", func(): UI.main.root("kit"))
	# ---- office
	_put("desk", 7.4, 7.45, 180.0)
	_put("computerScreen", 7.4, 7.6, 180.0, 0.77)
	_put("computerKeyboard", 7.4, 7.25, 180.0, 0.77)
	_put("laptop", 6.5, 7.4, 150.0, 0.77)
	_put("chairDesk", 7.4, 6.7, 0.0)
	_put("bookcaseOpenLow" if lvl < 2 else "bookcaseClosedWide", 5.45, 6.6, 90.0)
	_put("lampSquareFloor", 8.1, 5.4)
	_put("pottedPlant", 5.5, 7.6)
	_spot(Vector3(7.4, 1.9, 7.5), "Computer · inbox", func(): UI.main.root("inbox"))
	# trophies on the shelf: one small cup for each one won
	var tn = min(6, G.s.user.get("trophies", []).size())
	for i in tn:
		_box(Vector3(0.09, 0.16, 0.09), Vector3(5.42, 1.05 if lvl < 2 else 1.8, 6.2 + i * 0.16), Color("f2c019"))
	_spot(Vector3(5.45, 2.4, 6.6), "Trophies · %d" % G.s.user.get("trophies", []).size(), func(): UI.main.root("trophies"))
	# ---- bathroom
	_put("bathtub", 10.4, 7.35, 0.0)
	_put("toilet", 11.5, 4.2, -90.0)
	_put("bathroomSinkSquare" if lvl >= 2 else "bathroomSink", 9.0, 5.8, 90.0, 0.8)
	_put("bathroomMirror", 8.62, 5.8, 90.0, 1.3)
	_put("washerDryerStacked", 11.55, 5.6, -90.0)
	if lvl >= 1:
		_put("showerRound", 9.2, 4.1)
	# ---- hallway bits
	_put("coatRackStanding", 11.5, 2.9)
	_put("rugDoormat", 11.4, 2.8, 90.0, 0.01)
	_put("benchCushion", 10.6, 3.15, 180.0)
	# ---- outside: the car(s), and more as the home gets grander
	var car = G.OPS.car_node(int(lf.get("car", 0)))
	if car != null:
		car.position = Vector3(14.3, 0.02, 3.4)
		car.rotation_degrees.y = 180.0
		vp.add_child(car)
	var LIFE = load("res://scripts/screens/life.gd")
	_spot(Vector3(14.3, 2.0, 3.4), "%s" % str(LIFE.CARS[int(lf.get("car", 0))][1]), func(): UI.main.root("life", {"grp": "manager"}))
	var others = []
	for ci in lf.get("cars", []):
		if int(ci) != int(lf.get("car", 0)):
			others.append(int(ci))
	for i in min(2, others.size()):
		var c2 = G.OPS.car_node(others[i])
		if c2 != null:
			c2.position = Vector3(14.3, 0.02, 6.3 - i * 5.6 if i == 0 else 0.9)
			c2.rotation_degrees.y = 180.0
			vp.add_child(c2)
	for tp in [Vector2(-1.5, 1.0), Vector2(-1.8, 6.5), Vector2(5.5, -1.6), Vector2(10.5, -1.5), Vector2(3.0, 9.6)]:
		var tr = load("res://assets/city3d/suburban/tree-large.glb").instantiate() if ResourceLoader.exists("res://assets/city3d/suburban/tree-large.glb") else null
		if tr != null:
			tr.position = Vector3(tp.x, 0, tp.y)
			tr.scale = Vector3.ONE * 2.6
			vp.add_child(tr)
	if lvl >= 3:
		# pool and terrace
		_floor(1.0, 9.2, 8.0, 13.5, Color("a59d8a"))
		_box(Vector3(5.0, 0.08, 2.6), Vector3(4.5, 0.0, 11.3), Color("3fb7e6"), true)
		_put("loungeChairRelax", 1.9, 10.2, 90.0)
		_put("loungeChairRelax", 1.9, 12.2, 90.0)
	if lvl >= 4:
		# a private five-a-side pitch
		var pm = MeshInstance3D.new()
		var pl = PlaneMesh.new()
		pl.size = Vector2(9.0, 6.0)
		pm.mesh = pl
		var m = StandardMaterial3D.new()
		m.albedo_texture = load("res://assets/m3d/pitch.jpg")
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		pm.material_override = m
		pm.position = Vector3(5.5, 0.01, -5.0)
		vp.add_child(pm)


# ---------------------------------------------------------------- camera and input

func _aim(smooth := true):
	if cam == null:
		return
	var pos: Vector3
	var tgt: Vector3
	if room < 0:
		var centre = Vector3(7.0, 0.4, 4.2)
		pos = centre + Vector3(sin(yaw), 0.95, cos(yaw)).normalized() * dist
		tgt = centre
	else:
		var r = ROOMS[room]
		pos = r.eye
		var d: Vector3 = r.look - r.eye
		tgt = r.eye + d.rotated(Vector3.UP, look_yaw)
	cam.position = pos
	cam.look_at(tgt)
	cam.fov = 34.0 if room < 0 else 62.0


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
		if touches.size() >= 2 and room < 0:
			var p2 = touches.values()
			if pinch0 > 10.0:
				dist = clamp(dist0 * pinch0 / max(10.0, p2[0].distance_to(p2[1])), 10.0, 30.0)
		elif room < 0:
			yaw -= e.relative.x * 0.006
		else:
			look_yaw += e.relative.x * 0.005
		_aim()
	elif e is InputEventMouseButton:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP:
			dist = max(10.0, dist - 1.0)
			_aim()
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			dist = min(30.0, dist + 1.0)
			_aim()
		elif e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				moved = 0.0
			elif moved < 12.0 and not DisplayServer.is_touchscreen_available():
				_tap(e.position)
	elif e is InputEventMouseMotion and e.button_mask & MOUSE_BUTTON_MASK_LEFT and not DisplayServer.is_touchscreen_available():
		moved += e.relative.length()
		if room < 0:
			yaw -= e.relative.x * 0.006
		else:
			look_yaw += e.relative.x * 0.005
		_aim()


func _tap(at: Vector2):
	var best = null
	var bd = 70.0
	var k = float(svc.stretch_shrink)
	for sp in spots:
		if cam.is_position_behind(sp.at):
			continue
		var p = cam.unproject_position(sp.at) * k
		var d = p.distance_to(at)
		if d < bd:
			bd = d
			best = sp
	if best != null:
		UI.sfx("click", -14.0)
		best.cb.call()

extends "res://scripts/widgets/pitch.gd"
# Live 2D match view: 22 players that shift with the play, the ball, and a shot map at full time.

var sim = null
var dots: Array = [[], []]
var cols: Array = [Color.WHITE, Color.RED]
var rims: Array = [Color.BLACK, Color.WHITE]
var bpos := Vector2(0.5, 0.5)
var bdest := Vector2(0.5, 0.5)
var carrier := Vector2i(-1, -1)
var shot_mode := false
var t := 0.0


func setup(s):
	sim = s
	vertical = false
	for i in 2:
		var c = sim.sd[i].club
		var a = Color(c.c1)
		var b = Color(c.c2)
		cols[i] = a
		rims[i] = b
	# avoid kit clashes: the away side changes into its second colour, or a neutral dark kit
	if _dist(cols[0], cols[1]) < 0.5:
		var alt = rims[1]
		if _dist(cols[0], alt) < 0.5:
			alt = Color("1b2333") if cols[0].get_luminance() > 0.3 else Color("f6ad3c")
		rims[1] = Color.WHITE if alt.get_luminance() < 0.5 else Color("10141f")
		cols[1] = alt
	for i in 2:
		if _dist(cols[i], rims[i]) < 0.25:
			rims[i] = Color.WHITE if cols[i].get_luminance() < 0.5 else Color("10141f")
	for i in 2:
		dots[i] = []
		for k in 11:
			dots[i].append(_target(i, k))


func _dist(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()


func _target(i: int, k: int) -> Vector2:
	var sd = sim.sd[i]
	var sl = sd.slots[k]
	var bx = sim.ball.x if i == 0 else 1.0 - sim.ball.x
	var by = sim.ball.y if i == 0 else 1.0 - sim.ball.y
	var poss = sim.ball_side == i
	var along = 0.035 + 0.04 * bx
	if k > 0:
		along = clamp(0.1 + sl[2] * 0.5 + (bx - 0.5) * 0.44 + (0.07 if poss else -0.03), 0.08, 0.94)
	var across = clamp(sl[1] + (by - 0.5) * (0.1 if k == 0 else 0.24), 0.04, 0.96)
	var wob = Vector2(sin(t * 1.3 + k * 2.1 + i) * 0.008, cos(t * 1.1 + k * 1.7 + i * 3.0) * 0.012)
	if i == 0:
		return Vector2(along, across) + wob
	return Vector2(1.0 - along, 1.0 - across) + wob


func tick():
	# called once per simulated minute
	if sim.ball_state == "GOAL":
		carrier = Vector2i(-1, -1)
		bdest = Vector2(0.995 if sim.ball_side == 0 else 0.005, 0.5)
	elif sim.ball_state == "SHOT":
		carrier = Vector2i(-1, -1)
		bdest = Vector2(0.972 if sim.ball_side == 0 else 0.028, 0.5 + (sim.ball.y - 0.5) * 0.5)
	else:
		var side = sim.ball_side
		var best = 1
		var bd = 99.0
		for k in range(1, 11):
			if sim.sd[side].xi[k] < 0:
				continue
			var d = dots[side][k].distance_to(sim.ball)
			if d < bd:
				bd = d
				best = k
		carrier = Vector2i(side, best)


func _process(delta):
	if sim == null or shot_mode:
		return
	t += delta
	var k1 = 1.0 - exp(-delta * 3.2)
	for i in 2:
		for k in 11:
			dots[i][k] = dots[i][k].lerp(_target(i, k), k1)
	if carrier.x >= 0:
		var c = dots[carrier.x][carrier.y]
		bdest = c + Vector2(0.012 if carrier.x == 0 else -0.012, 0.0)
	bpos = bpos.lerp(bdest, 1.0 - exp(-delta * 9.0))
	queue_redraw()


func _draw():
	super._draw()
	if sim == null:
		return
	if shot_mode:
		for s in sim.shots:
			var p = pt(s[1], s[2])
			var r = 6.0 + sqrt(s[4]) * 22.0
			var c = cols[s[0]] if cols[s[0]].get_luminance() > 0.15 else rims[s[0]]
			if s[3]:
				draw_circle(p, r, UI.GOLD)
				draw_arc(p, r + 3, 0, TAU, 24, Color.WHITE, 2, true)
			else:
				draw_circle(p, r, Color(c, 0.35))
				draw_arc(p, r, 0, TAU, 24, c, 2, true)
		return
	for i in 2:
		for k in 11:
			if sim.sd[i].xi[k] < 0:
				continue
			var p = pt(dots[i][k].x, dots[i][k].y)
			var on = carrier.x == i and carrier.y == k
			draw_circle(p + Vector2(0, 2), 12, Color(0, 0, 0, 0.3))
			draw_circle(p, 11.5, rims[i])
			draw_circle(p, 9.5, cols[i] if k > 0 else cols[i].darkened(0.5))
			if on:
				draw_arc(p, 15, 0, TAU, 24, Color(1, 1, 1, 0.8), 2, true)
	var b = pt(bpos.x, bpos.y)
	draw_circle(b, 9, Color(0, 0, 0, 0.35))
	draw_circle(b, 6.5, Color.WHITE)
	draw_arc(b, 6.5, 0, TAU, 16, Color(0, 0, 0, 0.5), 1.5, true)

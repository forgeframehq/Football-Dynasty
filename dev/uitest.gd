extends RefCounted
# Dev tool: drives the UI with synthetic touches to check taps and drag-scrolling.

var main


func touch(pos: Vector2, pressed: bool):
	var e = InputEventScreenTouch.new()
	e.index = 0
	e.position = pos
	e.pressed = pressed
	Input.parse_input_event(e)


func drag(from: Vector2, to: Vector2):
	touch(from, true)
	await main.get_tree().process_frame
	for i in 10:
		var e = InputEventScreenDrag.new()
		e.index = 0
		e.position = from.lerp(to, (i + 1) / 10.0)
		e.relative = (to - from) / 10.0
		Input.parse_input_event(e)
		await main.get_tree().process_frame
	touch(to, false)
	for i in 3:
		await main.get_tree().process_frame


func tap(pos: Vector2):
	touch(pos, true)
	await main.get_tree().process_frame
	await main.get_tree().process_frame
	touch(pos, false)
	for i in 4:
		await main.get_tree().process_frame


func run(m):
	main = m
	var vs = main.size
	print("viewport ", vs)
	for i in 5:
		await main.get_tree().process_frame
	G.new_game("Tester", 1)
	main.root("home")
	for i in 5:
		await main.get_tree().process_frame
	await tap(Vector2(vs.x * 0.3, vs.y - 50))
	print("tab after nav tap: ", main.cur_tab, " (expect squad)")
	var sc = main.stack[-1].sc
	await drag(Vector2(360, 900), Vector2(360, 500))
	print("scroll after drag: ", sc.scroll_vertical, " (expect > 0), top screen: ", main.stack[-1].sname, " (expect squad)")
	await main.get_tree().create_timer(0.8).timeout
	await tap(Vector2(300, 700))
	print("top after row tap: ", main.stack[-1].sname, " (expect player)")
	await tap(Vector2(50, 60))
	print("top after back tap: ", main.stack[-1].sname, " (expect squad)")
	await tap(Vector2(vs.x * 0.5, vs.y - 50))
	print("tab: ", main.cur_tab, " (expect tactics)")
	var c = G.uc()
	var before = c.xi.duplicate()
	var toks = main.stack[-1].pitch.get_children()
	await tap(toks[9].global_position + Vector2(66, 40))
	await tap(main.stack[-1].pitch.get_children()[10].global_position + Vector2(66, 40))
	print("xi swapped: ", before[9] == c.xi[10] and before[10] == c.xi[9])
	main.get_tree().quit()

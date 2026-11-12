extends Control
# Rounded progress bar.

var frac := 0.5
var color := Color.WHITE
var bg := Color(1, 1, 1, 0.08)


func _draw():
	var r = size.y / 2.0
	var sb = StyleBoxFlat.new()
	sb.set_corner_radius_all(int(r))
	sb.bg_color = bg
	draw_style_box(sb, Rect2(Vector2.ZERO, size))
	if frac > 0.0:
		var sf = StyleBoxFlat.new()
		sf.set_corner_radius_all(int(r))
		sf.bg_color = color
		draw_style_box(sf, Rect2(0, 0, max(size.y, size.x * frac), size.y))

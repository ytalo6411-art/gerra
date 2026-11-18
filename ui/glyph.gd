extends Control
## Small original line-art inventory and wayfinding glyphs.

var kind := ""
var tint := Color.WHITE
var scale_unit := 1.0
var center := Vector2.ZERO

func setup(shape: String, paint: Color) -> void:
	kind = shape
	tint = paint
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _draw() -> void:
	scale_unit = minf(size.x, size.y) / 24.0
	center = size * 0.5 - Vector2.ONE * 12 * scale_unit
	match kind:
		"compass":
			_circle(Vector2(12, 12), 9.2, false)
			_poly([Vector2(7, 17), Vector2(10, 10), Vector2(17, 7), Vector2(14, 14), Vector2(7, 17)])
			_line(Vector2(10, 10), Vector2(14, 14))
		"water":
			_poly([Vector2(12, 3), Vector2(18, 11.2), Vector2(19, 14.9), Vector2(17, 19), Vector2(12, 21), Vector2(7, 19), Vector2(5, 14.9), Vector2(6, 11.2), Vector2(12, 3)])
			_poly([Vector2(9, 14.4), Vector2(9.8, 17), Vector2(12.4, 18)], 1.3)
		"food", "ration":
			_poly([Vector2(5, 5), Vector2(19, 5), Vector2(20, 20), Vector2(4, 20), Vector2(5, 5)])
			_line(Vector2(5, 8.4), Vector2(19, 8.4))
			_line(Vector2(8, 13), Vector2(16, 13))
			_line(Vector2(8, 16), Vector2(13, 16))
		"branch":
			_poly([Vector2(4, 16), Vector2(6, 19), Vector2(20, 10), Vector2(18, 7), Vector2(4, 16)])
			_poly([Vector2(6.5, 13.9), Vector2(4.5, 10), Vector2(8.4, 7.5), Vector2(12.3, 10.4)])
			_line(Vector2(13.1, 15.1), Vector2(17.8, 20.0))
		"berries":
			_circle(Vector2(8.5, 12.4), 3.8, false)
			_circle(Vector2(15.6, 12.4), 3.8, false)
			_circle(Vector2(12.1, 18), 3.2, false)
			_poly([Vector2(12, 8.6), Vector2(12, 5), Vector2(16.5, 3.3)])
		"health":
			_poly([Vector2(12, 20), Vector2(4.5, 13), Vector2(3.5, 8), Vector2(6.3, 5.4), Vector2(9.2, 5.4), Vector2(12, 8), Vector2(14.8, 5.4), Vector2(17.7, 5.4), Vector2(20.5, 8), Vector2(19.5, 13), Vector2(12, 20)])
		"energy":
			_poly([Vector2(13.3, 2.7), Vector2(5.3, 13.5), Vector2(11, 13.5), Vector2(10.7, 21.3), Vector2(18.7, 10.8), Vector2(13, 10.8), Vector2(13.3, 2.7)])
		"check":
			_poly([Vector2(6, 12), Vector2(10, 16), Vector2(18, 8)], 2.1)
		"map":
			_poly([Vector2(3.5, 5.5), Vector2(9.1, 4), Vector2(14.9, 6.2), Vector2(20.5, 4.8), Vector2(20.5, 18.5), Vector2(14.9, 20), Vector2(9.1, 17.8), Vector2(3.5, 19.2), Vector2(3.5, 5.5)])
			_line(Vector2(9.1, 4), Vector2(9.1, 17.8))
			_line(Vector2(14.9, 6.2), Vector2(14.9, 20))
		"arrow":
			_poly([Vector2(12, 4), Vector2(18, 18.5), Vector2(12, 15.5), Vector2(6, 18.5), Vector2(12, 4)])
		"pin":
			_poly([Vector2(12, 2.5), Vector2(18.6, 10), Vector2(12, 18.5), Vector2(5.4, 10), Vector2(12, 2.5)])
			_circle(Vector2(12, 10), 1.45, true)
		"fire":
			_poly([Vector2(12, 3), Vector2(15.4, 8.9), Vector2(16, 12), Vector2(19, 9.1), Vector2(19, 16), Vector2(16, 20.5), Vector2(12, 21.6), Vector2(7.5, 20), Vector2(5, 15.7), Vector2(7.1, 10.5), Vector2(9.5, 13), Vector2(12, 3)])
		"house":
			_poly([Vector2(3, 11), Vector2(12, 4), Vector2(21, 11)])
			_poly([Vector2(6, 9), Vector2(6, 20), Vector2(18, 20), Vector2(18, 9)])
			_poly([Vector2(10, 19.6), Vector2(10, 14), Vector2(14, 14), Vector2(14, 19.6)])
		"bag":
			_poly([Vector2(5, 9), Vector2(7, 6.2), Vector2(17, 6.2), Vector2(19, 9), Vector2(19, 20), Vector2(5, 20), Vector2(5, 9)])
			_poly([Vector2(9, 6), Vector2(9, 3.5), Vector2(15, 3.5), Vector2(15, 6)])
			_poly([Vector2(8.4, 12.2), Vector2(15.6, 12.2), Vector2(15.6, 17.7), Vector2(8.4, 17.7), Vector2(8.4, 12.2)])

func _poly(points: Array, weight: float = 1.55) -> void:
	var path := PackedVector2Array()
	for point: Vector2 in points:
		path.append(center + point * scale_unit)
	draw_polyline(path, tint, maxf(weight * scale_unit, 1.0), true)

func _line(a: Vector2, b: Vector2) -> void:
	_poly([a, b])

func _circle(at: Vector2, radius: float, fill: bool) -> void:
	draw_circle(center + at * scale_unit, radius * scale_unit, tint, fill, -1.0 if fill else maxf(1.0, 1.5 * scale_unit), true)

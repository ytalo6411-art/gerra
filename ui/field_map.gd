extends Control
## Lightweight notebook cartography aligned to the same world manifest and coordinates.

const Land = preload("res://world/landscape.gd")
const Palette = preload("res://ui/palette.gd")
const Catalog = preload("res://systems/catalog.gd")

var catalog: Catalog
var point := Vector2.ZERO
var heading := 0.0
var goal := "pump_cedro"
var radius := 25.0
var detailed := false
var face: Font
var _center := Vector2.ZERO
var _zoom := 1.0
var _rect := Rect2()

func update_location(where: Vector3, yaw: float, objective: String) -> void:
	point = Vector2(where.x, where.z)
	heading = yaw
	goal = objective
	if visible:
		queue_redraw()

func _draw() -> void:
	if catalog == null or size.x < 20.0:
		return
	_rect = Rect2(Vector2.ZERO, size)
	draw_rect(_rect, Color("2b382b"))
	_zoom = size.y / (2.0 * radius)
	_center = point
	var top_left := _center - size * 0.5 / _zoom
	var bottom_right := _center + size * 0.5 / _zoom
	var grid := 8 if detailed else 12
	for x in range(floori(top_left.x / grid) * grid, ceili(bottom_right.x), grid):
		for z in range(floori(top_left.y / grid) * grid, ceili(bottom_right.y), grid):
			var at := Vector2(x, z)
			var p := _map(at)
			var low := _map(at + Vector2.ONE * grid)
			var patch := Rect2(p, low - p).intersection(_rect)
			var mix := Land.woodland(x, z) * 0.5 + (0.25 + 0.25 * sin(x * 0.26 + z * 0.25))
			draw_rect(patch, Color("394638").lerp(Color("253529"), mix))
	for i in range(5):
		var contour := PackedVector2Array()
		for band in range(26):
			var n := float(band) / 25.0
			var x := top_left.x + n * (bottom_right.x - top_left.x)
			var z := top_left.y + (0.11 + i * 0.17) * (bottom_right.y - top_left.y) + 3.2 * sin(x * 0.15 + i * 1.1) + 1.3 * cos(n * 9.0)
			contour.append(_map(Vector2(x, z)))
		draw_polyline(contour, Color("58614b66"), 1.0, true)
	for x in range(floori(top_left.x / 16) * 16, ceili(bottom_right.x), 16):
		draw_line(_map(Vector2(x, top_left.y)), _map(Vector2(x, bottom_right.y)), Color("9aa78023"), 1.0)
	for z in range(floori(top_left.y / 16) * 16, ceili(bottom_right.y), 16):
		draw_line(_map(Vector2(top_left.x, z)), _map(Vector2(bottom_right.x, z)), Color("9aa78023"), 1.0)
	var creek := PackedVector2Array()
	for z in range(floori(top_left.y) - 1, ceili(bottom_right.y) + 2, 2):
		creek.append(_map(Vector2(Land.creek_x(z), z)))
	if creek.size() > 1:
		draw_polyline(creek, Color("576d67"), _zoom * 5.8, true)
		draw_polyline(creek, Color("748f86"), maxf(2, _zoom * 3.5), true)
	for trail: Array in Land.TRAILS:
		var path := PackedVector2Array()
		for p: Vector2 in trail: path.append(_map(p))
		draw_polyline(path, Color("8e825e"), 1.75 if detailed else 1.2, true)
	var structs: Dictionary = catalog.world["structures"]
	_zone(Catalog.point(structs["cabin"]), Vector2(9.4, 7.5), Color("9c8e70"))
	_zone(Catalog.point(structs["shed"]), Vector2(4.6, 3.4), Color("7b6c54"))
	_zone(Catalog.point(structs["pen"]), Vector2(5, 4.1), Color("646453"))
	var bridge_z := float(structs["bridge_z"])
	_zone(Vector2(Land.creek_x(bridge_z), bridge_z), Vector2(8.4, 1.9), Color("b29c72"))
	_mark("pump_cedro", "Água", Palette.WATER)
	_mark("fire_cedro", "Fogueira", Palette.GOLD)
	if not goal.is_empty() and catalog.objects.has(goal):
		var marker := _map(Catalog.point(catalog.objects[goal]["pos"]))
		if _rect.grow(-8).has_point(marker):
			draw_arc(marker, 7.8, 0, TAU, 24, Palette.GOLD, 1.1, true)
	var me := _map(point)
	var shape := PackedVector2Array()
	for p: Vector2 in [Vector2(0,-7.2), Vector2(5.3,5.4), Vector2(0,2.6), Vector2(-5.3,5.4)]:
		shape.append(me + p.rotated(-heading))
	draw_colored_polygon(shape, Color("fff2c9"))
	if face != null:
		draw_string(face, Vector2(size.x - 23, 22), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Palette.TEXT)
		draw_line(Vector2(size.x - 18, 28), Vector2(size.x - 18, 38), Palette.GOLD, 1.0)
		if detailed:
			draw_string(face, Vector2(12, size.y - 13), "LOCALIZAÇÃO ATUAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Palette.TEXT)

func _map(p: Vector2) -> Vector2:
	return (p - _center) * _zoom + size * 0.5

func _zone(p: Vector2, dimensions: Vector2, color: Color) -> void:
	var r := Rect2(_map(p) - dimensions * _zoom * 0.5, dimensions * _zoom)
	draw_rect(r, color)
	draw_rect(r, color.lightened(0.25), false, 1.0)

func _mark(id: String, title: String, color: Color) -> void:
	var p := _map(Catalog.point(catalog.objects[id]["pos"]))
	if not _rect.grow(-8).has_point(p):
		return
	draw_circle(p, 4.3, Palette.INK)
	draw_circle(p, 2.65, color)
	if detailed and face != null:
		draw_string(face, p + Vector2(7, -6), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Palette.TEXT)

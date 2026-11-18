extends RefCounted

const Land = preload("res://world/landscape.gd")
const Kit = preload("res://world/mesh_kit.gd")
const Catalog = preload("res://systems/catalog.gd")
const LEAVES := [Color("304d3b"), Color("435d45"), Color("526746"), Color("64764a"), Color("3d5842"), Color("707d51")]
const GRASSES := [Color("828756"), Color("a0a064"), Color("6a7f50"), Color("b2a66b"), Color("68754c"), Color("92975d")]
const CLEARING_TREES := [
	[Vector2(-11.6, -7.8), 7.2], [Vector2(-12.9, -11.8), 6.2], [Vector2(-9.2, -11.6), 5.7],
	[Vector2(2.8, -13.5), 6.1], [Vector2(5.1, -16.3), 8.1], [Vector2(11.6, -9.0), 5.2],
	[Vector2(11.5, -14.3), 6.6], [Vector2(-13.6, 7.6), 5.9], [Vector2(6.7, 14.7), 5.8],
	[Vector2(24.3, 6.6), 7.1], [Vector2(23.6, 15.9), 5.9], [Vector2(22.7, -4.5), 6.8]
]
const ROCKS := [Color("7b8176"), Color("919087"), Color("606b63"), Color("777667")]

var kit: Kit
var catalog: Catalog

func _init(mesh_kit: Kit, definitions: Catalog) -> void:
	kit = mesh_kit
	catalog = definitions

func populate(parent: Node3D, origin: Vector2, width: int, cell: Vector2i) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(catalog.world["seed"]) + (cell.x + 8) * 997 + (cell.y + 8) * 11939
	var batch: Dictionary = {}
	var blockers := StaticBody3D.new()
	blockers.name = "Troncos"
	var columns := int(width / 4)
	for z in range(columns):
		for x in range(columns):
			var point := origin + Vector2(4.0 * x + rng.randf_range(0.43, 3.57), 4.0 * z + rng.randf_range(0.43, 3.57))
			if not _can_tree(point) or rng.randf() > Land.woodland(point.x, point.y) * 0.66:
				continue
			var base := Land.at(point)
			var height := rng.randf_range(3.6, 8.8)
			var is_conifer := rng.randf() > 0.29
			_tree(batch, base, height, is_conifer, rng)
			Kit.add_box_shape(blockers, base + Vector3.UP, Vector3(0.30 + height * 0.041, 2.5, 0.30 + height * 0.041))
	for i in range(CLEARING_TREES.size()):
		var at: Vector2 = CLEARING_TREES[i][0]
		if not Rect2(origin, Vector2.ONE * width).has_point(at):
			continue
		var base := Land.at(at)
		var h: float = CLEARING_TREES[i][1]
		_tree(batch, base, h, i % 3 != 0, rng)
		Kit.add_box_shape(blockers, base + Vector3.UP, Vector3(0.57, 2.4, 0.57))
	if blockers.get_child_count() > 0:
		parent.add_child(blockers)
	else:
		blockers.free()
	var density := 645 if Rect2(-32, -32, 64, 64).intersects(Rect2(origin, Vector2.ONE * width)) else 375
	for i in range(density):
		var p := origin + Vector2(rng.randf_range(0.03, width - 0.03), rng.randf_range(0.03, width - 0.03))
		var river := absf(p.x - Land.creek_x(p.y))
		var path_distance := Land.trail_distance(p)
		if river < 3.06 or _footprint(p) or (path_distance < 0.70 and rng.randf() < 0.94):
			continue
		var g := Land.at(p, -0.026)
		var n := rng.randi_range(0, GRASSES.size() - 1)
		var size := rng.randf_range(0.53, 1.42)
		if river < 5.0:
			size *= 1.42
		Kit.stamp(batch, "grass", g, Vector3(size, size, size), GRASSES[n], Vector3(0, rng.randf() * TAU, 0), false)
		if i % 14 == 0 or (river < 5.1 and i % 3 == 0):
			var stone := rng.randf_range(0.15, 0.94)
			Kit.stamp(batch, "stone", g + Vector3.UP * stone * 0.09, Vector3(stone, 0.52 * stone, stone * 0.81), ROCKS[rng.randi_range(0, 3)], Vector3(0, rng.randf() * TAU, 0), false)
		if i % 32 == 0 and path_distance > 1.4:
			_shrub(batch, g, rng)
		if i % 43 == 0 and river > 4.8:
			for k in range(3):
				var offset := Vector3(rng.randf_range(-0.21, 0.21), rng.randf_range(0.16, 0.37), rng.randf_range(-0.19, 0.19))
				Kit.stamp(batch, "ball", g + offset, Vector3(0.058, 0.034, 0.058), Color("b99a68") if k % 2 == 0 else Color("cdc6a1"), Vector3.ZERO, false)
	if cell == Vector2i(-1, 0):
		_left_bank_debris(batch)
	if cell == Vector2i(0, 0):
		_levee(batch)
	kit.emit_batch(parent, batch)

static func _left_bank_debris(batch: Dictionary) -> void:
	var p := Land.at(Vector2(-11.5, 8.9))
	Kit.stamp(batch, "trunk", p + Vector3.UP * 0.28, Vector3(0.52, 3.8, 0.56), Color("605342"), Vector3(PI * 0.47, -0.60, 0))
	Kit.stamp(batch, "round", p + Vector3(-0.99, 0.115, 1.52), Vector3(0.48, 0.10, 0.49), Color("a38964"), Vector3(PI * 0.47, -0.60, 0))
	for i in range(6):
		var b := p + Vector3(sin(i * 2.4) * 1.6, 0.20, cos(i * 2.4) * 1.52)
		Kit.stamp(batch, "stone", b, Vector3(0.73, 0.44, 0.56), Color("72766a"), Vector3(0, i * 1.25, 0))

static func _levee(batch: Dictionary) -> void:
	for i in range(15):
		var z := 1.0 + i * 1.18
		if absf(z - 10.3) < 1.75:
			continue
		var x := Land.creek_x(z) - 3.5 - 0.48 * sin(i * 1.7)
		var p := Land.at(Vector2(x, z), 0.14)
		var span := 0.65 + 0.32 * sin(i * 2.1)
		Kit.stamp(batch, "stone", p, Vector3(span, span * 0.55, span * 0.86), ROCKS[i % 4], Vector3(0, i * 0.77, 0))

func _footprint(p: Vector2) -> bool:
	var structures: Dictionary = catalog.world["structures"]
	var cabin := Catalog.point(structures["cabin"])
	var shed := Catalog.point(structures["shed"])
	var fire := Catalog.point(catalog.objects["fire_cedro"]["pos"])
	return (Rect2(cabin - Vector2(5.1, 4.1), Vector2(10.2, 8.45)).has_point(p)
		or Rect2(shed - Vector2(2.42, 1.84), Vector2(4.84, 3.68)).has_point(p)
		or fire.distance_squared_to(p) < 1.23)

func _can_tree(p: Vector2) -> bool:
	return absf(p.x - Land.creek_x(p.y)) > 4.6 and Land.trail_distance(p) > 2.0 and not _footprint(p)

static func _tree(batch: Dictionary, base: Vector3, height: float, conifer: bool, rng: RandomNumberGenerator) -> void:
	var tint: Color = LEAVES[rng.randi_range(0, LEAVES.size() - 1)]
	var yaw := rng.randf() * TAU
	var lean := rng.randf_range(-0.09, 0.09)
	Kit.stamp(batch, "trunk", base + Vector3.UP * height * 0.38, Vector3(height * 0.112, height * 0.91, height * 0.109), Color("64513d"), Vector3(lean, yaw, lean))
	if conifer:
		var spread := rng.randf_range(0.34, 0.55) * height
		for i in range(4):
			var v := float(i) / 3.0
			var d := spread * (1.0 - v * 0.68)
			var center := base + Vector3(lean * height * v, height * (0.51 + v * 0.355), -lean * height * v)
			Kit.stamp(batch, "cone", center, Vector3(d, height * (0.36 - v * 0.05), d * 0.88), tint.lightened(v * 0.20).darkened((1.0 - v) * 0.15), Vector3(lean, yaw + i * 0.29, -lean))
	else:
		for i in range(5):
			var a := yaw + float(i) * 2.4
			var offset := Vector3(cos(a) * height * 0.13, height * (0.66 + i * 0.044), sin(a) * height * 0.145)
			var size := height * rng.randf_range(0.35, 0.49)
			Kit.stamp(batch, "stone", base + offset, Vector3(size, size * 0.75, size * 0.95), tint.lightened(i * 0.037), Vector3(0, a, lean))

static func _shrub(batch: Dictionary, at: Vector3, rng: RandomNumberGenerator) -> void:
	for n in range(3):
		var size := rng.randf_range(0.34, 0.82)
		var lift := Vector3(rng.randf_range(-0.20, 0.20), size * 0.26, rng.randf_range(-0.19, 0.19))
		Kit.stamp(batch, "stone", at + lift, Vector3(size, size * 0.82, size), LEAVES[rng.randi_range(1, 5)], Vector3.ZERO, false)

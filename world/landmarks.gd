extends RefCounted

const Land = preload("res://world/landscape.gd")
const Kit = preload("res://world/mesh_kit.gd")
const WOOD := Color("84694a")
const END := Color("a28763")
var kit: Kit

func _init(meshes: Kit) -> void:
	kit = meshes

func shed(parent: Node3D, point: Vector2) -> void:
	var root := Node3D.new()
	root.position = Land.at(point)
	parent.add_child(root)
	var batch: Dictionary = {}
	var walls := StaticBody3D.new()
	root.add_child(walls)
	for i in range(19):
		var x := -2.18 + 0.24 * i
		var tint := WOOD.lerp(Color("918979"), 0.46 + 0.31 * sin(float(i) * 2.4))
		Kit.stamp(batch, "box", Vector3(x, 1.17, -1.64), Vector3(0.237, 2.37, 0.13), tint)
		if x < -0.80 or x > 0.80:
			Kit.stamp(batch, "box", Vector3(x, 0.99, 1.64), Vector3(0.237, 2.0, 0.13), tint)
	for sign_value: float in [-1.0, 1.0]:
		for i in range(14):
			var z := -1.56 + 0.24 * i
			var h := 2.18 - z * 0.14
			Kit.stamp(batch, "box", Vector3(sign_value * 2.22, h * 0.5, z), Vector3(0.139, h, 0.233), WOOD.lightened(0.14 + 0.11 * sin(float(i) * 1.7)))
		Kit.add_box_shape(walls, Vector3(sign_value * 2.22, 1.08, 0), Vector3(0.15, 2.2, 3.25))
		Kit.add_box_shape(walls, Vector3(sign_value * 1.54, 1.05, 1.64), Vector3(1.4, 2.1, 0.14))
	Kit.add_box_shape(walls, Vector3(0, 1.17, -1.64), Vector3(4.48, 2.34, 0.15))
	Kit.stamp(batch, "box", Vector3(0, 2.36, 0), Vector3(4.98, 0.15, 4.12), Color("6d5c4f"), Vector3(0.14, 0, 0))
	for i in range(20):
		var tint := Color("776151").lerp(Color("8a775f"), 0.5 + 0.5 * sin(float(i) * 1.4))
		Kit.stamp(batch, "box", Vector3(-2.35 + i * 0.246, 2.45, -0.015), Vector3(0.22, 0.07, 4.12), tint, Vector3(0.14, 0, 0), false)
	Kit.stamp(batch, "box", Vector3(1.42, 0.31, -0.68), Vector3(1.18, 0.63, 1.2), Color("a29a63"))
	Kit.stamp(batch, "box", Vector3(1.31, 0.30, -0.68), Vector3(0.052, 0.65, 1.23), Color("6a6749"), Vector3.ZERO, false)
	kit.emit_batch(root, batch)

func pen(parent: Node3D, point: Vector2) -> void:
	var vertices := [Vector2(-2.5, 1.85), Vector2(-2.5, -2.35), Vector2(2.5, -2.35), Vector2(2.5, 1.85), Vector2(0.90, 1.85)]
	var body := StaticBody3D.new()
	body.name = "Cercado"
	parent.add_child(body)
	var batch: Dictionary = {}
	for i in range(vertices.size() - 1):
		var a: Vector2 = point + vertices[i]
		var b: Vector2 = point + vertices[i + 1]
		var steps := int(ceil(a.distance_to(b) / 1.52))
		var direction := b - a
		var yaw := -atan2(direction.y, direction.x)
		for j in range(steps + 1):
			var near := a.lerp(b, float(j) / float(steps))
			var p := Land.at(near)
			Kit.stamp(batch, "box", p + Vector3.UP * 0.53, Vector3(0.16, 1.16, 0.16), WOOD.darkened(0.1), Vector3(0, yaw + 0.09 * j, 0))
			if j == steps:
				continue
			var target := a.lerp(b, float(j + 1) / float(steps))
			var mid := Land.at(near.lerp(target, 0.5))
			var length := near.distance_to(target)
			for lift: float in [0.43, 0.81]:
				Kit.stamp(batch, "box", mid + Vector3.UP * lift, Vector3(length + 0.045, 0.13, 0.124), END.darkened(0.10 * float(j % 3)), Vector3(0, yaw, 0))
		var shape_body := Kit.solid(body, Land.at(a.lerp(b, 0.5), 0.49), Vector3(a.distance_to(b), 0.98, 0.14), Vector3(0, yaw, 0))
		shape_body.name = "Lado%d" % i
	kit.emit_batch(parent, batch)

func bridge(parent: Node3D, z: float) -> void:
	var center := Land.creek_x(z)
	var ends := Vector2(center - 4.1, center + 4.1)
	var y := 0.17
	var batch: Dictionary = {}
	for i in range(31):
		var x := lerpf(ends.x, ends.y, (float(i) + 0.5) / 31.0)
		Kit.stamp(batch, "box", Vector3(x, y, z), Vector3(0.25, 0.105, 1.84), WOOD.lerp(END, 0.48 + 0.36 * sin(i * 2.4)), Vector3(0, sin(i * 1.4) * 0.021, 0))
	for side: float in [-1.0, 1.0]:
		Kit.stamp(batch, "box", Vector3(center, 0.035, z + side * 0.69), Vector3(8.40, 0.22, 0.18), WOOD.darkened(0.18))
		for dx: float in [-3.95, -1.43, 1.33, 3.95]:
			Kit.stamp(batch, "box", Vector3(center + dx, 0.24, z + side * 0.93), Vector3(0.15, 1.35, 0.15), WOOD.darkened(0.08))
		Kit.stamp(batch, "box", Vector3(center, 0.84, z + side * 0.93), Vector3(8.1, 0.105, 0.11), END.darkened(0.05))
		Kit.solid(parent, Vector3(center, 0.49, z + side * 0.93), Vector3(8.1, 0.77, 0.15))
		Kit.solid(parent, Vector3(center + side * 4.26, 0.154, z), Vector3(0.48, 0.09, 1.76), Vector3(0, 0, -side * 0.22))
	Kit.solid(parent, Vector3(center, y, z), Vector3(8.23, 0.107, 1.82))
	kit.emit_batch(parent, batch)

func trail_sign(parent: Node3D, p: Vector2, content: String, yaw: float = 0.0) -> void:
	var root := Node3D.new()
	root.position = Land.at(p)
	root.rotation.y = yaw
	parent.add_child(root)
	kit.part(root, "box", Vector3(0, 0.73, 0), Vector3(0.13, 1.54, 0.13), WOOD.darkened(0.19))
	kit.part(root, "box", Vector3(0.05, 1.31, 0.08), Vector3(1.22, 0.29, 0.10), WOOD.darkened(0.18), Vector3(0, 0, -0.044))
	var lettering := Label3D.new()
	lettering.text = content
	lettering.font_size = 38
	lettering.pixel_size = 0.0030
	lettering.outline_size = 0
	lettering.position = Vector3(0.05, 1.31, 0.137)
	lettering.modulate = Color("efe4c5")
	root.add_child(lettering)

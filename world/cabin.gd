extends Node3D
## One-room modular kit with a view-only cutaway. All collider walls stay intact.

const Kit = preload("res://world/mesh_kit.gd")
const Land = preload("res://world/landscape.gd")
const WIDTH := 9.4
const DEPTH := 7.52
const HEIGHT := 2.84
const DOOR := 1.05
const GAP := 1.38
const TRIM := Color("5a4937")
const PLANKS := [Color("ad956e"), Color("b9a17b"), Color("a38c66"), Color("c0aa84"), Color("a89676")]

var kit: Kit
var roof: Node3D
var front: Node3D
var back: Node3D
var east: Node3D
var west: Node3D
var _cutaway: bool = false

func build(meshes: Kit, point: Vector2) -> void:
	kit = meshes
	position = Land.at(point)
	var walls := StaticBody3D.new()
	walls.name = "Paredes"
	add_child(walls)
	var h := HEIGHT * 0.5 + 0.11
	var w := WIDTH * 0.5
	var d := DEPTH * 0.5
	var left := w + DOOR - GAP * 0.5
	var right := w - DOOR - GAP * 0.5
	Kit.add_box_shape(walls, Vector3(-w + left * 0.5, h, d), Vector3(left, HEIGHT, 0.18))
	Kit.add_box_shape(walls, Vector3(w - right * 0.5, h, d), Vector3(right, HEIGHT, 0.18))
	Kit.add_box_shape(walls, Vector3(0, h, -d), Vector3(WIDTH, HEIGHT, 0.19))
	Kit.add_box_shape(walls, Vector3(w, h, 0), Vector3(0.18, HEIGHT, DEPTH))
	Kit.add_box_shape(walls, Vector3(-w, h, 0), Vector3(0.18, HEIGHT, DEPTH))
	Kit.add_box_shape(walls, Vector3(0, 0.02, 0), Vector3(WIDTH + 0.1, 0.17, DEPTH + 0.16))
	Kit.solid(self, Vector3(DOOR, -0.025, d + 0.59), Vector3(1.72, 0.13, 1.34), Vector3(0.145, 0, 0))
	front = _wall("Fachada", Vector3(0, 0, d), 0.0, WIDTH, true, -2.39)
	back = _wall("Fundos", Vector3(0, 0, -d), PI, WIDTH, false, -1.6)
	east = _wall("Leste", Vector3(w, 0, 0), PI * 0.5, DEPTH, false, 0.67)
	west = _wall("Oeste", Vector3(-w, 0, 0), -PI * 0.5, DEPTH, false, 0.6)
	_make_roof()
	_furnish()

func inside(actor: Vector3) -> bool:
	var p := actor - global_position
	return absf(p.x) < WIDTH * 0.5 + 0.21 and absf(p.z) < DEPTH * 0.5 + 0.24

func update_cutaway(actor: Vector3, camera: Vector3, elevated: bool) -> void:
	_cutaway = inside(actor)
	roof.visible = not _cutaway
	var direction := camera - global_position
	var cut := _cutaway and elevated
	front.visible = not cut or direction.z < 0.0
	back.visible = not cut or direction.z >= 0.0
	east.visible = not cut or direction.x < 0.0
	west.visible = not cut or direction.x >= 0.0

func _wall(label: String, at: Vector3, yaw: float, span: float, has_door: bool, window: float) -> Node3D:
	var node := Node3D.new()
	node.name = label
	node.position = at
	node.rotation.y = yaw
	add_child(node)
	var batch: Dictionary = {}
	var half := span * 0.5
	Kit.stamp(batch, "box", Vector3(0, 0.055, 0.015), Vector3(span + 0.11, 0.34, 0.36), Color("686556"))
	for row in range(14):
		var y := 0.29 + row * 0.19
		var holes: Array[Vector2] = []
		if has_door and y < 2.18:
			holes.append(Vector2(DOOR - GAP * 0.5, DOOR + GAP * 0.5))
		if y > 1.17 and y < 2.11:
			holes.push_front(Vector2(window - 0.70, window + 0.70))
		var begin := -half
		var tint: Color = PLANKS[(row * 3 + int(absf(yaw) * 3)) % PLANKS.size()]
		for hole in holes:
			_plank(batch, begin, hole.x, y, tint)
			begin = hole.y
		_plank(batch, begin, half, y, tint)
	for x: float in [-half + 0.04, half - 0.04]:
		Kit.stamp(batch, "box", Vector3(x, 1.51, 0.13), Vector3(0.18, HEIGHT, 0.23), TRIM)
	Kit.stamp(batch, "box", Vector3(0, 2.93, 0.1), Vector3(span + 0.19, 0.18, 0.24), TRIM)
	_window(batch, window, label == "Oeste")
	if has_door:
		for side: float in [-1.0, 1.0]:
			Kit.stamp(batch, "box", Vector3(DOOR + side * GAP * 0.5, 1.15, 0.16), Vector3(0.135, 2.08, 0.24), TRIM)
		Kit.stamp(batch, "box", Vector3(DOOR, 2.24, 0.16), Vector3(GAP + 0.25, 0.19, 0.25), TRIM)
		Kit.stamp(batch, "box", Vector3(-0.05, 2.49, 0.15), Vector3(1.55, 0.31, 0.10), Color("635843"))
		_label(node, "POSTO CEDRO", Vector3(-0.05, 2.50, 0.211), 0.0041)
	kit.emit_batch(node, batch)
	return node

static func _plank(batch: Dictionary, a: float, b: float, y: float, tint: Color) -> void:
	if b <= a:
		return
	var seam := lerpf(a, b, 0.47 + 0.30 * sin(y * 11.7))
	for segment: Vector2 in [Vector2(a, seam), Vector2(seam, b)]:
		var span := segment.y - segment.x
		if span < 0.035:
			continue
		Kit.stamp(batch, "box", Vector3((segment.x + segment.y) * 0.5, y, 0), Vector3(span - 0.012, 0.187, 0.18), tint.lightened(0.045 if segment.x == seam else 0.0))

static func _window(batch: Dictionary, x: float, damaged: bool) -> void:
	Kit.stamp(batch, "box", Vector3(x, 1.62, -0.04), Vector3(1.45, 0.97, 0.11), Color("4d5b53"))
	Kit.stamp(batch, "box", Vector3(x - 0.36, 1.63, 0.025), Vector3(0.61, 0.78, 0.027), Color("81918a"))
	for y: float in [1.14, 2.11]:
		Kit.stamp(batch, "box", Vector3(x, y, 0.13), Vector3(1.64, 0.12, 0.27), TRIM)
	for shift: float in [-0.71, 0.0, 0.71]:
		Kit.stamp(batch, "box", Vector3(x + shift, 1.62, 0.13), Vector3(0.102, 0.99, 0.22), TRIM)
	Kit.stamp(batch, "box", Vector3(x, 1.62, 0.135), Vector3(1.42, 0.08, 0.22), TRIM)
	if damaged:
		Kit.stamp(batch, "box", Vector3(x, 1.76, 0.23), Vector3(1.82, 0.19, 0.10), Color("9b8061"), Vector3(0, 0, -0.19))

func _make_roof() -> void:
	roof = Node3D.new()
	roof.name = "TelhadoRecortavel"
	add_child(roof)
	var batch: Dictionary = {}
	var slope := 0.344
	var reach := DEPTH * 0.5 + 0.56
	var length := reach / cos(slope)
	var center_y := 4.42 - tan(slope) * reach * 0.5
	for sign_value: float in [-1.0, 1.0]:
		var tilt := Vector3(sign_value * slope, 0, 0)
		Kit.stamp(batch, "box", Vector3(0, center_y, sign_value * reach * 0.5), Vector3(WIDTH + 1.07, 0.14, length), Color("4b514d"), tilt)
		for stripe in range(21):
			var x := -5.06 + float(stripe) * 0.504
			var a := Color("5b6158").lerp(Color("7c7563"), 0.27 + 0.24 * sin(float(stripe) * 1.46 + sign_value))
			Kit.stamp(batch, "box", Vector3(x, center_y + 0.088, sign_value * reach * 0.5), Vector3(0.496, 0.026, length - 0.024), a, tilt, false)
			Kit.stamp(batch, "box", Vector3(x - 0.246, center_y + 0.106, sign_value * reach * 0.5), Vector3(0.028, 0.055, length), a.darkened(0.21), tilt, false)
		Kit.stamp(batch, "box", Vector3(0, 2.89, sign_value * reach), Vector3(10.55, 0.18, 0.115), Color("3c413b"))
	Kit.stamp(batch, "box", Vector3(0, 4.48, 0), Vector3(10.5, 0.115, 0.27), Color("696455"))
	# Closed gable ends made of successively shorter boards.
	for sign_value: float in [-1.0, 1.0]:
		for i in range(8):
			var y := 3.015 + 0.173 * i
			var span := (4.42 - y - 0.035) / tan(slope)
			Kit.stamp(batch, "box", Vector3(sign_value * WIDTH * 0.5, y, 0), Vector3(0.16, 0.17, 2.0 * span), PLANKS[(i + 1) % PLANKS.size()])
	Kit.stamp(batch, "box", Vector3(-3.31, 4.18, -1.83), Vector3(0.78, 1.77, 0.74), Color("7e7160"))
	for i in range(6):
		Kit.stamp(batch, "box", Vector3(-3.31, 3.87 + 0.214 * i, -1.83), Vector3(0.794, 0.035, 0.76), Color("5f5749"), Vector3.ZERO, false)
	Kit.stamp(batch, "box", Vector3(-3.31, 5.12, -1.83), Vector3(0.95, 0.13, 0.87), Color("555549"))
	kit.emit_batch(roof, batch)

func _furnish() -> void:
	var batch: Dictionary = {}
	for n in range(25):
		var x := -WIDTH * 0.5 + (float(n) + 0.5) * WIDTH / 25.0
		Kit.stamp(batch, "box", Vector3(x, 0.093, 0), Vector3(WIDTH / 25.0 - 0.013, 0.038, DEPTH), PLANKS[n % PLANKS.size()].darkened(0.30), Vector3.ZERO, false)
	Kit.stamp(batch, "box", Vector3(0.48, 0.125, -0.65), Vector3(2.76, 0.025, 2.32), Color("6c6050"), Vector3.ZERO, false)
	Kit.stamp(batch, "box", Vector3(0.48, 0.14, -0.65), Vector3(2.56, 0.018, 2.12), Color("817955"), Vector3.ZERO, false)
	for j in range(5):
		Kit.stamp(batch, "box", Vector3(0.48, 0.151, -1.54 + float(j) * 0.43), Vector3(2.48, 0.008, 0.095), Color("948664"), Vector3.ZERO, false)
	Kit.stamp(batch, "box", Vector3(3.36, 0.90, -1.65), Vector3(0.90, 0.135, 2.36), Color("8d7350"))
	for x: float in [3.04, 3.68]:
		for z: float in [-2.56, -0.72]:
			Kit.stamp(batch, "box", Vector3(x, 0.52, z), Vector3(0.14, 0.83, 0.14), TRIM)
	Kit.add_box_shape(_backing_body(), Vector3(3.36, 0.52, -1.65), Vector3(0.88, 0.89, 2.31))
	Kit.stamp(batch, "round", Vector3(3.4, 1.13, -2.21), Vector3(0.26, 0.27, 0.26), Color("84908a"))
	Kit.stamp(batch, "box", Vector3(-3.56, 0.48, -2.6), Vector3(0.85, 0.76, 1.23), Color("69625a"))
	Kit.stamp(batch, "box", Vector3(-3.56, 0.91, -2.6), Vector3(0.92, 0.13, 1.29), Color("494e48"))
	Kit.stamp(batch, "round", Vector3(-3.76, 1.9, -2.88), Vector3(0.28, 1.9, 0.28), Color("51544a"))
	for j in range(9):
		Kit.stamp(batch, "box", Vector3(DOOR, 0.075 - 0.018 * j, DEPTH * 0.5 + 0.11 + float(j) * 0.123), Vector3(1.72, 0.10, 0.125), PLANKS[j % PLANKS.size()].darkened(0.18))
	kit.emit_batch(self, batch)

func _backing_body() -> StaticBody3D:
	var body := StaticBody3D.new()
	add_child(body)
	return body

static func _label(parent: Node3D, contents: String, at: Vector3, scale_per_pixel: float) -> void:
	var sign_text := Label3D.new()
	sign_text.text = contents
	sign_text.font_size = 36
	sign_text.pixel_size = scale_per_pixel
	sign_text.modulate = Color("d7cdb0")
	sign_text.outline_size = 0
	sign_text.position = at
	parent.add_child(sign_text)

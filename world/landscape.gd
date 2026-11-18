extends RefCounted
## Continuous authored paths and a single sampled surface across sector boundaries.

const STEP := 1
const STREAM_LEVEL := -0.44
const SOIL = preload("res://world/soil.gdshader")
const WATER = preload("res://world/stream.gdshader")
const TRAILS := [
	[Vector2(-46, 51), Vector2(-30, 38), Vector2(-15, 22), Vector2(-7, 11), Vector2(-4.2, 5.5), Vector2(-1.3, 0.1), Vector2(0.4, -12), Vector2(-3.0, -30)],
	[Vector2(-7, 11), Vector2(0, 8.0), Vector2(6.4, 7.5), Vector2(13.5, 10.3), Vector2(22.5, 10.3), Vector2(33.5, 13), Vector2(52, 5), Vector2(68, -12)],
	[Vector2(-2, 3.5), Vector2(3.75, 2.8), Vector2(7.0, -1.2), Vector2(8.5, -6.0), Vector2(8.7, -12.5)]
]

var soil := ShaderMaterial.new()
var water := ShaderMaterial.new()

func _init() -> void:
	soil.shader = SOIL
	water.shader = WATER
	soil.set_shader_parameter("soil_grain", _grain_texture())

static func _grain_texture() -> ImageTexture:
	const RESOLUTION := 64
	var bits := PackedByteArray()
	bits.resize(RESOLUTION * RESOLUTION)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1826
	for y in range(RESOLUTION):
		for x in range(RESOLUTION):
			var u := TAU * float(x) / RESOLUTION
			var v := TAU * float(y) / RESOLUTION
			var variation := 31 * sin(u * 3.0 + cos(v * 2.0)) + 19 * cos(v * 5.0 - u * 2.0)
			bits[y * RESOLUTION + x] = int(clampf(126 + variation + rng.randf_range(-56, 56), 0, 255))
	var image := Image.create_from_data(RESOLUTION, RESOLUTION, false, Image.FORMAT_L8, bits)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)

static func creek_x(z: float) -> float:
	return 17.7 + 2.65 * sin((z - 9.0) * 0.086) + 1.7 * sin((z - 9.0) * 0.159)

static func height(x: float, z: float) -> float:
	var radius := Vector2(x * 0.92, z * 0.79).length()
	var distant := smoothstep(12.0, 57.0, radius)
	var slope := (2.7 * sin(x * 0.047 + z * 0.037) + 2.5 * cos(z * 0.093 - x * 0.024)
		+ 1.2 * sin(x * 0.125 + z * 0.045)) * distant
	var rise := 0.09 * sin(x * 0.25 + 0.33) * cos(z * 0.29) + 0.15
	var creek := absf(x - creek_x(z))
	return (rise + slope * smoothstep(4.0, 17.5, creek)) * smoothstep(1.9, 4.9, creek) - 1.3 * (1.0 - smoothstep(1.3, 3.85, creek))

static func at(point: Vector2, lift: float = 0.0) -> Vector3:
	return Vector3(point.x, height(point.x, point.y) + lift, point.y)

static func woodland(x: float, z: float) -> float:
	return smoothstep(12.0, 24.0, Vector2(x + 0.6, z * 0.83 + 2.1).length())

static func trail_distance(point: Vector2) -> float:
	var minimum := 1000.0
	for trail: Array in TRAILS:
		for i in range(trail.size() - 1):
			var a: Vector2 = trail[i]
			var ab: Vector2 = trail[i + 1] - a
			var t := clampf((point - a).dot(ab) / ab.length_squared(), 0, 1)
			minimum = minf(minimum, (point - (a + ab * t)).length_squared())
	return sqrt(minimum)

static func ground_color(position: Vector2) -> Color:
	var x := position.x
	var z := position.y
	var field := 0.5 + 0.25 * sin(x * 0.18 + z * 0.29) + 0.25 * cos(z * 0.69 - x * 0.39)
	var patches := smoothstep(-0.25, 0.85, 0.5 * sin(x * 0.91 + z * 0.51) + 0.5 * cos(z * 1.1 - x * 0.23))
	var shade := woodland(x, z)
	var earth := Color("5e6b44").lerp(Color("7e8b5b"), field).lerp(Color("3c503b"), shade * 0.77)
	earth = earth.lerp(Color("635e43"), patches * (0.40 + shade * 0.27))
	var trail := 1.0 - smoothstep(0.46, 1.55, trail_distance(position) + 0.21 * sin(z * 2.32 + x * 0.61))
	earth = earth.lerp(Color("8d7556").lerp(Color("ab926d"), field), trail * 0.89)
	var bank := 1.0 - smoothstep(2.6, 4.5, absf(x - creek_x(z)) + 0.30 * sin(z * 1.4))
	return earth.lerp(Color("76725c").lerp(Color("91917a"), patches), bank)

func ground(parent: Node3D, origin: Vector2, width: int, step: int = STEP, collision: bool = true) -> void:
	var side := width / step + 1
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for z in range(side):
		for x in range(side):
			var p := origin + Vector2(x * step, z * step)
			vertices.append(at(p, 0.0 if collision else -0.27))
			colors.append(ground_color(p))
			normals.append(Vector3(height(p.x - 0.5, p.y) - height(p.x + 0.5, p.y), 1.0, height(p.x, p.y - 0.5) - height(p.x, p.y + 0.5)).normalized())
			if x < side - 1 and z < side - 1:
				var i := z * side + x
				indices.append_array([i, i + 1, i + side, i + 1, i + side + 1, i + side])
	var mesh := _mesh(vertices, normals, colors, PackedVector2Array(), indices)
	_show_mesh(parent, mesh, soil)
	if collision:
		var shape := mesh.create_trimesh_shape()
		var body := StaticBody3D.new()
		body.name = "Solo"
		var collider := CollisionShape3D.new()
		collider.shape = shape
		body.add_child(collider)
		parent.add_child(body)

func stream_mesh(parent: Node3D, origin: Vector2, width: int) -> void:
	if origin.x > 23.4 or origin.x + width < 11.0:
		return
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uv := PackedVector2Array()
	var indices := PackedInt32Array()
	for i in range(width + 1):
		var z := origin.y + float(i)
		var x := creek_x(z)
		var margin := 3.33 + 0.15 * sin(z * 0.73)
		for k in range(5):
			var u := float(k) / 4.0
			vertices.append(Vector3(clampf(lerpf(x - margin, x + margin, u), origin.x, origin.x + width), STREAM_LEVEL, z))
			normals.append(Vector3.UP)
			uv.append(Vector2(u, z))
			if i < width and k < 4:
				var index := i * 5 + k
				indices.append_array([index, index + 1, index + 5, index + 1, index + 6, index + 5])
	_show_mesh(parent, _mesh(vertices, normals, PackedColorArray(), uv, indices), water)

static func _mesh(v: PackedVector3Array, n: PackedVector3Array, c: PackedColorArray, uv: PackedVector2Array, indices: PackedInt32Array) -> ArrayMesh:
	var data: Array = []
	data.resize(Mesh.ARRAY_MAX)
	data[Mesh.ARRAY_VERTEX] = v
	data[Mesh.ARRAY_NORMAL] = n
	if not c.is_empty(): data[Mesh.ARRAY_COLOR] = c
	if not uv.is_empty(): data[Mesh.ARRAY_TEX_UV] = uv
	data[Mesh.ARRAY_INDEX] = indices
	var result := ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, data)
	return result

static func _show_mesh(parent: Node3D, mesh: Mesh, material: Material) -> void:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)

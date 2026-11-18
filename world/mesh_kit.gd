extends RefCounted
## Unit meshes and per-sector batches. Shapes use Godot clockwise winding.

var meshes: Dictionary = {}
var matte := StandardMaterial3D.new()
var blade_material := StandardMaterial3D.new()
var materials: Dictionary = {}

func _init() -> void:
	meshes["box"] = BoxMesh.new()
	var round := CylinderMesh.new()
	round.radial_segments = 8
	round.rings = 1
	round.height = 1.0
	meshes["round"] = round
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.31
	trunk.radial_segments = 7
	trunk.rings = 1
	trunk.height = 1.0
	meshes["trunk"] = trunk
	var conifer := CylinderMesh.new()
	conifer.top_radius = 0.11
	conifer.bottom_radius = 0.53
	conifer.height = 1.0
	conifer.radial_segments = 8
	conifer.rings = 2
	meshes["cone"] = conifer
	var ball := SphereMesh.new()
	ball.radial_segments = 10
	ball.rings = 6
	ball.height = 1.0
	meshes["ball"] = ball
	meshes["stone"] = _faceted(ball)
	meshes["grass"] = _blades()
	matte.vertex_color_use_as_albedo = true
	matte.vertex_color_is_srgb = true
	matte.roughness = 0.94
	matte.metallic_specular = 0.13
	blade_material.vertex_color_use_as_albedo = true
	blade_material.vertex_color_is_srgb = true
	blade_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	blade_material.roughness = 0.96

func part(parent: Node3D, shape: String, at: Vector3, size: Vector3, tint: Color, angles := Vector3.ZERO, shadow: bool = true) -> MeshInstance3D:
	var view := MeshInstance3D.new()
	view.mesh = meshes[shape]
	if not materials.has(tint):
		var surface := StandardMaterial3D.new()
		surface.albedo_color = tint
		surface.roughness = 0.9
		surface.metallic_specular = 0.26
		materials[tint] = surface
	view.material_override = materials[tint]
	view.position = at
	view.scale = size
	view.rotation = angles
	if not shadow:
		view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(view)
	return view

static func stamp(batch: Dictionary, shape: String, at: Vector3, size: Vector3, tint: Color, angles := Vector3.ZERO, shadow: bool = true) -> void:
	var key := shape + ("+" if shadow else "-")
	if not batch.has(key):
		batch[key] = []
	var basis := Basis.from_euler(angles) * Basis.from_scale(size)
	batch[key].append([Transform3D(basis, at), tint])

func emit_batch(parent: Node3D, source: Dictionary) -> void:
	for key: String in source:
		var kind := key.left(-1)
		var instances: Array = source[key]
		var batch := MultiMesh.new()
		batch.transform_format = MultiMesh.TRANSFORM_3D
		batch.use_colors = true
		batch.mesh = meshes[kind]
		batch.instance_count = instances.size()
		for i in range(instances.size()):
			batch.set_instance_transform(i, instances[i][0])
			batch.set_instance_color(i, instances[i][1])
		var view := MultiMeshInstance3D.new()
		view.multimesh = batch
		view.material_override = blade_material if kind == "grass" else matte
		if key.ends_with("-"):
			view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(view)

static func solid(parent: Node3D, at: Vector3, size: Vector3, angles := Vector3.ZERO) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = at
	body.rotation = angles
	add_box_shape(body, Vector3.ZERO, size)
	parent.add_child(body)
	return body

static func add_box_shape(body: StaticBody3D, at: Vector3, size: Vector3) -> void:
	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position = at
	body.add_child(collider)

static func _faceted(source: SphereMesh) -> ArrayMesh:
	var arrays := source.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var faces: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_smooth_group(-1)
	for i in faces:
		var v := vertices[i]
		var noise := sin(v.x * 24.0 + v.y * 17.1 + v.z * 7.8)
		tool.add_vertex(v * (1.0 + noise * 0.15))
	tool.generate_normals()
	return tool.commit()

static func _blades() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in range(5):
		var angle := float(k) * 2.399
		var axis := Vector3(cos(angle), 0, sin(angle))
		var right := axis.cross(Vector3.UP)
		var root := axis * (0.035 + 0.017 * k)
		var crown := axis * (0.15 + 0.016 * k) + Vector3.UP * (0.42 - 0.038 * k)
		tool.set_color(Color(0.60, 0.64, 0.48))
		tool.add_vertex(root - right * 0.043)
		tool.add_vertex(root + right * 0.043)
		tool.set_color(Color(0.97, 0.97, 0.79))
		tool.add_vertex(crown)
	tool.generate_normals()
	return tool.commit()

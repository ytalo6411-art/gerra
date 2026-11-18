extends Node3D
## 32 m tiles; queue the shell, build the current cell immediately. Data is owned by State.

const Kit = preload("res://world/mesh_kit.gd")
const Land = preload("res://world/landscape.gd")
const Scenery = preload("res://world/scenery.gd")
const Landmarks = preload("res://world/landmarks.gd")
const View = preload("res://world/object_view.gd")
const Cabin = preload("res://world/cabin.gd")
const Catalog = preload("res://systems/catalog.gd")
const State = preload("res://systems/world_state.gd")

var kit := Kit.new()
var landscape := Land.new()
var catalog: Catalog
var state: State
var landmarks: Landmarks
var scenery: Scenery
var active: Dictionary = {}
var targets: Dictionary = {}
var cabin: Cabin
var current := Vector2i(999, 999)
var pending: Array[Vector2i] = []
var tile := 32
var max_tile := 4

func build(model: State) -> void:
	state = model
	catalog = state.catalog
	tile = int(catalog.world["sector"])
	max_tile = int(float(catalog.world["size"]) / (2 * tile))
	scenery = Scenery.new(kit, catalog)
	landmarks = Landmarks.new(kit)
	var span := int(catalog.world["size"])
	landscape.ground(self, Vector2(-span * 0.5, -span * 0.5), span, 8, false)

func cell_at(p: Vector3) -> Vector2i:
	return Vector2i(floori(p.x / tile), floori(p.z / tile))

func around(p: Vector3, immediate: bool = false) -> void:
	var cell := cell_at(p)
	if cell != current:
		current = cell
		for old: Vector2i in active.keys():
			if absi(old.x - current.x) > 1 or absi(old.y - current.y) > 1:
				_drop(old)
		pending.clear()
		if not active.has(cell) and _valid(cell):
			_spawn(cell)
		for offset: Vector2i in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
			var key := cell + offset
			if not active.has(key) and _valid(key):
				pending.append(key)
	if immediate:
		while not pending.is_empty():
			_spawn(pending.pop_front())
	elif not pending.is_empty():
		_spawn(pending.pop_front())

func sync_all() -> void:
	for key: String in targets:
		targets[key].sync(state.changes.get(key, false))

func closest(actor: CharacterBody3D) -> View:
	var from := actor.global_position + Vector3.UP * 0.94
	var nearest: View = null
	var best := 3.10 * 3.10
	var space := get_world_3d().direct_space_state
	for id: String in targets:
		if not state.can_interact(id):
			continue
		var subject: View = targets[id]
		var destination := subject.global_position + subject.anchor
		var score := from.distance_squared_to(destination)
		if score > best:
			continue
		var ray := PhysicsRayQueryParameters3D.create(from, destination, 1, [actor.get_rid()])
		if subject.blocker != null:
			ray.exclude = [actor.get_rid(), subject.blocker.get_rid()]
		if not space.intersect_ray(ray).is_empty():
			continue
		best = score
		nearest = subject
	return nearest

func _valid(cell: Vector2i) -> bool:
	return cell.x >= -max_tile and cell.x < max_tile and cell.y >= -max_tile and cell.y < max_tile

func _drop(cell: Vector2i) -> void:
	var root: Node3D = active[cell]
	for child: Node in root.get_children():
		if child is View:
			targets.erase(child.id)
		elif child == cabin:
			cabin = null
	remove_child(root)
	root.queue_free()
	active.erase(cell)

func _spawn(key: Vector2i) -> void:
	var root := Node3D.new()
	root.name = "Setor_%d_%d" % [key.x, key.y]
	add_child(root)
	active[key] = root
	var origin := Vector2(key) * float(tile)
	landscape.ground(root, origin, tile)
	landscape.stream_mesh(root, origin, tile)
	scenery.populate(root, origin, tile, key)
	var structs: Dictionary = catalog.world["structures"]
	var cabin_at := Catalog.point(structs["cabin"])
	var shed_at := Catalog.point(structs["shed"])
	var pen_at := Catalog.point(structs["pen"])
	var z := float(structs["bridge_z"])
	if key == cell_at(Land.at(cabin_at)):
		cabin = Cabin.new()
		cabin.name = "CabanaDoGuarda"
		root.add_child(cabin)
		cabin.build(kit, cabin_at)
	if key == cell_at(Land.at(shed_at)):
		landmarks.shed(root, shed_at)
	if key == cell_at(Land.at(pen_at)):
		landmarks.pen(root, pen_at)
	if key == cell_at(Vector3(Land.creek_x(z), 0, z)):
		landmarks.bridge(root, z)
	if key == Vector2i(-1, 0):
		landmarks.trail_sign(root, Vector2(-5.9, 7.2), "POSTO CEDRO", 0.28)
		landmarks.trail_sign(root, Vector2(-8.55, 15.5), "TRILHA 01", 0.18)
	for id: String in catalog.objects:
		var rule: Dictionary = catalog.objects[id]
		if key != cell_at(Land.at(Catalog.point(rule["pos"]))):
			continue
		var view := View.new()
		root.add_child(view)
		view.build(rule, kit)
		view.sync(state.changes.get(id, false))
		targets[id] = view

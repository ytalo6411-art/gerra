extends Node3D
## Representation of one manifest ID. Streaming can discard it at any time.

const Land = preload("res://world/landscape.gd")
const Kit = preload("res://world/mesh_kit.gd")
const WOOD := Color("886b47")
const SLATE := Color("54584e")

var id := ""
var rule: Dictionary
var kit: Kit
var anchor := Vector3.ZERO
var blocker: StaticBody3D
var hinge: Node3D
var lid: Node3D
var flame: Node3D
var lamp: OmniLight3D
var age := 0.0

func build(definition: Dictionary, meshes: Kit) -> void:
	kit = meshes
	rule = definition
	id = rule["id"]
	name = id
	var p := Vector2(rule["pos"][0], rule["pos"][1])
	position = Land.at(p)
	match rule["kind"]:
		"water": _pump()
		"fire": _fire()
		"door": _door()
		"loot": _box()
		"rest": _cot()
		"pickup":
			if rule["item"] == "branch": _branch()
			else: _berries()
	set_process(false)

func sync(changed: bool) -> void:
	match rule["kind"]:
		"pickup": visible = not changed
		"loot": lid.rotation.x = -1.13 if changed else 0.0
		"door": hinge.rotation.y = -1.66 if changed else 0.0
		"fire":
			flame.visible = changed
			lamp.visible = changed
			set_process(changed)

func _process(delta: float) -> void:
	age += delta
	flame.scale = Vector3(1.0 + 0.065 * sin(age * 8), 1.0 + 0.20 * sin(age * 11.0) + 0.09 * sin(age * 23.0), 1.0)
	flame.rotation.y = 0.18 * sin(age * 6.1)
	lamp.light_energy = 0.53 + 0.13 * sin(age * 12.1)

func _pump() -> void:
	var green := Color("586e62")
	kit.part(self, "round", Vector3(0, 0.045, 0), Vector3(0.90, 0.13, 0.90), Color("828174"))
	kit.part(self, "round", Vector3(0, 0.27, 0), Vector3(0.31, 0.51, 0.31), green.darkened(0.20))
	kit.part(self, "round", Vector3(0, 0.66, 0), Vector3(0.42, 0.53, 0.39), green)
	kit.part(self, "ball", Vector3(0, 0.94, 0), Vector3(0.48, 0.23, 0.42), green.lightened(0.06))
	kit.part(self, "round", Vector3(0, 0.72, 0.24), Vector3(0.14, 0.35, 0.14), green, Vector3(PI * 0.5, 0, 0))
	kit.part(self, "round", Vector3(0, 0.645, 0.40), Vector3(0.135, 0.16, 0.135), green)
	kit.part(self, "box", Vector3(0, 0.94, -0.39), Vector3(0.105, 0.105, 0.77), SLATE, Vector3(-0.32, 0, 0))
	kit.part(self, "box", Vector3(0, 0.80, -0.74), Vector3(0.16, 0.105, 0.23), WOOD)
	blocker = Kit.solid(self, Vector3(0, 0.49, 0), Vector3(0.43, 0.98, 0.43))
	anchor = Vector3(0, 0.68, 0.12)

func _fire() -> void:
	var batch: Dictionary = {}
	Kit.stamp(batch, "round", Vector3(0, 0.028, 0), Vector3(1.24, 0.049, 1.20), Color("484338"), Vector3.ZERO, false)
	for i in range(10):
		var yaw := float(i) * TAU / 10.0
		var p := Vector3(cos(yaw) * 0.59, 0.1 + 0.047 * sin(i * 2.0), sin(yaw) * 0.58)
		Kit.stamp(batch, "stone", p, Vector3(0.36, 0.25, 0.31), Color("858075").darkened(0.19 + 0.12 * sin(i * 1.3)), Vector3(0, yaw, 0))
	for i in range(3):
		Kit.stamp(batch, "trunk", Vector3(0, 0.135 + 0.05 * i, 0), Vector3(0.18, 0.96, 0.18), Color("493b30"), Vector3(PI * 0.46, i * 1.92, 0))
	kit.emit_batch(self, batch)
	flame = Node3D.new()
	add_child(flame)
	for i in range(5):
		var s := 0.56 + 0.16 * sin(i * 7.9)
		var hue := Color("e38640").lerp(Color("ffd892"), float(i) / 4.0)
		var mesh := kit.part(flame, "cone", Vector3(sin(float(i) * 2.6) * 0.22, s * 0.5 + 0.13, cos(i * 2.6) * 0.19), Vector3(s * 0.61, s, s * 0.66), hue, Vector3(0.10 * i, 0, sin(i * 6.4) * 0.35), false)
		var lit := StandardMaterial3D.new()
		lit.albedo_color = hue
		lit.emission_enabled = true
		lit.emission = hue
		lit.emission_energy_multiplier = 0.67
		mesh.material_override = lit
	lamp = OmniLight3D.new()
	lamp.light_color = Color("ffae66")
	lamp.omni_range = 3.18
	lamp.position = Vector3(0, 0.60, 0)
	add_child(lamp)
	anchor = Vector3(0, 0.32, 0)

func _door() -> void:
	hinge = Node3D.new()
	hinge.position = Vector3(-0.62, 0.10, -0.15)
	add_child(hinge)
	var batch: Dictionary = {}
	for i in range(7):
		Kit.stamp(batch, "box", Vector3(0.09 + i * 0.18, 1.01, 0), Vector3(0.176, 1.99, 0.115), WOOD.lightened(0.035 * float(i % 3)))
	for y: float in [0.30, 1.61]:
		Kit.stamp(batch, "box", Vector3(0.63, y, 0.076), Vector3(1.23, 0.14, 0.073), WOOD.darkened(0.23))
	Kit.stamp(batch, "round", Vector3(1.05, 0.93, 0.079), Vector3(0.112, 0.093, 0.11), Color("9d9276"), Vector3(PI / 2, 0, 0))
	kit.emit_batch(hinge, batch)
	blocker = Kit.solid(hinge, Vector3(0.63, 1.0, 0), Vector3(1.25, 2.0, 0.13))
	anchor = Vector3(0.02, 1.18, 0)

func _box() -> void:
	var batch: Dictionary = {}
	Kit.stamp(batch, "box", Vector3(0, 0.35, 0), Vector3(0.96, 0.56, 0.65), Color("746144"))
	Kit.stamp(batch, "box", Vector3(0, 0.60, 0), Vector3(0.83, 0.038, 0.54), Color("393931"))
	for i in range(3):
		Kit.stamp(batch, "box", Vector3(0, 0.215 + i * 0.15, 0.334), Vector3(0.96, 0.136, 0.052), WOOD.lightened(float(i) * 0.033))
	for x: float in [-0.38, 0.38]:
		Kit.stamp(batch, "box", Vector3(x, 0.37, 0.367), Vector3(0.11, 0.53, 0.055), Color("564f3c"))
	kit.emit_batch(self, batch)
	lid = Node3D.new()
	lid.position = Vector3(0, 0.641, -0.32)
	add_child(lid)
	kit.part(lid, "box", Vector3(0, 0.002, 0.32), Vector3(1.02, 0.09, 0.68), Color("ab9166"))
	kit.part(lid, "box", Vector3(0.0, -0.03, 0.675), Vector3(0.14, 0.15, 0.040), SLATE)
	blocker = Kit.solid(self, Vector3(0, 0.35, 0), Vector3(0.96, 0.57, 0.65))
	anchor = Vector3(0, 0.52, 0.30)

func _cot() -> void:
	var batch: Dictionary = {}
	Kit.stamp(batch, "box", Vector3(0, 0.435, 0), Vector3(1.22, 0.14, 2.07), WOOD.darkened(0.26))
	for a: float in [-0.51, 0.51]:
		for b: float in [-0.86, 0.86]:
			Kit.stamp(batch, "box", Vector3(a, 0.29, b), Vector3(0.12, 0.37, 0.14), WOOD.darkened(0.23))
	Kit.stamp(batch, "box", Vector3(0, 0.51, 0), Vector3(1.13, 0.14, 1.98), Color("aea993"))
	Kit.stamp(batch, "box", Vector3(0, 0.598, 0.284), Vector3(1.16, 0.043, 1.40), Color("6e785c"))
	Kit.stamp(batch, "box", Vector3(0, 0.605, -0.29), Vector3(1.16, 0.048, 0.09), Color("b8a478"))
	Kit.stamp(batch, "ball", Vector3(0, 0.625, -0.64), Vector3(0.76, 0.162, 0.45), Color("c8baa0"))
	kit.emit_batch(self, batch)
	blocker = Kit.solid(self, Vector3(0, 0.33, 0), Vector3(1.21, 0.64, 2.01))
	anchor = Vector3(0, 0.66, 0.61)

func _branch() -> void:
	var batch: Dictionary = {}
	for i in range(4):
		var length := 0.57 + 0.12 * i
		var at := Vector3(0.15 * sin(i * 7.0), 0.076 + 0.021 * float(i), 0.094 * (i - 1))
		Kit.stamp(batch, "trunk", at, Vector3(0.13, length, 0.122), WOOD.lightened(0.21 + i * 0.024), Vector3(1.5 + i * 0.026, -0.58 + i * 0.39, 0), false)
	kit.emit_batch(self, batch)
	anchor = Vector3(0, 0.27, 0)

func _berries() -> void:
	var batch: Dictionary = {}
	for i in range(8):
		var angle := i * 2.399
		var at := Vector3(cos(angle) * 0.34, 0.22 + 0.040 * i, sin(angle) * 0.36)
		Kit.stamp(batch, "stone", at, Vector3(0.70, 0.48, 0.66), Color("626c46").lightened(0.019 * i), Vector3(0, angle, 0), false)
		for j in range(3):
			Kit.stamp(batch, "ball", at + Vector3(cos(angle + j) * 0.24, 0.19, sin(angle + j) * 0.24), Vector3.ONE * 0.098, Color("7f3c46").lightened(0.076 * j), Vector3.ZERO, false)
	kit.emit_batch(self, batch)
	anchor = Vector3(0, 0.56, 0)

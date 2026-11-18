extends CharacterBody3D

const Kit = preload("res://world/mesh_kit.gd")
const Land = preload("res://world/landscape.gd")
const WALK := 3.70
const RUN := 5.65

var figure: Node3D
var legs: Array[Node3D] = []
var arms: Array[Node3D] = []
var pace := 0.0

func build(meshes: Kit) -> void:
	name = "Sobrevivente"
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.34
	floor_max_angle = deg_to_rad(48.0)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.29
	capsule.height = 1.67
	collision.shape = capsule
	collision.position.y = 0.84
	add_child(collision)
	figure = Node3D.new()
	add_child(figure)
	var ochre := Color("b9985d")
	var dark := Color("47483b")
	var shoe := Color("4a3f30")
	var olive := Color("676650")
	var skin := Color("b4906e")
	meshes.part(figure, "ball", Vector3(0, 1.22, 0.005), Vector3(0.58, 0.67, 0.34), ochre)
	meshes.part(figure, "ball", Vector3(0, 1.43, -0.023), Vector3(0.47, 0.27, 0.34), ochre.lightened(0.09))
	meshes.part(figure, "ball", Vector3(0, 0.92, 0), Vector3(0.49, 0.28, 0.33), olive)
	meshes.part(figure, "ball", Vector3(0, 1.61, 0.005), Vector3(0.29, 0.34, 0.31), skin)
	meshes.part(figure, "ball", Vector3(0, 1.72, 0.025), Vector3(0.34, 0.17, 0.35), dark)
	meshes.part(figure, "box", Vector3(0, 1.681, -0.152), Vector3(0.30, 0.035, 0.16), dark)
	meshes.part(figure, "ball", Vector3(0, 1.29, 0.225), Vector3(0.48, 0.58, 0.32), Color("555b4c"))
	meshes.part(figure, "box", Vector3(0, 1.20, 0.36), Vector3(0.313, 0.25, 0.082), Color("727763"))
	meshes.part(figure, "round", Vector3(0, 1.56, 0.24), Vector3(0.195, 0.46, 0.18), Color("827659"), Vector3(0, 0, PI / 2))
	for side: float in [-1.0, 1.0]:
		var leg := Node3D.new()
		leg.position = Vector3(side * 0.125, 0.88, 0)
		figure.add_child(leg)
		legs.append(leg)
		meshes.part(leg, "ball", Vector3(0, -0.213, 0.018), Vector3(0.229, 0.51, 0.24), olive)
		meshes.part(leg, "ball", Vector3(0, -0.57, 0.031), Vector3(0.178, 0.48, 0.17), dark)
		meshes.part(leg, "ball", Vector3(0, -0.779, -0.044), Vector3(0.222, 0.19, 0.34), shoe)
		var arm := Node3D.new()
		arm.position = Vector3(side * 0.262, 1.39, 0)
		figure.add_child(arm)
		arms.append(arm)
		meshes.part(arm, "ball", Vector3(side * 0.08, -0.197, 0), Vector3(0.225, 0.51, 0.225), ochre.darkened(0.09), Vector3(0, 0, side * 0.14))
		meshes.part(arm, "ball", Vector3(side * 0.11, -0.431, -0.028), Vector3(0.136, 0.177, 0.151), skin)
		meshes.part(figure, "box", Vector3(side * 0.166, 1.27, -0.15), Vector3(0.055, 0.43, 0.045), dark)

func drive(direction: Vector3, running: bool, seconds: float, limit: float) -> void:
	var speed := RUN if running else WALK
	if position.y < Land.STREAM_LEVEL + 0.14:
		speed *= 0.57
	var acceleration := 26.5 if direction.length_squared() > 0 else 35.0
	velocity.x = move_toward(velocity.x, direction.x * speed, seconds * acceleration)
	velocity.z = move_toward(velocity.z, direction.z * speed, seconds * acceleration)
	velocity.y = -0.4 if is_on_floor() else maxf(velocity.y - 19.8 * seconds, -18.0)
	move_and_slide()
	position.x = clampf(position.x, -limit, limit)
	position.z = clampf(position.z, -limit, limit)
	if position.y < -6:
		position.y = Land.height(position.x, position.z) + 0.24
		velocity.y = 0
	var motion := Vector2(velocity.x, velocity.z).length()
	if direction.length_squared() > 0.002:
		figure.rotation.y = lerp_angle(figure.rotation.y, atan2(-direction.x, -direction.z), 1.0 - exp(-seconds * 15.0))
	_animate(motion, seconds)

func _animate(speed: float, seconds: float) -> void:
	pace += seconds * (4.1 + speed * 2.29)
	var movement := minf(speed / WALK, 1.0)
	var stride := sin(pace) * 0.56 * movement
	legs[0].rotation.x = stride
	legs[1].rotation.x = -stride
	arms[0].rotation.x = -stride * 0.55
	arms[1].rotation.x = stride * 0.55
	figure.position.y = 0.018 * sin(pace * 2.0) * movement

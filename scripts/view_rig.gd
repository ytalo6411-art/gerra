extends Camera3D
## Same actor and motion reference, two camera prototypes. Yaw is player controlled.

var mode := 0
var yaw := 0.31
var zoom := 24.0
var _smooth_focus := Vector3.ZERO
var _smooth_position := Vector3.ZERO
var _initialized := false

func _ready() -> void:
	current = true
	keep_aspect = Camera3D.KEEP_HEIGHT
	near = 0.13
	far = 90

func restore(configuration: Array) -> void:
	mode = int(configuration[0])
	yaw = float(configuration[1])
	zoom = float(configuration[2])
	_initialized = false

func orbit(steps: float) -> void:
	yaw = wrapf(yaw + steps * PI * 0.25, -PI, PI)

func change_zoom(steps: float) -> void:
	zoom = clampf(zoom + steps * 2.2, 13, 38)

func flip() -> void:
	mode = 1 - mode
	_initialized = false

func snapshot() -> Array:
	return [mode, yaw, zoom]

func compass_heading() -> String:
	const NAMES := ["N", "NO", "O", "SO", "S", "SE", "L", "NE"]
	return NAMES[posmod(roundi(yaw / (PI * 0.25)), 8)]

func movement(input: Vector2) -> Vector3:
	var right := Vector3(cos(yaw), 0, -sin(yaw))
	var backward := Vector3(sin(yaw), 0, cos(yaw))
	return right * input.x + backward * input.y

func follow(actor: CharacterBody3D, seconds: float, menu: bool = false, cabin: bool = false) -> void:
	var elevated := mode == 0 or menu
	var azimuth := 0.30 if menu else yaw
	var look := actor.global_position + Vector3(0, 0.85 if elevated else 1.35, 0)
	if menu:
		look = Vector3(-7.0, 0.86, 4.65)
	elif elevated:
		look += Vector3(-sin(azimuth), 0, -cos(azimuth)) * 2.85
		look += Vector3(cos(azimuth), 0, -sin(azimuth)) * 0.9
	var backward := Vector3(sin(azimuth), 0, cos(azimuth))
	var slide := 1.0 - exp(-seconds * 10.5)
	_smooth_focus = _smooth_focus.lerp(look, slide) if _initialized else look
	var ideal: Vector3
	if elevated:
		projection = Camera3D.PROJECTION_ORTHOGONAL
		size = lerpf(size, 29.5 if menu else zoom, slide) if _initialized else (29.5 if menu else zoom)
		ideal = _smooth_focus + backward * 16.0 + Vector3.UP * 23.0
	else:
		projection = Camera3D.PROJECTION_PERSPECTIVE
		fov = 66.0
		var arm := lerpf(3.30, 6.2, inverse_lerp(13, 38, zoom))
		if cabin:
			arm *= 0.72
		ideal = _smooth_focus + backward * arm + Vector3.UP * 1.14
		var query := PhysicsRayQueryParameters3D.create(_smooth_focus, ideal, 1, [actor.get_rid()])
		var hit := actor.get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			ideal = hit["position"] + (_smooth_focus - ideal).normalized() * 0.20
	_smooth_position = _smooth_position.lerp(ideal, slide) if _initialized and elevated else ideal
	_initialized = true
	position = _smooth_position
	look_at(_smooth_focus, Vector3.UP)

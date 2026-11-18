extends RefCounted
## Repeatable route, never writes the game save. Run on the actual target with a display.

const ROUTE := [Vector2(-5.6, 6.3), Vector2(3.4, 7.0), Vector2(12.6, 10.3), Vector2(23.3, 10.3), Vector2(31.6, 12.1), Vector2(35.0, 12.9), Vector2(26.0, 10.4), Vector2(14.0, 10.3), Vector2(2.8, 7.1), Vector2(-6.8, 8.7)]
var enabled := false
var camera_mode := 0
const INSIDE := [Vector2(-2.8, -1.4), Vector2(-0.1, -1.55), Vector2(-0.1, -3.75), Vector2(-2.30, -4.65), Vector2(-2.8, -1.4)]
var duration := 60.0
var scenario := "trilha"
var reached := 0
var elapsed := 0.0
var target := 0
var samples: Array[float] = []
var draws: Array[float] = []
var objects: Array[float] = []
var sample_countdown := 0.0
var loading_ms := 0.0
var last_frame_us := 0

func read_args(args: PackedStringArray) -> void:
	for arg: String in args:
		if arg.begins_with("--benchmark="):
			enabled = true
			camera_mode = 1 if arg.get_slice("=", 1).to_upper() == "B" else 0
		elif arg.begins_with("--benchmark-seconds="):
			duration = clampf(arg.get_slice("=", 1).to_float(), 5, 300)
		elif arg == "--benchmark-scenario=interior":
			scenario = "interior"

func direction(p: Vector3) -> Vector3:
	var point := Vector2(p.x, p.z)
	var route: Array = INSIDE if scenario == "interior" else ROUTE
	if point.distance_squared_to(route[target]) < 0.42:
		target = (target + 1) % route.size()
		reached += 1
	var vector: Vector2 = (route[target] - point).normalized()
	return Vector3(vector.x, 0, vector.y)

func frame(sectors: int, render_scale: float) -> bool:
	var now := Time.get_ticks_usec()
	var previous := last_frame_us
	last_frame_us = now
	if previous == 0:
		return false
	# Engine delta may be clamped under heavy load, so use the monotonic wall clock.
	var seconds := float(now - previous) / 1e6
	elapsed += seconds
	if elapsed < 3.0:
		return false
	samples.append(seconds * 1000.0)
	sample_countdown -= seconds
	if sample_countdown <= 0.0:
		sample_countdown = 1.0
		draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		objects.append(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
	if elapsed < 3.0 + duration:
		return false
	samples.sort()
	var avg := _average(samples)
	var slow := samples[mini(samples.size() - 1, floori(samples.size() * 0.99))]
	var report := {"camera": "A" if camera_mode == 0 else "B", "seconds": duration, "render_scale": render_scale, "route": scenario, "waypoints": reached,
		"fps_mean": snappedf(1000.0 / maxf(avg, 0.01), 0.1), "frame_ms_p99": snappedf(slow, 0.1),
		"frame_ms_max": snappedf(samples.back(), 0.1), "mesh_objects_mean": _average(objects),
		"draw_calls_mean": _average(draws), "active_sectors_end": sectors, "load_ms": loading_ms,
		"godot_static_mib": snappedf(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, 0.1)}
	print("NWH_BENCHMARK ", JSON.stringify(report))
	return true

static func _average(values: Array[float]) -> float:
	if values.is_empty():
		return 0
	var total := 0.0
	for value: float in values: total += value
	return snappedf(total / values.size(), 0.01)

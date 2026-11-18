extends Node3D
## Session composition root. Data, streamed world, input and UI meet only here.

const Catalog = preload("res://systems/catalog.gd")
const Session = preload("res://systems/world_state.gd")
const Store = preload("res://systems/save_store.gd")
const World = preload("res://world/streamer.gd")
const Land = preload("res://world/landscape.gd")
const ObjectView = preload("res://world/object_view.gd")
const Survivor = preload("res://scripts/survivor.gd")
const Rig = preload("res://scripts/view_rig.gd")
const Controls = preload("res://scripts/controls.gd")
const HUD = preload("res://ui/field_hud.gd")
const Sound = preload("res://audio/field_sound.gd")
const Benchmark = preload("res://scripts/benchmark.gd")

var catalog: Catalog
var session: Session
var store: Store
var world: World
var person: Survivor
var rig: Rig
var hud: HUD
var sound: Sound
var benchmark := Benchmark.new()
var phase := "title"
var before_guide := "title"
var save_found := false
var startup_notice := ""
var cooldown := 0.0
var auto_clock := 0.0
var state_clock := 0.0
var scan_clock := 0.0
var step_clock := 0.0
var pending_interaction := false
var spawned := false
var dirty := false
var sprint_latched := false
var objective := "pump_cedro"
var test_mode := false
var economy := false
var test_store_path := ""

func _ready() -> void:
	var loaded_at := Time.get_ticks_msec()
	get_tree().auto_accept_quit = false
	Controls.register()
	var arguments := OS.get_cmdline_user_args()
	benchmark.read_args(arguments)
	economy = arguments.has("--economico")
	if economy:
		get_viewport().scaling_3d_scale = 0.62
	catalog = Catalog.new()
	session = Session.new(catalog)
	store = Store.new() if test_store_path.is_empty() else Store.new(test_store_path)
	if not benchmark.enabled:
		_open_save()
	_build_lighting()
	world = World.new()
	world.name = "Streaming"
	add_child(world)
	world.build(session)
	person = Survivor.new()
	add_child(person)
	person.build(world.kit)
	rig = Rig.new()
	add_child(rig)
	rig.restore(session.camera)
	if benchmark.enabled:
		rig.mode = benchmark.camera_mode
	if not save_found:
		_spawn_person()
		if benchmark.enabled and benchmark.scenario == "interior":
			person.position = Land.at(Vector2(-2.8, -1.5), 0.26)
	else:
		person.position = session.player_position
	var opening_view := person.position if benchmark.enabled else Land.at(Catalog.point(catalog.world["spawn"]))
	world.around(opening_view, true)
	rig.follow(person, 0, not benchmark.enabled)
	var canvas := CanvasLayer.new()
	canvas.name = "Interface"
	add_child(canvas)
	hud = HUD.new()
	canvas.add_child(hud)
	hud.build(session)
	_connect_hud()
	if not test_mode and not benchmark.enabled:
		sound = Sound.new()
		add_child(sound)
		sound.build()
	_set_phase("play" if benchmark.enabled else "title")
	benchmark.loading_ms = Time.get_ticks_msec() - loaded_at
	if benchmark.enabled:
		print("NWH_BENCHMARK_START ", benchmark.loading_ms, " ms; renderer ", RenderingServer.get_current_rendering_method())

func _open_save() -> void:
	save_found = store.load_latest(session)
	if save_found:
		if store.source != "principal":
			startup_notice = "Registro recuperado: %s." % store.source
		return
	if store.has_files() and not test_mode:
		# Never overwrite an incompatible slot until there is a migration/recovery UI.
		var suffix := 1
		while store.has_files() and not save_found:
			store = Store.new("user://vale_do_cedro_rec_%02d.json" % suffix)
			suffix += 1
			save_found = store.load_latest(session)
		startup_notice = "Registro anterior preservado. Usando um espaço de recuperação."

func _connect_hud() -> void:
	hud.begin.connect(_begin)
	hud.pause_requested.connect(_toggle_pause)
	hud.resume_requested.connect(_toggle_pause)
	hud.inventory_requested.connect(_toggle_bag)
	hud.map_requested.connect(_toggle_map)
	hud.camera_requested.connect(_switch_camera)
	hud.save_requested.connect(_manual_save)
	hud.interact_requested.connect(_queue_interaction)
	hud.use_requested.connect(use_slot)
	hud.successor_requested.connect(_successor)
	hud.guide_requested.connect(func() -> void:
		before_guide = phase
		_set_phase("guide"))
	hud.back_requested.connect(func() -> void: _set_phase(before_guide))

func _build_lighting() -> void:
	var atmosphere := Environment.new()
	atmosphere.background_mode = Environment.BG_SKY
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("788f9b")
	sky_material.sky_horizon_color = Color("bac1ab")
	sky_material.ground_horizon_color = Color("bac1ab")
	sky_material.ground_bottom_color = Color("5a6653")
	sky_material.sun_angle_max = 12.0
	var sky := Sky.new()
	sky.sky_material = sky_material
	atmosphere.sky = sky
	atmosphere.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	atmosphere.ambient_light_color = Color("c3ccba")
	atmosphere.ambient_light_energy = 0.61
	atmosphere.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	atmosphere.fog_enabled = true
	atmosphere.fog_light_color = Color("adb7a4")
	atmosphere.fog_light_energy = 0.82
	atmosphere.fog_density = 0.0030
	atmosphere.fog_aerial_perspective = 0.34
	var space := WorldEnvironment.new()
	space.environment = atmosphere
	add_child(space)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-43, -27, 0)
	sun.light_color = Color("f4eee0")
	sun.light_energy = 0.79
	sun.shadow_enabled = not economy
	sun.shadow_blur = 0.85
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 44
	sun.shadow_normal_bias = 1.23
	add_child(sun)

func _spawn_person() -> void:
	var start := Vector2(session.player_position.x, session.player_position.z)
	person.position = Land.at(start, 0.03)
	person.velocity = Vector3.ZERO

func _begin() -> void:
	if phase != "title":
		return
	spawned = true
	world.around(person.position, true)
	if sound != null: sound.start()
	_set_phase("play" if session.is_alive() else "dead")
	if not save_found:
		_write(false, false)

func _set_phase(kind: String) -> void:
	phase = kind
	pending_interaction = false
	if hud == null:
		return
	hud.show_state(phase, save_found, startup_notice)
	hud.update_camera(rig.mode, rig.compass_heading())
	if kind == "bag":
		hud.bag.receive(session, true)
	if sound != null:
		sound.silent(kind != "play")
	scan_clock = 0

func _toggle_pause() -> void:
	match phase:
		"pause", "bag", "map": _set_phase("play")
		"guide": _set_phase(before_guide)
		"play": _set_phase("pause")

func _toggle_bag() -> void:
	if phase == "play" or phase == "map": _set_phase("bag")
	elif phase == "bag": _set_phase("play")

func _toggle_map() -> void:
	if phase == "play" or phase == "bag": _set_phase("map")
	elif phase == "map": _set_phase("play")

func _switch_camera() -> void:
	if phase != "play": return
	rig.flip()
	dirty = true
	hud.update_camera(rig.mode, rig.compass_heading())

func _successor() -> void:
	if phase != "dead": return
	session.new_survivor()
	_spawn_person()
	world.around(person.position, true)
	_refresh()
	_set_phase("play")
	_write(false, true)

func _manual_save() -> void:
	if phase in ["play", "pause"]: _write(true, true)

func _write(manual: bool, feedback: bool) -> bool:
	if benchmark.enabled: return false
	session.player_position = person.position
	session.camera = rig.snapshot()
	var recorded: bool = session.journal["recorded"]
	if manual and session.ready_to_record():
		session.journal["recorded"] = true
	if not store.write(session):
		session.journal["recorded"] = recorded
		if feedback: hud.notify(store.last_error, false)
		else: push_warning(store.last_error)
		return false
	dirty = false
	auto_clock = 0
	save_found = true
	if manual:
		_refresh()
		_cue("save")
	if feedback:
		hud.notify("Primeiro refúgio registrado." if manual and not recorded and session.journal["recorded"] else "Progresso salvo neste dispositivo.", true)
	return true

func _queue_interaction() -> void:
	if phase == "play": pending_interaction = true

func _interact(view: ObjectView) -> void:
	if view == null: return
	if view.rule["kind"] == "door" and session.changes.get(view.id, false) and Vector2(person.position.x - view.position.x, person.position.z - view.position.z).length_squared() < 0.79:
		hud.notify("Afaste-se um pouco do batente para fechar a porta.", false)
		return
	var response := session.interact(view.id)
	_commit_action(response)

func use_slot(index: int) -> void:
	if phase not in ["play", "bag"]: return
	_commit_action(session.use_slot(index))

func _commit_action(response: Dictionary) -> void:
	hud.notify(response["text"], response["ok"])
	if response["ok"]:
		_refresh()
		_cue(response["effect"])
		dirty = true
		_write(false, false)
		scan_clock = 0

func _refresh() -> void:
	world.sync_all()
	hud.update_model(session)
	_update_objective()

func _update_objective() -> void:
	var logbook: Dictionary = session.journal
	if not logbook["water"]:
		objective = "" if session.inventory.count("water") > 0 else "pump_cedro"
	elif not logbook["wood"]:
		objective = _closest_supply("branch")
	elif not logbook["fire"]:
		objective = "fire_cedro"
	elif not logbook["food"]:
		if session.inventory.count("ration") + session.inventory.count("berries") > 0:
			objective = ""
		elif session.changes.get("cache_cedro", false):
			objective = _closest_supply("berries")
		else:
			objective = "cache_cedro" if session.changes.get("door_cedro", false) else "door_cedro"
	elif not logbook["shelter"]:
		objective = "bed_cedro" if session.changes.get("door_cedro", false) else "door_cedro"
	else:
		objective = ""

func _closest_supply(item: String) -> String:
	var best := INF
	var id_result := ""
	for id: String in catalog.objects:
		var rule: Dictionary = catalog.objects[id]
		if rule.get("item") != item or not session.can_interact(id): continue
		var dist := person.position.distance_squared_to(Land.at(Catalog.point(rule["pos"])))
		if dist < best:
			best = dist
			id_result = id
	return id_result

func _cue(kind: String) -> void:
	if sound != null: sound.cue(kind)

func _physics_process(delta: float) -> void:
	if phase == "title" or (phase == "guide" and before_guide == "title"):
		rig.follow(person, delta, true)
		return
	if phase != "play": return
	var keys := Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
	var dir := benchmark.direction(person.position) if benchmark.enabled else rig.movement(keys)
	var energy := float(session.needs["energy"])
	if energy < 1.4: sprint_latched = true
	if energy > 15 or not Input.is_action_pressed("sprint"): sprint_latched = false
	var running := Input.is_action_pressed("sprint") and dir.length_squared() > 0.04 and not sprint_latched
	world.around(person.position)
	person.drive(dir, running, delta, float(catalog.world["size"]) * 0.5 - 0.62)
	var indoors := is_instance_valid(world.cabin) and world.cabin.inside(person.position)
	rig.follow(person, delta, false, indoors)
	if is_instance_valid(world.cabin):
		world.cabin.update_cutaway(person.position, rig.position, rig.mode == 0)
	if not benchmark.enabled:
		_step_session(delta, running)
		_track_interaction(delta)
	else:
		_update_map()

func _step_session(delta: float, running: bool) -> void:
	state_clock += delta
	if state_clock >= 0.24:
		session.tick(state_clock, running)
		state_clock = 0.0
		dirty = true
		hud.update_needs(session)
		if not session.is_alive():
			_write(false, false)
			_set_phase("dead")
			return
	auto_clock += delta
	if auto_clock >= 25:
		auto_clock = 0
		if dirty: _write(false, false)
	if person.is_on_floor() and Vector2(person.velocity.x, person.velocity.z).length() > 1.0:
		step_clock += delta
		if step_clock >= (0.34 if running else 0.49):
			_cue("step")
			step_clock = 0.0
	else:
		step_clock = 0.34

func _track_interaction(delta: float) -> void:
	if phase != "play": return
	scan_clock -= delta
	if scan_clock <= 0 or pending_interaction:
		scan_clock = 0.09
		var target := world.closest(person)
		if pending_interaction:
			pending_interaction = false
			_interact(target)
			target = world.closest(person)
		hud.set_prompt(session.prompt(target.id) if target != null else [])
		_update_objective()
		_update_map()
	if not objective.is_empty() and world.targets.has(objective):
		var goal: ObjectView = world.targets[objective]
		var position_3d := goal.position + Vector3.UP * (1.47 + goal.anchor.y * 0.22)
		var distance := person.position.distance_to(goal.position)
		var show_marker := distance > 3.0 and distance < 37.0 and not rig.is_position_behind(position_3d)
		hud.place_marker(rig.unproject_position(position_3d), distance, show_marker)
	else:
		hud.place_marker(Vector2.ZERO, 0, false)

func _update_map() -> void:
	hud.set_location(person.position, rig.yaw, world.current, objective)

func _process(delta: float) -> void:
	hud.tick(delta)
	if benchmark.enabled and benchmark.frame(world.active.size(), get_viewport().scaling_3d_scale):
		get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		_toggle_pause()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ENTER and phase == "title":
		_begin()
	elif event.is_action_pressed("inventory"):
		_toggle_bag()
	elif event.is_action_pressed("map_view"):
		_toggle_map()
	elif event.is_action_pressed("save_game"):
		_manual_save()
	elif phase == "play":
		if event.is_action_pressed("camera"):
			_switch_camera()
		elif event.is_action_pressed("interact"):
			_queue_interaction()
		elif event.is_action_pressed("orbit_left") or event.is_action_pressed("orbit_right"):
			rig.orbit(1 if event.is_action_pressed("orbit_left") else -1)
			dirty = true
			hud.update_camera(rig.mode, rig.compass_heading())
		elif event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			rig.change_zoom(-1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1)
			dirty = true
		else:
			for index in range(6):
				if event.is_action_pressed("slot%d" % (index + 1)): use_slot(index)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_node_ready():
		if spawned and dirty: _write(false, true)
		get_tree().quit()

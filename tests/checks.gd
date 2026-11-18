extends SceneTree
## Run: godot --headless --path . --script res://tests/checks.gd

const Catalog = preload("res://systems/catalog.gd")
const Inventory = preload("res://systems/inventory.gd")
const Model = preload("res://systems/world_state.gd")
const Store = preload("res://systems/save_store.gd")
const Land = preload("res://world/landscape.gd")
const Game = preload("res://scripts/valley.gd")
const SCENE = preload("res://scenes/valley.tscn")

var passed := 0
var failed := 0
var test_path := "user://check_%s_%s" % [OS.get_process_id(), Time.get_ticks_usec()]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var defs := Catalog.new()
	_check_inventory(defs)
	_check_model(defs)
	_check_save(defs)
	await _check_scene()
	for key: String in ["_data", "_scene", "_first"]:
		for suffix: String in ["", ".bak", ".tmp", ".bak.tmp"]:
			var path := test_path + key + suffix
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("NWH_TESTS %d verificações passaram; %d falharam" % [passed, failed])
	quit(0 if failed == 0 else 1)

func _check_inventory(defs: Catalog) -> void:
	var bag := Inventory.new(defs.items)
	_expect(bag.add("branch", 13) and bag.slots[0]["n"] == 12 and bag.slots[1]["n"] == 1, "Stack dividido sem perder unidades")
	_expect(bag.add("water", 16), "Preenche os outros quatro espaços")
	var before := bag.slots.duplicate(true)
	_expect(not bag.add("ration", 1) and before == bag.slots, "Mochila cheia rejeita coleta de forma atômica")
	_expect(not bag.add("branch", 12) and before == bag.slots, "Capacidade parcial não duplica nem perde material")
	_expect(not bag.pay({"branch": 1, "ration": 1}) and before == bag.slots, "Receita inválida não desconta nenhum ingrediente")
	_expect(bag.pay({"branch": 13}) and bag.slots[0] == null and bag.slots[1] == null, "Receita desconta de múltiplos stacks e libera slots")

func _check_model(defs: Catalog) -> void:
	var state := Model.new(defs)
	_expect(not state.interact("fire_cedro")["ok"] and not state.journal["fire"], "Fogo não acende sem materiais")
	_expect(state.interact("wood_trail_a")["ok"] and not state.interact("wood_trail_a")["ok"], "Coleta única por ID")
	state.interact("wood_trail_b")
	_expect(state.journal["wood"] and state.interact("fire_cedro")["ok"] and state.inventory.count("branch") == 0, "Fogueira consome três galhos")
	_expect(state.interact("fire_cedro")["ok"] and state.inventory.count("branch") == 0, "Aquecimento não cobra nova receita")
	for i in range(4): _expect(state.interact("pump_cedro")["ok"], "Obtenção da porção de água %d" % (i + 1))
	_expect(not state.interact("pump_cedro")["ok"], "Limite do cantil é respeitado")
	var water_before: float = state.needs["water"]
	_expect(state.use_slot(0)["ok"] and state.needs["water"] > water_before and state.inventory.count("water") == 3, "Beber restaura hidratação e consome uma porção")
	state.interact("cache_cedro")
	_expect(state.use_slot(1)["ok"] and state.journal["food"], "Alimento da caixa restaura saciedade")
	_expect(state.interact("rest_cedro")["ok"] == false, "IDs inválidos são rejeitados")
	state.interact("bed_cedro")
	_expect(state.ready_to_record(), "Cinco atividades deixam o diário pronto para registrar")
	var full: float = state.needs["water"]
	state.tick(35, false)
	_expect(state.needs["water"] < full and state.elapsed == 35, "Necessidades mudam no tick ativo")
	state.needs["water"] = 0.0
	state.tick(250, false)
	_expect(not state.is_alive(), "Desidratação extrema pode encerrar a jornada")
	state.new_survivor()
	_expect(state.is_alive() and state.survivor == 2 and state.changes["fire_cedro"] and state.inventory.count("water") == 0, "Novo sobrevivente usa o mesmo mundo, sem herdar mochila")

func _check_save(defs: Catalog) -> void:
	var state := Model.new(defs)
	state.interact("wood_trail_a")
	state.interact("door_cedro")
	state.interact("pump_cedro")
	state.camera = [1, -0.78, 19.6]
	state.player_position = Vector3(-17.7, 0.24, 22.1)
	var save := Store.new(test_path + "_data")
	var other := Model.new(defs)
	for i in range(20):
		state.elapsed = 27.2 + i
		var ok := save.write(state) and save.load_latest(other)
		_expect(ok and is_equal_approx(state.elapsed, other.elapsed) and other.changes == state.changes and other.inventory.slots == state.inventory.slots and other.camera == state.camera and other.player_position.is_equal_approx(state.player_position), "Gravação e reabertura %02d/20" % (i + 1))
	var frozen := other.elapsed
	OS.delay_msec(25)
	_expect(save.load_latest(other) and other.elapsed == frozen, "O relógio salvo não depende da hora do sistema")
	_write_text(save.path + ".tmp", "")
	_expect(save.load_latest(other) and save.source == "principal", "Interrupção durante gravação não afeta principal válido")
	_write_text(save.path, "{}")
	_expect(save.load_latest(other) and save.source == "backup" and is_equal_approx(other.elapsed, frozen - 1), "Principal danificado restaura o backup anterior")
	var backup_data := FileAccess.get_file_as_string(save.path + ".bak")
	_expect(save.write(state) and FileAccess.get_file_as_string(save.path + ".bak") == backup_data, "Principal inválido nunca sobrescreve o backup bom")
	var invalid := state.snapshot()
	invalid["version"] = 99
	_write_envelope(save.path, invalid)
	_expect(save.load_latest(other) and save.source == "backup", "Formato válido com versão incompatível é rejeitado")
	invalid["version"] = 1
	invalid["slots"][0]["n"] = 8000
	_write_envelope(save.path, invalid)
	_expect(save.load_latest(other) and save.source == "backup", "Quantidade impossível é rejeitada mesmo com checksum correto")
	var first := Store.new(test_path + "_first")
	_write_envelope(first.path + ".tmp", state.snapshot())
	_expect(first.load_latest(other) and first.source == "temporário", "Primeira gravação interrompida recupera temporário validado")
	_expect(first.write(other) and FileAccess.file_exists(first.path + ".bak"), "Substituição do temporário preserva a única cópia anterior")

func _check_scene() -> void:
	var game := _start_test_scene()
	game._begin()
	await _wait_physics(5)
	_expect(game.phase == "play" and game.person.is_on_floor() and game.world.active.size() == 9, "Cena inicial com solo físico e nove setores")
	var start := game.person.position
	Input.action_press("walk_up")
	await _wait_physics(25)
	Input.action_release("walk_up")
	_expect(start.distance_to(game.person.position) > 0.6, "Movimento pelo mesmo InputMap da partida")
	game._switch_camera()
	await _wait_physics(3)
	_expect(game.rig.projection == Camera3D.PROJECTION_PERSPECTIVE, "Câmera B usa perspectiva")
	game._switch_camera()
	await _wait_physics(3)
	_expect(game.rig.projection == Camera3D.PROJECTION_ORTHOGONAL, "Câmera A usa ortográfica")
	game._toggle_bag()
	var elapsed := game.session.elapsed
	await _wait_physics(20)
	_expect(game.hud.bag.visible and elapsed == game.session.elapsed, "Mochila abre sem simular necessidades")
	game._toggle_map()
	_expect(game.hud.map_sheet.visible and not game.hud.bag.visible, "Mapa substitui o painel de mochila")
	game._toggle_map()
	await _go(game, Vector2(3.8, 4.79))
	await _use_context(game, "pump_cedro")
	game.use_slot(0)
	await _go(game, Vector2(-8.2, 7.80))
	await _use_context(game, "wood_trail_a")
	await _go(game, Vector2(-10.3, 3.67))
	await _use_context(game, "wood_trail_b")
	await _go(game, Vector2(-3.5, 5.53))
	await _use_context(game, "fire_cedro")
	_expect(game.session.journal["fire"] and game.world.targets["fire_cedro"].flame.visible, "Fogueira aparece acesa após consumir galhos")
	await _go(game, Vector2(-1.35, 1.82))
	await _walk(game, Vector2(-1.35, -2.05), 65)
	_expect(game.person.position.z > 0.30, "Porta fechada bloqueia entrada")
	await _use_context(game, "door_cedro")
	await _walk(game, Vector2(-1.2, -2.05), 120)
	_expect(game.world.cabin.inside(game.person.position) and game.person.position.z < -1.7, "Entrada pela porta aberta e rampa real")
	await _wait_physics(4)
	_expect(not game.world.cabin.roof.visible, "Câmera elevada recorta telhado dentro da cabana")
	await _go(game, Vector2(-7.82, -3.3))
	var target := game.world.closest(game.person)
	_expect(target == null or target.id != "cache_cedro", "Parede impede saque à distância")
	await _go(game, Vector2(-4.51, -2.11))
	await _use_context(game, "cache_cedro")
	game.use_slot(0)
	await _go(game, Vector2(-0.12, -3.72))
	await _use_context(game, "bed_cedro")
	game._manual_save()
	_expect(game.session.journal["recorded"] and game.session.ready_to_record(), "Loop integrado completo: seis tarefas no diário")
	await _go(game, Vector2(13.3, 10.3))
	await _walk(game, Vector2(23.7, 10.3), 240)
	_expect(game.person.position.x > 23.3 and game.person.position.y > -0.03, "Ponte atravessável sem cair no riacho")
	await _go(game, Vector2(95.1, 28.1))
	_expect(not game.world.targets.has("fire_cedro") and game.world.active.size() <= 9, "Setor original sai da memória")
	await _go(game, Vector2(-7.2, 9.4))
	_expect(game.world.targets["fire_cedro"].flame.visible and not game.world.targets["wood_trail_a"].visible and game.world.targets["door_cedro"].hinge.rotation.y < -1, "Setor recriado preserva fogueira, coleta e porta")
	game._manual_save()
	var snapshot := game.session.snapshot()
	game.queue_free()
	await process_frame
	await process_frame
	var reopened := _start_test_scene()
	await _wait_physics(25)
	var restored := reopened.session.snapshot()
	var same := is_equal_approx(restored["elapsed"], snapshot["elapsed"])
	for key: String in Model.INITIAL:
		same = same and is_equal_approx(restored["needs"][key], snapshot["needs"][key])
	for key: String in ["world", "slots", "changes", "journal", "survivor", "position", "camera"]:
		same = same and restored[key] == snapshot[key]
	_expect(reopened.phase == "title" and reopened.save_found and same, "Reabertura real da cena mantém o registro congelado")
	reopened._begin()
	_expect(reopened.phase == "play" and reopened.session.journal["recorded"], "Continuar volta à sessão já concluída")
	reopened.queue_free()
	await process_frame

func _start_test_scene() -> Game:
	var game: Game = SCENE.instantiate()
	game.test_mode = true
	game.test_store_path = test_path + "_scene"
	root.add_child(game)
	return game

func _wait_physics(frames: int) -> void:
	for i in range(frames): await physics_frame

func _go(game: Game, at: Vector2) -> void:
	game.person.position = Land.at(at, 0.30)
	game.person.velocity = Vector3.ZERO
	game.world.around(game.person.position, true)
	await _wait_physics(4)

func _walk(game: Game, to: Vector2, max_frames: int) -> void:
	game.set_physics_process(false)
	for i in range(max_frames):
		await physics_frame
		var direction := Vector3(to.x - game.person.position.x, 0, to.y - game.person.position.z)
		if direction.length_squared() < 0.018:
			break
		game.world.around(game.person.position)
		game.person.drive(direction.normalized(), false, 1.0 / 60.0, 127)
	game.person.velocity = Vector3.ZERO
	game.set_physics_process(true)
	await _wait_physics(3)

func _use_context(game: Game, id: String) -> void:
	var nearby := game.world.closest(game.person)
	_expect(nearby != null and nearby.id == id, "Interação contextual seleciona %s (%s)" % [id, nearby.id if nearby != null else "sem alvo"])
	if nearby != null and nearby.id == id:
		game._queue_interaction()
		await _wait_physics(3)

func _expect(condition: bool, text: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FALHA: " + text)

static func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()

static func _write_envelope(path: String, data: Dictionary) -> void:
	var text := JSON.stringify(data, "", true, true)
	_write_text(path, JSON.stringify({"format": 1, "sha256": text.sha256_text(), "payload": text}))

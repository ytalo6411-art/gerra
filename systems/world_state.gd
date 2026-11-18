extends RefCounted
## Persistent session model. Has no nodes and never refers to streamed views.

const Catalog = preload("res://systems/catalog.gd")
const Inventory = preload("res://systems/inventory.gd")
const JOURNAL := ["water", "wood", "fire", "food", "shelter", "recorded"]
const INITIAL := {"health": 100.0, "food": 62.0, "water": 49.0, "energy": 85.0}
const VERSION := 1

var catalog: Catalog
var inventory: Inventory
var needs: Dictionary
var changes: Dictionary = {}
var journal: Dictionary = {}
var elapsed := 0.0
var survivor := 1
var player_position := Vector3.ZERO
var camera := [0, 0.31, 24.0]

func _init(definitions: Catalog) -> void:
	catalog = definitions
	inventory = Inventory.new(catalog.items)
	needs = INITIAL.duplicate()
	set_spawn()
	for key: String in JOURNAL:
		journal[key] = false

func set_spawn() -> void:
	var p := Catalog.point(catalog.world["spawn"])
	player_position = Vector3(p.x, 0.0, p.y)

func is_alive() -> bool:
	return float(needs["health"]) > 0.0

func new_survivor() -> void:
	survivor += 1
	needs = INITIAL.duplicate()
	inventory.clear()
	set_spawn()

func tick(seconds: float, exertion: bool) -> void:
	if seconds <= 0 or not is_alive():
		return
	elapsed += seconds
	needs["food"] = maxf(float(needs["food"]) - seconds * (0.078 if exertion else 0.049), 0)
	needs["water"] = maxf(float(needs["water"]) - seconds * (0.145 if exertion else 0.080), 0)
	var recovery := 3.3 if minf(needs["food"], needs["water"]) >= 12 else 1.3
	needs["energy"] = clampf(float(needs["energy"]) + seconds * (-13.0 if exertion else recovery), 0, 100)
	if needs["food"] <= 0 or needs["water"] <= 0:
		needs["health"] = maxf(float(needs["health"]) - 0.41 * seconds, 0)
	elif needs["food"] >= 55 and needs["water"] >= 55:
		needs["health"] = minf(float(needs["health"]) + 0.07 * seconds, 100)

func can_interact(id: String) -> bool:
	if not is_alive() or not catalog.objects.has(id):
		return false
	var kind: String = catalog.objects[id]["kind"]
	return not (kind in ["pickup", "loot"] and changes.get(id, false))

func prompt(id: String) -> Array[String]:
	if not can_interact(id):
		return []
	var rule: Dictionary = catalog.objects[id]
	match rule["kind"]:
		"water": return ["Encher cantil", "Água da bomba • segura para beber"]
		"fire":
			if changes.get(id, false):
				return ["Aquecer-se", "Fogueira acesa • recupera energia"]
			return ["Acender fogueira", "%d / %d galhos na mochila" % [inventory.count("branch"), catalog.recipes["campfire"]["cost"]["branch"]]]
		"door": return ["Fechar porta" if changes.get(id, false) else "Abrir porta", "Cabana do guarda-florestal"]
		"rest": return ["Preparar abrigo", "Cama de campanha • recupera energia"]
		"loot": return ["Recolher provisões", "%s ×%d" % [catalog.items[rule["item"]]["name"], rule["amount"]]]
		"pickup": return ["Coletar %s" % String(catalog.items[rule["item"]]["name"]).to_lower(), "%s ×%d" % [rule["title"], rule["amount"]]]
	return []

func interact(id: String) -> Dictionary:
	if not can_interact(id):
		return _result(false, "Não há nada para recolher aqui.")
	var rule: Dictionary = catalog.objects[id]
	match rule["kind"]:
		"water":
			if inventory.count("water") >= 4:
				return _result(false, "Seu cantil já está cheio (4 porções).")
			if not inventory.add("water", 1):
				return _result(false, "Mochila cheia.")
			return _result(true, "Água na mochila. Use a porção na barra inferior.", "water")
		"fire":
			if changes.get(id, false):
				needs["energy"] = minf(float(needs["energy"]) + 18.0, 100.0)
				return _result(true, "Você se aqueceu junto ao fogo.", "fire")
			if not inventory.pay(catalog.recipes["campfire"]["cost"]):
				return _result(false, "São necessários 3 galhos secos para acender a fogueira.")
			changes[id] = true
			journal["fire"] = true
			return _result(true, "A fogueira está acesa.", "fire")
		"door":
			changes[id] = not changes.get(id, false)
			return _result(true, "Porta aberta." if changes[id] else "Porta fechada.", "door")
		"rest":
			journal["shelter"] = true
			needs["energy"] = 100.0
			return _result(true, "Abrigo preparado. Você recuperou a energia.", "shelter")
		"pickup", "loot":
			var item: String = rule["item"]
			var amount := int(rule["amount"])
			if not inventory.add(item, amount):
				return _result(false, "Mochila cheia.")
			changes[id] = true
			if item == "branch" and inventory.count("branch") >= 3:
				journal["wood"] = true
			return _result(true, "+%d %s" % [amount, catalog.items[item]["name"]], "pickup")
	return _result(false, "Interação indisponível.")

func use_slot(index: int) -> Dictionary:
	if not is_alive() or index < 0 or index >= Inventory.CAPACITY or inventory.slots[index] == null:
		return _result(false, "Este espaço está vazio.")
	var item: Dictionary = catalog.items[inventory.slots[index]["id"]]
	var effect: String = item.get("effect", "")
	if effect.is_empty():
		return _result(false, "Leve os galhos até a fogueira para usá-los.")
	if float(needs[effect]) >= 99.5:
		return _result(false, "Você não precisa disso agora.")
	inventory.remove_one(index)
	needs[effect] = minf(float(needs[effect]) + float(item["restore"]), 100.0)
	journal[effect] = true
	return _result(true, "Hidratação recuperada." if effect == "water" else "Saciedade recuperada.", effect)

func ready_to_record() -> bool:
	for key: String in JOURNAL:
		if key != "recorded" and not journal[key]:
			return false
	return true

func snapshot() -> Dictionary:
	return {"version": VERSION, "world": catalog.world["id"], "needs": needs.duplicate(),
		"slots": inventory.slots.duplicate(true), "changes": changes.duplicate(), "elapsed": elapsed,
		"journal": journal.duplicate(), "survivor": survivor, "camera": camera.duplicate(),
		"position": [player_position.x, player_position.y, player_position.z]}

func is_valid(data: Variant) -> bool:
	if not data is Dictionary or data.get("version") != VERSION or data.get("world") != catalog.world["id"]:
		return false
	if not _number(data.get("elapsed"), 0, 1e9) or not _number(data.get("survivor"), 1, 1000000):
		return false
	if data["survivor"] != int(data["survivor"]) or not inventory.is_valid(data.get("slots")):
		return false
	if not data.get("needs") is Dictionary or not data.get("changes") is Dictionary or not data.get("journal") is Dictionary:
		return false
	for key: String in INITIAL:
		if not _number(data["needs"].get(key), 0, 100):
			return false
	for key: Variant in data["changes"]:
		if not catalog.objects.has(key) or catalog.objects[key]["kind"] not in ["door", "fire", "loot", "pickup"] or not data["changes"][key] is bool:
			return false
	for key: String in JOURNAL:
		if not data["journal"].get(key) is bool:
			return false
	if not data.get("position") is Array or data["position"].size() != 3 or not data.get("camera") is Array or data["camera"].size() != 3:
		return false
	var p: Array = data["position"]
	var edge := float(catalog.world["size"]) / 2.0
	var c: Array = data["camera"]
	return (_number(p[0], -edge, edge) and _number(p[1], -8, 40) and _number(p[2], -edge, edge)
		and (c[0] == 0 or c[0] == 1) and _number(c[1], -TAU, TAU) and _number(c[2], 13, 38))

func restore(data: Dictionary) -> void:
	needs = data["needs"].duplicate()
	inventory.slots = data["slots"].duplicate(true)
	for slot: Variant in inventory.slots:
		if slot != null:
			# JSON reads numbers as floats; normalize counts at the model boundary.
			slot["n"] = int(slot["n"])
	changes = data["changes"].duplicate()
	journal = data["journal"].duplicate()
	elapsed = float(data["elapsed"])
	survivor = int(data["survivor"])
	var optics: Array = data["camera"]
	camera = [int(optics[0]), float(optics[1]), float(optics[2])]
	var p: Array = data["position"]
	player_position = Vector3(p[0], p[1], p[2])

static func _number(value: Variant, low: float, high: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) >= low and float(value) <= high

static func _result(ok: bool, text: String, effect: String = "") -> Dictionary:
	return {"ok": ok, "text": text, "effect": effect}

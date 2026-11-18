extends RefCounted
## Fixed-size indexed stacks. Failed operations never change a single slot.

const CAPACITY := 6
var definitions: Dictionary
var slots: Array = []

func _init(items: Dictionary) -> void:
	definitions = items
	clear()

func clear() -> void:
	slots.clear()
	slots.resize(CAPACITY)

func count(item: String) -> int:
	var total := 0
	for slot: Variant in slots:
		if slot != null and slot["id"] == item:
			total += int(slot["n"])
	return total

func add(item: String, amount: int) -> bool:
	if not definitions.has(item) or amount <= 0:
		return false
	var limit := int(definitions[item]["stack"])
	var free := 0
	for slot: Variant in slots:
		if slot == null:
			free += limit
		elif slot["id"] == item:
			free += limit - int(slot["n"])
	if free < amount:
		return false
	var remaining := amount
	for index in range(CAPACITY):
		var slot: Variant = slots[index]
		if slot != null and slot["id"] == item:
			var moved := mini(remaining, limit - int(slot["n"]))
			slot["n"] += moved
			remaining -= moved
	for index in range(CAPACITY):
		if remaining == 0:
			break
		if slots[index] == null:
			var moved := mini(remaining, limit)
			slots[index] = {"id": item, "n": moved}
			remaining -= moved
	return true

func pay(cost: Dictionary) -> bool:
	for item: String in cost:
		if int(cost[item]) <= 0 or count(item) < int(cost[item]):
			return false
	for item: String in cost:
		var remaining := int(cost[item])
		for index in range(CAPACITY):
			var slot: Variant = slots[index]
			if remaining > 0 and slot != null and slot["id"] == item:
				var taken := mini(remaining, int(slot["n"]))
				slot["n"] -= taken
				remaining -= taken
				if int(slot["n"]) == 0:
					slots[index] = null
	return true

func remove_one(index: int) -> void:
	if index < 0 or index >= CAPACITY or slots[index] == null:
		return
	slots[index]["n"] -= 1
	if int(slots[index]["n"]) == 0:
		slots[index] = null

func is_valid(data: Variant) -> bool:
	if not data is Array or data.size() != CAPACITY:
		return false
	for slot: Variant in data:
		if slot == null:
			continue
		if not slot is Dictionary or not slot.get("id") is String or not definitions.has(slot["id"]):
			return false
		var count_value: Variant = slot.get("n")
		if not (count_value is int or count_value is float) or not is_finite(float(count_value)):
			return false
		if count_value != int(count_value) or count_value < 1 or count_value > definitions[slot["id"]]["stack"]:
			return false
	return true

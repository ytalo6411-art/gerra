extends RefCounted
## Static definitions. They are deployment files, not part of the save game.

const ITEM_PATH := "res://data/items/catalog.json"
const RECIPE_PATH := "res://data/recipes/catalog.json"
const WORLD_PATH := "res://data/world/cedro.json"

var items := _read(ITEM_PATH)
var recipes := _read(RECIPE_PATH)
var world := _read(WORLD_PATH)
var objects: Dictionary = {}

func _init() -> void:
	for definition: Dictionary in world["objects"]:
		objects[definition["id"]] = definition

static func _read(path: String) -> Dictionary:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert(data is Dictionary, "Arquivo de dados inválido: %s" % path)
	return data

static func point(data: Array) -> Vector2:
	return Vector2(data[0], data[1])

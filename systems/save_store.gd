extends RefCounted
## One authoritative slot. Recover from a validated backup without replacing it with bad data.

const State = preload("res://systems/world_state.gd")
const FORMAT := 1
const DEFAULT_PATH := "user://vale_do_cedro_v1.json"
const MAX_BYTES := 128 * 1024
var path: String
var source := ""
var last_error := ""

func _init(file_path: String = DEFAULT_PATH) -> void:
	path = file_path

func has_files() -> bool:
	return FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak") or FileAccess.file_exists(path + ".tmp")

func load_latest(state: State) -> bool:
	source = ""
	last_error = ""
	for suffix: String in ["", ".bak", ".tmp"]:
		var data := _read(path + suffix, state)
		if not data.is_empty():
			state.restore(data)
			source = "principal" if suffix.is_empty() else ("backup" if suffix == ".bak" else "temporário")
			return true
	if has_files():
		last_error = "Nenhum registro válido foi encontrado. Os arquivos foram preservados."
	return false

func write(state: State) -> bool:
	last_error = ""
	var snapshot := state.snapshot()
	if not state.is_valid(snapshot):
		return _fail("O estado atual não passou na validação.")
	var payload := JSON.stringify(snapshot, "", true, true)
	var staged := path + ".tmp"
	# Preserve the one remaining recovery copy if an interrupted first write is the only valid file.
	if _read(path, state).is_empty() and _read(path + ".bak", state).is_empty() and not _read(staged, state).is_empty():
		if _rename(staged, path + ".bak") != OK:
			return _fail("Não foi possível preservar a cópia recuperável.")
	var file := FileAccess.open(staged, FileAccess.WRITE)
	if file == null:
		return _fail("Não foi possível abrir o arquivo temporário.")
	file.store_string(JSON.stringify({"format": FORMAT, "sha256": payload.sha256_text(), "payload": payload}))
	file.flush()
	var status := file.get_error()
	file.close()
	if status != OK or _read(staged, state).is_empty():
		return _fail("O arquivo temporário não passou na validação.")
	if not _read(path, state).is_empty():
		var backup_stage := path + ".bak.tmp"
		if DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(backup_stage)) != OK:
			return _fail("Não foi possível escrever o backup.")
		if _read(backup_stage, state).is_empty() or _rename(backup_stage, path + ".bak") != OK:
			return _fail("Não foi possível validar e substituir o backup.")
	if _rename(staged, path) != OK:
		return _fail("Não foi possível substituir o registro principal.")
	return true

static func _read(file_path: String, state: State) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {}
	var f := FileAccess.open(file_path, FileAccess.READ)
	if f == null:
		return {}
	if f.get_length() > MAX_BYTES:
		f.close()
		return {}
	var envelope: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not envelope is Dictionary or envelope.get("format") != FORMAT or not envelope.get("payload") is String:
		return {}
	var payload: String = envelope["payload"]
	if envelope.get("sha256") != payload.sha256_text():
		return {}
	var data: Variant = JSON.parse_string(payload)
	return data if state.is_valid(data) else {}

static func _rename(from: String, to: String) -> Error:
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(from), ProjectSettings.globalize_path(to))

func _fail(reason: String) -> bool:
	last_error = reason
	return false

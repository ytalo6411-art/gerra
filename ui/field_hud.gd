extends Control

signal begin
signal pause_requested
signal resume_requested
signal guide_requested
signal back_requested
signal successor_requested
signal inventory_requested
signal map_requested
signal camera_requested
signal save_requested
signal interact_requested
signal use_requested(index: int)

const Palette = preload("res://ui/palette.gd")
const Glyph = preload("res://ui/glyph.gd")
const Cartography = preload("res://ui/field_map.gd")
const Slot = preload("res://ui/slot_button.gd")
const Overlay = preload("res://ui/game_overlay.gd")
const InventorySheet = preload("res://ui/inventory_sheet.gd")
const State = preload("res://systems/world_state.gd")
const JOURNAL_TEXT := ["Encontre água e beba", "Recolha três galhos secos", "Acenda a fogueira", "Encontre e coma uma porção", "Prepare o abrigo", "Registre seu progresso"]
const FIELD_NOTES := ["Encha o cantil na bomba e use a porção.", "Há galhos junto à trilha de chegada.", "Leve os galhos ao círculo de pedras.", "Procure na cabana ou colha amoras.", "Use a cama de campanha na cabana.", "Use P ou o botão SALVAR."]

var t := Palette.new()
var mini: Cartography
var large_map: Cartography
var game: Control
var overlay: Overlay
var bag: InventorySheet
var map_sheet: Control
var veil: ColorRect
var compass: Label
var camera_button: Button
var coordinates: Label
var survivor_title: Label
var meters: Dictionary = {}
var checks: Array[Glyph] = []
var objectives: Array[Label] = []
var track: ColorRect
var diary_count: Label
var hint: Label
var belt: Array[Slot] = []
var prompt: Panel
var action: Button
var prompt_detail: Label
var goal_marker: Panel
var marker_distance: Label
var toast: Panel
var toast_label: Label
var toast_time := 0.0
var toast_mark: ColorRect

func build(model: State) -> void:
	theme = t.interface
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Palette.full(self)
	game = Control.new()
	game.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(game)
	Palette.full(game)
	_make_marker()
	_make_header()
	_make_diary()
	_make_vitals()
	_make_map(model, false)
	_make_belt()
	_make_prompt()
	veil = ColorRect.new()
	veil.color = Color("0e160fae")
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(veil)
	Palette.full(veil)
	bag = InventorySheet.new()
	add_child(bag)
	Palette.full(bag)
	bag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bag.build(t)
	bag.closed.connect(func() -> void: inventory_requested.emit())
	bag.use_requested.connect(func(index: int) -> void: use_requested.emit(index))
	_make_map(model, true)
	overlay = Overlay.new()
	add_child(overlay)
	Palette.full(overlay)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.build(t)
	overlay.begin.connect(func() -> void: begin.emit())
	overlay.resume.connect(func() -> void: resume_requested.emit())
	overlay.guide.connect(func() -> void: guide_requested.emit())
	overlay.back.connect(func() -> void: back_requested.emit())
	overlay.successor.connect(func() -> void: successor_requested.emit())
	overlay.save_requested.connect(func() -> void: save_requested.emit())
	_make_toast()
	update_model(model)

func show_state(kind: String, has_save: bool, notice: String = "") -> void:
	game.visible = kind in ["play", "bag", "map", "pause"]
	veil.visible = kind in ["bag", "map"]
	bag.visible = kind == "bag"
	map_sheet.visible = kind == "map"
	overlay.show_state(kind, has_save, notice)
	if kind != "play":
		prompt.hide()
		goal_marker.hide()

func update_model(model: State) -> void:
	survivor_title.text = "SOBREVIVENTE  /  %02d" % model.survivor
	update_needs(model)
	for i in range(6):
		belt[i].display(model.inventory.slots[i], model.catalog.items)
	bag.receive(model)
	var done := 0
	var next := -1
	for i in range(State.JOURNAL.size()):
		var checked: bool = model.journal[State.JOURNAL[i]]
		if checked:
			done += 1
		elif next == -1:
			next = i
		checks[i].setup("check" if checked else "pin", Palette.GREEN if checked else (Palette.GOLD if next == i else Palette.FAINT))
		checks[i].modulate.a = 1.0 if next == i or checked else 0.57
		objectives[i].add_theme_color_override("font_color", Palette.FAINT if checked else (Palette.TEXT if next == i else Palette.MUTE))
	diary_count.text = "%02d / 06" % done
	track.offset_right = 0.0 if done == 0 else 238.0 * float(done) / 6.0
	hint.text = FIELD_NOTES[next] if next != -1 else "Registro completo. O vale agora é seu refúgio."

func update_needs(model: State) -> void:
	for kind: String in meters:
		var meter: Array = meters[kind]
		var amount := clampf(float(model.needs[kind]) / 100.0, 0, 1)
		meter[0].offset_right = 110.0 * amount
		meter[1].text = "%d" % roundi(amount * 100)
		meter[0].color = Palette.RED if amount < 0.18 else meter[2]

func update_camera(mode: int, direction: String) -> void:
	camera_button.text = "A  ·  CÂMERA 3/4    C" if mode == 0 else "B  ·  TERCEIRA PESSOA    C"
	compass.text = "–  ·  –     %s     –  ·  –" % direction

func set_location(at: Vector3, yaw: float, cell: Vector2i, goal: String) -> void:
	mini.update_location(at, yaw, goal)
	large_map.update_location(at, yaw, goal)
	coordinates.text = "SETOR %s%02d" % [String.chr(69 + cell.x), cell.y + 5]

func set_prompt(contents: Array) -> void:
	prompt.visible = not contents.is_empty()
	if prompt.visible:
		action.text = "E     " + contents[0]
		prompt_detail.text = contents[1]

func place_marker(point: Vector2, distance: float, enabled: bool) -> void:
	var bounds := get_viewport_rect().size
	var clear := Rect2(55, 108, bounds.x - 110, bounds.y - 280).has_point(point)
	clear = clear and not Rect2(bounds.x - 320, 0, 320, 345).has_point(point)
	clear = clear and not Rect2(0, 0, 280, 150).has_point(point)
	goal_marker.visible = enabled and clear
	if goal_marker.visible:
		goal_marker.position = point.round() - Vector2(35, 27)
		marker_distance.text = "%d m" % roundi(distance)

func notify(message: String, good: bool) -> void:
	toast_time = 3.6
	toast_label.text = message
	toast_mark.color = Palette.GOLD if good else Palette.RED
	toast.modulate.a = 1.0
	toast.show()

func tick(seconds: float) -> void:
	if toast_time > 0:
		toast_time -= seconds
		toast.modulate.a = clampf(toast_time * 2.5, 0, 1)
		if toast_time <= 0:
			toast.hide()

func _make_header() -> void:
	var badge := Palette.panel(game)
	Palette.pin(badge, 23, 23, 224, 62)
	_glyph(badge, "compass", Palette.GOLD, 12, 14, 32)
	Palette.pin(t.text(badge, "NO WAY HOME", 26, Palette.TEXT, true), 53, 5, 162, 31)
	Palette.pin(t.text(badge, "VALE DO CEDRO   /   ENTRADA 01", 13, Palette.MUTE, true), 54, 37, 163, 19)
	var compass_base := Palette.panel(game, Color("1b241de3"), Palette.EDGE)
	Palette.pin(compass_base, -79, 23, 158, 36, 0.5, 0)
	compass = t.text(compass_base, "", 20, Palette.GOLD, true)
	compass.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Palette.full(compass)
	camera_button = t.button(game, "", false, 14)
	Palette.pin(camera_button, -96, 68, 192, 30, 0.5, 0)
	camera_button.pressed.connect(func() -> void: camera_requested.emit())
	var esc := t.button(game, "PAUSA   ·   ESC", false, 14)
	Palette.pin(esc, 23, 93, 103, 29)
	esc.pressed.connect(func() -> void: pause_requested.emit())

func _make_diary() -> void:
	var base := Palette.panel(game)
	Palette.pin(base, -294, 23, 271, 293, 1, 0)
	Palette.block(base, Palette.GOLD, 15, 17, 5, 16)
	Palette.pin(t.text(base, "DIÁRIO DE CAMPO", 25, Palette.TEXT, true), 28, 9, 190, 32)
	Palette.pin(t.text(base, "01  /  PRIMEIRO REFÚGIO", 14, Palette.MUTE, true), 16, 45, 177, 21)
	diary_count = t.text(base, "", 16, Palette.GOLD, true)
	diary_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	Palette.pin(diary_count, 196, 43, 58, 24)
	var rule := Palette.block(base, Palette.SUBTLE, 16, 72, 238, 3)
	track = Palette.block(rule, Palette.GOLD, 0, 0, 0, 3)
	for i in range(JOURNAL_TEXT.size()):
		var y := 87 + i * 25
		checks.append(_glyph(base, "pin", Palette.GOLD, 16, y + 2, 17))
		var line := t.text(base, JOURNAL_TEXT[i], 17)
		Palette.pin(line, 41, y, 214, 22)
		objectives.append(line)
	Palette.block(base, Palette.SUBTLE, 16, 244, 238, 1)
	hint = t.text(base, "", 14, Palette.GOLD)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Palette.pin(hint, 16, 252, 238, 36)

func _make_vitals() -> void:
	var base := Palette.panel(game)
	Palette.pin(base, 23, -202, 233, 156, 0, 1)
	survivor_title = t.text(base, "", 20, Palette.TEXT, true)
	Palette.pin(survivor_title, 13, 6, 205, 26)
	Palette.block(base, Palette.SUBTLE, 13, 38, 207, 1)
	var rules := [["health", "Saúde", Palette.RED], ["food", "Fome", Palette.GOLD], ["water", "Sede", Palette.WATER], ["energy", "Energia", Palette.GREEN]]
	for i in range(rules.size()):
		var key: String = rules[i][0]
		var color: Color = rules[i][2]
		var y := 47 + i * 24
		_glyph(base, key, color, 13, y + 1, 17)
		Palette.pin(t.text(base, rules[i][1], 16, Palette.MUTE), 35, y, 58, 20)
		var rail := Palette.block(base, Palette.SUBTLE, 88, y + 9, 110, 4)
		var level := Palette.block(rail, color, 0, 0, 110, 4)
		var value := t.text(base, "", 15, Palette.TEXT, true)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		Palette.pin(value, 199, y, 22, 20)
		meters[key] = [level, value, color]
	var save_button := t.button(game, "SALVAR  ·  P", false, 14)
	Palette.pin(save_button, 23, -37, 233, 25, 0, 1)
	save_button.pressed.connect(func() -> void: save_requested.emit())

func _make_map(model: State, large: bool) -> void:
	var base := Palette.panel(self if large else game, Color("202821") if large else Palette.PANEL)
	if large:
		map_sheet = base
		Palette.pin(base, -307, -246, 614, 492, 0.5, 0.5)
		_glyph(base, "map", Palette.GOLD, 21, 18, 29)
		Palette.pin(t.text(base, "MAPA DO VALE", 32, Palette.TEXT, true), 60, 10, 308, 44)
		var close := t.button(base, "FECHAR  ·  M", false, 16)
		Palette.pin(close, 473, 16, 119, 36)
		close.pressed.connect(func() -> void: map_requested.emit())
		Palette.pin(t.text(base, "VOCÊ   /   ÁGUA   /   OBJETIVO   /   TRILHA", 17, Palette.MUTE, true), 23, 446, 565, 30)
	else:
		Palette.pin(base, -234, -208, 211, 196, 1, 1)
		_glyph(base, "map", Palette.GOLD, 10, 8, 20)
		Palette.pin(t.text(base, "MAPA DO VALE", 18, Palette.TEXT, true), 38, 5, 133, 25)
		var expand := t.button(base, "M", false, 15)
		Palette.pin(expand, 168, 6, 31, 24)
		expand.pressed.connect(func() -> void: map_requested.emit())
		coordinates = t.text(base, "", 14, Palette.FAINT, true)
		Palette.pin(coordinates, 11, 169, 185, 22)
	var clipping := Control.new()
	clipping.clip_contents = true
	clipping.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base.add_child(clipping)
	if large: Palette.pin(clipping, 22, 64, 570, 375)
	else: Palette.pin(clipping, 10, 37, 191, 129)
	var map := Cartography.new()
	map.catalog = model.catalog
	map.detailed = large
	map.face = t.strong
	map.radius = 38.5 if large else 22.0
	map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clipping.add_child(map)
	Palette.full(map)
	if large: large_map = map
	else: mini = map

func _make_belt() -> void:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.add_child(root)
	Palette.pin(root, -166, -108, 332, 102, 0.5, 1)
	var inventory_button := t.button(root, "MOCHILA   TAB", false, 14)
	Palette.pin(inventory_button, 109, 0, 115, 25)
	inventory_button.pressed.connect(func() -> void: inventory_requested.emit())
	for i in range(6):
		var slot := Slot.new()
		root.add_child(slot)
		Palette.pin(slot, i * 56, 31, 52, 49)
		slot.build(t, i)
		slot.pressed.connect(func() -> void: use_requested.emit(i))
		belt.append(slot)
	var help := t.text(root, "WASD MOVER   ·   SHIFT CORRER   ·   Q/R GIRAR   ·   RODA ZOOM", 13, Palette.TEXT, true)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.add_theme_color_override("font_shadow_color", Color("101510"))
	help.add_theme_constant_override("shadow_offset_y", 1)
	Palette.pin(help, -116, 80, 564, 22)

func _make_prompt() -> void:
	prompt = Palette.panel(game)
	Palette.pin(prompt, -161, -183, 322, 63, 0.5, 1)
	action = t.button(prompt, "", true, 17)
	Palette.pin(action, 7, 6, 308, 29)
	action.pressed.connect(func() -> void: interact_requested.emit())
	prompt_detail = t.text(prompt, "", 15, Palette.MUTE)
	prompt_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Palette.pin(prompt_detail, 7, 36, 308, 20)
	prompt.hide()

func _make_marker() -> void:
	goal_marker = Palette.panel(game, Color("20281de8"), Color("d8b17a"), 3)
	Palette.pin(goal_marker, 0, 0, 70, 23)
	_glyph(goal_marker, "pin", Palette.GOLD, 4, 3, 18)
	marker_distance = t.text(goal_marker, "", 14, Palette.TEXT, true)
	Palette.pin(marker_distance, 26, 1, 41, 20)
	goal_marker.hide()

func _make_toast() -> void:
	toast = Palette.panel(self, Color("182319f5"), Palette.EDGE)
	Palette.pin(toast, -241, 109, 482, 42, 0.5, 0)
	toast_mark = Palette.block(toast, Palette.GOLD, 9, 11, 3, 20)
	toast_label = t.text(toast, "", 17)
	Palette.pin(toast_label, 20, 6, 448, 29)
	toast.hide()

func _glyph(parent: Node, kind: String, color: Color, x: float, y: float, diameter: float) -> Glyph:
	var mark := Glyph.new()
	parent.add_child(mark)
	mark.setup(kind, color)
	Palette.pin(mark, x, y, diameter, diameter)
	return mark

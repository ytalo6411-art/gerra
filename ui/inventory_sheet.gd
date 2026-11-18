extends Control

signal use_requested(index: int)
signal closed

const Palette = preload("res://ui/palette.gd")
const Slot = preload("res://ui/slot_button.gd")
const State = preload("res://systems/world_state.gd")
const Glyph = preload("res://ui/glyph.gd")

var palette: Palette
var model: State
var slots: Array[Slot] = []
var selected := -1
var item_title: Label
var item_category: Label
var description: Label
var count_label: Label
var use_button: Button

func build(styles: Palette) -> void:
	palette = styles
	var sheet := Palette.panel(self, Color("202821"), Palette.EDGE, 7)
	Palette.pin(sheet, -300, -171, 600, 342, 0.5, 0.5)
	var icon := Glyph.new()
	sheet.add_child(icon)
	icon.setup("bag", Palette.GOLD)
	Palette.pin(icon, 24, 23, 31, 31)
	Palette.pin(palette.text(sheet, "MOCHILA", 32, Palette.TEXT, true), 65, 16, 300, 42)
	count_label = palette.text(sheet, "", 14, Palette.FAINT, true)
	Palette.pin(count_label, 66, 54, 270, 20)
	var close_button := palette.button(sheet, "FECHAR  ·  TAB", false, 15)
	Palette.pin(close_button, 457, 25, 118, 33)
	close_button.pressed.connect(func() -> void: closed.emit())
	Palette.block(sheet, Palette.EDGE, 24, 83, 551, 1)
	for i in range(6):
		var slot := Slot.new()
		sheet.add_child(slot)
		Palette.pin(slot, 24 + i * 93, 101, 85, 77)
		slot.build(palette, i)
		slot.pressed.connect(_select.bind(i))
		slots.append(slot)
	var summary := Palette.panel(sheet, Color("18211b"), Palette.SUBTLE)
	Palette.pin(summary, 24, 196, 551, 121)
	item_category = palette.text(summary, "", 14, Palette.GOLD, true)
	Palette.pin(item_category, 15, 9, 372, 19)
	item_title = palette.text(summary, "", 22, Palette.TEXT, true)
	Palette.pin(item_title, 15, 27, 382, 29)
	description = palette.text(summary, "", 16, Palette.MUTE)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Palette.pin(description, 15, 63, 398, 46)
	use_button = palette.button(summary, "USAR", true, 17)
	Palette.pin(use_button, 432, 36, 103, 42)
	use_button.pressed.connect(func() -> void: use_requested.emit(selected))

func receive(state: State, prefer_occupied: bool = false) -> void:
	model = state
	if prefer_occupied:
		selected = -1
		for i in range(6):
			if model.inventory.slots[i] != null:
				selected = i
				break
	_refresh()

func _select(index: int) -> void:
	selected = index
	_refresh()

func _refresh() -> void:
	if model == null:
		return
	var count := 0
	for i in range(6):
		var slot: Variant = model.inventory.slots[i]
		if slot != null:
			count += 1
		slots[i].display(slot, model.catalog.items, i == selected)
	count_label.text = "%02d / 06 ESPAÇOS OCUPADOS" % count
	var active: Variant = model.inventory.slots[selected] if selected >= 0 else null
	if active == null:
		item_category.text = "INVENTÁRIO DE CAMPO"
		item_title.text = "Mochila vazia" if count == 0 else "Espaço vazio"
		description.text = "Pegue água ou recursos no vale para preencher os espaços." if count == 0 else "Selecione um item para saber como usá-lo."
		use_button.visible = false
		return
	var item: Dictionary = model.catalog.items[active["id"]]
	item_category.text = String(item["category"]).to_upper() + "  /  ×%d" % int(active["n"])
	item_title.text = item["name"]
	description.text = item["description"]
	use_button.visible = item.has("effect")
	use_button.text = "BEBER" if item.get("effect") == "water" else "COMER"

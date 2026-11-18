extends Button

const Palette = preload("res://ui/palette.gd")
const Glyph = preload("res://ui/glyph.gd")

var item_glyph: Glyph
var quantity: Label
var key: Label
var occupied := false
var selected := false

func build(palette: Palette, index: int) -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	key = palette.text(self, str(index + 1), 13, Palette.FAINT, true)
	Palette.pin(key, 7, 3, 17, 16)
	item_glyph = Glyph.new()
	add_child(item_glyph)
	Palette.pin(item_glyph, -13, -12, 26, 26, 0.5, 0.5)
	quantity = palette.text(self, "", 13, Palette.GOLD, true)
	quantity.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	Palette.pin(quantity, -26, -17, 20, 15, 1.0, 1.0)
	_apply_style()

func display(slot: Variant, items: Dictionary, highlight: bool = false) -> void:
	occupied = slot != null
	selected = highlight
	item_glyph.visible = occupied
	quantity.visible = occupied
	if occupied:
		var item: Dictionary = items[slot["id"]]
		item_glyph.setup(item["icon"], Palette.WATER if slot["id"] == "water" else Palette.GOLD)
		quantity.text = str(int(slot["n"]))
		tooltip_text = item["name"]
	else:
		tooltip_text = "Espaço vazio"
	_apply_style()

func _apply_style() -> void:
	var color := Palette.GOLD if selected else (Color("67705a") if occupied else Palette.EDGE)
	add_theme_stylebox_override("normal", Palette.frame(Color("303b2beF") if occupied else Palette.PANEL, color, 4))
	add_theme_stylebox_override("hover", Palette.frame(Color("394331"), Palette.GOLD, 4))
	add_theme_stylebox_override("pressed", Palette.frame(Color("20281f"), Palette.GOLD, 4))

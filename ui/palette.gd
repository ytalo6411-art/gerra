extends RefCounted

const INK := Color("171e17")
const PANEL := Color("18201beF")
const PANEL_SOLID := Color("202821")
const EDGE := Color("50604e")
const SUBTLE := Color("343e32")
const TEXT := Color("f2efdf")
const MUTE := Color("b5bda9")
const FAINT := Color("9ba68f")
const GOLD := Color("e6bc7d")
const RED := Color("d48c78")
const GREEN := Color("a9b586")
const WATER := Color("88b3b5")

var strong: Font
var body: Font
var interface := Theme.new()

func _init() -> void:
	strong = _font("res://assets/fonts/BarlowCondensed-Bold.ttf")
	body = _font("res://assets/fonts/Barlow-Regular.ttf")
	interface.default_font = body
	interface.default_font_size = 16

static func _font(path: String) -> Font:
	# The regular exports use Godot imports; the source-format runner can read the font directly.
	if ResourceLoader.exists(path):
		var imported := load(path) as Font
		if imported != null:
			return imported
	var direct := FontFile.new()
	if direct.load_dynamic_font(path) == OK:
		return direct
	return ThemeDB.fallback_font

static func frame(fill: Color, edge: Color, radius: int = 4, border: int = 1) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = edge
	box.set_border_width_all(border)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 2
	box.content_margin_bottom = 2
	return box

func text(parent: Node, value: String, size: int = 16, color: Color = TEXT, compact: bool = false) -> Label:
	var label := Label.new()
	label.text = value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_override("font", strong if compact else body)
	label.add_theme_font_size_override("font_size", size)
	parent.add_child(label)
	return label

func button(parent: Node, title: String, primary: bool = false, size: int = 16) -> Button:
	var action := Button.new()
	action.text = title
	action.focus_mode = Control.FOCUS_NONE
	action.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	action.add_theme_font_override("font", strong)
	action.add_theme_font_size_override("font_size", size)
	style_button(action, primary)
	parent.add_child(action)
	return action

static func style_button(action: Button, primary: bool) -> void:
	var back := GOLD if primary else Color("263127f0")
	var color := INK if primary else TEXT
	action.add_theme_stylebox_override("normal", frame(back, GOLD if primary else EDGE))
	action.add_theme_stylebox_override("hover", frame(back.lightened(0.16), GOLD))
	action.add_theme_stylebox_override("pressed", frame(back.darkened(0.13), GOLD))
	action.add_theme_stylebox_override("disabled", frame(PANEL_SOLID, SUBTLE))
	action.add_theme_color_override("font_color", color)
	action.add_theme_color_override("font_hover_color", color)
	action.add_theme_color_override("font_pressed_color", color)
	action.add_theme_color_override("font_disabled_color", FAINT)

static func panel(parent: Node, fill: Color = PANEL, edge: Color = EDGE, radius: int = 5) -> Panel:
	var node := Panel.new()
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_theme_stylebox_override("panel", frame(fill, edge, radius, 0 if edge.a == 0.0 else 1))
	parent.add_child(node)
	return node

static func block(parent: Node, color: Color, x: float, y: float, w: float, h: float) -> ColorRect:
	var node := ColorRect.new()
	node.color = color
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	pin(node, x, y, w, h)
	return node

static func pin(node: Control, x: float, y: float, w: float, h: float, ax: float = 0, ay: float = 0) -> void:
	node.anchor_left = ax
	node.anchor_right = ax
	node.anchor_top = ay
	node.anchor_bottom = ay
	node.offset_left = x
	node.offset_top = y
	node.offset_right = x + w
	node.offset_bottom = y + h

static func full(node: Control) -> void:
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

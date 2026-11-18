extends Control
## Start, pause, recovery and control cards. Gameplay is paused by the session owner.

signal begin
signal resume
signal guide
signal back
signal save_requested
signal successor

const Palette = preload("res://ui/palette.gd")
const Glyph = preload("res://ui/glyph.gd")

var t: Palette
var title_screen: Control
var modal: Control
var start_button: Button
var status_line: Label
var headline: Label
var explanation: Label
var main_button: Button
var side_button: Button
var third_button: Button
var guide_rows: Control
var current := "title"
var device_tag: Label

func build(styles: Palette) -> void:
	t = styles
	_title()
	_modal()

func show_state(kind: String, has_save: bool, notice: String = "") -> void:
	current = kind
	title_screen.visible = kind == "title"
	modal.visible = kind in ["pause", "guide", "dead"]
	status_line.text = notice
	start_button.text = "CONTINUAR JORNADA  >" if has_save else "ENTRAR NA CLAREIRA  >"
	if modal.visible:
		guide_rows.visible = kind == "guide"
		explanation.visible = kind != "guide"
		side_button.visible = kind == "pause"
		third_button.visible = kind == "pause"
		match kind:
			"pause":
				headline.text = "No seu ritmo."
				explanation.text = "A simulação está pausada. Salve antes de encerrar ou volte para a clareira."
				main_button.text = "VOLTAR AO VALE"
				side_button.text = "CONTROLES"
				third_button.text = "SALVAR"
			"guide":
				headline.text = "Controles de campo"
				main_button.text = "VOLTAR"
			"dead":
				headline.text = "Uma jornada termina."
				explanation.text = "Este sobrevivente não retorna. Entre no mesmo vale com outro personagem. O que mudou na clareira permanece."
				main_button.text = "NOVO SOBREVIVENTE"
		device_tag.visible = kind != "guide"

func _title() -> void:
	title_screen = Control.new()
	add_child(title_screen)
	Palette.full(title_screen)
	title_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.28, 0.50, 0.76, 1.0])
	gradient.colors = PackedColorArray([Color("121a15fc"), Color("121a15f0"), Color("151d15a6"), Color("22281916"), Color("20291809")])
	var shade := GradientTexture2D.new()
	shade.gradient = gradient
	shade.width = 256
	shade.height = 8
	shade.fill_from = Vector2(0, 0)
	shade.fill_to = Vector2(1, 0)
	var tint := TextureRect.new()
	tint.texture = shade
	tint.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_screen.add_child(tint)
	Palette.full(tint)
	var emblem := Glyph.new()
	title_screen.add_child(emblem)
	emblem.setup("compass", Palette.GOLD)
	Palette.pin(emblem, 51, 42, 29, 29)
	Palette.pin(t.text(title_screen, "CADERNO DE CAMPO", 16, Palette.TEXT, true), 89, 42, 163, 28)
	Palette.block(title_screen, Color("8e947360"), 229, 55, 27, 1)
	Palette.pin(t.text(title_screen, "ENTRADA 01", 15, Palette.FAINT, true), 269, 42, 115, 28)
	Palette.block(title_screen, Palette.GOLD, 57, 126, 8, 8)
	Palette.pin(t.text(title_screen, "SEIS MESES DEPOIS", 17, Palette.GOLD, true), 77, 114, 280, 31)
	var title_one := t.text(title_screen, "NO WAY", 112, Palette.TEXT, true)
	var title_two := t.text(title_screen, "HOME", 134, Palette.TEXT, true)
	Palette.pin(title_one, 48, 132, 496, 128)
	Palette.pin(title_two, 47, 217, 486, 146)
	Palette.block(title_screen, Palette.GOLD, 56, 369, 48, 2)
	Palette.block(title_screen, Color("83907478"), 105, 369, 313, 1)
	Palette.pin(t.text(title_screen, "VALE DO CEDRO", 29, Palette.TEXT, true), 55, 387, 420, 37)
	var intro := t.text(title_screen, "A mata tomou de volta a estrada. Encontre água, prepare um abrigo e faça da clareira um lugar para ficar.", 20, Palette.MUTE)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Palette.pin(intro, 56, 435, 357, 80)
	start_button = t.button(title_screen, "ENTRAR NA CLAREIRA  >", true, 19)
	Palette.pin(start_button, 56, 529, 234, 49)
	start_button.pressed.connect(func() -> void: begin.emit())
	var how := t.button(title_screen, "CONTROLES", false, 17)
	Palette.pin(how, 302, 529, 119, 49)
	how.pressed.connect(func() -> void: guide.emit())
	status_line = t.text(title_screen, "", 15, Palette.GOLD)
	status_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Palette.pin(status_line, 56, 586, 380, 43)
	var footer := t.text(title_screen, "01  /  PROTÓTIPO DE SOBREVIVÊNCIA     •     JOGO OFFLINE", 14, Palette.FAINT, true)
	Palette.pin(footer, 56, -61, 450, 34, 0, 1)
	var plate := Palette.panel(title_screen, Color("202a21eb"), Color("bcc3a69a"))
	Palette.pin(plate, -277, 34, 244, 65, 1, 0)
	Palette.block(plate, Palette.GOLD, 13, 15, 3, 32)
	Palette.pin(t.text(plate, "POSTO FLORESTAL Nº 01", 20, Palette.TEXT, true), 25, 9, 206, 29)
	Palette.pin(t.text(plate, "SETOR DE TESTE  /  256 × 256 M", 14, Palette.MUTE, true), 26, 35, 203, 19)

func _modal() -> void:
	modal = Control.new()
	add_child(modal)
	Palette.full(modal)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	var veil := ColorRect.new()
	veil.color = Color("0e160fc8")
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modal.add_child(veil)
	Palette.full(veil)
	var sheet := Palette.panel(modal, Palette.PANEL_SOLID, Palette.EDGE, 8)
	Palette.pin(sheet, -293, -204, 586, 408, 0.5, 0.5)
	Palette.block(sheet, Palette.GOLD, 27, 28, 6, 6)
	Palette.pin(t.text(sheet, "POSTO DE CAMPO  /  VALE DO CEDRO", 16, Palette.GOLD, true), 44, 17, 420, 26)
	headline = t.text(sheet, "", 44, Palette.TEXT, true)
	Palette.pin(headline, 28, 52, 522, 63)
	explanation = t.text(sheet, "", 21, Palette.MUTE)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Palette.pin(explanation, 29, 132, 510, 89)
	device_tag = t.text(sheet, "SESSÃO LOCAL   /   O VALE NÃO AVANÇA FORA DO JOGO", 15, Palette.FAINT, true)
	Palette.pin(device_tag, 29, 270, 510, 22)
	guide_rows = Control.new()
	guide_rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet.add_child(guide_rows)
	Palette.pin(guide_rows, 29, 129, 528, 187)
	var descriptions := [
		["WASD / SETAS · SHIFT", "Caminhar · correr"], ["E  ·  1–6", "Interagir · usar item da barra"],
		["C  ·  Q / R  ·  RODA", "Trocar câmera · girar · aproximar"], ["TAB  ·  M", "Mochila · mapa do vale"],
		["P  ·  ESC", "Salvar · pausar ou fechar painel"]]
	for i in range(descriptions.size()):
		var y := i * 37
		Palette.pin(t.text(guide_rows, descriptions[i][0], 16, Palette.GOLD, true), 0, y, 186, 27)
		Palette.pin(t.text(guide_rows, descriptions[i][1], 17, Palette.TEXT), 203, y, 310, 27)
		Palette.block(guide_rows, Palette.SUBTLE, 0, y + 30, 528, 1)
	main_button = t.button(sheet, "VOLTAR AO VALE", true, 18)
	Palette.pin(main_button, 28, 333, 208, 47)
	main_button.pressed.connect(_main_action)
	side_button = t.button(sheet, "CONTROLES", false, 16)
	Palette.pin(side_button, 248, 333, 140, 47)
	side_button.pressed.connect(func() -> void: guide.emit())
	third_button = t.button(sheet, "SALVAR", false, 16)
	Palette.pin(third_button, 400, 333, 158, 47)
	third_button.pressed.connect(func() -> void: save_requested.emit())

func _main_action() -> void:
	match current:
		"pause": resume.emit()
		"guide": back.emit()
		"dead": successor.emit()

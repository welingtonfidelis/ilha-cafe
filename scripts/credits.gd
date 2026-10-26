class_name Credits
extends CanvasLayer
## Créditos do fim (seção 4 do doc, "Epílogo"): o álbum de fotos da partida, uma de cada vez como foto de
## polaroide com legenda, e depois os créditos de quem fez a arte subindo pela tela.
## Pular (A / Espaço / clique) passa para a próxima foto; Start / Esc encerra. Roda com o jogo pausado.

signal finished

const HOLD := 3.4
const SCROLL_TIME := 16.0
const LINES := [
	["Ilha Cafuné", 44, "#ffd23f"],
	["", 18, ""],
	["Personagens, esqueletos, cidade, mata, festa e cemitério", 20, "#d9a8ff"],
	["KayKit, de Kay Lousberg", 26, "#ffffff"],
	["", 12, ""],
	["Blasters", 20, "#d9a8ff"],
	["Kenney", 26, "#ffffff"],
	["", 12, ""],
	["Bichos e peixes", 20, "#d9a8ff"],
	["Quaternius", 26, "#ffffff"],
	["", 12, ""],
	["Sons e música", 20, "#d9a8ff"],
	["feitos por código, dentro do projeto", 24, "#ffffff"],
	["", 12, ""],
	["Feito com", 20, "#d9a8ff"],
	["Godot Engine", 26, "#ffffff"],
	["", 30, ""],
	["Obrigado por jogar!", 36, "#ffd23f"],
]

## Fotos do álbum ({legenda, imagem}); sem imagem (jogo sem tela), aparece um cartão só com a legenda.
var photos: Array = []
var fast := false

var _bg: ColorRect
var _title: Label
var _card: Control
var _photo: TextureRect
var _placeholder: ColorRect
var _caption: Label
var _scroll: VBoxContainer
var _next := false
var _skip := false


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bg = ColorRect.new()
	_bg.color = Color(0.05, 0.06, 0.14, 0.92)
	_bg.modulate.a = 0.0
	add_child(_bg)
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_title = Label.new()
	_title.text = "Álbum da Festa do Cafuné"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 34)
	_title.add_theme_color_override("font_color", Color("#ffd23f"))
	_title.add_theme_constant_override("outline_size", 10)
	_title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	_title.modulate.a = 0.0
	add_child(_title)
	_title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_title.offset_top = 28
	_title.offset_left = -400
	_title.offset_right = 400
	_build_card()
	_scroll = VBoxContainer.new()
	_scroll.alignment = BoxContainer.ALIGNMENT_CENTER
	_scroll.add_theme_constant_override("separation", 6)
	for line in LINES:
		var l := Label.new()
		l.text = line[0]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", line[1])
		if line[2] != "":
			l.add_theme_color_override("font_color", Color(line[2]))
		_scroll.add_child(l)
	_scroll.visible = false
	add_child(_scroll)
	_run()


## Polaroide: moldura clara, a foto e a legenda embaixo, um pouco torta.
func _build_card() -> void:
	var frame := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fdf8ec")
	style.set_corner_radius_all(6)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 18
	style.content_margin_bottom = 14
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 14
	frame.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	frame.add_child(box)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(720, 405)
	box.add_child(holder)
	_placeholder = ColorRect.new()
	_placeholder.color = Color("#b9d7ff")
	holder.add_child(_placeholder)
	_placeholder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_photo = TextureRect.new()
	_photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	holder.add_child(_photo)
	_photo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_caption = Label.new()
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.add_theme_font_size_override("font_size", 26)
	_caption.add_theme_color_override("font_color", Color("#3a2f45"))
	box.add_child(_caption)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_top = 40
	center.add_child(frame)
	_card = frame
	_card.modulate.a = 0.0


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu") or event.is_action_pressed("ui_cancel"):
		_skip = true
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pular") or event.is_action_pressed("ui_accept") or event.is_action_pressed("atirar"):
		_next = true
		get_viewport().set_input_as_handled()


func _speed() -> float:
	return 0.05 if fast else 1.0


func _hold(seconds: float) -> void:
	var t := 0.0
	_next = false
	while t < seconds * _speed() and not _next and not _skip:
		await get_tree().process_frame
		t += get_process_delta_time()


func _fade(node: CanvasItem, to: float, seconds: float) -> void:
	var tw := create_tween()
	tw.tween_property(node, "modulate:a", to, seconds * _speed())
	await tw.finished


func _run() -> void:
	await _fade(_bg, 1.0, 0.6)
	if not photos.is_empty():
		await _fade(_title, 1.0, 0.4)
	for p in photos:
		if _skip:
			break
		var image: Image = p.get("imagem")
		_photo.texture = ImageTexture.create_from_image(image) if image != null else null
		_placeholder.visible = image == null
		_caption.text = p.legenda
		_card.pivot_offset = _card.size * 0.5
		_card.rotation = deg_to_rad(randf_range(-2.5, 2.5))
		await _fade(_card, 1.0, 0.4)
		await _hold(HOLD)
		await _fade(_card, 0.0, 0.35)
	_title.visible = false
	if not _skip:
		var view := get_viewport().get_visible_rect().size
		_scroll.visible = true
		_scroll.size = Vector2(view.x, 0)
		_scroll.reset_size()
		_scroll.position = Vector2(0, view.y)
		var end_y := view.y * 0.5 - _scroll.size.y * 0.5
		var tw := create_tween()
		tw.tween_property(_scroll, "position:y", end_y, SCROLL_TIME * _speed())
		_next = false
		while tw.is_running() and not _next and not _skip:
			await get_tree().process_frame
		tw.kill()
		_scroll.position.y = end_y
		await _hold(2.5)
		await _fade(_scroll, 0.0, 0.4)
	await _fade(_bg, 0.0, 0.5)
	finished.emit()
	queue_free()

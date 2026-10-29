class_name CharacterMenu
extends CenterContainer
## Escolha de personagem (pedido do usuário em 2026-10-29: só com os nomes escritos, uma criança tinha
## dificuldade). Cada personagem ganha um cartão grande com o boneco 3D de verdade (Portrait) num fundo da cor
## dele, o nome embaixo e uma linha do que ele faz. O cartão marcado (direcional, setas ou o mouse em cima)
## cresce, ganha a borda dourada e o boneco dá tchau; quem já está jogando tem a etiqueta "Jogando agora". O
## Faísca só aparece com a Parte 2 aberta. O main.gd decide o que acontece (sinais `chosen` e `back_pressed`).

signal chosen(key: String)
signal back_pressed

## Chave, nome, o que faz e o ícone dessa linha (a miniatura de um blaster ou uma estrela).
const CARDS := [
	["menino", "Menino", "Blasters de doce", "res://assets/ui/loja/pacoca.png"],
	["menina", "Menina", "Blasters de doce", "res://assets/ui/loja/granulado.png"],
	["faisca", "Faísca", "Pula, voa e solta laser", "estrela"],
]
const CARD_SIZE := Vector2(236, 352)
const PHOTO_SIZE := Vector2(216, 240)

var game: Node
## Botão de cada cartão, pela chave (os testes do main.gd apertam por aqui).
var cards := {}
var back_button: Button
var hint: Label
var _portraits := {}
var _tags := {}


func build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", MenuKit.panel_style())
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	var title := Label.new()
	title.text = "Quem vai jogar?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", MenuKit.GOLD)
	box.add_child(title)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 22)
	box.add_child(row)
	for spec in CARDS:
		_card(row, spec[0], spec[1], spec[2], spec[3])
	# Respiro para o cartão marcado crescer sem encostar no Voltar.
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 6)
	box.add_child(gap)
	back_button = MenuKit.icon_button("Voltar", "voltar", game.ui_layer, 240)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.pressed.connect(func() -> void:
		Sfx.play(game.ui_layer, "ui_ok", 0.0, 0.0)
		back_pressed.emit())
	box.add_child(back_button)
	hint = Label.new()
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	box.add_child(hint)


## Abre marcando quem está jogando (`current`, vazio no começo do jogo: marca o menino, sem etiqueta).
func open(current: String, with_faisca: bool, can_go_back: bool) -> void:
	cards.faisca.visible = with_faisca
	back_button.visible = can_go_back
	for k in _tags:
		_tags[k].visible = k == current
	var target: Button = cards.get(current, cards.menino)
	if not target.visible:
		target = cards.menino
	_link_focus(target)
	target.grab_focus.call_deferred()


## Vizinhos fixos para o direcional: os lados só andam entre os cartões (sem cair no Voltar, que fica no meio,
## embaixo) e as pontas não dão a volta; para baixo vai ao Voltar e de lá para cima volta ao cartão de antes.
func _link_focus(first: Button) -> void:
	var shown: Array[Button] = []
	for spec in CARDS:
		if cards[spec[0]].visible:
			shown.append(cards[spec[0]])
	for i in shown.size():
		var b := shown[i]
		b.focus_neighbor_left = b.get_path_to(shown[maxi(i - 1, 0)])
		b.focus_neighbor_right = b.get_path_to(shown[mini(i + 1, shown.size() - 1)])
		b.focus_neighbor_top = b.get_path_to(b)
		b.focus_neighbor_bottom = b.get_path_to(back_button) if back_button.visible else b.get_path_to(b)
	back_button.focus_neighbor_top = back_button.get_path_to(first)
	back_button.focus_neighbor_bottom = back_button.get_path_to(back_button)


## O cartão entra na fileira antes de montar: o retrato precisa estar na árvore para mostrar o boneco.
func _card(row: HBoxContainer, key: String, label: String, line: String, icon: String) -> void:
	var color: Color = Portrait.BACKGROUNDS[key]
	var b := Button.new()
	b.name = key
	row.add_child(b)
	b.custom_minimum_size = CARD_SIZE
	var normal := MenuKit.box(MenuKit.CARD, 22, color.darkened(0.15), 3)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("hover_pressed", normal)
	b.add_theme_stylebox_override("pressed", MenuKit.box(MenuKit.BUTTON_PRESSED, 22, color, 3))
	b.add_theme_stylebox_override("focus", MenuKit.focus_style(24, 6))
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 6)
	b.add_child(box)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	# Foto com os cantos redondos: o painel recorta o retrato no formato dele.
	var frame := Panel.new()
	frame.custom_minimum_size = PHOTO_SIZE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	frame.add_theme_stylebox_override("panel", MenuKit.box(color, 16))
	box.add_child(frame)
	var portrait := Portrait.new(PHOTO_SIZE)
	frame.add_child(portrait)
	portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait.show_character(key)
	_portraits[key] = portrait
	var tag := _tag("Jogando agora")
	frame.add_child(tag)
	tag.position = Vector2(8, 8)
	_tags[key] = tag
	var name_label := Label.new()
	name_label.text = label
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 30)
	box.add_child(name_label)
	var line_row := HBoxContainer.new()
	line_row.alignment = BoxContainer.ALIGNMENT_CENTER
	line_row.add_theme_constant_override("separation", 6)
	line_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(line_row)
	if icon == "estrela":
		line_row.add_child(MenuIcon.new("estrela", Color.WHITE, 22))
	else:
		var pic := TextureRect.new()
		pic.texture = load(icon)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.custom_minimum_size = Vector2(38, 24)
		line_row.add_child(pic)
	var what := Label.new()
	what.text = line
	what.add_theme_font_size_override("font_size", 15)
	what.add_theme_color_override("font_color", Color(1, 1, 1, 0.65))
	line_row.add_child(what)
	b.resized.connect(func() -> void: b.pivot_offset = b.size * 0.5)
	b.focus_entered.connect(func() -> void:
		Sfx.play(game.ui_layer, "ui_mover", 0.0, 0.0)
		back_button.focus_neighbor_top = back_button.get_path_to(b)
		portrait.cheer(true)
		b.create_tween().tween_property(b, "scale", Vector2.ONE * 1.06, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
	b.focus_exited.connect(func() -> void:
		portrait.cheer(false)
		b.create_tween().tween_property(b, "scale", Vector2.ONE, 0.1))
	MenuKit.focus_on_mouse_move(b)
	b.pressed.connect(func() -> void: chosen.emit(key))
	cards[key] = b


## Etiqueta verde no canto da foto.
func _tag(text: String) -> PanelContainer:
	var tag := PanelContainer.new()
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s := MenuKit.box(Color("#c9f7a0"), 10)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 2
	s.content_margin_bottom = 2
	tag.add_theme_stylebox_override("panel", s)
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", Color("#1f3a12"))
	tag.add_child(l)
	return tag

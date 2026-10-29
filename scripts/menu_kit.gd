class_name MenuKit
extends RefCounted
## Visual dos menus do main.gd (início, confirmação, pausa, escolha de personagem e comandos), pedido do
## usuário em 2026-10-29: a mesma tela escura e opaca da lojinha do celular (as faixas do jogo não aparecem
## mais por trás das letras), com borda dourada, e botões grandes com um ícone colorido à esquerda. Passar o
## mouse por cima marca o botão, igual ao direcional do controle.

const GOLD := Color("#ffd23f")
const SCREEN := Color(0.11, 0.11, 0.16, 0.97)
const CARD := Color("#1d1d29")
const BUTTON := Color("#262635")
const BUTTON_HOVER := Color("#30304a")
const BUTTON_PRESSED := Color("#3b3b58")
## Cor da bolinha de cada ícone.
const ICON_COLORS := {
	"continuar": Color("#3fbf63"),
	"casa": Color("#3d8fe0"),
	"trocar": Color("#a05be0"),
	"comandos": Color("#1fa8a0"),
	"nova": Color("#f08a24"),
	"sair": Color("#e0504f"),
	"voltar": Color("#6a7390"),
	"objetivo": Color("#8a5cd6"),
}


static func panel_style() -> StyleBoxFlat:
	var s := box(SCREEN, 24, Color(GOLD, 0.6), 3)
	s.set_content_margin_all(26)
	s.content_margin_top = 16
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 16
	return s


static func box(color: Color, radius := 14, border := Color.TRANSPARENT, border_width := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	if border_width > 0:
		s.border_color = border
		s.set_border_width_all(border_width)
	s.anti_aliasing = true
	return s


## Borda dourada grossa de quem está marcado.
static func focus_style(radius := 16, width := 5) -> StyleBoxFlat:
	var s := box(Color.TRANSPARENT, radius, GOLD, width)
	s.draw_center = false
	s.set_expand_margin_all(4)
	return s


## Botão grande com o ícone colorido à esquerda e o texto logo depois.
static func icon_button(text: String, icon: String, sfx_parent: Node, width := 340.0) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(width, 56)
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	b.add_theme_color_override("font_focus_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	for state in [["normal", BUTTON], ["hover", BUTTON_HOVER], ["pressed", BUTTON_PRESSED]]:
		var s := box(state[1], 16)
		s.content_margin_left = 64
		s.content_margin_right = 16
		b.add_theme_stylebox_override(state[0], s)
	b.add_theme_stylebox_override("focus", focus_style())
	var ic := MenuIcon.new(icon, ICON_COLORS.get(icon, Color.GRAY), 40)
	b.add_child(ic)
	ic.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	ic.offset_left = 12
	ic.offset_right = 52
	ic.offset_top = -20
	ic.offset_bottom = 20
	b.focus_entered.connect(func() -> void: Sfx.play(sfx_parent, "ui_mover", 0.0, 0.0))
	focus_on_mouse_move(b)
	return b


## O mouse andando por cima marca o botão. Só com movimento de verdade (o mesmo limite do Player.detect_device):
## o menu que abre embaixo do cursor parado, de quem joga de controle, não perde o botão marcado.
static func focus_on_mouse_move(b: Control) -> void:
	b.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseMotion and ev.relative.length() > 2.0 and not b.has_focus():
			b.grab_focus())

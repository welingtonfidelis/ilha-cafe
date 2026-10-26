class_name WeaponHud
extends Control
## Painel das armas no canto de baixo à direita, inspirado em HUD de jogo de tiro:
## - painel grande inclinado com a arma na mão: número do encaixe, ícone de balas, pente (grande,
##   laranja) sobre o estoque (cinza) e a silhueta branca da arma;
## - painel menor em cima com a próxima arma (a que vem ao apertar Y ou a rodinha), se houver;
## - painel à esquerda com as granadas Brigadeiro.
## Desenhado em "unidades de projeto" (tela de 1280 x 720) e ampliado conforme a altura da janela.
## As silhuetas vêm de tools/gerar_icones.gd.

const ICONS := "res://assets/ui/icones/%s.png"
const MARGIN := 22.0
const SLANT := 0.32  # inclinação dos lados: x por y
const FILL := Color(0.05, 0.06, 0.08, 0.62)
const EDGE := Color(1, 1, 1, 0.32)
const TEXT := Color(0.94, 0.95, 0.97)
const GREY := Color(0.78, 0.8, 0.84)
const ORANGE := Color("#ffb36b")
const LOW := Color("#ffd23f")
const EMPTY := Color("#ff6b6b")
const RELOAD := Color("#9fdcff")

var _font: FontVariation
var _icons := {}
var _state := {}
var _last_weapon := -1
var _last_mag := -1
## 1 logo depois de trocar de arma, caindo até 0 (o conteúdo desliza e acende).
var _switch := 0.0
## 1 a cada tiro, caindo até 0 (o número do pente dá um pulinho).
var _pulse := 0.0


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	_font = FontVariation.new()
	_font.base_font = ThemeDB.fallback_font
	_font.variation_embolden = 0.6
	for def in Weapons.DEFS:
		_icons[def.id] = load(ICONS % def.id)
	_icons["granada"] = load(ICONS % "granada")


## Lê o estado do aventureiro; só redesenha quando algo mudou ou há animação.
func refresh(p: Player) -> void:
	var i := p.weapon_index
	var n := p.next_weapon_index(1)
	var next_id: String = Weapons.get_def(n).id
	var s := {
		"i": i, "mag": p.mag(), "reserve": p.reserve(),
		"n": n, "next_mag": p.ammo[next_id].mag, "next_reserve": p.ammo[next_id].reserve,
		"grenades": p.grenades, "reload": snappedf(p.reload_progress(), 0.01),
	}
	if i != _last_weapon:
		if _last_weapon != -1:
			_switch = 1.0
		_last_weapon = i
	elif s.mag < _last_mag:
		_pulse = 1.0
	_last_mag = s.mag
	if s != _state:
		_state = s
		queue_redraw()


func _process(delta: float) -> void:
	size = get_viewport_rect().size
	if _switch > 0.0 or _pulse > 0.0:
		_switch = move_toward(_switch, 0.0, delta * 4.0)
		_pulse = move_toward(_pulse, 0.0, delta * 6.0)
		queue_redraw()


# --- desenho -----------------------------------------------------------------

## Paralelogramo inclinado para a direita: lados esquerdo e direito em "/".
func _slanted(x: float, y: float, w: float, h: float) -> PackedVector2Array:
	var s := h * SLANT
	return PackedVector2Array([Vector2(x + s, y), Vector2(x + w, y), Vector2(x + w - s, y + h), Vector2(x, y + h)])


func _panel(x: float, y: float, w: float, h: float, alpha := 1.0) -> void:
	var pts := _slanted(x, y, w, h)
	draw_colored_polygon(pts, Color(FILL, FILL.a * alpha))
	var outline := pts.duplicate()
	outline.append(pts[0])
	draw_polyline(outline, Color(EDGE, EDGE.a * alpha), 1.5, true)


## Divisória inclinada dentro de um painel, na mesma inclinação dos lados.
func _divider(x: float, y: float, h: float, alpha := 1.0) -> void:
	draw_line(Vector2(x + h * SLANT, y + 4), Vector2(x, y + h - 4), Color(EDGE, EDGE.a * alpha), 1.5, true)


## Etiqueta pequena inclinada com o número do encaixe.
func _slot_tag(x: float, y: float, label: String, alpha := 1.0) -> void:
	var pts := _slanted(x, y, 30, 20)
	var outline := pts.duplicate()
	outline.append(pts[0])
	draw_polyline(outline, Color(1, 1, 1, 0.5 * alpha), 1.2, true)
	_text(Vector2(x + 9, y + 16), label, 14, Color(1, 1, 1, 0.8 * alpha))


## Duas balinhas em pé.
func _bullets(center: Vector2, h: float, alpha := 1.0) -> void:
	var color := Color(0.85, 0.87, 0.9, 0.9 * alpha)
	var w := h * 0.28
	for k in 2:
		var cx := center.x + (k - 0.5) * w * 1.5
		var body := Rect2(cx - w / 2.0, center.y - h * 0.15, w, h * 0.65)
		draw_rect(body, color, true)
		draw_circle(Vector2(cx, center.y - h * 0.15), w / 2.0, color)
		draw_rect(Rect2(cx - w / 2.0, center.y + h * 0.42, w, h * 0.08), color, true)


func _text(pos: Vector2, s: String, font_size: int, color: Color) -> void:
	draw_string(_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _text_width(s: String, font_size: int) -> float:
	return _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x


## Silhueta da arma encaixada numa área, mantendo a proporção, alinhada à direita.
func _icon(id: String, area: Rect2, alpha: float) -> void:
	var tex: Texture2D = _icons.get(id)
	if tex == null:
		return
	var ts := tex.get_size()
	var k := minf(area.size.x / ts.x, area.size.y / ts.y)
	var draw_size := ts * k
	var pos := Vector2(area.end.x - draw_size.x, area.position.y + (area.size.y - draw_size.y) / 2.0)
	draw_texture_rect(tex, Rect2(pos, draw_size), false, Color(1, 1, 1, alpha))


func _mag_color(mag: int, pente: int) -> Color:
	if mag == 0:
		return EMPTY
	if mag <= int(ceil(pente * 0.25)):
		return LOW
	return ORANGE


func _reserve_text(reserve: int) -> String:
	return "∞" if reserve < 0 else str(reserve)


func _draw() -> void:
	if _state.is_empty():
		return
	var u := clampf(size.y / 720.0, 0.75, 2.5)
	# Origem no canto de baixo à direita; desenha para a esquerda e para cima (coordenadas negativas).
	draw_set_transform(Vector2(size.x - MARGIN * u, size.y - MARGIN * u), 0.0, Vector2(u, u))
	_draw_main()
	if _state.n != _state.i:
		_draw_next()
	_draw_grenades()
	draw_set_transform(Vector2.ZERO)


func _draw_main() -> void:
	var def := Weapons.get_def(_state.i)
	var x := -400.0
	var y := -104.0
	var h := 104.0
	_panel(x, y, 400, h)
	_divider(x + 86, y, h)
	_bullets(Vector2(x + 52, y + 52), 44)
	var slide := 36.0 * _switch
	var glow := 1.0 - 0.6 * _switch
	_slot_tag(x + 128 + slide, y + 10, str(_state.i + 1), glow)
	var mag_size := int(round(42 * (1.0 + 0.12 * _pulse)))
	var mag_text := str(_state.mag)
	var mag_color := _mag_color(_state.mag, def.pente)
	var nx := x + 124 + slide
	_text(Vector2(nx, y + 62), mag_text, mag_size, Color(mag_color, glow))
	var reserve_text := _reserve_text(_state.reserve)
	var col_w := maxf(_text_width(mag_text, 42), _text_width(reserve_text, 30)) + 8
	draw_line(Vector2(nx - 4, y + 70), Vector2(nx + col_w, y + 70), Color(1, 1, 1, 0.35 * glow), 1.5)
	_text(Vector2(nx, y + 98), reserve_text, 30, Color(GREY, glow))
	var reloading: bool = _state.reload >= 0.0
	var icon_area := Rect2(x + 205 + slide, y + 14, 160, h - 28)
	_icon(def.id, icon_area, (0.3 if reloading else 0.95) * glow)
	if reloading:
		var bar_x := x + 100.0
		var bar_w := 400.0 - 100.0 - h * SLANT - 10.0
		draw_rect(Rect2(bar_x, y + h - 9, bar_w, 4), Color(1, 1, 1, 0.18), true)
		draw_rect(Rect2(bar_x, y + h - 9, bar_w * _state.reload, 4), RELOAD, true)
		var label := "RECARREGANDO"
		var lw := _text_width(label, 16)
		_text(Vector2(icon_area.get_center().x - lw / 2.0, icon_area.get_center().y + 6), label, 16, RELOAD)


func _draw_next() -> void:
	var def := Weapons.get_def(_state.n)
	var x := -282.0
	var y := -104.0 - 10.0 - 62.0
	var h := 62.0
	var alpha := 0.8
	_panel(x, y, 270, h, alpha)
	_divider(x + 58, y, h, alpha)
	_bullets(Vector2(x + 36, y + 31), 26, alpha)
	_slot_tag(x + 84, y + 7, str(_state.n + 1), alpha)
	var mag_text := str(_state.next_mag)
	var nx := x + 92.0
	_text(Vector2(nx + 32, y + 26), mag_text, 22, Color(TEXT, alpha))
	var reserve_text := _reserve_text(_state.next_reserve)
	var col_w := maxf(_text_width(mag_text, 22), _text_width(reserve_text, 18)) + 6
	draw_line(Vector2(nx + 30, y + 33), Vector2(nx + 32 + col_w, y + 33), Color(1, 1, 1, 0.3 * alpha), 1.2)
	_text(Vector2(nx + 32, y + 54), reserve_text, 18, Color(GREY, alpha * 0.9))
	_icon(def.id, Rect2(x + 160, y + 10, 92, h - 20), 0.8 * alpha)


func _draw_grenades() -> void:
	var count: int = _state.grenades
	var alpha := 1.0 if count > 0 else 0.45
	var x := -400.0 - 12.0 - 120.0
	var y := -104.0
	var h := 104.0
	_panel(x, y, 120, h, alpha)
	_icon("granada", Rect2(x + 34, y + 18, 40, h - 36), 0.9 * alpha)
	_text(Vector2(x + 80, y + 92), str(count), 30, Color(ORANGE if count > 0 else GREY, alpha))

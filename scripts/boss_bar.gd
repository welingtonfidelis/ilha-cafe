class_name BossBar
extends Control
## Barra de vida do guardião no topo da tela, no mesmo estilo inclinado do painel de armas.
## O pedaço perdido fica branco um instante antes de sumir, para dar para ver o tamanho do golpe.

const WIDTH := 520.0
const HEIGHT := 18.0
const SLANT := 0.5

var boss: Boss
var _shown := 0.0
var _trail := 0.0
var _font: FontVariation


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	visible = false
	_font = FontVariation.new()
	_font.base_font = ThemeDB.fallback_font
	_font.variation_embolden = 0.7


func track(b: Boss) -> void:
	boss = b
	_shown = b.health / b.max_health
	_trail = _shown
	visible = true
	queue_redraw()


func release() -> void:
	boss = null
	visible = false


func _process(delta: float) -> void:
	if not visible:
		return
	var u := clampf(get_viewport_rect().size.y / 720.0, 0.75, 2.5)
	scale = Vector2(u, u)
	position = Vector2(get_viewport_rect().size.x * 0.5 - WIDTH * 0.5 * u, 30.0 * u)
	if is_instance_valid(boss):
		_shown = boss.health / boss.max_health
	_trail = move_toward(_trail, _shown, delta * 0.5) if _trail > _shown else _shown
	queue_redraw()


func _bar(x: float, w: float, color: Color) -> void:
	if w <= 0.0:
		return
	var s := HEIGHT * SLANT
	var pts := PackedVector2Array([Vector2(x + s, 0), Vector2(x + w + s, 0), Vector2(x + w, HEIGHT), Vector2(x, HEIGHT)])
	draw_colored_polygon(pts, color)


func _draw() -> void:
	var name_text := boss.display_name if is_instance_valid(boss) else ""
	var sub := boss.subtitle if is_instance_valid(boss) else ""
	draw_string_outline(_font, Vector2(4, -10), name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, 8, Color(0, 0, 0, 0.75))
	draw_string(_font, Vector2(4, -10), name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
	if sub != "":
		var nw := _font.get_string_size(name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
		draw_string_outline(ThemeDB.fallback_font, Vector2(14 + nw, -11), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 6, Color(0, 0, 0, 0.7))
		draw_string(ThemeDB.fallback_font, Vector2(14 + nw, -11), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.8))
	_bar(-3, WIDTH + 6, Color(0, 0, 0, 0.55))
	_bar(0, WIDTH * _trail, Color(1, 1, 1, 0.85))
	_bar(0, WIDTH * _shown, Color("#ff7a59"))

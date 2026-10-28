class_name ObjectiveMarker
extends Control
## Losango roxo que aponta o objetivo atual, com a distância em metros. Quando o ponto está fora da
## tela (ou atrás da câmera), o losango fica preso na borda, do lado certo. Some quando chega perto.

const MARGIN := 48.0
## Embaixo sobra espaço para o painel de armas não ficar por baixo do losango.
const BOTTOM := 205.0
const NEAR := 8.0

## Seta da entrega de balão da lojinha do celular: moeda dourada com "Entrega" no lugar do losango roxo.
var coin := false
var _font: FontVariation
var _pos := Vector2.ZERO
var _meters := 0
var _edge := false


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	visible = false
	_font = FontVariation.new()
	_font.base_font = ThemeDB.fallback_font
	_font.variation_embolden = 0.6


func update_marker(camera: Camera3D, target: Vector3, from: Vector3) -> void:
	if target == Vector3.INF or not is_instance_valid(camera) or from.distance_to(target) < NEAR:
		visible = false
		return
	visible = true
	var view := get_viewport_rect().size
	_meters = roundi(from.distance_to(target))
	var p := camera.unproject_position(target)
	var behind := camera.is_position_behind(target)
	var u := clampf(view.y / 720.0, 0.75, 2.5)
	var area := Rect2(Vector2(MARGIN, MARGIN), view - Vector2(MARGIN * 2.0, MARGIN + BOTTOM * u))
	if area.size.x < 10.0 or area.size.y < 10.0:
		# Janela minúscula (ou testes sem janela): usa a tela inteira.
		area = Rect2(Vector2.ZERO, view.max(Vector2.ONE))
	if behind:
		# Atrás da câmera a projeção sai espelhada: inverte e joga para a borda de baixo.
		p = view - p
		p.y = area.end.y
	var inside := not behind and area.has_point(p)
	_edge = not inside
	if not inside:
		var c := area.get_center()
		var d := p - c
		if d.length() < 1.0:
			d = Vector2.DOWN
		var kx := (area.size.x * 0.5) / maxf(absf(d.x), 0.001)
		var ky := (area.size.y * 0.5) / maxf(absf(d.y), 0.001)
		p = c + d * minf(kx, ky)
	_pos = p
	queue_redraw()


func _draw() -> void:
	var s := 14.0
	if coin:
		draw_circle(_pos, s, Color("#ffd23f"))
		draw_arc(_pos, s, 0.0, TAU, 32, Color.WHITE, 3.0, true)
		draw_arc(_pos, s * 0.55, 0.0, TAU, 24, Color("#c98a10"), 2.5, true)
		var label := "Entrega · %d m" % _meters
		var lw := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
		var lp := _pos + Vector2(-lw / 2.0, s + 22)
		draw_string_outline(_font, lp, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, 6, Color(0, 0, 0, 0.75))
		draw_string(_font, lp, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#ffe9a8"))
		return
	var pts := PackedVector2Array([_pos + Vector2(0, -s), _pos + Vector2(s, 0), _pos + Vector2(0, s), _pos + Vector2(-s, 0)])
	var outline := pts.duplicate()
	outline.append(pts[0])
	draw_colored_polygon(pts, Color(0.69, 0.42, 1.0, 0.95))
	draw_polyline(outline, Color.WHITE, 3.0, true)
	var text := "%d m" % _meters
	var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	var tp := _pos + Vector2(-w / 2.0, s + 22)
	draw_string_outline(_font, tp, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, 6, Color(0, 0, 0, 0.75))
	draw_string(_font, tp, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)

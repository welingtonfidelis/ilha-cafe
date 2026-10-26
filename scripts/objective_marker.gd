class_name ObjectiveMarker
extends Control
## Losango roxo que aponta o objetivo atual, com a distância em metros. Quando o ponto está fora da
## tela (ou atrás da câmera), o losango fica preso na borda, do lado certo. Some quando chega perto.

const MARGIN := 48.0
const NEAR := 8.0

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
	if behind:
		# Atrás da câmera a projeção sai espelhada: inverte e joga para a borda de baixo.
		p = view - p
		p.y = view.y - MARGIN
	var inside := not behind and p.x > MARGIN and p.x < view.x - MARGIN and p.y > MARGIN and p.y < view.y - MARGIN
	_edge = not inside
	if not inside:
		var c := view * 0.5
		var d := p - c
		if d.length() < 1.0:
			d = Vector2.DOWN
		var kx := (c.x - MARGIN) / maxf(absf(d.x), 0.001)
		var ky := (c.y - MARGIN) / maxf(absf(d.y), 0.001)
		p = c + d * minf(kx, ky)
	_pos = p
	queue_redraw()


func _draw() -> void:
	var s := 14.0
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

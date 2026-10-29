class_name MenuIcon
extends Control
## Ícone redondo dos botões de menu (pedido do usuário em 2026-10-29: a pausa só com texto era difícil para
## criança): uma bolinha colorida com um desenho branco no meio, feito por código. Cada botão tem a sua cor,
## então dá para achar "o verde de continuar" sem ler.
##   continuar  triângulo de "play"          casa      volta para a ilha ou para o farol
##   trocar     duas setas girando           comandos  controle de videogame
##   nova       brilho de estrela            sair      símbolo de desligar
##   voltar     seta para a esquerda         objetivo  alvo
##   estrela    estrela amarela (sem bolinha)

var kind := "continuar"
var color := Color("#4cc76a")


func _init(icon_kind := "continuar", icon_color := Color("#4cc76a"), side := 40.0) -> void:
	kind = icon_kind
	color = icon_color
	custom_minimum_size = Vector2(side, side)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5
	# O desenho é feito numa caixa de 40 px e escalado para o tamanho do ícone.
	var k := r / 20.0
	if kind == "estrela":
		_star(c, r * 0.95, r * 0.42, Color("#ffd23f"))
		return
	draw_circle(c, r, color)
	draw_circle(c, r, color.lightened(0.35), false, 2.0 * k, true)
	var w := Color.WHITE
	match kind:
		"continuar":
			draw_colored_polygon(_pts(c, k, [Vector2(-5, -9), Vector2(10, 0), Vector2(-5, 9)]), w)
		"casa":
			draw_colored_polygon(_pts(c, k, [Vector2(-11, 0), Vector2(0, -10), Vector2(11, 0)]), w)
			draw_rect(Rect2(c + Vector2(-7.5, -1) * k, Vector2(15, 11) * k), w)
			draw_rect(Rect2(c + Vector2(-2.5, 3) * k, Vector2(5, 7) * k), color)
		"trocar":
			draw_arc(c, 9.0 * k, deg_to_rad(200), deg_to_rad(330), 12, w, 3.5 * k, true)
			draw_arc(c, 9.0 * k, deg_to_rad(20), deg_to_rad(150), 12, w, 3.5 * k, true)
			_arrow_head(c + Vector2.from_angle(deg_to_rad(330)) * 9.0 * k, deg_to_rad(330 + 90), k)
			_arrow_head(c + Vector2.from_angle(deg_to_rad(150)) * 9.0 * k, deg_to_rad(150 + 90), k)
		"comandos":
			draw_circle(c + Vector2(-7, 2) * k, 6.5 * k, w)
			draw_circle(c + Vector2(7, 2) * k, 6.5 * k, w)
			draw_rect(Rect2(c + Vector2(-7, -4.5) * k, Vector2(14, 10) * k), w)
			draw_rect(Rect2(c + Vector2(-10, 0.5) * k, Vector2(6, 2) * k), color)
			draw_rect(Rect2(c + Vector2(-8, -1.5) * k, Vector2(2, 6) * k), color)
			draw_circle(c + Vector2(6, 0) * k, 1.5 * k, color)
			draw_circle(c + Vector2(9, 3) * k, 1.5 * k, color)
		"nova":
			_sparkle(c + Vector2(-1.5, 1.5) * k, 11.0 * k, w)
			_sparkle(c + Vector2(8, -8) * k, 4.5 * k, w)
		"sair":
			draw_arc(c + Vector2(0, 1) * k, 9.0 * k, deg_to_rad(-55), deg_to_rad(235), 20, w, 3.5 * k, true)
			draw_line(c + Vector2(0, -11) * k, c + Vector2(0, -1) * k, w, 3.5 * k, true)
		"voltar":
			draw_colored_polygon(_pts(c, k, [Vector2(-11, 0), Vector2(-1, -9), Vector2(-1, -3.5), Vector2(10, -3.5),
					Vector2(10, 3.5), Vector2(-1, 3.5), Vector2(-1, 9)]), w)
		"objetivo":
			draw_circle(c, 11.0 * k, w)
			draw_circle(c, 7.5 * k, color)
			draw_circle(c, 4.0 * k, w)


func _pts(c: Vector2, k: float, pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p: Vector2 in pts:
		out.append(c + p * k)
	return out


func _arrow_head(tip: Vector2, angle: float, k: float) -> void:
	var fwd := Vector2.from_angle(angle)
	var side := fwd.orthogonal()
	draw_colored_polygon(PackedVector2Array([tip + fwd * 5.0 * k, tip - fwd * 1.5 * k + side * 5.0 * k,
			tip - fwd * 1.5 * k - side * 5.0 * k]), Color.WHITE)


## Brilho de quatro pontas (o "novo" da nova campanha).
func _sparkle(c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 8:
		var a := -PI / 2.0 + TAU * i / 8.0
		pts.append(c + Vector2.from_angle(a) * (r if i % 2 == 0 else r * 0.3))
	draw_colored_polygon(pts, col)


func _star(c: Vector2, outer: float, inner: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + TAU * i / 10.0
		pts.append(c + Vector2.from_angle(a) * (outer if i % 2 == 0 else inner))
	draw_colored_polygon(pts, col)
	draw_polyline(pts + PackedVector2Array([pts[0]]), col.darkened(0.35), 1.5, true)

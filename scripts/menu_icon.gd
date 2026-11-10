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
##   ajustes    engrenagem                   musica    nota musical
##   som        alto-falante                 camera    olho
##   inverter   setas para cima e para baixo vibracao  controle tremendo
##   binoculo   binóculo                     facil     coração com um "mais"
## Figuras dos objetivos (na seta do objetivo e na pausa; item 4 da lista de melhorias, 2026-11-10):
##   esqueleto  cabeça de esqueleto          ossao     esqueleto com escudo
##   mira_torta esqueleto com flecha         torre     três cabecinhas empilhadas
##   minionzao  cabeçona de sobrancelha brava  planta  folha
##   mestre     esqueleto de coroa           presente  caixa de presente com laço
##   lanterna   lanterna mágica              ponte     ponte de arco
##   cemiterio  lápide                       festa     três balões

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
		"ajustes":
			for i in 8:
				var a := TAU * i / 8.0
				var dente := PackedVector2Array()
				for p in [Vector2(-2.6, 7.0), Vector2(2.6, 7.0), Vector2(2.0, 12.0), Vector2(-2.0, 12.0)]:
					dente.append(c + p.rotated(a) * k)
				draw_colored_polygon(dente, w)
			draw_circle(c, 8.0 * k, w)
			draw_circle(c, 3.5 * k, color)
		"musica":
			draw_circle(c + Vector2(-6, 7) * k, 4.0 * k, w)
			draw_circle(c + Vector2(6, 4) * k, 4.0 * k, w)
			draw_line(c + Vector2(-2.5, 7) * k, c + Vector2(-2.5, -8) * k, w, 2.6 * k, true)
			draw_line(c + Vector2(9.5, 4) * k, c + Vector2(9.5, -11) * k, w, 2.6 * k, true)
			draw_colored_polygon(_pts(c, k, [Vector2(-3.8, -8), Vector2(10.8, -11), Vector2(10.8, -6.5), Vector2(-3.8, -3.5)]), w)
		"som":
			draw_colored_polygon(_pts(c, k, [Vector2(-11, -4), Vector2(-6, -4), Vector2(1, -10), Vector2(1, 10), Vector2(-6, 4), Vector2(-11, 4)]), w)
			draw_arc(c + Vector2(1, 0) * k, 5.5 * k, deg_to_rad(-50), deg_to_rad(50), 8, w, 2.4 * k, true)
			draw_arc(c + Vector2(1, 0) * k, 10.0 * k, deg_to_rad(-50), deg_to_rad(50), 10, w, 2.4 * k, true)
		"camera":
			var olho := PackedVector2Array()
			for i in 17:
				var t := float(i) / 16.0
				olho.append(c + Vector2(lerpf(-12, 12, t), -sin(t * PI) * 7.5) * k)
			for i in range(15, 0, -1):
				var t := float(i) / 16.0
				olho.append(c + Vector2(lerpf(-12, 12, t), sin(t * PI) * 7.5) * k)
			draw_colored_polygon(olho, w)
			draw_circle(c, 4.5 * k, color)
			draw_circle(c, 2.0 * k, w)
		"inverter":
			draw_line(c + Vector2(-4.5, 9) * k, c + Vector2(-4.5, -5) * k, w, 3.0 * k, true)
			draw_colored_polygon(_pts(c, k, [Vector2(-10, -4), Vector2(-4.5, -11), Vector2(1, -4)]), w)
			draw_line(c + Vector2(4.5, -9) * k, c + Vector2(4.5, 5) * k, w, 3.0 * k, true)
			draw_colored_polygon(_pts(c, k, [Vector2(-1, 4), Vector2(4.5, 11), Vector2(10, 4)]), w)
		"vibracao":
			draw_circle(c + Vector2(-4.5, 1.5) * k, 4.5 * k, w)
			draw_circle(c + Vector2(4.5, 1.5) * k, 4.5 * k, w)
			draw_rect(Rect2(c + Vector2(-4.5, -3) * k, Vector2(9, 8) * k), w)
			for lado in [-1.0, 1.0]:
				draw_polyline(_pts(c, k, [Vector2(11.5 * lado, -7), Vector2(13.5 * lado, -3.5), Vector2(11.5 * lado, 0),
						Vector2(13.5 * lado, 3.5), Vector2(11.5 * lado, 7)]), w, 1.8 * k, true)
		"facil":
			draw_circle(c + Vector2(-4, -3) * k, 5.0 * k, w)
			draw_circle(c + Vector2(4, -3) * k, 5.0 * k, w)
			draw_colored_polygon(_pts(c, k, [Vector2(-8.9, -1.6), Vector2(8.9, -1.6), Vector2(0, 10)]), w)
			draw_rect(Rect2(c + Vector2(-1.3, -6) * k, Vector2(2.6, 9) * k), color)
			draw_rect(Rect2(c + Vector2(-4.5, -2.8) * k, Vector2(9, 2.6) * k), color)
		"esqueleto":
			_cranio(c + Vector2(0, -1) * k, 9.0 * k, w)
		"ossao":
			_cranio(c + Vector2(-2.5, -2) * k, 8.0 * k, w)
			draw_colored_polygon(_pts(c, k, [Vector2(3, 2), Vector2(12, 2), Vector2(12, 7), Vector2(7.5, 12), Vector2(3, 7)]), Color("#ffd23f"))
		"mira_torta":
			_cranio(c + Vector2(-2, -1) * k, 8.0 * k, w)
			draw_line(c + Vector2(-11, 11) * k, c + Vector2(10, -10) * k, Color("#ffd23f"), 2.4 * k, true)
			_arrow_head(c + Vector2(10, -10) * k, -PI / 4.0, k)
		"torre":
			for i in 3:
				_cranio(c + Vector2(0, 8 - i * 7.5) * k, 4.2 * k, w)
		"minionzao":
			_cranio(c + Vector2(0, 0) * k, 10.0 * k, w)
			draw_line(c + Vector2(-8, -7) * k, c + Vector2(-2, -4) * k, color.darkened(0.4), 2.4 * k, true)
			draw_line(c + Vector2(8, -7) * k, c + Vector2(2, -4) * k, color.darkened(0.4), 2.4 * k, true)
		"planta":
			var folha := PackedVector2Array()
			for i in 13:
				var t := float(i) / 12.0
				folha.append(c + Vector2(lerpf(-11, 11, t), -sin(t * PI) * 7.0).rotated(-0.6) * k)
			for i in range(11, 0, -1):
				var t := float(i) / 12.0
				folha.append(c + Vector2(lerpf(-11, 11, t), sin(t * PI) * 7.0).rotated(-0.6) * k)
			draw_colored_polygon(folha, w)
			draw_line(c + Vector2(-11, 0).rotated(-0.6) * k, c + Vector2(11, 0).rotated(-0.6) * k, color, 1.6 * k, true)
		"mestre":
			_cranio(c + Vector2(0, 2) * k, 8.0 * k, w)
			draw_colored_polygon(_pts(c, k, [Vector2(-8, -5), Vector2(-8, -12), Vector2(-4, -8), Vector2(0, -13), Vector2(4, -8),
					Vector2(8, -12), Vector2(8, -5)]), Color("#ffd23f"))
		"presente":
			draw_rect(Rect2(c + Vector2(-9, -3) * k, Vector2(18, 13) * k), w)
			draw_rect(Rect2(c + Vector2(-10, -6) * k, Vector2(20, 4) * k), w)
			draw_rect(Rect2(c + Vector2(-1.6, -6) * k, Vector2(3.2, 16) * k), Color("#ffd23f"))
			draw_circle(c + Vector2(-3.5, -8.5) * k, 3.0 * k, Color("#ffd23f"))
			draw_circle(c + Vector2(3.5, -8.5) * k, 3.0 * k, Color("#ffd23f"))
		"lanterna":
			draw_arc(c + Vector2(0, -10) * k, 3.0 * k, PI, TAU, 10, w, 1.8 * k, true)
			draw_rect(Rect2(c + Vector2(-7, -8) * k, Vector2(14, 2.6) * k), w)
			draw_colored_polygon(_pts(c, k, [Vector2(-6, -5.5), Vector2(6, -5.5), Vector2(7.5, 6), Vector2(-7.5, 6)]), Color("#ffe6a0"))
			draw_circle(c + Vector2(0, 0.5) * k, 3.2 * k, Color("#ffd23f"))
			draw_rect(Rect2(c + Vector2(-8, 6) * k, Vector2(16, 3) * k), w)
		"ponte":
			draw_rect(Rect2(c + Vector2(-12, -3) * k, Vector2(24, 3) * k), w)
			draw_arc(c + Vector2(0, 9) * k, 9.0 * k, PI, TAU, 16, w, 3.0 * k, true)
			draw_rect(Rect2(c + Vector2(-12, -3) * k, Vector2(3, 12) * k), w)
			draw_rect(Rect2(c + Vector2(9, -3) * k, Vector2(3, 12) * k), w)
		"cemiterio":
			draw_circle(c + Vector2(0, -4) * k, 7.0 * k, w)
			draw_rect(Rect2(c + Vector2(-7, -4) * k, Vector2(14, 13) * k), w)
			draw_rect(Rect2(c + Vector2(-1.3, -8) * k, Vector2(2.6, 10) * k), color)
			draw_rect(Rect2(c + Vector2(-4.5, -5) * k, Vector2(9, 2.6) * k), color)
			draw_rect(Rect2(c + Vector2(-11, 9) * k, Vector2(22, 2.5) * k), w)
		"festa":
			for b in [[Vector2(-6, -3), Color("#ff6b8b")], [Vector2(6, -4), Color("#6bd1ff")], [Vector2(0, -8), Color("#ffe066")]]:
				draw_line(c + (b[0] + Vector2(0, 5.5)) * k, c + Vector2(0, 11) * k, w, 1.2 * k, true)
				draw_circle(c + b[0] * k, 5.0 * k, b[1])
				draw_arc(c + b[0] * k, 5.0 * k, 0, TAU, 16, w, 1.2 * k, true)
		"binoculo":
			draw_circle(c + Vector2(-5.5, 3) * k, 5.5 * k, w)
			draw_circle(c + Vector2(5.5, 3) * k, 5.5 * k, w)
			draw_rect(Rect2(c + Vector2(-9, -9) * k, Vector2(7, 10) * k), w)
			draw_rect(Rect2(c + Vector2(2, -9) * k, Vector2(7, 10) * k), w)
			draw_circle(c + Vector2(-5.5, 3) * k, 2.6 * k, color)
			draw_circle(c + Vector2(5.5, 3) * k, 2.6 * k, color)


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


## Cabeça de esqueleto: crânio branco, mandíbula, olhos e nariz na cor do fundo (parecem buracos) e dentinhos.
func _cranio(c: Vector2, r: float, w: Color) -> void:
	draw_circle(c, r, w)
	draw_rect(Rect2(c + Vector2(-r * 0.6, r * 0.5), Vector2(r * 1.2, r * 0.6)), w)
	draw_circle(c + Vector2(-r * 0.38, -r * 0.05), r * 0.28, color)
	draw_circle(c + Vector2(r * 0.38, -r * 0.05), r * 0.28, color)
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, r * 0.2), c + Vector2(-r * 0.12, r * 0.45), c + Vector2(r * 0.12, r * 0.45)]), color)
	for i in 3:
		var x := -r * 0.3 + i * r * 0.3
		draw_line(c + Vector2(x, r * 0.62), c + Vector2(x, r * 1.05), color, maxf(r * 0.08, 1.0), true)


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

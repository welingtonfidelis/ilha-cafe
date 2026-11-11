class_name Plantas3D
extends RefCounted
## As malhas da vegetação da ilha (pedido do usuário em 2026-11-11, com uma imagem de referência: "eu tinha imaginado
## algo mais abundante de vegetação"; não precisa ser realista). Cada uma é feita aqui, com poucos triângulos, para
## desenhar milhares de uma vez (MultiMesh):
## - o tufo de grama: doze folhas compridas e finas, abertas em leque e curvadas para fora;
## - os trevos: um tufinho de cinco trevos de três folhas redondas, rentes ao chão;
## - a florzinha: o caule, uma folhinha e a flor de cinco pétalas virada para cima;
## - a samambaia: sete folhas em arco, com o contorno recortado dos folíolos.
## Em todas, o UV.y vai de 0 no pé a 1 na ponta (o shader escurece o pé e clareia a ponta, e a ponta é o que o vento
## e o empurrão mexem); a normal aponta para cima, para a luz pegar igual ao chão. A cor vem de cada planta
## (MultiMesh), menos nas pétalas, marcadas com a cor do vértice de alfa 0 (a cor delas vem do custom_data).


static func tufo() -> ArrayMesh:
	var g := RandomNumberGenerator.new()
	g.seed = 11
	var st := _comecar()
	# Doze folhas compridas e finas num tufo de uns 50 cm, curvadas para fora (as de fora mais baixas e mais
	# deitadas), em três partes que afinam até a ponta: cheio, mas com folha de grama, não estrelinha de papel.
	for b in 12:
		var a := TAU * b / 12.0 + g.randf_range(-0.3, 0.3)
		var fora := Vector3(cos(a), 0, sin(a))
		var r := g.randf_range(0.0, 0.2)
		var pe := fora * r
		var altura := g.randf_range(0.38, 0.6) * (1.0 - r * 1.5)
		var largura := g.randf_range(0.03, 0.045)
		var curva := fora * g.randf_range(0.12, 0.22) * (1.0 + r * 2.5)
		var lado := Vector3(-fora.z, 0, fora.x).rotated(Vector3.UP, g.randf_range(-0.7, 0.7)) * largura
		var linhas: Array = []
		for f in [0.0, 0.4, 0.75]:
			var meio: Vector3 = pe + curva * f * f + Vector3.UP * altura * f
			linhas.append([meio - lado * (1.0 - f * 0.7), meio + lado * (1.0 - f * 0.7), f])
		var ponta := pe + curva + Vector3.UP * altura * 0.97
		for k in 2:
			var l0: Array = linhas[k]
			var l1: Array = linhas[k + 1]
			_tri(st, l0[0], l0[1], l1[1], l0[2], l0[2], l1[2])
			_tri(st, l0[0], l1[1], l1[0], l0[2], l1[2], l1[2])
		var l2: Array = linhas[2]
		_tri(st, l2[0], l2[1], ponta, l2[2], l2[2], 1.0)
	return st.commit()


static func trevos() -> ArrayMesh:
	var g := RandomNumberGenerator.new()
	g.seed = 12
	var st := _comecar()
	for c in 5:
		var a := g.randf() * TAU
		var centro := Vector3(cos(a), 0, sin(a)) * g.randf_range(0.0, 0.16)
		var alto := g.randf_range(0.05, 0.11)
		var giro := g.randf() * TAU
		for f in 3:
			var b := giro + TAU * f / 3.0
			var dir := Vector3(cos(b), 0, sin(b))
			var meio := centro + dir * 0.05 + Vector3.UP * alto
			# A folha redonda, um pouco erguida para fora, num leque de 7 pontas.
			var borda: Array[Vector3] = []
			for k in 7:
				var c2 := TAU * k / 7.0
				var p := Vector3(cos(c2), 0, sin(c2)) * 0.05
				p.y = p.dot(dir) * 0.35
				borda.append(meio + p)
			for k in 7:
				_tri(st, meio, borda[(k + 1) % 7], borda[k], 0.85, 0.75, 0.75)
	return st.commit()


static func florzinha() -> ArrayMesh:
	var st := _comecar()
	# Mais alta que o tufo de grama (até uns 60 cm), para a flor aparecer por cima do campo.
	var alto := 0.56
	var verde := Color(0.42, 0.68, 0.3)
	# O caule: duas fitas cruzadas.
	for giro in [0.0, PI / 2.0]:
		var lado := Vector3(cos(giro), 0, sin(giro)) * 0.008
		_quad(st, -lado, lado, lado + Vector3.UP * alto, -lado + Vector3.UP * alto, 0.0, 0.9, verde)
	# A folhinha do meio do caule.
	var f0 := Vector3(0, alto * 0.35, 0)
	_tri_cor(st, f0, f0 + Vector3(0.09, 0.05, 0.02), f0 + Vector3(0.05, 0.02, -0.03), 0.4, 0.6, 0.5, verde)
	# A flor: cinco pétalas (alfa 0: a cor vem de cada flor) em volta do miolo amarelo.
	var topo := Vector3(0, alto, 0)
	var branco := Color(1, 1, 1, 0)
	for p in 5:
		var a := TAU * p / 5.0
		var dir := Vector3(cos(a), 0, sin(a))
		var lado := Vector3(-dir.z, 0, dir.x)
		var meio := topo + dir * 0.055 + Vector3.UP * 0.008
		var ponta := topo + dir * 0.095 + Vector3.UP * 0.02
		_tri_cor(st, topo, meio + lado * 0.034, ponta, 1.0, 1.0, 1.0, branco)
		_tri_cor(st, topo, ponta, meio - lado * 0.034, 1.0, 1.0, 1.0, branco)
	var amarelo := Color(1.0, 0.8, 0.2)
	for k in 6:
		var a0 := TAU * k / 6.0
		var a1 := TAU * (k + 1) / 6.0
		_tri_cor(st, topo + Vector3.UP * 0.014, topo + Vector3(cos(a1), 0.6, sin(a1)) * 0.02, topo + Vector3(cos(a0), 0.6, sin(a0)) * 0.02,
				1.0, 1.0, 1.0, amarelo)
	return st.commit()


static func samambaia() -> ArrayMesh:
	var g := RandomNumberGenerator.new()
	g.seed = 14
	var st := _comecar()
	for b in 7:
		var a := TAU * b / 7.0 + g.randf_range(-0.25, 0.25)
		var fora := Vector3(cos(a), 0, sin(a))
		var lado := Vector3(-fora.z, 0, fora.x)
		var comprimento := g.randf_range(0.6, 0.85)
		var anterior: Array = []
		var n := 12
		for k in n + 1:
			var t := float(k) / n
			# Sobe e cai em arco; a largura recortada (os folíolos) afina até a ponta.
			var espinha := fora * comprimento * t + Vector3.UP * comprimento * 0.55 * sin(t * PI * 0.8)
			var largura := 0.1 * (1.0 - t) * (0.45 + 0.55 * absf(sin(t * PI * 7.0)))
			var par := [espinha - lado * largura, espinha + lado * largura, t]
			if not anterior.is_empty():
				_tri(st, anterior[0], anterior[1], par[1], anterior[2], anterior[2], t)
				_tri(st, anterior[0], par[1], par[0], anterior[2], t, t)
			anterior = par
	return st.commit()


# --- miúdos ---------------------------------------------------------------------------

static func _comecar() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, ta: float, tb: float, tc: float) -> void:
	_tri_cor(st, a, b, c, ta, tb, tc, Color.WHITE)


static func _tri_cor(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, ta: float, tb: float, tc: float, cor: Color) -> void:
	for par in [[a, ta], [b, tb], [c, tc]]:
		st.set_color(cor)
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(0.5, par[1]))
		st.add_vertex(par[0])


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, t0: float, t1: float, cor: Color) -> void:
	_tri_cor(st, a, b, c, t0, t0, t1, cor)
	_tri_cor(st, a, c, d, t0, t1, t1, cor)

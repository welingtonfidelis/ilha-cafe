class_name Fase31
extends Fase
## 3-1 Pico Gelado (Mundo 3, Frio e Vento; fase de céu). As Bolotas esconderam a sexta Estrela Grande no cume de um
## pico de gelo que flutua no céu, no meio de ilhas de neve. Novidades: o gelo que escorrega (azul clarinho e riscado;
## a neve branca é firme) e as bolas de neve grandes que rolam e empurram. Poder da fase: a Luva de Neve, pega no iglu
## grande da vila (cada golpe joga uma bola de neve que vai sozinha até o sino ou a Bolota mais perto na frente). Feita
## em 2026-10-30 a partir da maquete (docs/level-design/maquete-3-1-pico-gelado.html), pedido do usuário: "commita,
## push, manda pro pc e segue pra próxima". Cinco playgrounds em espiral em volta do pico, cada saída com uma tarefa.
##   1 Lago Congelado (y 0, ao sul): três botões no meio do lago de gelo levantam a ponte de neve até o trenó
##   viagem: o trenó dos pinguins
##   2 Ilhas de Gelo (y 7 a 14, a oeste): pontes estreitas de gelo; o laser derrete os três cubos dos pinguins
##     filhotes (um em cada ponta), e soltos eles desentopem o canhão de neve; V1 na beirada embaixo da ilha do meio (P1)
##   viagem: o canhão de neve
##   3 Vila do Iglu (y 18, a noroeste): a Luva de Neve no iglu grande; três sinos no alto de colunas de 12 m soltam a
##     cadeirinha; o quarto sino, atrás da chaminé, faz aparecer a escada de gelo até a pedra alta do V2; coração na
##     cabana de esqui (P2)
##   viagem: a cadeirinha de esqui (leva de volta também)
##   4 Encosta das Avalanches (y 22 a 31, de nordeste a leste do pico): três cachoeiras cortam o caminho, e o sino de
##     cada uma congela a água numa rampa de gelo; bolas de neve rolando; coração na caverna atrás da segunda (P3)
##   ponte de gelo até o anel do pico
##   5 Subida do Pico (y 30 a 46): monte de neve fofa, saliências de neve e pingentes lilases que caem, subindo pela
##     parede até a porta de gelo do cume, que abre com o último sino; V3 na gruta rachada do anel (P4)
##   Arena no cume (46 m): o baú e três Bolotas, dentro de um muro de gelo

const NEVE_PASTA := "res://assets/faisca/neve/"
const DOCES := "res://assets/faisca/doces/"
const NEVE := [Color("f4f8ff"), Color("c9dff2"), Color("9aa7bf")]
const PEDRA := [Color("b9c3d6"), Color("7d879e"), Color("8f99ae")]
## O marco: o pico de gelo. O pé (raio 26) vai até 30 m, e o anel em cima dele (de 18 a 26 m do meio) é o chão da
## Subida do Pico; o pico de cima vai de raio 18 (a 30 m) a raio 11 (no cume plano, a 46 m).
const RAIO_PE := 26.0
const TOPO_PE := 30.0
const RAIO_BASE_CIMA := 18.0
const RAIO_CUME := 11.0
const TOPO_CUME := 46.0
const LAGO := Vector3(0, 0, 110)
const VILA := Vector3(-70, 18, -78)
const RAIO_VILA := 32.0
## Onde o canhão de neve pousa o Faísca na vila.
const POUSO_CANHAO := Vector3(-78, 18.05, -52)

## A Luva de Neve já foi pega.
var luva_pega := false
var treno: Carona
var cadeirinha: Carona
var sinos_da_vila: Array[Sino] = []
var sino_da_escada: Sino
var degraus_de_gelo: Array[StaticBody3D] = []
var sinos_das_cachoeiras: Array[Sino] = []
var sino_da_porta: Sino
var porta_do_cume: StaticBody3D
var paredes_do_pico: Array[ParedeRachada] = []
## O monte de neve que entope o canhão até os três pinguins saírem do gelo.
var tampa_do_canhao: StaticBody3D
var _luva: Area3D
var _neve_caindo: CPUParticles3D


func _montar() -> void:
	nome = "3-1 Pico Gelado"
	inicio = Vector3(12, 0.1, 128)
	limite_queda = -10.0
	farol(Vector3(140, -16, -240), 2.0)
	_pico()
	_lago_congelado()
	_viagem_treno()
	_ilhas_de_gelo()
	_vila_do_iglu()
	_viagem_cadeirinha()
	_encosta_das_avalanches()
	_subida_do_pico()
	_arena()
	_nuvens_de_enfeite()
	_neve_do_ceu()


# --- peças da fase ------------------------------------------------------------------

## Ilha redonda com `topo` no meio de cima: a tampa de neve, a borda e o cone de pedra por baixo.
func ilha(topo: Vector3, raio: float, cores: Array, fundura := -1.0) -> StaticBody3D:
	var corpo := StaticBody3D.new()
	corpo.position = topo
	add_child(corpo)
	_malha(corpo, _cilindro(raio, raio * 0.97, 1.2), cores[0], Vector3(0, -0.6, 0))
	var toro := TorusMesh.new()
	toro.inner_radius = raio - 0.25
	toro.outer_radius = raio + 0.25
	toro.rings = 64
	_malha(corpo, toro, cores[1], Vector3(0, -0.08, 0))
	var h := maxf(raio * 0.75, 2.5) if fundura < 0.0 else fundura
	var cone := _cilindro(raio * 0.92, 0.0, h)
	_malha(corpo, cone, cores[2], Vector3(0, -1.2 - h * 0.5, 0))
	var cs := CollisionShape3D.new()
	var forma := CylinderShape3D.new()
	forma.radius = raio
	forma.height = 1.2
	cs.shape = forma
	cs.position.y = -0.6
	corpo.add_child(cs)
	var cs_cone := CollisionShape3D.new()
	cs_cone.shape = cone.create_convex_shape()
	cs_cone.position.y = -1.2 - h * 0.5
	corpo.add_child(cs_cone)
	return corpo


## Lago (ou laguinho) de gelo redondo em cima de uma ilha, com o topo 8 cm acima de `centro`.
func lago_de_gelo(centro: Vector3, raio: float) -> StaticBody3D:
	var corpo := StaticBody3D.new()
	corpo.position = centro + Vector3(0, -0.07, 0)
	Gelo.marcar(corpo)
	var mi := MeshInstance3D.new()
	mi.mesh = _cilindro(raio, raio, 0.3)
	mi.material_override = Gelo.material()
	corpo.add_child(mi)
	var cs := CollisionShape3D.new()
	var forma := CylinderShape3D.new()
	forma.radius = raio
	forma.height = 0.3
	cs.shape = forma
	corpo.add_child(cs)
	add_child(corpo)
	return corpo


## Bloco quadrado de neve (ou de gelo, que escorrega) com `topo` no meio de cima: a tampa, o miolo por baixo e
## pingentes de enfeite na frente.
func bloco_de_neve(topo: Vector3, largura: float, fundo: float, gelo := false) -> StaticBody3D:
	var corpo := StaticBody3D.new()
	corpo.position = topo
	add_child(corpo)
	if gelo:
		Gelo.marcar(corpo)
	var tampa := BoxMesh.new()
	tampa.size = Vector3(largura, 1.2, fundo)
	var mi := _malha(corpo, tampa, NEVE[0], Vector3(0, -0.6, 0))
	if gelo:
		mi.material_override = Gelo.material()
	var miolo := BoxMesh.new()
	miolo.size = Vector3(largura * 0.8, 3.0, fundo * 0.8)
	_malha(corpo, miolo, NEVE[2], Vector3(0, -2.7, 0))
	for spec in [[Vector3(largura, 1.2, fundo), Vector3(0, -0.6, 0)], [Vector3(largura * 0.8, 3.0, fundo * 0.8), Vector3(0, -2.7, 0)]]:
		var cs := CollisionShape3D.new()
		var forma := BoxShape3D.new()
		forma.size = spec[0]
		cs.shape = forma
		cs.position = spec[1]
		corpo.add_child(cs)
	for i in 3:
		var ponta := _cilindro(0.35, 0.0, 1.6)
		so_enfeite(_malha(corpo, ponta, Color("bfe6ff"), Vector3(-largura * 0.3 + i * largura * 0.3, -2.0, fundo * 0.42)))
	return corpo


## Ponte (ou rampa) de gelo de `de` até `ate`, os dois na altura do chão: escorrega como todo gelo.
func rampa_de_gelo(de: Vector3, ate: Vector3, largura := 2.4) -> StaticBody3D:
	var dir := (ate - de).normalized()
	var lado := Vector3.UP.cross(dir).normalized()
	var cima := dir.cross(lado).normalized()
	var comprimento := de.distance_to(ate)
	var corpo := StaticBody3D.new()
	Gelo.marcar(corpo)
	corpo.transform = Transform3D(Basis(lado, cima, dir), (de + ate) * 0.5 - cima * 0.25)
	var malha := BoxMesh.new()
	malha.size = Vector3(largura, 0.5, comprimento)
	var mi := MeshInstance3D.new()
	mi.mesh = malha
	mi.material_override = Gelo.material()
	corpo.add_child(mi)
	var cs := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = malha.size
	cs.shape = forma
	corpo.add_child(cs)
	add_child(corpo)
	return corpo


## Coluna de gelo com `topo` em cima (as colunas dos sinos e a pedra alta do V2).
func coluna(topo: Vector3, raio: float, altura: float, cor := Color(0, 0, 0, 0)) -> StaticBody3D:
	var corpo := StaticBody3D.new()
	corpo.position = topo
	add_child(corpo)
	var mi := _malha(corpo, _cilindro(raio, raio * 1.25, altura), cor, Vector3(0, -altura * 0.5, 0))
	if cor.a == 0.0:
		mi.material_override = Gelo.material()
	var cs := CollisionShape3D.new()
	var forma := CylinderShape3D.new()
	forma.radius = raio * 1.12
	forma.height = altura
	cs.shape = forma
	cs.position.y = -altura * 0.5
	corpo.add_child(cs)
	return corpo


## Iglu oco de raio `raio` com o meio do chão em `centro` e a porta virada para `frente` (o +Z do giro), com o
## tunelzinho de entrada. Dá para entrar: a cúpula é uma casca com colisão dos dois lados. Com `cores`, vira a
## caverna de pedra da Encosta.
func iglu(centro: Vector3, raio: float, frente: float, cor := Color("f4fbff")) -> StaticBody3D:
	var corpo := StaticBody3D.new()
	corpo.position = centro
	corpo.rotation.y = frente
	add_child(corpo)
	var aneis := 8
	var gomos := 36
	var d_teta := PI * 0.5 / aneis
	var d_fi := TAU / gomos
	var porta_aneis := ceili(asin(minf(2.8 / raio, 0.95)) / d_teta)
	var porta_meia := 1.4 / raio + 0.05
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ponto := func(teta: float, fi: float) -> Vector3:
		return Vector3(sin(fi) * cos(teta), sin(teta), cos(fi) * cos(teta)) * raio
	var meia_porta := 0.0
	for i in aneis:
		for k in gomos:
			var fi_meio := (k + 0.5) * d_fi
			var desvio := absf(wrapf(fi_meio, -PI, PI))
			if i < porta_aneis and desvio < porta_meia:
				meia_porta = maxf(meia_porta, desvio + d_fi * 0.5)
				continue
			var a: Vector3 = ponto.call(i * d_teta, k * d_fi)
			var b: Vector3 = ponto.call(i * d_teta, (k + 1) * d_fi)
			var c: Vector3 = ponto.call((i + 1) * d_teta, k * d_fi)
			var e: Vector3 = ponto.call((i + 1) * d_teta, (k + 1) * d_fi)
			for v: Vector3 in [a, c, e, a, e, b]:
				st.set_normal(v.normalized())
				st.add_vertex(v)
	var cupula := MeshInstance3D.new()
	cupula.mesh = st.commit()
	var m := _material(cor)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.95
	cupula.material_override = m
	corpo.add_child(cupula)
	var casca := ConcavePolygonShape3D.new()
	casca.set_faces(cupula.mesh.get_faces())
	casca.backface_collision = true
	var cs := CollisionShape3D.new()
	cs.shape = casca
	corpo.add_child(cs)
	# O tunelzinho: duas paredes e o teto, da porta para fora.
	var largura := raio * sin(meia_porta) * 2.0
	var alto := raio * sin(porta_aneis * d_teta) - 0.2
	var de_z := raio * cos(meia_porta) - 0.4
	var comprimento := 2.0
	var cor_tunel := cor.darkened(0.06)
	for lado in [-1.0, 1.0]:
		_parede(corpo, Vector3(0.5, alto, comprimento), Vector3(lado * (largura * 0.5 + 0.25), alto * 0.5, de_z + comprimento * 0.5), cor_tunel)
	_parede(corpo, Vector3(largura + 1.0, 0.5, comprimento), Vector3(0, alto + 0.25, de_z + comprimento * 0.5), cor_tunel)
	return corpo


## Caixa sólida dentro de `pai` (paredes do túnel, da gruta, da cabana).
func _parede(pai: Node3D, tamanho: Vector3, pos: Vector3, cor: Color) -> MeshInstance3D:
	var malha := BoxMesh.new()
	malha.size = tamanho
	var mi := _malha(pai, malha, cor, pos)
	var cs := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tamanho
	cs.shape = forma
	cs.position = pos
	pai.add_child(cs)
	return mi


## Peça do Holiday Bits da neve (bonecos de neve, pinheiros, lampiões, presentes), sólida no formato da malha.
func neve(arquivo: String, pos: Vector3, giro := 0.0, escala: Variant = 1.0, solida := true) -> Node3D:
	return peca_de(NEVE_PASTA, arquivo, pos, giro, escala, solida)


## Ponto em volta do pico: `graus` contados do leste (+X) para o norte (-Z), a `raio` m do meio, na altura `y`.
func no_pico(graus: float, raio: float, y: float) -> Vector3:
	var a := deg_to_rad(graus)
	return Vector3(raio * cos(a), y, -raio * sin(a))


## Raio da parede do pico de cima na altura `y` (ele afina de 18 m no anel até 11 m no cume).
func raio_do_pico(y: float) -> float:
	return lerpf(RAIO_BASE_CIMA, RAIO_CUME, clampf((y - TOPO_PE) / (TOPO_CUME - TOPO_PE), 0.0, 1.0))


func _cilindro(r_cima: float, r_baixo: float, altura: float) -> CylinderMesh:
	var cil := CylinderMesh.new()
	cil.top_radius = r_cima
	cil.bottom_radius = r_baixo
	cil.height = altura
	cil.radial_segments = 48
	return cil


func _malha(pai: Node3D, malha: Mesh, cor: Color, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = malha
	mi.material_override = _material(cor)
	mi.position = pos
	pai.add_child(mi)
	return mi


## Dica do Vovô fora de um ponto de dica (a da luva), uma vez só.
func _dica_uma_vez(qual: String) -> void:
	if not _dicas_dadas.has(qual):
		_dicas_dadas[qual] = true
		dica.emit(qual)


# --- o marco: o pico de gelo ---------------------------------------------------------

## O pé de pedra azulada com a tampa de neve (o anel), o pico de cima de gelo e neve até o cume, pingentes em volta da
## beira do anel e o cone de pedra por baixo.
func _pico() -> void:
	var corpo := StaticBody3D.new()
	add_child(corpo)
	var baixo := TOPO_PE + 10.0
	_malha(corpo, _cilindro(RAIO_PE, RAIO_PE - 1.5, baixo), Color("9aa7bf"), Vector3(0, TOPO_PE - baixo * 0.5, 0))
	_malha(corpo, _cilindro(RAIO_PE + 0.1, RAIO_PE + 0.1, 1.0), NEVE[0], Vector3(0, TOPO_PE - 0.5, 0))
	var alto := TOPO_CUME - TOPO_PE
	var cima := _cilindro(RAIO_CUME, RAIO_BASE_CIMA, alto)
	_malha(corpo, cima, Color("d9e6f5"), Vector3(0, TOPO_PE + alto * 0.5, 0))
	_malha(corpo, _cilindro(RAIO_CUME + 0.1, RAIO_CUME + 0.1, 0.6), NEVE[0], Vector3(0, TOPO_CUME - 0.3, 0))
	# Faixas de gelo na parede do pico de cima, para dar a cara de gelo.
	for y in [34.0, 39.5]:
		_malha(corpo, _cilindro(raio_do_pico(y + 0.6) + 0.12, raio_do_pico(y - 0.6) + 0.12, 1.2), Color("bfe6ff"), Vector3(0, y, 0))
	var cone := _cilindro(RAIO_PE - 1.5, 0.0, 26.0)
	_malha(corpo, cone, Color("a9d6f0"), Vector3(0, TOPO_PE - baixo - 13.0, 0))
	for spec in [[RAIO_PE, TOPO_PE - baixo, TOPO_PE]]:
		var cs := CollisionShape3D.new()
		var forma := CylinderShape3D.new()
		forma.radius = spec[0]
		forma.height = spec[2] - spec[1]
		cs.shape = forma
		cs.position.y = (spec[1] + spec[2]) * 0.5
		corpo.add_child(cs)
	var cs_cima := CollisionShape3D.new()
	cs_cima.shape = cima.create_convex_shape()
	cs_cima.position.y = TOPO_PE + alto * 0.5
	corpo.add_child(cs_cima)
	var cs_cone := CollisionShape3D.new()
	cs_cone.shape = cone.create_convex_shape()
	cs_cone.position.y = TOPO_PE - baixo - 13.0
	corpo.add_child(cs_cone)
	# Pingentes em volta da beira do anel, pendurados na parede (embaixo da beira, ninguém pisa).
	for i in 30:
		var a := TAU * i / 30.0
		var ponta := _cilindro(0.6, 0.0, 2.4 + (i % 3))
		so_enfeite(_malha(corpo, ponta, Color("bfe6ff"), Vector3(cos(a) * (RAIO_PE - 0.2), TOPO_PE - 1.6 - (i % 3) * 0.5, sin(a) * (RAIO_PE - 0.2))))


# --- 1 · Lago Congelado ---------------------------------------------------------------

## Playground 1 · Lago Congelado (apresenta): a ilha grande de neve firme com o lago de gelo no meio, sem risco. O Vovô
## mostra o gelo logo na chegada. A saída é a ponte de blocos de neve até o trenó, que só sobe com os três botões
## apertados, todos no meio do lago (escorregando até eles). Mini-marco: o boneco de neve gigante. Bolsos: o iglu
## pequeno, com estrelinhas dentro, e o monte do coração, subindo pela pilha de bolas de neve.
func _lago_congelado() -> void:
	playground("1 · Lago Congelado", LAGO, 32.0, inicio)
	ilha(LAGO, 32.0, NEVE, 14.0)
	lago_de_gelo(LAGO, 14.0)
	trilha_creme([Vector3(12, 0, 127), Vector3(19, 0, 116), Vector3(18, 0, 100), Vector3(8, 0, 91), Vector3(-6, 0, 89), Vector3(-18, 0, 92.5), Vector3(-27, 0, 95.5)])
	trilha(Vector3(15, 1.0, 118), Vector3(18, 1.0, 104), 4)
	trilha(Vector3(12, 1.0, 93), Vector3(-14, 1.0, 90), 5)
	ponto_de_dica(Vector3(14, 0.5, 117), 3.5, "gelo")
	bolota(Vector3(-12, 0, 126), true, "pinguim")
	bolota(Vector3(12, 0, 88.5), false, "cogumelo")

	# Os três botões no meio do lago, uma estrelinha em cima de cada. Ficam afundados no gelo (só a tampa aparece),
	# para dar para apertar escorregando por cima: em pé no gelo, a base de 26 cm era um degrau que segurava o Faísca.
	ponto_de_dica(Vector3(-4, 0.5, 96), 3.0, "botao")
	for spec in [[Vector3(-6, -0.14, 104), "red"], [Vector3(5, -0.14, 101), "yellow"], [Vector3(-3, -0.14, 116), "blue"]]:
		botao(spec[0], spec[1])
		estrelinha(spec[0] + Vector3(0, 2.2, 0))
	roda(LAGO + Vector3(0, 1.0, 0), 4.0, 6)
	_ponte_de_neve([Vector3(-31, 0, 94.5), Vector3(-36.5, 0, 91.5), Vector3(-42, 0, 88.5)])
	for x in [-31.0, -36.5, -42.0]:
		estrelinha(Vector3(x, 1.2, 94.5 + (x + 31.0) * 0.545))
	arco_de_saida(Vector3(-27, 0, 95.5), atan2(-7.0, -2.0), "yellow")
	for p in [Vector3(14, 0, 108), Vector3(10, 0, 96), Vector3(-2, 0, 92), Vector3(-14, 0, 94.5)]:
		neve("lantern", p, 0.0, 1.3)

	# Mini-marco: o boneco de neve gigante, olhando para quem chega.
	neve("snowman_B", Vector3(22, 0, 101), -2.2, 5.0)
	roda(Vector3(22, 0.9, 106.5), 2.0, 4)

	# Bolso: o iglu pequeno, com estrelinhas lá dentro.
	iglu(Vector3(-19, 0, 123), 4.5, PI * 0.3)
	roda(Vector3(-19, 1.0, 123), 1.6, 4)

	# Bolso: o monte do coração, subindo pela pilha de bolas de neve.
	for b in [[Vector3(-24.5, -0.2, 108), 1.8], [Vector3(-26.5, 1.4, 111.5), 1.8], [Vector3(-27.5, 2.8, 115), 1.8]]:
		_bola_parada(b[0], b[1])
	ilha(Vector3(-26, 6.0, 119), 3.6, NEVE, 3.0)
	coracao(Vector3(-26, 7.4, 119))
	trilha(Vector3(-24, 7.0, 117.5), Vector3(-28, 7.0, 120.5), 2)

	for p in [Vector3(24, 0, 120), Vector3(26, 0, 88), Vector3(-8, 0, 136), Vector3(14, 0, 135)]:
		neve("christmas_tree_withoutLights", p, p.x, 2.0)
	for spec in [["present_C_blue", Vector3(18, 0, 126), 3.0], ["present_D_red", Vector3(-22, 0, 102), 3.0], ["snowball_pile", Vector3(6, 0, 128), 2.0],
			["snowman_A", Vector3(-12, 0, 132), 1.6], ["snowball_pile", Vector3(28, 0, 104), 2.0]]:
		neve(spec[0], spec[1], spec[1].x, spec[2])


## Bola de neve grande parada (degrau da pilha do monte), com o meio em `meio`.
func _bola_parada(meio: Vector3, raio: float) -> StaticBody3D:
	var corpo := StaticBody3D.new()
	corpo.position = meio
	var bola: Node3D = _cena(NEVE_PASTA + "snowball.gltf").instantiate()
	bola.scale = Vector3.ONE * raio / 0.15
	corpo.add_child(bola)
	var cs := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = raio
	cs.shape = esfera
	corpo.add_child(cs)
	add_child(corpo)
	return corpo


## A ponte dos botões, de blocos de neve firme (o playground 1 é sem risco): escondida lá embaixo até os três botões
## estarem apertados (Fase._botao_apertado sobe cada bloco para o lugar dele).
func _ponte_de_neve(topos: Array) -> void:
	for t: Vector3 in topos:
		var corpo := StaticBody3D.new()
		var lugar := t - Vector3(0, 1.0, 0)
		corpo.set_meta("lugar", lugar)
		corpo.position = lugar - Vector3(0, 14.0, 0)
		corpo.visible = false
		var malha := BoxMesh.new()
		malha.size = Vector3(4, 1, 4)
		_malha(corpo, malha, NEVE[0], Vector3(0, 0.5, 0))
		var cs := CollisionShape3D.new()
		var caixa := BoxShape3D.new()
		caixa.size = Vector3(4, 1, 4)
		cs.shape = caixa
		cs.position.y = 0.5
		cs.disabled = true
		corpo.add_child(cs)
		add_child(corpo)
		ponte_botoes.append(corpo)


## Viagem 1: o trenó dos pinguins, da ponta da ponte até a primeira ilha de gelo, voando (espera o Faísca subir).
func _viagem_treno() -> void:
	treno = carona(Vector3(-46.6, 0, 87.6), Vector3(-64.6, 7, 63.2), "treno", 3.5)
	for t in [0.25, 0.5, 0.75]:
		estrelinha(treno.de.lerp(treno.ate, t) + Vector3.UP * 1.8)


# --- 2 · Ilhas de Gelo ----------------------------------------------------------------

## Playground 2 · Ilhas de Gelo (desenvolve): seis ilhas de blocos de neve e de gelo em alturas diferentes, ligadas
## por pontes estreitas de gelo (escorregam) e degraus de neve, com dois caminhos até a ilha do meio. Os três pinguins
## filhotes estão presos em cubos de gelo, um em cada ponta (direita, esquerda e fundo): o laser derrete, e com os três
## soltos o monte de neve que entope o canhão some. Mini-marco: o forte de neve na ilha do meio, com uma bola de neve
## rolando. Bolso: a beirada embaixo da ilha do meio, com o V1.
func _ilhas_de_gelo() -> void:
	var ilhas := {
		"chegada": [Vector3(-70, 7, 56), 12.0, false], "direita": [Vector3(-86, 9, 66), 8.0, true], "meio": [Vector3(-96, 10, 40), 16.0, false],
		"esquerda": [Vector3(-78, 8, 34), 8.0, false], "fundo": [Vector3(-114, 12, 28), 8.0, true], "alto": [Vector3(-104, 14, 10), 12.0, false],
	}
	playground("2 · Ilhas de Gelo", Vector3(-92, 10, 38), 26.0, treno.ate)
	for k in ilhas:
		bloco_de_neve(ilhas[k][0], ilhas[k][1], ilhas[k][1], ilhas[k][2])
	posto(Vector3(-72, 7, 59))
	ponto_de_dica(Vector3(-69, 7.5, 55), 3.5, "laser")

	# Pontes estreitas de gelo e os degraus de neve.
	for par in [[Vector3(-74, 7, 60), Vector3(-82.5, 9, 64)], [Vector3(-88, 9, 62.5), Vector3(-93, 10, 47.5)], [Vector3(-72, 7, 50.5), Vector3(-76, 8, 37.5)],
			[Vector3(-81.5, 8, 35), Vector3(-88.5, 10, 38)], [Vector3(-112, 12, 24.5), Vector3(-108, 14, 15.5)]]:
		rampa_de_gelo(par[0], par[1])
		estrelinha((par[0] + par[1]) * 0.5 + Vector3.UP * 1.2)
	for p in [Vector3(-98, 11, 29), Vector3(-100, 12, 24.5), Vector3(-102, 13, 19.5), Vector3(-104, 11, 29.5), Vector3(-108, 12, 25.5)]:
		bloco_de_neve(p, 3.5, 3.5)
		estrelinha(p + Vector3.UP * 1.1)

	# Os três pinguins presos, um em cada ponta, e o canhão entupido.
	ponto_de_dica(Vector3(-84, 9.5, 63), 2.5, "laser")
	for spec in [[ilhas["direita"][0] + Vector3(0, 0, 1.5), PI], [ilhas["esquerda"][0] + Vector3(0, 0, -1.5), 0.0], [ilhas["fundo"][0] + Vector3(-1, 0, 1), PI * 0.5]]:
		var c := pinguim_preso(spec[0], spec[1])
		c.solto.connect(_pinguim_solto)
		estrelinha(spec[0] + Vector3(0, 3.6, 0))
	var alto: Vector3 = ilhas["alto"][0]
	# O canhão de bolas de neve do Holiday Bits (o modelo vai antes de entrar na cena).
	var c := Canhao.new()
	c.destino = POUSO_CANHAO
	c.modelo = NEVE_PASTA + "snowball_cannon.gltf"
	c.escala_modelo = 4.0
	c.position = Vector3(alto.x, alto.y, 5.5)
	add_child(c)
	canhoes.append(c)
	tampa_do_canhao = StaticBody3D.new()
	tampa_do_canhao.position = Vector3(alto.x, alto.y, 5.5)
	var monte := SphereMesh.new()
	monte.radius = 2.8
	monte.height = 3.6
	_malha(tampa_do_canhao, monte, NEVE[0], Vector3(0, 0.6, 0))
	var cs := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = 2.8
	cs.shape = esfera
	cs.position.y = -0.2
	tampa_do_canhao.add_child(cs)
	add_child(tampa_do_canhao)
	arco_de_saida(Vector3(alto.x, alto.y, 11.0), 0.0, "blue")
	roda(alto + Vector3(0, 1.0, 2.5), 3.0, 5)

	# A ilha do meio: o forte de neve (mini-marco), a bola de neve rolando, duas Bolotas e estrelinhas.
	var meio: Vector3 = ilhas["meio"][0]
	bloco(Vector3(-100, 11.5, 34), Vector3(8, 3, 1.2), NEVE[0])
	bloco(Vector3(-103.4, 11.5, 38.6), Vector3(1.2, 3, 8), NEVE[0])
	coluna(Vector3(-103.4, 16, 34), 1.5, 6.0, NEVE[0])
	bola_de_neve(Vector3(-101, 10, 45.5), Vector3(-91, 10, 45.5), 1.6, 6.0)
	bolota(meio + Vector3(3, 0, 2), false, "pinguim")
	bolota(meio + Vector3(-1, 0, -3), false, "cogumelo")
	roda(meio + Vector3(0, 1.0, 0), 4.0, 5)
	bolota(ilhas["fundo"][0] + Vector3(2, 0, -2), false, "abelha")

	# Bolso embaixo da ilha do meio: a beirada com o V1 e um monte de neve fofa que devolve lá para cima.
	ilha(Vector3(-104, 3, 49), 3.5, PEDRA)
	vaga_lume(Vector3(-104.8, 4.2, 48.2))
	neve_fofa(Vector3(-101.8, 3.3, 50.8), 1.6, 19.0)
	trilha(Vector3(-102, 9.5, 48.5), Vector3(-104, 5.0, 49), 3)

	# O boneco de neve fica no canto, fora do caminho de quem desce do trenó (no meio dele, o Faísca esbarrava).
	for spec in [["christmas_tree_withoutLights", Vector3(-66, 7, 52), 1.5], ["snowman_A", Vector3(-75, 7, 54.5), 1.5], ["present_A_green", Vector3(-117, 12, 31), 3.0],
			["snowball_pile", Vector3(-100, 14, 14), 2.0], ["christmas_tree_withoutLights", Vector3(-89, 9, 69), 1.2]]:
		neve(spec[0], spec[1], spec[1].z, spec[2])


## Um pinguim saiu do gelo: com os três soltos, o monte de neve do canhão some num puf.
func _pinguim_solto(_c: CuboDeGelo) -> void:
	if not cubos_de_gelo.all(func(x: CuboDeGelo) -> bool: return x.derretido) or tampa_do_canhao.has_meta("aberta"):
		return
	tampa_do_canhao.set_meta("aberta", true)
	Sfx.play(self, "bandeira", 0.0, 0.0)
	Fx.confetti(self, tampa_do_canhao.global_position + Vector3.UP * 2.0, 40, 5.0)
	var tw := tampa_do_canhao.create_tween()
	tw.tween_interval(0.4)
	tw.tween_property(tampa_do_canhao, "scale", Vector3.ONE * 0.05, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		tampa_do_canhao.process_mode = Node.PROCESS_MODE_DISABLED
		tampa_do_canhao.hide())


## O monte de neve já saiu de cima do canhão.
func canhao_pronto() -> bool:
	return tampa_do_canhao.has_meta("aberta") and not tampa_do_canhao.visible


## Caixa sólida com o meio em `centro`, girada `giro` em Y (o forte de neve, a cabana).
func bloco(centro: Vector3, tamanho: Vector3, cor: Color, giro := 0.0) -> StaticBody3D:
	var corpo := StaticBody3D.new()
	corpo.position = centro
	corpo.rotation.y = giro
	var malha := BoxMesh.new()
	malha.size = tamanho
	_malha(corpo, malha, cor, Vector3.ZERO)
	var cs := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tamanho
	cs.shape = forma
	corpo.add_child(cs)
	add_child(corpo)
	return corpo


# --- 3 · Vila do Iglu ------------------------------------------------------------------

## Playground 3 · Vila do Iglu (central): a ilha grande com iglus, bonecos de neve e um laguinho de gelo. A Luva de
## Neve fica dentro do iglu grande (a porta dá para a trilha, e ela brilha lá dentro). Três sinos no alto de colunas
## de gelo de 12 m, só com a luva, soltam a cadeirinha de esqui na beirada leste. Bolsos: o quarto sino, atrás da
## chaminé do iglu grande (só se acerta indo por trás), faz aparecer a escada de gelo em volta da pedra alta do V2; o
## coração no telhado da cabana de esqui; estrelinhas no iglu pequeno. Três Bolotas, uma delas o fantasma (só a bola
## de neve e o laser pegam nele).
func _vila_do_iglu() -> void:
	playground("3 · Vila do Iglu", VILA, RAIO_VILA, POUSO_CANHAO)
	ilha(VILA, RAIO_VILA, NEVE, 16.0)
	posto(Vector3(-82, 18, -54))
	lago_de_gelo(Vector3(-74, 18, -84), 6.0)
	roda(Vector3(-74, 19.0, -84), 3.0, 5)
	trilha_creme([POUSO_CANHAO, Vector3(-70, 18, -57), Vector3(-60, 18, -61), Vector3(-50, 18, -66), Vector3(-44, 18, -73.5)])
	trilha(Vector3(-75, 19, -55), Vector3(-63, 19, -60), 3)
	for p in [Vector3(-74, 18, -54), Vector3(-66, 18, -59), Vector3(-56, 18, -59.5), Vector3(-48, 18, -63)]:
		neve("lantern", p, 0.0, 1.3)

	# O iglu grande com a Luva de Neve lá dentro, a chaminé e o quarto sino atrás dela.
	var centro := Vector3(-58, 18, -73)
	var frente := atan2(3.0, 8.5)
	iglu(centro, 7.0, frente)
	_luva_de_neve(centro + Vector3(0, 1.4, 0))
	var atras := -Vector3(sin(frente), 0, cos(frente))
	coluna(centro + Vector3(0, 7.9, 0) + atras * 1.5, 0.7, 2.4, Color("8f99ae"))
	var no_domo := atras * 4.2
	sino_da_escada = sino(centro + no_domo + Vector3(0, sqrt(49.0 - 4.2 * 4.2) - 0.3, 0), frente)
	sino_da_escada.tocou.connect(_escada_de_gelo)

	# Os três sinos nas colunas de gelo, que soltam a cadeirinha.
	for p in [Vector3(-92, 30, -70), Vector3(-78, 30, -104), Vector3(-46, 30, -92)]:
		coluna(p, 1.1, 12.0)
		var s := sino(p, atan2(VILA.x - p.x, VILA.z - p.z))
		s.tocou.connect(_sino_da_vila)
		sinos_da_vila.append(s)
		estrelinha(Vector3(p.x, 19.2, p.z) + (VILA - p).normalized() * 3.0)

	# A pedra alta do V2 e a escada de gelo em volta dela (escondida até o quarto sino tocar).
	var pedra := Vector3(-88, 30, -92)
	coluna(pedra, 1.4, 12.0, Color("8f99ae"))
	ilha(pedra, 3.5, PEDRA, 2.5)
	vaga_lume(pedra + Vector3(0, 1.4, 0))
	var para_meio := atan2(VILA.z - pedra.z, VILA.x - pedra.x)
	for i in 7:
		var a := para_meio - PI * 0.5 + i * PI / 6.0
		var topo := Vector3(pedra.x + cos(a) * 6.2, 18.0 + 1.6 * (i + 1), pedra.z + sin(a) * 6.2)
		# Gelo mágico transparente, firme (o gelo que escorrega tem sempre a cara azul riscada).
		var corpo := StaticBody3D.new()
		corpo.position = topo
		var malha := BoxMesh.new()
		malha.size = Vector3(3.2, 0.6, 3.2)
		var mi := MeshInstance3D.new()
		mi.mesh = malha
		mi.material_override = Gelo.material_cubo()
		mi.position.y = -0.3
		corpo.add_child(mi)
		var cs := CollisionShape3D.new()
		var caixa := BoxShape3D.new()
		caixa.size = malha.size
		cs.shape = caixa
		cs.position.y = -0.3
		cs.disabled = true
		corpo.add_child(cs)
		corpo.visible = false
		add_child(corpo)
		degraus_de_gelo.append(corpo)
		estrelinha(topo + Vector3.UP * 1.1)

	# A cabana de esqui com o coração no telhado (a pilha de bolas de neve é o degrau).
	var cabana := Vector3(-56, 18, -94)
	bloco(cabana + Vector3(0, 1.7, 0), Vector3(5, 3.4, 4), Color("8a5a36"), 0.4)
	bloco(cabana + Vector3(0, 3.55, 0), Vector3(5.6, 0.3, 4.6), NEVE[0], 0.4)
	_bola_parada(cabana + Vector3(3.8, -0.5, 1.8), 1.6)
	coracao(cabana + Vector3(0, 5.0, 0))

	# O iglu pequeno com estrelinhas dentro.
	iglu(Vector3(-66, 18, -100), 4.5, PI * 0.9)
	roda(Vector3(-66, 19.0, -100), 1.6, 4)

	ponto_de_dica(Vector3(-79, 18.5, -62), 3.0, "agarrar")
	bolota(Vector3(-80, 18, -70), false, "fantasma")
	bolota(Vector3(-63, 18, -86), false, "pinguim")
	bolota(Vector3(-70, 18, -94), false, "cogumelo")
	for spec in [["christmas_tree_withoutLights", Vector3(-92, 18, -58), 2.0], ["christmas_tree_withoutLights", Vector3(-70, 18, -108), 2.0],
			["christmas_tree_withoutLights", Vector3(-98, 18, -90), 1.8], ["snowman_B", Vector3(-74, 18, -64), 2.4], ["snowman_A", Vector3(-82, 18, -92), 2.2],
			["iglu", Vector3(-94, 18, -82), 4.0]]:
		if spec[0] == "iglu":
			iglu(spec[1], spec[2], PI * 0.5)
		else:
			neve(spec[0], spec[1], spec[1].x * 0.1, spec[2])
	roda(Vector3(-94, 19.0, -82), 1.4, 3)

	# A saída: o arco na beirada leste e a ilhota da estação da cadeirinha.
	arco_de_saida(Vector3(-44, 18, -73.5), PI * 0.5, "green")
	ilha(Vector3(-38, 18, -74), 4.5, NEVE)


## A Luva de Neve: uma luva azul de lã girando e brilhando dentro do iglu grande.
func _luva_de_neve(pos: Vector3) -> void:
	_luva = Area3D.new()
	_luva.position = pos
	_luva.collision_layer = 0
	_luva.collision_mask = CAMADA_JOGADOR
	var forma := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = 1.3
	forma.shape = esfera
	_luva.add_child(forma)
	var desenho := Node3D.new()
	_luva.add_child(desenho)
	var azul := _material(Color("3f8fe0"))
	azul.emission_enabled = true
	azul.emission = Color("4aa8ff")
	azul.emission_energy_multiplier = 0.5
	var palma := MeshInstance3D.new()
	palma.mesh = Forma.superelipsoide(Vector3(0.42, 0.55, 0.24), 1.0, 1.0)
	palma.material_override = azul
	desenho.add_child(palma)
	var dedao := MeshInstance3D.new()
	dedao.mesh = Forma.superelipsoide(Vector3(0.14, 0.26, 0.14), 1.0, 1.0)
	dedao.material_override = azul
	dedao.position = Vector3(0.42, -0.05, 0)
	dedao.rotation.z = -0.6
	desenho.add_child(dedao)
	var punho := MeshInstance3D.new()
	punho.mesh = _cilindro(0.38, 0.38, 0.28)
	punho.material_override = _material(Color("f4fbff"))
	punho.position.y = -0.62
	desenho.add_child(punho)
	var bola: Node3D = _cena(NEVE_PASTA + "snowball.gltf").instantiate()
	bola.scale = Vector3.ONE * 2.0
	bola.position = Vector3(0, 0.75, 0.1)
	desenho.add_child(bola)
	var luz := OmniLight3D.new()
	luz.light_color = Color("8fd0ff")
	luz.light_energy = 1.6
	luz.omni_range = 6.0
	_luva.add_child(luz)
	add_child(_luva)
	var tw := _luva.create_tween().set_loops()
	tw.tween_property(desenho, "position:y", 0.35, 0.7).set_trans(Tween.TRANS_SINE)
	tw.tween_property(desenho, "position:y", 0.0, 0.7).set_trans(Tween.TRANS_SINE)
	var gira := _luva.create_tween().set_loops()
	gira.tween_property(desenho, "rotation:y", TAU, 2.4).from(0.0)
	_luva.body_entered.connect(func(corpo: Node3D) -> void:
		if corpo is Jogador and not luva_pega:
			pegar_luva(corpo))


## O Faísca pega a Luva de Neve: vale até o fim da fase, e o Vovô mostra como usa.
func pegar_luva(j: Jogador) -> void:
	luva_pega = true
	j.luva_de_neve = true
	j.robo.expressao("feliz", 1.2)
	Fx.confetti(self, _luva.global_position, 40, 4.0)
	Sfx.play(self, "bandeira", 0.0, 0.0)
	_luva.set_deferred("monitoring", false)
	_luva.hide()
	_dica_uma_vez("luva")


## Um dos três sinos da vila tocou: com os três, a cadeirinha destrava.
func _sino_da_vila(_s: Sino) -> void:
	if not sinos_da_vila.all(func(x: Sino) -> bool: return x.tocado) or not cadeirinha.travada:
		return
	cadeirinha.travada = false
	Sfx.play(self, "bandeira", 0.0, 0.0)
	Fx.confetti(self, cadeirinha.global_position + Vector3.UP * 2.0, 40, 5.0)


## O quarto sino tocou: os degraus de gelo aparecem um depois do outro em volta da pedra alta.
func _escada_de_gelo(_s: Sino) -> void:
	for i in degraus_de_gelo.size():
		var d := degraus_de_gelo[i]
		var tw := d.create_tween()
		tw.tween_interval(0.18 * i)
		tw.tween_callback(func() -> void:
			d.show()
			(d.get_child(1) as CollisionShape3D).disabled = false
			d.scale = Vector3.ONE * 0.05)
		tw.tween_property(d, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func() -> void: Fx.confetti(self, d.global_position + Vector3.UP, 8, 2.0))
	Sfx.play(self, "gelo", 2.0, 0.0)


## A escada de gelo já apareceu inteira.
func escada_pronta() -> bool:
	return degraus_de_gelo.all(func(d: StaticBody3D) -> bool: return d.visible and d.scale.is_equal_approx(Vector3.ONE))


## Viagem 3: a cadeirinha de esqui, da ilhota da estação até a primeira plataforma da Encosta, com o cabo e as duas
## torrinhas. Fica travada até os três sinos da vila tocarem; depois leva de volta também (atalho).
func _viagem_cadeirinha() -> void:
	var de := Vector3(-38, 18, -74)
	var g0 := no_pico(70, 40, 22)
	var rumo := Vector3(g0.x - de.x, 0, g0.z - de.z).normalized()
	var ate := Vector3(g0.x, 22, g0.z) - rumo * 7.4
	cadeirinha = carona(de, ate, "cadeirinha", 5.0)
	cadeirinha.travada = true
	var dir := (ate - de).normalized()
	var ponta_a := de - dir * 3.5 + Vector3.UP * 7.6
	var ponta_b := ate + dir * 3.5 + Vector3.UP * 7.6
	var cabo := MeshInstance3D.new()
	cabo.mesh = _cilindro(0.08, 0.08, ponta_a.distance_to(ponta_b))
	cabo.material_override = _material(Color("3a3150"))
	add_child(so_enfeite(cabo))
	cabo.look_at_from_position((ponta_a + ponta_b) * 0.5, ponta_b, Vector3.UP)
	cabo.rotate_object_local(Vector3.RIGHT, PI / 2.0)
	for p: Vector3 in [ponta_a, ponta_b]:
		var torre := StaticBody3D.new()
		torre.position = p + Vector3.DOWN * 4.0
		add_child(torre)
		_malha(torre, _cilindro(0.3, 0.4, 8.4), Color("6a6478"), Vector3.ZERO)
		var cs := CollisionShape3D.new()
		var cil := CylinderShape3D.new()
		cil.radius = 0.4
		cil.height = 8.4
		cs.shape = cil
		torre.add_child(cs)
	for t in [0.3, 0.55, 0.8]:
		estrelinha(de.lerp(ate, 0.5 - 0.5 * cos(PI * t)) + Vector3.UP * 1.8)


# --- 4 · Encosta das Avalanches --------------------------------------------------------

## Playground 4 · Encosta das Avalanches (reviravolta): plataformas de neve subindo em volta do pico, de 22 a 31 m.
## Três cachoeiras cortam o caminho entre as quatro primeiras (o vão é alto e largo demais para um pulo, e a água
## empurra de volta); o sino na pedra em cima de cada uma, acertado com a bola de neve, congela a água numa rampa de
## gelo. Bolas de neve rolam nas plataformas do meio, com bonecos de neve de abrigo. Bolso: a caverna atrás da
## segunda cachoeira, com o coração. A saída é a ponte de gelo até o anel do pico.
func _encosta_das_avalanches() -> void:
	var g := [[no_pico(70, 40, 22), 6.0], [no_pico(46, 38, 25), 4.5], [no_pico(22, 37, 28), 4.5], [no_pico(-2, 36, 31), 4.5], [no_pico(-26, 33, 31), 4.5]]
	playground("4 · Encosta das Avalanches", no_pico(24, 37, 27), 22.0, cadeirinha.ate)
	for i in g.size():
		ilha(g[i][0], g[i][1], NEVE)
		estrelinha(g[i][0] + Vector3(0, 1.2, 0))
	posto(g[0][0] + Vector3(1.5, 0, 1.0))
	trilha(cadeirinha.ate + Vector3(0, 1.0, 0), g[0][0] + Vector3(-2, 1.0, -1), 3)

	# As três cachoeiras, cada uma com o sino na pedra lá em cima.
	for i in 3:
		var a: Vector3 = g[i][0]
		var b: Vector3 = g[i + 1][0]
		var rumo := Vector3(b.x - a.x, 0, b.z - a.z).normalized()
		var de: Vector3 = a + rumo * (g[i][1] - 0.4)
		var ate: Vector3 = b - rumo * (g[i + 1][1] - 0.4)
		var meio := (de + ate) * 0.5
		var topo := maxf(a.y, b.y) + 9.0
		var c := cachoeira(de, ate, topo, a.y - 14.0)
		var pedra := MeshInstance3D.new()
		pedra.mesh = Forma.superelipsoide(Vector3(2.6, 1.0, 2.0), 1.0, 1.0)
		pedra.material_override = _material(PEDRA[2])
		pedra.position = Vector3(meio.x, topo + 0.4, meio.z)
		pedra.rotation.y = atan2(rumo.x, rumo.z)
		add_child(so_enfeite(pedra))
		var s := sino(Vector3(meio.x, topo + 1.2, meio.z), atan2(-rumo.x, -rumo.z))
		s.tocou.connect(c.congelar)
		sinos_das_cachoeiras.append(s)
		estrelinha(meio + Vector3(0, 1.8, 0))
		arco(de + Vector3(0, 1.0, 0) - rumo * 1.5, de + Vector3(0, 1.0, 0) + Vector3.UP * 5.0, 1.0, 2)

	# Bolas de neve rolando de lado nas plataformas do meio, e um boneco de neve de abrigo em cada.
	for i in [1, 2]:
		var c: Vector3 = g[i][0]
		var rumo := Vector3(g[i + 1][0].x - g[i - 1][0].x, 0, g[i + 1][0].z - g[i - 1][0].z).normalized()
		var lado := Vector3.UP.cross(rumo).normalized()
		bola_de_neve(c - lado * 3.0, c + lado * 3.0, 1.4, 4.5 + i, i * 1.3)
		neve("snowman_A", c - rumo * 2.6 + lado * 2.4, atan2(rumo.x, rumo.z), 1.3)
	bolota(g[0][0] + Vector3(-2.5, 0, 2.5), false, "caranguejo")
	bolota(g[3][0] + Vector3(1, 0, 0), false, "pinguim")

	# Bolso: a caverna de pedra atrás da segunda cachoeira, com o coração e estrelinhas.
	var cav := no_pico(34, 31, 26.5)
	ilha(cav, 3.6, PEDRA, 3.0)
	iglu(cav, 3.0, atan2(cav.x, cav.z), PEDRA[0])
	coracao(cav + Vector3(0, 1.3, 0))
	roda(cav + Vector3(0, 1.0, 0), 1.6, 3)

	# A saída: o arco na última plataforma e a ponte de gelo até o anel do pico.
	var g4: Vector3 = g[4][0]
	var para_dentro := -Vector3(g4.x, 0, g4.z).normalized()
	arco_de_saida(g4 + para_dentro * 2.6, atan2(para_dentro.x, para_dentro.z), "red")
	rampa_de_gelo(g4 + para_dentro * 4.1, no_pico(-26, RAIO_PE - 1.5, TOPO_PE), 3.4)
	trilha(g4 + para_dentro * 5.0 + Vector3.UP, no_pico(-26, 23.0, TOPO_PE + 1.0), 3)


# --- 5 · Subida do Pico ---------------------------------------------------------------

## Playground 5 · Subida do Pico (o fim): o anel em cima do pé do pico e a subida pela parede do pico de cima. O monte
## de neve fofa do anel joga até a primeira saliência; daí em diante saliências de neve (firmes) e pingentes lilases
## (caem um instante depois de pisados) sobem 1,6 m por vez em volta do pico até o degrau na frente da porta de gelo do
## cume, que só abre com o sino pendurado em cima dela. Quem cai da parede cai no anel, sem perder coração; outro
## monte de neve fofa, do outro lado do anel, devolve até a quinta saliência. Segredo: a gruta de gelo encostada no
## pico, com a parede rachada (V3).
func _subida_do_pico() -> void:
	var entrada := no_pico(-26, 23.0, TOPO_PE)
	playground("5 · Subida do Pico", Vector3(0, 38, 0), 24.0, entrada)
	posto(no_pico(-34, 23.5, TOPO_PE))
	trilha_creme([no_pico(-26, 22.0, TOPO_PE), no_pico(-40, 22.0, TOPO_PE), no_pico(-54, 22.0, TOPO_PE), no_pico(-62, 21.5, TOPO_PE)])
	for a in [-38.0, -48.0, -58.0]:
		estrelinha(no_pico(a, 22.0, TOPO_PE + 1.0))
	ponto_de_dica(no_pico(-50, 22.5, TOPO_PE + 0.5), 3.0, "quicar")
	bolota(no_pico(-100, 22.5, TOPO_PE), false, "ciclope")

	neve_fofa(no_pico(-66, 21.0, TOPO_PE + 0.3), 2.0, 18.0)
	# Saliências (S) e pingentes (P) subindo pela parede: [graus, altura, tipo].
	var degraus := [[-80.0, 33.6, "S"], [-97.0, 35.2, "S"], [-114.0, 36.8, "P"], [-130.0, 38.4, "P"], [-146.0, 40.0, "S"],
		[-162.0, 41.6, "P"], [-178.0, 43.2, "S"], [-194.0, 44.6, "D"]]
	for d in degraus:
		var y: float = d[1]
		if d[2] == "P":
			var p := pingente(no_pico(d[0], raio_do_pico(y) + 1.6, y), 1.7)
			estrelinha(p.position + Vector3(0, 1.4, 0))
		else:
			var topo := no_pico(d[0], raio_do_pico(y) + 1.8, y)
			var lado := 3.6 if d[2] == "D" else 4.0
			# Saliências de neve firme: gelo num degrau de 4 m na parede jogava a criança para fora.
			var b := bloco_de_neve(topo, lado, lado)
			b.rotation.y = deg_to_rad(d[0]) + PI * 0.5
			estrelinha(topo + Vector3(0, 1.2, 0))
	bolota(no_pico(-146, raio_do_pico(40.0) + 1.8, 40.0), false, "pinguim")

	# O monte de neve fofa do outro lado do anel, para quem caiu, devolve até a quinta saliência.
	neve_fofa(no_pico(-150, 21.6, TOPO_PE + 0.3), 2.0, 24.0)

	# O muro de gelo em volta do cume, a porta de gelo virada para o degrau e o sino dela.
	_muro_do_cume(-194.0)
	sino_da_porta = sino(no_pico(-194, RAIO_CUME + 1.6, TOPO_CUME + 2.4), deg_to_rad(-194.0) + PI * 0.5)
	sino_da_porta.tocou.connect(_abrir_porta)

	# Segredo: a gruta de gelo encostada no pico, com a parede rachada virada para quem vem pelo anel.
	_gruta_secreta(no_pico(-125, RAIO_BASE_CIMA + 2.2, TOPO_PE), deg_to_rad(-125.0))
	ponto_de_dica(no_pico(-112, 22.5, TOPO_PE + 0.5), 3.0, "golpe")
	coracao(no_pico(-82, 23.0, TOPO_PE + 1.2))
	for spec in [["snowball_pile", -44.0, 24.0], ["present_C_blue", -110.0, 24.6], ["snowman_A", -170.0, 23.6], ["snowball_pile", -210.0, 23.0]]:
		neve(spec[0], no_pico(spec[1], spec[2], TOPO_PE), deg_to_rad(spec[1]), 2.0 if spec[0] != "snowman_A" else 1.5)


## O muro de gelo de 2,6 m em volta do cume, com o vão da porta em `porta_graus` (a porta de gelo fecha o vão).
func _muro_do_cume(porta_graus: float) -> void:
	var corpo := StaticBody3D.new()
	add_child(corpo)
	var n := 24
	for i in n:
		var graus := porta_graus + 7.5 + 15.0 * i
		if absf(wrapf(graus - porta_graus, -180.0, 180.0)) < 14.0:
			continue
		var p := no_pico(graus, RAIO_CUME - 0.5, TOPO_CUME + 1.3)
		var giro := deg_to_rad(graus) + PI * 0.5
		var forma := BoxShape3D.new()
		forma.size = Vector3(2.9, 2.6, 0.9)
		var cs := CollisionShape3D.new()
		cs.shape = forma
		cs.position = p
		cs.rotation.y = giro
		corpo.add_child(cs)
		var malha := BoxMesh.new()
		malha.size = forma.size
		var mi := MeshInstance3D.new()
		mi.mesh = malha
		mi.material_override = Gelo.material()
		mi.position = p
		mi.rotation.y = giro
		corpo.add_child(mi)
	porta_do_cume = StaticBody3D.new()
	porta_do_cume.position = no_pico(porta_graus, RAIO_CUME - 0.5, TOPO_CUME)
	porta_do_cume.rotation.y = deg_to_rad(porta_graus) + PI * 0.5
	var malha := BoxMesh.new()
	malha.size = Vector3(4.4, 2.6, 0.7)
	var mi := MeshInstance3D.new()
	mi.mesh = malha
	mi.material_override = Gelo.material_cubo()
	mi.position.y = 1.3
	porta_do_cume.add_child(mi)
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = malha.size
	cs.shape = caixa
	cs.position.y = 1.3
	porta_do_cume.add_child(cs)
	add_child(porta_do_cume)


## O último sino tocou: a porta de gelo do cume racha e afunda.
func _abrir_porta(_s: Sino) -> void:
	if porta_do_cume.has_meta("aberta"):
		return
	porta_do_cume.set_meta("aberta", true)
	Sfx.play(self, "gelo", 2.0, 0.0)
	Fx.confetti(self, porta_do_cume.global_position + Vector3.UP * 1.5, 40, 4.0)
	var tw := porta_do_cume.create_tween()
	tw.tween_interval(0.3)
	tw.tween_property(porta_do_cume, "position:y", porta_do_cume.position.y - 3.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		porta_do_cume.process_mode = Node.PROCESS_MODE_DISABLED
		porta_do_cume.hide())


func porta_aberta() -> bool:
	return porta_do_cume.has_meta("aberta") and not porta_do_cume.visible


## Gruta de gelo encostada no pico, com a parede da frente rachada (três golpes abrem): dentro, o V3 e estrelinhas.
## `centro` é o meio do chão e `ang_rad` o ângulo dela em volta do pico (como em `no_pico`): o fundo fica encostado no
## pico, e a frente aponta no sentido de quem vem pelo anel.
func _gruta_secreta(centro: Vector3, ang_rad: float) -> void:
	var raiz := Node3D.new()
	raiz.position = centro
	# +X local para dentro do pico; +Z local é a frente, no sentido anti-horário do anel (o ângulo crescendo).
	var fora := Vector3(cos(ang_rad), 0, -sin(ang_rad))
	var frente := -fora.cross(Vector3.UP)
	raiz.basis = Basis(-fora, Vector3.UP, frente)
	add_child(raiz)
	var cor := Color("a9c4dc")
	var corpo := StaticBody3D.new()
	raiz.add_child(corpo)
	for spec in [[Vector3(-2.2, 2.3, 0), Vector3(0.5, 4.6, 5.0)], [Vector3(2.2, 2.3, 0), Vector3(0.5, 4.6, 5.0)],
			[Vector3(0, 2.3, -2.5), Vector3(4.9, 4.6, 0.5)], [Vector3(0, 4.85, 0), Vector3(5.3, 0.5, 5.6)]]:
		_parede(corpo, spec[1], spec[0], cor)
	var cobertura := BoxMesh.new()
	cobertura.size = Vector3(5.6, 0.35, 5.9)
	var neve_em_cima := _malha(corpo, cobertura, NEVE[0], Vector3(0, 5.25, 0))
	var cs := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = cobertura.size
	cs.shape = forma
	cs.position = neve_em_cima.position
	corpo.add_child(cs)
	var p := ParedeRachada.new()
	p.escala = 1.1
	p.position = Vector3(0, 0, 2.5)
	raiz.add_child(p)
	for mi in p.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = _material(Color("bcd8ee"))
	paredes_rachadas.append(p)
	paredes_do_pico.append(p)
	vaga_lume(raiz.to_global(Vector3(0, 1.4, -1.2)))
	for x in [-1.3, 1.3]:
		estrelinha(raiz.to_global(Vector3(x, 1.0, -0.6)))
	estrelinha(raiz.to_global(Vector3(0, 1.0, 1.0)))


# --- arena --------------------------------------------------------------------------

## Arena no cume (46 m), dentro do muro de gelo: o baú, três Bolotas e a coluna de luz que aparece da fase toda.
func _arena() -> void:
	var topo := Vector3(0, TOPO_CUME, 0)
	var para_porta := no_pico(-194, 1.0, 0)
	colocar_bau(topo, atan2(para_porta.x, para_porta.z))
	brilho_de_marco(topo + Vector3(0, 1.5, 0), 40.0)
	bolota(topo + Vector3(-4, 0, 4), false, "alien")
	bolota(topo + Vector3(5, 0, 3), false, "porco")
	bolota(topo + Vector3(1, 0, -6), false, "abelha")
	ponto_de_dica(topo + Vector3(-5, 1, -5), 3.0, "giro_forte")
	roda(topo + Vector3(0, 0.9, 0), 3.4, 4)
	for p in [Vector3(-7, 0, -3), Vector3(6, 0, -5)]:
		neve("snowball_pile", topo + p, p.x, 2.0)


## Nuvens do Medieval Hexagon espalhadas pelo céu, só de enfeite, longe dos playgrounds e das viagens.
func _nuvens_de_enfeite() -> void:
	var gerador := RandomNumberGenerator.new()
	gerador.seed = 31
	var viagens := [[treno.de, treno.ate], [canhoes[0].global_position, canhoes[0].destino], [cadeirinha.de, cadeirinha.ate]]
	for i in 40:
		var p := Vector3(gerador.randf_range(-180, 130), gerador.randf_range(-4, 56), gerador.randf_range(-170, 190))
		var perto := Vector2(p.x, p.z).length() < 55.0
		for pg in playgrounds:
			perto = perto or Vector2(p.x - pg.centro.x, p.z - pg.centro.z).length() < pg.raio + 22.0
		for v in viagens:
			var a := Vector2(v[0].x, v[0].z)
			var b := Vector2(v[1].x, v[1].z)
			var q := Vector2(p.x, p.z)
			perto = perto or q.distance_to(a + (b - a) * clampf((q - a).dot(b - a) / (b - a).length_squared(), 0.0, 1.0)) < 22.0
		if not perto:
			so_enfeite(peca_de(DOCES, "cloud_big" if i % 2 else "cloud_small", p, gerador.randf() * TAU, gerador.randf_range(5.0, 9.0), false))


## Neve caindo devagar em volta da câmera (os flocos acompanham quem estiver olhando).
func _neve_do_ceu() -> void:
	_neve_caindo = CPUParticles3D.new()
	_neve_caindo.amount = 500
	_neve_caindo.lifetime = 7.0
	_neve_caindo.preprocess = 7.0
	_neve_caindo.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_neve_caindo.emission_box_extents = Vector3(35, 1, 35)
	_neve_caindo.direction = Vector3.DOWN
	_neve_caindo.spread = 15.0
	_neve_caindo.gravity = Vector3(0.4, -1.2, 0)
	_neve_caindo.initial_velocity_min = 1.0
	_neve_caindo.initial_velocity_max = 2.0
	var floco := QuadMesh.new()
	floco.size = Vector2(0.14, 0.14)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1, 1, 1, 0.9)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	floco.material = m
	_neve_caindo.mesh = floco
	_neve_caindo.local_coords = false
	add_child(_neve_caindo)


func _process(delta: float) -> void:
	super._process(delta)
	var cam := get_viewport().get_camera_3d()
	if cam and _neve_caindo:
		_neve_caindo.global_position = cam.global_position + Vector3.UP * 14.0


# --- céu ----------------------------------------------------------------------------

## Céu de inverno: azul limpo em cima e branco-azulado no horizonte, luz fria.
func _montar_ceu_e_luz() -> void:
	super._montar_ceu_e_luz()
	for we in find_children("*", "WorldEnvironment", false, false):
		var ceu := ((we as WorldEnvironment).environment.sky.sky_material as ProceduralSkyMaterial)
		ceu.sky_top_color = Color("4f93ee")
		ceu.sky_horizon_color = Color("e6f3ff")
		ceu.ground_horizon_color = Color("eef6ff")
		ceu.ground_bottom_color = Color("cfe3f7")
		var env := (we as WorldEnvironment).environment
		env.fog_light_color = Color("dcebfb")
		env.fog_density = 0.0015
		env.ambient_light_color = Color("dfe8f5")
		env.ambient_light_energy = 0.55
		env.tonemap_exposure = 0.8
		# Neve, céu e névoa brancos deixavam tudo lavado e o gelo sumia na neve (fotos de 2026-10-30): mais cor e contraste.
		env.adjustment_enabled = true
		env.adjustment_saturation = 1.25
		env.adjustment_contrast = 1.08


## Mar de nuvens embaixo da fase toda (a fase vai de z 140 a -110 e de x -125 a 50).
func _montar_nuvens() -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("e4ecf8")
	m.roughness = 1.0
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _esfera_baixa()
	var gerador := RandomNumberGenerator.new()
	gerador.seed = 7
	var bolas := []
	for i in 34:
		for j in 34:
			if gerador.randf() < 0.3:
				continue
			var p := Vector3(-230 + i * 12 + gerador.randf_range(-5, 5), limite_queda - 5.0 + gerador.randf_range(-2.5, 1.5), 200 - j * 12 + gerador.randf_range(-5, 5))
			var r := gerador.randf_range(5.0, 9.5)
			bolas.append(Transform3D(Basis.from_scale(Vector3(r, r * 0.42, r)), p))
	mm.instance_count = bolas.size()
	for k in bolas.size():
		mm.set_instance_transform(k, bolas[k])
	var nuvens := MultiMeshInstance3D.new()
	nuvens.multimesh = mm
	nuvens.material_override = m
	nuvens.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(nuvens)

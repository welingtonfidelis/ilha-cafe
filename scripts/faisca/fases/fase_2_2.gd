class_name Fase22
extends Fase
## 2-2 Nuvens de Algodão-Doce (Mundo 2, Doces e Brinquedos; fase de céu). As Bolotas esconderam a quarta Estrela
## Grande em cima de um bolo-montanha que flutua no céu, no meio de ilhas de algodão-doce, biscoito e chiclete.
## Novidade: as nuvens que quicam (e as lilases, que quicam e somem). Poder da fase: o Balão de Chiclete, pego na
## máquina da praça (segurando o pulo no ar, o Faísca sobe devagar). Feita em 2026-10-30 a partir da maquete
## aprovada (docs/level-design/maquete-2-2-nuvens-de-algodao-doce.html), já mais longa, a pedido do usuário no
## mesmo dia ("a duração das fases precisa aumentar, as crianças estão zerando muito rápido"): cinco playgrounds em
## espiral em volta do bolo, e cada saída só abre com uma tarefa.
##   1 Campo de Algodão (y 0, ao sul): nuvens que quicam sem risco; três botões no alto de três pilares (só quicando)
##     levantam a ponte até a nuvem-carro
##   viagem: nuvem-carro
##   2 Ilhas de Biscoito (y 7 a 14, a oeste): nuvens que quicam sobre o vazio; as três flores (uma em cada ponta)
##     abrem o portão do canhão; V1 numa beirada embaixo da ilha do meio (P1)
##   viagem: canhão
##   3 Praça do Carrossel (y 16, a noroeste): a máquina de chiclete dá o balão, e só com ele se sobe até a estação do
##     teleférico; V2 no anel alto; coração (P2)
##   viagem: teleférico (leva de volta também)
##   4 Céu de Chiclete (y 14 a 26, a nordeste e leste): ilhas de chiclete e nuvens que quicam e somem, subindo; coração
##     num bolso alto que só o balão alcança (P3)
##   ponte de wafer até o bolo
##   5 Subida do Bolo (y 26 a 40, em volta do andar de cima do bolo): cereja que quica, vela que sobe e desce e uma
##     fileira de biscoitos presos no bolo; V3 na casinha de biscoito com a parede rachada, lá embaixo no anel (P4)
##   Arena no topo do bolo (40 m): o baú e três Bolotas

const DOCES := "res://assets/faisca/doces/"
const ALGODAO := [Color("f6b6d3"), Color("d9608f"), Color("ee9cc2")]
const BISCOITO := [Color("e8b878"), Color("7a4a1c"), Color("b98546")]
const CHICLETE_AZUL := [Color("8fd8ff"), Color("1f6f9e"), Color("5fb2df")]
const CHICLETE_ROSA := [Color("ff9fd0"), Color("b23c79"), Color("e57fb4")]
## O marco: o bolo-montanha. O andar de baixo (raio 24) vai até 26 m, e o anel em cima dele (de 14 a 24 m do meio) é o
## chão da Subida do Bolo; o andar de cima (raio 14) vai até a arena, a 40 m.
const RAIO_BOLO := 24.0
const TOPO_BOLO := 26.0
const RAIO_TOPO := 14.0
const TOPO_ARENA := 40.0
const CAMPO := Vector3(0, 0, 108)
const PRACA := Vector3(-70, 16, -78)

## A bola de chiclete da máquina já foi pega.
var balao_pego := false
var carrossel: Carrossel
var teleferico: Carona
var nuvem_carro: Carona
var paredes_do_bolo: Array[ParedeRachada] = []
var velas: Array[AnimatableBody3D] = []
var cerejas: Array[Area3D] = []
var _bola_de_chiclete: Area3D


func _montar() -> void:
	nome = "2-2 Nuvens de Algodão-Doce"
	inicio = Vector3(12, 0.1, 128)
	limite_queda = -10.0
	farol(Vector3(140, -16, -240), 2.0)
	_bolo()
	_campo_de_algodao()
	_viagem_nuvem_carro()
	_ilhas_de_biscoito()
	_praca_do_carrossel()
	_viagem_teleferico()
	_ceu_de_chiclete()
	_subida_do_bolo()
	_arena()
	_nuvens_de_enfeite()


# --- peças da fase ------------------------------------------------------------------

## Ilha redonda de doce com `topo` no meio de cima: a tampa, a borda de cobertura e o cone por baixo.
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


## Pilar de doce com `topo` em cima (o pilar dos botões, a estação do teleférico).
func coluna(topo: Vector3, raio: float, altura: float, cores: Array) -> StaticBody3D:
	var corpo := StaticBody3D.new()
	corpo.position = topo
	add_child(corpo)
	_malha(corpo, _cilindro(raio, raio * 1.12, altura), cores[2], Vector3(0, -altura * 0.5, 0))
	_malha(corpo, _cilindro(raio + 0.05, raio + 0.05, 0.6), cores[0], Vector3(0, -0.3, 0))
	var toro := TorusMesh.new()
	toro.inner_radius = raio - 0.2
	toro.outer_radius = raio + 0.3
	toro.rings = 48
	_malha(corpo, toro, cores[1], Vector3(0, -0.06, 0))
	var cs := CollisionShape3D.new()
	var forma := CylinderShape3D.new()
	forma.radius = raio
	forma.height = altura
	cs.shape = forma
	cs.position.y = -altura * 0.5
	corpo.add_child(cs)
	return corpo


## Caixa sólida com o meio em `centro`, girada `giro` em Y (a ponte de wafer, as paredes da casinha).
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


## Peça dos doces (Holiday Bits, Halloween Bits e as nuvens do Medieval Hexagon).
func doce(arquivo: String, pos: Vector3, giro := 0.0, escala: Variant = 1.0, solida := false) -> Node3D:
	return peca_de(DOCES, arquivo, pos, giro, escala, solida)


## Ponto em volta do bolo: `graus` contados do leste (+X) para o norte (-Z), a `raio` m do meio, na altura `y`.
func no_bolo(graus: float, raio: float, y: float) -> Vector3:
	var a := deg_to_rad(graus)
	return Vector3(raio * cos(a), y, -raio * sin(a))


## Cereja que quica (o "botão" da Subida do Bolo): em cima dela, quem cai vai para o alto como na mola. `chao` é onde
## ela está apoiada; o topo fica 1,5 m acima.
func cereja(chao: Vector3, forca := 16.0) -> Area3D:
	var visual := Node3D.new()
	visual.position = chao
	add_child(visual)
	var vermelho := _material(Color("e2304a"))
	vermelho.roughness = 0.2
	vermelho.rim_enabled = true
	vermelho.rim = 0.3
	var bola := SphereMesh.new()
	bola.radius = 0.95
	bola.height = 1.6
	_malha(visual, bola, Color.WHITE, Vector3(0, 0.8, 0)).material_override = vermelho
	var cabo := _cilindro(0.06, 0.08, 1.0)
	var no_cabo := _malha(visual, cabo, Color("5a9a3a"), Vector3(0.15, 2.0, 0))
	no_cabo.rotation.z = -0.3
	var corpo := StaticBody3D.new()
	var cs0 := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = 0.9
	cil.height = 1.5
	cs0.shape = cil
	cs0.position.y = 0.75
	corpo.add_child(cs0)
	visual.add_child(corpo)
	var area := AreaDeMola.new()
	area.forca = forca
	area.visual = visual
	area.amassado = Vector3(1.25, 0.7, 1.25)
	area.position = chao + Vector3(0, 1.6, 0)
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(1.8, 1.0, 1.8)
	cs.shape = caixa
	area.add_child(cs)
	add_child(area)
	molas.append(area)
	cerejas.append(area)
	return area


## Vela grande espetada no bolo, que sobe `subida` m e desce (o elevador da Subida do Bolo). `topo` é em cima dela,
## na posição de baixo.
func vela(topo: Vector3, subida: float, periodo := 6.0, atraso := 0.0) -> AnimatableBody3D:
	var corpo := AnimatableBody3D.new()
	corpo.position = topo
	var altura := 10.0
	_malha(corpo, _cilindro(1.6, 1.6, altura), Color("fff6fb"), Vector3(0, -altura * 0.5, 0))
	for i in 5:
		var faixa := TorusMesh.new()
		faixa.inner_radius = 1.55
		faixa.outer_radius = 1.75
		_malha(corpo, faixa, Color("8fd8ff") if i % 2 == 0 else Color("ff9fd0"), Vector3(0, -1.0 - i * 1.8, 0))
	var cobertura := TorusMesh.new()
	cobertura.inner_radius = 1.3
	cobertura.outer_radius = 1.75
	_malha(corpo, cobertura, Color("ff7a22"), Vector3(0, -0.05, 0))
	var cs := CollisionShape3D.new()
	var forma := CylinderShape3D.new()
	forma.radius = 1.6
	forma.height = altura
	cs.shape = forma
	cs.position.y = -altura * 0.5
	corpo.add_child(cs)
	add_child(corpo)
	_moveis.append([corpo, corpo.position, Vector3(0, subida, 0), periodo, atraso, 0.2])
	moveis.append(corpo)
	velas.append(corpo)
	return corpo


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


## Dica do Vovô fora de um ponto de dica (a da bola de chiclete), uma vez só.
func _dica_uma_vez(qual: String) -> void:
	if not _dicas_dadas.has(qual):
		_dicas_dadas[qual] = true
		dica.emit(qual)


# --- o marco: o bolo-montanha ---------------------------------------------------------

## Dois andares de bolo flutuando numa nuvem rosa: o de baixo, rosa com recheio creme e escorrido de cobertura, e o de
## cima, creme com faixa rosa e cerejas na beira da arena.
func _bolo() -> void:
	var corpo := StaticBody3D.new()
	add_child(corpo)
	var baixo := TOPO_BOLO + 12.0
	_malha(corpo, _cilindro(RAIO_BOLO, RAIO_BOLO, baixo), Color("f39cc4"), Vector3(0, TOPO_BOLO - baixo * 0.5, 0))
	_malha(corpo, _cilindro(RAIO_BOLO + 0.15, RAIO_BOLO + 0.15, 3.0), Color("ffe08a"), Vector3(0, 8.0, 0))
	_malha(corpo, _cilindro(RAIO_BOLO + 0.1, RAIO_BOLO + 0.1, 0.3), Color("fbc8e0"), Vector3(0, TOPO_BOLO - 0.1, 0))
	var cima := TOPO_ARENA - TOPO_BOLO
	_malha(corpo, _cilindro(RAIO_TOPO, RAIO_TOPO, cima), Color("ffe3a3"), Vector3(0, TOPO_BOLO + cima * 0.5, 0))
	_malha(corpo, _cilindro(RAIO_TOPO + 0.15, RAIO_TOPO + 0.15, 2.4), Color("f37fb4"), Vector3(0, TOPO_BOLO + 6.0, 0))
	_malha(corpo, _cilindro(RAIO_TOPO + 0.1, RAIO_TOPO + 0.1, 0.3), Color("ffffff"), Vector3(0, TOPO_ARENA - 0.1, 0))
	for spec in [[RAIO_BOLO, TOPO_BOLO], [RAIO_TOPO, TOPO_ARENA]]:
		var toro := TorusMesh.new()
		toro.inner_radius = spec[0] - 0.7
		toro.outer_radius = spec[0] + 0.7
		toro.rings = 96
		_malha(corpo, toro, Color("ffffff"), Vector3(0, spec[1], 0))
		# Escorrido de cobertura pela parede.
		var n := int(spec[0] * 1.2)
		for i in n:
			var a := TAU * i / n
			var gota := CapsuleMesh.new()
			gota.radius = 0.55
			gota.height = 1.6 + 1.6 * absf(sin(i * 1.7))
			_malha(corpo, gota, Color("ffffff"), Vector3(cos(a) * (spec[0] + 0.05), spec[1] - gota.height * 0.4, sin(a) * (spec[0] + 0.05)))
	# Cerejas na beira da arena, sólidas: parecem de verdade e fazem uma cerquinha.
	var vermelho := Color("e2304a")
	for i in 12:
		var a := TAU * (i + 0.5) / 12.0
		var bola := SphereMesh.new()
		bola.radius = 0.75
		bola.height = 1.5
		var onde := Vector3(cos(a) * (RAIO_TOPO - 0.9), TOPO_ARENA + 0.6, sin(a) * (RAIO_TOPO - 0.9))
		_malha(corpo, bola, vermelho, onde)
		var cs_cereja := CollisionShape3D.new()
		var esfera := SphereShape3D.new()
		esfera.radius = 0.75
		cs_cereja.shape = esfera
		cs_cereja.position = onde
		corpo.add_child(cs_cereja)
	# A nuvem rosa embaixo do bolo.
	_malha(corpo, _cilindro(RAIO_BOLO + 2.0, 3.0, 16.0), ALGODAO[2], Vector3(0, -12.0 - 8.0, 0))
	for i in 8:
		var a := TAU * i / 8.0
		var nuvem_baixo := MeshInstance3D.new()
		nuvem_baixo.mesh = Forma.superelipsoide(Vector3(9, 4, 9), 1.0, 1.0)
		nuvem_baixo.material_override = _material(ALGODAO[0])
		nuvem_baixo.position = Vector3(cos(a) * 20.0, -13.0, sin(a) * 20.0)
		corpo.add_child(nuvem_baixo)
	for spec in [[RAIO_BOLO, -12.0, TOPO_BOLO], [RAIO_TOPO, TOPO_BOLO, TOPO_ARENA]]:
		var cs := CollisionShape3D.new()
		var forma := CylinderShape3D.new()
		forma.radius = spec[0]
		forma.height = spec[2] - spec[1]
		cs.shape = forma
		cs.position.y = (spec[1] + spec[2]) * 0.5
		corpo.add_child(cs)


# --- 1 · Campo de Algodão ---------------------------------------------------------------

## Playground 1 · Campo de Algodão (apresenta): o campo largo de algodão-doce, com chão embaixo de tudo e nuvens que
## quicam espalhadas (o Vovô mostra o quique logo na chegada). A saída é a ponte para a nuvem-carro, que só sobe com
## os três botões apertados, cada um no alto de um pilar que só se alcança quicando. Mini-marco: o pirulito gigante.
## Bolso: o morro de algodão, com estrelinhas e um coração, e uma roda de estrelinhas atrás do pirulito.
func _campo_de_algodao() -> void:
	playground("1 · Campo de Algodão", CAMPO, 30.0, inicio)
	ilha(CAMPO, 30.0, ALGODAO, 14.0)
	trilha_creme([Vector3(12, 0, 127), Vector3(6, 0, 118), Vector3(-2, 0, 108), Vector3(-12, 0, 101), Vector3(-20, 0, 97.5), Vector3(-27, 0, 95.5)])
	trilha(Vector3(9, 1.0, 121.5), Vector3(-2, 1.0, 108.5), 4)
	trilha(Vector3(-8, 1.0, 103), Vector3(-20, 1.0, 97.5), 3)
	bolota(Vector3(-17, 0, 124), true)

	# O primeiro quique, sem risco: a nuvem com duas estrelinhas no alto do pulo.
	ponto_de_dica(Vector3(7, 0.5, 120), 3.0, "quicar")
	nuvem_que_quica(Vector3(3.5, 1.0, 115.5))
	estrelinha(Vector3(3.5, 3.6, 115.5))
	estrelinha(Vector3(3.5, 5.4, 115.5))

	# Três pilares com um botão em cima de cada, e uma nuvem que quica ao lado de cada pilar.
	ponto_de_dica(Vector3(-12, 0.5, 112), 3.0, "botao")
	var pilares := [[Vector3(-18, 4.5, 116), Vector3(-12.5, 1.0, 117.5), "red"], [Vector3(0, 4.5, 88), Vector3(-1, 1.0, 94.5), "yellow"],
		[Vector3(18, 4.5, 104), Vector3(12.5, 1.0, 102), "blue"]]
	for p in pilares:
		coluna(p[0], 2.6, 6.0, ALGODAO)
		botao(p[0], p[2])
		nuvem_que_quica(p[1])
		arco(p[1] + Vector3(0, 2.0, 0), p[0] + Vector3(0, 1.4, 0), 2.6, 3)
	ponte_dos_botoes([Vector3(-31, 0, 94.5), Vector3(-36.5, 0, 91.5), Vector3(-42, 0, 88.5)])
	for x in [-31.0, -36.5, -42.0]:
		estrelinha(Vector3(x, 1.2, 94.5 + (x + 31.0) * 0.545))
	arco_de_saida(Vector3(-27, 0, 95.5), atan2(-7.0, -2.0), "yellow")
	for p in [Vector3(5, 0, 112.5), Vector3(-3, 0, 103.5), Vector3(-11, 0, 97.5), Vector3(-19, 0, 93.5)]:
		doce("candycane_large", p, PI * 0.6, 2.2)

	# Mini-marco: o pirulito gigante (com o palito sólido), e a roda de estrelinhas atrás dele.
	doce("lollipop_pink", Vector3(-6, 3.9, 84), 0.4, 14.0)
	var palito := StaticBody3D.new()
	palito.position = Vector3(-6, 4.0, 84)
	var cs := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = 0.6
	cil.height = 8.0
	cs.shape = cil
	palito.add_child(cs)
	add_child(palito)
	roda(Vector3(-6, 0.9, 81.5), 2.2, 6)

	# Bolso: o morro de algodão (uma nuvem mais forte leva lá para cima).
	coluna(Vector3(14, 5.5, 90), 4.5, 6.5, ALGODAO)
	nuvem_que_quica(Vector3(8, 1.0, 94), 2.2, 17.0)
	coracao(Vector3(14, 6.9, 90))
	roda(Vector3(14, 6.4, 90), 2.8, 5)

	for spec in [[1, Vector3(-20, 0, 106), 1.3], [4, Vector3(-10, 0, 128), 1.1], [2, Vector3(22, 0, 116), 1.2], [5, Vector3(-14, 0, 88), 1.0]]:
		arvore(spec[0], 8, spec[1], spec[2])
	for spec in [["candy_B_blue", Vector3(16, 0, 122), 4.0], ["candy_A_green", Vector3(-24, 0, 112), 5.0], ["candy_C_yellow", Vector3(5, 0, 96), 5.0],
			["candy_peppermint", Vector3(-14, 0, 122), 4.0], ["present_B_blue", Vector3(26, 0, 104), 3.0], ["gingerbread_man", Vector3(-4, 0.05, 124), 4.0]]:
		doce(spec[0], spec[1], spec[1].x, spec[2])


## Viagem 1: a nuvem-carro, da ponta da ponte até a primeira ilha de biscoito (espera o Faísca subir).
func _viagem_nuvem_carro() -> void:
	nuvem_carro = carona(Vector3(-46.6, 0, 87.6), Vector3(-64.6, 7, 63.2), "nuvem", 3.5)
	for t in [0.25, 0.5, 0.75]:
		estrelinha(nuvem_carro.de.lerp(nuvem_carro.ate, t) + Vector3.UP * 1.6)


# --- 2 · Ilhas de Biscoito ---------------------------------------------------------------

## Playground 2 · Ilhas de Biscoito (desenvolve): seis ilhas de biscoito em alturas diferentes, ligadas por nuvens que
## quicam sobre o vazio, com dois caminhos até a ilha do meio e dois até a ilha do alto. O canhão fica atrás do
## portão, que só abre com as três flores acesas pelo laser: uma em cada ponta (a da direita, a da esquerda e a do
## fundo). Mini-marco: a casinha de gengibre na ilha do meio. Bolso: a beirada embaixo da ilha do meio, com o V1.
func _ilhas_de_biscoito() -> void:
	var ilhas := {
		"chegada": [Vector3(-70, 7, 56), 6.5], "direita": [Vector3(-86, 9, 64), 5.0], "meio": [Vector3(-96, 10, 40), 9.0],
		"esquerda": [Vector3(-78, 8, 36), 5.0], "fundo": [Vector3(-114, 12, 30), 5.0], "alto": [Vector3(-104, 14, 12), 7.0],
	}
	playground("2 · Ilhas de Biscoito", Vector3(-92, 10, 38), 26.0, nuvem_carro.ate)
	for k in ilhas:
		ilha(ilhas[k][0], ilhas[k][1], BISCOITO)
	posto(Vector3(-72, 7, 58.5))
	ponto_de_dica(Vector3(-69, 7.5, 55), 3.5, "laser")

	# As nuvens que ligam as ilhas: `quantas` em fila, da beirada de uma ilha na direção da outra.
	for spec in [["chegada", "direita", 1], ["chegada", "esquerda", 2], ["direita", "meio", 2], ["esquerda", "meio", 1],
			["meio", "fundo", 1], ["meio", "alto", 2], ["fundo", "alto", 1]]:
		var a: Vector3 = ilhas[spec[0]][0]
		var b: Vector3 = ilhas[spec[1]][0]
		var dir := Vector3(b.x - a.x, 0, b.z - a.z).normalized()
		for i in spec[2]:
			var d: float = ilhas[spec[0]][1] + 3.0 + 5.0 * i
			var alto := lerpf(a.y, b.y, 0.3 + 0.25 * i) + 0.3
			var c := Vector3(a.x, alto, a.z) + dir * d
			nuvem_que_quica(c)
			estrelinha(c + Vector3(0, 2.4, 0))

	# As três flores e o portão do canhão.
	for k in ["direita", "esquerda", "fundo"]:
		var p: Vector3 = ilhas[k][0] + Vector3(0.5, 0, 0.5)
		flor(p)
		estrelinha(p + Vector3(0, 2.0, 0))
	var alto: Vector3 = ilhas["alto"][0]
	bloco(Vector3(alto.x, alto.y - 0.5, 1.5), Vector3(4, 1, 9), Color("f2d6a2"))
	portao(Vector3(alto.x, alto.y, 1.5), 0.0)
	ilha(Vector3(alto.x, alto.y, -5.5), 3.0, BISCOITO)
	canhao(Vector3(alto.x, alto.y, -6.0), Vector3(-78, 16.05, -52), "red")
	arco_de_saida(Vector3(alto.x, alto.y, 6.5), 0.0, "red")
	roda(alto + Vector3(0, 1.0, 1.5), 3.0, 5)

	# A ilha do meio: a casinha de gengibre (mini-marco), duas Bolotas e estrelinhas.
	var meio: Vector3 = ilhas["meio"][0]
	doce("gingerbread_house_decorated", meio + Vector3(-3, 0, -3), 0.6, 4.0, true)
	bolota(meio + Vector3(3, 0, 3), false, "pinguim")
	bolota(meio + Vector3(4, 0, -4.5), false, "cogumelo")
	roda(meio + Vector3(1, 1.0, 1), 2.5, 4)
	bolota(ilhas["fundo"][0] + Vector3(1, 0, -2), false, "abelha")

	# Bolso embaixo da ilha do meio: a beirada com o V1 e uma nuvem forte que devolve lá para cima.
	ilha(Vector3(-104, 3, 47), 3.5, BISCOITO)
	vaga_lume(Vector3(-104.8, 4.2, 46.2))
	nuvem_que_quica(Vector3(-101.8, 4.3, 48.8), 1.6, 19.0)
	trilha(Vector3(-102, 9.5, 46), Vector3(-104, 5.0, 47), 3)

	for spec in [["candycane_large", Vector3(-73, 7, 51), 2.0], ["candy_A_pink", Vector3(-66, 7, 59), 3.0], ["cookie", Vector3(-82, 8, 34), 5.0],
			["present_A_red", Vector3(-117, 12, 32), 3.0], ["candy_peppermint", Vector3(-100, 14, 15), 3.0], ["lollipop_blue", Vector3(-88, 10.0, 66), 3.5]]:
		doce(spec[0], spec[1], spec[1].z, spec[2])


# --- 3 · Praça do Carrossel --------------------------------------------------------------

## Playground 3 · Praça do Carrossel (central): a praça redonda de 60 m com o carrossel girando no meio. A máquina de
## chiclete dá o poder da fase, o Balão de Chiclete, e só com ele se sobe até a estação do teleférico, no alto do
## pilar da beirada leste (uma fileira de lampiões aponta para ela). Bolsos: o anel de chiclete lá no alto, com o V2,
## e a aba do telhado do carrossel. Três Bolotas com espaço para o giro forte; coração perto da máquina.
func _praca_do_carrossel() -> void:
	var chegada := Vector3(-78, 16, -52)
	playground("3 · Praça do Carrossel", PRACA, 30.0, chegada)
	ilha(PRACA, 30.0, ALGODAO, 16.0)
	posto(Vector3(-81, 16, -56))
	carrossel = Carrossel.new()
	carrossel.position = PRACA
	add_child(carrossel)
	roda(Vector3(PRACA.x, carrossel.topo_aba() + 1.0, PRACA.z), 6.0, 6)
	_maquina_de_chiclete(Vector3(-56, 16, -64), Vector3(-0.6, 0, 0.8))
	coracao(Vector3(-60, 17.4, -58.5))
	trilha_creme([chegada, Vector3(-70, 16, -57), Vector3(-60, 16, -61.5), Vector3(-52, 16, -67.5), Vector3(-47.5, 16, -73)])
	trilha(Vector3(-75, 17, -55), Vector3(-63, 17, -60), 3)
	for p in [Vector3(-73, 16, -60.5), Vector3(-64, 16, -64.5), Vector3(-55, 16, -70.5), Vector3(-50, 16, -78)]:
		doce("lantern_decorated", p, 0.0, 1.2)
	ponto_de_dica(Vector3(-79, 16.5, -63), 3.0, "agarrar")
	bolota(Vector3(-82, 16, -70), false, "porco")
	bolota(Vector3(-63, 16, -90), false, "caranguejo")
	bolota(Vector3(-77, 16, -92), false, "cogumelo")

	# A estação do teleférico, 10 m acima da praça: só com o balão.
	coluna(Vector3(-44, 26, -76), 4.5, 12.0, ALGODAO)
	arco_de_saida(Vector3(-41.8, 26, -76.6), atan2(45.0, 33.7), "blue")
	trilha(Vector3(-50, 19, -73), Vector3(-46, 25, -75), 3)

	# O anel alto (12 m acima da praça), só com o balão: o V2 na do meio, estrelinhas nas outras.
	for i in 5:
		var a := deg_to_rad(200.0 + i * 35.0)
		var p := PRACA + Vector3(cos(a) * 21.0, 12.0, sin(a) * 21.0)
		ilha(p, 4.0, CHICLETE_ROSA if i % 2 else CHICLETE_AZUL)
		if i == 2:
			vaga_lume(p + Vector3(0, 1.1, 0))
		else:
			roda(p + Vector3(0, 1.0, 0), 1.8, 4)

	for spec in [[2, Vector3(-92, 16, -66), 1.4], [4, Vector3(-90, 16, -94), 1.2], [1, Vector3(-52, 16, -92), 1.3], [5, Vector3(-70, 16, -104), 1.1]]:
		arvore(spec[0], 8, spec[1], spec[2])
	for spec in [["candy_B_blue", Vector3(-88, 16, -78), 4.0], ["present_B_blue", Vector3(-60, 16, -98), 3.0], ["candy_C_yellow", Vector3(-84, 16, -86), 4.0]]:
		doce(spec[0], spec[1], 0.5, spec[2])


## A máquina de chiclete: base vermelha, globo de vidro cheio de bolinhas e a bola grande na frente (`frente`), que
## dá o Balão de Chiclete. Dá para subir nela (o alto é um bom lugar para encher o balão).
func _maquina_de_chiclete(pos: Vector3, frente: Vector3) -> void:
	var corpo := StaticBody3D.new()
	corpo.position = pos
	add_child(corpo)
	var caixa := BoxMesh.new()
	caixa.size = Vector3(2.8, 2.4, 2.8)
	_malha(corpo, caixa, Color("e2304a"), Vector3(0, 1.2, 0))
	var vidro := StandardMaterial3D.new()
	vidro.albedo_color = Color(0.87, 0.96, 1.0, 0.35)
	vidro.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vidro.roughness = 0.05
	vidro.rim_enabled = true
	vidro.rim = 0.8
	var globo := SphereMesh.new()
	globo.radius = 2.3
	globo.height = 4.6
	_malha(corpo, globo, Color.WHITE, Vector3(0, 4.6, 0)).material_override = vidro
	var cores := [Color("ff6fb5"), Color("7fd3ff"), Color("ffd23f"), Color("9be15d"), Color("ff8a45")]
	for i in 22:
		var a := i * 2.4
		var r := 0.7 + (i % 3) * 0.45
		var bolinha := SphereMesh.new()
		bolinha.radius = 0.45
		bolinha.height = 0.9
		_malha(corpo, bolinha, cores[i % 5], Vector3(cos(a) * r, 3.2 + (i % 5) * 0.4, sin(a) * r))
	_malha(corpo, _cilindro(0.8, 1.1, 0.7), Color("e2304a"), Vector3(0, 7.15, 0))
	var boca := BoxMesh.new()
	boca.size = Vector3(0.9, 0.7, 0.4)
	var no_boca := _malha(corpo, boca, Color("ffd23f"), frente.normalized() * 1.45 + Vector3(0, 1.0, 0))
	no_boca.rotation.y = atan2(frente.x, frente.z)
	for spec in [[BoxShape3D.new(), Vector3(0, 1.2, 0)], [SphereShape3D.new(), Vector3(0, 4.6, 0)], [CylinderShape3D.new(), Vector3(0, 7.15, 0)]]:
		var cs := CollisionShape3D.new()
		cs.shape = spec[0]
		if spec[0] is BoxShape3D:
			spec[0].size = Vector3(2.8, 2.4, 2.8)
		elif spec[0] is SphereShape3D:
			spec[0].radius = 2.3
		else:
			spec[0].radius = 1.1
			spec[0].height = 0.7
		cs.position = spec[1]
		corpo.add_child(cs)
	trilha(pos + Vector3(0, 8.4, 0), pos + Vector3(0, 9.6, 0), 2)
	# A bola de chiclete grande, pulando na frente da máquina.
	_bola_de_chiclete = Area3D.new()
	_bola_de_chiclete.position = pos + frente.normalized() * 2.6 + Vector3(0, 1.3, 0)
	_bola_de_chiclete.collision_layer = 0
	_bola_de_chiclete.collision_mask = CAMADA_JOGADOR
	var forma := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = 1.3
	forma.shape = esfera
	_bola_de_chiclete.add_child(forma)
	var bola := SphereMesh.new()
	bola.radius = 0.7
	bola.height = 1.4
	var goma := _malha(_bola_de_chiclete, bola, Color("ff79bd"), Vector3.ZERO)
	(goma.material_override as StandardMaterial3D).roughness = 0.25
	(goma.material_override as StandardMaterial3D).emission_enabled = true
	(goma.material_override as StandardMaterial3D).emission = Color("ff4fa8")
	(goma.material_override as StandardMaterial3D).emission_energy_multiplier = 0.4
	add_child(_bola_de_chiclete)
	var tw := _bola_de_chiclete.create_tween().set_loops()
	tw.tween_property(goma, "position:y", 0.35, 0.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(goma, "position:y", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
	_bola_de_chiclete.body_entered.connect(func(corpo_: Node3D) -> void:
		if corpo_ is Jogador and not balao_pego:
			pegar_balao(corpo_))


## O Faísca pega a bola de chiclete: ganha o Balão de Chiclete até o fim da fase, e o Vovô mostra como usa.
func pegar_balao(j: Jogador) -> void:
	balao_pego = true
	j.balao_de_chiclete = true
	j.robo.expressao("feliz", 1.2)
	Fx.confetti(self, _bola_de_chiclete.global_position, 40, 4.0)
	Sfx.play(self, "bandeira", 0.0, 0.0)
	_bola_de_chiclete.set_deferred("monitoring", false)
	_bola_de_chiclete.hide()
	_dica_uma_vez("balao")


## Viagem 3: o teleférico, da estação no alto do pilar até a primeira ilha do Céu de Chiclete, com o cabo e as duas
## torrinhas. Leva de volta também (atalho).
func _viagem_teleferico() -> void:
	var de := Vector3(-37.6, 26, -76)
	var ate := Vector3(7.46, 14, -42.3)
	teleferico = carona(de, ate, "cabine", 5.0)
	var dir := (ate - de).normalized()
	var ponta_a := de - dir * 3.5 + Vector3.UP * 5.4
	var ponta_b := ate + dir * 3.5 + Vector3.UP * 5.4
	var cabo := MeshInstance3D.new()
	var fio := _cilindro(0.08, 0.08, ponta_a.distance_to(ponta_b))
	cabo.mesh = fio
	cabo.material_override = _material(Color("3a3150"))
	add_child(cabo)
	cabo.look_at_from_position((ponta_a + ponta_b) * 0.5, ponta_b, Vector3.UP)
	cabo.rotate_object_local(Vector3.RIGHT, PI / 2.0)
	for p: Vector3 in [ponta_a, ponta_b]:
		var torre := MeshInstance3D.new()
		torre.mesh = _cilindro(0.25, 0.35, 6.4)
		torre.material_override = _material(Color("6a6478"))
		torre.position = p + Vector3.DOWN * 3.0
		add_child(torre)
	for t in [0.3, 0.55, 0.8]:
		estrelinha(de.lerp(ate, 0.5 - 0.5 * cos(PI * t)) + Vector3.UP * 4.0)


# --- 4 · Céu de Chiclete -----------------------------------------------------------------

## Playground 4 · Céu de Chiclete (reviravolta): ilhas de chiclete subindo em volta do bolo, de 14 a 26 m, ligadas
## por nuvens lilases que quicam e somem (não dá para quicar duas vezes). Com o balão dá para cortar caminho. Bolso:
## a ilha alta com o coração, que só o balão alcança. Três Bolotas nas ilhas estreitas.
func _ceu_de_chiclete() -> void:
	var g0 := no_bolo(70, 40, 14)
	playground("4 · Céu de Chiclete", no_bolo(24, 37, 20), 22.0, teleferico.ate)
	ilha(g0, 6.0, CHICLETE_AZUL)
	posto(g0 + Vector3(1.5, 0, 1.0))
	var ilhas := [[no_bolo(46, 38, 17), 4.0], [no_bolo(22, 37, 20), 4.0], [no_bolo(-2, 36, 23), 4.0], [no_bolo(-26, 34, 26), 5.0]]
	var nuvens := [no_bolo(58, 38, 14.9), no_bolo(34, 37, 17.9), no_bolo(10, 36, 20.9), no_bolo(-14, 35, 23.9)]
	for i in ilhas.size():
		ilha(ilhas[i][0], ilhas[i][1], CHICLETE_ROSA if i % 2 == 0 else CHICLETE_AZUL)
		nuvem_que_quica(nuvens[i], 2.2, 16.0, true)
		estrelinha(nuvens[i] + Vector3(0, 2.6, 0))
		estrelinha(ilhas[i][0] + Vector3(1.5, 1.0, 0))
	# O cacto fica na beirada de fora, longe de onde se pousa (pisar nele espeta).
	bolota(ilhas[0][0] + Vector3(cos(deg_to_rad(46.0)), 0, -sin(deg_to_rad(46.0))) * 2.5, false, "cacto")
	bolota(ilhas[1][0] + Vector3(-1, 0, 1), false, "pinguim")
	bolota(ilhas[2][0], false, "morcego")
	trilha(g0 + Vector3(-1, 1, 1), g0 + Vector3(4, 1, 3), 2)

	# Bolso alto, só com o balão: o coração e uma roda de estrelinhas.
	var bolso := no_bolo(30, 44, 27)
	ilha(bolso, 3.5, CHICLETE_ROSA)
	coracao(bolso + Vector3(0, 1.4, 0))
	roda(bolso + Vector3(0, 1.0, 0), 2.2, 4)

	# A saída: o arco na última ilha e a ponte de wafer até o anel do bolo.
	var g4: Vector3 = ilhas[3][0]
	var ang := atan2(g4.x, g4.z)
	arco_de_saida(no_bolo(-26, 30.5, 26), ang, "green")
	bloco(no_bolo(-26, 26.8, 25.5), Vector3(3.6, 1.0, 7.4), Color("f2d6a2"), ang)
	trilha(no_bolo(-26, 29, 27), no_bolo(-26, 24, 27), 3)


# --- 5 · Subida do Bolo ------------------------------------------------------------------

## Playground 5 · Subida do Bolo (o fim): o anel em cima do andar de baixo do bolo e a subida pela parede do andar de
## cima, no sentido do relógio visto de cima. A cereja do anel joga até o primeiro biscoito preso no bolo; a vela sobe
## até o segundo; depois uma fileira de biscoitos, com uma Bolota no estreito, até a cereja que joga para a arena.
## Quem cai dos biscoitos cai no anel (sem perder coração); a cereja do outro lado do anel devolve lá para cima.
## Segredo: a casinha de biscoito no anel, com a parede rachada (V3).
func _subida_do_bolo() -> void:
	var entrada := no_bolo(-26, 21.5, TOPO_BOLO)
	playground("5 · Subida do Bolo", Vector3(0, 32, 0), 24.0, entrada)
	# O posto fica de lado, fora da linha da ponte.
	posto(no_bolo(-32, 21.0, TOPO_BOLO))
	trilha_creme([no_bolo(-26, 19.5, TOPO_BOLO), no_bolo(-38, 19, TOPO_BOLO), no_bolo(-50, 19, TOPO_BOLO), no_bolo(-58, 19, TOPO_BOLO)])
	for g in [-34.0, -44.0, -54.0]:
		estrelinha(no_bolo(g, 19, TOPO_BOLO + 1.0))
	bolota(no_bolo(-100, 19, TOPO_BOLO), false, "ciclope")

	# Cereja até o primeiro biscoito, a vela que sobe até o segundo e a fileira de biscoitos.
	cereja(no_bolo(-62, 19, TOPO_BOLO), 16.0)
	var biscoitos := [[-75.0, 30.5], [-115.0, 35.0], [-140.0, 35.0], [-165.0, 35.0], [-190.0, 35.0]]
	for b in biscoitos:
		var topo := no_bolo(b[0], 16.2, b[1])
		doce("cube_gingerbread_large_A", topo - Vector3(0, 4.0, 0), deg_to_rad(b[0]), 1.0, true)
		estrelinha(topo + Vector3(0, 1.1, 0))
	vela(no_bolo(-95, 17.5, 30.5), 4.5, 6.0)
	estrelinha(no_bolo(-95, 17.5, 32))
	for par in [[-140.0, -165.0], [-165.0, -190.0]]:
		arco(no_bolo(par[0] - 6.0, 16.2, 36.1), no_bolo(par[1] + 6.0, 16.2, 36.1), 1.6, 2)
	bolota(no_bolo(-140, 16.2, 35.0), false, "pinguim")
	cereja(no_bolo(-190, 16.2, 35.0), 16.0)
	arco(no_bolo(-190, 16.2, 38.5), no_bolo(-190, 10.0, 41.5), 1.5, 3)

	# A cereja do outro lado do anel, para quem caiu, devolve lá para cima (até o quarto biscoito).
	cereja(no_bolo(-160, 20.5, TOPO_BOLO), 22.0)

	# Segredo: a casinha de biscoito encostada no bolo, com a parede rachada virada para quem vem pelo anel.
	_casinha_secreta(no_bolo(-135, 17.0, TOPO_BOLO), deg_to_rad(-135.0))
	ponto_de_dica(no_bolo(-120, 20, TOPO_BOLO + 0.5), 3.0, "golpe")
	coracao(no_bolo(-80, 21, TOPO_BOLO + 1.2))
	for spec in [["present_A_red", -48.0, 22.5], ["candy_A_pink", -110.0, 22.8], ["present_B_blue", -175.0, 22.6], ["candy_peppermint", -210.0, 22.0]]:
		doce(spec[0], no_bolo(spec[1], spec[2], TOPO_BOLO), deg_to_rad(spec[1]), 3.0)


## Casinha de biscoito com a parede da frente rachada (três golpes abrem): dentro, o V3 e estrelinhas. `centro` é o
## meio do chão e `ang_rad` o ângulo dela em volta do bolo (como em `no_bolo`): um lado fica encostado no bolo, e a
## frente aponta no sentido anti-horário do anel, para quem cai dos biscoitos de antes.
func _casinha_secreta(centro: Vector3, ang_rad: float) -> void:
	var raiz := Node3D.new()
	raiz.position = centro
	# +X local para dentro do bolo; +Z local é a frente, no sentido anti-horário do anel (o ângulo crescendo).
	var fora := Vector3(cos(ang_rad), 0, -sin(ang_rad))
	var frente := -fora.cross(Vector3.UP)
	raiz.basis = Basis(-fora, Vector3.UP, frente)
	add_child(raiz)
	var cor := Color("c98a4a")
	for spec in [[Vector3(-2.75, 2.5, 0), Vector3(0.5, 5.0, 5.0)], [Vector3(2.75, 2.5, 0), Vector3(0.5, 5.0, 5.0)],
			[Vector3(0, 2.5, -2.5), Vector3(6.0, 5.0, 0.5)], [Vector3(0, 5.25, 0), Vector3(6.4, 0.5, 5.6)]]:
		var parede := bloco(Vector3.ZERO, spec[1], cor)
		remove_child(parede)
		raiz.add_child(parede)
		parede.position = spec[0]
	var cobertura := BoxMesh.new()
	cobertura.size = Vector3(6.6, 0.3, 5.8)
	_malha(raiz, cobertura, Color("ffffff"), Vector3(0, 5.6, 0))
	var p := ParedeRachada.new()
	p.escala = 1.25
	p.position = Vector3(0, 0, 2.5)
	raiz.add_child(p)
	for mi in p.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = _material(Color("d9a066"))
	paredes_rachadas.append(p)
	paredes_do_bolo.append(p)
	vaga_lume(raiz.to_global(Vector3(0, 1.4, -1.2)))
	for x in [-1.6, 1.6]:
		estrelinha(raiz.to_global(Vector3(x, 1.0, -0.6)))
	estrelinha(raiz.to_global(Vector3(0, 1.0, 1.0)))


# --- arena --------------------------------------------------------------------------

## Arena no topo do bolo (40 m): o baú, três Bolotas e a coluna de luz que aparece da fase toda.
func _arena() -> void:
	var topo := Vector3(0, TOPO_ARENA, 0)
	colocar_bau(topo + Vector3(0, 0, -1.5))
	brilho_de_marco(topo + Vector3(0, 1.5, -1.5), 40.0)
	bolota(topo + Vector3(-5, 0, 4), false, "alien")
	bolota(topo + Vector3(5, 0, 5), false, "porco")
	bolota(topo + Vector3(1, 0, -8), false, "abelha")
	ponto_de_dica(topo + Vector3(-6, 1, -6), 3.0, "giro_forte")
	roda(topo + Vector3(0, 0.9, -1.5), 3.4, 4)
	doce("lollipop_green", topo + Vector3(-9, 2.8, -6), 0.8, 10.0)
	doce("lollipop_blue", topo + Vector3(9, 2.8, -5), -0.6, 10.0)


## Nuvens do Medieval Hexagon espalhadas pelo céu, só de enfeite, longe dos playgrounds e das viagens (uma no
## caminho do teleférico tapava a vista nas primeiras fotos).
func _nuvens_de_enfeite() -> void:
	var gerador := RandomNumberGenerator.new()
	gerador.seed = 22
	var viagens := [[nuvem_carro.de, nuvem_carro.ate], [canhoes[0].global_position, canhoes[0].destino], [teleferico.de, teleferico.ate]]
	for i in 40:
		var p := Vector3(gerador.randf_range(-180, 130), gerador.randf_range(-4, 50), gerador.randf_range(-170, 190))
		var perto := Vector2(p.x, p.z).length() < 55.0
		for pg in playgrounds:
			perto = perto or Vector2(p.x - pg.centro.x, p.z - pg.centro.z).length() < pg.raio + 22.0
		for v in viagens:
			var a := Vector2(v[0].x, v[0].z)
			var b := Vector2(v[1].x, v[1].z)
			var q := Vector2(p.x, p.z)
			perto = perto or q.distance_to(a + (b - a) * clampf((q - a).dot(b - a) / (b - a).length_squared(), 0.0, 1.0)) < 22.0
		if not perto:
			doce("cloud_big" if i % 2 else "cloud_small", p, gerador.randf() * TAU, gerador.randf_range(5.0, 9.0))


# --- céu ----------------------------------------------------------------------------

## Céu de algodão-doce: azul em cima e rosa no horizonte, luz quente.
func _montar_ceu_e_luz() -> void:
	super._montar_ceu_e_luz()
	for we in find_children("*", "WorldEnvironment", false, false):
		var ceu := ((we as WorldEnvironment).environment.sky.sky_material as ProceduralSkyMaterial)
		ceu.sky_top_color = Color("7fb8ff")
		ceu.sky_horizon_color = Color("ffd9ec")
		ceu.ground_horizon_color = Color("ffe3f1")
		ceu.ground_bottom_color = Color("f7c6e0")
		var env := (we as WorldEnvironment).environment
		env.fog_light_color = Color("f1e8ff")
		env.fog_density = 0.0018
		env.ambient_light_energy = 0.62
		env.tonemap_exposure = 0.9
		# Um pouco mais de cor: com o céu claro e o chão rosa, tudo saía desbotado (fotos de 2026-10-30).
		env.adjustment_enabled = true
		env.adjustment_saturation = 1.15


## Mar de nuvens rosadas embaixo da fase toda (a fase vai de z 140 a -110 e de x -125 a 50).
func _montar_nuvens() -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("eef3ff")
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

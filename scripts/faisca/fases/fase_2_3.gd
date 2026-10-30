class_name Fase23
extends Fase
## 2-3 Quarto de Brinquedos (Mundo 2, Doces e Brinquedos; fase de chão). As Bolotas esconderam a quinta Estrela
## Grande no alto da torre de um castelo de blocos, no meio de um quarto de criança, e o Faísca fica pequenininho entre
## os móveis (Furniture Bits e Board Game Bits ampliados). O chão do quarto é a rede de segurança: cair de um móvel só
## faz descer (uma escada de livros leva de volta), menos no tapete de lava do playground 4. Novidade: os dados que
## tombam com um soco (viram degrau). Poder da fase: o Ioiô (no ar, o golpe perto de uma argola laranja puxa até ela).
## Feita em 2026-10-30 a partir da maquete aprovada (docs/level-design/maquete-2-3-quarto-de-brinquedos.html), já no
## tamanho maior (pedido do usuário no mesmo dia): cinco playgrounds em volta do castelo, e cada saída com uma tarefa.
##   1 Tapete da Cidade (no chão, ao sul): o dado tombado vira degrau até a estação alta do trenzinho
##   viagem: o trenzinho, pela ponte de blocos, até o pé da mesa
##   2 Tabuleiro na Mesa (6 m, a oeste): os três dados nas casas brilhantes do tabuleiro chamam o avião de papel; V1
##     embaixo da mesa (P1)
##   viagem: o avião de papel
##   3 Escrivaninha (12 m, ao norte): a caixa de brinquedos dá o ioiô, e só com ele se chega à torre de livros do
##     carrinho; V2 na prateleira alta; o topo do abajur (P2)
##   viagem: o carrinho de corda, pela pista laranja
##   4 O Chão É Lava (a leste): almofadas, cartas que viram e dados que rolam; as três alavancas abaixam a ponte
##     levadiça do castelo (P3)
##   5 Subida do Castelo: o dado do pátio vira degrau até a muralha, e o ioiô puxa até o alto da torre; V3 no bloco
##     rachado da muralha de fora (P4)
##   Arena no alto da torre (22 m): o baú e três Bolotas

const MEIA_SALA := 86.0
const CASTELO := Vector3(10, 0, -8)
const MESA := Vector3(-56, 0, -6)
const ESCRIVANINHA := Vector3(-14, 0, -62)
const TOPO_TABULEIRO := 6.3
const TOPO_ESCRIVANINHA := 12.0
const TOPO_TORRE := 22.0
const BLOCOS := [Color("e94f4f"), Color("3f8fe0"), Color("ffc93a"), Color("4cc27a")]
## O tapete de lava: de x 28 a 64 e de z -50 a 14 (a faixa de 4 m do lado do castelo é chão firme).
const LAVA_CENTRO := Vector3(46, 0, -18)
const LAVA_TAMANHO := Vector2(36, 64)

var trem: Carona
var aviao: Carona
var carrinho_de_corda: Carona
var ponte: PonteLevadica
## Os três dados do tabuleiro e as casas deles (a tarefa do playground 2).
var dados_do_tabuleiro: Array[DadoQueTomba] = []
var casas_do_tabuleiro: Array[Vector3] = []
var _marcas_das_casas: Array[MeshInstance3D] = []
var dado_da_estacao: DadoQueTomba
var dado_do_patio: DadoQueTomba
var lavas: Array[Area3D] = []
var paredes_do_castelo: Array[ParedeRachada] = []
var ioio_pego := false
var aviao_chegou := false
var _bola_de_ioio: Area3D


func _montar() -> void:
	nome = "2-3 Quarto de Brinquedos"
	inicio = Vector3(16, 0.2, 70)
	limite_queda = -5.0
	_quarto()
	_castelo()
	_tapete_da_cidade()
	_viagem_trem()
	_tabuleiro_na_mesa()
	_escrivaninha()
	_viagem_carrinho()
	_chao_e_lava()
	_subida_do_castelo()
	_arena()


# --- peças da fase ------------------------------------------------------------------

func do_quarto(arquivo: String, pos: Vector3, giro := 0.0, escala: Variant = 1.0, solida := true) -> Node3D:
	return peca_de(QUARTO, arquivo, pos, giro, escala, solida)


## Bloco de brinquedo de cantos redondos, com o meio de baixo em `base`.
func bloco(base: Vector3, tamanho: Vector3, cor: Color, solido := true) -> Node3D:
	var corpo: Node3D = StaticBody3D.new() if solido else Node3D.new()
	corpo.position = base + Vector3.UP * tamanho.y * 0.5
	var mi := MeshInstance3D.new()
	mi.mesh = Forma.caixa_redonda(tamanho, minf(0.35, minf(tamanho.x, minf(tamanho.y, tamanho.z)) * 0.15))
	mi.material_override = _material(cor)
	corpo.add_child(mi)
	if solido:
		var cs := CollisionShape3D.new()
		var forma := BoxShape3D.new()
		forma.size = tamanho
		cs.shape = forma
		corpo.add_child(cs)
	add_child(corpo)
	return corpo


## Livro deitado (capa colorida e as folhas creme de um lado), com o meio de baixo em `base`.
func livro(base: Vector3, tamanho: Vector3, cor: Color) -> void:
	bloco(base, tamanho, cor)
	bloco(base + Vector3(0, tamanho.y * 0.12, tamanho.z * 0.06), Vector3(tamanho.x + 0.06, tamanho.y * 0.76, tamanho.z * 0.9), Color("fff6e0"), false)


## Escada de livros: `n` degraus de `subida` m, do chão em `de` andando na direção `dir`, cada um com `fundo` m.
func escada_de_livros(de: Vector3, dir: Vector3, n: int, subida := 1.5, fundo := 3.0, largura := 6.0) -> void:
	var cores := [Color("e94f4f"), Color("3f8fe0"), Color("4cc27a"), Color("ffc93a"), Color("b07cf0")]
	for i in n:
		var p := de + dir * fundo * (i + 0.5)
		var tam := Vector3(largura, subida * (i + 1), fundo) if absf(dir.z) > 0.5 else Vector3(fundo, subida * (i + 1), largura)
		livro(Vector3(p.x, de.y, p.z), tam, cores[i % cores.size()])
		estrelinha(Vector3(p.x, de.y + subida * (i + 1) + 1.0, p.z))


## Marca de chão: um quadrado de contorno (o lugar do dado), com o meio em `centro`.
func marca(centro: Vector3, lado: float, cor: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2(lado, lado)
	mi.mesh = plano
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.emission_enabled = true
	m.emission = cor
	m.emission_energy_multiplier = 0.8
	mi.material_override = m
	mi.position = centro + Vector3.UP * 0.03
	add_child(mi)
	return mi


func _cilindro(r_cima: float, r_baixo: float, altura: float) -> CylinderMesh:
	var cil := CylinderMesh.new()
	cil.top_radius = r_cima
	cil.bottom_radius = r_baixo
	cil.height = altura
	cil.radial_segments = 32
	return cil


func _malha(pai: Node3D, malha: Mesh, cor: Color, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = malha
	mi.material_override = _material(cor)
	mi.position = pos
	pai.add_child(mi)
	return mi


func _dica_uma_vez(qual: String) -> void:
	if not _dicas_dadas.has(qual):
		_dicas_dadas[qual] = true
		dica.emit(qual)


# --- o quarto ----------------------------------------------------------------------

## O chão de tábuas, as quatro paredes (papel de parede azul, rodapé e a janela com a luz do dia) e a cama no canto.
func _quarto() -> void:
	var piso := StaticBody3D.new()
	add_child(piso)
	var tabuas := BoxMesh.new()
	tabuas.size = Vector3(MEIA_SALA * 2.0, 1.0, MEIA_SALA * 2.0)
	_malha(piso, tabuas, Color("d9a066"), Vector3(0, -0.5, 0))
	for i in 22:
		var linha := BoxMesh.new()
		linha.size = Vector3(0.15, 0.02, MEIA_SALA * 2.0)
		_malha(piso, linha, Color("b9824e"), Vector3(-MEIA_SALA + 8.0 * i, 0.005, 0))
	var cs := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tabuas.size
	cs.shape = forma
	cs.position.y = -0.5
	piso.add_child(cs)
	for spec in [[Vector3(0, 30, -MEIA_SALA - 1), Vector3(MEIA_SALA * 2, 60, 2)], [Vector3(0, 30, MEIA_SALA + 1), Vector3(MEIA_SALA * 2, 60, 2)],
			[Vector3(-MEIA_SALA - 1, 30, 0), Vector3(2, 60, MEIA_SALA * 2)], [Vector3(MEIA_SALA + 1, 30, 0), Vector3(2, 60, MEIA_SALA * 2)]]:
		var parede := StaticBody3D.new()
		parede.position = spec[0]
		var caixa := BoxMesh.new()
		caixa.size = spec[1]
		_malha(parede, caixa, Color("cfe8f0"), Vector3.ZERO)
		var pcs := CollisionShape3D.new()
		var pf := BoxShape3D.new()
		pf.size = spec[1]
		pcs.shape = pf
		parede.add_child(pcs)
		add_child(parede)
		var rodape := BoxMesh.new()
		rodape.size = Vector3(spec[1].x + 0.4, 3.0, spec[1].z + 0.4)
		_malha(parede, rodape, Color("ffffff"), Vector3(0, -28.5, 0))
	var janela := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(40, 26)
	janela.mesh = quad
	var luz := StandardMaterial3D.new()
	luz.albedo_color = Color("dff3ff")
	luz.emission_enabled = true
	luz.emission = Color("dff3ff")
	luz.emission_energy_multiplier = 1.4
	janela.material_override = luz
	janela.position = Vector3(44, 34, -MEIA_SALA + 0.05)
	add_child(janela)
	do_quarto("bed_double_A", Vector3(64, 0, 56), PI, Vector3(9.0, 8.0, 14.0))
	do_quarto("armchair", Vector3(-70, 0, 64), 0.6, 7.0)
	do_quarto("rug_oval_A", Vector3(-62, 0, 52), 0.3, Vector3(6.0, 1.0, 6.0), false)
	do_quarto("pictureframe_large_A", Vector3(-30, 30, -MEIA_SALA), 0.0, 10.0, false)


# --- o marco: o castelo de blocos ---------------------------------------------------------

## O castelo no meio do quarto: muralha de blocos de 4 m em dois andares (28 x 28 m), quatro torres redondas com
## telhado e bandeira, e a torre do meio (12 x 12 m, 22 m de altura) com a arena em cima. O portão é o buraco de baixo
## no meio da muralha leste (fechado pela ponte levadiça), e o bloco de baixo da muralha sul, perto do canto leste, é o
## bloco rachado do segredo.
func _castelo() -> void:
	var c := CASTELO
	for i in 7:
		for camada in 2:
			var o := -12.0 + i * 4.0
			var y := camada * 4.0
			bloco(c + Vector3(o, y, -12), Vector3(4, 4, 4), BLOCOS[(i + camada) % 4])
			if not (camada == 0 and i == 4):
				bloco(c + Vector3(o, y, 12), Vector3(4, 4, 4), BLOCOS[(i + camada + 1) % 4])
			if i > 0 and i < 6:
				bloco(c + Vector3(-12, y, o), Vector3(4, 4, 4), BLOCOS[(i + camada + 2) % 4])
				if not (camada == 0 and i == 3):
					bloco(c + Vector3(12, y, o), Vector3(4, 4, 4), BLOCOS[(i + camada + 3) % 4])
	for k in 4:
		var canto := c + Vector3(-12.0 if k % 2 == 0 else 12.0, 0, -12.0 if k < 2 else 12.0)
		var torre := StaticBody3D.new()
		torre.position = canto
		add_child(torre)
		_malha(torre, _cilindro(3.0, 3.0, 15.0), BLOCOS[k], Vector3(0, 7.5, 0))
		_malha(torre, _cilindro(0.05, 3.6, 5.0), BLOCOS[(k + 2) % 4], Vector3(0, 17.5, 0))
		var tcs := CollisionShape3D.new()
		var cil := CylinderShape3D.new()
		cil.radius = 3.0
		cil.height = 15.0
		tcs.shape = cil
		tcs.position.y = 7.5
		torre.add_child(tcs)
		do_quarto(["flag_A_red", "flag_A_blue", "flag_A_yellow", "flag_A_green"][k], canto + Vector3(0, 19.6, 0), 0.0, 3.0, false)
	# A torre do meio, com faixas de blocos e as ameias da arena.
	bloco(c, Vector3(12, TOPO_TORRE, 12), Color("f2e6d0"))
	for k in 5:
		bloco(c + Vector3(0, 3.0 + k * 4.0, 0), Vector3(12.2, 0.5, 12.2), BLOCOS[k % 4], false)
	for k in 8:
		var a := TAU * k / 8.0 + PI / 8.0
		bloco(c + Vector3(cos(a) * 5.0, TOPO_TORRE, sin(a) * 5.0), Vector3(1.6, 1.6, 1.6), BLOCOS[k % 4])


# --- 1 · Tapete da Cidade ---------------------------------------------------------------

## Playground 1 · Tapete da Cidade (apresenta): o tapete de cidade no chão, sem risco. O Vovô mostra a novidade: um
## soco tomba o dado para o lado. A estação do trenzinho fica num bloco de 3,4 m (alto demais para um pulo); tombando
## o dado amarelo até encostar nela, ele vira o degrau. Mini-marco: o foguete de brinquedo. Bolsos: a torre de blocos
## (com outro dado) e a garagem, com o coração.
func _tapete_da_cidade() -> void:
	playground("1 · Tapete da Cidade", Vector3(0, 0, 58), 26.0, inicio)
	do_quarto("rug_rectangle_A", Vector3(0, 0, 58), 0.0, Vector3(18.7, 1.0, 18.0))
	trilha_creme([Vector3(15, 0.1, 68), Vector3(8, 0.1, 62), Vector3(0, 0.1, 57), Vector3(-9, 0.1, 50), Vector3(-14, 0.1, 45.5)])
	trilha(Vector3(12, 1.2, 66), Vector3(-6, 1.2, 52), 5)
	trilha(Vector3(-15.9, 2.9, 44), Vector3(-21.3, 2.9, 44), 3)
	roda(Vector3(10, 1.2, 70), 2.2, 5)
	for p in [Vector3(22, 1.2, 60), Vector3(-26, 1.2, 50), Vector3(0, 1.2, 46)]:
		estrelinha(p)
	bolota(Vector3(-22, 0.1, 58), true, "cogumelo")
	bolota(Vector3(-2, 0.1, 58))

	# A estação alta e o dado que vira degrau (com a marca amarela onde ele tem que parar).
	bloco(Vector3(-28, 0, 44), Vector3(8, 3.4, 6), Color("ffc93a"))
	bloco(Vector3(-28, 3.4, 44), Vector3(8.2, 0.3, 6.2), Color("e94f4f"), false)
	dado_da_estacao = dado(Vector3(-15.9, 0.1, 44), "D6_A_yellow")
	marca(Vector3(-23.1, 0.1, 44), 1.9, Color("ffd23f"))
	ponto_de_dica(Vector3(-12, 0.6, 46), 3.5, "dado")
	estrelinha(Vector3(-23.1, 2.9, 44))
	roda(Vector3(-28, 4.4, 44), 1.6, 4)
	arco_de_saida(Vector3(-30.5, 3.4, 44), PI / 2.0, "red")

	# Mini-marco: o foguete de brinquedo.
	var foguete := StaticBody3D.new()
	foguete.position = Vector3(-6, 0.1, 70)
	add_child(foguete)
	_malha(foguete, _cilindro(2.2, 2.2, 10.0), Color("ffffff"), Vector3(0, 5.6, 0))
	_malha(foguete, _cilindro(0.05, 2.2, 4.0), Color("e94f4f"), Vector3(0, 12.6, 0))
	var janela := SphereMesh.new()
	janela.radius = 0.9
	janela.height = 1.8
	_malha(foguete, janela, Color("7fc8ff"), Vector3(0, 7.5, 2.0))
	for k in 3:
		var a := TAU * k / 3.0
		var aleta := _malha(foguete, BoxMesh.new(), Color("e94f4f"), Vector3(cos(a) * 2.6, 1.6, sin(a) * 2.6))
		(aleta.mesh as BoxMesh).size = Vector3(0.4, 3.0, 2.0)
		aleta.rotation.y = -a
	var fcs := CollisionShape3D.new()
	var fcil := CylinderShape3D.new()
	fcil.radius = 2.4
	fcil.height = 14.0
	fcs.shape = fcil
	fcs.position.y = 7.0
	foguete.add_child(fcs)

	# Bolso: a torre de blocos (outro dado, empurrado duas vezes para o norte, vira o degrau).
	bloco(Vector3(16, 0, 46), Vector3(3, 3.4, 3), Color("3f8fe0"))
	bloco(Vector3(19.5, 0, 46), Vector3(3, 5.0, 3), Color("e94f4f"))
	dado(Vector3(16, 0.1, 52.0), "D6_A_blue")
	roda(Vector3(19.5, 6.0, 46), 1.0, 4)
	estrelinha(Vector3(16, 4.4, 46))

	# Bolso: a garagem de brinquedo, com estrelinhas e o coração lá dentro.
	bloco(Vector3(-20, 0, 69), Vector3(9, 5, 1), Color("ff9f6a"))
	bloco(Vector3(-24, 0, 66), Vector3(1, 5, 7), Color("ff9f6a"))
	bloco(Vector3(-16, 0, 66), Vector3(1, 5, 7), Color("ff9f6a"))
	bloco(Vector3(-20, 5, 66), Vector3(10, 0.8, 8), Color("8a4a2a"))
	trilha(Vector3(-22, 1.2, 66), Vector3(-18, 1.2, 66), 3)
	coracao(Vector3(-20, 1.4, 67.5))

	for spec in [["building_red", Vector3(24, 0.1, 72)], ["building_blue", Vector3(-26, 0.1, 74)], ["building_green", Vector3(24, 0.1, 40)],
			["building_yellow", Vector3(4, 0.1, 74)]]:
		do_quarto(spec[0], spec[1], spec[1].x * 0.1, 4.0)
	for spec in [["meeple_red", Vector3(8, 0.1, 44)], ["meeple_blue", Vector3(-8, 0.1, 64)]]:
		do_quarto(spec[0], spec[1], 0.4, 3.0)


## Viagem 1: o trenzinho, da estação alta pela ponte de blocos até o pé da escada de livros da mesa (leva de volta
## também). O chão do vagão fica 1 m acima dos trilhos.
func _viagem_trem() -> void:
	var caminho := [Vector3(-34.6, 3.4, 44), Vector3(-50, 3.4, 44), Vector3(-57, 3.4, 39), Vector3(-60, 1.0, 31), Vector3(-60, 1.0, 26)]
	trem = carona(caminho[0], caminho[caminho.size() - 1], "trem", 4.0, caminho)
	for i in caminho.size() - 1:
		var a: Vector3 = caminho[i] - Vector3.UP
		var b: Vector3 = caminho[i + 1] - Vector3.UP
		trilhos(a, b)
		var n := int(a.distance_to(b) / 4.0)
		for k in n + 1:
			var p := a.lerp(b, float(k) / maxf(n, 1))
			if p.y > 0.4:
				bloco(Vector3(p.x, 0, p.z), Vector3(1.2, p.y - 0.05, 1.2), BLOCOS[k % 4])
	for t in [0.3, 0.6]:
		estrelinha((caminho[1] as Vector3).lerp(caminho[3], t) + Vector3.UP * 1.8)


# --- 2 · Tabuleiro na Mesa ---------------------------------------------------------------

## Playground 2 · Tabuleiro na Mesa (desenvolve): a escada de livros sobe do trenzinho até a mesa, onde está o jogo
## de tabuleiro aberto. A tarefa: tombar os três dados até as casas brilhantes (cada um de uma cor). Com os três no
## lugar, o avião de papel aparece na beira da mesa. Dado que cai da mesa volta para o lugar dele. Peões são pilares e
## o rei de xadrez é o mini-marco. Bolso: embaixo da mesa, o V1.
func _tabuleiro_na_mesa() -> void:
	playground("2 · Tabuleiro na Mesa", MESA + Vector3(0, TOPO_TABULEIRO, 0), 20.0, trem.ate)
	do_quarto("table_medium_long", MESA, 0.0, Vector3(12.0, 6.0, 15.0))
	do_quarto("board_A", MESA + Vector3(0, 6.0, 0), 0.0, Vector3(3.0, 1.0, 2.4))
	escada_de_livros(Vector3(-58, 0, 21.5), Vector3(0, 0, -1), 4)
	posto(Vector3(-60, TOPO_TABULEIRO, 3.5))

	var t := TOPO_TABULEIRO
	for spec in [[Vector3(-66, t, 2.0), Vector3(-66, t, -5.2), "D6_A_red"], [Vector3(-56, t, -14.0), Vector3(-48.8, t, -14.0), "D6_A_blue"],
			[Vector3(-46, t, 2.0), Vector3(-46, t, -1.6), "D6_A_green"]]:
		var d := dado(spec[0], spec[2])
		d.tombou.connect(_dado_do_tabuleiro_tombou)
		dados_do_tabuleiro.append(d)
		casas_do_tabuleiro.append(spec[1])
		_marcas_das_casas.append(marca(spec[1], 1.9, Color("ffd23f")))
	trilha(Vector3(-58, t + 1.0, 0), Vector3(-58, t + 1.0, -12), 4)
	for i in 3:
		estrelinha(casas_do_tabuleiro[i] + Vector3(0, 3.0, 0))
	roda(Vector3(-66, t + 1.0, -14), 2.0, 4)
	for p in [Vector3(-50, t + 1.0, -6), Vector3(-62, t + 1.0, -16), Vector3(-44, t + 1.0, -8)]:
		estrelinha(p)

	for spec in [["pawn_B_red", Vector3(-70, t, -16)], ["pawn_B_blue", Vector3(-42, t, 4.5)], ["pawn_B_yellow", Vector3(-70, t, 4)], ["pawn_B_green", Vector3(-62, t, -17)]]:
		do_quarto(spec[0], spec[1], 0.0, 4.0)
	do_quarto("chess_white_king", Vector3(-43.5, t, -16.5), 0.3, 5.0)
	bolota(Vector3(-60, t, -8))
	bolota(Vector3(-52, t, -4), false, "pinguim")
	bolota(Vector3(-63, t, -11), false, "caranguejo")

	# Bolso embaixo da mesa: o V1 e estrelinhas (o brilho aparece da beirada).
	vaga_lume(Vector3(-60, 1.2, -10))
	for p in [Vector3(-64, 1.0, -8), Vector3(-56, 1.0, -12), Vector3(-52, 1.0, -6)]:
		estrelinha(p)

	# O avião de papel (escondido até os três dados chegarem) e o arco da beira da mesa.
	arco_de_saida(Vector3(-56, t, -16.8), 0.0, "blue")
	aviao = carona(Vector3(-56, 6.0, -23.8), Vector3(-36, 12.0, -48.5), "aviao", 5.0,
			[Vector3(-56, 6.0, -23.8), Vector3(-52, 12.0, -32), Vector3(-44, 15.0, -40), Vector3(-36, 12.0, -48.5)])
	aviao.visible = false
	aviao.collision_layer = 0
	aviao.process_mode = Node.PROCESS_MODE_DISABLED


func _dado_do_tabuleiro_tombou(d: DadoQueTomba) -> void:
	var i := dados_do_tabuleiro.find(d)
	var casa: Vector3 = casas_do_tabuleiro[i]
	if Vector2(d.global_position.x - casa.x, d.global_position.z - casa.z).length() < 0.3:
		d.travado = true
		(_marcas_das_casas[i].material_override as StandardMaterial3D).albedo_color = Color("5fdc7a")
		(_marcas_das_casas[i].material_override as StandardMaterial3D).emission = Color("5fdc7a")
		Fx.confetti(self, d.global_position + Vector3.UP, 20, 2.5)
		Sfx.play(self, "ui_ok", 0.0, 0.0)
		if dados_do_tabuleiro.all(func(x: DadoQueTomba) -> bool: return x.travado):
			_chamar_aviao()


## Os três dados no lugar: o avião de papel aparece na beira da mesa, com confete.
func _chamar_aviao() -> void:
	aviao_chegou = true
	aviao.visible = true
	aviao.collision_layer = 1
	aviao.process_mode = Node.PROCESS_MODE_INHERIT
	aviao.scale = Vector3.ONE * 0.05
	var tw := aviao.create_tween()
	tw.tween_property(aviao, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Fx.confetti(self, aviao.global_position + Vector3.UP * 2.0, 50, 4.0)
	Sfx.play(self, "bandeira", 0.0, 0.0)


# --- 3 · Escrivaninha -------------------------------------------------------------------

## Playground 3 · Escrivaninha (central): a escrivaninha encostada na parede, a 12 m. A caixa de brinquedos dá o
## poder da fase, o Ioiô. A torre de livros do carrinho (8 m acima da mesa) só se alcança com ele. Bolsos: a
## prateleira alta (três argolas na parede, com o V2) e o topo do abajur (uma escadinha de livros e uma argola).
## Uma escada de livros do chão devolve quem cair.
func _escrivaninha() -> void:
	var e := TOPO_ESCRIVANINHA
	playground("3 · Escrivaninha", ESCRIVANINHA + Vector3(0, e, 0), 24.0, aviao.ate)
	do_quarto("desk_large", ESCRIVANINHA, 0.0, Vector3(12.5, 12.0, 14.7))
	posto(Vector3(-32, e, -55))
	escada_de_livros(Vector3(-42.5, 0, -49), Vector3(0, 0, -1), 8, 1.5, 2.6, 5.0)
	trilha_creme([Vector3(-34, e, -52), Vector3(-24, e, -55.5), Vector3(-12, e, -55), Vector3(-2, e, -56)])
	trilha(Vector3(-30, e + 1.0, -54), Vector3(-6, e + 1.0, -55), 5)
	for p in [Vector3(-36, e + 1.0, -70), Vector3(-20, e + 1.0, -70), Vector3(-8, e + 1.0, -52.5), Vector3(-24, e + 4.0, -63)]:
		estrelinha(p)
	arco(Vector3(-28, e + 2.0, -72), Vector3(-28, 18.5, -75), 1.5, 2)

	# A caixa de brinquedos e o ioiô.
	bloco(Vector3(-24, e, -63), Vector3(5, 3, 4), Color("3f8fe0"))
	bloco(Vector3(-24, e + 3, -63), Vector3(5.3, 0.4, 4.3), Color("ffc93a"), false)
	_bola_de_ioio = Area3D.new()
	_bola_de_ioio.position = Vector3(-24, e + 1.4, -59.5)
	_bola_de_ioio.collision_layer = 0
	_bola_de_ioio.collision_mask = CAMADA_JOGADOR
	var forma := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = 1.3
	forma.shape = esfera
	_bola_de_ioio.add_child(forma)
	var ioio_visual := Node3D.new()
	_bola_de_ioio.add_child(ioio_visual)
	for z in [-0.25, 0.25]:
		var disco := _malha(ioio_visual, _cilindro(0.8, 0.8, 0.35), Color("ff7a22"), Vector3(0, 0, z))
		disco.rotation.x = PI / 2.0
	add_child(_bola_de_ioio)
	var tw := ioio_visual.create_tween().set_loops()
	tw.tween_property(ioio_visual, "rotation:y", TAU, 1.6).from(0.0)
	_bola_de_ioio.body_entered.connect(func(corpo: Node3D) -> void:
		if corpo is Jogador and not ioio_pego:
			pegar_ioio(corpo))
	coracao(Vector3(-28, e + 1.4, -54))

	# A torre de livros do carrinho, com a argola ao lado (tarefa: só com o ioiô).
	for k in 4:
		livro(Vector3(7, e + k * 2.0, -56), Vector3(6, 2.0, 6), [Color("e94f4f"), Color("4cc27a"), Color("3f8fe0"), Color("ffc93a")][k])
	argola_de_ioio(Vector3(3.0, 24.0, -56))
	roda(Vector3(7, 21.0, -56), 1.6, 4)
	arco_de_saida(Vector3(8.5, 20.0, -56), PI / 2.0, "green")
	arco(Vector3(-1, e + 2.0, -56), Vector3(3.0, 25.5, -56), 2.0, 3)

	# Bolso alto: a prateleira na parede, pelas três argolas, com o V2.
	bloco(Vector3(-14, 27.4, -81), Vector3(40, 1.2, 8), Color("c98b55"))
	# A última fica na frente da prateleira e um pouco acima dela: o impulso do fim do puxão leva lá para cima.
	for spec in [Vector3(-28, 18.5, -75), Vector3(-21, 23.5, -75.5), Vector3(-14, 29.0, -75.5)]:
		argola_de_ioio(spec)
	vaga_lume(Vector3(-12, 29.6, -81))
	for x in [-26.0, -20.0, -6.0, 0.0]:
		estrelinha(Vector3(x, 29.6, -81))

	# Bolso: o topo do abajur (uma escadinha de livros até 16,8 m e a argola em cima da tampa).
	do_quarto("lamp_table", Vector3(0, e, -66), 0.0, 9.0)
	var tampa := StaticBody3D.new()
	tampa.position = Vector3(0, e + 9.3, -66)
	_malha(tampa, _cilindro(3.0, 3.0, 0.3), Color("fff2b0"), Vector3.ZERO)
	var tcs := CollisionShape3D.new()
	var tcil := CylinderShape3D.new()
	tcil.radius = 3.0
	tcil.height = 0.3
	tcs.shape = tcil
	tampa.add_child(tcs)
	add_child(tampa)
	livro(Vector3(-15.5, e, -66), Vector3(4, 1.6, 4), Color("b07cf0"))
	livro(Vector3(-11.5, e, -66), Vector3(4, 3.2, 4), Color("e94f4f"))
	livro(Vector3(-7.5, e, -66), Vector3(4, 4.8, 4), Color("3f8fe0"))
	argola_de_ioio(Vector3(-1.5, e + 14.0, -66))
	roda(Vector3(0, e + 10.4, -66), 1.8, 5)

	do_quarto("cup_pencils", Vector3(-34, e, -68), 0.0, 10.0)
	do_quarto("book_set", Vector3(-20, e + 2.0, -71.5), 0.0, 8.0)
	do_quarto("chair_desk_A", Vector3(-20, 0, -42), PI, 8.0)
	bolota(Vector3(-28, e, -66), false, "porco")
	bolota(Vector3(-16, e, -60), false, "cacto")
	bolota(Vector3(-2, e, -60), false, "pinguim")


## A caixa de brinquedos dá o Ioiô: vale até o fim da fase, e o Vovô mostra como usa.
func pegar_ioio(j: Jogador) -> void:
	ioio_pego = true
	j.ioio = true
	j.robo.expressao("feliz", 1.2)
	Fx.confetti(self, _bola_de_ioio.global_position, 40, 4.0)
	Sfx.play(self, "bandeira", 0.0, 0.0)
	_bola_de_ioio.set_deferred("monitoring", false)
	_bola_de_ioio.hide()
	_dica_uma_vez("ioio")


## Viagem 3: o carrinho de corda, do alto da torre de livros pela pista laranja até a primeira almofada da lava.
func _viagem_carrinho() -> void:
	var caminho := [Vector3(12.4, 20, -56), Vector3(22, 16, -60), Vector3(32, 10, -56), Vector3(38, 5, -49), Vector3(40.5, 1.8, -44.6)]
	carrinho_de_corda = carona(caminho[0], caminho[caminho.size() - 1], "carrinho", 6.0, caminho)
	var pontos := PackedVector3Array()
	for p: Vector3 in caminho:
		pontos.append(p + Vector3.DOWN * 1.3)
	var pista := MeshInstance3D.new()
	pista.mesh = Forma.tubo_fechado(pontos, 1.0)
	pista.material_override = _material(Color("ff7a22"))
	add_child(pista)
	for i in range(1, caminho.size() - 1):
		var p: Vector3 = caminho[i]
		bloco(Vector3(p.x, 0, p.z), Vector3(0.8, p.y - 2.3, 0.8), Color("6a6478"), false)
	for t in [0.25, 0.5, 0.75]:
		var a: Vector3 = caminho[1]
		var b: Vector3 = caminho[3]
		estrelinha(a.lerp(b, t) + Vector3.UP * 2.0)


# --- 4 · O Chão É Lava ------------------------------------------------------------------

## Playground 4 · O Chão É Lava (reviravolta): daqui o tapete é lava, de brincadeira (encostar conta como cair). Para
## atravessar há almofadas, cartas que viram sozinhas e um dado que rola. A tarefa: as três alavancas, em três
## almofadas, abaixam a ponte levadiça do castelo. A faixa de chão junto ao castelo é firme.
func _chao_e_lava() -> void:
	playground("4 · O Chão É Lava", LAVA_CENTRO + Vector3(0, 1, 0), 30.0, carrinho_de_corda.ate)
	_lava(LAVA_CENTRO, LAVA_TAMANHO)
	var almofadas := [Vector3(40, 0, -40), Vector3(40, 0, -23), Vector3(61, 0, -23), Vector3(61, 0, -6), Vector3(43, 0, -6), Vector3(35, 0, -8)]
	for i in almofadas.size():
		do_quarto("pillow_A" if i % 2 == 0 else "pillow_B", almofadas[i] + Vector3.UP * 0.9, 0.0, 9.0)
		estrelinha(almofadas[i] + Vector3(1.6, 2.9, 0))
	posto(almofadas[0] + Vector3(-1.0, 1.8, 0.5))
	ponto_de_dica(almofadas[1] + Vector3(0, 2.4, 0), 3.0, "alavanca")
	carta(Vector3(40, 0.6, -31.5), "card_hearts_ace", 0.0)
	carta(Vector3(61, 0.6, -14.5), "card_spades_king", 1.3)
	carta(Vector3(52, 0.6, -6), "card_diamonds_queen", 2.4, PI / 2.0)
	for p in [Vector3(40, 2.2, -31.5), Vector3(61, 2.2, -14.5), Vector3(52, 2.2, -6)]:
		estrelinha(p)
	dado_rolando(Vector3(45, 0.1, -23), Vector3(56, 0.1, -23), 7.0)
	trilha(Vector3(46, 3.8, -23), Vector3(54, 3.8, -23), 3)
	coracao(almofadas[3] + Vector3(-1.5, 3.0, 0))
	bolota(almofadas[2] + Vector3(-1.5, 1.8, 1.0), false, "pinguim")
	bolota(almofadas[4] + Vector3(1.0, 1.8, -0.5), false, "cogumelo")

	# O arco da saída na faixa firme, na frente do portão (a ponte passa por baixo dele).
	arco_de_saida(CASTELO + Vector3(16, 0, 0), PI / 2.0, "yellow")
	trilha(Vector3(30, 1.3, -8), Vector3(25, 1.3, -8), 3)
	# As três alavancas e a ponte levadiça do portão leste.
	ponte = PonteLevadica.new()
	ponte.position = CASTELO + Vector3(14, 0, 0)
	ponte.rotation.y = PI / 2.0
	add_child(ponte)
	var cores := ["red", "yellow", "blue"]
	for k in 3:
		var a := Alavanca.new()
		a.cor = cores[k]
		a.position = almofadas[[1, 2, 3][k]] + Vector3(1.4, 1.8, 0.8)
		add_child(a)
		a.puxada.connect(_alavanca_puxada)
		alavancas.append(a)


func _alavanca_puxada(_a: Alavanca) -> void:
	if alavancas.all(func(x: Alavanca) -> bool: return x.puxada_ja):
		ponte.abaixar()


## O tapete de lava: vermelho e laranja, com manchas que andam devagar. Encostar é cair (volta no posto).
func _lava(centro: Vector3, tamanho: Vector2) -> void:
	var ruido := FastNoiseLite.new()
	ruido.frequency = 0.05
	var textura := NoiseTexture2D.new()
	textura.noise = ruido
	textura.seamless = true
	textura.width = 256
	textura.height = 256
	var rampa := Gradient.new()
	rampa.set_color(0, Color("c2240f"))
	rampa.set_color(1, Color("ffb21e"))
	rampa.add_point(0.55, Color("ff5a1a"))
	textura.color_ramp = rampa
	var m := StandardMaterial3D.new()
	m.albedo_texture = textura
	m.emission_enabled = true
	m.emission_texture = textura
	m.emission_energy_multiplier = 0.9
	m.uv1_scale = Vector3(4, 7, 1)
	m.roughness = 0.9
	var plano := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = tamanho
	plano.mesh = pm
	plano.material_override = m
	plano.position = centro + Vector3.UP * 0.06
	add_child(plano)
	var tw := plano.create_tween().set_loops()
	tw.tween_property(m, "uv1_offset", Vector3(1, 1, 0), 40.0).from(Vector3.ZERO)
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = CAMADA_JOGADOR
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(tamanho.x, 1.2, tamanho.y)
	cs.shape = caixa
	cs.position = centro + Vector3.DOWN * 0.4
	area.add_child(cs)
	add_child(area)
	area.body_entered.connect(func(corpo: Node3D) -> void:
		if corpo is Jogador:
			Fx.confetti(self, corpo.global_position, 20, 3.0)
			(corpo as Jogador).cair())
	lavas.append(area)


# --- 5 · Subida do Castelo --------------------------------------------------------------

## Playground 5 · Subida do Castelo (o fim): pela ponte levadiça, o pátio entre a muralha e a torre do meio. O dado do
## pátio, tombado quatro vezes para o norte, vira o degrau da escada de blocos até o alto da muralha (8 m). Na
## muralha, uma Bolota no estreito; do canto, duas argolas do ioiô puxam até o alto da torre. Segredo: o bloco rachado
## da muralha de fora, no lado sul (V3).
func _subida_do_castelo() -> void:
	var c := CASTELO
	playground("5 · Subida do Castelo", c + Vector3(0, 8, 0), 18.0, c + Vector3(22, 0.5, 0))
	posto(c + Vector3(8, 0, 8.5))
	dado_do_patio = dado(c + Vector3(8, 0, 1.6), "D6_A_green")
	marca(c + Vector3(8, 0, -5.6), 1.9, Color("ffd23f"))
	bloco(c + Vector3(8, 0, -8), Vector3(3, 3.4, 3), BLOCOS[0])
	bloco(c + Vector3(4.5, 0, -8), Vector3(3, 5.0, 3), BLOCOS[1])
	bloco(c + Vector3(1, 0, -8), Vector3(3, 6.6, 3), BLOCOS[2])
	for p in [c + Vector3(8, 4.4, -8), c + Vector3(4.5, 6.0, -8), c + Vector3(1, 7.6, -8)]:
		estrelinha(p)
	trilha(c + Vector3(8, 1.2, 4), c + Vector3(8, 1.2, -4), 3)
	trilha(c + Vector3(-8, 1.2, 4), c + Vector3(-8, 1.2, -6), 3)
	trilha(c + Vector3(-9, 16.5, -7), c + Vector3(-6.8, 23.0, -3.5), 3)
	for p in [c + Vector3(16, 1.2, 6), c + Vector3(16, 1.2, -20), c + Vector3(-16, 1.2, 8)]:
		estrelinha(p)
	coracao(c + Vector3(-8, 1.4, 8))
	bolota(c + Vector3(-5, 8, -12), false, "ciclope")
	bolota(c + Vector3(-8, 0, 0), false, "morcego")
	trilha(c + Vector3(-1, 9.2, -12), c + Vector3(-8, 9.2, -12), 3)
	argola_de_ioio(c + Vector3(-9, 15, -7))
	argola_de_ioio(c + Vector3(-6.8, 24, -3.5))

	# Segredo: o bloco rachado de baixo da muralha sul, perto do canto leste, com o V3 no oco atrás dele.
	var oco := c + Vector3(4, 0, 12)
	var p := ParedeRachada.new()
	p.escala = 1.0
	p.position = oco + Vector3(0, 0, 1.5)
	add_child(p)
	for mi in p.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = _material(Color("ffc93a"))
	paredes_rachadas.append(p)
	paredes_do_castelo.append(p)
	bloco(oco + Vector3(0, 0, -1.75), Vector3(4, 4, 0.5), BLOCOS[2])
	vaga_lume(oco + Vector3(0, 1.4, -0.4))
	for x in [-1.2, 1.2]:
		estrelinha(oco + Vector3(x, 1.0, -0.6))
	ponto_de_dica(oco + Vector3(0, 0.5, 6.0), 3.0, "golpe")


# --- arena --------------------------------------------------------------------------

## Arena no alto da torre (22 m): o baú, três Bolotas e a coluna de luz que aparece do quarto todo.
func _arena() -> void:
	var topo := CASTELO + Vector3(0, TOPO_TORRE, 0)
	colocar_bau(topo + Vector3(0, 0, -0.5))
	brilho_de_marco(topo + Vector3(0, 1.5, -0.5), 34.0)
	bolota(topo + Vector3(-3, 0, 2.5))
	bolota(topo + Vector3(3, 0, -3), false, "porco")
	bolota(topo + Vector3(2.5, 0, 3), false, "abelha")
	ponto_de_dica(topo + Vector3(-3, 1, -3), 2.5, "giro_forte")
	roda(topo + Vector3(0, 0.9, -0.5), 2.8, 4)


# --- luz --------------------------------------------------------------------------

## Quarto de dia: fundo azul-claro, luz ambiente quente e o sol entrando pela janela, com sombra.
func _montar_ceu_e_luz() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("dcefff")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("fff1dc")
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.95
	env.ssao_enabled = true
	env.glow_enabled = true
	env.glow_intensity = 0.4
	env.glow_hdr_threshold = 1.2
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-55, 20, 0)
	sol.light_color = Color("fff3dd")
	sol.light_energy = 1.1
	sol.shadow_enabled = true
	sol.shadow_opacity = 0.7
	sol.directional_shadow_max_distance = 110.0
	add_child(sol)


func _montar_nuvens() -> void:
	pass

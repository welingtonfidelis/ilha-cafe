class_name Fase32
extends Fase
## 3-2 Fábrica de Blocos (Mundo 3, Frio e Vento; fase de chão). Uma fábrica de brinquedos que faz blocos: as Bolotas
## desligaram tudo e penduraram a sétima Estrela Grande no gancho do guindaste, no alto da Máquina de Blocos, no meio do
## galpão. O chão da fábrica é a rede de segurança: cair de uma máquina só faz descer, e um monta-carga laranja leva de
## volta (ele só anda depois que o posto daquele andar acendeu, para o chão não virar atalho). A exceção é a tinta rosa do
## andar da pintura, que conta como cair. Novidades: as esteiras e os blocos-pisca (aparecem e somem no tique-taque).
## Poder da fase: o Martelinho de Apito (no ar, o golpe vira pancada, que afunda os pinos laranja).
## Feita em 2026-10-31 a partir da maquete aprovada (docs/level-design/maquete-3-2-fabrica-de-blocos.html), no tamanho
## maior: cinco playgrounds em volta da máquina, subindo em espiral, e cada saída com uma tarefa.
##   1 Esteiras da Entrada (no chão, ao sul): o soco tomba três blocos de brinquedo para as esteiras, que os levam à
##     recebedora; com as três luzes, a esteira expressa (que até lá anda para baixo) passa a subir
##   viagem: a esteira expressa, até as máquinas
##   2 Blocos-Pisca (8 m, a oeste): três alavancas, cada uma em cima de uma máquina, chamam a ponte rolante; V1 no cano
##     gigante da parede (P1)
##   viagem: o palete da ponte rolante
##   3 Oficina do Martelinho (14 m, ao norte): o martelinho na caixa de ferramentas; três pinos sobem os pistões que viram
##     a escada até a estante da empilhadeira; o quarto pino liga o pistão alto do V2 (P2)
##   viagem: a empilhadeira, pela passarela alta
##   4 Andar da Pintura (20 m, a leste): o chão é tinta; latas de ilha, esteiras e blocos-pisca; o pino de cada lata sobe
##     um vão da ponte de blocos (P3)
##   5 Subida da Máquina (do anel a 26 m até o topo a 44 m): um pino em cada canto sobe o pistão seguinte; V3 atrás do
##     painel rachado (P4)
##   Arena no topo: o baú, três Bolotas (uma de capacete) e o guindaste

const PISO_X := Vector2(-134, 140)
const PISO_Z := Vector2(-126, 150)
const ALTURA_PAREDE := 60.0
## A Máquina de Blocos: a parte de baixo (34 x 34 m) vai até o anel, a de cima (20 x 20 m) até o topo.
const ANEL := 26.0
const TOPO := 44.0
const MEIA_BAIXA := 17.0
const MEIA_ALTA := 10.0
const TOPO_MAQUINAS := 8.0
const TOPO_OFICINA := 14.0
const TOPO_PINTURA := 20.0
## As três esteiras da entrada, rentes ao chão (no x de cada uma), de z 86 (a recebedora) até z 110.
const ESTEIRAS_DA_ENTRADA := [-14.0, 0.0, 14.0]
const Z_RECEBEDORA := 86.0
const VELOCIDADE_ESTEIRA := 2.5
## A esteira expressa: seis esteiras em linha, do chão da entrada até a beira sul da máquina A (8 m). Antes da tarefa
## ela anda para baixo, mais rápido do que o Faísca corre.
const EXPRESSA_FIM := Vector3(-64, TOPO_MAQUINAS, 68)
const EXPRESSA_UNIDADES := 6
const EXPRESSA_DESCE := -9.0
const EXPRESSA_SOBE := 4.0
## A ponte de blocos até o anel: o começo firme na faixa de saída e os três vãos, cada um com o topo 1,5 m acima do outro.
const PONTE_Z := 4.0
const VAOS := [[56.0, 43.0, 21.5], [43.0, 30.0, 23.0], [30.0, 17.0, 24.5]]
const LADO_DA_PONTE := 4.33
const CORES := [Color("e94f4f"), Color("3f8fe0"), Color("4cc27a"), Color("ffc93a")]
const BLOCOS_COR := ["red", "blue", "green"]

var expressa: Array[Esteira] = []
var blocos_da_entrada: Array[DadoQueTomba] = []
var entregues := 0
var ponte_rolante: Carona
var empilhadeira: Carona
var montacargas: Array[Carona] = []
var martelinho_pego := false
var pinos_da_oficina: Array[Pino] = []
var pistoes_da_oficina: Array[Pistao] = []
var pino_secreto: Pino
var pistao_alto: Pistao
var pinos_da_pintura: Array[Pino] = []
var vaos_da_ponte: Array[AnimatableBody3D] = []
var pinos_da_subida: Array[Pino] = []
var pistoes_da_subida: Array[Pistao] = []
var tintas: Array[Area3D] = []
var parede_secreta: ParedeRachada
var _luzes: Array[StandardMaterial3D] = []
var _area_martelo: Area3D
var _martelo_visual: Node3D
var _viga: Node3D
var _cabo: MeshInstance3D
var _engrenagem: Node3D
var _estrela_do_gancho: Node3D
var _cabeca_impressora: Node3D
var _tique := -1
var _mats := {}


func _montar() -> void:
	nome = "3-2 Fábrica de Blocos"
	inicio = Vector3(12, 0.2, 130)
	limite_queda = -5.0
	_galpao()
	_maquina_de_blocos()
	_esteiras_da_entrada()
	_esteira_expressa()
	_blocos_pisca()
	_viagem_ponte_rolante()
	_oficina()
	_viagem_empilhadeira()
	_andar_da_pintura()
	_ponte_de_blocos()
	_subida_da_maquina()
	_arena()


# --- peças da fase ------------------------------------------------------------------

func _mat(cor: Color, rugosidade := 0.6) -> StandardMaterial3D:
	var chave := "%s/%s" % [cor.to_html(), rugosidade]
	if not _mats.has(chave):
		var m := StandardMaterial3D.new()
		m.albedo_color = cor
		m.roughness = rugosidade
		_mats[chave] = m
	return _mats[chave]


## Caixa sólida com o meio em `centro` (`canto` > 0 arredonda as quinas).
func caixa_solida(centro: Vector3, tamanho: Vector3, material: Material, canto := 0.0) -> StaticBody3D:
	var corpo := StaticBody3D.new()
	corpo.position = centro
	var mi := MeshInstance3D.new()
	if canto > 0.0:
		mi.mesh = Forma.caixa_redonda(tamanho, canto)
	else:
		var b := BoxMesh.new()
		b.size = tamanho
		mi.mesh = b
	mi.material_override = material
	corpo.add_child(mi)
	var cs := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tamanho
	cs.shape = forma
	corpo.add_child(cs)
	add_child(corpo)
	return corpo


## Só o desenho de uma caixa (faixas, detalhes rentes ao que já é sólido).
func caixa_visual(centro: Vector3, tamanho: Vector3, material: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = tamanho
	mi.mesh = b
	mi.material_override = material
	mi.position = centro
	add_child(mi)
	return mi


## Bloco do Block Bits (`nome` sem ".gltf") com o meio em `centro`, de `lado` m, sólido como uma caixa.
func bloco(nome_do: String, centro: Vector3, lado: float, giro := 0.0) -> StaticBody3D:
	var corpo := StaticBody3D.new()
	corpo.position = centro
	corpo.rotation.y = giro
	var m: Node3D = _cena(FABRICA + nome_do + ".gltf").instantiate()
	m.scale = Vector3.ONE * lado * 0.5
	corpo.add_child(m)
	var cs := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3.ONE * lado
	cs.shape = forma
	corpo.add_child(cs)
	add_child(corpo)
	return corpo


## Máquina da fábrica: corpo de aço do chão (`base`) até `topo`, tampo claro e uma faixa colorida perto do alto.
func maquina(centro_topo: Vector3, largura: float, fundo: float, faixa: Color, base := 0.0) -> StaticBody3D:
	var altura := centro_topo.y - base
	var corpo := caixa_solida(Vector3(centro_topo.x, base + (altura - 0.3) * 0.5, centro_topo.z), Vector3(largura, altura - 0.3, fundo), _mat(Color("8ea4c9"), 0.5))
	caixa_solida(Vector3(centro_topo.x, centro_topo.y - 0.15, centro_topo.z), Vector3(largura + 0.3, 0.3, fundo + 0.3), _mat(Color("dfe6f2"), 0.7))
	caixa_visual(Vector3(centro_topo.x, centro_topo.y - 2.0, centro_topo.z), Vector3(largura + 0.08, 1.1, fundo + 0.08), _mat(faixa))
	return corpo


## Viga firme e reta (o topo em `a.y`), de `a` até `b`.
func passarela(a: Vector3, b: Vector3, largura := 2.4) -> StaticBody3D:
	var d := b - a
	var comprimento := Vector2(d.x, d.z).length()
	var corpo := caixa_solida((a + b) * 0.5 - Vector3(0, 0.25, 0), Vector3(largura, 0.5, comprimento), _mat(Color("aab6cc"), 0.5))
	corpo.rotation.y = atan2(d.x, d.z)
	return corpo


## Corrimão sólido (1,1 m) de `de` até `ate`, em pé na altura `y`.
func corrimao(de: Vector2, ate: Vector2, y: float) -> void:
	var d := ate - de
	var corpo := StaticBody3D.new()
	corpo.position = Vector3((de.x + ate.x) * 0.5, y, (de.y + ate.y) * 0.5)
	corpo.rotation.y = atan2(d.x, d.y)
	add_child(corpo)
	var ferro := _mat(Color("55607a"), 0.4)
	var barra := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.18, 0.16, d.length())
	barra.mesh = b
	barra.material_override = ferro
	barra.position.y = 1.02
	corpo.add_child(barra)
	var n := maxi(1, roundi(d.length() / 3.0))
	for i in n + 1:
		var poste := MeshInstance3D.new()
		var p := BoxMesh.new()
		p.size = Vector3(0.14, 1.1, 0.14)
		poste.mesh = p
		poste.material_override = ferro
		poste.position = Vector3(0, 0.55, -d.length() * 0.5 + d.length() * i / n)
		corpo.add_child(poste)
	var cs := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(0.2, 1.1, d.length())
	cs.shape = forma
	cs.position.y = 0.55
	corpo.add_child(cs)


## Monta-carga laranja do chão `chao` até `ate_y`, virado com a frente aberta para `giro`. Só anda depois que o posto
## `posto_do_andar` acende (o caminho de volta de quem caiu, que não serve de atalho antes da hora).
func monta_carga(chao: Vector3, ate_y: float, giro: float, posto_do_andar: Posto) -> Carona:
	var c := Carona.new()
	c.de = chao
	c.ate = Vector3(chao.x, ate_y, chao.z)
	c.tipo = "montacarga"
	c.velocidade = 4.0
	c.giro_fixo = giro
	c.travada = not posto_do_andar.acendido
	c.position = chao
	add_child(c)
	caronas.append(c)
	montacargas.append(c)
	posto_do_andar.aceso.connect(func(_p: Posto) -> void: c.travada = false)
	# As duas colunas do poço, dos lados fechados, e a trave lá em cima.
	var lado := Basis(Vector3.UP, giro) * Vector3(2.05, 0, 0)
	for s in [-1.0, 1.0]:
		var pe: Vector3 = chao + lado * s
		caixa_solida(Vector3(pe.x, (ate_y + 3.2) * 0.5, pe.z), Vector3(0.4, ate_y + 3.2, 0.4), _mat(Color("55607a"), 0.4))
	so_enfeite(caixa_visual(Vector3(chao.x, ate_y + 3.3, chao.z), Vector3(4.5, 0.4, 0.4), _mat(Color("55607a"), 0.4))).rotation.y = giro
	return c


func _dica_uma_vez(qual: String) -> void:
	if not _dicas_dadas.has(qual):
		_dicas_dadas[qual] = true
		dica.emit(qual)


# --- o galpão ------------------------------------------------------------------------

## O chão de concreto em placas (com os buracos das três esteiras da entrada, que ficam rentes a ele), as quatro
## paredes altas com janelões e uns montes de blocos encostados nelas.
func _galpao() -> void:
	var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
	img.fill(Color("c9d1de"))
	for i in 64:
		for k in [0, 63]:
			img.set_pixel(i, k, Color("a7b2c4"))
			img.set_pixel(k, i, Color("a7b2c4"))
	var piso := StandardMaterial3D.new()
	piso.albedo_texture = ImageTexture.create_from_image(img)
	piso.uv1_triplanar = true
	piso.uv1_scale = Vector3.ONE * 0.125
	piso.roughness = 0.85
	var x0 := PISO_X.x
	var x1 := PISO_X.y
	var furos := [-16.1, -11.9, -2.1, 2.1, 11.9, 16.1]
	var faixas := [Rect2(x0, PISO_Z.x, x1 - x0, Z_RECEBEDORA - PISO_Z.x), Rect2(x0, 110, x1 - x0, PISO_Z.y - 110),
		Rect2(x0, Z_RECEBEDORA, furos[0] - x0, 110 - Z_RECEBEDORA), Rect2(furos[1], Z_RECEBEDORA, furos[2] - furos[1], 110 - Z_RECEBEDORA),
		Rect2(furos[3], Z_RECEBEDORA, furos[4] - furos[3], 110 - Z_RECEBEDORA), Rect2(furos[5], Z_RECEBEDORA, x1 - furos[5], 110 - Z_RECEBEDORA)]
	for r: Rect2 in faixas:
		caixa_solida(Vector3(r.position.x + r.size.x * 0.5, -0.5, r.position.y + r.size.y * 0.5), Vector3(r.size.x, 1.0, r.size.y), piso)
	var parede := _mat(Color("b9c5d8"), 0.9)
	var meio_x := (x0 + x1) * 0.5
	var meio_z := (PISO_Z.x + PISO_Z.y) * 0.5
	for spec in [[Vector3(meio_x, ALTURA_PAREDE * 0.5, PISO_Z.x - 1), Vector3(x1 - x0 + 4, ALTURA_PAREDE, 2)],
			[Vector3(meio_x, ALTURA_PAREDE * 0.5, PISO_Z.y + 1), Vector3(x1 - x0 + 4, ALTURA_PAREDE, 2)],
			[Vector3(x0 - 1, ALTURA_PAREDE * 0.5, meio_z), Vector3(2, ALTURA_PAREDE, PISO_Z.y - PISO_Z.x)],
			[Vector3(x1 + 1, ALTURA_PAREDE * 0.5, meio_z), Vector3(2, ALTURA_PAREDE, PISO_Z.y - PISO_Z.x)]]:
		caixa_solida(spec[0], spec[1], parede)
		var faixa: Vector3 = spec[1] + Vector3(0.2, 0, 0.2)
		faixa.y = 3.0
		caixa_visual(Vector3(spec[0].x, 1.5, spec[0].z), faixa, _mat(Color("3f8fe0")))
	# Janelões altos, com a luz do dia (enfeite na parede).
	var luz := StandardMaterial3D.new()
	luz.albedo_color = Color("eef7ff")
	luz.emission_enabled = true
	luz.emission = Color("e6f3ff")
	luz.emission_energy_multiplier = 1.3
	for i in 9:
		for spec in [[Vector3(-112 + i * 28, 40, PISO_Z.x + 0.05), 0.0], [Vector3(-112 + i * 28, 40, PISO_Z.y - 0.05), PI],
				[Vector3(x0 + 0.05, 40, -100 + i * 28), PI / 2.0], [Vector3(x1 - 0.05, 40, -100 + i * 28), -PI / 2.0]]:
			var janela := MeshInstance3D.new()
			var q := QuadMesh.new()
			q.size = Vector2(18, 12)
			janela.mesh = q
			janela.material_override = luz
			janela.position = spec[0]
			janela.rotation.y = spec[1]
			add_child(so_enfeite(janela))
	# O portão grande da entrada, na parede sul (pintado na parede).
	caixa_visual(Vector3(12, 9, PISO_Z.y - 0.1), Vector3(20, 18, 0.2), _mat(Color("55607a"), 0.5))
	caixa_visual(Vector3(12, 9, PISO_Z.y - 0.15), Vector3(17, 16, 0.2), _mat(Color("7f93b8"), 0.5))
	# Montes de blocos e caixotes encostados nas paredes, longe dos caminhos.
	for spec in [[Vector3(118, 0, 132), "crate"], [Vector3(-118, 0, 134), "battery"], [Vector3(124, 0, -110), "metal"],
			[Vector3(-30, 0, -116), "crate"], [Vector3(40, 0, 136), "striped_block_blue"], [Vector3(-60, 0, 136), "metalframe"]]:
		var p: Vector3 = spec[0]
		bloco(spec[1], p + Vector3(0, 2.0, 0), 4.0)
		bloco(spec[1], p + Vector3(4.2, 2.0, 0.5), 4.0, 0.2)
		bloco(spec[1], p + Vector3(2.0, 6.0, 0.2), 4.0, -0.15)


# --- o marco: a Máquina de Blocos ------------------------------------------------------

## A Máquina de Blocos no meio do galpão: a parte de baixo, com colunas de blocos coloridos nos cantos, a engrenagem
## grande na frente e o anel em cima (26 m, com corrimão); a parte de cima, com a salinha do segredo atrás do painel
## rachado no lado oeste; e o topo (44 m), com corrimão e o guindaste, que segura a Estrela Grande no gancho.
func _maquina_de_blocos() -> void:
	var aco := _mat(Color("7f93b8"), 0.45)
	var aco_claro := _mat(Color("93a6c7"), 0.45)
	var tampo := _mat(Color("dfe6f2"), 0.7)
	caixa_solida(Vector3(0, (ANEL - 0.4) * 0.5, 0), Vector3(MEIA_BAIXA * 2, ANEL - 0.4, MEIA_BAIXA * 2), aco)
	caixa_solida(Vector3(0, ANEL - 0.2, 0), Vector3(MEIA_BAIXA * 2 + 0.4, 0.4, MEIA_BAIXA * 2 + 0.4), tampo)
	# A parte de cima, com a salinha (x -10 a -6, z 2 a 6, do anel até 30 m) fechada pelo painel rachado.
	var meio := (ANEL + TOPO - 0.4) * 0.5
	var alto := TOPO - 0.4 - ANEL
	caixa_solida(Vector3(2, meio, 0), Vector3(16, alto, 20), aco_claro)
	caixa_solida(Vector3(-8, meio, -4), Vector3(4, alto, 12), aco_claro)
	caixa_solida(Vector3(-8, meio, 8), Vector3(4, alto, 4), aco_claro)
	caixa_solida(Vector3(-8, (ANEL + 4.0 + TOPO - 0.4) * 0.5, 4), Vector3(4, TOPO - 0.4 - ANEL - 4.0, 4), aco_claro)
	caixa_solida(Vector3(0, TOPO - 0.2, 0), Vector3(MEIA_ALTA * 2 + 0.4, 0.4, MEIA_ALTA * 2 + 0.4), tampo)
	var janelas := StandardMaterial3D.new()
	janelas.albedo_color = Color("cfe6f7")
	janelas.emission_enabled = true
	janelas.emission = Color("bfe0ff")
	janelas.emission_energy_multiplier = 0.4
	caixa_visual(Vector3(0, 36.5, 0), Vector3(MEIA_ALTA * 2 + 0.1, 3.0, MEIA_ALTA * 2 + 0.1), janelas)
	# Colunas de blocos coloridos nos quatro cantos da parte de baixo.
	var nomes := ["colored_block_red", "colored_block_blue", "colored_block_green"]
	for k in 4:
		var canto := Vector2(-1.0 if k % 2 == 0 else 1.0, -1.0 if k < 2 else 1.0) * (MEIA_BAIXA - 1.9)
		for andar in 6:
			bloco(nomes[(k + andar) % 3], Vector3(canto.x, 2.1 + andar * 4.2, canto.y), 4.2)
	for z in [-6.0, 6.0]:
		var cano := StaticBody3D.new()
		cano.position = Vector3(-MEIA_BAIXA - 0.7, (ANEL - 0.4) * 0.5, z)
		var cil := CylinderMesh.new()
		cil.top_radius = 0.8
		cil.bottom_radius = 0.8
		cil.height = ANEL - 0.4
		var mi := MeshInstance3D.new()
		mi.mesh = cil
		mi.material_override = _mat(Color("4cc27a"), 0.4)
		cano.add_child(mi)
		var cs := CollisionShape3D.new()
		var forma := CylinderShape3D.new()
		forma.radius = 0.8
		forma.height = cil.height
		cs.shape = forma
		cano.add_child(cs)
		add_child(cano)
	# A engrenagem grande na frente (sul), girando devagar, lá no alto (enfeite).
	_engrenagem = so_enfeite(Node3D.new())
	_engrenagem.position = Vector3(0, 14, MEIA_BAIXA + 0.45)
	add_child(_engrenagem)
	var dourado := _mat(Color("ffd9a8"), 0.4)
	var aro := MeshInstance3D.new()
	var toro := TorusMesh.new()
	toro.inner_radius = 3.9
	toro.outer_radius = 5.3
	aro.mesh = toro
	aro.material_override = dourado
	aro.rotation.x = PI / 2.0
	_engrenagem.add_child(aro)
	for d in 10:
		var dente := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(1.3, 1.6, 0.8)
		dente.mesh = b
		dente.material_override = dourado
		var a := TAU * d / 10.0
		dente.position = Vector3(cos(a) * 5.8, sin(a) * 5.8, 0)
		dente.rotation.z = a + PI / 2.0
		_engrenagem.add_child(dente)
	# Corrimão do anel (com a passagem da ponte, a leste) e do topo.
	var m := MEIA_BAIXA - 0.1
	corrimao(Vector2(-m, -m), Vector2(m, -m), ANEL)
	corrimao(Vector2(-m, -m), Vector2(-m, m), ANEL)
	corrimao(Vector2(-m, m), Vector2(m, m), ANEL)
	corrimao(Vector2(m, m), Vector2(m, PONTE_Z + 3.0), ANEL)
	corrimao(Vector2(m, PONTE_Z - 3.0), Vector2(m, -m), ANEL)
	var t := MEIA_ALTA + 0.1
	corrimao(Vector2(-t, -t), Vector2(t, -t), TOPO)
	corrimao(Vector2(-t, -t), Vector2(-t, t), TOPO)
	corrimao(Vector2(-t, t), Vector2(t, t), TOPO)
	corrimao(Vector2(t, t), Vector2(t, -t), TOPO)
	# O guindaste: o mastro é sólido (fica na arena); a lança, o contrapeso, a cabine e o gancho ficam lá no alto.
	caixa_solida(Vector3(-7, TOPO + 11, -7), Vector3(1.6, 22, 1.6), _mat(Color("3f4c6b"), 0.4))
	var guindaste := so_enfeite(Node3D.new())
	add_child(guindaste)
	var lanca := MeshInstance3D.new()
	var bl := BoxMesh.new()
	bl.size = Vector3(1.2, 1.2, 34)
	lanca.mesh = bl
	lanca.material_override = _mat(Color("3f4c6b"), 0.4)
	lanca.position = Vector3(-3, TOPO + 22.6, -3)
	lanca.rotation.y = PI / 4.0
	guindaste.add_child(lanca)
	for spec in [[Vector3(-14, TOPO + 21.2, -14), Vector3(3, 2.4, 3), Color("55607a")], [Vector3(-7, TOPO + 19.6, -4.8), Vector3(2.6, 2.6, 2.4), Color("cfe6f7")],
			[Vector3(0, TOPO + 14.0, 2), Vector3(1.4, 1.2, 1.4), Color("ff7a22")]]:
		var mi := MeshInstance3D.new()
		var bb := BoxMesh.new()
		bb.size = spec[1]
		mi.mesh = bb
		mi.material_override = _mat(spec[2], 0.5)
		mi.position = spec[0]
		guindaste.add_child(mi)
	var cabo := MeshInstance3D.new()
	var cc := CylinderMesh.new()
	cc.top_radius = 0.08
	cc.bottom_radius = 0.08
	cc.height = 8.0
	cabo.mesh = cc
	cabo.material_override = _mat(Color("2b2140"))
	cabo.position = Vector3(0, TOPO + 18.6, 2)
	guindaste.add_child(cabo)
	# A Estrela Grande pendurada no gancho (some quando o baú abre e a de verdade sobe).
	_estrela_do_gancho = so_enfeite(_cena(PLATAFORMA + "star_yellow.gltf").instantiate())
	_estrela_do_gancho.scale = Vector3.ONE * 4.0
	_estrela_do_gancho.position = Vector3(0, TOPO + 10.5, 2)
	add_child(_estrela_do_gancho)


# --- 1 · Esteiras da Entrada ------------------------------------------------------------

## Playground 1 · Esteiras da Entrada (apresenta): o chão da fábrica, logo depois do portão, sem risco. Três esteiras
## rentes ao chão levam até a recebedora (andar contra elas é devagar). A tarefa: os três blocos de brinquedo fora do
## lugar, um ao lado de cada esteira; o soco tomba o bloco até a esteira, ela o leva para a recebedora, que acende uma
## luz. Com as três luzes, a esteira expressa passa a subir. Mini-marco: a torre de blocos. Bolsos: a escada de
## caixotes até a prateleira do coração, e o nicho atrás da torre, por uma esteira.
func _esteiras_da_entrada() -> void:
	playground("1 · Esteiras da Entrada", Vector3(0, 0, 104), 30.0, inicio)
	trilha_creme([Vector3(12, 0.1, 126), Vector3(6, 0.1, 119), Vector3(-6, 0.1, 117), Vector3(-19, 0.1, 114), Vector3(-26, 0.1, 106),
			Vector3(-29.5, 0.1, 102.5)])
	ponto_de_dica(Vector3(5, 0.5, 116), 4.0, "esteira")
	# A recebedora (8 m), com uma boca escura e uma luz em cima para cada esteira.
	maquina(Vector3(0, TOPO_MAQUINAS, Z_RECEBEDORA - 4.0), 52, 8, CORES[1])
	for i in 3:
		var x: float = ESTEIRAS_DA_ENTRADA[i]
		caixa_visual(Vector3(x, 2.4, Z_RECEBEDORA + 0.03), Vector3(5.0, 4.6, 0.1), _mat(Color("1d2340")))
		for k in 3:
			esteira(Vector3(x, 0.0, 106.0 - k * 8.0), PI, VELOCIDADE_ESTEIRA, "blue", true)
		var lampada := MeshInstance3D.new()
		var esfera := SphereMesh.new()
		esfera.radius = 0.9
		esfera.height = 1.8
		lampada.mesh = esfera
		var m := StandardMaterial3D.new()
		m.albedo_color = Color("d9dde8")
		m.emission_enabled = true
		m.emission = Color("ffe28a")
		m.emission_energy_multiplier = 0.0
		lampada.material_override = m
		lampada.position = Vector3(x, TOPO_MAQUINAS + 0.9, Z_RECEBEDORA - 2.0)
		add_child(so_enfeite(lampada))
		_luzes.append(m)
		for z in [106.0, 98.0, 90.0]:
			estrelinha(Vector3(x, 1.3, z))
	# Os três blocos fora do lugar, cada um a duas tombadas (2,6 m cada) a leste da sua esteira.
	for spec in [[Vector3(-8.8, 0, 102), "colored_block_red"], [Vector3(5.2, 0, 98), "colored_block_green"], [Vector3(19.2, 0, 104), "colored_block_blue"]]:
		var d := DadoQueTomba.new()
		d.pasta = FABRICA
		d.lado_modelo = 2.0
		d.lado = 2.6
		d.modelo = spec[1]
		d.position = spec[0] + Vector3.UP * 1.3
		add_child(d)
		dados.append(d)
		blocos_da_entrada.append(d)
		d.tombou.connect(_bloco_tombou)
	ponto_de_dica(Vector3(-4, 0.5, 104), 3.5, "dado")

	# Mini-marco: a torre de blocos; atrás dela, a esteira que entra no nicho (bolso), com estrelinhas lá dentro.
	var torre := ["decorative_block_red", "decorative_block_blue", "decorative_block_green", "decorative_block_red"]
	for i in 4:
		bloco(torre[i], Vector3(30, 2.25 + i * 4.5, 102), 4.5, i * 0.35)
	esteira(Vector3(37, 0.0, 92), PI / 2.0, VELOCIDADE_ESTEIRA, "blue", true)
	caixa_solida(Vector3(46, 2.5, 87.8), Vector3(9, 5, 0.6), _mat(Color("8ea4c9"), 0.5))
	caixa_solida(Vector3(46, 2.5, 96.2), Vector3(9, 5, 0.6), _mat(Color("8ea4c9"), 0.5))
	caixa_solida(Vector3(50.2, 2.5, 92), Vector3(0.6, 5, 9), _mat(Color("8ea4c9"), 0.5))
	caixa_solida(Vector3(46, 5.3, 92), Vector3(9.6, 0.6, 9.6), _mat(Color("3f8fe0"), 0.5))
	roda(Vector3(46.5, 1.2, 92), 1.8, 4)

	# Bolso: a escada de caixotes até a prateleira do coração.
	for spec in [[Vector2(-17.5, 125), 1], [Vector2(-20.1, 125), 2]]:
		var p: Vector2 = spec[0]
		for k in spec[1]:
			bloco("crate", Vector3(p.x, 0.8 + k * 1.6, p.y), 1.6)
			bloco("crate", Vector3(p.x, 0.8 + k * 1.6, p.y + 1.2), 1.6)
	caixa_solida(Vector3(-26, 4.55, 125.4), Vector3(7, 0.5, 5), _mat(Color("c49a6c")))
	for c in [Vector2(-29.2, 123.2), Vector2(-22.8, 123.2), Vector2(-29.2, 127.6), Vector2(-22.8, 127.6)]:
		caixa_solida(Vector3(c.x, 2.15, c.y), Vector3(0.5, 4.3, 0.5), _mat(Color("6a4a2a")))
	coracao(Vector3(-26.5, 6.0, 125.4))
	estrelinha(Vector3(-24, 5.8, 124))
	estrelinha(Vector3(-28.5, 5.8, 126.6))

	bolota(Vector3(-6, 0.1, 128), true, "cogumelo")
	bolota(Vector3(8, 0.1, 94))
	for p in [Vector3(10, 1.2, 122), Vector3(2, 1.2, 118), Vector3(-12, 1.2, 116), Vector3(-22, 1.2, 111), Vector3(-27, 1.2, 105)]:
		estrelinha(p)
	roda(Vector3(12, 1.2, 138), 2.5, 3)


## O bloco tombou: se parou em cima de uma esteira da entrada, ela o leva até a recebedora (alinhado no meio dela).
## Longe demais de casa (empurrado para o outro lado), ele volta para lá num puf.
func _bloco_tombou(d: DadoQueTomba) -> void:
	if d.travado:
		return
	var p := d.global_position
	for x: float in ESTEIRAS_DA_ENTRADA:
		if absf(p.x - x) < 1.45 and p.z > Z_RECEBEDORA + 0.5 and p.z < 110.0:
			_levar_bloco(d, x)
			return
	if Vector2(p.x - d.casa.x, p.z - d.casa.z).length() > 16.0:
		d.voltar_para_casa()


func _levar_bloco(d: DadoQueTomba, x: float) -> void:
	d.travado = true
	var fim := Vector3(x, d.global_position.y, Z_RECEBEDORA + 1.4)
	var tw := d.create_tween()
	tw.tween_property(d, "global_position:x", x, 0.25)
	tw.tween_property(d, "global_position", fim, (d.global_position.z - fim.z) / VELOCIDADE_ESTEIRA)
	tw.tween_property(d, "global_position", fim + Vector3(0, 0, -3.0), 0.6)
	tw.tween_callback(func() -> void:
		d.hide()
		d.collision_layer = 0
		_entregar(x))


## Um bloco entrou na recebedora: acende a próxima luz; com as três, a esteira expressa passa a subir.
func _entregar(x: float) -> void:
	if entregues >= 3:
		return
	_luzes[entregues].emission_energy_multiplier = 2.2
	entregues += 1
	Fx.confetti(self, Vector3(x, TOPO_MAQUINAS + 2.0, Z_RECEBEDORA - 2.0), 24, 3.0)
	Sfx.play(self, "ui_ok", 0.0, 0.0)
	if entregues == 3:
		for e in expressa:
			e.mudar(EXPRESSA_SOBE)
		Fx.confetti(self, expressa[0].global_position + Vector3.UP * 2.0, 50, 4.0)
		Sfx.play(self, "bandeira", 0.0, 0.0)


## A esteira expressa já sobe.
func expressa_ligada() -> bool:
	return entregues >= 3


## Viagem 1: a esteira expressa, seis esteiras em linha do chão da entrada até a beira sul da máquina A (8 m). Antes da
## tarefa ela desce rápido (as setas apontam para baixo e quem pisa volta para a entrada); depois, sobe devagar.
func _esteira_expressa() -> void:
	var u := Vector3(-1, 0, -1).normalized()
	var comprimento := Esteira.COMPRIMENTO * EXPRESSA_UNIDADES
	var inclinacao := asin(EXPRESSA_FIM.y / comprimento)
	var comeco := EXPRESSA_FIM - u * comprimento * cos(inclinacao)
	comeco.y = 0.0
	var dir := (EXPRESSA_FIM - comeco).normalized()
	var giro := atan2(u.x, u.z)
	for i in EXPRESSA_UNIDADES:
		var meio := comeco + dir * Esteira.COMPRIMENTO * (i + 0.5)
		var e := Esteira.new()
		e.velocidade = EXPRESSA_DESCE
		e.cor = "yellow"
		e.faixa_escura = true
		e.rotation = Vector3(-inclinacao, giro, 0)
		e.position = meio - Basis.from_euler(e.rotation) * Vector3(0, Esteira.ALTURA - 0.03, 0)
		add_child(e)
		esteiras.append(e)
		expressa.append(e)
		if meio.y > 1.6:
			caixa_solida(Vector3(meio.x, (meio.y - 1.1) * 0.5, meio.z), Vector3(0.9, meio.y - 1.1, 0.9), _mat(Color("6b7894"), 0.5))
		if i % 2 == 1:
			estrelinha(meio + Vector3.UP * 1.6)
	arco_de_saida(comeco - u * 2.6, giro, "yellow")


# --- 2 · Blocos-Pisca --------------------------------------------------------------------

## Playground 2 · Blocos-Pisca (desenvolve): máquinas de 8 m (cair só leva ao chão, e o monta-carga devolve). Entre elas,
## blocos-pisca lilases, que se revezam em dois grupos. A tarefa: três alavancas, cada uma em cima de uma máquina,
## chamam a ponte rolante. Há mais de um caminho até a praça do meio (vigas firmes). Mini-marco: a Impressora de Blocos,
## que bate o carimbo e imprime um bloco lilás no tique. Bolso: o cano gigante da parede, com o V1.
func _blocos_pisca() -> void:
	var t := TOPO_MAQUINAS
	playground("2 · Blocos-Pisca", Vector3(-94, t, 40), 30.0, Vector3(-62, t + 0.2, 64))
	maquina(Vector3(-64, t, 62), 12, 12, CORES[0])
	var p1 := posto(Vector3(-61, t, 58.5))
	maquina(Vector3(-86, t, 66), 8, 8, CORES[1])
	maquina(Vector3(-96, t, 40), 18, 18, CORES[2])
	maquina(Vector3(-72, t, 27), 8, 8, CORES[1])
	maquina(Vector3(-118, 10.0, 24), 8, 8, CORES[0])
	maquina(Vector3(-100, t, 12), 12, 12, CORES[2])
	for spec in [Vector3(-86, t, 66.5), Vector3(-72, t, 27.5), Vector3(-118, 10.0, 24.5)]:
		var a := Alavanca.new()
		a.cor = "red"
		a.position = spec
		add_child(a)
		a.puxada.connect(_alavanca_puxada)
		alavancas.append(a)
	ponto_de_dica(Vector3(-67, t + 0.5, 64), 4.0, "pisca")
	# Os blocos-pisca: até a primeira alavanca, até a segunda, até a terceira e, subindo, até o cano do V1.
	for spec in [[Vector3(-73.5, t, 64.5), 0], [Vector3(-78.5, t, 65.5), 1], [Vector3(-83.5, t, 31.5), 0], [Vector3(-79.5, t, 29.5), 1],
			[Vector3(-107.5, 8.8, 30), 1], [Vector3(-111.5, 9.6, 27), 0], [Vector3(-120, 11.6, 30.5), 0], [Vector3(-121.5, 13.2, 34.5), 1]]:
		bloco_pisca(spec[0], spec[1])
		estrelinha(spec[0] + Vector3.UP * 1.4)
	# Vigas firmes: B até a praça, A até a praça (o caminho sem pisca), D até a saída e a praça até a saída.
	passarela(Vector3(-86, t, 61.8), Vector3(-90, t, 49.2))
	passarela(Vector3(-65, t, 55.8), Vector3(-87.2, t, 44))
	passarela(Vector3(-72, t, 22.8), Vector3(-94.2, t, 14))
	passarela(Vector3(-98, t, 30.8), Vector3(-98, t, 18.2))
	trilha_creme([Vector3(-64, t, 57.5), Vector3(-76, t, 50.5), Vector3(-87, t, 44.5), Vector3(-96, t, 37), Vector3(-98, t, 30), Vector3(-98.5, t, 17)])
	# Mini-marco: a Impressora de Blocos (as colunas são sólidas; a trave e a cabeça ficam lá no alto).
	for x in [-104.5, -87.5]:
		caixa_solida(Vector3(x, t + 5.5, 40), Vector3(1.0, 11.0, 1.0), _mat(Color("55607a"), 0.4))
	so_enfeite(caixa_visual(Vector3(-96, t + 11.6, 40), Vector3(18, 1.2, 1.4), _mat(Color("55607a"), 0.4)))
	_cabeca_impressora = so_enfeite(Node3D.new())
	_cabeca_impressora.position = Vector3(-96, t + 8.0, 40)
	add_child(_cabeca_impressora)
	var cabeca := MeshInstance3D.new()
	var bc := BoxMesh.new()
	bc.size = Vector3(2.6, 2.6, 2.6)
	cabeca.mesh = bc
	cabeca.material_override = _mat(Color("2b2140"))
	_cabeca_impressora.add_child(cabeca)
	var bico := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.7
	cone.height = 1.2
	bico.mesh = cone
	bico.material_override = _mat(Color("c9a7ff"))
	bico.rotation.x = PI
	bico.position.y = -1.9
	_cabeca_impressora.add_child(bico)
	bloco_pisca(Vector3(-96, t + 1.0, 40), 0)
	# Bolso: o cano gigante que sai da parede oeste, oco, com o V1 lá dentro.
	var cano := StaticBody3D.new()
	cano.position = Vector3(-129, 15.6, 38.5)
	cano.rotation.z = PI / 2.0
	var cil := CylinderMesh.new()
	cil.top_radius = 2.6
	cil.bottom_radius = 2.6
	cil.height = 10.0
	cil.cap_top = false
	cil.cap_bottom = false
	var verde := _mat(Color("4cc27a"), 0.4).duplicate() as StandardMaterial3D
	verde.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mi := MeshInstance3D.new()
	mi.mesh = cil
	mi.material_override = verde
	cano.add_child(mi)
	var cs := CollisionShape3D.new()
	var oco := cil.create_trimesh_shape()
	oco.backface_collision = true
	cs.shape = oco
	cano.add_child(cs)
	add_child(cano)
	var aro := MeshInstance3D.new()
	var toro := TorusMesh.new()
	toro.inner_radius = 2.55
	toro.outer_radius = 2.85
	aro.mesh = toro
	aro.material_override = _mat(Color("2f8a4f"), 0.4)
	aro.position = Vector3(-124, 15.6, 38.5)
	aro.rotation.z = PI / 2.0
	# A borda do cano é fininha (0,3 m) e fica rente a ele: enfeite.
	add_child(so_enfeite(aro))
	vaga_lume(Vector3(-129, 14.4, 38.5))
	estrelinha(Vector3(-126, 14.2, 38.5))

	monta_carga(Vector3(-56.2, 0, 62), t, -PI / 2.0, p1)
	bolota(Vector3(-92, t, 36))
	bolota(Vector3(-100, t, 45), false, "pinguim")
	bolota(Vector3(-80, t, 31), false, "morcego")
	roda(Vector3(-96, t + 1.2, 40), 5.5, 5)
	for p in [Vector3(-86, t + 1.2, 68.5), Vector3(-72, t + 1.2, 29.5), Vector3(-118, 11.2, 21.5), Vector3(-64, t + 1.2, 65), Vector3(-100, t + 1.2, 9),
			Vector3(-76, t + 1.2, 50), Vector3(-88, t + 1.2, 55), Vector3(-83, t + 1.2, 18.5), Vector3(-98, t + 1.2, 24)]:
		estrelinha(p)
	arco_de_saida(Vector3(-100, t, 16.5), 0.0, "red")


func _alavanca_puxada(_a: Alavanca) -> void:
	if alavancas.all(func(x: Alavanca) -> bool: return x.puxada_ja) and ponte_rolante.travada:
		ponte_rolante.travada = false
		Fx.confetti(self, ponte_rolante.global_position + Vector3.UP * 2.0, 50, 4.0)
		Sfx.play(self, "bandeira", 0.0, 0.0)


## Viagem 2: o palete laranja pendurado no gancho da ponte rolante, da máquina F até a oficina. Os trilhos e a viga
## correm lá no alto (a 30 m); as colunas do pé são sólidas. Fica travado até as três alavancas.
func _viagem_ponte_rolante() -> void:
	var caminho := [Vector3(-100, TOPO_MAQUINAS, 8.5), Vector3(-99, 17, 1), Vector3(-90, 21, -26), Vector3(-84, 18, -50), Vector3(-82, TOPO_OFICINA, -60)]
	ponte_rolante = carona(caminho[0], caminho[caminho.size() - 1], "palete", 5.0, caminho)
	ponte_rolante.travada = true
	var a := Vector3(-100, 30, 10)
	var b := Vector3(-82, 30, -56)
	var d := (b - a).normalized()
	var lado := Vector3(-d.z, 0, d.x)
	var ferro := _mat(Color("55607a"), 0.4)
	for s: float in [-5.0, 5.0]:
		var ra := a + lado * s - d * 10.0
		var rb := b + lado * s + d * 10.0
		var trilho := so_enfeite(caixa_visual((ra + rb) * 0.5, Vector3(0.8, 0.8, ra.distance_to(rb)), ferro))
		trilho.rotation.y = atan2(d.x, d.z)
		for q: Vector3 in [ra, rb]:
			caixa_solida(Vector3(q.x, 15, q.z), Vector3(1.0, 30, 1.0), _mat(Color("6b7894"), 0.5))
	_viga = so_enfeite(Node3D.new())
	add_child(_viga)
	var viga := MeshInstance3D.new()
	var bv := BoxMesh.new()
	bv.size = Vector3(11.5, 0.9, 1.2)
	viga.mesh = bv
	viga.material_override = _mat(Color("ff7a22"))
	_viga.add_child(viga)
	_viga.rotation.y = atan2(d.x, d.z)
	_cabo = so_enfeite(MeshInstance3D.new())
	var cc := CylinderMesh.new()
	cc.top_radius = 0.07
	cc.bottom_radius = 0.07
	cc.height = 1.0
	_cabo.mesh = cc
	_cabo.material_override = _mat(Color("2b2140"))
	add_child(_cabo)
	for k in [0.3, 0.6]:
		estrelinha((caminho[1] as Vector3).lerp(caminho[3], k) + Vector3.UP * 2.0)


# --- 3 · Oficina do Martelinho ----------------------------------------------------------------

## Playground 3 · Oficina do Martelinho (central): a bancada larga a 14 m, com ferramentas de brinquedo gigantes. A
## caixa de ferramentas (subindo pela escada de caixotes) dá o poder da fase, o Martelinho de Apito. A tarefa: a
## empilhadeira espera em cima da estante, 6 m acima da bancada; três pinos no chão, cada um ligado por um cano a um
## pistão perto da estante, e as três pancadas fazem a escada. Bolsos: o quarto pino, atrás da caixa de ferramentas,
## liga o pistão alto, que sobe e desce até a prateleira com o V2; o coração na gaveta. Uma das Bolotas usa capacete.
func _oficina() -> void:
	var t := TOPO_OFICINA
	playground("3 · Oficina do Martelinho", Vector3(-72, t, -80), 26.0, Vector3(-82, t + 0.2, -60))
	caixa_solida(Vector3(-72, t - 0.5, -80), Vector3(56, 1.0, 46), _mat(Color("d6deec"), 0.7))
	for p in [Vector2(-98, -59), Vector2(-46, -59), Vector2(-98, -101), Vector2(-46, -101), Vector2(-72, -59), Vector2(-72, -101)]:
		caixa_solida(Vector3(p.x, (t - 1.0) * 0.5, p.y), Vector3(2.0, t - 1.0, 2.0), _mat(Color("6b7894"), 0.5))
	var p2 := posto(Vector3(-86, t, -61))
	trilha_creme([Vector3(-82, t, -60), Vector3(-76, t, -68), Vector3(-70, t, -80), Vector3(-66, t, -90), Vector3(-63, t, -94)])

	# A caixa de ferramentas vermelha (5 m), a tampa aberta para trás, a gaveta com o coração e a escada de caixotes.
	var vermelho := _mat(Color("e94f4f"), 0.5)
	caixa_solida(Vector3(-58, t + 2.5, -68), Vector3(10, 5, 6), vermelho, 0.2)
	var tampa := caixa_solida(Vector3(-58, t + 7.8, -71.6), Vector3(10, 6, 0.5), vermelho, 0.1)
	tampa.rotation.x = -0.25
	caixa_solida(Vector3(-58, t + 0.8, -63.8), Vector3(8, 1.6, 2.4), _mat(Color("c0403b"), 0.5), 0.1)
	coracao(Vector3(-58, t + 2.8, -63.8))
	for spec in [[Vector2(-70.2, -68), 1], [Vector2(-67.6, -68), 2], [Vector2(-65.0, -68), 3]]:
		var p: Vector2 = spec[0]
		for k in spec[1]:
			bloco("crate", Vector3(p.x, t + 0.8 + k * 1.6, p.y), 1.6)
			bloco("crate", Vector3(p.x, t + 0.8 + k * 1.6, p.y + 1.6), 1.6)
	# O martelinho, flutuando em cima da caixa.
	_area_martelo = Area3D.new()
	_area_martelo.position = Vector3(-58, t + 6.4, -68)
	_area_martelo.collision_layer = 0
	_area_martelo.collision_mask = CAMADA_JOGADOR
	var forma := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = 1.4
	forma.shape = esfera
	_area_martelo.add_child(forma)
	_martelo_visual = Node3D.new()
	_area_martelo.add_child(_martelo_visual)
	for spec in [[Vector3(0, -0.6, 0), Vector3(0.18, 1.8, 0.18), Color("ffd23f"), false], [Vector3(0, 0.5, 0), Vector3(0.6, 1.6, 0.6), Color("e94f4f"), true],
			[Vector3(0, 0.5, 0), Vector3(0.66, 0.5, 0.66), Color("ffd23f"), true]]:
		var mi := MeshInstance3D.new()
		var cil := CylinderMesh.new()
		cil.top_radius = spec[1].x
		cil.bottom_radius = spec[1].z
		cil.height = spec[1].y
		mi.mesh = cil
		mi.material_override = _mat(spec[2], 0.4)
		mi.position = spec[0]
		if spec[3]:
			mi.rotation.z = PI / 2.0
		_martelo_visual.add_child(mi)
	add_child(_area_martelo)
	_area_martelo.body_entered.connect(func(corpo: Node3D) -> void:
		if corpo is Jogador and not martelinho_pego:
			pegar_martelinho(corpo))

	# A tarefa: os três pinos e os pistões deles, que viram a escada até a estante da empilhadeira (6 m).
	for spec in [[Vector3(-84, t, -76), Vector3(-59, t, -94), 1.2], [Vector3(-74, t, -90), Vector3(-55.5, t, -94), 2.8],
			[Vector3(-64, t, -82), Vector3(-52, t, -94), 4.4]]:
		var pino_: Pino = pino(spec[0])
		var pistao_: Pistao = pistao(spec[1], spec[2])
		pinos_da_oficina.append(pino_)
		pistoes_da_oficina.append(pistao_)
		pino_.batido.connect(func(_p: Pino) -> void: pistao_.ligar())
		_cano_do_chao([spec[0], (spec[0] + spec[1]) * 0.5 + Vector3(0, 0, 2), spec[1] + Vector3(0, 0, 1.9)])
		estrelinha(spec[1] + Vector3(0, spec[2] + 1.6, 0))
		estrelinha(spec[0] + Vector3(0, 3.0, 0))
	# A estante vai do chão da fábrica até 20 m, encostada na beira da bancada: a empilhadeira fica na metade de lá e
	# sobra a metade de cá para chegar pelos pistões.
	caixa_solida(Vector3(-44, TOPO_PINTURA * 0.5, -94), Vector3(12, TOPO_PINTURA, 12), _mat(Color("c49a6c"), 0.8))
	for y in [4.0, 8.0, 12.0, t + 2.0, t + 4.0]:
		caixa_visual(Vector3(-44, y, -94), Vector3(12.06, 0.15, 12.06), _mat(Color("6a4a2a")))
	for p in [Vector2(-78, -66), Vector2(-70, -76), Vector2(-64, -88)]:
		_placa(Vector3(p.x, t, p.y), Vector3(-47, t, -94))
	arco_de_saida(Vector3(-66, t, -94), PI / 2.0, "yellow")

	# Bolso alto: o quarto pino, atrás da caixa de ferramentas, liga o pistão alto (sobe e desce) até a prateleira do V2.
	pino_secreto = pino(Vector3(-48, t, -64))
	pistao_alto = pistao(Vector3(-47, t, -75), 8.0, 3.0, true)
	pino_secreto.batido.connect(func(_p: Pino) -> void: pistao_alto.ligar())
	_cano_do_chao([Vector3(-48, t, -64), Vector3(-47.4, t, -70), Vector3(-47, t, -73.3)])
	# A prateleira encosta no pistão alto: lá em cima, é só andar para ela.
	caixa_solida(Vector3(-47, t + 8.15, -79.1), Vector3(5, 0.5, 5), _mat(Color("c49a6c")))
	for c in [Vector2(-49.2, -81.3), Vector2(-44.8, -81.3), Vector2(-49.2, -76.9), Vector2(-44.8, -76.9)]:
		caixa_solida(Vector3(c.x, t + 3.95, c.y), Vector3(0.5, 7.9, 0.5), _mat(Color("6a4a2a")))
	vaga_lume(Vector3(-47, t + 9.8, -79.6))
	estrelinha(Vector3(-45.5, t + 9.8, -77.6))
	estrelinha(Vector3(-48.5, t + 9.8, -81))

	monta_carga(Vector3(-96, 0, -54.4), t, PI, p2)
	bolota(Vector3(-72, t, -70))
	bolota(Vector3(-80, t, -88), false, "capacete")
	bolota(Vector3(-62, t, -100), false, "cogumelo")
	for p in [Vector3(-80, t + 1.2, -63), Vector3(-74, t + 1.2, -72), Vector3(-68, t + 1.2, -84), Vector3(-47, t + 7.2, -91), Vector3(-47, t + 7.2, -97),
			Vector3(-60, 1.2, -66), Vector3(-80, 1.2, -66), Vector3(-70, 1.2, -96)]:
		estrelinha(p)
	roda(Vector3(-86, t + 1.2, -80), 3.0, 4)


## A caixa de ferramentas dá o Martelinho de Apito: vale até o fim da fase, e o Vovô mostra como usa.
func pegar_martelinho(j: Jogador) -> void:
	martelinho_pego = true
	j.martelinho = true
	j.robo.expressao("feliz", 1.2)
	Fx.confetti(self, _area_martelo.global_position, 40, 4.0)
	Sfx.play(self, "bandeira", 0.0, 0.0)
	_area_martelo.set_deferred("monitoring", false)
	_area_martelo.hide()
	_dicas_dadas.erase("martelo")
	_dica_uma_vez("martelo")


## Cano laranja fininho rente ao chão (liga o pino ao pistão; enfeite, que se atravessa).
func _cano_do_chao(pontos: Array) -> void:
	var pts := PackedVector3Array()
	for p: Vector3 in pontos:
		pts.append(p + Vector3.UP * 0.25)
	var mi := MeshInstance3D.new()
	mi.mesh = Forma.tubo_fechado(pts, 0.22)
	mi.material_override = _mat(Color("ff7a22"), 0.5)
	add_child(so_enfeite(mi))


## Placa de seta azul apontando para `alvo` (o poste e a placa são sólidos).
func _placa(pe: Vector3, alvo: Vector3) -> void:
	var corpo := StaticBody3D.new()
	corpo.position = pe
	var d := alvo - pe
	corpo.rotation.y = atan2(-d.z, d.x)
	add_child(corpo)
	var poste := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = 0.12
	cil.bottom_radius = 0.12
	cil.height = 2.6
	poste.mesh = cil
	poste.material_override = _mat(Color("2b2140"))
	poste.position.y = 1.3
	corpo.add_child(poste)
	var chapa := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(1.8, 0.8, 0.14)
	chapa.mesh = b
	chapa.material_override = _mat(Color("3f8fe0"))
	chapa.position.y = 2.8
	corpo.add_child(chapa)
	var ponta := MeshInstance3D.new()
	var tri := CylinderMesh.new()
	tri.top_radius = 0.0
	tri.bottom_radius = 0.55
	tri.height = 0.8
	tri.radial_segments = 3
	ponta.mesh = tri
	ponta.material_override = _mat(Color("ffffff"))
	ponta.rotation.z = -PI / 2.0
	ponta.position = Vector3(1.25, 2.8, 0)
	corpo.add_child(ponta)
	var cs := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(2.4, 3.2, 0.3)
	cs.shape = forma
	cs.position.y = 1.6
	corpo.add_child(cs)


## Viagem 3: a empilhadeira, pela passarela alta (20 m, com corrimão), da estante da oficina até a faixa de entrada do
## andar da pintura (e volta). A passarela é firme: dá para ir andando também.
func _viagem_empilhadeira() -> void:
	var t := TOPO_PINTURA
	var pontos := [Vector3(-40, t, -94), Vector3(-30, t, -96), Vector3(-6, t, -88), Vector3(18, t, -74), Vector3(40, t, -62), Vector3(62, t, -55),
		Vector3(80, t, -52), Vector3(90, t, -45.5)]
	var caminho := pontos.map(func(p: Vector3) -> Vector3: return p + Vector3.UP * 0.4)
	empilhadeira = carona(caminho[0], caminho[caminho.size() - 1], "empilhadeira", 7.0, caminho)
	var piso := _mat(Color("aab6cc"), 0.5)
	for i in pontos.size() - 1:
		var a: Vector3 = pontos[i] if i > 0 else Vector3(-38, t, -94)
		var b: Vector3 = pontos[i + 1]
		passarela(a, b, 4.6)
		var d := b - a
		var lado := Vector3(-d.z, 0, d.x).normalized() * 2.4
		for s in [-1.0, 1.0]:
			var de: Vector3 = a + lado * s
			var ate: Vector3 = b + lado * s
			if i < pontos.size() - 2:
				corrimao(Vector2(de.x, de.z), Vector2(ate.x, ate.z), t)
		if i > 0:
			var junta := StaticBody3D.new()
			junta.position = a + Vector3.DOWN * 0.25
			var cil := CylinderMesh.new()
			cil.top_radius = 2.3
			cil.bottom_radius = 2.3
			cil.height = 0.5
			var mi := MeshInstance3D.new()
			mi.mesh = cil
			mi.material_override = piso
			junta.add_child(mi)
			var cs := CollisionShape3D.new()
			var forma := CylinderShape3D.new()
			forma.radius = 2.3
			forma.height = 0.5
			cs.shape = forma
			junta.add_child(cs)
			add_child(junta)
			caixa_solida(Vector3(a.x, (t - 0.5) * 0.5, a.z), Vector3(1.0, t - 0.5, 1.0), _mat(Color("6b7894"), 0.5))
	for k in [0.25, 0.5, 0.75]:
		var i := int(k * (pontos.size() - 1))
		estrelinha((pontos[i] as Vector3).lerp(pontos[i + 1], 0.5) + Vector3.UP * 1.4)


# --- 4 · Andar da Pintura ------------------------------------------------------------------

## Playground 4 · Andar da Pintura (reviravolta): o andar onde os blocos são pintados, a 20 m. O chão é um tanque de
## tinta rosa (encostar conta como cair, como a lava do quarto); só as faixas da entrada e da saída são firmes. Latas
## de tinta gigantes servem de ilhas, ligadas por esteiras (uma empurra para o lado) e blocos-pisca. A tarefa: o pino
## de cada lata sobe um vão da ponte de blocos até a máquina. Bolso: a lata tombada, com o coração.
func _andar_da_pintura() -> void:
	var t := TOPO_PINTURA
	playground("4 · Andar da Pintura", Vector3(88, t, -18), 30.0, Vector3(92, t + 0.2, -45))
	caixa_solida(Vector3(88, (t - 0.6) * 0.5, -18), Vector3(52, t - 0.6, 60), _mat(Color("8ea4c9"), 0.5))
	_tinta(Vector3(88, t - 0.4, -18), Vector2(52, 60))
	var mureta := _mat(Color("b8c4da"), 0.6)
	for spec in [[Vector2(62, -48), Vector2(84, -48)], [Vector2(96, -48), Vector2(114, -48)], [Vector2(114, -48), Vector2(114, 12)],
			[Vector2(62, 12), Vector2(64, 12)], [Vector2(68, 12), Vector2(114, 12)], [Vector2(62, -48), Vector2(62, PONTE_Z - 2.5)],
			[Vector2(62, PONTE_Z + 2.5), Vector2(62, 12)]]:
		var a: Vector2 = spec[0]
		var b: Vector2 = spec[1]
		caixa_solida(Vector3((a.x + b.x) * 0.5, t + 0.7, (a.y + b.y) * 0.5), Vector3(maxf(absf(b.x - a.x), 0.8), 2.6, maxf(absf(b.y - a.y), 0.8)), mureta)
	caixa_solida(Vector3(99, t - 0.3, -45), Vector3(30, 0.6, 6), _mat(Color("dfe6f2"), 0.7))
	caixa_solida(Vector3(67, t - 0.3, 4), Vector3(10, 0.6, 16), _mat(Color("dfe6f2"), 0.7))
	var p3 := posto(Vector3(96, t, -45.5))
	ponto_de_dica(Vector3(100, t + 0.5, -44), 4.0, "tinta")

	var latas := [Vector3(102, t, -30), Vector3(82, t, -24), Vector3(84, t, -4)]
	for i in 3:
		_lata(latas[i], 4.5, CORES[i])
		var pino_: Pino = pino(latas[i])
		pinos_da_pintura.append(pino_)
		var k := i
		pino_.batido.connect(func(_p: Pino) -> void: _subir_vao(k))
		roda(latas[i] + Vector3.UP * 1.2, 2.9, 3)
	esteira(Vector3(102, t, -38.25), 0.0, VELOCIDADE_ESTEIRA, "blue", true)
	bloco_pisca(Vector3(94.6, t, -27.8), 0)
	bloco_pisca(Vector3(89.4, t, -26.2), 1)
	# A esteira larga que empurra para o lado (para leste, para a tinta), entre a lata do meio e a última.
	for z in [-16.9, -12.7]:
		for x in [79.0, 87.0]:
			esteira(Vector3(x, t, z), PI / 2.0, VELOCIDADE_ESTEIRA, "red", true)
	bloco_pisca(Vector3(75.8, t, -1.5), 1)
	# Bolso: a lata tombada, pela esteira que sai da primeira lata e dois blocos-pisca.
	esteira(Vector3(102, t, -21.4), 0.0, VELOCIDADE_ESTEIRA, "blue", true)
	bloco_pisca(Vector3(103, t, -14), 0)
	bloco_pisca(Vector3(105, t, -9.5), 1)
	_lata_tombada(Vector3(107, t, -6), 3.6, 10.0)
	coracao(Vector3(107, t + 1.4, 3.0))
	for p in [Vector3(107, t + 1.2, -3), Vector3(107, t + 1.2, -0.8), Vector3(107, t + 1.2, 1.2)]:
		estrelinha(p)

	bolota(Vector3(80, t, -22), false, "cogumelo")
	bolota(Vector3(86.5, t, -3), false, "pinguim")
	for p in [Vector3(102, t + 1.2, -40), Vector3(102, t + 1.2, -36.5), Vector3(94.6, t + 1.4, -27.8), Vector3(89.4, t + 1.4, -26.2),
			Vector3(80, t + 1.4, -14.8), Vector3(86, t + 1.4, -14.8), Vector3(75.8, t + 1.4, -1.5), Vector3(102, t + 1.4, -20), Vector3(103, t + 1.4, -14),
			Vector3(67, t + 1.2, 0), Vector3(67, t + 1.2, 8)]:
		estrelinha(p)
	monta_carga(Vector3(66, 0, 14.6), t, PI, p3)
	arco_de_saida(Vector3(63.5, t, PONTE_Z), PI / 2.0, "blue")


## O tanque de tinta: rosa, com manchas que andam devagar. Encostar é cair (volta no posto e custa um coração).
func _tinta(centro: Vector3, tamanho: Vector2) -> void:
	var ruido := FastNoiseLite.new()
	ruido.frequency = 0.06
	var textura := NoiseTexture2D.new()
	textura.noise = ruido
	textura.seamless = true
	textura.width = 256
	textura.height = 256
	var rampa := Gradient.new()
	rampa.set_color(0, Color("ff3f96"))
	rampa.set_color(1, Color("ff9ccf"))
	rampa.add_point(0.55, Color("ff5fae"))
	textura.color_ramp = rampa
	var m := StandardMaterial3D.new()
	m.albedo_texture = textura
	m.emission_enabled = true
	m.emission_texture = textura
	m.emission_energy_multiplier = 0.35
	m.uv1_scale = Vector3(4, 5, 1)
	m.roughness = 0.25
	var plano := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = tamanho
	plano.mesh = pm
	plano.material_override = m
	plano.position = centro
	add_child(plano)
	var tw := plano.create_tween().set_loops()
	tw.tween_property(m, "uv1_offset", Vector3(1, 1, 0), 50.0).from(Vector3.ZERO)
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = CAMADA_JOGADOR
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(tamanho.x, 1.0, tamanho.y)
	cs.shape = caixa
	cs.position = centro + Vector3.DOWN * 0.15
	area.add_child(cs)
	add_child(area)
	area.body_entered.connect(func(corpo: Node3D) -> void:
		if corpo is Jogador:
			Fx.confetti(self, corpo.global_position, 20, 3.0)
			(corpo as Jogador).cair())
	tintas.append(area)


## Lata de tinta gigante em pé (ilha firme), com o topo em `topo`: corpo branco, rótulo colorido, tampa de lata.
func _lata(topo: Vector3, raio: float, cor: Color) -> void:
	var corpo := StaticBody3D.new()
	corpo.position = topo + Vector3.DOWN * 2.5
	add_child(corpo)
	for spec in [[raio, 5.0, Color("f4f6fb"), 0.0], [raio + 0.06, 1.8, cor, -0.4], [raio - 0.25, 0.1, Color("cfd6e2"), 2.52]]:
		var mi := MeshInstance3D.new()
		var cil := CylinderMesh.new()
		cil.top_radius = spec[0]
		cil.bottom_radius = spec[0]
		cil.height = spec[1]
		mi.mesh = cil
		mi.material_override = _mat(spec[2], 0.4)
		mi.position.y = spec[3]
		corpo.add_child(mi)
	var cs := CollisionShape3D.new()
	var forma := CylinderShape3D.new()
	forma.radius = raio
	forma.height = 5.0
	cs.shape = forma
	corpo.add_child(cs)


## A lata tombada (bolso): deitada no eixo z, oca, com a boca para o norte em `boca` (o chão de dentro na altura dela).
func _lata_tombada(boca: Vector3, raio: float, comprimento: float) -> void:
	var corpo := StaticBody3D.new()
	corpo.position = boca + Vector3(0, raio, comprimento * 0.5)
	# Deitada com o +Y do cilindro (a ponta aberta) para o norte (-Z).
	corpo.rotation.x = -PI / 2.0
	add_child(corpo)
	var cil := CylinderMesh.new()
	cil.top_radius = raio
	cil.bottom_radius = raio
	cil.height = comprimento
	cil.cap_top = false
	var m := _mat(Color("f4f6fb"), 0.4).duplicate() as StandardMaterial3D
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mi := MeshInstance3D.new()
	mi.mesh = cil
	mi.material_override = m
	corpo.add_child(mi)
	var faixa := MeshInstance3D.new()
	var f := CylinderMesh.new()
	f.top_radius = raio + 0.06
	f.bottom_radius = raio + 0.06
	f.height = comprimento * 0.4
	f.cap_top = false
	f.cap_bottom = false
	faixa.mesh = f
	faixa.material_override = _mat(Color("4cc27a"), 0.4)
	corpo.add_child(faixa)
	var cs := CollisionShape3D.new()
	var oca := cil.create_trimesh_shape()
	oca.backface_collision = true
	cs.shape = oca
	corpo.add_child(cs)


# --- a ponte de blocos ------------------------------------------------------------------------

## A ponte de blocos da saída da pintura até o anel da máquina: o começo firme e três vãos. Cada vão é uma fileira de
## três blocos grandes que espera no chão, em cima de um pistão; o pino de uma lata sobe a fileira até o lugar, cada
## uma 1,5 m acima da anterior (a última fica 1,5 m abaixo do anel).
func _ponte_de_blocos() -> void:
	passarela(Vector3(62, TOPO_PINTURA, PONTE_Z), Vector3(56, TOPO_PINTURA, PONTE_Z), LADO_DA_PONTE)
	for i in VAOS.size():
		var v: Array = VAOS[i]
		var comprimento: float = v[0] - v[1]
		var corpo := AnimatableBody3D.new()
		corpo.sync_to_physics = true
		corpo.collision_layer = 1
		corpo.collision_mask = 0
		var no_lugar := Vector3((v[0] + v[1]) * 0.5, v[2], PONTE_Z)
		corpo.set_meta("lugar", no_lugar)
		corpo.position = Vector3(no_lugar.x, LADO_DA_PONTE, PONTE_Z)
		for k in 3:
			var b: Node3D = _cena(FABRICA + "colored_block_%s.gltf" % BLOCOS_COR[(i + k) % 3]).instantiate()
			b.scale = Vector3.ONE * LADO_DA_PONTE * 0.5
			b.position = Vector3(-comprimento * 0.5 + LADO_DA_PONTE * (k + 0.5), -LADO_DA_PONTE * 0.5, 0)
			corpo.add_child(b)
		var cs := CollisionShape3D.new()
		var forma := BoxShape3D.new()
		forma.size = Vector3(comprimento, LADO_DA_PONTE, LADO_DA_PONTE)
		cs.shape = forma
		cs.position.y = -LADO_DA_PONTE * 0.5
		corpo.add_child(cs)
		# O pistão embaixo, que desce até o chão quando a fileira está no lugar (some dentro do chão antes).
		var coluna_altura: float = v[2] - LADO_DA_PONTE
		var coluna := MeshInstance3D.new()
		var bc := BoxMesh.new()
		bc.size = Vector3(2.6, coluna_altura, 2.6)
		coluna.mesh = bc
		coluna.material_override = _mat(Color("8a94ab"), 0.4)
		coluna.position.y = -LADO_DA_PONTE - coluna_altura * 0.5
		corpo.add_child(coluna)
		var ccs := CollisionShape3D.new()
		var cf := BoxShape3D.new()
		cf.size = bc.size
		ccs.shape = cf
		ccs.position = coluna.position
		corpo.add_child(ccs)
		add_child(corpo)
		vaos_da_ponte.append(corpo)
		estrelinha(no_lugar + Vector3.UP * 1.4)


## O pino da lata `i` bateu: a fileira de blocos do vão `i` sobe até o lugar.
func _subir_vao(i: int) -> void:
	var corpo := vaos_da_ponte[i]
	var tw := corpo.create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tw.tween_interval(0.3)
	tw.tween_property(corpo, "position", corpo.get_meta("lugar"), 2.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		Fx.confetti(self, corpo.position + Vector3.UP * 1.5, 30, 3.5)
		Sfx.play(self, "bandeira", 0.0, 0.0))
	Sfx.play_at(self, "pistao", corpo.global_position, 0.0)


## Os três vãos da ponte estão no lugar.
func ponte_pronta() -> bool:
	return vaos_da_ponte.all(func(c: AnimatableBody3D) -> bool: return c.position.distance_to(c.get_meta("lugar")) < 0.05)


# --- 5 · Subida da Máquina --------------------------------------------------------------------

## Playground 5 · Subida da Máquina (o fim): a ponte chega ao anel em volta da máquina, a 26 m. A subida vai pela parede
## da parte de cima, no sentido do relógio (leste, sul, oeste e norte): saliências de metal, uma esteira que sobe,
## blocos-pisca e pistões. A tarefa: um pino em cada canto sobe o pistão logo adiante, e o último sobe o pistão grande
## acima do corrimão do topo. Quem cai da parede cai no anel. Segredo: o painel rachado na parede oeste, no anel, com uma
## luz verde-limão perto; três golpes abrem a salinha das engrenagens, com o V3.
func _subida_da_maquina() -> void:
	playground("5 · Subida da Máquina", Vector3(0, ANEL, 0), 18.0, Vector3(24, VAOS[2][2] + 0.2, PONTE_Z))
	posto(Vector3(14, ANEL, -1))
	var cantos := [Vector3(11.9, 29.2, 11.9), Vector3(-11.9, 35.6, 11.9), Vector3(-11.9, 42.0, -11.9)]
	# O último é o pistão grande, que depois da pancada fica subindo e descendo: embaixo, na altura do canto; em cima,
	# acima do corrimão do topo.
	var pistoes := [[Vector3(6.5, 29.2, 11.7), 1.2, 3.0, false], [Vector3(-11.7, 38.8, -0.6), 1.2, 3.0, false], [Vector3(-5.2, 41.6, -12.2), 3.3, 4.0, true]]
	for p: Vector3 in [Vector3(11.7, 27.6, 7), Vector3(6.5, 29.2, 11.7), Vector3(-11.7, 38.8, -0.6)]:
		_saliencia(p, 3.4)
	# A saliência do fim da esteira começa onde ela acaba (senão a esteira deixa o Faísca parado na beirada), e a do lado
	# oeste vai do pistão até perto do canto.
	_saliencia(Vector3(-5.95, 34.0, 11.7), 4.7, 3.4)
	_saliencia(Vector3(-11.7, 42.0, -5.7), 3.4, 6.0)
	for p: Vector3 in cantos:
		_saliencia(p, 4.4)
	_saliencia(Vector3(-5.2, 41.6, -12.2), 4.0)
	for i in 3:
		var pino_: Pino = pino(cantos[i])
		var pistao_: Pistao = pistao(pistoes[i][0], pistoes[i][1], pistoes[i][2], pistoes[i][3])
		pinos_da_subida.append(pino_)
		pistoes_da_subida.append(pistao_)
		pino_.batido.connect(func(_p: Pino) -> void: pistao_.ligar())
	# A esteira que sobe pela parede sul, para oeste.
	var de := Vector3(4.2, 32.4, 11.7)
	var ate := Vector3(-3.64, 34.0, 11.7)
	var inclinacao := asin((ate.y - de.y) / Esteira.COMPRIMENTO)
	var e := Esteira.new()
	e.velocidade = VELOCIDADE_ESTEIRA
	e.cor = "yellow"
	e.faixa_escura = true
	e.rotation = Vector3(-inclinacao, -PI / 2.0, 0)
	e.position = (de + ate) * 0.5 - Basis.from_euler(e.rotation) * Vector3(0, Esteira.ALTURA - 0.03, 0)
	add_child(e)
	esteiras.append(e)
	bloco_pisca(Vector3(-11.7, 37.2, 7.6), 0)
	bloco_pisca(Vector3(-11.7, 38.8, 3.6), 1)
	ponto_de_dica(Vector3(14, ANEL + 0.5, 8), 3.0, "martelo")

	# Segredo: o painel rachado na salinha da parede oeste, a luz verde-limão perto e o V3 lá dentro.
	parede_secreta = ParedeRachada.new()
	parede_secreta.escala = 1.0
	parede_secreta.position = Vector3(-MEIA_ALTA - 0.5, ANEL, 4)
	parede_secreta.rotation.y = PI / 2.0
	add_child(parede_secreta)
	for mi in parede_secreta.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = _mat(Color("a9b8d3"), 0.5)
	paredes_rachadas.append(parede_secreta)
	var limao := MeshInstance3D.new()
	var bola := SphereMesh.new()
	bola.radius = 0.45
	bola.height = 0.9
	limao.mesh = bola
	var lm := StandardMaterial3D.new()
	lm.albedo_color = Color("c6ff5a")
	lm.emission_enabled = true
	lm.emission = Color("b6f23a")
	lm.emission_energy_multiplier = 1.6
	limao.material_override = lm
	limao.position = Vector3(-MEIA_ALTA - 0.3, ANEL + 5.0, 7.0)
	add_child(so_enfeite(limao))
	vaga_lume(Vector3(-8, ANEL + 1.4, 4))
	estrelinha(Vector3(-8, ANEL + 1.0, 2.8))
	estrelinha(Vector3(-8, ANEL + 1.0, 5.2))
	ponto_de_dica(Vector3(-14, ANEL + 0.5, 4), 3.0, "golpe")

	bolota(Vector3(4, ANEL, 14))
	bolota(Vector3(-14, ANEL, 4), false, "morcego")
	coracao(Vector3(4, ANEL + 1.4, -14))
	for p in [Vector3(11.7, 28.8, 7), Vector3(11.9, 30.4, 10.4), Vector3(6.5, 32.2, 11.7), Vector3(-1, 34.4, 11.7), Vector3(-6.6, 35.2, 11.7),
			Vector3(-11.7, 38.6, 7.6), Vector3(-11.7, 40.2, 3.6), Vector3(-11.7, 41.8, -0.6), Vector3(-11.7, 43.2, -5.2), Vector3(-5.2, 43.2, -12.2)]:
		estrelinha(p)
	for p in [Vector3(14, ANEL + 1.2, 10), Vector3(10, ANEL + 1.2, 14.5), Vector3(-6, ANEL + 1.2, 14.5), Vector3(-14, ANEL + 1.2, -8),
			Vector3(-6, ANEL + 1.2, -14.5), Vector3(10, ANEL + 1.2, -14.5), Vector3(14, ANEL + 1.2, -9)]:
		estrelinha(p)


## Saliência de metal na parede da máquina, com o meio da face de cima em `topo` (`lado` em x; `fundo` em z, se for
## diferente).
func _saliencia(topo: Vector3, lado: float, fundo := -1.0) -> void:
	caixa_solida(topo + Vector3.DOWN * 0.6, Vector3(lado, 1.2, fundo if fundo > 0.0 else lado), _mat(Color("aab6cc"), 0.45), 0.1)


# --- arena ------------------------------------------------------------------------------------

## Arena no topo da máquina (44 m): o baú, três Bolotas (uma de capacete, que só cai com a pancada) e a coluna de luz.
## A Estrela Grande do gancho some quando o baú abre (a de verdade sobe do baú).
func _arena() -> void:
	var topo := Vector3(0, TOPO, 2)
	colocar_bau(topo)
	brilho_de_marco(topo + Vector3(0, 1.5, 0), 34.0)
	bau.aberto.connect(func() -> void: _estrela_do_gancho.hide())
	bolota(Vector3(-4, TOPO, 5))
	bolota(Vector3(5, TOPO, -2), false, "porco")
	bolota(Vector3(-1, TOPO, -5), false, "capacete")
	roda(topo + Vector3(0, 0.9, 0), 2.8, 4)


# --- relógio, viga e enfeites que mexem ------------------------------------------------------

func _physics_process(delta: float) -> void:
	super(delta)
	for b in blocos_pisca:
		b.definir(_tempo)
	# O tique da fábrica a cada troca de grupo, quando o Faísca está perto de algum bloco-pisca.
	var agora := int(_tempo / (BlocoPisca.CICLO * 0.5))
	if agora != _tique:
		_tique = agora
		var j := get_tree().get_first_node_in_group("jogador") as Node3D
		if j and blocos_pisca.any(func(b: BlocoPisca) -> bool: return b.global_position.distance_to(j.global_position) < 22.0):
			Sfx.play(self, "tique", -6.0, 0.0)


func _process(delta: float) -> void:
	super(delta)
	if _engrenagem:
		_engrenagem.rotation.z += delta * 0.3
	if _martelo_visual:
		_martelo_visual.rotation.y += delta * 1.6
		_martelo_visual.position.y = sin(_tempo * 1.5) * 0.3
	if _cabeca_impressora:
		_cabeca_impressora.position.y = TOPO_MAQUINAS + 8.0 - maxf(0.0, sin(_tempo * PI / 2.4)) * 3.0
	if ponte_rolante and _viga:
		var p := ponte_rolante.global_position
		_viga.position = Vector3(p.x, 30, p.z)
		var gancho := p.y + 5.0
		_cabo.position = Vector3(p.x, (gancho + 30.0) * 0.5, p.z)
		_cabo.scale = Vector3(1, maxf(0.1, 30.0 - gancho), 1)
	if _estrela_do_gancho and _estrela_do_gancho.visible:
		_estrela_do_gancho.rotation.y += delta * 0.8


# --- luz ------------------------------------------------------------------------------------

## Galpão de dia: fundo claro, luz ambiente branca e o sol entrando por cima, com sombra.
func _montar_ceu_e_luz() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("bcd3ee")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("f3efe6")
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.82
	# Sem isto o galpão ficava desbotado (quase tudo branco): um pouco mais de cor e de contraste.
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.2
	env.adjustment_contrast = 1.08
	env.ssao_enabled = true
	env.glow_enabled = true
	env.glow_intensity = 0.4
	env.glow_hdr_threshold = 1.2
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-60, 30, 0)
	sol.light_color = Color("fff6e6")
	sol.light_energy = 1.2
	sol.shadow_enabled = true
	sol.shadow_opacity = 0.7
	sol.directional_shadow_max_distance = 140.0
	add_child(sol)


func _montar_nuvens() -> void:
	pass

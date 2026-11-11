class_name HubFarol
extends Fase
## Dentro do farol: o hub da Parte 2 (seção 11 do doc). Uma torre redonda e alta, mais larga do que o farol
## por fora, com quatro andares: o térreo, dois andares de sacada e o topo, a sala da lâmpada. Cada andar é
## um mundo, com as portas das fases na parede. Uma escada em espiral (pedido do usuário em 2026-10-29) sobe
## pelo vão do meio, em volta do eixo da lâmpada: cada lance sobe um andar e termina num patamar colado na
## sacada, por onde se entra nela. Murinhas, com paredes invisíveis mais altas que o pulo, seguram o Faísca
## na escada e nas sacadas. As 8 estrelinhas do farol ficam na escada e também contam.
## Cada porta mostra a imagem da fase, um ícone (nuvem para as do céu, casinha para as do chão) e quantas
## estrelinhas pede; fechada tem cadeado. A do topo, para a nave do Rei Bolotão, pede as Estrelas Grandes.
## O teto é o céu apagado: cada Estrela Grande devolvida acende uma constelação.
## Os Faisquinhas salvos (item 1 da lista do Faísca, 2026-11-11) moram aqui, cada um no andar do mundo de onde veio
## (os da 1-x no térreo, os da 2-x no 2º andar, os da 3-x no 3º), brincando nas vagas livres do anel. Com 10, eles
## consertam o elevador (a plataforma laranja que sobe e desce pelo vão das sacadas, a sudeste, parando em cada
## andar); com 20, o trenzinho de brinquedo roda em volta do eixo no térreo, com dois Faisquinhas de passageiros;
## com 30, o farolete do topo acende e os fachos giram pela torre. Antes disso, uma placa mostra quantos faltam.
## No térreo ficam também a Máquina de Brindes (a sudoeste), a estante das figurinhas (na parede a noroeste) e o
## cabide das roupinhas do Faísca (ao norte), do item 4 da lista (2026-11-11).
## O FaiscaJogo preenche `portas` antes de pôr o hub na árvore e escuta `porta_escolhida`. A porta "saida" (que
## voltava para a ilha) não é mais usada desde que o menu principal separou os dois jogos (2026-11-10).
## Ângulos em graus, como os das portas: 0 norte (-Z), 90 leste (+X), 180 sul, 270 oeste.

signal porta_escolhida(id: String)
signal saiu

const RAIO := 12.0
## Altura do piso de cada andar: térreo, 2º, 3º e topo.
const ANDARES := [0.0, 7.0, 14.0, 21.0]
## Altura da parede, até o começo do domo.
const ALTURA := 27.0
const RAIO_EIXO := 1.4
## As sacadas vão da beira (SACADA) até a parede; a escada passa entre o vão do meio e elas.
const SACADA := 7.5
const ESCADA_DENTRO := 4.5
## O primeiro lance sai do térreo a oeste-noroeste (longe das portas) e sobe pelo norte. Cada lance gira
## LANCE graus em DEGRAUS degraus e termina num patamar de PATAMAR graus; o seguinte sai do fim do patamar.
## Assim os patamares ficam a leste (2º andar e topo) e a oeste (3º).
const ESCADA_COMECO := 285.0
const LANCE := 150.0
const PATAMAR := 30.0
const DEGRAUS := 35
## Altura da murinha que se vê, e da parede invisível nas beiradas (o pulo com os jatos chega a uns 2,5 m).
const MURINHA := 1.0
const PAREDE_INVISIVEL := 3.2
## O vão do elevador: no meio a sudeste (entre as portas e longe dos patamares), largo ELEVADOR_ABERTURA graus.
const ELEVADOR_GRAUS := 135.0
const ELEVADOR_ABERTURA := 24.0
const ELEVADOR_RAIO := 9.9
## O trilho do trenzinho, em volta do eixo no térreo.
const TREM_RAIO := 3.2
const TREM_VELOCIDADE := 0.25
## Onde ficam as placas dos prêmios que faltam (graus, raio, andar).
const PLACAS := {"elevador": [118.0, 7.6, 0], "trem": [180.0, 5.6, 0], "farolete": [55.0, 9.6, 3]}
const PEDE := {"elevador": 10, "trem": 20, "farolete": 30}
## O modelo do troféu de cada chefe.
const MODELOS_DOS_CHEFES := {"chefe-1": ChefeBolotao.MODELO, "chefe-2": ChefeChef.MODELO}
## Os móveis dos brindes no térreo (graus, raio).
const MAQUINA := [225.0, 9.4]
const ESTANTE := [325.0, 11.25]
const CABIDE := [354.0, 10.2]
const MADEIRA := Color("c98b55")
const MADEIRA_CLARA := Color("dca46c")
const CREME := Color("f3ead8")
const LARANJA := Color("ff7a22")
## Constelações do teto, por fase: pontos em (giro, altura) em graus no domo, ligados em ordem.
const CONSTELACOES := {
	"1-1": [Vector2(200, 50), Vector2(222, 58), Vector2(246, 54), Vector2(258, 40), Vector2(236, 34), Vector2(212, 38)],
	"1-2": [Vector2(300, 46), Vector2(318, 60), Vector2(338, 50), Vector2(330, 34), Vector2(310, 32)],
	"2-1": [Vector2(20, 40), Vector2(38, 54), Vector2(58, 46), Vector2(52, 32), Vector2(30, 30)],
	"2-2": [Vector2(80, 58), Vector2(98, 48), Vector2(118, 56), Vector2(110, 38), Vector2(90, 36)],
	"2-3": [Vector2(140, 36), Vector2(156, 50), Vector2(176, 44), Vector2(186, 30), Vector2(162, 28)],
	"3-1": [Vector2(10, 70), Vector2(50, 78), Vector2(95, 72), Vector2(70, 65)],
	"3-2": [Vector2(130, 70), Vector2(170, 78), Vector2(215, 72), Vector2(190, 65)],
	"3-3": [Vector2(250, 70), Vector2(290, 78), Vector2(335, 72), Vector2(310, 65)],
	# Os chefes: uma coroa de cinco pontas (a do andar 1 no lado norte do domo).
	"chefe-1": [Vector2(340, 25), Vector2(345, 38), Vector2(352, 30), Vector2(0, 40), Vector2(8, 30), Vector2(15, 38), Vector2(20, 25)],
	# O chapéu de cozinheiro do Chef, no lado leste, embaixo.
	"chefe-2": [Vector2(100, 18), Vector2(98, 28), Vector2(106, 34), Vector2(114, 30), Vector2(122, 34), Vector2(130, 28), Vector2(128, 18)],
}

## Uma por porta: {id, nome, tipo ("ceu", "chao", "nave" ou "saida"), andar (0 é o térreo), lado (graus),
## pede, pede_grandes, falta, aberta, feita, imagem, grande, achados, total_faisquinhas}.
var portas: Array = []
## Os Faisquinhas salvos, um por item: {fase, id, andar, chegando}; os que chegam agora caem do alto.
var moradores_dados: Array = []
var moradores: Array[Faisquinha] = []
## Prêmios abertos ("elevador", "trem", "farolete"), os que ainda não tiveram festa e o total de Faisquinhas.
var premios: Array = []
var premios_novos: Array = []
var total_faisquinhas := 0
var elevador: ElevadorFarol
## Os chefes vencidos (ids das portas): o troféu dourado aparece do lado da porta de cada um.
var chefes: Array = []
## Os brindes que já saíram da máquina (ids de Brindes), e os três móveis deles.
var brindes: Array = []
var maquina: MaquinaDeBrindes
var estante: EstanteDeFigurinhas
var cabide: CabideDeRoupas
var trem: Array[AnimatableBody3D] = []
var farolete: Node3D
## Estrelas Grandes já devolvidas (ids das fases): acendem as constelações.
var grandes: Array = []
## Porta onde o Faísca aparece (voltando de uma fase); vazio é a entrada, no sul.
var volta_de := ""
var portas_nos := {}
var _tempo_hub := 0.0


func _montar() -> void:
	nome = "Farol"
	superficie = "madeira"
	limite_queda = -6.0
	inicio = Vector3(0, 0.1, RAIO - 3.5)
	_sala()
	_eixo_e_lampada()
	_escada()
	_sacadas()
	_teto()
	_elevador()
	if "trem" in premios:
		_trem()
	if "farolete" in premios:
		_farolete()
	for premio in PEDE:
		if not premio in premios:
			_placa(premio)
	_moveis_dos_brindes()
	_trofeus()
	for p in portas:
		var porta := PortaFase.new()
		porta.dados = p
		var a := deg_to_rad(float(p.lado))
		# Norte é -Z; a porta olha para o meio da sala.
		var fora := Vector3(sin(a), 0, -cos(a))
		porta.position = fora * (RAIO - 0.35) + Vector3.UP * float(ANDARES[int(p.get("andar", 0))])
		porta.rotation.y = atan2(-fora.x, -fora.z)
		add_child(porta)
		porta.tocada.connect(_porta_tocada)
		portas_nos[p.id] = porta
		if p.id == volta_de:
			inicio = porta.position - fora * 3.4 + Vector3.UP * 0.1
	_moradores()


## Para onde o Faísca olha ao aparecer (o yaw do Jogador: 0 olha para -Z).
func yaw_inicial() -> float:
	if volta_de == "" or not portas_nos.has(volta_de):
		return 0.0
	var d: Vector3 = -portas_nos[volta_de].position
	return atan2(-d.x, -d.z)


## Total de estrelinhas mudou (as da escada): atualiza quantas faltam e destranca a porta que chegou lá.
## A porta da nave depende das Estrelas Grandes, que só mudam fora do farol.
func atualizar_portas(total: int) -> void:
	for p in portas:
		if p.tipo == "saida" or p.aberta or int(p.get("pede_grandes", 0)) > 0:
			continue
		p.falta = maxi(int(p.pede) - total, 0)
		if p.falta == 0:
			portas_nos[p.id].destrancar()


## Ponto a `graus` (como os das portas), a `raio` do meio e na altura `y`.
static func ponto(graus: float, raio: float, y := 0.0) -> Vector3:
	var a := deg_to_rad(graus)
	return Vector3(sin(a) * raio, y, -cos(a) * raio)


## Onde começa o lance `k` da escada (o 0 sai do térreo), em graus.
static func comeco_do_lance(k: int) -> float:
	return ESCADA_COMECO + 180.0 * k


## Altura do piso no lance `k`, `giro` graus depois do começo dele (no patamar, a do andar de cima).
static func altura_na_escada(k: int, giro: float) -> float:
	return lerpf(ANDARES[k], ANDARES[k + 1], clampf(giro / LANCE, 0.0, 1.0))


func _porta_tocada(p: Dictionary) -> void:
	if p.tipo == "saida":
		saiu.emit()
	elif p.aberta and p.feita:
		porta_escolhida.emit(p.id)


func _sala() -> void:
	var chao := StaticBody3D.new()
	add_child(chao)
	var piso := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = RAIO
	cil.bottom_radius = RAIO
	cil.height = 1.0
	cil.radial_segments = 48
	piso.mesh = cil
	piso.material_override = _material(MADEIRA)
	piso.position.y = -0.5
	chao.add_child(piso)
	var cs := CollisionShape3D.new()
	var forma := CylinderShape3D.new()
	forma.radius = RAIO + 1.0
	forma.height = 1.0
	cs.shape = forma
	cs.position.y = -0.5
	chao.add_child(cs)
	# Tapete redondo de faixas laranja e branca, as cores do Faísca.
	for k in 3:
		var tapete := MeshInstance3D.new()
		var disco := CylinderMesh.new()
		disco.top_radius = 7.5 - k * 1.6
		disco.bottom_radius = disco.top_radius
		disco.height = 0.04
		disco.radial_segments = 48
		tapete.mesh = disco
		tapete.material_override = _material(LARANJA if k % 2 == 0 else Color("f6efe2"))
		tapete.position.y = 0.02 + k * 0.005
		add_child(tapete)
	# Parede: um cilindro virado para dentro, creme com uma faixa laranja em cada andar.
	var parede := MeshInstance3D.new()
	var tubo := CylinderMesh.new()
	tubo.top_radius = RAIO
	tubo.bottom_radius = RAIO
	tubo.height = ALTURA
	tubo.radial_segments = 48
	tubo.cap_top = false
	tubo.cap_bottom = false
	tubo.flip_faces = true
	parede.mesh = tubo
	parede.material_override = _material(CREME)
	parede.position.y = ALTURA * 0.5
	add_child(parede)
	for andar in ANDARES:
		var faixa := MeshInstance3D.new()
		var anel := CylinderMesh.new()
		anel.top_radius = RAIO - 0.03
		anel.bottom_radius = RAIO - 0.03
		anel.height = 0.8
		anel.radial_segments = 48
		anel.cap_top = false
		anel.cap_bottom = false
		anel.flip_faces = true
		faixa.mesh = anel
		faixa.material_override = _material(LARANJA)
		faixa.position.y = andar + 1.0
		add_child(faixa)
	# A colisão da parede fica um pouco para dentro: o braço da câmera, raspando de lado, para nela antes
	# de passar da parede que se vê (senão a câmera vai para fora e a torre some de um lado da tela).
	var muro := StaticBody3D.new()
	add_child(muro)
	var lados := 32
	for k in lados:
		var a := TAU * k / lados
		var parte := CollisionShape3D.new()
		var caixa := BoxShape3D.new()
		caixa.size = Vector3(2.0 * PI * RAIO / lados + 0.6, ALTURA, 1.0)
		parte.shape = caixa
		parte.position = Vector3(sin(a), 0, cos(a)) * (RAIO + 0.15) + Vector3.UP * ALTURA * 0.5
		parte.rotation.y = a
		muro.add_child(parte)
	# Janelinhas redondas com o azul de fora, entre as portas de cada andar.
	var vidro := StandardMaterial3D.new()
	vidro.albedo_color = Color("bfe6ff")
	vidro.emission_enabled = true
	vidro.emission = Color("8fd0ff")
	vidro.emission_energy_multiplier = 0.8
	for andar in ANDARES:
		for k in 4:
			var a := TAU * (k + 0.5) / 4.0
			var janela := MeshInstance3D.new()
			var disco := CylinderMesh.new()
			disco.top_radius = 0.9
			disco.bottom_radius = 0.9
			disco.height = 0.1
			janela.mesh = disco
			janela.material_override = vidro
			var fora := Vector3(sin(a), 0, cos(a))
			janela.position = fora * (RAIO - 0.06) + Vector3.UP * (andar + 3.4)
			janela.rotation = Vector3(PI / 2.0, a, 0)
			add_child(janela)


## O eixo listrado no meio, do chão até o topo, com a lâmpada ciano em cima (a luz do farol vista de dentro).
func _eixo_e_lampada() -> void:
	var topo: float = ANDARES[-1] + 0.8
	var eixo := StaticBody3D.new()
	add_child(eixo)
	var pedacos := 11
	for k in pedacos:
		var pedaco := MeshInstance3D.new()
		var cil := CylinderMesh.new()
		cil.top_radius = RAIO_EIXO
		cil.bottom_radius = RAIO_EIXO
		cil.height = topo / pedacos
		pedaco.mesh = cil
		pedaco.material_override = _material(LARANJA if k % 2 == 1 else Color("f4f5f9"))
		pedaco.position.y = (k + 0.5) * topo / pedacos
		eixo.add_child(pedaco)
	var cs := CollisionShape3D.new()
	var forma := CylinderShape3D.new()
	forma.radius = RAIO_EIXO
	forma.height = topo
	cs.shape = forma
	cs.position.y = topo * 0.5
	eixo.add_child(cs)
	var vidro := StandardMaterial3D.new()
	vidro.albedo_color = Color(0.75, 1.0, 1.0, 0.45)
	vidro.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vidro.emission_enabled = true
	vidro.emission = FarolModelo.LUZ
	vidro.emission_energy_multiplier = 1.2
	var lampada := MeshInstance3D.new()
	var tubo := CylinderMesh.new()
	tubo.top_radius = 1.9
	tubo.bottom_radius = 1.9
	tubo.height = 2.6
	lampada.mesh = tubo
	lampada.material_override = vidro
	lampada.position.y = topo + 1.3
	add_child(lampada)
	var miolo := MeshInstance3D.new()
	var bola := SphereMesh.new()
	bola.radius = 0.9
	bola.height = 1.8
	miolo.mesh = bola
	var brilho := StandardMaterial3D.new()
	brilho.albedo_color = Color("e8ffff")
	brilho.emission_enabled = true
	brilho.emission = FarolModelo.LUZ
	brilho.emission_energy_multiplier = 4.0
	miolo.material_override = brilho
	miolo.position.y = topo + 1.3
	add_child(miolo)
	var telhado := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.25
	cone.bottom_radius = 2.3
	cone.height = 1.3
	telhado.mesh = cone
	telhado.material_override = _material(Color("d8433b"))
	telhado.position.y = topo + 3.25
	add_child(telhado)
	# A lâmpada e o telhadinho dela são sólidos, no mesmo corpo do eixo: no topo, o Faísca não entra no vidro.
	var cs_lampada := CollisionShape3D.new()
	var cil_lampada := CylinderShape3D.new()
	cil_lampada.radius = 1.9
	cil_lampada.height = 2.6
	cs_lampada.shape = cil_lampada
	cs_lampada.position.y = topo + 1.3
	eixo.add_child(cs_lampada)
	var cs_telhado := CollisionShape3D.new()
	cs_telhado.shape = cone.create_convex_shape()
	cs_telhado.position.y = topo + 3.25
	eixo.add_child(cs_telhado)
	var luz := OmniLight3D.new()
	luz.light_color = FarolModelo.LUZ
	luz.light_energy = 2.5
	luz.omni_range = 14.0
	luz.position.y = topo + 1.3
	add_child(luz)


## A escada em espiral: degraus de madeira (um claro, um escuro), murinha creme com a borda laranja dos
## dois lados (do lado de fora só no lance; o patamar abre para a sacada) e, por baixo dos degraus, uma
## colisão lisa de rampa, para o Faísca subir sem tropeçar. As 8 estrelinhas do farol ficam no caminho.
func _escada() -> void:
	var claro := _malha()
	var escuro := _malha()
	var creme := _malha()
	var laranja := _malha()
	var colisao := _malha()
	var passo := LANCE / DEGRAUS
	for k in ANDARES.size() - 1:
		var c := comeco_do_lance(k)
		var de: float = ANDARES[k]
		var ate: float = ANDARES[k + 1]
		var subida := (ate - de) / DEGRAUS
		# A rampa lisa passa no meio de cada degrau: o pé fica no máximo meio degrau (10 cm) acima ou abaixo.
		# As pontas dos degraus entram um pouco nas murinhas, sem encostar na face delas (piscaria).
		for i in DEGRAUS:
			var topo := de + (i + 0.5) * subida
			_bloco(escuro if i % 2 == 1 else claro, ESCADA_DENTRO + 0.05, SACADA - 0.05, c + i * passo, c + (i + 1) * passo,
					topo, topo, subida + 0.35)
		var fim := c + LANCE + PATAMAR
		_bloco(claro, ESCADA_DENTRO + 0.05, SACADA, c + LANCE, fim, ate, ate, 0.4)
		_bloco(colisao, ESCADA_DENTRO, SACADA, c, c + LANCE, de, ate, 0.6)
		_bloco(colisao, ESCADA_DENTRO, SACADA, c + LANCE, fim, ate, ate, 0.6)
		_murinha(creme, laranja, colisao, ESCADA_DENTRO, ESCADA_DENTRO + 0.2, c, c + LANCE, de, ate)
		_murinha(creme, laranja, colisao, ESCADA_DENTRO, ESCADA_DENTRO + 0.2, c + LANCE, fim, ate, ate)
		_murinha(creme, laranja, colisao, SACADA - 0.2, SACADA, c, c + LANCE, de, ate)
	# O último patamar, no topo, termina numa murinha atravessada.
	var ultimo := comeco_do_lance(ANDARES.size() - 2) + LANCE + PATAMAR
	_murinha(creme, laranja, colisao, ESCADA_DENTRO, SACADA, ultimo - 1.5, ultimo, ANDARES[-1], ANDARES[-1])
	_pintar(claro, MADEIRA_CLARA)
	_pintar(escuro, MADEIRA)
	_pintar(creme, CREME)
	_pintar(laranja, LARANJA)
	_solido(colisao)
	# Estrelinhas: 4 no primeiro lance e 2 em cada um dos outros (a fração do lance onde fica cada uma).
	var meio := (ESCADA_DENTRO + SACADA) * 0.5
	for e in [[0, 0.2], [0, 0.42], [0, 0.64], [0, 0.86], [1, 0.35], [1, 0.75], [2, 0.35], [2, 0.75]]:
		var giro: float = e[1] * LANCE
		estrelinha(ponto(comeco_do_lance(e[0]) + giro, meio, altura_na_escada(e[0], giro) + 1.1))


## As sacadas dos andares de cima: piso de madeira da beira (SACADA) até a parede, com a faixa laranja na
## beira e a murinha, menos no patamar da escada, por onde se chega.
func _sacadas() -> void:
	var madeira := _malha()
	var creme := _malha()
	var laranja := _malha()
	var colisao := _malha()
	var com_vao := "elevador" in premios
	var g0 := ELEVADOR_GRAUS - ELEVADOR_ABERTURA * 0.5
	var g1 := ELEVADOR_GRAUS + ELEVADOR_ABERTURA * 0.5
	for k in range(1, ANDARES.size()):
		var y: float = ANDARES[k]
		if com_vao:
			# O anel sem o vão, e a tira de dentro (embaixo da murinha) que passa na frente dele.
			_bloco(madeira, SACADA, RAIO, g1, g0 + 360.0, y, y, 0.4)
			_bloco(colisao, SACADA, RAIO + 0.3, g1, g0 + 360.0, y, y, 0.4)
			_bloco(madeira, SACADA, ElevadorFarol.DENTRO - 0.1, g0, g1, y, y, 0.4)
			_bloco(colisao, SACADA, ElevadorFarol.DENTRO - 0.1, g0, g1, y, y, 0.4)
		else:
			_bloco(madeira, SACADA, RAIO, 0.0, 360.0, y, y, 0.4)
			_bloco(colisao, SACADA, RAIO + 0.3, 0.0, 360.0, y, y, 0.4)
		var chegada := comeco_do_lance(k - 1) + LANCE + PATAMAR
		_bloco(laranja, SACADA - 0.05, SACADA + 0.05, chegada, chegada + 360.0 - PATAMAR, y - 0.02, y - 0.02, 0.42)
		_murinha(creme, laranja, colisao, SACADA, SACADA + 0.2, chegada, chegada + 360.0 - PATAMAR, y, y)
	_pintar(madeira, MADEIRA)
	_pintar(creme, CREME)
	_pintar(laranja, LARANJA)
	_solido(colisao)


## Murinha entre os raios `r1` e `r2`, de `a` a `b` graus, em cima de um piso que vai de `piso_a` a `piso_b`:
## creme com a borda laranja e, só de colisão, a parede invisível até PAREDE_INVISIVEL acima do piso.
func _murinha(creme: SurfaceTool, laranja: SurfaceTool, colisao: SurfaceTool, r1: float, r2: float, a: float, b: float,
		piso_a: float, piso_b: float) -> void:
	_bloco(creme, r1, r2, a, b, piso_a + MURINHA, piso_b + MURINHA, MURINHA + 0.7)
	_bloco(laranja, r1 - 0.04, r2 + 0.04, a, b, piso_a + MURINHA + 0.1, piso_b + MURINHA + 0.1, 0.14)
	_bloco(colisao, r1, r2, a, b, piso_a + PAREDE_INVISIVEL, piso_b + PAREDE_INVISIVEL, PAREDE_INVISIVEL + 0.6)


## Bloco curvo (um pedaço de anel entre os raios `r1` e `r2`, de `a` a `b` graus), com o topo indo em linha
## reta de `topo_a` a `topo_b` e `grossura` de altura. Acrescenta os triângulos em `st`.
func _bloco(st: SurfaceTool, r1: float, r2: float, a: float, b: float, topo_a: float, topo_b: float, grossura: float) -> void:
	var n := maxi(1, ceili(absf(b - a) / 6.0))
	var baixo := Vector3.DOWN * grossura
	for i in n:
		var g0 := lerpf(a, b, float(i) / n)
		var g1 := lerpf(a, b, float(i + 1) / n)
		var t0 := lerpf(topo_a, topo_b, float(i) / n)
		var t1 := lerpf(topo_a, topo_b, float(i + 1) / n)
		var d0 := ponto(g0, r1, t0)
		var f0 := ponto(g0, r2, t0)
		var d1 := ponto(g1, r1, t1)
		var f1 := ponto(g1, r2, t1)
		var meio := ponto((g0 + g1) * 0.5, 1.0)
		_quad(st, d0, f0, f1, d1, Vector3.UP)
		_quad(st, d0 + baixo, f0 + baixo, f1 + baixo, d1 + baixo, Vector3.DOWN)
		_quad(st, d0, d1, d1 + baixo, d0 + baixo, -meio)
		_quad(st, f0, f1, f1 + baixo, f0 + baixo, meio)
		if absf(b - a) < 359.9:
			if i == 0:
				_quad(st, d0, f0, f0 + baixo, d0 + baixo, d0 - d1)
			if i == n - 1:
				_quad(st, d1, f1, f1 + baixo, d1 + baixo, d1 - d0)


## Um quadrilátero com a frente para o lado de `fora`. O Godot desenha a frente no sentido horário.
func _quad(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, fora: Vector3) -> void:
	var n := (p1 - p0).cross(p2 - p0)
	if n.length_squared() < 1e-10:
		n = (p2 - p0).cross(p3 - p0)
	if n.dot(fora) < 0.0:
		var t := p1
		p1 = p3
		p3 = t
		n = -n
	n = n.normalized()
	for v in [p0, p2, p1, p0, p3, p2]:
		st.set_normal(n)
		st.add_vertex(v)


func _malha() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


func _pintar(st: SurfaceTool, cor: Color) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _material(cor)
	add_child(mi)


## Colisão com a forma exata dos blocos (dos dois lados, para não atravessar vindo de baixo).
func _solido(st: SurfaceTool) -> void:
	var corpo := StaticBody3D.new()
	add_child(corpo)
	var cs := CollisionShape3D.new()
	var forma := st.commit().create_trimesh_shape()
	forma.backface_collision = true
	cs.shape = forma
	corpo.add_child(cs)


## Domo escuro (o céu apagado) e as constelações das Estrelas Grandes já devolvidas.
func _teto() -> void:
	var domo := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = RAIO
	esfera.height = RAIO
	esfera.is_hemisphere = true
	esfera.flip_faces = true
	domo.mesh = esfera
	domo.material_override = _material(Color("161f4f"))
	domo.position.y = ALTURA
	domo.scale = Vector3(1, 0.55, 1)
	# O teto fica alto demais para o pulo (só se vê).
	add_child(so_enfeite(domo))
	var acesa := StandardMaterial3D.new()
	acesa.albedo_color = Color("fff1a8")
	acesa.emission_enabled = true
	acesa.emission = Color("ffd23f")
	acesa.emission_energy_multiplier = 2.5
	var apagada := _material(Color("3a4270"))
	var linha := StandardMaterial3D.new()
	linha.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	linha.albedo_color = Color(1.0, 0.9, 0.55, 0.55)
	linha.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for id in CONSTELACOES:
		var ligada: bool = id in grandes
		var pontos: Array[Vector3] = []
		for p in CONSTELACOES[id]:
			var giro := deg_to_rad(p.x)
			var alt := deg_to_rad(p.y)
			var r := RAIO - 0.4
			pontos.append(Vector3(sin(giro) * cos(alt) * r, ALTURA + sin(alt) * r * 0.55, -cos(giro) * cos(alt) * r))
		for k in pontos.size():
			var estrela := MeshInstance3D.new()
			var bola := SphereMesh.new()
			bola.radius = 0.5 if ligada else 0.2
			bola.height = bola.radius * 2.0
			estrela.mesh = bola
			estrela.material_override = acesa if ligada else apagada
			estrela.position = pontos[k]
			add_child(estrela)
			if ligada:
				var b := pontos[(k + 1) % pontos.size()]
				var traco := MeshInstance3D.new()
				var caixa := BoxMesh.new()
				caixa.size = Vector3(0.12, 0.12, pontos[k].distance_to(b))
				traco.mesh = caixa
				traco.material_override = linha
				add_child(traco)
				traco.look_at_from_position((pontos[k] + b) * 0.5, b)


# --- Faisquinhas e prêmios ---------------------------------------------------------------

## Os Faisquinhas salvos, cada um no andar do mundo dele, nas vagas livres do anel (longe das portas, do elevador, das
## placas e de onde a escada chega). Olham para o meio da torre.
func _moradores() -> void:
	var por_andar := {}
	for d in moradores_dados:
		var andar: int = d.andar
		if not por_andar.has(andar):
			por_andar[andar] = vagas_do_andar(andar)
		var vagas: Array = por_andar[andar]
		if vagas.is_empty():
			continue
		var casa: Vector3 = vagas.pop_front()
		var f := Faisquinha.new()
		f.morador = true
		f.id = d.id
		f.name = "Faisquinha_%s_%s" % [d.fase, d.id]
		f.set_meta("fase", d.fase)
		f.casa = casa
		f.olhar_casa = atan2(-casa.x, -casa.z)
		f.position = casa + Vector3.UP * 0.5
		add_child(f)
		f.corpo.rotation.y = f.olhar_casa
		moradores.append(f)
		if d.get("chegando", false):
			f.set_meta("chegando", true)
			f.chegar()


## Vagas para morar no andar: de 15 em 15 graus, em dois anéis (10 m e 8,7 m do meio), sem as que caem perto de uma
## porta, do elevador, de uma placa, da entrada do térreo ou do patamar onde a escada chega.
func vagas_do_andar(andar: int) -> Array:
	var longe := [ELEVADOR_GRAUS]
	for p in portas:
		if int(p.get("andar", 0)) == andar:
			longe.append(float(p.lado))
	for premio in PLACAS:
		if int(PLACAS[premio][2]) == andar:
			longe.append(float(PLACAS[premio][0]))
	if andar == 0:
		longe.append_array([180.0, MAQUINA[0], ESTANTE[0] - 13.0, ESTANTE[0], ESTANTE[0] + 13.0, CABIDE[0]])
	var patamar := -1000.0
	if andar > 0:
		patamar = comeco_do_lance(andar - 1) + LANCE + PATAMAR * 0.5
	var vagas := []
	for r in [10.0, 8.7]:
		for k in 24:
			var g := 7.5 + k * 15.0
			if longe.any(func(a: float) -> bool: return absf(angle_difference(deg_to_rad(g), deg_to_rad(a))) < deg_to_rad(14.0)):
				continue
			if absf(angle_difference(deg_to_rad(g), deg_to_rad(patamar))) < deg_to_rad(26.0):
				continue
			vagas.append(ponto(g, r, ANDARES[andar]))
	return vagas


## O troféu de cada chefe vencido: ele mesmo em miniatura, dourado, num pedestal ao lado da porta dele.
func _trofeus() -> void:
	for p in portas:
		if p.tipo != "chefe" or not p.id in chefes:
			continue
		var g := float(p.lado) + 14.0
		var raiz := Node3D.new()
		raiz.name = "Trofeu_" + String(p.id)
		raiz.position = ponto(g, RAIO - 1.4, ANDARES[int(p.andar)])
		raiz.rotation.y = atan2(-raiz.position.x, -raiz.position.z)
		add_child(raiz)
		var pedestal := MeshInstance3D.new()
		var cil := CylinderMesh.new()
		cil.top_radius = 0.6
		cil.bottom_radius = 0.7
		cil.height = 0.8
		pedestal.mesh = cil
		pedestal.material_override = _material(CREME)
		pedestal.position.y = 0.4
		raiz.add_child(pedestal)
		var corpo := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var forma := CylinderShape3D.new()
		forma.radius = 0.7
		forma.height = 2.2
		cs.shape = forma
		cs.position.y = 1.1
		corpo.add_child(cs)
		raiz.add_child(corpo)
		var estatua: Node3D = load(MODELOS_DOS_CHEFES.get(p.id, ChefeBolotao.MODELO)).instantiate()
		estatua.scale = Vector3.ONE * 0.55
		estatua.position.y = 0.8
		var ouro := StandardMaterial3D.new()
		ouro.albedo_color = Color("ffc93c")
		ouro.metallic = 0.7
		ouro.roughness = 0.25
		for mi: MeshInstance3D in estatua.find_children("*", "MeshInstance3D", true, false):
			mi.material_override = ouro
		raiz.add_child(estatua)
		var luz := OmniLight3D.new()
		luz.light_color = Color("ffe9a8")
		luz.light_energy = 1.2
		luz.omni_range = 3.0
		luz.position.y = 2.2
		raiz.add_child(luz)


## A Máquina de Brindes, a estante e o cabide, no térreo, virados para o meio da torre.
func _moveis_dos_brindes() -> void:
	maquina = MaquinaDeBrindes.new()
	maquina.name = "MaquinaDeBrindes"
	_no_terreo(maquina, MAQUINA)
	estante = EstanteDeFigurinhas.new()
	estante.name = "Estante"
	_no_terreo(estante, ESTANTE)
	estante.mostrar(brindes)
	cabide = CabideDeRoupas.new()
	cabide.name = "Cabide"
	_no_terreo(cabide, CABIDE)
	cabide.mostrar(brindes)


func _no_terreo(no: Node3D, onde: Array) -> void:
	no.position = ponto(onde[0], onde[1], 0.0)
	no.rotation.y = atan2(-no.position.x, -no.position.z)
	add_child(no)


## Festa dos prêmios novos e das chegadas: os Faisquinhas pulam e acenam.
func festa() -> void:
	for f in moradores:
		f.comemorar()


## Onde fica cada prêmio (para o confete da festa).
func lugar_do_premio(premio: String) -> Vector3:
	match premio:
		"elevador":
			return ponto(ELEVADOR_GRAUS, ELEVADOR_RAIO, 2.5)
		"trem":
			return ponto(180.0, TREM_RAIO, 1.5)
		"farolete":
			return Vector3(0, ANDARES[-1] + 2.0, 0)
	return Vector3.ZERO


## O elevador no vão a sudeste. Quebrado (antes de 10 Faisquinhas), fica parado no térreo, torto e apagado.
func _elevador() -> void:
	elevador = ElevadorFarol.new()
	elevador.funcionando = "elevador" in premios
	elevador.andares = ANDARES
	# O x de dentro dele aponta para fora da torre (do meio para a parede) e o z corre ao longo do anel.
	var a := deg_to_rad(ELEVADOR_GRAUS)
	elevador.rotation.y = atan2(cos(a), sin(a))
	elevador.position = ponto(ELEVADOR_GRAUS, ELEVADOR_RAIO, 0.0)
	add_child(elevador)
	if elevador.funcionando:
		# As cancelas dos andares de cima, uma de cada lado do vão: fechadas quando o elevador não está ali.
		for k in range(1, ANDARES.size()):
			for lado in [-1.0, 1.0]:
				var g: float = ELEVADOR_GRAUS + lado * (ELEVADOR_ABERTURA * 0.5 + 0.8)
				var c := Cancela.new()
				c.andar = k
				c.position = ponto(g, (ElevadorFarol.DENTRO + RAIO) * 0.5, ANDARES[k])
				var b := deg_to_rad(g)
				c.rotation.y = atan2(cos(b), sin(b))
				add_child(c)
				elevador.cancelas.append(c)


## O trenzinho: o trilho redondo em volta do eixo e a locomotiva, o tênder dos presentes e o vagão, cada um uma peça
## que gira em volta do meio (dá para subir em cima), com dois Faisquinhas de passageiros no vagão.
func _trem() -> void:
	for raio in [TREM_RAIO - 0.45, TREM_RAIO + 0.45]:
		var trilho := MeshInstance3D.new()
		var anel := TorusMesh.new()
		anel.inner_radius = raio - 0.06
		anel.outer_radius = raio + 0.06
		anel.rings = 48
		trilho.mesh = anel
		trilho.material_override = _material(Color("8a8fa6"))
		trilho.scale = Vector3(1, 0.4, 1)
		trilho.position.y = 0.05
		add_child(trilho)
	for k in 24:
		var dormente := MeshInstance3D.new()
		var caixa := BoxMesh.new()
		caixa.size = Vector3(1.3, 0.06, 0.25)
		dormente.mesh = caixa
		dormente.material_override = _material(MADEIRA)
		var g := k * 15.0
		dormente.position = ponto(g, TREM_RAIO, 0.03)
		dormente.rotation.y = deg_to_rad(-g)
		add_child(dormente)
	# [modelo, comprimento, altura do teto] (em 2,6x: a locomotiva tem 1,7 m de altura e o vagão 1,9 m).
	var pecas := [["train_locomotive", 2.2, 1.7], ["train_tender_presents_A", 1.7, 1.3], ["train_wagon", 2.5, 1.9]]
	var angulo := 0.0
	for i in pecas.size():
		var carro := AnimatableBody3D.new()
		carro.name = "Trem_%d" % i
		carro.sync_to_physics = false
		carro.set_meta("angulo", angulo)
		# Quem move os carros é o farol (no _physics_process dele), por isso sem sync_to_physics: com ele ligado, a
		# posição voltava para a anterior a cada quadro e o trem ficava parado (visto em 2026-11-11).
		carro.position = Vector3(cos(angulo) * TREM_RAIO, 0.05, -sin(angulo) * TREM_RAIO)
		carro.rotation.y = angulo + PI
		var modelo: Node3D = load(Fase.QUARTO + pecas[i][0] + ".gltf").instantiate()
		modelo.scale = Vector3.ONE * 2.6
		carro.add_child(modelo)
		var cs := CollisionShape3D.new()
		var forma := BoxShape3D.new()
		forma.size = Vector3(1.1, pecas[i][2], pecas[i][1])
		cs.shape = forma
		cs.position.y = pecas[i][2] * 0.5
		carro.add_child(cs)
		if pecas[i][0] == "train_wagon":
			# Os dois passageiros vão sentados no teto do vagão, um olhando para cada lado.
			for lado in [-1.0, 1.0]:
				var passageiro := Faisquinha.boneco(Faisquinha.cor_de(2 if lado < 0.0 else 4))
				passageiro.position = Vector3(0, pecas[i][2], lado * 0.6)
				passageiro.rotation.y = lado * PI / 2.0
				passageiro.name = "Passageiro%d" % (0 if lado < 0.0 else 1)
				carro.add_child(passageiro)
		add_child(carro)
		trem.append(carro)
		if i + 1 < pecas.size():
			angulo -= (pecas[i][1] * 0.5 + 0.3 + pecas[i + 1][1] * 0.5) / TREM_RAIO
	_mover_trem(0.0)


## Os carros andam no sentido anti-horário visto de cima, com a frente (+Z deles) para onde vão.
func _mover_trem(tempo: float) -> void:
	for carro in trem:
		var a: float = carro.get_meta("angulo") + tempo * TREM_VELOCIDADE
		carro.position = Vector3(cos(a) * TREM_RAIO, 0.05, -sin(a) * TREM_RAIO)
		carro.rotation.y = a + PI
		for p in carro.get_children():
			if p.name.begins_with("Passageiro"):
				p.position.y = 1.9 + absf(sin(tempo * 5.0 + p.position.z * 3.0)) * 0.1


## O farolete aceso: a lâmpada mais forte e dois fachos que giram pela torre, cada um com um holofote que passa pela
## parede.
func _farolete() -> void:
	farolete = Node3D.new()
	farolete.name = "Farolete"
	farolete.position.y = ANDARES[-1] + 0.8 + 1.3
	add_child(farolete)
	var luz := StandardMaterial3D.new()
	luz.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	luz.albedo_color = Color(FarolModelo.LUZ, 0.1)
	luz.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	luz.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	luz.cull_mode = BaseMaterial3D.CULL_DISABLED
	for lado in [-1.0, 1.0]:
		var facho := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.5
		cone.bottom_radius = 2.4
		cone.height = 9.5
		facho.mesh = cone
		facho.material_override = luz
		facho.rotation.z = lado * PI / 2.0
		facho.position.x = lado * (1.9 + 4.75)
		farolete.add_child(facho)
		var holofote := SpotLight3D.new()
		holofote.light_color = FarolModelo.LUZ
		holofote.light_energy = 6.0
		holofote.spot_range = 14.0
		holofote.spot_angle = 16.0
		holofote.position.x = lado * 1.9
		holofote.rotation.y = -lado * PI / 2.0
		farolete.add_child(holofote)
	var forte := OmniLight3D.new()
	forte.light_color = FarolModelo.LUZ
	forte.light_energy = 3.0
	forte.omni_range = 10.0
	farolete.add_child(forte)


## A placa de um prêmio que ainda falta: o desenho dele em cima, um Faisquinha e "quantos tem/quantos pede".
func _placa(premio: String) -> void:
	var spec: Array = PLACAS[premio]
	var raiz := Node3D.new()
	raiz.name = "Placa_" + premio
	raiz.position = ponto(spec[0], spec[1], ANDARES[int(spec[2])])
	# Virada para o meio da torre (a do trem, no meio, para a entrada ao sul).
	var para := Vector3(0, 0, RAIO) - raiz.position if premio == "trem" else -raiz.position
	raiz.rotation.y = atan2(para.x, para.z)
	add_child(raiz)
	var poste := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = 0.08
	cil.bottom_radius = 0.08
	cil.height = 1.5
	poste.mesh = cil
	poste.material_override = _material(MADEIRA)
	poste.position.y = 0.75
	raiz.add_child(poste)
	var tabua := MeshInstance3D.new()
	var caixa := BoxMesh.new()
	caixa.size = Vector3(1.9, 1.0, 0.12)
	tabua.mesh = caixa
	tabua.material_override = _material(MADEIRA_CLARA)
	tabua.position.y = 1.8
	raiz.add_child(tabua)
	# O poste e a tábua seguram o Faísca (o revisor de física cobra).
	var corpo := StaticBody3D.new()
	for parte in [[Vector3(0.2, 1.5, 0.2), Vector3(0, 0.75, 0)], [Vector3(1.9, 1.0, 0.12), Vector3(0, 1.8, 0)]]:
		var cs := CollisionShape3D.new()
		var forma := BoxShape3D.new()
		forma.size = parte[0]
		cs.shape = forma
		cs.position = parte[1]
		corpo.add_child(cs)
	raiz.add_child(corpo)
	var numero := Label3D.new()
	numero.name = "Numero"
	numero.text = "%d/%d" % [total_faisquinhas, PEDE[premio]]
	numero.font_size = 64
	numero.pixel_size = 0.01
	numero.outline_size = 14
	numero.outline_modulate = Color(0.08, 0.06, 0.18)
	numero.modulate = Color("ffd23f")
	numero.position = Vector3(0.35, 1.8, 0.08)
	raiz.add_child(numero)
	var boneco := Faisquinha.boneco(Faisquinha.cor_de(PEDE.keys().find(premio) + 1))
	boneco.scale = Vector3.ONE * 0.7
	boneco.position = Vector3(-0.55, 1.42, 0.12)
	raiz.add_child(boneco)
	var desenho: Node3D
	match premio:
		"elevador":
			desenho = MeshInstance3D.new()
			var cubo := BoxMesh.new()
			cubo.size = Vector3(0.6, 0.14, 0.6)
			(desenho as MeshInstance3D).mesh = cubo
			(desenho as MeshInstance3D).material_override = _material(LARANJA)
		"trem":
			desenho = load(Fase.QUARTO + "train_locomotive.gltf").instantiate()
			desenho.scale = Vector3.ONE * 0.9
			desenho.rotation.y = PI / 2.0
		"farolete":
			desenho = MeshInstance3D.new()
			var bola := SphereMesh.new()
			bola.radius = 0.22
			bola.height = 0.44
			(desenho as MeshInstance3D).mesh = bola
			var m := StandardMaterial3D.new()
			m.albedo_color = Color("e8ffff")
			m.emission_enabled = true
			m.emission = FarolModelo.LUZ
			m.emission_energy_multiplier = 1.2
			(desenho as MeshInstance3D).material_override = m
	desenho.position.y = 2.45
	raiz.add_child(desenho)


func _physics_process(delta: float) -> void:
	super(delta)
	_tempo_hub += delta
	if not trem.is_empty():
		_mover_trem(_tempo_hub)


func _process(delta: float) -> void:
	super(delta)
	if farolete:
		farolete.rotation.y += delta * 0.6


## Por dentro: sem céu à vista, luz ambiente morna e duas luzes no alto de cada andar, sem sol.
func _montar_ceu_e_luz() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("10162f")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("fff1dc")
	env.ambient_light_energy = 0.85
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.ssao_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	for k in ANDARES.size():
		for j in 2:
			var luz := OmniLight3D.new()
			luz.light_color = Color("ffe2b8")
			luz.light_energy = 1.2
			luz.omni_range = 13.0
			luz.shadow_enabled = k == 0 and j == 0
			luz.position = ponto(45.0 + 180.0 * j + 90.0 * k, 9.0, ANDARES[k] + 5.0)
			add_child(luz)


func _montar_nuvens() -> void:
	pass


## Porta de uma fase na parede do farol (ou a de sair, para a ilha). Frente para +Z.
class PortaFase:
	extends Node3D

	signal tocada(dados: Dictionary)

	const CORES := {"ceu": Color("4aa3ff"), "chao": Color("5cc06a"), "nave": Color("8a4fe0"), "saida": Color("ff7a22"),
		"chefe": Color("e8424f")}

	var dados := {}
	var _cadeado: Node3D
	var _aviso: Label3D
	var _espera := 0.0
	var _quadro_mat: StandardMaterial3D
	## O que só aparece com a porta trancada (o número e a estrelinha do quanto pede).
	var _pede: Array[Node3D] = []

	func _ready() -> void:
		var cor: Color = CORES[dados.tipo]
		var moldura := _mat(cor)
		for x in [-1.55, 1.55]:
			_caixa(Vector3(0.4, 4.2, 0.45), Vector3(x, 2.1, 0), moldura)
		_caixa(Vector3(3.5, 0.5, 0.5), Vector3(0, 4.35, 0), moldura)
		var quadro := MeshInstance3D.new()
		var plano := QuadMesh.new()
		plano.size = Vector2(2.7, 3.85)
		quadro.mesh = plano
		quadro.position = Vector3(0, 2.0, 0.02)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		if dados.tipo == "saida":
			m.albedo_color = Color("d9f3ff")
		elif dados.aberta and dados.feita and dados.imagem != "":
			m.albedo_texture = load(dados.imagem)
			# A foto é larga: mostra o meio dela no quadro em pé.
			m.uv1_scale = Vector3(0.4, 1, 1)
			m.uv1_offset = Vector3(0.3, 0, 0)
		else:
			m.albedo_color = Color("2a2f48")
		quadro.material_override = m
		_quadro_mat = m
		add_child(quadro)
		var titulo := _rotulo(dados.nome, 38, Color.WHITE)
		titulo.position = Vector3(0, 5.15, 0.1)
		add_child(titulo)
		if dados.tipo != "saida":
			_icone(cor)
		if dados.tipo == "saida":
			pass
		elif not dados.aberta:
			_cadeado = _fazer_cadeado()
			_cadeado.position = Vector3(0, 2.2, 0.35)
			add_child(_cadeado)
			# A da nave pede Estrelas Grandes (a estrela do lado do número é maior).
			var grandes := int(dados.get("pede_grandes", 0))
			var pede := _rotulo(str(grandes if grandes > 0 else dados.pede), 72, Color("ffd23f"))
			pede.position = Vector3(0.25, 0.75, 0.3)
			add_child(pede)
			var estrela := MeshInstance3D.new()
			estrela.mesh = Forma.estrela(0.42, 0.19, 0.2) if grandes > 0 else Forma.estrela(0.28, 0.12, 0.12)
			estrela.material_override = _brilho(Color("ffd23f"))
			estrela.position = Vector3(-0.55, 0.78, 0.3)
			add_child(estrela)
			_pede = [pede, estrela]
		elif not dados.feita:
			_em_breve()
		else:
			# Fase aberta: a Estrela Grande no alto (dourada se já devolvida) e os vaga-lumes achados.
			var grande := MeshInstance3D.new()
			grande.mesh = Forma.estrela(0.42, 0.19, 0.2)
			grande.material_override = _brilho(Color("ffd23f")) if dados.grande else _mat(Color("4a4f6a"))
			grande.position = Vector3(0, 4.35, 0.4)
			add_child(grande)
			# As cabecinhas dos Faisquinhas da fase: brancas com a tela preta e a luz da antena os salvos, cinza os outros.
			var n := int(dados.total_faisquinhas)
			for k in n:
				var x := (k - (n - 1) * 0.5) * 0.4
				var salvo := k < int(dados.achados)
				var cabeca := MeshInstance3D.new()
				var bola := SphereMesh.new()
				bola.radius = 0.14
				bola.height = 0.26
				cabeca.mesh = bola
				cabeca.material_override = _mat(Color("f4f5f9")) if salvo else _mat(Color("3a4050"))
				cabeca.position = Vector3(x, 0.32, 0.35)
				add_child(cabeca)
				if salvo:
					var tela := MeshInstance3D.new()
					var caixa_tela := BoxMesh.new()
					caixa_tela.size = Vector3(0.19, 0.11, 0.04)
					tela.mesh = caixa_tela
					tela.material_override = _mat(Color("15121f"))
					tela.position = Vector3(x, 0.32, 0.48)
					add_child(tela)
					var luz := MeshInstance3D.new()
					var bolinha := SphereMesh.new()
					bolinha.radius = 0.045
					bolinha.height = 0.09
					luz.mesh = bolinha
					luz.material_override = _brilho(Faisquinha.cor_de(k))
					luz.position = Vector3(x, 0.52, 0.35)
					add_child(luz)
		_aviso = _rotulo("", 52, Color("ffd23f"))
		_aviso.position = Vector3(0, 3.2, 0.6)
		add_child(_aviso)
		var area := Area3D.new()
		area.collision_layer = 0
		area.collision_mask = Fase.CAMADA_JOGADOR
		var cs := CollisionShape3D.new()
		var caixa := BoxShape3D.new()
		caixa.size = Vector3(2.8, 3.6, 1.4)
		cs.shape = caixa
		cs.position = Vector3(0, 1.8, 0.6)
		area.add_child(cs)
		add_child(area)
		area.body_entered.connect(_encostou)

	func _process(delta: float) -> void:
		_espera -= delta
		if _cadeado:
			_cadeado.rotation.z = lerpf(_cadeado.rotation.z, 0.0, 1.0 - exp(-6.0 * delta))

	func _encostou(corpo: Node3D) -> void:
		if not corpo is Jogador or _espera > 0.0:
			return
		_espera = 1.5
		if dados.tipo != "saida" and not dados.aberta:
			if _cadeado:
				_cadeado.rotation.z = 0.4
			if int(dados.get("pede_grandes", 0)) > 0:
				_mostrar_aviso("Falta 1 Estrela Grande" if int(dados.falta) == 1 else "Faltam %d Estrelas Grandes" % int(dados.falta))
			else:
				_mostrar_aviso("Faltam %d" % int(dados.falta))
		elif dados.tipo != "saida" and not dados.feita:
			_mostrar_aviso("Em breve!")
		tocada.emit(dados)

	## Chegou no número de estrelinhas com a porta à vista: o cadeado cai e a porta abre.
	func destrancar() -> void:
		if dados.aberta:
			return
		dados.aberta = true
		for n in _pede:
			n.queue_free()
		_pede.clear()
		var cadeado := _cadeado
		_cadeado = null
		var tw := cadeado.create_tween()
		tw.tween_property(cadeado, "position:y", -0.6, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(cadeado.queue_free)
		Fx.confetti(self, global_position + Vector3.UP * 2.5, 20, 3.0)
		if dados.feita and dados.imagem != "":
			_quadro_mat.albedo_color = Color.WHITE
			_quadro_mat.albedo_texture = load(dados.imagem)
			_quadro_mat.uv1_scale = Vector3(0.4, 1, 1)
			_quadro_mat.uv1_offset = Vector3(0.3, 0, 0)
		elif not dados.feita:
			_em_breve()

	func _em_breve() -> void:
		var breve := _rotulo("Em breve", 64, Color("ffd23f"))
		breve.position = Vector3(0, 2.0, 0.25)
		add_child(breve)

	func _mostrar_aviso(texto: String) -> void:
		_aviso.text = texto
		_aviso.modulate.a = 1.0
		var tw := _aviso.create_tween()
		tw.tween_interval(1.4)
		tw.tween_property(_aviso, "modulate:a", 0.0, 0.4)

	## Nuvem (fase do céu), casinha (fase do chão) ou disco voador (a nave) em cima da moldura.
	func _icone(cor: Color) -> void:
		var raiz := Node3D.new()
		raiz.position = Vector3(1.25, 4.95, 0.3)
		add_child(raiz)
		if dados.tipo == "chefe":
			# A coroa do capitão.
			var aro := MeshInstance3D.new()
			var cil := CylinderMesh.new()
			cil.top_radius = 0.3
			cil.bottom_radius = 0.26
			cil.height = 0.16
			aro.mesh = cil
			aro.material_override = _brilho(Color("ffc93c"))
			raiz.add_child(aro)
			for k in 5:
				var a := TAU * k / 5.0
				var ponta := MeshInstance3D.new()
				var cone := CylinderMesh.new()
				cone.top_radius = 0.0
				cone.bottom_radius = 0.07
				cone.height = 0.2
				ponta.mesh = cone
				ponta.material_override = _brilho(Color("ffc93c"))
				ponta.position = Vector3(cos(a) * 0.27, 0.17, sin(a) * 0.27)
				raiz.add_child(ponta)
		elif dados.tipo == "nave":
			var disco := MeshInstance3D.new()
			var bola := SphereMesh.new()
			bola.radius = 0.34
			bola.height = 0.2
			disco.mesh = bola
			disco.material_override = _mat(cor)
			raiz.add_child(disco)
			var cupula := MeshInstance3D.new()
			var meia := SphereMesh.new()
			meia.radius = 0.15
			meia.height = 0.15
			meia.is_hemisphere = true
			cupula.mesh = meia
			cupula.material_override = _brilho(Color("c9f6ff"))
			cupula.position.y = 0.06
			raiz.add_child(cupula)
		elif dados.tipo == "ceu":
			for b in [[Vector3(-0.18, 0, 0), 0.2], [Vector3(0.05, 0.08, 0), 0.25], [Vector3(0.26, 0, 0), 0.18]]:
				var mi := MeshInstance3D.new()
				var bola := SphereMesh.new()
				bola.radius = b[1]
				bola.height = b[1] * 1.6
				mi.mesh = bola
				mi.material_override = _mat(Color.WHITE)
				mi.position = b[0]
				raiz.add_child(mi)
		else:
			var casa := MeshInstance3D.new()
			var cubo := BoxMesh.new()
			cubo.size = Vector3(0.42, 0.34, 0.3)
			casa.mesh = cubo
			casa.material_override = _mat(Color("f6efe2"))
			raiz.add_child(casa)
			var telhado := MeshInstance3D.new()
			var prisma := PrismMesh.new()
			prisma.size = Vector3(0.56, 0.28, 0.34)
			telhado.mesh = prisma
			telhado.material_override = _mat(cor.darkened(0.2))
			telhado.position.y = 0.31
			raiz.add_child(telhado)

	func _fazer_cadeado() -> Node3D:
		var raiz := Node3D.new()
		var ouro := _mat(Color("ffc93c"))
		ouro.metallic = 0.6
		ouro.roughness = 0.3
		var corpo := MeshInstance3D.new()
		var bloco := BoxMesh.new()
		bloco.size = Vector3(0.9, 0.75, 0.3)
		corpo.mesh = bloco
		corpo.material_override = ouro
		raiz.add_child(corpo)
		var alca := MeshInstance3D.new()
		var anel := TorusMesh.new()
		anel.inner_radius = 0.22
		anel.outer_radius = 0.33
		alca.mesh = anel
		alca.material_override = ouro
		alca.rotation.x = PI / 2.0
		alca.position.y = 0.45
		raiz.add_child(alca)
		return raiz

	func _caixa(tamanho: Vector3, pos: Vector3, material: Material) -> void:
		var mi := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = tamanho
		mi.mesh = b
		mi.material_override = material
		mi.position = pos
		add_child(mi)

	func _rotulo(texto: String, tamanho: int, cor: Color) -> Label3D:
		var l := Label3D.new()
		l.text = texto
		l.font_size = tamanho
		l.pixel_size = 0.01
		l.outline_size = 14
		l.outline_modulate = Color(0.08, 0.06, 0.18)
		l.modulate = cor
		return l

	func _mat(cor: Color) -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_color = cor
		m.roughness = 0.6
		return m

	func _brilho(cor: Color) -> StandardMaterial3D:
		var m := _mat(cor)
		m.emission_enabled = true
		m.emission = cor
		m.emission_energy_multiplier = 1.6
		return m


## O elevador do farol (prêmio dos 10 Faisquinhas): uma plataforma laranja com borda amarela, corrimão do lado de
## dentro (o vão do meio) e a parede da torre do lado de fora. Sobe e desce sem parar pelo vão das sacadas, parando
## PARADA s em cada andar. Andando, liga as paredinhas das duas pontas (para o Faísca não sair no meio do caminho);
## parado, desliga as do elevador e abre as cancelas daquele andar. Não desce enquanto o Faísca está embaixo dele no
## térreo. Quebrado (`funcionando` falso), fica no térreo, torto e sem luz. O x dele aponta para fora da torre.
class ElevadorFarol:
	extends AnimatableBody3D

	## Do meio da torre até a borda de dentro da plataforma, e o tamanho dela (ao longo do raio e do anel).
	const DENTRO := 8.2
	const FUNDO := 3.4
	const LARGURA := 3.0
	const PARADA := 2.6
	const VELOCIDADE := 2.8

	var funcionando := true
	var andares: Array = []
	var cancelas: Array = []
	## O andar em que está (ou o último em que parou) e para onde vai.
	var andar := 0
	var indo_para := 0
	var parado := true
	var subindo := true
	var _espera := 0.0
	var _paredes: Array[CollisionShape3D] = []
	var _luz: OmniLight3D

	func _ready() -> void:
		sync_to_physics = true
		var laranja := _mat(Color("ff7a22"))
		var amarelo := _mat(Color("ffd23f"))
		var branco := _mat(Color("f4f5f9"))
		_caixa(Vector3(FUNDO, 0.3, LARGURA), Vector3(0, -0.15, 0), laranja, true)
		for z in [-1.0, 1.0]:
			_caixa(Vector3(FUNDO, 0.08, 0.16), Vector3(0, 0.02, z * (LARGURA * 0.5 - 0.08)), amarelo, false)
		# Corrimão de dentro (sempre sólido) e os postes dos cantos com a moldura de cima.
		_caixa(Vector3(0.12, 1.0, LARGURA), Vector3(-FUNDO * 0.5 + 0.06, 0.5, 0), branco, false)
		var parede := CollisionShape3D.new()
		var caixa := BoxShape3D.new()
		caixa.size = Vector3(0.2, 3.0, LARGURA)
		parede.shape = caixa
		parede.position = Vector3(-FUNDO * 0.5 + 0.1, 1.5, 0)
		add_child(parede)
		for x in [-1.0, 1.0]:
			for z in [-1.0, 1.0]:
				_caixa(Vector3(0.14, 2.7, 0.14), Vector3(x * (FUNDO * 0.5 - 0.07), 1.35, z * (LARGURA * 0.5 - 0.07)), branco, false)
		for x in [-1.0, 1.0]:
			_caixa(Vector3(0.16, 0.16, LARGURA), Vector3(x * (FUNDO * 0.5 - 0.07), 2.75, 0), laranja, false)
		# As paredinhas das pontas (ligadas só andando).
		for z in [-1.0, 1.0]:
			var ponta := CollisionShape3D.new()
			var forma := BoxShape3D.new()
			forma.size = Vector3(FUNDO, 2.6, 0.2)
			ponta.shape = forma
			ponta.position = Vector3(0, 1.3, z * (LARGURA * 0.5 + 0.1))
			ponta.disabled = true
			add_child(ponta)
			_paredes.append(ponta)
		_luz = OmniLight3D.new()
		_luz.light_color = Color("ffd9a0")
		_luz.light_energy = 1.4
		_luz.omni_range = 5.0
		_luz.position.y = 2.6
		add_child(_luz)
		if not funcionando:
			_luz.visible = false
			rotation.z = 0.06
			position.y = 0.05
		_espera = PARADA
		_atualizar_cancelas()

	func _physics_process(delta: float) -> void:
		if not funcionando:
			return
		if parado:
			_espera -= delta
			if _espera <= 0.0:
				_partir()
			return
		var alvo: float = andares[indo_para]
		var y := move_toward(position.y, alvo, VELOCIDADE * delta)
		if y < position.y and _faisca_embaixo():
			return
		position.y = y
		if is_equal_approx(position.y, alvo):
			andar = indo_para
			parado = true
			_espera = PARADA
			for p in _paredes:
				p.disabled = true
			_atualizar_cancelas()

	func _partir() -> void:
		if andar >= andares.size() - 1:
			subindo = false
		elif andar <= 0:
			subindo = true
		indo_para = andar + (1 if subindo else -1)
		parado = false
		for p in _paredes:
			p.disabled = false
		_atualizar_cancelas()

	## Cancela aberta só no andar em que o elevador está parado.
	func _atualizar_cancelas() -> void:
		for c in cancelas:
			c.abrir(parado and c.andar == andar)

	## O Faísca embaixo da plataforma (no vão, entre ela e o andar de baixo): o elevador espera.
	func _faisca_embaixo() -> bool:
		var j := get_tree().get_first_node_in_group("jogador") as Node3D
		if j == null:
			return false
		var local := to_local(j.global_position)
		return absf(local.x) < FUNDO * 0.5 + 0.5 and absf(local.z) < LARGURA * 0.5 + 0.5 and local.y < -0.1 and local.y > -3.0

	func _caixa(tamanho: Vector3, pos: Vector3, material: Material, solida: bool) -> void:
		var mi := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = tamanho
		mi.mesh = b
		mi.material_override = material
		mi.position = pos
		add_child(mi)
		if solida:
			var cs := CollisionShape3D.new()
			var forma := BoxShape3D.new()
			forma.size = tamanho
			cs.shape = forma
			cs.position = pos
			add_child(cs)

	func _mat(cor: Color) -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_color = cor
		m.roughness = 0.5
		return m


## Cancela de um lado do vão do elevador, num andar de cima: a barra listrada de amarelo e preto, na altura da
## cintura, que sobe quando o elevador para ali; fechada, uma parede invisível segura o Faísca na sacada. O x dela
## aponta para fora da torre.
class Cancela:
	extends StaticBody3D

	var andar := 1
	var aberta := false
	var _barra: Node3D
	var _forma: CollisionShape3D

	func _ready() -> void:
		var largura := HubFarol.RAIO - ElevadorFarol.DENTRO
		_forma = CollisionShape3D.new()
		var caixa := BoxShape3D.new()
		caixa.size = Vector3(largura, HubFarol.PAREDE_INVISIVEL, 0.2)
		_forma.shape = caixa
		_forma.position.y = HubFarol.PAREDE_INVISIVEL * 0.5
		add_child(_forma)
		var poste := MeshInstance3D.new()
		var cil := CylinderMesh.new()
		cil.top_radius = 0.09
		cil.bottom_radius = 0.09
		cil.height = 1.2
		poste.mesh = cil
		poste.material_override = _mat(Color("f4f5f9"))
		poste.position = Vector3(-largura * 0.5 + 0.1, 0.6, 0)
		add_child(poste)
		# A barra gira em volta da ponta de dentro (perto do poste).
		_barra = Node3D.new()
		_barra.position = Vector3(-largura * 0.5 + 0.1, 1.05, 0)
		add_child(_barra)
		var listras := 6
		for k in listras:
			var pedaco := MeshInstance3D.new()
			var b := BoxMesh.new()
			b.size = Vector3((largura - 0.2) / listras, 0.14, 0.1)
			pedaco.mesh = b
			pedaco.material_override = _mat(Color("ffd23f") if k % 2 == 0 else Color("2b2140"))
			pedaco.position.x = (k + 0.5) * (largura - 0.2) / listras
			_barra.add_child(pedaco)
		abrir(aberta)

	func abrir(sim: bool) -> void:
		aberta = sim
		if _forma == null:
			return
		_forma.disabled = sim
		var tw := _barra.create_tween()
		tw.tween_property(_barra, "rotation:z", 1.35 if sim else 0.0, 0.4).set_trans(Tween.TRANS_QUAD)

	func _mat(cor: Color) -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_color = cor
		m.roughness = 0.5
		return m

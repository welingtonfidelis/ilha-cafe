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
## O teto é o céu apagado: cada Estrela Grande devolvida acende uma constelação. A porta do sul, no
## térreo, volta para a ilha.
## A Parte2 preenche `portas` antes de pôr o hub na árvore e escuta `porta_escolhida` e `saiu`.
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
}

## Uma por porta: {id, nome, tipo ("ceu", "chao", "nave" ou "saida"), andar (0 é o térreo), lado (graus),
## pede, pede_grandes, falta, aberta, feita, imagem, grande, achados, total_vaga_lumes}.
var portas: Array = []
## Estrelas Grandes já devolvidas (ids das fases): acendem as constelações.
var grandes: Array = []
## Porta onde o Faísca aparece (voltando de uma fase); vazio é a entrada, no sul.
var volta_de := ""
var portas_nos := {}


func _montar() -> void:
	nome = "Farol"
	limite_queda = -6.0
	inicio = Vector3(0, 0.1, RAIO - 3.5)
	_sala()
	_eixo_e_lampada()
	_escada()
	_sacadas()
	_teto()
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
	for k in range(1, ANDARES.size()):
		var y: float = ANDARES[k]
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

	const CORES := {"ceu": Color("4aa3ff"), "chao": Color("5cc06a"), "nave": Color("8a4fe0"), "saida": Color("ff7a22")}

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
			for k in int(dados.total_vaga_lumes):
				var luz := MeshInstance3D.new()
				var bola := SphereMesh.new()
				bola.radius = 0.13
				bola.height = 0.26
				luz.mesh = bola
				luz.material_override = _brilho(Color("c6ff4a")) if k < int(dados.achados) else _mat(Color("3a4050"))
				luz.position = Vector3(-0.4 + k * 0.4, 0.3, 0.35)
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
		if dados.tipo == "nave":
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

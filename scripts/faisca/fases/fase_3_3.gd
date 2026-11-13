class_name Fase33
extends Fase
## 3-3 Moinhos do Vento (Mundo 3, Frio e Vento; fase de céu). As Bolotas esconderam a oitava Estrela Grande no alto do
## Moinho Gigante, que gira devagar no meio de ilhas de pasto no céu. Novidade: o vento, que se vê (FaixaDeVento):
## flutuando dentro de uma faixa, o Faísca é levado e passa vãos que o voo sozinho não passa; contra o vento, não dá.
## Poder da fase: a Pipa (no celeiro da fazenda), que faz as colunas de vento (ColunaDeVento) levarem para o alto.
## Feita em 2026-11-12 a partir da maquete aprovada pelo usuário (docs/level-design/maquete-3-3-moinhos-do-vento.html,
## "Acho que podemos seguir pra fase 3-3, aprovado sua maquete"). Cinco playgrounds em espiral em volta do Moinho
## Gigante, cada saída com uma tarefa (o mesmo esqueleto da 3-1):
##   1 Campina dos Cata-ventos (y 0, ao sul): um riacho raso corta a ilha, e a faixa de vento leva de uma margem à
##     outra (quem cai só se molha); três cata-ventos parados, um soco em cada, abrem o portão de feno (P0 no começo)
##   viagem: o balão de ar quente
##   2 Ilhas do Vento (y 10 a 16, a oeste): vãos que só se passam no vento a favor, dois caminhos até a ilha do meio;
##     atravessar flutuando as três argolas-sino traz a nuvem; V1 na ilhota de baixo, por uma faixa que desce (P1)
##   viagem: a nuvem soprada pelo vento
##   3 Fazenda das Nuvens (y 18, a noroeste): a Pipa no celeiro; com ela, a coluna ao lado de cada silo leva ao
##     cata-vento do alto, e os três girando soltam o teleférico; V2 no telhado do celeiro; coração no paiol (P2)
##   viagem: o teleférico (vai e volta)
##   4 Corredor dos Moinhos (y 22 a 31, a leste): três moinhos travados, cujas pás levam gôndolas até a ilha seguinte;
##     a coluna de vento (com a pipa) leva ao freio de cada um; rajadas de lado entre as ilhas; V3 na ilhota atrás do
##     terceiro moinho, do alto da roda (P3)
##   5 Subida do Moinho Gigante (y 30 a 40): a escada de tábuas por fora da torre, com três degraus altos demais; o
##     soco no ferrolho de cada janela solta uma coluna de vento, e a terceira janela acorda o vendaval (o momento
##     especial, item 9): um redemoinho que leva o Faísca voando em volta do moinho até o topo (P4). Segredo: a parede
##     rachada da sacada de baixo, com o coração e o Faisquinha 4
##   Arena no topo (40 m): a sacada de cima, com o baú e três Bolotas

signal faixa_pedida(titulo: String, sub: String)

const MOINHOS := "res://assets/faisca/moinhos/"
const GRAMA := [Color("8fd36a"), Color("3f7a3a"), Color("a8865f")]
const PEDRA := [Color("e9eef5"), Color("55607a"), Color("9aa7bf")]
const AREIA := [Color("d9c28f"), Color("8a7450"), Color("a8865f")]
const MADEIRA := Color("b07a45")
const MADEIRA_ESCURA := Color("6e4a26")
const CAMPINA := Vector3(0, 0, 110)
const RAIO_CAMPINA := 32.0
## O riacho raso da campina: de z RIACHO.x a RIACHO.y, com o leito a LEITO m.
const RIACHO := Vector2(98.0, 111.0)
const LEITO := -1.2
const FAZENDA := Vector3(-70, 18, -78)
const RAIO_FAZENDA := 30.0
## O Moinho Gigante, no meio: a torre de pedra até a sacada de baixo, a de madeira até a sacada do topo (a arena).
const SACADA_BAIXA := 30.0
const SACADA_TOPO := 40.0
const RAIO_PEDRA := Vector2(14.0, 11.5)
const RAIO_MADEIRA := Vector2(11.5, 10.0)
const RAIO_SACADA_BAIXA := 19.0
const RAIO_ARENA := 15.5
const RAIO_ESCADA := 13.2
## Os três trechos da escada: o ângulo de começo (graus, contados do leste para o norte, como o no_moinho) e a altura.
const TRECHOS := [[-40.0, 30.3], [-140.0, 33.2], [-240.0, 36.1]]
const DEGRAUS_POR_TRECHO := 6
const PASSO_DEGRAU := 12.0
const ALTURA_PAS := 46.0

var pipa_pega := false
var _pipa: Pipa
var catavento_da_campina: Array[CataVento] = []
var catavento_dos_silos: Array[CataVento] = []
var argolas_sino: Array[ArgolaSino] = []
var faixas: Array[FaixaDeVento] = []
var colunas: Array[ColunaDeVento] = []
var moinhos: Array[MoinhoDeGondolas] = []
var freios: Array[Ferrolho] = []
var janelas: Array[Ferrolho] = []
var colunas_das_janelas: Array[ColunaDeVento] = []
var balao: Carona
var nuvem_soprada: Carona
var teleferico: Carona
var portao_de_feno: StaticBody3D
var degraus: Array[StaticBody3D] = []
var parede_secreta: ParedeRachada
var vendaval: Vendaval
var agua_do_riacho: Area3D
var molhou := 0
var _pas_gigantes: Node3D
var _leito: MeshInstance3D


func _montar() -> void:
	superficie = "grama"
	nome = "3-3 Moinhos do Vento"
	inicio = Vector3(12, 0.1, 128)
	limite_queda = -10.0
	farol(Vector3(-150, -16, 230), 2.0)
	_moinho_gigante()
	_campina_dos_cata_ventos()
	_viagem_balao()
	_ilhas_do_vento()
	_fazenda_das_nuvens()
	_viagem_teleferico()
	_corredor_dos_moinhos()
	_subida_do_moinho()
	_arena()
	_nuvens_de_enfeite()


## Só a grama dos topos ganha o desenho e a vegetação (nem a torre, nem as tábuas, nem o leito do riacho).
func leva_desenho(mi: MeshInstance3D, _arquivo: String) -> bool:
	return mi.has_meta("grama")


# --- peças da fase ------------------------------------------------------------------

## Ilha redonda com `topo` no meio de cima: a tampa, a borda e o cone por baixo (a mesma da 3-1). A tampa de grama
## ganha o desenho e a vegetação.
func ilha(topo: Vector3, raio: float, cores: Array, fundura := -1.0) -> StaticBody3D:
	var corpo := StaticBody3D.new()
	corpo.position = topo
	add_child(corpo)
	var tampa := _malha(corpo, _cilindro(raio, raio * 0.97, 1.2), cores[0], Vector3(0, -0.6, 0))
	if cores == GRAMA:
		tampa.set_meta("grama", true)
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


## Ponto em volta do Moinho Gigante: `graus` contados do leste (+X) para o norte (-Z), a `raio` m do meio, na altura `y`.
func no_moinho(graus: float, raio: float, y: float) -> Vector3:
	var a := deg_to_rad(graus)
	return Vector3(raio * cos(a), y, -raio * sin(a))


## Caixa sólida com o meio em `centro`, girada `giro` em volta do Y.
func caixa(centro: Vector3, tamanho: Vector3, cor: Color, giro := 0.0) -> StaticBody3D:
	var corpo := StaticBody3D.new()
	corpo.position = centro
	corpo.rotation.y = giro
	add_child(corpo)
	var bm := BoxMesh.new()
	bm.size = tamanho
	_malha(corpo, bm, cor, Vector3.ZERO)
	var cs := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tamanho
	cs.shape = forma
	corpo.add_child(cs)
	return corpo


## Tábua (ou rampa) de madeira de `de` até `ate` (o meio de cima nas duas pontas), com a borda escura por baixo.
func tabuas(de: Vector3, ate: Vector3, largura := 3.0) -> StaticBody3D:
	var corpo := StaticBody3D.new()
	add_child(corpo)
	# 2 cm acima das pontas: no mesmo plano do chão onde ela encosta, piscava.
	corpo.look_at_from_position((de + ate) * 0.5 + Vector3.DOWN * 0.18, ate + Vector3.DOWN * 0.18, Vector3.UP)
	var comp := de.distance_to(ate)
	var bm := BoxMesh.new()
	bm.size = Vector3(largura, 0.4, comp)
	_malha(corpo, bm, MADEIRA, Vector3.ZERO)
	var borda := BoxMesh.new()
	borda.size = Vector3(largura + 0.12, 0.14, comp + 0.1)
	_malha(corpo, borda, MADEIRA_ESCURA, Vector3(0, -0.25, 0))
	var cs := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = bm.size
	cs.shape = forma
	corpo.add_child(cs)
	return corpo


## Pedaço de anel (de `r1` a `r2` m do meio do moinho, de `a` a `b` graus) com o topo em `topo` e `grossura` de altura,
## sólido, na `cor`.
func anel(r1: float, r2: float, a: float, b: float, topo: float, grossura: float, cor: Color) -> StaticBody3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := maxi(1, ceili(absf(b - a) / 6.0))
	for i in n:
		var g0 := lerpf(a, b, float(i) / n)
		var g1 := lerpf(a, b, float(i + 1) / n)
		var pts := [no_moinho(g0, r1, topo), no_moinho(g0, r2, topo), no_moinho(g1, r2, topo), no_moinho(g1, r1, topo)]
		var baixo := Vector3.DOWN * grossura
		_quad(st, pts[0], pts[1], pts[2], pts[3], Vector3.UP)
		_quad(st, pts[0] + baixo, pts[1] + baixo, pts[2] + baixo, pts[3] + baixo, Vector3.DOWN)
		var fora := no_moinho((g0 + g1) * 0.5, 1.0, 0.0)
		_quad(st, pts[1], pts[2], pts[2] + baixo, pts[1] + baixo, fora)
		_quad(st, pts[0], pts[3], pts[3] + baixo, pts[0] + baixo, -fora)
		if absf(b - a) < 359.9:
			if i == 0:
				_quad(st, pts[0], pts[1], pts[1] + baixo, pts[0] + baixo, pts[0] - pts[3])
			if i == n - 1:
				_quad(st, pts[3], pts[2], pts[2] + baixo, pts[3] + baixo, pts[3] - pts[0])
	var malha := st.commit()
	var corpo := StaticBody3D.new()
	add_child(corpo)
	var mi := MeshInstance3D.new()
	mi.mesh = malha
	mi.material_override = _material(cor)
	corpo.add_child(mi)
	var cs := CollisionShape3D.new()
	var forma := malha.create_trimesh_shape()
	forma.backface_collision = true
	cs.shape = forma
	corpo.add_child(cs)
	return corpo


## Quadrilátero com a frente para o lado de `fora`.
func _quad(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, fora: Vector3) -> void:
	var nrm := (p1 - p0).cross(p2 - p0)
	if nrm.length_squared() < 1e-10:
		nrm = (p2 - p0).cross(p3 - p0)
	if nrm.dot(fora) < 0.0:
		var t := p1
		p1 = p3
		p3 = t
		nrm = -nrm
	nrm = nrm.normalized()
	for v in [p0, p2, p1, p0, p3, p2]:
		st.set_normal(nrm)
		st.add_vertex(v)


## A margem de grama de um lado do riacho: o pedaço do círculo da campina que fica além da linha z = `corte` (para o
## norte, `norte`), com a tampa de `LEITO` até 0.
func _margem(corte: float, norte: bool) -> void:
	var pontos := PackedVector2Array()
	var dz := corte - CAMPINA.z
	var meio := asin(clampf(dz / RAIO_CAMPINA, -1.0, 1.0))
	var a0 := meio if norte else PI - meio
	var a1 := PI - meio if norte else TAU + meio
	for i in 41:
		var a := lerpf(a0, a1, i / 40.0)
		pontos.append(Vector2(CAMPINA.x + cos(a) * RAIO_CAMPINA, CAMPINA.z + sin(a) * RAIO_CAMPINA))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var centro := Vector2.ZERO
	for p in pontos:
		centro += p
	centro /= pontos.size()
	for i in pontos.size():
		var p0 := pontos[i]
		var p1 := pontos[(i + 1) % pontos.size()]
		var t0 := Vector3(p0.x, 0, p0.y)
		var t1 := Vector3(p1.x, 0, p1.y)
		var c := Vector3(centro.x, 0, centro.y)
		_quad(st, c, t0, t1, c, Vector3.UP)
		_quad(st, t0, t1, t1 + Vector3(0, LEITO, 0), t0 + Vector3(0, LEITO, 0), Vector3(p0.x + p1.x - 2 * centro.x, 0, p0.y + p1.y - 2 * centro.y))
	var malha := st.commit()
	var corpo := StaticBody3D.new()
	add_child(corpo)
	var mi := MeshInstance3D.new()
	mi.mesh = malha
	mi.material_override = _material(GRAMA[0])
	mi.set_meta("grama", true)
	corpo.add_child(mi)
	var cs := CollisionShape3D.new()
	var forma := malha.create_trimesh_shape()
	forma.backface_collision = true
	cs.shape = forma
	corpo.add_child(cs)


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


func moinho_peca(arquivo: String, pos: Vector3, giro := 0.0, escala: Variant = 1.0, solida := true) -> Node3D:
	return peca_de(MOINHOS, arquivo, pos, giro, escala, solida)


## Fardo de feno redondo, deitado, com o pé em `pe` (sólido: dá para subir neles).
func fardo(pe: Vector3, raio := 1.1, giro := 0.0) -> StaticBody3D:
	var corpo := StaticBody3D.new()
	corpo.position = pe + Vector3.UP * raio
	corpo.rotation = Vector3(0, giro, PI / 2.0)
	add_child(corpo)
	_malha(corpo, _cilindro(raio, raio, raio * 1.3), Color("f2c94c"), Vector3.ZERO)
	var faixa := _cilindro(raio + 0.02, raio + 0.02, 0.18)
	_malha(corpo, faixa, Color("c99a2e"), Vector3(0, raio * 0.3, 0))
	_malha(corpo, faixa, Color("c99a2e"), Vector3(0, -raio * 0.3, 0))
	var cs := CollisionShape3D.new()
	var forma := CylinderShape3D.new()
	forma.radius = raio
	forma.height = raio * 1.3
	cs.shape = forma
	corpo.add_child(cs)
	return corpo


## Dica do Vovô fora de um ponto de dica, uma vez só.
func _dica_uma_vez(qual: String) -> void:
	if not _dicas_dadas.has(qual):
		_dicas_dadas[qual] = true
		dica.emit(qual)


## Uma faixa de vento de `de` até `ate` (os meios das pontas, no ar), com as birutas em `birutas` (pés no chão).
func faixa(de: Vector3, ate: Vector3, largura := 6.0, altura := 4.4, birutas: Array = [], rajada := false, fase_rajada := 0.0, forca := 7.5) -> FaixaDeVento:
	var f := FaixaDeVento.new()
	f.forca = forca
	f.de = de
	f.ate = ate
	f.largura = largura
	f.altura = altura
	f.rajada = rajada
	f.fase_da_rajada = fase_rajada
	add_child(f)
	for b: Vector3 in birutas:
		f.biruta_em(b)
	faixas.append(f)
	return f


## Uma coluna de vento com a grade em `pe`, levando até `topo_y`.
func coluna(pe: Vector3, topo_y: float, ligada := true) -> ColunaDeVento:
	var c := ColunaDeVento.new()
	c.position = pe
	c.topo_y = topo_y
	c.ligada = ligada
	add_child(c)
	colunas.append(c)
	return c


# --- o marco: o Moinho Gigante -------------------------------------------------------

## A ilha de pasto, a torre de pedra até a sacada de baixo e a de madeira até a sacada do topo, o telhado vermelho e as
## pás gigantes viradas para o sul, girando devagar.
func _moinho_gigante() -> void:
	ilha(Vector3.ZERO, 24.0, GRAMA, 18.0)
	var torre := StaticBody3D.new()
	add_child(torre)
	_malha(torre, _cilindro(RAIO_PEDRA.y, RAIO_PEDRA.x, SACADA_BAIXA), Color("e4e1d8"), Vector3(0, SACADA_BAIXA * 0.5, 0))
	_malha(torre, _cilindro(RAIO_MADEIRA.y, RAIO_MADEIRA.x, SACADA_TOPO - SACADA_BAIXA), Color("c8955a"), Vector3(0, (SACADA_BAIXA + SACADA_TOPO) * 0.5, 0))
	# Faixas de pedra mais escura, para a torre não ficar lisa.
	for y in [8.0, 16.0, 24.0]:
		var r := lerpf(RAIO_PEDRA.x, RAIO_PEDRA.y, y / SACADA_BAIXA) + 0.04
		_malha(torre, _cilindro(r, r + 0.12, 0.6), Color("b9b4a6"), Vector3(0, y, 0))
	for cs_spec in [[RAIO_PEDRA, 0.0, SACADA_BAIXA], [RAIO_MADEIRA, SACADA_BAIXA, SACADA_TOPO]]:
		var cs := CollisionShape3D.new()
		cs.shape = _cilindro((cs_spec[0] as Vector2).y, (cs_spec[0] as Vector2).x, cs_spec[2] - cs_spec[1]).create_convex_shape()
		cs.position.y = (cs_spec[1] + cs_spec[2]) * 0.5
		torre.add_child(cs)
	# A porta grande no pé da torre e as janelinhas redondas.
	var porta := BoxMesh.new()
	porta.size = Vector3(3.4, 5.0, 0.4)
	var pm := _malha(torre, porta, MADEIRA_ESCURA, no_moinho(-90, RAIO_PEDRA.x - 0.05, 2.5))
	pm.rotation.y = 0.0
	# O telhado (de madeira vermelha) e o bico, com a Estrela Grande brilhando em cima (o brilho do marco).
	var telhado := MeshInstance3D.new()
	telhado.mesh = _cilindro(0.0, RAIO_MADEIRA.y + 0.6, 14.0)
	telhado.material_override = _material(Color("d94f3d"))
	telhado.position.y = SACADA_TOPO + 7.0
	add_child(so_enfeite(telhado))
	brilho_de_marco(Vector3(0, SACADA_TOPO + 14.0, 0), 34.0)
	# As pás gigantes, na frente (para o sul), girando devagar em volta do eixo (o vendaval acelera).
	_pas_gigantes = Node3D.new()
	_pas_gigantes.position = Vector3(0, ALTURA_PAS, RAIO_ARENA + 2.6)
	add_child(so_enfeite(_pas_gigantes))
	var eixo := MeshInstance3D.new()
	eixo.mesh = _cilindro(0.7, 0.7, RAIO_ARENA + 2.6 - RAIO_MADEIRA.y)
	eixo.material_override = _material(MADEIRA_ESCURA)
	eixo.rotation.x = PI / 2.0
	eixo.position = Vector3(0, ALTURA_PAS, (RAIO_ARENA + 2.6 + RAIO_MADEIRA.y) * 0.5)
	add_child(so_enfeite(eixo))
	var miolo := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 1.8
	esfera.height = 3.6
	miolo.mesh = esfera
	miolo.material_override = _material(Color("ff7a22"))
	_pas_gigantes.add_child(miolo)
	for i in 4:
		var braco := Node3D.new()
		braco.rotation.z = i * PI / 2.0
		_pas_gigantes.add_child(braco)
		var vara := MeshInstance3D.new()
		var vb := BoxMesh.new()
		vb.size = Vector3(1.0, 11.0, 0.8)
		vara.mesh = vb
		vara.material_override = _material(MADEIRA_ESCURA)
		vara.position.y = 5.5
		braco.add_child(vara)
		var vela := MeshInstance3D.new()
		var vlb := BoxMesh.new()
		vlb.size = Vector3(4.6, 8.4, 0.25)
		vela.mesh = vlb
		vela.material_override = _material(Color("faf3e3"))
		vela.position = Vector3(2.6, 6.4, -0.2)
		braco.add_child(vela)
	# A sacada de baixo (de madeira, com a murinha na beira, menos onde chega a ponte) e a do topo (a arena).
	anel(RAIO_PEDRA.y - 0.05, RAIO_SACADA_BAIXA, 0.0, 360.0, SACADA_BAIXA, 0.8, MADEIRA)
	anel(RAIO_SACADA_BAIXA - 0.35, RAIO_SACADA_BAIXA, -14.0, 324.0, SACADA_BAIXA + 1.0, 1.0, MADEIRA_ESCURA)
	anel(RAIO_MADEIRA.y - 0.05, RAIO_ARENA, 0.0, 360.0, SACADA_TOPO, 0.8, MADEIRA)
	anel(RAIO_ARENA - 0.35, RAIO_ARENA, 0.0, 360.0, SACADA_TOPO + 1.0, 1.0, MADEIRA_ESCURA)
	# Os pilares que seguram a sacada do topo, por fora da escada (não atrapalham os degraus).
	for k in 12:
		var g := k * 30.0 + 15.0
		var p := no_moinho(g, RAIO_ARENA - 0.5, (SACADA_BAIXA + SACADA_TOPO) * 0.5)
		var pilar := caixa(p, Vector3(0.5, SACADA_TOPO - SACADA_BAIXA - 0.8, 0.5), MADEIRA_ESCURA)
		pilar.position.y = SACADA_BAIXA + (SACADA_TOPO - 0.8 - SACADA_BAIXA) * 0.5


func _process(delta: float) -> void:
	super._process(delta)
	if _pas_gigantes:
		var rapido := vendaval != null and vendaval.soprando
		_pas_gigantes.rotation.z -= delta * (1.6 if rapido else 0.12)


# --- 1 · Campina dos Cata-ventos ------------------------------------------------------

## Playground 1 · Campina dos Cata-ventos (apresenta): uma ilha de pasto cortada por um riacho raso de 13 m. Uma faixa
## de vento sopra de uma margem à outra: flutuando dentro dela, o Faísca é levado até o outro lado (o Vovô mostra o
## vento na chegada); quem cai no riacho só se molha e sai pelas pedras. Tarefa: um soco em cada um dos três
## cata-ventos parados do outro lado abre o portão de feno. Mini-marco: o moinho pequeno amarelo. Bolsos: o
## celeirinho (com o Faisquinha 3) e a pilha de fardos até o coração.
func _campina_dos_cata_ventos() -> void:
	playground("1 · Campina dos Cata-ventos", CAMPINA, RAIO_CAMPINA, inicio)
	# O leito do riacho (a ilha de baixo, de areia) e as duas margens de grama por cima.
	ilha(CAMPINA + Vector3(0, LEITO, 0), RAIO_CAMPINA, AREIA, 14.0)
	_margem(RIACHO.y, true)
	_margem(RIACHO.x, false)
	var agua := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	var meia := sqrt(RAIO_CAMPINA * RAIO_CAMPINA - 36.0)
	plano.size = Vector2(meia * 2.0 - 0.6, RIACHO.y - RIACHO.x)
	agua.mesh = plano
	var mat_agua := StandardMaterial3D.new()
	mat_agua.albedo_color = Color(0.45, 0.78, 0.95, 0.72)
	mat_agua.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_agua.roughness = 0.08
	mat_agua.metallic = 0.2
	agua.material_override = mat_agua
	agua.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	agua.position = Vector3(0, LEITO + 0.65, (RIACHO.x + RIACHO.y) * 0.5)
	add_child(so_enfeite(agua))
	agua_do_riacho = Area3D.new()
	agua_do_riacho.collision_layer = 0
	agua_do_riacho.collision_mask = CAMADA_JOGADOR
	var cs := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(meia * 2.0, 0.6, RIACHO.y - RIACHO.x)
	cs.shape = forma
	agua_do_riacho.add_child(cs)
	agua_do_riacho.position = agua.position + Vector3.DOWN * 0.25
	add_child(agua_do_riacho)
	agua_do_riacho.body_entered.connect(func(corpo: Node3D) -> void:
		if corpo is Jogador:
			molhou += 1
			Fx.confetti(self, corpo.global_position + Vector3.UP * 0.6, 14, 2.0)
			Sfx.play_at(self, "poca", corpo.global_position, 0.0, 0.1))
	# As pedras para sair do riacho (dos dois lados).
	# A de cima fica 3 cm abaixo da margem (no mesmo plano dela, piscava).
	for p in [Vector3(-20, LEITO + 0.3, 99.6), Vector3(-17.6, LEITO + 0.57, 99.0), Vector3(16, LEITO + 0.3, 110.0), Vector3(13.6, LEITO + 0.57, 110.6)]:
		caixa(p, Vector3(2.4, 0.6 if p.y < LEITO + 0.5 else 1.2, 1.6), PEDRA[2])

	# A faixa de vento de uma margem à outra, com as birutas, e o Vovô mostrando.
	faixa(Vector3(2, 2.1, 116), Vector3(2, 2.6, 92), 6.0, 4.4, [Vector3(-2.5, 0, 117), Vector3(6.5, 0, 91)])
	ponto_de_dica(Vector3(6, 0.5, 119), 3.5, "vento")
	trilha_creme([Vector3(12, 0, 127), Vector3(7, 0, 121), Vector3(2, 0, 117)])
	trilha_creme([Vector3(2, 0, 93), Vector3(-4, 0, 89), Vector3(-14, 0, 87.5), Vector3(-24, 0, 91.5), Vector3(-27.5, 0, 94.5)])
	trilha(Vector3(10, 1.2, 125), Vector3(4, 1.2, 119), 3)
	for z in [111.0, 107.0, 103.0, 99.0]:
		estrelinha(Vector3(2, 2.7, z))

	# Os três cata-ventos da tarefa e o portão de feno.
	ponto_de_dica(Vector3(-2, 0.5, 90), 3.0, "catavento")
	for p in [Vector3(-14, 0, 91), Vector3(4, 0, 85), Vector3(18, 0, 91)]:
		var c := CataVento.new()
		c.position = p
		add_child(c)
		c.girou.connect(_catavento_da_campina)
		catavento_da_campina.append(c)
		estrelinha(p + Vector3(0, 1.4, 1.8))
	arco_de_saida(Vector3(-28, 0, 95), atan2(-10.0, -3.0), "yellow")
	portao_de_feno = StaticBody3D.new()
	portao_de_feno.position = Vector3(-28, 0, 95)
	portao_de_feno.rotation.y = atan2(-10.0, -3.0)
	add_child(portao_de_feno)
	for spec in [[Vector3(-1.15, 1.1, 0), 1.1], [Vector3(1.15, 1.1, 0), 1.1], [Vector3(0, 3.2, 0), 1.0]]:
		var bale := MeshInstance3D.new()
		bale.mesh = _cilindro(spec[1], spec[1], 1.6)
		bale.material_override = _material(Color("f2c94c"))
		bale.rotation.x = PI / 2.0
		bale.position = spec[0]
		portao_de_feno.add_child(bale)
	var cs_portao := CollisionShape3D.new()
	var forma_portao := BoxShape3D.new()
	forma_portao.size = Vector3(4.6, 4.4, 1.6)
	cs_portao.shape = forma_portao
	cs_portao.position.y = 2.2
	portao_de_feno.add_child(cs_portao)

	# Mini-marco: o moinho pequeno amarelo, com as pás girando, e estrelinhas em volta.
	var amarelo := moinho_peca("building_windmill_yellow", Vector3(22, 0, 86), -2.4, 6.0)
	var pas := amarelo.find_child("building_windmill_top_fan_yellow", true, false) as Node3D
	if pas:
		var tw := pas.create_tween().set_loops()
		tw.tween_property(pas, "rotation:z", -TAU, 5.0).from(0.0)
	roda(Vector3(22, 1.2, 86), 5.0, 6)

	# Bolso: o celeirinho, com estrelinhas e o Faisquinha 3 lá dentro.
	var celeiro := Vector3(-19, 0, 124)
	_celeiro(celeiro, Vector3(6, 4, 5), 0.3 + PI)
	roda(celeiro + Vector3(0, 1.2, 0), 1.6, 4)
	faisquinha(celeiro + Vector3(0, 1.5, 0), "3")
	# Bolso: a pilha de fardos de feno, como escada, até o monte com o coração.
	fardo(Vector3(-24, 0, 105.8) + Vector3(0, 0, 6.2), 1.1, 0.4)
	fardo(Vector3(-25.5, 0, 114), 1.1, 0.4)
	fardo(Vector3(-26.2, 2.2, 115.6), 1.0, 0.4)
	ilha(Vector3(-28.5, 5.2, 120), 3.4, GRAMA, 3.0)
	coracao(Vector3(-28.5, 6.6, 120))

	bolota(Vector3(-10, 0, 128), true, "cogumelo")
	bolota(Vector3(8, 0, 90), false, "pinguim")
	for p in [Vector3(24, 0, 122), Vector3(-6, 0, 138), Vector3(26, 0, 100)]:
		arvore(1, 1, p, 2.2, p.x)
	arvore(2, 5, Vector3(-27, 0, 86), 2.0)
	roda(Vector3(12, 1.2, 128), 2.6, 5)
	for p in [Vector3(-8, 1.2, 88), Vector3(10, 1.2, 88), Vector3(-22, 1.2, 90)]:
		estrelinha(p)
	moinho_peca("haybale", Vector3(14, 0, 116), 0.6, 6.0)
	moinho_peca("barrel", Vector3(-12, 0, 118), 0.0, 3.0)


## Celeiro vermelho com a porta aberta para `giro` (o +Z dele), telhado em duas águas e o caibro de cima plano (dá
## para ficar em pé lá em cima). `tamanho` = largura, altura da parede e fundo.
func _celeiro(pe: Vector3, tamanho: Vector3, giro: float) -> Node3D:
	var raiz := Node3D.new()
	raiz.position = pe
	raiz.rotation.y = giro
	add_child(raiz)
	var l := tamanho.x
	var h := tamanho.y
	var f := tamanho.z
	var vermelho := Color("c8463d")
	var porta := minf(l * 0.45, 4.0)
	for spec in [[Vector3(0, h * 0.5, -f * 0.5), Vector3(l, h, 0.3)], [Vector3(-l * 0.5, h * 0.5, 0), Vector3(0.3, h, f)],
			[Vector3(l * 0.5, h * 0.5, 0), Vector3(0.3, h, f)],
			[Vector3(-(l + porta) * 0.25, h * 0.5, f * 0.5), Vector3((l - porta) * 0.5, h, 0.3)],
			[Vector3((l + porta) * 0.25, h * 0.5, f * 0.5), Vector3((l - porta) * 0.5, h, 0.3)],
			[Vector3(0, h - 0.4, f * 0.5), Vector3(porta, 0.8, 0.3)]]:
		var c := caixa(Vector3.ZERO, spec[1], vermelho)
		c.reparent(raiz, false)
		c.position = spec[0]
	# As tábuas brancas em X na porta (enfeite) e o telhado: duas águas e o caibro plano de 1,6 m em cima.
	var subida := l * 0.32
	for lado in [-1.0, 1.0]:
		var agua := caixa(Vector3.ZERO, Vector3(sqrt(pow(l * 0.5 - 0.8, 2.0) + subida * subida) + 0.6, 0.3, f + 0.8), Color("6e4a26"))
		agua.reparent(raiz, false)
		agua.position = Vector3(lado * (l * 0.25 + 0.4), h + subida * 0.5, 0)
		agua.rotation.z = -lado * atan2(subida, l * 0.5 - 0.8)
	var caibro := caixa(Vector3.ZERO, Vector3(1.6, 0.4, f + 0.8), Color("5a3a1e"))
	caibro.reparent(raiz, false)
	caibro.position = Vector3(0, h + subida + 0.05, 0)
	return raiz


## Um cata-vento da campina girou: com os três, o portão de feno rola para os lados e abre.
func _catavento_da_campina(_c: CataVento) -> void:
	if not catavento_da_campina.all(func(c: CataVento) -> bool: return c.girando) or not is_instance_valid(portao_de_feno):
		return
	var portao := portao_de_feno
	portao_de_feno = null
	(portao.get_child(portao.get_child_count() - 1) as CollisionShape3D).set_deferred("disabled", true)
	var tw := portao.create_tween().set_parallel()
	for i in 3:
		var b := portao.get_child(i) as Node3D
		var lado := -1.0 if i == 0 else 1.0
		tw.tween_property(b, "position", b.position + Vector3(lado * 4.0, -b.position.y + 1.0, 1.5), 0.9).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(b, "rotation:y", lado * 2.5, 0.9)
	tw.chain().tween_callback(portao.queue_free)
	Fx.confetti(self, portao.global_position + Vector3.UP * 2.0, 40, 4.0)
	Sfx.play(self, "bandeira", 0.0, 0.0)


## A campina já abriu o portão.
func portao_aberto_ja() -> bool:
	return portao_de_feno == null


## Viagem 1: o balão de ar quente, da ilhota depois do portão até a primeira ilha do vento.
func _viagem_balao() -> void:
	ilha(Vector3(-35, 0, 92.5), 4.0, GRAMA, 3.0)
	tabuas(Vector3(-27.6, 0, 94.6), Vector3(-31.8, 0, 93.4), 3.0)
	balao = carona(Vector3(-35, 0, 92.5), Vector3(-63.4, 10, 62.6), "balao", 4.0)
	for t in [0.3, 0.55, 0.8]:
		estrelinha(balao.de.lerp(balao.ate, t) + Vector3.UP * 2.0)


# --- 2 · Ilhas do Vento ---------------------------------------------------------------

## Playground 2 · Ilhas do Vento (desenvolve): ilhas de pasto sobre o vazio, separadas por vãos de 14 a 18 m que só se
## passam flutuando no vento a favor. Dois caminhos até a ilha do meio: o direto, com o vento a favor, e o das
## ilhotas, com uma faixa que leva em diagonal. Tarefa: atravessar flutuando as três argolas-sino no meio das faixas
## traz a nuvem que leva à fazenda. Mini-marco: a torre de vigia. Bolso: a ilhota do V1, por uma faixa que desce, e
## o fardo que quica de volta.
func _ilhas_do_vento() -> void:
	var chegada := Vector3(-68, 10, 58)
	var meio := Vector3(-96, 12, 40)
	var saida := Vector3(-106, 14, 10)
	playground("2 · Ilhas do Vento", meio, 26.0, balao.ate)
	ilha(chegada, 7.0, GRAMA)
	ilha(meio, 10.0, GRAMA)
	ilha(saida, 7.0, GRAMA)
	ilha(Vector3(-76, 10.5, 70), 3.4, GRAMA, 3.0)
	ilha(Vector3(-86, 11, 76), 3.4, GRAMA, 3.0)
	posto(chegada + Vector3(-2, 0, 3))
	ponto_de_dica(chegada + Vector3(-2.5, 0.5, -1.5), 3.0, "vento")
	# O caminho direto: a favor da chegada até o meio, e do meio até a saída.
	var a := faixa(Vector3(-72.5, 13, 55.5), Vector3(-88, 14, 46), 6.0, 4.6, [chegada + Vector3(-3.5, 0, -5)])
	var b := faixa(Vector3(-99.5, 15.5, 31), Vector3(-105, 16.5, 17.5), 6.0, 4.6, [meio + Vector3(-1, 0, -8.5)])
	# O caminho das ilhotas: pulando até a segunda, e uma faixa até a ilha do meio.
	var c := faixa(Vector3(-88.5, 12.5, 73.5), Vector3(-93, 13.2, 52), 8.0, 4.8, [Vector3(-86, 11, 77.5)])
	# As argolas-sino, uma no meio de cada faixa.
	for f in [a, b, c]:
		var arg := ArgolaSino.new()
		add_child(arg)
		arg.global_position = (f.de + f.ate) * 0.5 + Vector3.UP * 0.3
		arg.look_at(arg.global_position + (f.ate - f.de).normalized(), Vector3.UP)
		arg.tocou.connect(_argola_tocou)
		argolas_sino.append(arg)
	for f in [a, b, c]:
		for t in [0.2, 0.8]:
			estrelinha(f.de.lerp(f.ate, t) + Vector3.UP * 0.3)
	ponto_de_dica(meio + Vector3(5, 0.5, 4), 3.0, "argola")
	# Mini-marco: a torre de vigia com a biruta grande.
	moinho_peca("building_watchtower_blue", meio + Vector3(7.5, 0, -5.5), 0.6, 4.0)
	FaixaDeVento.biruta(self, meio + Vector3(7.5, 4.6, -5.5), Vector3(-1, 0, -1))
	bolota(meio + Vector3(4, 2.5, 3), false, "abelha")
	bolota(meio + Vector3(-4, 2.5, -4), false, "abelha")
	bolota(saida + Vector3(2, 0, 2), false, "alien")
	roda(meio + Vector3(0, 1.2, 0), 4.0, 5)
	roda(saida + Vector3(0, 1.2, 0), 3.0, 4)
	for p in [Vector3(-76, 11.7, 70), Vector3(-86, 12.2, 76), chegada + Vector3(0, 1.2, 0)]:
		estrelinha(p)
	# Bolso: a ilhota de baixo, com o V1, por uma faixa que desce da beira da ilha do meio; o fardo que quica devolve.
	var ilhota := Vector3(-106, 3, 50)
	ilha(ilhota, 3.6, GRAMA, 3.0)
	# Mais fraca que as outras (desce devagar, para dar para pousar na ilhota).
	faixa(Vector3(-101, 13.5, 47), Vector3(-105.5, 5.0, 50), 4.0, 3.2, [], false, 0.0, 4.5)
	faisquinha(ilhota + Vector3(-1.2, 1.4, 0.6))
	var quica := mola(ilhota + Vector3(1.6, 0, -0.6), 23.0)
	quica.set_meta("fardo", true)
	estrelinha(ilhota + Vector3(0.4, 1.2, 1.6))
	# A saída: o arco na beira de baixo e a nuvem soprada (travada até as três argolas).
	arco_de_saida(saida + Vector3(0, 0, -6), PI, "blue")


## Uma argola tocou: com as três, a nuvem chega e destrava.
func _argola_tocou(_a: ArgolaSino) -> void:
	if not argolas_sino.all(func(x: ArgolaSino) -> bool: return x.tocada) or not nuvem_soprada.travada:
		return
	nuvem_soprada.travada = false
	Sfx.play(self, "bandeira", 0.0, 0.0)
	Fx.confetti(self, nuvem_soprada.global_position + Vector3.UP * 2.0, 40, 5.0)


# --- 3 · Fazenda das Nuvens -----------------------------------------------------------

## Playground 3 · Fazenda das Nuvens (central, respiro e poder novo): um pasto grande com celeiro, silos, cercas e
## trigo. No celeiro está a Pipa. Tarefa: os três cata-ventos no alto dos silos (11 m acima do pasto); com a pipa, a
## coluna de vento ao lado de cada silo leva até lá, e um soco faz girar. Com os três, o teleférico anda. Bolso alto:
## a coluna atrás do celeiro leva ao telhado, com o V2; coração no paiol.
func _fazenda_das_nuvens() -> void:
	nuvem_soprada = carona(Vector3(-106, 14, 1.5), Vector3(-80, 18, -50.5), "nuvem", 5.0)
	nuvem_soprada.travada = true
	for t in [0.3, 0.55, 0.8]:
		estrelinha(nuvem_soprada.de.lerp(nuvem_soprada.ate, t) + Vector3.UP * 1.8)
	playground("3 · Fazenda das Nuvens", FAZENDA, RAIO_FAZENDA, nuvem_soprada.ate)
	ilha(FAZENDA, RAIO_FAZENDA, GRAMA, 16.0)
	posto(Vector3(-80, 18, -55))
	trilha_creme([Vector3(-80, 18, -51.5), Vector3(-72, 18, -57), Vector3(-62, 18, -60), Vector3(-50, 18, -66), Vector3(-42.5, 18, -73.5)])
	# O celeiro grande, com a Pipa na porta.
	var celeiro := Vector3(-58, 18, -68)
	var frente := atan2(-80.0 - celeiro.x, -51.5 - celeiro.z)
	_celeiro(celeiro, Vector3(11, 6, 9), frente)
	_pipa = Pipa.new()
	_pipa.position = celeiro + Vector3(sin(frente), 0, cos(frente)) * 2.0 + Vector3.UP * 1.6
	add_child(_pipa)
	_pipa.pega.connect(func(_j: Jogador) -> void:
		pipa_pega = true
		_dica_uma_vez("pipa"))
	roda(celeiro + Vector3(0, 1.2, 0), 2.6, 5)
	# Os três silos com o cata-vento no alto e a coluna de vento do lado.
	for s in [Vector3(-92, 18, -72), Vector3(-80, 18, -104), Vector3(-46, 18, -92)]:
		_silo(s, 11.0)
		var c := CataVento.new()
		c.alto = 2.6
		c.position = s + Vector3(0, 11.0, 0)
		c.rotation.y = atan2(FAZENDA.x - s.x, FAZENDA.z - s.z)
		add_child(c)
		c.girou.connect(_catavento_do_silo)
		catavento_dos_silos.append(c)
		var lado: Vector3 = (FAZENDA - s) * Vector3(1, 0, 1)
		var pe_coluna: Vector3 = s + lado.normalized() * 4.2
		coluna(pe_coluna, s.y + 13.0)
		for h in [4.0, 7.0, 10.0]:
			estrelinha(pe_coluna + Vector3.UP * h)
	ponto_de_dica(Vector3(-84, 18.5, -68), 3.0, "pipa")
	# O campo de trigo e as cercas.
	var trigo := MeshInstance3D.new()
	var tb := BoxMesh.new()
	tb.size = Vector3(14, 0.9, 10)
	trigo.mesh = tb
	trigo.material_override = _material(Color("e9c25a"))
	trigo.position = Vector3(-72, 18.45, -90)
	add_child(so_enfeite(trigo))
	for x in range(-79, -64, 3):
		moinho_peca("fence_wood_straight", Vector3(x + 1.5, 18, -84.5), 0.0, 3.0)
		moinho_peca("fence_wood_straight", Vector3(x + 1.5, 18, -95.5), 0.0, 3.0)
	roda(Vector3(-72, 19.4, -90), 4.5, 6)
	# Bolso alto: a coluna atrás do celeiro até o caibro do telhado, com o V2.
	var atras := -Vector3(sin(frente), 0, cos(frente))
	var topo_telhado := celeiro + Vector3.UP * (6.0 + 11.0 * 0.32 + 0.25)
	var pe_v2 := celeiro + atras * 7.4
	coluna(pe_v2, topo_telhado.y + 2.0)
	faisquinha(topo_telhado + Vector3.UP * 1.4)
	estrelinha(pe_v2 + Vector3.UP * 5.0)
	# O paiol com o coração em cima, e os fardos de degrau.
	var paiol := caixa(Vector3(-44, 20, -59), Vector3(5, 4, 4), Color("8a5a36"))
	paiol.rotation.y = 0.3
	coracao(Vector3(-44, 23.4, -59))
	fardo(Vector3(-40.6, 18, -57.0), 1.0, 0.3)
	# As Bolotas: o porco (que leva o Faisquinha 5) dispara pelo pasto.
	bolota(Vector3(-80, 18, -70), false, "cogumelo")
	faisquinha_na_bolota(bolota(Vector3(-63, 18, -86), false, "porco"))
	bolota(Vector3(-77, 18, -100), false, "alien")
	for p in [Vector3(-96, 18, -60), Vector3(-60, 18, -104), Vector3(-42, 18, -98)]:
		arvore(1, 1, p, 2.2, p.z)
	for p in [Vector3(-76, 19.2, -55), Vector3(-68, 19.2, -58), Vector3(-46, 19.2, -70)]:
		estrelinha(p)
	for k in 4:
		fardo(Vector3(-74 + k * 8, 18, -53 - k * 3.2), 0.8, 0.4)
	# A saída: o arco na beirada leste e a ilhota da estação do teleférico.
	arco_de_saida(Vector3(-42.5, 18, -73.5), PI * 0.5, "green")
	ilha(Vector3(-36, 18, -74), 4.5, GRAMA, 3.0)


## Silo: o cilindro claro com o pé no pasto, o topo plano (com a beirada vermelha) a `alto` m.
func _silo(pe: Vector3, alto: float) -> void:
	var corpo := StaticBody3D.new()
	corpo.position = pe
	add_child(corpo)
	_malha(corpo, _cilindro(2.4, 2.4, alto), Color("dfe5ee"), Vector3(0, alto * 0.5, 0))
	for y in [alto * 0.33, alto * 0.66]:
		_malha(corpo, _cilindro(2.45, 2.45, 0.3), Color("aab3c2"), Vector3(0, y, 0))
	var toro := TorusMesh.new()
	toro.inner_radius = 2.2
	toro.outer_radius = 2.6
	_malha(corpo, toro, Color("c8463d"), Vector3(0, alto, 0))
	var cs := CollisionShape3D.new()
	var forma := CylinderShape3D.new()
	forma.radius = 2.4
	forma.height = alto
	cs.shape = forma
	cs.position.y = alto * 0.5
	corpo.add_child(cs)


## Um cata-vento de silo girou: com os três, o teleférico destrava.
func _catavento_do_silo(_c: CataVento) -> void:
	if not catavento_dos_silos.all(func(c: CataVento) -> bool: return c.girando) or not teleferico.travada:
		return
	teleferico.travada = false
	Sfx.play(self, "bandeira", 0.0, 0.0)
	Fx.confetti(self, teleferico.global_position + Vector3.UP * 2.0, 40, 5.0)


## Viagem 3: o teleférico, da ilhota da estação até a primeira ilha do corredor, com o cabo e as duas torrinhas.
## Travado até os três cata-ventos dos silos; depois leva de volta também (atalho).
func _viagem_teleferico() -> void:
	var de := Vector3(-36, 18, -74)
	var g0 := no_moinho(70, 40, 22)
	var rumo := Vector3(g0.x - de.x, 0, g0.z - de.z).normalized()
	var ate := Vector3(g0.x, 22, g0.z) - rumo * 5.4
	teleferico = carona(de, ate, "cabine", 5.0)
	teleferico.travada = true
	var dir := (ate - de).normalized()
	var ponta_a := de - dir * 3.5 + Vector3.UP * 6.2
	var ponta_b := ate + dir * 3.5 + Vector3.UP * 6.2
	var cabo := MeshInstance3D.new()
	cabo.mesh = _cilindro(0.08, 0.08, ponta_a.distance_to(ponta_b))
	cabo.material_override = _material(Color("3a3150"))
	add_child(so_enfeite(cabo))
	cabo.look_at_from_position((ponta_a + ponta_b) * 0.5, ponta_b, Vector3.UP)
	cabo.rotate_object_local(Vector3.RIGHT, PI / 2.0)
	for p: Vector3 in [ponta_a, ponta_b]:
		var torre := StaticBody3D.new()
		torre.position = p + Vector3.DOWN * 3.3
		add_child(torre)
		_malha(torre, _cilindro(0.3, 0.4, 7.0), Color("6a6478"), Vector3.ZERO)
		var cs := CollisionShape3D.new()
		var cil := CylinderShape3D.new()
		cil.radius = 0.4
		cil.height = 7.0
		cs.shape = cil
		torre.add_child(cs)
	for t in [0.3, 0.55, 0.8]:
		estrelinha(de.lerp(ate, 0.5 - 0.5 * cos(PI * t)) + Vector3.UP * 1.8)


# --- 4 · Corredor dos Moinhos ---------------------------------------------------------

## Playground 4 · Corredor dos Moinhos (reviravolta): ilhas subindo em volta do Moinho Gigante, de 22 a 33 m, as três do
## meio com um moinho travado cujas pás levam gôndolas até a ilha seguinte. A coluna de vento ao lado de cada moinho
## (com a pipa) leva até o freio, e um soco solta. Rajadas de lado vão e vêm entre as ilhas, avisadas pelas birutas.
## Segredo: do alto da roda do terceiro moinho, a ilhota escondida com o V3.
func _corredor_dos_moinhos() -> void:
	var gs := [no_moinho(70, 40, 22), no_moinho(46, 40, 25), no_moinho(22, 40, 28), no_moinho(-2, 40, 31), no_moinho(-26, 36, 33)]
	playground("4 · Corredor dos Moinhos", no_moinho(22, 40, 28), 26.0, teleferico.ate)
	for i in gs.size():
		ilha(gs[i], 6.0 if i == 0 else 5.0, GRAMA, 4.0)
		estrelinha(gs[i] + Vector3(0, 1.2, 0) + (gs[i] * Vector3(1, 0, 1)).normalized() * 2.4)
	posto(gs[0] + Vector3(1.5, 0, 1.0))
	ponto_de_dica(gs[0] + Vector3(-2.0, 0.5, 2.0), 3.0, "freio")
	var bolotas_do_corredor := [[1, "alien"], [3, "cogumelo"]]
	for i in [1, 2, 3]:
		var g: Vector3 = gs[i]
		var fora := Vector3(g.x, 0, g.z).normalized()
		var m := MoinhoDeGondolas.new()
		m.position = g
		m.rotation.y = atan2(fora.x, fora.z)
		m.cor_telhado = [Color("3f7fd9"), Color("4cc27a"), Color("ff8a2a")][i - 1]
		add_child(m)
		moinhos.append(m)
		# A coluna e o freio, atrás da roda (do lado de onde se vem).
		var traz := m.global_basis.x
		var pe := g + traz * 3.7
		var ch := coluna(pe, g.y + 8.4)
		ch.raio = 1.6
		# O freio na altura de quem paira no topo da coluna (os golpes medem do pé do alvo).
		var f := Ferrolho.new()
		add_child(f)
		f.global_position = g + traz * 2.05 + Vector3.UP * 8.9
		f.rotation.y = atan2(traz.x, traz.z)
		f.aberto.connect(func(_f: Ferrolho) -> void: m.destravar())
		freios.append(f)
		estrelinha(m.eixo_global() + Vector3.UP * 1.8)
		estrelinha(pe + Vector3.UP * 6.0)
	for spec in bolotas_do_corredor:
		bolota(gs[spec[0]] + Vector3(-1.5, 0, -1.0), false, spec[1])
	bolota(moinhos[1].eixo_global() + Vector3(0, -2.0, 6.0), false, "morcego")
	# As rajadas de lado entre as ilhas (vão e voltam, uma de cada vez), com as birutas.
	for i in 3:
		var a: Vector3 = gs[i + 1]
		var b: Vector3 = gs[i + 2]
		var meio := (a + b) * 0.5
		var fora := Vector3(meio.x, 0, meio.z).normalized()
		var y := maxf(a.y, b.y) + 4.0
		var r := faixa(Vector3(meio.x, y, meio.z) - fora * 7.0, Vector3(meio.x, y, meio.z) + fora * 7.0, 7.0, 6.0, [], true, i * 1.7)
		r.biruta_em(a + (b - a).normalized() * 3.6 - fora * 2.0)
		estrelinha(Vector3(meio.x, y - 1.5, meio.z))
	# Segredo: a ilhota atrás do terceiro moinho, com o V3, alcançada do alto da roda.
	var escondida := no_moinho(-6, 50, 41)
	ilha(escondida, 3.2, GRAMA, 3.0)
	faisquinha(escondida + Vector3(0, 1.4, 0))
	roda(escondida + Vector3(0, 1.0, 0), 1.8, 3)
	# A saída: o arco na última ilha e a rampa de tábuas até a sacada de baixo do Moinho Gigante.
	var g4: Vector3 = gs[4]
	var anel_chega := no_moinho(-26, RAIO_SACADA_BAIXA - 1.4, SACADA_BAIXA)
	var rumo := (anel_chega - g4) * Vector3(1, 0, 1)
	var beira := g4 + rumo.normalized() * 4.4
	arco_de_saida(beira + Vector3(0, 0, 0), atan2(rumo.x, rumo.z), "red")
	tabuas(beira + rumo.normalized() * 0.4, no_moinho(-26, RAIO_SACADA_BAIXA - 0.6, SACADA_BAIXA), 3.4)


# --- 5 · Subida do Moinho Gigante -----------------------------------------------------

## Playground 5 · Subida do Moinho Gigante (o fim): da sacada de baixo, a escada de tábuas sobe em espiral por fora da
## torre, em três trechos. Entre um trecho e o outro o degrau é alto demais: o soco no ferrolho da janela do fim de cada
## trecho abre a janela e solta uma coluna de vento (a pipa leva até o trecho seguinte). A terceira janela acorda o
## vendaval (o momento especial), que leva o Faísca voando em volta do moinho até a arena. Quem cai da escada cai na
## sacada de baixo. Segredo: a parede rachada da sacada de baixo, com o coração e o Faisquinha 4.
func _subida_do_moinho() -> void:
	# A entrada é o começo da rampa, na última ilha do corredor: de lá se vê o moinho inteiro (da sacada de baixo, o
	# piso da arena tapa o brilho do telhado).
	var g4 := no_moinho(-26, 36, 33)
	var rumo := (no_moinho(-26, RAIO_SACADA_BAIXA - 1.4, SACADA_BAIXA) - g4) * Vector3(1, 0, 1)
	playground("5 · Subida do Moinho Gigante", Vector3(0, SACADA_BAIXA, 0), RAIO_SACADA_BAIXA, g4 + rumo.normalized() * 4.4)
	posto(no_moinho(-20, 16.5, SACADA_BAIXA))
	for k in TRECHOS.size():
		var g0: float = TRECHOS[k][0]
		var y0: float = TRECHOS[k][1]
		for i in DEGRAUS_POR_TRECHO:
			var g := g0 - i * PASSO_DEGRAU
			var topo := y0 + i * 0.06
			var d := caixa(no_moinho(g, RAIO_ESCADA, topo - 0.2), Vector3(2.4, 0.4, 2.95), MADEIRA)
			d.rotation.y = deg_to_rad(g)
			degraus.append(d)
			if i % 2 == 1:
				estrelinha(no_moinho(g, RAIO_ESCADA, topo + 1.2))
		# A janela do fim do trecho, com o ferrolho laranja; aberta, solta a coluna até o trecho seguinte (a última, o
		# vendaval).
		var g_fim := g0 - (DEGRAUS_POR_TRECHO - 1) * PASSO_DEGRAU - 6.0
		var y_fim := y0 + (DEGRAUS_POR_TRECHO - 1) * 0.06
		var r_parede := lerpf(RAIO_MADEIRA.x, RAIO_MADEIRA.y, (y_fim - SACADA_BAIXA) / (SACADA_TOPO - SACADA_BAIXA))
		var janela := caixa(no_moinho(g_fim, r_parede, y_fim + 1.6), Vector3(2.4, 2.6, 0.5), MADEIRA_ESCURA)
		janela.rotation.y = deg_to_rad(g_fim) + PI / 2.0
		var f := Ferrolho.new()
		add_child(f)
		f.global_position = no_moinho(g_fim, r_parede + 0.35, y_fim)
		f.rotation.y = deg_to_rad(g_fim) + PI / 2.0
		janelas.append(f)
		if k < TRECHOS.size() - 1:
			var g_vao := g0 - (DEGRAUS_POR_TRECHO - 1) * PASSO_DEGRAU - 20.0
			var c := coluna(no_moinho(g_vao, RAIO_ESCADA, SACADA_BAIXA), float(TRECHOS[k + 1][1]) + 1.6, false)
			colunas_das_janelas.append(c)
			f.aberto.connect(func(_f: Ferrolho) -> void: c.ligar())
			estrelinha(no_moinho(g_vao, RAIO_ESCADA, float(TRECHOS[k + 1][1]) - 0.5))
		else:
			f.aberto.connect(func(_f: Ferrolho) -> void: vendaval.chamar())
	ponto_de_dica(no_moinho(-36, RAIO_ESCADA, TRECHOS[0][1] + 0.5), 2.6, "janela")
	# O vendaval (o momento especial), em volta da torre.
	vendaval = Vendaval.new()
	vendaval.fase = self
	vendaval.de_onde = no_moinho(float(TRECHOS[2][0]) - (DEGRAUS_POR_TRECHO - 1) * PASSO_DEGRAU, RAIO_ESCADA, float(TRECHOS[2][1]))
	vendaval.pouso = no_moinho(-75, (RAIO_MADEIRA.y + RAIO_ARENA) * 0.5, SACADA_TOPO + 0.1)
	add_child(vendaval)
	vendaval.levou.connect(func() -> void: faixa_pedida.emit("Que vendaval!", "O vento levou o Faísca até o topo do moinho"))
	# As estrelinhas no caminho do voo (ele passa por elas).
	for t in [0.18, 0.28, 0.38, 0.48, 0.58, 0.68, 0.76]:
		estrelinha(vendaval.ponto_do_voo(t) + Vector3.UP * 1.0)
	# Segredo: a salinha da sacada de baixo, atrás da parede rachada, com o coração, estrelinhas e o Faisquinha 4.
	# Em -150 graus, entre dois pilares da sacada do topo e por fora da escada.
	var g_sala := -150.0
	var centro := no_moinho(g_sala, 16.9, SACADA_BAIXA)
	var giro := deg_to_rad(g_sala) + PI / 2.0
	var sala := Node3D.new()
	sala.position = centro
	sala.rotation.y = giro
	add_child(sala)
	for spec in [[Vector3(-1.7, 1.5, 0), Vector3(0.3, 3.0, 3.4)], [Vector3(1.7, 1.5, 0), Vector3(0.3, 3.0, 3.4)],
			[Vector3(0, 1.5, 1.7), Vector3(3.7, 3.0, 0.3)], [Vector3(0, 3.15, 0), Vector3(4.0, 0.3, 4.0)]]:
		var parede := caixa(Vector3.ZERO, spec[1], Color("c8955a"))
		parede.reparent(sala, false)
		parede.position = spec[0]
	# A parede rachada na largura da salinha (a de sempre tem 6 m, na escala 1,5).
	parede_secreta = ParedeRachada.new()
	parede_secreta.escala = 0.85
	parede_secreta.position = centro + (sala.global_basis.z * -1.7)
	parede_secreta.rotation.y = giro
	add_child(parede_secreta)
	paredes_rachadas.append(parede_secreta)
	coracao(centro + Vector3.UP * 1.4)
	faisquinha(centro + sala.global_basis.x * 0.9 + Vector3.UP * 1.5, "4")
	roda(centro + Vector3.UP * 1.0, 1.4, 4)
	bolota(no_moinho(-90, 17.0, SACADA_BAIXA), false, "abelha")
	for g in [-60.0, -120.0, -200.0, -250.0, -300.0]:
		estrelinha(no_moinho(g, 17.0, SACADA_BAIXA + 1.2))


# --- arena ----------------------------------------------------------------------------

func _arena() -> void:
	var bau_pos := no_moinho(-90, (RAIO_MADEIRA.y + RAIO_ARENA) * 0.5 + 0.4, SACADA_TOPO)
	colocar_bau(bau_pos, 0.0)
	bolota(no_moinho(-60, 12.8, SACADA_TOPO), false, "alien")
	bolota(no_moinho(-120, 12.8, SACADA_TOPO), false, "porco")
	bolota(no_moinho(-150, 12.8, SACADA_TOPO), false, "abelha")
	ponto_de_dica(no_moinho(-70, 12.6, SACADA_TOPO + 1.0), 3.0, "giro_forte")
	for g in [-30.0, -75.0, -105.0, -135.0, 0.0, 30.0]:
		estrelinha(no_moinho(g, 12.8, SACADA_TOPO + 1.2))


## Nuvens do Medieval Hexagon e moinhos pequenos em nuvens, só de enfeite, longe dos playgrounds e das viagens.
func _nuvens_de_enfeite() -> void:
	var gerador := RandomNumberGenerator.new()
	gerador.seed = 33
	var viagens := [[balao.de, balao.ate], [nuvem_soprada.de, nuvem_soprada.ate], [teleferico.de, teleferico.ate]]
	for i in 36:
		var p := Vector3(gerador.randf_range(-190, 140), gerador.randf_range(-4, 60), gerador.randf_range(-170, 200))
		var perto := Vector2(p.x, p.z).length() < 60.0
		for pg in playgrounds:
			perto = perto or Vector2(p.x - pg.centro.x, p.z - pg.centro.z).length() < pg.raio + 22.0
		for v in viagens:
			var a := Vector2(v[0].x, v[0].z)
			var b := Vector2(v[1].x, v[1].z)
			var q := Vector2(p.x, p.z)
			perto = perto or q.distance_to(a + (b - a) * clampf((q - a).dot(b - a) / (b - a).length_squared(), 0.0, 1.0)) < 22.0
		if perto:
			continue
		if i % 6 == 0:
			var cor: String = ["yellow", "red", "green"][i % 3]
			so_enfeite(moinho_peca("building_windmill_" + cor, p, gerador.randf() * TAU, 7.0, false))
			so_enfeite(moinho_peca("cloud_big", p + Vector3.DOWN * 2.0, gerador.randf() * TAU, 5.0, false))
		else:
			so_enfeite(moinho_peca("cloud_big" if i % 2 else "cloud_small", p, gerador.randf() * TAU, gerador.randf_range(5.0, 9.0), false))


# --- céu ----------------------------------------------------------------------------

## Céu de fim de tarde de vento: azul forte em cima e dourado clarinho no horizonte.
func _montar_ceu_e_luz() -> void:
	super._montar_ceu_e_luz()
	for we in find_children("*", "WorldEnvironment", false, false):
		var ceu := ((we as WorldEnvironment).environment.sky.sky_material as ProceduralSkyMaterial)
		ceu.sky_top_color = Color("4a8ff0")
		ceu.sky_horizon_color = Color("ffe9c4")
		ceu.ground_horizon_color = Color("fff1d8")
		ceu.ground_bottom_color = Color("d8e6f5")
		var env := (we as WorldEnvironment).environment
		env.fog_light_color = Color("f4ead8")
		env.fog_density = 0.0009


## Mar de nuvens embaixo da fase toda.
func _montar_nuvens() -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("f4f6fb")
	m.roughness = 1.0
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _esfera_baixa()
	var gerador := RandomNumberGenerator.new()
	gerador.seed = 9
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

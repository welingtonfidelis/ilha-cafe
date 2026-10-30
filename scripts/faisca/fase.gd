class_name Fase
extends Node3D
## Base das fases do Faísca (a Parte 2 da Ilha Cafuné). Monta o céu de dia, a luz, o mar de nuvens lá
## embaixo e o farol da ilha ao longe (a bússola do jogador), e tem as funções que cada fase chama em
## `_montar()` como uma tabela: morros da floresta e plataformas do KayKit, árvores,
## estrelinhas em trilha e em arco, postos de recarga, molas, corações, plataformas que vão e
## voltam, flores de luz com portão, o baú com a Estrela Grande, vaga-lumes escondidos, Bolotas
## e os pontos de dica do vovô. As posições estão em metros; o Faísca tem uns 2,2 m.
## Cada estrelinha e cada vaga-lume tem um nome (a ordem em que a fase cria, ou "b<Bolota>_<n>" nas
## que as Bolotas soltam): os já pegos em outras vezes chegam em `ja_pegas` e `ja_achados`, aparecem
## transparentes e não contam de novo; os novos ficam em `novas` e `novos_vaga_lumes`.

signal estrela_pega(pegas: int, total: int)
signal vaga_lume_achado(achados: int, total: int)
signal posto_aceso(posto: Posto)
signal dica(qual: String)
signal estrela_grande_pega

const PLATAFORMA := "res://assets/faisca/plataforma/"
const FLORESTA := "res://assets/faisca/floresta/"
## Peças do Dungeon Pack (Túneis do Morro).
const MASMORRA := "res://assets/faisca/masmorra/"
## Peças do Restaurant Bits (a 2-1 Cozinha Gigante, ampliadas 8 vezes).
const COZINHA := "res://assets/faisca/cozinha/"
const CAMADA_JOGADOR := 1 << 1
## Camada do que o laser dos pés acende (flores de luz). O Faísca não esbarra nela. Na Ilha a camada 4
## é a dos pontos de impacto dos esqueletos e a 5 a dos moradores; esta é a 6.
const CAMADA_LUZ := 1 << 5
## Paredes invisíveis acima das paredes que se veem (fases sem teto, como os Túneis do Morro): o Faísca
## esbarra e a câmera não. Na Ilha é a camada dos moradores, que não existem dentro das fases.
const CAMADA_LIMITE := 1 << 4
## Cada Bolota derrotada solta estas estrelinhas (já contam no total desde o começo).
const ESTRELAS_POR_BOLOTA := 3

## Onde o Faísca começa.
var inicio := Vector3.ZERO
## Abaixo desta altura o Faísca caiu nas nuvens.
var limite_queda := -12.0
var nome := ""
## Estrelinhas e vaga-lumes pegos em outras vezes (nome -> true), postos antes de entrar na árvore.
var ja_pegas := {}
var ja_achados := {}
## Pegos desta vez (só os que não estavam em `ja_pegas` / `ja_achados`).
var novas: Array[String] = []
var novos_vaga_lumes: Array[String] = []
var estrelas: Array[Area3D] = []
var pegas := 0
var alvos: Array[Alvo] = []
var postos: Array[Posto] = []
var vaga_lumes: Array[VagaLume] = []
var achados := 0
var flores: Array[FlorDeLuz] = []
var portoes: Array[Node3D] = []
var tochas: Array[Tocha] = []
var paredes_rachadas: Array[ParedeRachada] = []
## Portas que abrem com tochas: {"porta": nó da folha, "tochas": [Tocha], "aberta": bool}.
var portas_das_tochas: Array[Dictionary] = []
## Pontes que sobem quando a tocha delas acende.
var pontes: Array[StaticBody3D] = []
var bau: Bau
var molas: Array[Area3D] = []
var coracoes: Array[Area3D] = []
var moveis: Array[AnimatableBody3D] = []
## Peças pedidas em 2026-10-29 para as fases ficarem mais compridas: esteiras, argolas no ar (com as estrelinhas
## do prêmio, que aparecem quando todas acendem), botões que sobem a ponte, nuvens que somem e o canhão.
var esteiras: Array[Esteira] = []
var argolas: Array[Argola] = []
var premio_argolas: Array[Area3D] = []
var botoes: Array[Botao] = []
var ponte_botoes: Array[StaticBody3D] = []
var nuvens_que_somem: Array[NuvemQueSome] = []
var canhoes: Array[Canhao] = []
## E as da 1-2: carrinho de mina, alavancas com as grades delas, cristais que pulam e a Bolotona.
var carrinhos: Array[CarrinhoDeMina] = []
var alavancas: Array[Alavanca] = []
var grades: Array[Grade] = []
var cristais: Array[Area3D] = []
var bolotonas: Array[Bolotona] = []
## E as da 2-1: tampas que pulam, rolos de macarrão, a pizza que gira, as bocas do fogão e a água da pia.
var tampas: Array[TampaQuePula] = []
var rolos: Array[RoloDeMassa] = []
var pizzas: Array[PizzaGiratoria] = []
var bocas: Array[BocaDoFogao] = []
var aguas: Array[Area3D] = []
## E as da 2-2: nuvens que quicam (e as que quicam e somem) e as viagens que esperam o Faísca (nuvem-carro, teleférico).
var nuvens_que_quicam: Array[NuvemQueQuica] = []
var caronas: Array[Carona] = []

## Padrão de playgrounds (aprovado pelo usuário em 2026-10-29; docs/level-design/molde-das-fases.html): os
## playgrounds na ordem ({nome, centro, raio, entrada}), o marco com o ponto do brilho dele (a coluna de luz que
## aparece de toda a fase) e os arcos de saída. Os testes e as fotos usam.
var playgrounds: Array[Dictionary] = []
var brilho_do_marco := Vector3.ZERO
var saidas: Array[Node3D] = []
var _trilhas_por_fazer := []

var _moveis := []  # [corpo, origem, caminho, período, atraso]
var _tempo := 0.0
var _mat_estrela: StandardMaterial3D
var _mat_estrela_vista: StandardMaterial3D
var _proxima_estrela := 0
var _cenas := {}
var _dicas_dadas := {}


func _ready() -> void:
	_montar_ceu_e_luz()
	_montar()
	# Depois do caminho, que diz a altura das nuvens (`limite_queda`).
	_montar_nuvens()
	pegas = ja_pegas.size()
	achados = ja_achados.size()


## Cada fase monta o caminho aqui.
func _montar() -> void:
	pass


## Estrelinhas da fase: as soltas no caminho mais as que as Bolotas ainda vão soltar.
func total_estrelas() -> int:
	var por_vir := 0
	for a in alvos:
		if a is Bolota and not a.derrotado:
			por_vir += ESTRELAS_POR_BOLOTA
	return estrelas.size() + por_vir


func _physics_process(delta: float) -> void:
	_tempo += delta
	for m in _moveis:
		var t: float = (_tempo + m[4]) / m[3]
		var s := 0.5 - 0.5 * cos(TAU * t)
		# Com pausa (as viagens), fica parado um tempo em cada ponta, para dar tempo de subir e descer.
		if m.size() > 5 and m[5] > 0.0:
			s = clampf((s - m[5]) / (1.0 - 2.0 * m[5]), 0.0, 1.0)
		m[0].position = m[1] + m[2] * s


func _process(delta: float) -> void:
	for e in estrelas:
		if e.visible and e.monitoring:
			e.rotation.y += delta * 2.5
	for c in coracoes:
		c.rotation.y += delta * 1.5


# --- peças dos pacotes --------------------------------------------------------------

## Peça de um pacote do KayKit pelo nome do arquivo, sem ".gltf" (as da floresta têm "_Color"
## no nome). `escala` aceita número ou Vector3. `solida` gera a colisão com a forma da malha.
func peca(arquivo: String, pos: Vector3, giro := 0.0, escala: Variant = 1.0, solida := true) -> Node3D:
	return peca_de(FLORESTA if arquivo.contains("_Color") else PLATAFORMA, arquivo, pos, giro, escala, solida)


## Como `peca`, de uma pasta qualquer (MASMORRA, por exemplo).
func peca_de(pasta: String, arquivo: String, pos: Vector3, giro := 0.0, escala: Variant = 1.0, solida := true) -> Node3D:
	var no: Node3D = _cena(pasta + arquivo + ".gltf").instantiate()
	no.position = pos
	no.rotation.y = giro
	no.scale = escala if escala is Vector3 else Vector3.ONE * float(escala)
	add_child(no)
	if solida:
		for mi in no.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).create_trimesh_collision()
	return no


## Morro de grama com paredão de pedra (Forest Nature). `tamanho` é o do nome ("12x12x4");
## `topo` é o meio da grama em cima, então a altura do morro fica para baixo.
func morro(tamanho: String, topo: Vector3, giro := 0.0) -> Node3D:
	var altura := float(tamanho.get_slice("x", 2))
	return peca("Hill_%s_Color1" % tamanho, topo - Vector3(0, altura, 0), giro)


## Plataforma colorida do Platformer ("4x4x1", "blue"), com `topo` no meio da face de cima.
func plataforma(tamanho: String, cor: String, topo: Vector3, giro := 0.0) -> Node3D:
	var altura := float(tamanho.get_slice("x", 2))
	return peca("platform_%s_%s" % [tamanho, cor], topo - Vector3(0, altura, 0), giro)


## Árvore da floresta (`tipo` 1, 2, 4 ou 5; `cor` de 1 a 8: 1 verde, 5 amarela, 6 laranja,
## 7 vermelha, 8 rosa), com um tronco sólido para não atravessar.
func arvore(tipo: int, cor: int, pos: Vector3, escala := 1.0, giro := 0.0) -> Node3D:
	var no := peca("Tree_%d_A_Color%d" % [tipo, cor], pos, giro, escala, false)
	var corpo := StaticBody3D.new()
	corpo.position = pos + Vector3(0, 1.5 * escala, 0)
	var cs := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = 0.35 * escala
	cil.height = 3.0 * escala
	cs.shape = cil
	corpo.add_child(cs)
	add_child(corpo)
	return no


## Enfeite sem colisão (moitas, pedrinhas, grama).
func enfeite(arquivo: String, pos: Vector3, escala := 1.0, giro := 0.0) -> Node3D:
	return peca(arquivo, pos, giro, escala, false)


# --- estrelinhas ------------------------------------------------------------------

func estrelinha(pos: Vector3, id := "") -> Area3D:
	if id == "":
		id = str(_proxima_estrela)
		_proxima_estrela += 1
	if _mat_estrela == null:
		_mat_estrela = StandardMaterial3D.new()
		_mat_estrela.albedo_color = Color("ffd23f")
		_mat_estrela.roughness = 0.3
		_mat_estrela.emission_enabled = true
		_mat_estrela.emission = Color("ffb800")
		_mat_estrela.emission_energy_multiplier = 0.7
		_mat_estrela_vista = _mat_estrela.duplicate()
		_mat_estrela_vista.albedo_color = Color(1.0, 0.86, 0.4, 0.4)
		_mat_estrela_vista.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat_estrela_vista.emission_energy_multiplier = 0.25
	var area := Area3D.new()
	area.set_meta("id", id)
	area.position = pos
	area.collision_layer = 0
	area.collision_mask = CAMADA_JOGADOR
	var cs := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = 0.65
	cs.shape = esfera
	area.add_child(cs)
	var mi := MeshInstance3D.new()
	mi.mesh = Forma.estrela(0.34, 0.15, 0.17)
	mi.material_override = _mat_estrela_vista if ja_pegas.has(id) else _mat_estrela
	area.add_child(mi)
	area.body_entered.connect(_pegar.bind(area))
	add_child(area)
	estrelas.append(area)
	return area


## `n` estrelinhas em linha reta de `de` até `ate`.
func trilha(de: Vector3, ate: Vector3, n: int) -> void:
	for i in n:
		estrelinha(de.lerp(ate, float(i) / maxf(n - 1, 1)))


## `n` estrelinhas num arco de `de` até `ate`, subindo `altura` no meio (o desenho de um pulo).
func arco(de: Vector3, ate: Vector3, altura: float, n: int) -> void:
	for i in n:
		var t := float(i) / maxf(n - 1, 1)
		estrelinha(de.lerp(ate, t) + Vector3.UP * altura * 4.0 * t * (1.0 - t))


## `n` estrelinhas em roda, deitada no chão em volta de `centro`.
func roda(centro: Vector3, raio: float, n: int) -> void:
	for i in n:
		var a := TAU * i / n
		estrelinha(centro + Vector3(cos(a), 0, sin(a)) * raio)


func _pegar(corpo: Node3D, area: Area3D) -> void:
	if not corpo is Jogador or not area.monitoring:
		return
	area.set_deferred("monitoring", false)
	var id: String = area.get_meta("id")
	if not ja_pegas.has(id) and not id in novas:
		novas.append(id)
		pegas += 1
	estrela_pega.emit(pegas, total_estrelas())
	(corpo as Jogador).robo.expressao("feliz", 0.8)
	Sfx.play(self, "estrelinha", 0.0, 0.1)
	var tw := create_tween()
	tw.tween_property(area, "scale", Vector3.ONE * 1.6, 0.1)
	tw.tween_property(area, "scale", Vector3.ONE * 0.01, 0.12)
	tw.tween_callback(area.hide)


## As estrelinhas que a Bolota soltou pulam para perto dela e ficam esperando.
func _soltar_estrelinhas(alvo: Alvo) -> void:
	var centro := alvo.global_position
	var k := alvos.find(alvo)
	for i in ESTRELAS_POR_BOLOTA:
		var a := TAU * i / ESTRELAS_POR_BOLOTA + randf() * 0.5
		var destino := centro + Vector3(cos(a) * 1.3, 0.8, sin(a) * 1.3)
		var e := estrelinha(centro + Vector3.UP * 0.6, "b%d_%d" % [k, i])
		e.monitoring = false
		var tw := e.create_tween()
		tw.tween_property(e, "position", destino + Vector3.UP * 1.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(e, "position", destino, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(func(): e.monitoring = true)


# --- coisas da fase ------------------------------------------------------------------

func posto(pos: Vector3, giro := 0.0) -> Posto:
	var p := Posto.new()
	p.position = pos
	p.rotation.y = giro
	add_child(p)
	p.aceso.connect(func(q: Posto): posto_aceso.emit(q))
	postos.append(p)
	return p


# --- padrão de playgrounds -------------------------------------------------------------

## Registra um playground (para os testes e as fotos): `entrada` é onde o Faísca chega nele.
func playground(nome_do: String, centro: Vector3, raio: float, entrada: Vector3) -> void:
	playgrounds.append({"nome": nome_do, "centro": centro, "raio": raio, "entrada": entrada})


## Chão largo de um playground: o morro do nome esticado em X e Z (`escala`), sem emendas no meio.
func chao_largo(tamanho: String, topo: Vector3, escala: Vector2, giro := 0.0) -> Node3D:
	var altura := float(tamanho.get_slice("x", 2))
	return peca("Hill_%s_Color1" % tamanho, topo - Vector3(0, altura, 0), giro, Vector3(escala.x, 1.0, escala.y))


## Trilha creme pintada no chão: o caminho fácil do playground, da entrada até o arco de saída. Os pontos são
## no chão; a faixa é montada depois do primeiro quadro de física, encostando cada ponta no chão de verdade.
func trilha_creme(pontos: Array, largura := 2.4) -> void:
	_trilhas_por_fazer.append([pontos, largura])
	if _trilhas_por_fazer.size() == 1:
		_fazer_trilhas.call_deferred()


func _fazer_trilhas() -> void:
	await get_tree().physics_frame
	if not is_inside_tree():
		return
	var espaco := get_world_3d().direct_space_state
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("f6e2a8")
	mat.roughness = 1.0
	for t in _trilhas_por_fazer:
		var curva := Curve3D.new()
		for p: Vector3 in t[0]:
			curva.add_point(p)
		curva.bake_interval = 0.8
		var pts := curva.get_baked_points()
		var meia: float = t[1] * 0.5
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var anterior := []
		for i in pts.size():
			var tg := pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)]
			tg.y = 0.0
			var lado := Vector3(-tg.z, 0, tg.x).normalized() * meia
			var par := []
			for q: Vector3 in [pts[i] + lado, pts[i] - lado]:
				var r := espaco.intersect_ray(PhysicsRayQueryParameters3D.create(q + Vector3.UP * 2.0, q + Vector3.DOWN * 3.0, 1))
				par.append((r.position if not r.is_empty() else q) + Vector3.UP * 0.05)
			if not anterior.is_empty():
				for v: Vector3 in [anterior[0], par[0], anterior[1], anterior[1], par[0], par[1]]:
					st.set_normal(Vector3.UP)
					st.add_vertex(v)
			anterior = par
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
	_trilhas_por_fazer.clear()


## Arco de saída do playground: o arco do Platformer, duas vezes maior, em pé no `pe` e atravessado no caminho
## (com `giro` 0 atravessa-se em Z). Aparece de qualquer ponto do playground.
func arco_de_saida(pe: Vector3, giro := 0.0, cor := "red") -> Node3D:
	var a := peca("arch_%s" % cor, pe, giro, 2.0)
	saidas.append(a)
	return a


## O brilho do marco: uma coluna de luz dourada saindo do baú lá no alto, que aparece de toda a fase.
func brilho_de_marco(base: Vector3, altura := 36.0) -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.85, 0.3, 0.22)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var coluna := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = 0.6
	cil.bottom_radius = 1.8
	cil.height = altura
	coluna.mesh = cil
	coluna.material_override = mat
	coluna.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	coluna.position = base + Vector3.UP * altura * 0.5
	add_child(coluna)
	var luz := OmniLight3D.new()
	luz.light_color = Color("ffd86a")
	luz.light_energy = 2.0
	luz.omni_range = 16.0
	luz.position = base + Vector3.UP * 3.0
	add_child(luz)
	brilho_do_marco = base + Vector3.UP * altura * 0.6


## Mola amarela: quem cai em cima vai lá para o alto (`forca` em m/s; 17 dá uns 6 m).
func mola(pos: Vector3, forca := 17.0) -> Area3D:
	var modelo := peca("spring_pad_yellow", pos, 0.0, 1.2)
	var area := AreaDeMola.new()
	area.forca = forca
	area.visual = modelo
	area.escala_normal = Vector3.ONE * 1.2
	area.amassado = Vector3(1.4, 0.7, 1.4)
	area.position = pos + Vector3(0, 1.25, 0)
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(1.6, 0.7, 1.6)
	cs.shape = caixa
	area.add_child(cs)
	add_child(area)
	molas.append(area)
	return area


## Coração extra: devolve um coração (se o Faísca não estiver com todos, ele fica esperando).
func coracao(pos: Vector3) -> Area3D:
	var area := Area3D.new()
	area.position = pos
	area.collision_layer = 0
	area.collision_mask = CAMADA_JOGADOR
	var cs := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = 0.8
	cs.shape = esfera
	area.add_child(cs)
	var modelo: Node3D = _cena(PLATAFORMA + "heart_red.gltf").instantiate()
	modelo.scale = Vector3.ONE * 0.8
	area.add_child(modelo)
	add_child(area)
	area.body_entered.connect(func(corpo: Node3D):
		if corpo is Jogador and area.visible and corpo.curar():
			area.set_deferred("monitoring", false)
			area.hide())
	coracoes.append(area)
	return area


## Plataforma colorida que vai e volta `caminho` (em metros) a cada `periodo` segundos.
func movel(tamanho: String, cor: String, topo: Vector3, caminho: Vector3, periodo := 4.0, atraso := 0.0) -> AnimatableBody3D:
	var corpo := AnimatableBody3D.new()
	var dim := Vector3(float(tamanho.get_slice("x", 0)), float(tamanho.get_slice("x", 2)), float(tamanho.get_slice("x", 1)))
	corpo.position = topo - Vector3(0, dim.y, 0)
	var modelo: Node3D = _cena(PLATAFORMA + "platform_%s_%s.gltf" % [tamanho, cor]).instantiate()
	corpo.add_child(modelo)
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = dim
	cs.shape = caixa
	cs.position.y = dim.y / 2.0
	corpo.add_child(cs)
	add_child(corpo)
	_moveis.append([corpo, corpo.position, caminho, periodo, atraso])
	moveis.append(corpo)
	return corpo


## Esteira rolante com `topo` no meio da faixa, levando para o +Z do `giro` (0 leva para +Z; PI, para -Z). A
## faixa fica 3 cm acima de `topo`: quem a esteira leva até a ponta desce um degrauzinho para a plataforma do
## lado (na mesma altura, a emenda segurava o Faísca parado ali).
func esteira(topo: Vector3, giro: float, velocidade := 3.0, cor := "blue") -> Esteira:
	var e := Esteira.new()
	e.velocidade = velocidade
	e.cor = cor
	e.position = topo - Vector3(0, Esteira.ALTURA - 0.03, 0)
	e.rotation.y = giro
	add_child(e)
	esteiras.append(e)
	return e


## Argola em pé no ar, com o pé em `pe` e a abertura virada para o caminho (`giro` 0: atravessa-se em Z).
func argola(pe: Vector3, giro := 0.0, cor := "red") -> Argola:
	var a := Argola.new()
	a.cor = cor
	a.position = pe
	a.rotation.y = giro
	add_child(a)
	a.acesa.connect(_argola_acesa)
	argolas.append(a)
	return a


## Estrelinhas do prêmio das argolas: ficam escondidas até todas as argolas acenderem.
func premio_das_argolas(posicoes: Array) -> void:
	for p: Vector3 in posicoes:
		var e := estrelinha(p)
		e.visible = false
		e.monitoring = false
		premio_argolas.append(e)


func _argola_acesa(_a: Argola) -> void:
	if not argolas.all(func(x: Argola) -> bool: return x.esta_acesa):
		return
	for i in premio_argolas.size():
		var e := premio_argolas[i]
		var alvo := e.position
		e.position = alvo + Vector3.UP * 4.0
		e.scale = Vector3.ONE * 0.01
		e.show()
		var tw := e.create_tween()
		tw.tween_interval(0.08 * i)
		tw.tween_property(e, "position", alvo, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(e, "scale", Vector3.ONE, 0.4)
		tw.tween_callback(func() -> void: e.monitoring = true)
	if not premio_argolas.is_empty():
		Fx.confetti(self, premio_argolas[0].position + Vector3.UP, 60, 5.0)
	Sfx.play(self, "bandeira", 0.0, 0.0)


## Botão colorido no chão. Com todos os botões apertados, a ponte dos botões sobe.
func botao(pos: Vector3, cor: String, giro := 0.0) -> Botao:
	var b := Botao.new()
	b.cor = cor
	b.position = pos
	b.rotation.y = giro
	add_child(b)
	b.apertado.connect(_botao_apertado)
	botoes.append(b)
	return b


## Plataformas escondidas lá embaixo, que sobem para `topos` quando todos os botões estão apertados.
func ponte_dos_botoes(topos: Array, tamanho := "4x4x1", cores := ["red", "yellow", "blue"]) -> void:
	var dim := Vector3(float(tamanho.get_slice("x", 0)), float(tamanho.get_slice("x", 2)), float(tamanho.get_slice("x", 1)))
	for i in topos.size():
		var corpo := StaticBody3D.new()
		var lugar: Vector3 = topos[i] - Vector3(0, dim.y, 0)
		corpo.set_meta("lugar", lugar)
		corpo.position = lugar - Vector3(0, 14.0, 0)
		corpo.visible = false
		var modelo: Node3D = _cena(PLATAFORMA + "platform_%s_%s.gltf" % [tamanho, cores[i % cores.size()]]).instantiate()
		corpo.add_child(modelo)
		var cs := CollisionShape3D.new()
		var caixa := BoxShape3D.new()
		caixa.size = dim
		cs.shape = caixa
		cs.position.y = dim.y / 2.0
		cs.disabled = true
		corpo.add_child(cs)
		add_child(corpo)
		ponte_botoes.append(corpo)


func _botao_apertado(_b: Botao) -> void:
	if not botoes.all(func(x: Botao) -> bool: return x.esta_apertado):
		return
	for i in ponte_botoes.size():
		var corpo := ponte_botoes[i]
		corpo.show()
		(corpo.get_child(1) as CollisionShape3D).set_deferred("disabled", false)
		var tw := corpo.create_tween()
		tw.tween_interval(0.25 * i)
		tw.tween_property(corpo, "position", corpo.get_meta("lugar"), 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func() -> void: Fx.confetti(self, corpo.position + Vector3.UP * 1.5, 16, 2.5))
	Sfx.play(self, "bandeira", 0.0, 0.0)


## A ponte dos botões já subiu e está no lugar.
func ponte_dos_botoes_pronta() -> bool:
	return not ponte_botoes.is_empty() and ponte_botoes.all(func(c: StaticBody3D) -> bool:
		return c.visible and c.position.distance_to(c.get_meta("lugar")) < 0.05)


## Nuvem lilás que some um instante depois de pisada e volta depois de 3 s (`topo` em cima). Com `bolha`, é
## uma bolha de sabão (a pia da 2-1).
func nuvem_que_some(topo: Vector3, raio := 1.6, bolha := false) -> NuvemQueSome:
	var n := NuvemQueSome.new()
	n.raio = raio
	n.bolha = bolha
	n.position = topo
	add_child(n)
	nuvens_que_somem.append(n)
	return n


## Nuvem de algodão-doce que quica (rosa), com `topo` onde se pisa; com `some`, é lilás e some depois do quique.
func nuvem_que_quica(topo: Vector3, raio := 2.2, forca := 16.0, some := false) -> NuvemQueQuica:
	var n := NuvemQueQuica.new()
	n.raio = raio
	n.forca = forca
	n.some = some
	n.position = topo
	add_child(n)
	nuvens_que_quicam.append(n)
	return n


## Viagem que espera o Faísca subir em `de` e o leva até `ate` (`tipo` "nuvem" ou "cabine"; os dois pontos são o
## chão dela, onde ele pisa).
func carona(de: Vector3, ate: Vector3, tipo := "nuvem", velocidade := 5.0) -> Carona:
	var c := Carona.new()
	c.de = de
	c.ate = ate
	c.tipo = tipo
	c.velocidade = velocidade
	# A posição vai antes de entrar na cena: depois, o corpo animado só sai do lugar quando começa a andar.
	c.position = de
	add_child(c)
	caronas.append(c)
	return c


## Canhão em `pos` que lança o Faísca até `destino` (onde ele pousa).
func canhao(pos: Vector3, destino: Vector3, cor := "blue") -> Canhao:
	var c := Canhao.new()
	c.cor = cor
	c.destino = destino
	c.position = pos
	add_child(c)
	canhoes.append(c)
	return c


## Trilhos de `de` até `ate` (no chão, em linha reta): dois trilhos de ferro e dormentes de madeira.
func trilhos(de: Vector3, ate: Vector3) -> void:
	var ferro := _material(Color("5a5668"))
	ferro.metallic = 0.6
	var madeira := _material(Color("6a4126"))
	var dir := (ate - de).normalized()
	var lado := Vector3.UP.cross(dir).normalized()
	var comprimento := de.distance_to(ate)
	var base := Basis(lado, Vector3.UP, dir)
	for s in [-0.7, 0.7]:
		var t := MeshInstance3D.new()
		var caixa := BoxMesh.new()
		caixa.size = Vector3(0.12, 0.12, comprimento)
		t.mesh = caixa
		t.material_override = ferro
		add_child(t)
		t.global_transform = Transform3D(base, (de + ate) * 0.5 + lado * s + Vector3.UP * 0.12)
	var n := int(comprimento / 1.2)
	for i in n + 1:
		var d := MeshInstance3D.new()
		var caixa := BoxMesh.new()
		caixa.size = Vector3(2.0, 0.1, 0.35)
		d.mesh = caixa
		d.material_override = madeira
		add_child(d)
		d.global_transform = Transform3D(base, de.lerp(ate, float(i) / maxf(n, 1)) + Vector3.UP * 0.05)


## Carrinho de mina nos trilhos de `de` até `ate` (o carrinho anda sozinho com o Faísca dentro).
func carrinho(de: Vector3, ate: Vector3) -> CarrinhoDeMina:
	trilhos(de - (ate - de).normalized() * 2.0, ate + (ate - de).normalized() * 2.0)
	var c := CarrinhoDeMina.new()
	c.de = de
	c.ate = ate
	# A posição vai antes de entrar na cena: depois, o corpo animado só sai do lugar quando começa a andar.
	c.position = de
	add_child(c)
	carrinhos.append(c)
	return c


## Porta de masmorra com grade em `pos` (o meio do vão, no chão) e a alavanca que abre em `alavanca_em`.
func portao_de_grade(pos: Vector3, giro: float, alavanca_em: Vector3, cor := "yellow") -> Grade:
	var vao := peca_de(MASMORRA, "wall_doorway", pos, giro, 1.5, false)
	vao.find_child("wall_doorway_door", true, false).queue_free()
	var g := Grade.new()
	g.position = pos
	g.rotation.y = giro
	add_child(g)
	grades.append(g)
	var a := Alavanca.new()
	a.cor = cor
	a.position = alavanca_em
	add_child(a)
	a.puxada.connect(func(_a: Alavanca) -> void: g.abrir())
	alavancas.append(a)
	return g


## Cristal azul que joga para o alto, como a mola (mesma `forca`): três prismas brilhando.
func mola_de_cristal(pos: Vector3, forca := 19.0) -> Area3D:
	var brilho := StandardMaterial3D.new()
	brilho.albedo_color = Color("7fd8ff")
	brilho.emission_enabled = true
	brilho.emission = Color("4ab8ff")
	brilho.emission_energy_multiplier = 1.6
	brilho.roughness = 0.2
	var visual := Node3D.new()
	visual.position = pos
	add_child(visual)
	for spec in [[Vector3(0, 0, 0), 0.55, 1.6, 0.0], [Vector3(0.6, 0, 0.3), 0.32, 1.0, 0.35], [Vector3(-0.5, 0, -0.4), 0.3, 0.9, -0.3]]:
		var mi := MeshInstance3D.new()
		var prisma := CylinderMesh.new()
		prisma.radial_segments = 6
		prisma.rings = 1
		prisma.top_radius = spec[1] * 0.35
		prisma.bottom_radius = spec[1]
		prisma.height = spec[2]
		mi.mesh = prisma
		mi.material_override = brilho
		mi.position = spec[0] + Vector3.UP * spec[2] * 0.5
		mi.rotation.z = spec[3]
		visual.add_child(mi)
	var luz := OmniLight3D.new()
	luz.light_color = Color("7fd8ff")
	luz.light_energy = 1.2
	luz.omni_range = 6.0
	luz.position = Vector3.UP * 1.2
	visual.add_child(luz)
	var corpo := StaticBody3D.new()
	var cs0 := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = 0.8
	cil.height = 0.5
	cs0.shape = cil
	cs0.position.y = 0.25
	corpo.add_child(cs0)
	visual.add_child(corpo)
	var area := AreaDeMola.new()
	area.forca = forca
	area.visual = visual
	area.amassado = Vector3(1.2, 0.75, 1.2)
	area.position = pos + Vector3(0, 0.9, 0)
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(1.8, 1.0, 1.8)
	cs.shape = caixa
	area.add_child(cs)
	add_child(area)
	cristais.append(area)
	molas.append(area)
	return area


## A Bolotona e as três filhas dela (escondidas até ela se desfazer).
func bolotona(pos: Vector3) -> Bolotona:
	var grande := Bolotona.new()
	grande.position = pos
	grande.dormindo = true
	add_child(grande)
	grande.derrotada.connect(_soltar_estrelinhas)
	alvos.append(grande)
	for i in 3:
		var filha := bolota(pos)
		Bolotona.guardar(filha)
		grande.filhas.append(filha)
	bolotonas.append(grande)
	return grande


## A Bolotona e as filhas já foram todas derrotadas.
func bolotona_vencida(b: Bolotona) -> bool:
	return b.derrotado and b.filhas.all(func(f: Bolota) -> bool: return f.derrotado)


## Como `movel`, com uma peça qualquer de `pasta` (o prato que boia, a frigideira): `tamanho` é a caixa de
## colisão (ou o cilindro, com `redondo`), com o topo em `topo`. `pausa` (de 0 a 0,5) é quanto do vaivém ele
## fica parado em cada ponta (as viagens usam, para dar tempo de descer andando).
func movel_peca(pasta: String, arquivo: String, escala: float, topo: Vector3, tamanho: Vector3, caminho: Vector3,
		periodo := 4.0, atraso := 0.0, redondo := false, pausa := 0.0) -> AnimatableBody3D:
	var corpo := AnimatableBody3D.new()
	corpo.position = topo - Vector3(0, tamanho.y, 0)
	var modelo: Node3D = _cena(pasta + arquivo + ".gltf").instantiate()
	modelo.scale = Vector3.ONE * escala
	corpo.add_child(modelo)
	var cs := CollisionShape3D.new()
	if redondo:
		var cil := CylinderShape3D.new()
		cil.radius = tamanho.x * 0.5
		cil.height = tamanho.y
		cs.shape = cil
	else:
		var caixa := BoxShape3D.new()
		caixa.size = tamanho
		cs.shape = caixa
	cs.position.y = tamanho.y / 2.0
	corpo.add_child(cs)
	add_child(corpo)
	_moveis.append([corpo, corpo.position, caminho, periodo, atraso, pausa])
	moveis.append(corpo)
	return corpo


## Peça da cozinha (Restaurant Bits), 8 vezes maior se não disser outra escala.
func cozinha(arquivo: String, pos: Vector3, giro := 0.0, escala: Variant = 8.0, solida := true) -> Node3D:
	return peca_de(COZINHA, arquivo, pos, giro, escala, solida)


## Panela no fogo com a tampa que pula: a panela fica em `pos` (no tampo), a tampa em cima dela.
func panela_com_tampa(pos: Vector3, forca := 21.0, atraso := 0.0, escala := 6.0) -> TampaQuePula:
	cozinha("pot_A", pos, 0.0, escala)
	var t := TampaQuePula.new()
	t.forca = forca
	t.atraso = atraso
	t.escala = escala
	t.position = pos + Vector3.UP * 0.5 * escala
	add_child(t)
	tampas.append(t)
	return t


## Rolo de macarrão rolando `caminho` metros e voltando, a partir de `pos` (no tampo).
func rolo(pos: Vector3, caminho: Vector3, periodo := 4.0, atraso := 0.0) -> RoloDeMassa:
	var r := RoloDeMassa.new()
	r.caminho = caminho
	r.periodo = periodo
	r.atraso = atraso
	r.position = pos
	add_child(r)
	rolos.append(r)
	return r


## Pizza gigante girando, com o meio de baixo em `pos` (com `escala` 8 ela tem 16 m e 2,4 de altura).
func pizza(pos: Vector3, velocidade := 0.35, escala := 8.0) -> PizzaGiratoria:
	var p := PizzaGiratoria.new()
	p.velocidade = velocidade
	p.escala = escala
	p.position = pos
	add_child(p)
	pizzas.append(p)
	return p


## Boca do fogão que acende e apaga, com o meio em `pos` (no tampo).
func boca(pos: Vector3, raio := 2.6, atraso := 0.0) -> BocaDoFogao:
	var b := BocaDoFogao.new()
	b.raio = raio
	b.atraso = atraso
	b.position = pos
	add_child(b)
	bocas.append(b)
	return b


## Água com espuma (a pia da 2-1): a superfície em `centro`, do `tamanho` no plano. Encostar nela é cair.
func agua(centro: Vector3, tamanho: Vector2) -> Area3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.55, 0.82, 1.0, 0.75)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.1
	m.metallic = 0.2
	var plano := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = tamanho
	plano.mesh = pm
	plano.material_override = m
	plano.position = centro
	add_child(plano)
	# Espuma: bolinhas brancas boiando.
	var espuma := StandardMaterial3D.new()
	espuma.albedo_color = Color("f4fbff")
	espuma.roughness = 0.9
	var gerador := RandomNumberGenerator.new()
	gerador.seed = int(centro.z * 10.0)
	for i in int(tamanho.x * tamanho.y / 6.0):
		var bola := MeshInstance3D.new()
		var esfera := SphereMesh.new()
		esfera.radius = gerador.randf_range(0.3, 0.8)
		esfera.height = esfera.radius * 1.2
		bola.mesh = esfera
		bola.material_override = espuma
		bola.position = centro + Vector3(gerador.randf_range(-0.5, 0.5) * tamanho.x, 0.05, gerador.randf_range(-0.5, 0.5) * tamanho.y)
		add_child(bola)
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = CAMADA_JOGADOR
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(tamanho.x, 1.2, tamanho.y)
	cs.shape = caixa
	cs.position = centro + Vector3.DOWN * 0.7
	area.add_child(cs)
	add_child(area)
	area.body_entered.connect(func(corpo: Node3D) -> void:
		if corpo is Jogador:
			Fx.confetti(self, corpo.global_position, 20, 3.0)
			(corpo as Jogador).cair())
	aguas.append(area)
	return area


## Sorvete de casquinha que joga para o alto, como a mola: a bola de cima é o que se pisa. Fica baixinho
## (2,1 m), para dar para subir nele com um pulo.
func mola_de_sorvete(pos: Vector3, forca := 19.0, sabor := "strawberry") -> Area3D:
	var visual := cozinha("food_icecream_cone_" + sabor, pos, 0.0, 2.0, false)
	var corpo := StaticBody3D.new()
	var cs0 := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = 0.5
	cil.height = 1.3
	cs0.shape = cil
	cs0.position = pos + Vector3.UP * 0.65
	corpo.add_child(cs0)
	add_child(corpo)
	var area := AreaDeMola.new()
	area.forca = forca
	area.visual = visual
	area.escala_normal = Vector3.ONE * 2.0
	area.amassado = Vector3(2.4, 1.6, 2.4)
	area.position = pos + Vector3(0, 1.9, 0)
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(1.8, 1.0, 1.8)
	cs.shape = caixa
	area.add_child(cs)
	add_child(area)
	molas.append(area)
	return area


## Nuvenzinha firme para pisar (segunda chance no meio de um vão), com `topo` em cima.
func nuvem(topo: Vector3, raio := 1.6) -> StaticBody3D:
	var corpo := StaticBody3D.new()
	corpo.position = topo
	var m := _material(Color("ffffff"))
	m.roughness = 1.0
	for bola in [[Vector3(0, -0.35, 0), Vector3(raio, 0.5, raio)], [Vector3(raio * 0.5, -0.2, raio * 0.3), Vector3(raio * 0.6, 0.55, raio * 0.6)],
			[Vector3(-raio * 0.45, -0.25, -raio * 0.35), Vector3(raio * 0.65, 0.5, raio * 0.6)], [Vector3(-raio * 0.2, -0.3, raio * 0.5), Vector3(raio * 0.5, 0.45, raio * 0.5)]]:
		var mi := MeshInstance3D.new()
		mi.mesh = Forma.superelipsoide(bola[1], 1.0, 1.0)
		mi.material_override = m
		mi.position = bola[0]
		corpo.add_child(mi)
	var cs := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = raio
	cil.height = 0.7
	cs.shape = cil
	cs.position.y = -0.35
	corpo.add_child(cs)
	add_child(corpo)
	return corpo


func flor(pos: Vector3) -> FlorDeLuz:
	var f := FlorDeLuz.new()
	f.position = pos
	f.scale = Vector3.ONE * 1.4
	add_child(f)
	f.acesa.connect(_flor_acesa)
	flores.append(f)
	return f


## Portão vermelho (a barreira do Platformer, 4 m de largura por 4 de altura). Abre, afundando
## no chão, quando todas as flores de luz da fase estão acesas.
func portao(pos: Vector3, giro := 0.0) -> Node3D:
	var corpo := StaticBody3D.new()
	corpo.position = pos
	corpo.rotation.y = giro
	var modelo: Node3D = _cena(PLATAFORMA + "barrier_4x1x2_red.gltf").instantiate()
	modelo.scale = Vector3(1, 2, 1)
	corpo.add_child(modelo)
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(4, 4, 1)
	cs.shape = caixa
	cs.position.y = 2.0
	corpo.add_child(cs)
	add_child(corpo)
	portoes.append(corpo)
	return corpo


func portao_aberto(p: Node3D) -> bool:
	return p.has_meta("aberto")


func _flor_acesa(_f: FlorDeLuz) -> void:
	for f in flores:
		if not f.esta_acesa:
			return
	for p in portoes:
		if portao_aberto(p):
			continue
		p.set_meta("aberto", true)
		var tw := p.create_tween()
		tw.tween_property(p, "position:y", p.position.y + 0.3, 0.2)
		tw.tween_property(p, "position:y", p.position.y - 4.3, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(func(): p.process_mode = Node.PROCESS_MODE_DISABLED; p.hide())


## Tocha que o laser acende (com pedestal de pedra, ou direto no chão de cima de um pilar ou caixote).
func tocha(pos: Vector3, com_pedestal := true, acesa := false) -> Tocha:
	var t := Tocha.new()
	t.position = pos
	t.com_pedestal = com_pedestal
	t.acesa_no_comeco = acesa
	add_child(t)
	t.acesa.connect(_tocha_acesa)
	tochas.append(t)
	return t


## Parede rachada (6 x 6 m) com a frente para +Z girada de `giro`: três golpes quebram.
func parede_rachada(pos: Vector3, giro := 0.0) -> ParedeRachada:
	var p := ParedeRachada.new()
	p.position = pos
	p.rotation.y = giro
	add_child(p)
	paredes_rachadas.append(p)
	return p


## Vão de porta com a porta de madeira do Dungeon Pack (6 x 6 m), fechada até as `quais` tochas acenderem;
## aí a porta gira e abre. Devolve o nó da parede.
func porta_das_tochas(pos: Vector3, giro: float, quais: Array) -> Node3D:
	var vao := peca_de(MASMORRA, "wall_doorway", pos, giro, 1.5)
	portas_das_tochas.append({"porta": vao.find_child("wall_doorway_door", true, false), "tochas": quais, "aberta": false})
	return vao


## Ponte de tábuas (3 m de largura) de `de` até `ate` (os dois na altura de pisar), escondida no escuro
## até a tocha `t` acender; aí ela sobe lá de baixo e para no lugar.
func ponte_da_tocha(t: Tocha, de: Vector3, ate: Vector3) -> StaticBody3D:
	var corpo := StaticBody3D.new()
	var meio := (de + ate) * 0.5
	var dir := ate - de
	var comprimento := dir.length()
	corpo.position = meio
	corpo.rotation.y = atan2(dir.x, dir.z)
	var n := maxi(1, ceili(comprimento / 3.0))
	for i in n:
		var tabua: Node3D = _cena(MASMORRA + "floor_wood_small.gltf").instantiate()
		tabua.scale = Vector3(1.5, 1.5, comprimento / n / 2.0)
		tabua.position = Vector3(0, -0.08, -comprimento * 0.5 + comprimento / n * (i + 0.5))
		corpo.add_child(tabua)
	var vigas := _material(Color("6b3f22"))
	for lado in [-1.0, 1.0]:
		var viga := MeshInstance3D.new()
		var caixa := BoxMesh.new()
		caixa.size = Vector3(0.25, 0.35, comprimento)
		viga.mesh = caixa
		viga.material_override = vigas
		viga.position = Vector3(1.4 * lado, -0.3, 0)
		corpo.add_child(viga)
	var cs := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(3.0, 0.4, comprimento)
	cs.shape = forma
	cs.position.y = -0.2
	cs.disabled = true
	corpo.add_child(cs)
	corpo.visible = false
	add_child(corpo)
	corpo.set_meta("lugar", meio)
	corpo.set_meta("tocha", t)
	pontes.append(corpo)
	return corpo


func ponte_no_lugar(p: StaticBody3D) -> bool:
	return p.has_meta("no_lugar")


func _tocha_acesa(t: Tocha) -> void:
	for p in pontes:
		if p.get_meta("tocha") == t and not p.visible:
			var lugar: Vector3 = p.get_meta("lugar")
			p.position = lugar + Vector3.DOWN * 14.0
			p.visible = true
			(p.get_child(p.get_child_count() - 1) as CollisionShape3D).disabled = false
			var tw := p.create_tween()
			tw.tween_property(p, "position", lugar, 1.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_callback(func(): p.set_meta("no_lugar", true))
	for d in portas_das_tochas:
		if d.aberta or not (d.tochas as Array).all(func(q: Tocha) -> bool: return q.esta_acesa):
			continue
		d.aberta = true
		var folha: Node3D = d.porta
		var tw := folha.create_tween()
		tw.tween_interval(0.4)
		tw.tween_property(folha, "rotation:y", folha.rotation.y - 1.75, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func colocar_bau(pos: Vector3, giro := 0.0, dourado := false) -> Bau:
	bau = Bau.new()
	bau.dourado = dourado
	bau.position = pos
	bau.rotation.y = giro
	add_child(bau)
	bau.estrela_pega.connect(func(): estrela_grande_pega.emit())
	return bau


func vaga_lume(pos: Vector3) -> VagaLume:
	var v := VagaLume.new()
	var id := str(vaga_lumes.size())
	v.position = pos
	v.ja_visto = ja_achados.has(id)
	add_child(v)
	v.achado.connect(func(_v: VagaLume):
		if not v.ja_visto and not id in novos_vaga_lumes:
			novos_vaga_lumes.append(id)
			achados += 1
		vaga_lume_achado.emit(achados, vaga_lumes.size()))
	vaga_lumes.append(v)
	return v


## Uma Bolota da turma do Rei Bolotão: `tipo` é um dos BolotaMonstro.TIPOS (o Alien é a Bolota de sempre).
func bolota(pos: Vector3, dormindo := false, tipo := "alien") -> BolotaMonstro:
	var b := BolotaMonstro.new(tipo)
	b.position = pos
	b.dormindo = dormindo
	add_child(b)
	b.derrotada.connect(_soltar_estrelinhas)
	alvos.append(b)
	return b


## Lugar onde o Vovô Farol dá uma dica, uma vez só ("pulo_alto", "flutuar", "laser").
func ponto_de_dica(pos: Vector3, raio: float, qual: String) -> void:
	var area := Area3D.new()
	area.position = pos
	area.collision_layer = 0
	area.collision_mask = CAMADA_JOGADOR
	var cs := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = raio
	cs.shape = esfera
	area.add_child(cs)
	add_child(area)
	area.body_entered.connect(func(corpo: Node3D):
		if corpo is Jogador and not _dicas_dadas.has(qual):
			_dicas_dadas[qual] = true
			dica.emit(qual))


# --- céu, nuvens e farol --------------------------------------------------------------

func _montar_ceu_e_luz() -> void:
	var ceu := ProceduralSkyMaterial.new()
	ceu.sky_top_color = Color("5fa4ff")
	ceu.sky_horizon_color = Color("cfe8ff")
	ceu.ground_horizon_color = Color("d9ecff")
	ceu.ground_bottom_color = Color("8fc3ff")
	ceu.sun_angle_max = 20.0
	var sky := Sky.new()
	sky.sky_material = ceu
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	# Luz ambiente quase neutra: com a cor do céu as sombras saíam azuis, parecendo buracos.
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("e2e0ee")
	env.ambient_light_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.95
	env.ssao_enabled = true
	env.glow_enabled = true
	env.glow_intensity = 0.45
	env.glow_hdr_threshold = 1.3
	# Neblina clarinha ao longe: as ilhas distantes ficam azuladas, dando fundo.
	env.fog_enabled = true
	env.fog_light_color = Color("d6ebff")
	env.fog_density = 0.004
	env.fog_sky_affect = 0.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, -35, 0)
	sol.light_energy = 1.05
	sol.shadow_enabled = true
	sol.shadow_opacity = 0.75
	sol.light_angular_distance = 1.5
	sol.directional_shadow_max_distance = 80.0
	add_child(sol)


## Mar de nuvens: muitas bolas brancas achatadas um pouco abaixo de onde o Faísca cai.
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
	# Bem abaixo de onde o Faísca cai, com buracos para o azul de baixo aparecer.
	for i in 40:
		for j in 40:
			if gerador.randf() < 0.3:
				continue
			var p := Vector3(-240 + i * 12 + gerador.randf_range(-5, 5), limite_queda - 5.0 + gerador.randf_range(-2.5, 1.5), 70 - j * 12 + gerador.randf_range(-5, 5))
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


## O farol da Ilha Cafuné ao longe, numa ilhota com grama, sempre à vista, como bússola.
func farol(pos: Vector3, escala := 1.0) -> void:
	var raiz := Node3D.new()
	raiz.position = pos
	raiz.scale = Vector3.ONE * escala
	add_child(raiz)
	var ilha := MeshInstance3D.new()
	ilha.mesh = Forma.superelipsoide(Vector3(9, 4, 9), 1.0, 1.0, -PI / 2.0)
	ilha.material_override = _material(Color("8fd16a"))
	raiz.add_child(ilha)
	var pedra := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 8.5
	cone.bottom_radius = 2.0
	cone.height = 10.0
	pedra.mesh = cone
	pedra.position.y = -4.5
	pedra.material_override = _material(Color("b9bccb"))
	raiz.add_child(pedra)
	var torre := FarolModelo.new()
	torre.escala = 6.0
	torre.aceso = true
	torre.position.y = -0.2
	raiz.add_child(torre)


func _material(cor: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = 0.7
	return m


func _esfera_baixa() -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = 1.0
	s.height = 2.0
	s.radial_segments = 16
	s.rings = 8
	return s


func _cena(caminho: String) -> PackedScene:
	if not _cenas.has(caminho):
		_cenas[caminho] = load(caminho)
	return _cenas[caminho]

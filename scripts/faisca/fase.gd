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
const CAMADA_JOGADOR := 1 << 1
## Camada do que o laser dos pés acende (flores de luz). O Faísca não esbarra nela. Na Ilha a camada 4
## é a dos pontos de impacto dos esqueletos e a 5 a dos moradores; esta é a 6.
const CAMADA_LUZ := 1 << 5
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
var bau: Bau
var molas: Array[Area3D] = []
var coracoes: Array[Area3D] = []
var moveis: Array[AnimatableBody3D] = []

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
		m[0].position = m[1] + m[2] * (0.5 - 0.5 * cos(TAU * t))


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
	var pasta := FLORESTA if arquivo.contains("_Color") else PLATAFORMA
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


## Mola amarela: quem cai em cima vai lá para o alto (`forca` em m/s; 17 dá uns 6 m).
func mola(pos: Vector3, forca := 17.0) -> Area3D:
	var modelo := peca("spring_pad_yellow", pos, 0.0, 1.2)
	var area := Area3D.new()
	area.position = pos + Vector3(0, 1.25, 0)
	area.collision_layer = 0
	area.collision_mask = CAMADA_JOGADOR
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(1.6, 0.7, 1.6)
	cs.shape = caixa
	area.add_child(cs)
	add_child(area)
	area.body_entered.connect(func(corpo: Node3D):
		if corpo is Jogador and corpo.velocity.y <= 1.0:
			corpo.lancar(forca)
			var tw := modelo.create_tween()
			tw.tween_property(modelo, "scale", Vector3(1.4, 0.7, 1.4), 0.06)
			tw.tween_property(modelo, "scale", Vector3.ONE * 1.2, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT))
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


func colocar_bau(pos: Vector3, giro := 0.0) -> Bau:
	bau = Bau.new()
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


func bolota(pos: Vector3, dormindo := false) -> Bolota:
	var b := Bolota.new()
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

class_name VegetacaoIlha
extends Node3D
## A vegetação abundante da ilha (pedido do usuário em 2026-11-11, com uma imagem de referência de campo cheio de
## grama alta, trevos, florzinhas e samambaias: "eu tinha imaginado algo mais abundante de vegetação"; no estilo do
## jogo, não realista). Só no campo e na mata (pela cor de cada triângulo do terreno gerado), em pedaços de PEDACO m
## criados em volta da câmera e apagados quando ela se afasta. Cada pedaço tem um MultiMesh por planta (Plantas3D) e
## o desenho é do `vegetacao.gdshader`: vento, a grama abrindo quando o jogador passa e as plantas encolhendo de longe,
## onde o desenho do chão (item 13) assume.
## - Campo: tufos de grama por todo lado (mais altos e mais cheios em manchas), trevos em canteiros e florzinhas de
##   cinco cores nos prados.
## - Mata: grama mais alta e mais rala, samambaias e trevos no musgo.
## Nada nasce embaixo do que está em cima do chão (casa, cerca, pedra, pista, deque): um raio de cima confere cada
## planta. Em volta dos lugares das caixas de munição, que ficam no chão, só trevos (a grama esconderia a caixa).
## Sem tela (os testes), não faz nada.

## A grade do terreno do tools/gerar_ilha.gd (CELL, HALF_X e HALF_Z): mudou lá, mude aqui.
const CELULA := 4.0
const METADE_X := 224.0
const METADE_Z := 272.0
## As cores do campo e da mata no terreno (C_GRASS e C_GRASS_FOREST do gerador).
const COR_CAMPO := Color("#8cc96b")
const COR_MATA := Color("#6fb35a")
const PEDACO := 16.0
## Cria os pedaços até esta distância da câmera e apaga depois desta (o shader faz as plantas sumirem antes de 38 m).
const CRIA_ATE := 40.0
const APAGA_DE := 60.0
## Tempo máximo por quadro montando pedaços (em milissegundos).
const ORCAMENTO_MS := 6.0
const CORES_DAS_FLORES := [Color("#ffffff"), Color("#ffd23f"), Color("#ff8fc8"), Color("#9fd4ff"), Color("#ffa24c")]

var terreno: StaticBody3D
var jogador: Node3D
## Quantas plantas de cada tipo estão na tela agora (para os testes e as fotos).
var plantas := {"tufo": 0, "trevos": 0, "florzinha": 0, "samambaia": 0}

var _pedacos := {}
var _fila: Array[Vector2i] = []
var _material: ShaderMaterial
var _malhas := {}
var _vertices: PackedVector3Array
var _cores: PackedColorArray
var _colunas := 0
var _linhas := 0
## Onde a grama fica baixinha: os lugares fixos das caixas de munição (Marcadores/Municao), que ficam no chão.
var _baixinha: Array[Vector3] = []
var _ruido := FastNoiseLite.new()
var _ruido2 := FastNoiseLite.new()


func _ready() -> void:
	if DisplayServer.get_name() == "headless" or terreno == null:
		set_physics_process(false)
		return
	var malha := (terreno.get_node("Malha") as MeshInstance3D).mesh
	var arrays := malha.surface_get_arrays(0)
	_vertices = arrays[Mesh.ARRAY_VERTEX]
	_cores = arrays[Mesh.ARRAY_COLOR]
	_colunas = int(METADE_X * 2.0 / CELULA)
	_linhas = int(METADE_Z * 2.0 / CELULA)
	if _vertices.size() != _colunas * _linhas * 6 or _cores.size() != _vertices.size():
		push_warning("VegetacaoIlha: o terreno não tem a grade esperada; sem vegetação")
		set_physics_process(false)
		return
	_material = ShaderMaterial.new()
	_material.shader = load("res://scripts/vegetacao/vegetacao.gdshader")
	_malhas = {"tufo": Plantas3D.tufo(), "trevos": Plantas3D.trevos(), "florzinha": Plantas3D.florzinha(),
			"samambaia": Plantas3D.samambaia()}
	var municao := terreno.get_parent().get_node_or_null("Marcadores/Municao")
	if municao:
		for m in municao.get_children():
			_baixinha.append((m as Node3D).global_position)
	_ruido.seed = 3
	_ruido.frequency = 0.06
	_ruido2.seed = 8
	_ruido2.frequency = 0.035


func _physics_process(_delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var centro := cam.global_position
	if is_instance_valid(jogador):
		_material.set_shader_parameter("jogador", jogador.global_position)
	_atualizar_fila(centro)
	var comeco := Time.get_ticks_usec()
	while not _fila.is_empty() and (Time.get_ticks_usec() - comeco) < ORCAMENTO_MS * 1000.0:
		var chave: Vector2i = _fila.pop_front()
		if not _pedacos.has(chave):
			_pedacos[chave] = _montar(chave)


## Monta já tudo o que a câmera vê (no começo, para não brotar na frente de quem joga).
func montar_tudo_agora() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null or _material == null:
		return
	_atualizar_fila(cam.global_position)
	while not _fila.is_empty():
		var chave: Vector2i = _fila.pop_front()
		if not _pedacos.has(chave):
			_pedacos[chave] = _montar(chave)


func pronta() -> bool:
	return _fila.is_empty()


func _atualizar_fila(centro: Vector3) -> void:
	var c := Vector2(centro.x, centro.z)
	var raio := ceili(CRIA_ATE / PEDACO) + 1
	var meio := Vector2i(floori(centro.x / PEDACO), floori(centro.z / PEDACO))
	for dz in range(-raio, raio + 1):
		for dx in range(-raio, raio + 1):
			var chave := meio + Vector2i(dx, dz)
			if _pedacos.has(chave) or chave in _fila:
				continue
			if _distancia(chave, c) < CRIA_ATE:
				_fila.append(chave)
	_fila.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return _distancia(a, c) < _distancia(b, c))
	for chave in _pedacos.keys():
		if _distancia(chave, c) > APAGA_DE:
			_apagar(chave)


## Distância da câmera ao ponto mais perto do pedaço.
func _distancia(chave: Vector2i, c: Vector2) -> float:
	var x0 := chave.x * PEDACO
	var z0 := chave.y * PEDACO
	var perto := Vector2(clampf(c.x, x0, x0 + PEDACO), clampf(c.y, z0, z0 + PEDACO))
	return perto.distance_to(c)


func _apagar(chave: Vector2i) -> void:
	var no: Node3D = _pedacos[chave]
	for mmi in no.get_children():
		plantas[mmi.name] -= (mmi as MultiMeshInstance3D).multimesh.instance_count
	no.queue_free()
	_pedacos.erase(chave)


# --- um pedaço --------------------------------------------------------------------------

func _montar(chave: Vector2i) -> Node3D:
	var no := Node3D.new()
	no.name = "Pedaco_%d_%d" % [chave.x, chave.y]
	add_child(no)
	var g := RandomNumberGenerator.new()
	g.seed = hash(chave)
	var listas := {"tufo": [], "trevos": [], "florzinha": [], "samambaia": []}
	var x0 := chave.x * PEDACO
	var z0 := chave.y * PEDACO
	var espaco := get_world_3d().direct_space_state
	# Uma grade de 0,45 m sorteada: cada ponto pode ganhar um tufo e, mais raro, outra planta.
	var passo := 0.45
	var n := int(PEDACO / passo)
	for j in n:
		for i in n:
			var x := x0 + (i + g.randf()) * passo
			var z := z0 + (j + g.randf()) * passo
			var chao := _chao(x, z)
			if chao.is_empty():
				continue
			var mata: bool = chao.mata
			var cheio := 0.5 + 0.5 * _ruido.get_noise_2d(x, z)
			var prado := 0.5 + 0.5 * _ruido2.get_noise_2d(x + 300.0, z)
			var sorteio := g.randf()
			var tipo := ""
			if mata:
				# Na sombra da mata a grama é mais rala (aparecem as folhas secas do chão) e tem mais samambaia.
				if sorteio < 0.065:
					tipo = "samambaia"
				elif sorteio < 0.11 + 0.06 * cheio:
					tipo = "trevos"
				elif sorteio < 0.32 + 0.3 * cheio:
					tipo = "tufo"
			else:
				if sorteio < 0.16 * smoothstep(0.4, 0.7, prado):
					tipo = "florzinha"
				elif sorteio < 0.2 + 0.05 * (1.0 - cheio):
					tipo = "trevos"
				elif sorteio < 0.8 + 0.2 * cheio:
					tipo = "tufo"
			if tipo == "" or not _livre(espaco, Vector3(x, chao.y, z)):
				continue
			var altura := 1.0
			var largura := g.randf_range(0.85, 1.2)
			match tipo:
				"tufo":
					altura = g.randf_range(0.75, 1.1) * (0.7 + 0.6 * cheio) * (1.25 if mata else 1.0)
					largura = g.randf_range(0.9, 1.3)
				"trevos":
					altura = g.randf_range(0.8, 1.3)
					largura = altura
				"florzinha":
					altura = g.randf_range(0.75, 1.15)
					largura = g.randf_range(1.0, 1.3)
				"samambaia":
					altura = g.randf_range(0.8, 1.35)
					largura = altura
			if _baixinha.any(func(m: Vector3) -> bool: return Vector2(m.x - x, m.z - z).length() < 1.6):
				if tipo != "trevos":
					continue
			var base := Basis(Vector3.UP, g.randf() * TAU).scaled(Vector3(largura, altura, largura))
			var cor: Color = chao.cor
			if tipo == "trevos":
				cor = Color("#6cc35a") if not mata else Color("#57ad4c")
			elif tipo == "samambaia":
				cor = Color("#4a9a4e")
			cor = cor * g.randf_range(0.9, 1.08)
			cor.a = 1.0
			var custom := Color(0, 0, 0, 1.0 if mata else 0.0)
			if tipo == "florzinha":
				var p: Color = CORES_DAS_FLORES[g.randi() % CORES_DAS_FLORES.size()]
				custom = Color(p.r, p.g, p.b, 0.0)
				cor = Color.WHITE
			(listas[tipo] as Array).append([Transform3D(base, Vector3(x, chao.y - 0.02, z)), cor, custom])
	for tipo in listas:
		var lista: Array = listas[tipo]
		if lista.is_empty():
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.use_custom_data = true
		mm.mesh = _malhas[tipo]
		mm.instance_count = lista.size()
		for k in lista.size():
			mm.set_instance_transform(k, lista[k][0])
			mm.set_instance_color(k, lista[k][1])
			mm.set_instance_custom_data(k, lista[k][2])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = tipo
		mmi.multimesh = mm
		mmi.material_override = _material
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.extra_cull_margin = 1.0
		no.add_child(mmi)
		plantas[tipo] += lista.size()
	return no


## O chão do terreno em (x, z): a altura, a cor e se é mata. Vazio se não for campo nem mata, ou se for íngreme.
func _chao(x: float, z: float) -> Dictionary:
	var fi := (x + METADE_X) / CELULA
	var fj := (z + METADE_Z) / CELULA
	var i := floori(fi)
	var j := floori(fj)
	if i < 0 or j < 0 or i >= _colunas or j >= _linhas:
		return {}
	var fx := fi - i
	var fz := fj - j
	var b := (j * _colunas + i) * 6
	# Dois triângulos por célula, na ordem do gerador: [p00, p10, p01] e [p10, p11, p01].
	var t := b if fx + fz <= 1.0 else b + 3
	var cor := _cores[t]
	var e_campo := _parecida(cor, COR_CAMPO)
	var e_mata := _parecida(cor, COR_MATA)
	if not e_campo and not e_mata:
		return {}
	var a := _vertices[t]
	var bb := _vertices[t + 1]
	var c := _vertices[t + 2]
	var normal := (c - a).cross(bb - a).normalized()
	if absf(normal.y) < 0.82:
		return {}
	# A altura no plano do triângulo.
	var y := a.y - (normal.x * (x - a.x) + normal.z * (z - a.z)) / normal.y
	return {"y": y, "cor": cor, "mata": e_mata and not e_campo}


## A cor do terreno é a da paleta com até 4% de variação (o gerador clareia e escurece a grama).
func _parecida(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) < 0.12


## Nada em cima deste ponto (até 2,5 m acima): o primeiro que o raio de cima acha é o próprio terreno.
func _livre(espaco: PhysicsDirectSpaceState3D, p: Vector3) -> bool:
	# Só a camada do mundo: gente e bicho em cima não contam.
	var r := espaco.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3.UP * 2.5, p + Vector3.DOWN * 0.3, 1))
	return not r.is_empty() and r.collider == terreno

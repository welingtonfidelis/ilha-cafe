class_name VegetacaoDaFase
extends Node3D
## A vegetação e as miudezas no chão de cada fase do Faísca (pedido do usuário em 2026-11-11: "trabalha na textura e
## vegetaçao ou outros materias que fazem sentido pra fase"), o mesmo jeito da vegetação da ilha (VegetacaoIlha):
## milhares de peças por MultiMesh, com o vegetacao.gdshader. Cada mundo tem a sua turma (ESTILOS, pela `superficie`):
##   grama    tufos de grama (na cor da grama embaixo), trevos e florzinhas: 1-1 e a arena do Bolotão Fofão
##   pedra    musgo baixinho e pedrinhas: os túneis da 1-2
##   madeira  farelos e granulado: a cozinha da 2-1 e a mesa do Chef Bolotão
##   algodao  granulado colorido e confeitos: as nuvens da 2-2
##   tapete   pecinhas de montar e bolinhas de gude: o quarto da 2-3
##   neve     tufos de geada saindo da neve, montinhos de neve e cristais: o pico da 3-1 e a arena do Pinguinzão
##   metal    porcas e parafusos: a fábrica da 3-2
## Nascem só nas peças de chão que ganharam a textura (TexturaDoChao), nas faces de cima, sorteadas pela área; cada
## ponto é conferido por um raio de cima (nada embaixo de outra peça, nem de caixa). Ficam longe do que se usa no chão
## (botões, molas, postos, alavancas...), das poças e do caminho creme. Em pedaços de PEDACO m que somem de longe.
## Sem tela (os testes), não monta, a não ser com `nos_testes`.

const PEDACO := 16.0
const SOME_DE := 46.0
## Tipos -> [densidade por m² (pela superfície)] em ESTILOS; e cada tipo -> como é (TIPOS).
const ESTILOS := {
	"grama": {"tufo": 2.2, "trevos": 0.22, "florzinha": 0.16},
	"pedra": {"musgo": 0.5, "pedrinha": 0.3},
	"madeira": {"farelo": 0.08, "granulado": 0.06},
	"algodao": {"granulado": 0.35, "confeito": 0.12},
	"tapete": {"pecinha": 0.022, "gude": 0.018},
	"neve": {"geada": 0.38, "montinho": 0.06, "cristal": 0.04},
	"metal": {"porca": 0.04, "parafuso": 0.04},
}
## tipo -> {cores (sRGB; vazio = a cor do chão), altura [mín, máx], largura [mín, máx], mancha (0 campo, 2 nenhuma),
## e o material (rígido, aspereza, metálico, especular)}.
const TIPOS := {
	"tufo": {"cores": [], "alto": [0.55, 0.9], "largo": [0.9, 1.2], "mancha": 0.0},
	"trevos": {"cores": ["#6cc35a"], "alto": [0.8, 1.2], "largo": [0.8, 1.2], "mancha": 0.0},
	"florzinha": {"cores": ["#ffffff", "#ffd23f", "#ff8fc8", "#9fd4ff", "#ffa24c"], "alto": [0.7, 0.95], "largo": [1.0, 1.25], "mancha": 0.0},
	"musgo": {"cores": ["#4f8a3c", "#5c9944"], "alto": [0.25, 0.42], "largo": [1.1, 1.5], "mancha": 2.0},
	"geada": {"cores": ["#e4f3ff", "#f0f9ff"], "alto": [0.45, 0.75], "largo": [0.9, 1.2], "mancha": 2.0, "pe": 0.9, "ponta": 1.05},
	"pedrinha": {"cores": ["#8d8f99", "#a39b8b", "#7a7f8c", "#9a8f80"], "alto": [0.7, 1.6], "largo": [0.7, 1.6], "rigido": true, "aspereza": 0.9},
	"montinho": {"cores": ["#f4faff"], "alto": [0.7, 1.3], "largo": [0.7, 1.4], "rigido": true, "aspereza": 0.8},
	"cristal": {"cores": ["#bfe8ff", "#d6f3ff"], "alto": [0.8, 1.3], "largo": [0.8, 1.3], "rigido": true, "aspereza": 0.12, "especular": 0.8},
	"granulado": {"cores": ["#ff5d8f", "#7bdff2", "#ffd23f", "#b8f2a0", "#c39bff", "#ffffff"], "alto": [1.0, 1.6], "largo": [1.0, 1.6],
			"rigido": true, "aspereza": 0.4, "especular": 0.5},
	"confeito": {"cores": ["#ff4d6d", "#ffb703", "#4cc9f0", "#80ed99", "#9d4edd"], "alto": [0.9, 1.4], "largo": [0.9, 1.4],
			"rigido": true, "aspereza": 0.3, "especular": 0.6},
	"farelo": {"cores": ["#c8904a", "#d9a35f", "#b07a3a"], "alto": [0.8, 1.8], "largo": [0.8, 1.8], "rigido": true, "aspereza": 0.95},
	"pecinha": {"cores": ["#ff3b3b", "#ffd23f", "#3fa7ff", "#4cd964", "#ff8c1a"], "alto": [1.0, 1.35], "largo": [1.0, 1.35],
			"rigido": true, "aspereza": 0.35, "especular": 0.5},
	"gude": {"cores": ["#4fc3f7", "#ff6b6b", "#7bd389", "#ffd166"], "alto": [0.9, 1.3], "largo": [0.9, 1.3], "rigido": true,
			"aspereza": 0.08, "especular": 0.9},
	"porca": {"cores": ["#a7adb8", "#c9a227"], "alto": [1.5, 2.2], "largo": [1.5, 2.2], "rigido": true, "aspereza": 0.35, "metalico": 0.7},
	"parafuso": {"cores": ["#a7adb8", "#b8bec9"], "alto": [1.5, 2.2], "largo": [1.5, 2.2], "rigido": true, "aspereza": 0.35, "metalico": 0.7},
}

static var nos_testes := false

## Quantas peças de cada tipo foram postas, e uma amostra de onde ([tipo, posição], até 80 de cada), para os testes (sem
## tela, o Godot não guarda as posições do MultiMesh).
var plantas := {}
var amostra: Array = []
var _materiais := {}
var _malhas := {}
var _imagens := {}


## Monta tudo nas `pecas` ([MeshInstance3D, desenho]) da `fase`. Devolve quantas peças pôs.
func montar(fase: Fase, pecas: Array) -> int:
	if DisplayServer.get_name() == "headless" and not nos_testes:
		return 0
	var estilo: Dictionary = ESTILOS.get(fase.estilo if fase.estilo != "" else fase.superficie, {})
	if estilo.is_empty() or pecas.is_empty():
		return 0
	var g := RandomNumberGenerator.new()
	g.seed = hash(String(fase.get_script().resource_path) + "/vegetacao")
	var espaco := fase.get_world_3d().direct_space_state
	var longe_de := _o_que_evitar(fase)
	var por_pedaco := {}
	var total := 0
	# Só nas peças do chão do mundo (na 3-1, a neve sim e o lago congelado não).
	var desenho: String = TexturaDoChao.DA_SUPERFICIE.get(fase.superficie, "")
	for par in pecas:
		var mi: MeshInstance3D = par[0]
		if not is_instance_valid(mi) or String(par[1]) != desenho:
			continue
		for tri in _faces_de_cima(mi):
			var area: float = tri[3]
			for tipo in estilo:
				var quantos := area * float(estilo[tipo])
				var n := int(quantos) + (1 if g.randf() < quantos - int(quantos) else 0)
				for k in n:
					var u := g.randf()
					var v := g.randf()
					if u + v > 1.0:
						u = 1.0 - u
						v = 1.0 - v
					var p: Vector3 = tri[0] + (tri[1] - tri[0]) * u + (tri[2] - tri[0]) * v
					if _perto_de_algo(p, longe_de):
						continue
					var r := espaco.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3.UP * 2.0, p + Vector3.DOWN * 0.3, 1))
					if r.is_empty() or absf((r.position as Vector3).y - p.y) > 0.15 or (r.normal as Vector3).y < 0.8:
						continue
					# O lago congelado fica por cima do chão de neve: nada em cima do gelo.
					if (r.collider as Node).has_meta("gelo") or ((r.collider as Node).get_parent() and (r.collider as Node).get_parent().has_meta("gelo")):
						continue
					var spec: Dictionary = TIPOS[tipo]
					var cores: Array = spec.cores
					var cor: Color = Color(cores[g.randi() % cores.size()]) if not cores.is_empty() else _cor_do_chao(mi, tri, u, v)
					var custom := Color(0, 0, 0, float(spec.get("mancha", 2.0)))
					if tipo == "florzinha":
						custom = Color(cor.r, cor.g, cor.b, 0.0)
						cor = Color.WHITE
					else:
						cor = cor * g.randf_range(0.92, 1.06)
						cor.a = 1.0
					var alto := g.randf_range(spec.alto[0], spec.alto[1])
					var largo := g.randf_range(spec.largo[0], spec.largo[1])
					var base := Basis(Vector3.UP, g.randf() * TAU).scaled(Vector3(largo, alto, largo))
					var chave := Vector3i(floori(p.x / PEDACO), floori(p.y / 8.0), floori(p.z / PEDACO))
					if not por_pedaco.has(chave):
						por_pedaco[chave] = {}
					if not por_pedaco[chave].has(tipo):
						por_pedaco[chave][tipo] = []
					(por_pedaco[chave][tipo] as Array).append([Transform3D(base, (r.position as Vector3) + Vector3.DOWN * 0.02), cor, custom])
					total += 1
	for chave in por_pedaco:
		var meio := Vector3((chave.x + 0.5) * PEDACO, chave.y * 8.0, (chave.z + 0.5) * PEDACO)
		var no := Node3D.new()
		no.position = meio
		add_child(no)
		for tipo in por_pedaco[chave]:
			var lista: Array = por_pedaco[chave][tipo]
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.use_colors = true
			mm.use_custom_data = true
			mm.mesh = _malha(tipo)
			mm.instance_count = lista.size()
			for k in lista.size():
				var t: Transform3D = lista[k][0]
				t.origin -= meio
				mm.set_instance_transform(k, t)
				mm.set_instance_color(k, lista[k][1])
				mm.set_instance_custom_data(k, lista[k][2])
			var mmi := MultiMeshInstance3D.new()
			mmi.name = tipo
			mmi.multimesh = mm
			mmi.material_override = _material(tipo)
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mmi.visibility_range_end = SOME_DE + 6.0
			mmi.visibility_range_end_margin = 4.0
			mmi.extra_cull_margin = 1.0
			no.add_child(mmi)
			plantas[tipo] = int(plantas.get(tipo, 0)) + lista.size()
			if nos_testes:
				for k in mini(lista.size(), 6):
					amostra.append([tipo, (lista[k][0] as Transform3D).origin])
	return total


func _process(_delta: float) -> void:
	var j := get_tree().get_first_node_in_group("jogador") as Node3D
	if j == null:
		return
	for tipo in _materiais:
		if not bool(TIPOS[tipo].get("rigido", false)):
			(_materiais[tipo] as ShaderMaterial).set_shader_parameter("jogador", j.global_position)


## As faces de cima (viradas para o céu) da peça, no mundo: [a, b, c, área, índices dos vértices, superfície].
func _faces_de_cima(mi: MeshInstance3D) -> Array:
	var faces := []
	var t := mi.global_transform
	for s in mi.mesh.get_surface_count():
		var arrays := mi.mesh.surface_get_arrays(s)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var n := idx.size() if not idx.is_empty() else verts.size()
		for k in range(0, n - 2, 3):
			var i0 := idx[k] if not idx.is_empty() else k
			var i1 := idx[k + 1] if not idx.is_empty() else k + 1
			var i2 := idx[k + 2] if not idx.is_empty() else k + 2
			var a := t * verts[i0]
			var b := t * verts[i1]
			var c := t * verts[i2]
			var cruz := (b - a).cross(c - a)
			var area := cruz.length() * 0.5
			if area < 0.0001:
				continue
			if absf(cruz.normalized().y) < 0.85:
				continue
			faces.append([a, b, c, area, [i0, i1, i2], s])
	return faces


## A cor da grama embaixo: a textura do pacote no UV do ponto, vezes a cor do material (a arena não tem textura).
func _cor_do_chao(mi: MeshInstance3D, tri: Array, u: float, v: float) -> Color:
	var mat := mi.get_active_material(int(tri[5]))
	var base := Color("#7cc65e")
	var textura: Texture2D = null
	if mat is ShaderMaterial:
		var cb: Variant = (mat as ShaderMaterial).get_shader_parameter("cor_base")
		if cb is Color:
			base = cb
		textura = (mat as ShaderMaterial).get_shader_parameter("textura") as Texture2D
	elif mat is BaseMaterial3D:
		base = (mat as BaseMaterial3D).albedo_color
		textura = (mat as BaseMaterial3D).albedo_texture
	if textura == null:
		return base
	var img: Image = _imagens.get(textura)
	if img == null:
		img = textura.get_image()
		if img == null:
			return base
		if img.is_compressed():
			img.decompress()
		_imagens[textura] = img
	var uvs: PackedVector2Array = mi.mesh.surface_get_arrays(int(tri[5]))[Mesh.ARRAY_TEX_UV]
	var ids: Array = tri[4]
	if uvs.is_empty():
		return base
	var uv: Vector2 = uvs[ids[0]] + (uvs[ids[1]] - uvs[ids[0]]) * u + (uvs[ids[2]] - uvs[ids[0]]) * v
	var px := img.get_pixel(clampi(int(fposmod(uv.x, 1.0) * img.get_width()), 0, img.get_width() - 1),
			clampi(int(fposmod(uv.y, 1.0) * img.get_height()), 0, img.get_height() - 1))
	return px * base


## O que fica sem nada em volta: [ponto, raio] e trechos [a, b, raio]. Botões, molas, postos e o que mais tem script
## ou é área na fase; o caminho de quem anda de um lado para o outro; as poças; o caminho creme.
func _o_que_evitar(fase: Fase) -> Array:
	var o := []
	for filho in fase.get_children():
		if not filho is Node3D or filho is Mato or filho == self:
			continue
		var no := filho as Node3D
		if no is Area3D:
			o.append([no.global_position, 0.7])
		elif no.get_script() != null and not no is Quebravel:
			o.append([no.global_position, 1.3])
		# O caminho de quem anda de um lado para o outro (rolo de massa, bola de neve, dado, carrinho, carona).
		if "de" in no and "ate" in no and no.get("de") is Vector3:
			o.append([no.get("de"), no.get("ate"), 1.8])
		if "caminho" in no and no.get("caminho") is Vector3:
			o.append([no.global_position, no.global_position + (no.get("caminho") as Vector3), 1.8])
		if "caminho" in no and no.get("caminho") is Array:
			var c: Array = no.get("caminho")
			for i in c.size() - 1:
				o.append([c[i], c[i + 1], 1.8])
	for m in fase._moveis:
		var de: Vector3 = fase.to_global(m[1])
		o.append([de, de + fase.global_basis * (m[2] as Vector3), 2.0])
	for p in fase.pocas:
		o.append([p.global_position, p.raio * 1.15 + 0.2])
	for t in fase.trilhas:
		var pontos: Array = t[0]
		for i in pontos.size() - 1:
			o.append([pontos[i], pontos[i + 1], float(t[1]) * 0.5 + 0.1])
	return o


func _perto_de_algo(p: Vector3, o: Array) -> bool:
	for e in o:
		if e.size() == 2:
			var c: Vector3 = e[0]
			if absf(p.y - c.y) < 3.0 and Vector2(p.x - c.x, p.z - c.z).length() < float(e[1]):
				return true
		else:
			var perto := Geometry3D.get_closest_point_to_segment(p, e[0], e[1])
			if absf(p.y - perto.y) < 2.0 and Vector2(p.x - perto.x, p.z - perto.z).length() < float(e[2]):
				return true
	return false


func _malha(tipo: String) -> Mesh:
	if not _malhas.has(tipo):
		var m: Mesh
		match tipo:
			"tufo", "musgo", "geada":
				m = Plantas3D.tufo()
			"trevos":
				m = Plantas3D.trevos()
			"florzinha":
				m = Plantas3D.florzinha()
			"pedrinha":
				m = Miudezas3D.pedrinha()
			"montinho":
				m = Miudezas3D.montinho()
			"cristal":
				m = Miudezas3D.cristal()
			"granulado":
				m = Miudezas3D.granulado()
			"confeito":
				m = Miudezas3D.confeito()
			"farelo":
				m = Miudezas3D.farelo()
			"pecinha":
				m = Miudezas3D.pecinha()
			"gude":
				m = Miudezas3D.gude()
			"porca":
				m = Miudezas3D.porca()
			"parafuso":
				m = Miudezas3D.parafuso()
		_malhas[tipo] = m
	return _malhas[tipo]


func _material(tipo: String) -> ShaderMaterial:
	if _materiais.has(tipo):
		return _materiais[tipo]
	var spec: Dictionary = TIPOS[tipo]
	var m := ShaderMaterial.new()
	m.shader = load("res://scripts/vegetacao/vegetacao.gdshader")
	m.set_shader_parameter("some_de", SOME_DE - 12.0)
	m.set_shader_parameter("some_ate", SOME_DE)
	if spec.has("pe"):
		m.set_shader_parameter("pe_escuro", float(spec.pe))
		m.set_shader_parameter("ponta_clara", float(spec.ponta))
	if bool(spec.get("rigido", false)):
		m.set_shader_parameter("rigido", true)
		m.set_shader_parameter("ponta_clara", 1.0)
		m.set_shader_parameter("pe_escuro", 1.0)
		m.set_shader_parameter("aspereza", float(spec.get("aspereza", 0.8)))
		m.set_shader_parameter("metalico", float(spec.get("metalico", 0.0)))
		m.set_shader_parameter("especular", float(spec.get("especular", 0.3)))
	_materiais[tipo] = m
	return m

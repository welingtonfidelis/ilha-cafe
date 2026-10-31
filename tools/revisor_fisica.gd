extends SceneTree
## Revisor de física (2026-10-30): procura o que se vê com tamanho de obstáculo ou de chão e que nenhuma colisão
## cobre, onde o Faísca (ou o aventureiro, na ilha) passaria por dentro, como os pirulitos gigantes da 2-2 antes
## desta revisão. De cada peça (o modelo inteiro de um pacote, ou cada malha feita por código) ele sorteia pontos
## na superfície e pergunta à física se tem algo sólido, nas camadas em que o jogador esbarra, a menos de FOLGA m
## de cada ponto. A parte dos pontos com algo sólido perto é a cobertura:
##   SEM FÍSICA  menos de SEM coberta: o jogador entra nela inteira;
##   EM PARTE    até PARTE coberta, só nas peças altas: o cabo do pirulito é sólido e a bala não, por exemplo.
## Só contam os pontos que o jogador alcança: ficam de fora a faixa de baixo das peças altas (o chão em que elas
## estão sempre "cobre"), as faces viradas para baixo, as que têm algo sólido logo em cima (enterradas embaixo
## do chão) e as que estão abaixo da altura em que o Faísca cai (`limite_queda`).
## Fica fora da conta:
## - o que é de pegar ou de atravessar (dentro de uma Area3D: estrelinhas, molas, lava), os personagens
##   (CharacterBody3D) e o que é luz (material de luz somada, como o brilho do marco, ou transparente sem sombra,
##   como o vapor das panelas);
## - o que é miúdo: menos de 0,9 m de altura ou de 0,4 m de largura (o que é baixo e largo, de 1,5 x 0,8 m para
##   cima, entra, porque pode ser uma plataforma que não segura), e o que passa de 1 km (o mar);
## - moitas, grama e flores (ATRAVESSAVEIS), que o jogador atravessa de propósito;
## - nas fases do Faísca, o que está longe de onde se anda: a mais de PERTO m de toda estrelinha, vaga-lume,
##   posto, coração, Bolota e do começo (o farol ao longe, as nuvens do céu), ou inteiro abaixo de `limite_queda`;
## - enfeite de propósito, com o meta "enfeite" nele ou num pai (`Fase.so_enfeite` põe): a copa das árvores,
##   o teto do farol, bandeirinhas no alto.
## Árvores (o nome começa com "tree") só precisam do tronco sólido: o revisor confere uma coluna no meio delas.
## Uso: godot --headless --path . -s res://tools/revisor_fisica.gd [-- farol 1-1 1-2 2-1 2-2 2-3 ilha]
## Sem nomes, revisa o farol, todas as fases do Faísca e a ilha. Sai com código 1 se achar algo SEM FÍSICA.
## Com `--ver <nome>` (o começo do nome de uma peça), lista também os pontos descobertos de cada peça com esse nome.

const NIVEIS := ["farol", "1-1", "1-2", "2-1", "2-2", "2-3", "3-1", "ilha"]
const ATRAVESSAVEIS := ["bush", "grass", "flower"]
const PERTO := 14.0
const FOLGA := 0.35
const PONTOS := 40
const SEM := 0.35
const PARTE := 0.75

var _sorteio := RandomNumberGenerator.new()
var _ver := ""
## Triângulos e áreas de cada malha (muitas peças usam a mesma).
var _faces := {}


func _init() -> void:
	var pedidos := Array(OS.get_cmdline_user_args())
	var i_ver := pedidos.find("--ver")
	if i_ver >= 0 and i_ver + 1 < pedidos.size():
		_ver = pedidos[i_ver + 1]
		pedidos = pedidos.slice(0, i_ver) + pedidos.slice(i_ver + 2)
	var quais: Array = NIVEIS if pedidos.is_empty() else pedidos
	var sem := 0
	var parte := 0
	for id in quais:
		var achados: Vector2i = await _revisar(id)
		sem += achados.x
		parte += achados.y
	print("RESULTADO: %d sem física, %d em parte" % [sem, parte])
	quit(1 if sem > 0 else 0)


func _revisar(id: String) -> Vector2i:
	var nivel := _criar(id)
	if nivel == null:
		print("FALHA: nível desconhecido '%s' (são %s)" % [id, ", ".join(NIVEIS)])
		return Vector2i(1, 0)
	root.add_child(nivel)
	for i in 3:
		await physics_frame
	var espaco := nivel.get_world_3d().direct_space_state
	var mascara := 1 | Alvo.CAMADA | Fase.CAMADA_LIMITE if nivel is Fase else 1
	var queda := (nivel as Fase).limite_queda if nivel is Fase else -INF
	var referencias := _onde_se_anda(nivel)
	var pecas := {}
	for mi in nivel.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null or not m.is_visible_in_tree() or _fora_da_conta(m, nivel):
			continue
		var dono := _peca_de(m, nivel)
		if not pecas.has(dono):
			pecas[dono] = []
		pecas[dono].append(m)
	var q := PhysicsShapeQueryParameters3D.new()
	var bola := SphereShape3D.new()
	bola.radius = FOLGA
	q.shape = bola
	q.collision_mask = mascara
	var raio := PhysicsRayQueryParameters3D.new()
	raio.collision_mask = mascara
	var achados := []
	var conferidas := 0
	var longe := 0
	for dono in pecas:
		var malhas: Array = pecas[dono]
		var caixa := _caixa(malhas)
		var alta := caixa.size.y >= 0.9 and maxf(caixa.size.x, caixa.size.z) >= 0.4
		var larga := maxf(caixa.size.x, caixa.size.z) >= 1.5 and minf(caixa.size.x, caixa.size.z) >= 0.8
		var nome := _nome(dono, nivel)
		if (not alta and not larga) or maxf(caixa.size.x, caixa.size.z) > 1000.0 or _atravessavel(nome):
			continue
		if caixa.end.y < queda + 0.3 or (not referencias.is_empty() and _distancia(caixa, referencias) > PERTO):
			longe += 1
			continue
		conferidas += 1
		if nome.to_lower().begins_with("tree"):
			if not _tem_tronco(espaco, caixa, mascara):
				achados.append({"nome": nome + " (tronco)", "caixa": caixa, "cobertura": 0.0})
			continue
		var piso := caixa.position.y + FOLGA + 0.05 if caixa.size.y > FOLGA * 3.0 else -INF
		var pontos := 0
		var cobertos := 0
		var descobertos := []
		for amostra in _pontos(malhas, PONTOS):
			var p: Vector3 = amostra[0]
			var n: Vector3 = amostra[1]
			if p.y < piso or p.y < queda:
				continue
			# Um pouco para fora da face: com o centro bem em cima de uma colisão feita da malha, a física não vê o toque.
			q.transform = Transform3D(Basis.IDENTITY, p + n * 0.08)
			if not espaco.intersect_shape(q, 1).is_empty():
				pontos += 1
				cobertos += 1
				continue
			# Sem nada sólido perto: só conta se o jogador chega nessa face.
			if n.y < -0.6:
				continue
			raio.from = p + n * 0.1
			raio.to = raio.from + Vector3.UP * 2.0
			if not espaco.intersect_ray(raio).is_empty():
				continue
			pontos += 1
			descobertos.append(p)
		if pontos == 0:
			continue
		var cobertura := float(cobertos) / pontos
		if cobertura < SEM or (alta and cobertura < PARTE):
			achados.append({"nome": nome, "caixa": caixa, "cobertura": cobertura})
		if _ver != "" and nome.begins_with(_ver):
			print("VER  %s em %s: %d de %d pontos cobertos; descobertos: %s" % [nome, _texto(caixa.get_center()), cobertos, pontos,
					" ".join(descobertos.map(func(d): return _texto(d)))])
	achados.sort_custom(func(a, b): return a.cobertura < b.cobertura)
	var sem := 0
	var parte := 0
	print("== %s: %d peças conferidas, %d longe de onde se anda" % [id, conferidas, longe])
	for a in achados:
		var c: AABB = a.caixa
		var tipo := "SEM FÍSICA" if a.cobertura < SEM else "EM PARTE  "
		if a.cobertura < SEM:
			sem += 1
		else:
			parte += 1
		print("%s  %-36s %3d%% coberta  %5.1f x %5.1f x %5.1f m  em %s" % [tipo, a.nome, roundi(a.cobertura * 100.0),
				c.size.x, c.size.y, c.size.z, _texto(c.get_center())])
	print("   %s: %d sem física, %d em parte" % [id, sem, parte])
	nivel.queue_free()
	await process_frame
	return Vector2i(sem, parte)


func _criar(id: String) -> Node3D:
	match id:
		"farol":
			var hub := HubFarol.new()
			for f in Parte2.FASES:
				hub.portas.append({"id": f.id, "nome": f.nome, "tipo": f.tipo, "andar": f.andar, "lado": f.lado, "pede": f.pede,
					"pede_grandes": int(f.get("pede_grandes", 0)), "falta": 0, "aberta": true, "feita": f.cena != "",
					"imagem": f.imagem, "grande": false, "achados": 0, "total_vaga_lumes": 3})
			hub.portas.append({"id": "saida", "nome": "Ilha Cafuné", "tipo": "saida", "andar": 0, "lado": 180})
			return hub
		"1-1":
			return Fase11.new()
		"1-2":
			return Fase12.new()
		"2-1":
			return Fase21.new()
		"2-2":
			return Fase22.new()
		"2-3":
			return Fase23.new()
		"3-1":
			return Fase31.new()
		"ilha":
			return load("res://scenes/ilha.tscn").instantiate()
	return null


## Os lugares por onde o Faísca passa numa fase. Fora das fases (a ilha), vazio: confere tudo.
func _onde_se_anda(nivel: Node3D) -> PackedVector3Array:
	var lista := PackedVector3Array()
	if not nivel is Fase:
		return lista
	var f := nivel as Fase
	lista.append(f.to_global(f.inicio))
	for grupo in [f.estrelas, f.vaga_lumes, f.postos, f.coracoes, f.alvos]:
		for n in grupo:
			if is_instance_valid(n) and n.is_inside_tree():
				lista.append((n as Node3D).global_position)
	return lista


func _fora_da_conta(m: MeshInstance3D, nivel: Node3D) -> bool:
	var mat := m.material_override
	if mat == null and m.mesh.get_surface_count() > 0:
		mat = m.get_active_material(0)
	if mat is BaseMaterial3D:
		var b := mat as BaseMaterial3D
		# Luz: brilho somado, ou transparente sem sombra (o vapor da panela, os raios das lanternas da ilha).
		if b.blend_mode == BaseMaterial3D.BLEND_MODE_ADD or (b.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED
				and b.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED):
			return true
	var n: Node = m
	while n != nivel and n != null:
		if n.has_meta("enfeite") or n is Area3D or n is CharacterBody3D:
			return true
		n = n.get_parent()
	return false


func _atravessavel(nome: String) -> bool:
	var minusculo := nome.to_lower()
	for a in ATRAVESSAVEIS:
		if minusculo.begins_with(a):
			return true
	return false


## Uma coluna de 0,5 m de raio no meio da árvore, logo acima do chão, esbarra em algo.
func _tem_tronco(espaco: PhysicsDirectSpaceState3D, caixa: AABB, mascara: int) -> bool:
	var q := PhysicsShapeQueryParameters3D.new()
	var cilindro := CylinderShape3D.new()
	cilindro.radius = 0.5
	cilindro.height = minf(1.6, caixa.size.y * 0.4)
	q.shape = cilindro
	var meio := caixa.get_center()
	q.transform = Transform3D(Basis.IDENTITY, Vector3(meio.x, caixa.position.y + 0.5 + cilindro.height * 0.5, meio.z))
	q.collision_mask = mascara
	return not espaco.intersect_shape(q, 1).is_empty()


## A peça de uma malha: o modelo de pacote em que ela está (o nó com o arquivo da cena) ou, nas feitas por
## código, ela mesma.
func _peca_de(m: MeshInstance3D, nivel: Node3D) -> Node:
	var n: Node = m
	while n != nivel and n != null:
		if n.scene_file_path != "":
			return n
		n = n.get_parent()
	return m


func _nome(dono: Node, nivel: Node3D) -> String:
	if dono.scene_file_path != "":
		return dono.scene_file_path.get_file().get_basename()
	var m := dono as MeshInstance3D
	var pai := m.get_parent()
	var de: String = str(pai.name) if pai != nivel else ""
	if pai.get_script():
		de = (pai.get_script() as Script).get_global_name()
	var malha := m.mesh.get_class().replace("Mesh", "")
	return ("%s em %s" % [malha, de]) if de != "" else malha


func _caixa(malhas: Array) -> AABB:
	var caixa := AABB()
	var primeira := true
	for m in malhas:
		var c: AABB = (m as MeshInstance3D).global_transform * (m as MeshInstance3D).get_aabb()
		caixa = c if primeira else caixa.merge(c)
		primeira = false
	return caixa


func _distancia(caixa: AABB, referencias: PackedVector3Array) -> float:
	var menor := INF
	for r in referencias:
		var dentro: Vector3 = r.clamp(caixa.position, caixa.end)
		menor = minf(menor, dentro.distance_to(r))
	return menor


## `n` pontos sorteados na superfície das malhas (mais nas que têm mais área), cada um com a normal da face para
## fora: [ponto, normal], no espaço do mundo.
func _pontos(malhas: Array, n: int) -> Array:
	_sorteio.seed = 7
	var infos := []
	var area_total := 0.0
	for m in malhas:
		var info := _faces_de((m as MeshInstance3D).mesh)
		if info.area <= 0.0:
			continue
		var escala := (m as MeshInstance3D).global_transform.basis.get_scale()
		var area: float = info.area * absf(escala.x * escala.y * escala.z) ** (2.0 / 3.0)
		infos.append([m, info, area])
		area_total += area
	var pontos := []
	for par in infos:
		var m: MeshInstance3D = par[0]
		var info: Dictionary = par[1]
		var faces: PackedVector3Array = info.faces
		var acumulada: PackedFloat32Array = info.acumulada
		var para_normal := m.global_transform.basis.inverse().transposed()
		var k := maxi(4, roundi(n * par[2] / area_total))
		for i in k:
			var t := mini(acumulada.bsearch(_sorteio.randf() * info.area), acumulada.size() - 1)
			var a := _sorteio.randf()
			var b := _sorteio.randf()
			if a + b > 1.0:
				a = 1.0 - a
				b = 1.0 - b
			var v0: Vector3 = faces[t * 3]
			var lado1: Vector3 = faces[t * 3 + 1] - v0
			var lado2: Vector3 = faces[t * 3 + 2] - v0
			# As faces da frente do Godot são horárias: lado2 x lado1 aponta para fora.
			var normal := (para_normal * lado2.cross(lado1)).normalized()
			pontos.append([m.global_transform * (v0 + lado1 * a + lado2 * b), normal])
	return pontos


func _faces_de(malha: Mesh) -> Dictionary:
	if _faces.has(malha):
		return _faces[malha]
	var faces := malha.get_faces()
	var acumulada := PackedFloat32Array()
	acumulada.resize(faces.size() / 3)
	var soma := 0.0
	for t in faces.size() / 3:
		soma += (faces[t * 3 + 1] - faces[t * 3]).cross(faces[t * 3 + 2] - faces[t * 3]).length() * 0.5
		acumulada[t] = soma
	var info := {"faces": faces, "acumulada": acumulada, "area": soma}
	_faces[malha] = info
	return info


func _texto(v: Vector3) -> String:
	return "(%d, %d, %d)" % [roundi(v.x), roundi(v.y), roundi(v.z)]

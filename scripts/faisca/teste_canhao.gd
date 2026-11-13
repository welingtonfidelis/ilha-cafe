class_name TesteCanhao
extends RefCounted
## O canhão jogando de verdade (relato do usuário em 2026-11-13: "tivemos um bug ontem que chegando perto do canhão o
## Faísca não era atirado pra próxima plataforma"). Os testes das fases põem o Faísca direto em cima do canhão e dentro
## das argolas; aqui ele chega como uma criança: andando, pulando em cima e, na 1-1, atravessando as quatro argolas
## pulando de verdade. Chamado pelo FaiscaSolo:
##   --faisca-canhao       1-1 (o canhão das Argolas, com rolha)
##   --faisca-canhao-2-2   2-2
##   --faisca-canhao-3-1   3-1 (o canhão de bolas de neve)

var m: Node
var n: Fase
var j: Jogador


func _init(main: Node) -> void:
	m = main
	n = main.nivel
	j = main.jogador
	main.testando = true


func rodar() -> void:
	var ok := true
	await m._comecar_fase()
	await m._esperar(0.5)
	var c: Canhao = n.canhoes[0]
	var chegada := _chao_perto_do_canhao(c)
	ok = m._conferir("tem chão para chegar andando no canhão", chegada != Vector3.INF, "(%s)" % chegada) and ok
	if chegada == Vector3.INF:
		m._terminar(false)
		return
	if c.travado:
		# Com rolha: chegar andando não dispara (de propósito), e as luzinhas estão apagadas.
		var disparou := await _andar_ate(c, chegada, 3.0)
		ok = m._conferir("com rolha, chegando andando ele não é atirado (é a tarefa das argolas)", not disparou and c.luzes_acesas == 0,
				"(%d luzes)" % c.luzes_acesas) and ok
		# As quatro argolas, pulando de verdade pelos vãos entre as nuvens.
		for i in n.argolas.size():
			var a := n.argolas[i]
			var pousou := await _pular_pela_argola(a)
			ok = m._conferir("pulando pelo vão %d, a argola %s acende e ele pousa na nuvem" % [i + 1, a.cor], a.esta_acesa and pousou,
					"(acesa %s, pousou %s, em %s)" % [a.esta_acesa, pousou, j.global_position.snapped(Vector3.ONE * 0.1)]) and ok
		ok = m._conferir("com as quatro argolas, a rolha salta", not c.travado and c.luzes_acesas == 4, "(%d luzes)" % c.luzes_acesas) and ok
	if n is Fase31:
		# A 3-1: o monte de neve cobre o canhão até os três pinguins saírem do gelo (de propósito); o laser nos cubos é
		# conferido no teste da fase, aqui eles derretem direto.
		var n31 := n as Fase31
		var disparou := await _andar_ate(c, chegada, 3.0)
		ok = m._conferir("com o monte de neve, chegando andando ele não é atirado (é a tarefa dos pinguins)", not disparou) and ok
		for cubo: CuboDeGelo in n31.cubos_de_gelo:
			cubo.acender()
		var t := 0.0
		while t < 3.0 and not n31.canhao_pronto():
			await m.get_tree().physics_frame
			t += 1.0 / Engine.physics_ticks_per_second
		ok = m._conferir("com os três pinguins soltos, o monte de neve sai de cima do canhão", n31.canhao_pronto()) and ok
	# Chegando andando, ele entra e voa até a próxima plataforma.
	var foi := await _andar_ate(c, chegada, 3.0)
	ok = m._conferir("chegando andando no canhão, ele entra e é atirado", foi) and ok
	if foi:
		ok = await _confere_pouso(c, "andando") and ok
	# Pulando em cima do canhão (vindo de longe, no ar).
	await m._esperar(1.2)
	var foi_pulando := await _pular_ate(c, chegada)
	ok = m._conferir("pulando em cima do canhão, ele entra e é atirado", foi_pulando) and ok
	if foi_pulando:
		ok = await _confere_pouso(c, "pulando") and ok
	# Andando devagarinho (o analógico só um pouco), como criança chegando perto.
	await m._esperar(1.2)
	var foi_devagar := await _andar_ate(c, chegada, 5.0, 0.35)
	ok = m._conferir("andando devagarinho até o canhão, ele entra e é atirado", foi_devagar) and ok
	if foi_devagar:
		ok = await _confere_pouso(c, "devagar") and ok
	print("CANHAO OK" if ok else "CANHAO COM FALHAS")
	m._terminar(ok)


## Um ponto de chão a uns 4 m do canhão, do lado de onde se chega (longe do destino), achado por raio para baixo.
func _chao_perto_do_canhao(c: Canhao) -> Vector3:
	var espaco := j.get_world_3d().direct_space_state
	var para := Vector3(c.destino.x - c.global_position.x, 0, c.destino.z - c.global_position.z).normalized()
	var melhor := Vector3.INF
	var melhor_nota := -INF
	for k in 16:
		var dir := Vector3.FORWARD.rotated(Vector3.UP, TAU * k / 16.0)
		for longe: float in [4.0, 3.5, 5.0]:
			var p := c.global_position + dir * longe
			var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 3.0, p + Vector3.DOWN * 2.0, 1)
			var r := espaco.intersect_ray(q)
			if r.is_empty() or absf((r.position as Vector3).y - c.global_position.y) > 0.6:
				continue
			# Prefere o lado oposto ao destino (de onde a criança vem).
			var nota := -dir.dot(para)
			if nota > melhor_nota:
				melhor_nota = nota
				melhor = r.position as Vector3
			break
	return melhor


## Põe o Faísca em `de` e anda até o meio do canhão por até `segundos` (com o analógico em `forca`). Devolve se ele
## entrou no canhão.
func _andar_ate(c: Canhao, de: Vector3, segundos: float, forca := 1.0) -> bool:
	j.teleportar(de + Vector3.UP * 0.1)
	await m._esperar(0.4)
	var t := 0.0
	while t < segundos and not c.voando:
		var falta := Vector3(c.global_position.x - j.global_position.x, 0, c.global_position.z - j.global_position.z)
		j.yaw = atan2(-falta.x, -falta.z)
		j.forcar_direcao = Vector2(0, -forca) if falta.length() > 0.3 else Vector2.ZERO
		await m.get_tree().physics_frame
		t += 1.0 / Engine.physics_ticks_per_second
	j.forcar_direcao = Vector2.ZERO
	return c.voando


## De `de`, um pouco mais longe, corre e pula na direção do canhão, segurando o pulo. Devolve se ele entrou.
func _pular_ate(c: Canhao, de: Vector3) -> bool:
	var fora := Vector3(de.x - c.global_position.x, 0, de.z - c.global_position.z).normalized()
	j.teleportar(de + fora * 0.5 + Vector3.UP * 0.1)
	await m._esperar(0.4)
	var t := 0.0
	var pulou := false
	while t < 3.0 and not c.voando:
		var falta := Vector3(c.global_position.x - j.global_position.x, 0, c.global_position.z - j.global_position.z)
		j.yaw = atan2(-falta.x, -falta.z)
		j.forcar_direcao = Vector2(0, -1) if falta.length() > 0.3 else Vector2.ZERO
		if not pulou and falta.length() < 3.2:
			pulou = true
			j.forcar_pulo = true
		if pulou and j.velocity.y < 0.0:
			j.forcar_pulo = false
		await m.get_tree().physics_frame
		t += 1.0 / Engine.physics_ticks_per_second
	j.forcar_direcao = Vector2.ZERO
	j.forcar_pulo = false
	return c.voando


## Espera o voo e confere que ele pousou no destino, de pé, com o controle de volta.
func _confere_pouso(c: Canhao, como: String) -> bool:
	var t := 0.0
	while t < Canhao.VOO + 2.0 and c.voando:
		await m.get_tree().physics_frame
		t += 1.0 / Engine.physics_ticks_per_second
	await m._esperar(0.8)
	var longe := j.global_position.distance_to(c.destino)
	return m._conferir("(%s) o voo leva até a próxima plataforma e ele fica de pé lá" % como, not c.voando and j.is_on_floor()
			and j.controle_ligado and longe < 3.0, "(%.1f m do destino)" % longe)


## Da plataforma de antes da argola, corre e pula pelo vão, segurando o pulo (flutuando) e mirando a nuvem depois dela.
## Devolve se pousou na nuvem.
func _pular_pela_argola(a: Argola) -> bool:
	var meio := a.centro()
	# As argolas da 1-1 se atravessam em -Z: a plataforma de antes fica em +Z, a nuvem de depois em -Z.
	var nuvem := _nuvem_depois(meio)
	var de := _beirada_antes(meio)
	j.teleportar(de + Vector3.UP * 0.1)
	await m._esperar(0.4)
	var t := 0.0
	var pulou := false
	var pousou := false
	while t < 4.0:
		var falta := Vector3(nuvem.x - j.global_position.x, 0, nuvem.z - j.global_position.z)
		j.yaw = atan2(-falta.x, -falta.z)
		j.forcar_direcao = Vector2(0, -1) if falta.length() > 0.5 else Vector2.ZERO
		if not pulou and absf(j.global_position.z - meio.z) < 2.6:
			pulou = true
			j.forcar_pulo = true
		await m.get_tree().physics_frame
		t += 1.0 / Engine.physics_ticks_per_second
		if pulou and t > 0.4 and j.is_on_floor():
			pousou = j.global_position.distance_to(nuvem) < 2.2
			break
	j.forcar_direcao = Vector2.ZERO
	j.forcar_pulo = false
	await m._esperar(0.2)
	return pousou


## O chão logo antes da argola (do lado +Z), achado por raio.
func _beirada_antes(meio: Vector3) -> Vector3:
	var espaco := j.get_world_3d().direct_space_state
	for dz: float in [3.4, 3.8, 4.2, 4.6, 5.0, 5.6]:
		var p := Vector3(meio.x, meio.y + 2.0, meio.z + dz)
		var r := espaco.intersect_ray(PhysicsRayQueryParameters3D.create(p, p + Vector3.DOWN * 8.0, 1))
		if not r.is_empty():
			return r.position as Vector3
	return meio + Vector3(0, -2.4, 4.0)


## O meio da nuvem depois da argola (do lado -Z), achado por raio.
func _nuvem_depois(meio: Vector3) -> Vector3:
	var espaco := j.get_world_3d().direct_space_state
	for dz: float in [3.0, 3.5, 4.0, 2.5, 4.5]:
		var p := Vector3(meio.x, meio.y + 2.0, meio.z - dz)
		var r := espaco.intersect_ray(PhysicsRayQueryParameters3D.create(p, p + Vector3.DOWN * 8.0, 1))
		if not r.is_empty():
			return r.position as Vector3
	return meio + Vector3(0, -2.4, -3.0)

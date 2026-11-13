class_name TesteAviao
extends RefCounted
## O avião de papel da 2-3 na primeira vez (relato do usuário em 2026-11-13: "quando entra no avião a primeira vez o
## Faísca é jogado pra longe"). O teste da fase põe o Faísca no avião por teleporte, segundos depois de ele aparecer;
## aqui ele chega como uma criança, andando e pulando da beira da mesa logo depois de o avião aparecer, e mede a
## rapidez dele a cada quadro. Chamado pelo FaiscaSolo: --faisca-aviao (na 2-3).

var m: Node
var n: Fase23
var j: Jogador


func _init(main: Node) -> void:
	m = main
	n = main.nivel as Fase23
	j = main.jogador
	main.testando = true


func rodar() -> void:
	var ok := true
	await m._comecar_fase()
	await m._esperar(0.5)
	var av := n.aviao
	# Cada caso numa fase nova (é a primeira vez de verdade): --caso=0..3; sem ele, o primeiro.
	var casos := [[2.0, "andando"], [0.6, "andando"], [2.0, "pulando"], [0.6, "pulando"], [0.1, "andando"], [0.25, "pulando"],
			[1.0, "dados"], [1.0, "mexido"]]
	var k := 0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--caso="):
			k = int(a.substr(7))
	var espera: float = casos[k][0]
	var como: String = casos[k][1]
	var r: Dictionary
	if como == "mexido":
		# O avião mexido por fora do caminho dele (um teleporte) e o Faísca subindo depois: antes ele guardava a
		# velocidade do teleporte e jogava o Faísca a mais de 20 m/s.
		n._chamar_aviao()
		await m._esperar(0.8)
		av.global_position = av.de + Vector3(10, 0, 10)
		await m.get_tree().physics_frame
		av.global_position = av.de
		await m._esperar(espera)
		r = await _entrar(av, false)
	elif como == "dados":
		# Como no jogo: os três dados socados até as casas (o avião aparece quando o último trava, no meio da física dele).
		var t23 := TesteFase23.new(m)
		var dirs := [Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(0, 0, -1)]
		var vezes := [4, 4, 2]
		for i in 3:
			await t23._socar_dado(n.dados_do_tabuleiro[i], dirs[i], vezes[i])
		m._conferir("(os três dados chamaram o avião)", n.aviao_chegou)
		await m._esperar(espera)
		r = await _entrar(av, false)
	else:
		n._chamar_aviao()
		await m._esperar(espera)
		r = await _entrar(av, como == "pulando")
	ok = m._conferir("%s no avião %.1f s depois de ele aparecer: não é jogado longe e sai com ele" % [como, espera],
			r.max_rapidez < 8.0 and r.saiu and r.ficou, "(rapidez máxima de lado %.1f m/s, saiu %s, ficou em cima %s)" % [r.max_rapidez, r.saiu, r.ficou]) and ok
	print("AVIAO OK" if ok else "AVIAO COM FALHAS")
	m._terminar(ok)


## Da beira da mesa (atrás do avião, do lado do arco), anda (ou corre e pula) para cima dele. Devolve a maior rapidez
## do Faísca, se o avião saiu com ele e se ele ficou em cima até o avião sair.
func _entrar(av: Carona, pulando: bool) -> Dictionary:
	var de := av.de + Vector3(0, 0.1, 5.5)
	j.teleportar(de)
	await m._esperar(0.4)
	var max_rapidez := 0.0
	var t := 0.0
	var pulou := false
	var saiu := false
	while t < 4.0:
		var falta := Vector3(av.global_position.x - j.global_position.x, 0, av.global_position.z - j.global_position.z)
		j.yaw = atan2(-falta.x, -falta.z)
		j.forcar_direcao = Vector2(0, -1) if falta.length() > 0.4 and av.estado == "em_de" else Vector2.ZERO
		if pulando and not pulou and falta.length() < 3.5:
			pulou = true
			j.forcar_pulo = true
		if pulou and j.velocity.y < 0.0:
			j.forcar_pulo = false
		await m.get_tree().physics_frame
		t += 1.0 / Engine.physics_ticks_per_second
		max_rapidez = maxf(max_rapidez, Vector2(j.velocity.x, j.velocity.z).length())
		if av.estado == "indo":
			saiu = true
			break
	j.forcar_direcao = Vector2.ZERO
	j.forcar_pulo = false
	# Logo depois de sair, ele continua em cima.
	for k in 30:
		await m.get_tree().physics_frame
		max_rapidez = maxf(max_rapidez, Vector2(j.velocity.x - av.constant_linear_velocity.x, j.velocity.z - av.constant_linear_velocity.z).length())
	var ficou := Vector2(j.global_position.x - av.global_position.x, j.global_position.z - av.global_position.z).length() < 2.5
	return {"max_rapidez": max_rapidez, "saiu": saiu, "ficou": ficou}


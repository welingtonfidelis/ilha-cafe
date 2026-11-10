class_name TesteFaiscaJogo
extends RefCounted
## Testes do jogo do Faísca separado da ilha (FaiscaJogo, 2026-11-10), chamados por ele:
##   --faisca-jogo           confere: a migração do progresso da Parte 2 antiga, a abertura na primeira vez, o hub
##                           (portas dos andares, sem a saída para a ilha), a escada em espiral andando de verdade,
##                           porta trancada, a 1-1 com a pausa nova (Sair da fase, Menu principal), estrelinhas que
##                           contam uma vez, a Estrela Grande, o save próprio (FaiscaSave) e a 1-2 abrindo com 30
##   --faisca-jogo-captura   fotos da abertura, do hub, da pausa e da 1-1 em tools/capturas/faisca/jogo/
## Veio da parte do farol e das fases do antigo teste --parte2 do main.gd.

var j: FaiscaJogo
var f: Jogador


func _init(jogo: FaiscaJogo) -> void:
	j = jogo
	f = jogo.faisca


func rodar() -> void:
	var ok := true
	j.rapido = true
	ok = _migracao() and ok
	FaiscaSave.path = "user://teste_faisca_jogo.json"
	FaiscaSave.enabled = true
	FaiscaSave.apagar()

	# Abertura: a nave suga as estrelas, o farol acende e o Faísca sai pulando; termina no térreo do farol.
	var viu_nave := false
	var farol_aceso := false
	var viu_faisca := false
	j.abertura()
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 40000:
		await j.get_tree().physics_frame
		var cena := j.get_node_or_null("Abertura")
		if cena:
			viu_nave = viu_nave or cena.get_node_or_null("Aspiratrao") != null
			for c in cena.get_children():
				if c is FarolIlha and (c as FarolIlha).aberto and (c as FarolIlha).modelo.aceso:
					farol_aceso = true
		viu_faisca = viu_faisca or (j.lugar == "abertura" and f.visible)
		if j.lugar == "hub" and not j.busy():
			break
	ok = _conferir("na primeira vez, a abertura toca: a nave, o farol acendendo e o Faísca saindo pela porta", viu_nave and farol_aceso and viu_faisca,
			"(nave %s, farol %s, Faísca %s)" % [viu_nave, farol_aceso, viu_faisca]) and ok
	await _esperar(0.3)
	var hub := j.hub
	ok = _conferir("a abertura termina no térreo do farol, com o controle, e o save guarda que ela passou", j.lugar == "hub" and is_instance_valid(hub)
			and f.global_position.distance_to(hub.inicio) < 1.5 and f.controle_ligado and j.get_node_or_null("Abertura") == null
			and FaiscaSave.ler().get("abertura", false)) and ok

	# As portas: no térreo a 1-1 aberta e os Túneis do Morro trancados; nos andares de cima, todas trancadas.
	var portas := hub.portas
	var terreo := portas.filter(func(d: Dictionary) -> bool: return int(d.andar) == 0)
	ok = _conferir("no térreo: a 1-1 aberta e os Túneis do Morro trancados (pedem 30), sem a porta de volta para a ilha", terreo.size() == 2
			and terreo[0].aberta and not terreo[1].aberta and int(terreo[1].pede) == 30
			and not portas.any(func(d: Dictionary) -> bool: return d.tipo == "saida")) and ok
	var de_cima := portas.filter(func(d: Dictionary) -> bool: return int(d.andar) > 0)
	ok = _conferir("nos andares de cima: 7 portas trancadas e a da nave no topo, pedindo as 8 Estrelas Grandes", de_cima.size() == 7
			and de_cima.all(func(d: Dictionary) -> bool: return not d.aberta) and int(hub.portas_nos["nave"].dados.pede_grandes) == 8) and ok
	var da_escada: Area3D = hub.estrelas[0]
	await _faisca_em(da_escada.global_position - Vector3(0, 1.0, 0))
	ok = _conferir("a estrelinha da escada do farol conta", j.total_estrelas() == 1 and j.hud._contador.text == "1", "(%d)" % j.total_estrelas()) and ok
	var trancada: Node3D = hub.portas_nos["1-2"]
	trancada._espera = 0.0
	await _faisca_em(trancada.global_position + trancada.global_basis.z * 0.9 + Vector3.UP * 0.1, 0.4)
	ok = _conferir("a porta trancada não abre e mostra quantas faltam", j.lugar == "hub" and trancada._aviso.text == "Faltam 29",
			"(%s)" % trancada._aviso.text) and ok

	# A escada em espiral, andando de verdade, do térreo ao 2º andar.
	var meio := (HubFarol.ESCADA_DENTRO + HubFarol.SACADA) * 0.5
	await _faisca_em(HubFarol.ponto(HubFarol.ESCADA_COMECO - 8.0, meio, 0.1), 0.3)
	var subiu := await _subir_escada(0, 8.0)
	await _esperar(0.2)
	ok = _conferir("a escada sobe do térreo até o patamar do 2º andar, pegando as estrelinhas do caminho", subiu and f.is_on_floor()
			and absf(f.global_position.y - HubFarol.ANDARES[1]) < 0.3 and j.total_estrelas() == 4,
			"(altura %.1f, %d estrelinhas)" % [f.global_position.y, j.total_estrelas()]) and ok
	var do_farol := j.total_estrelas()

	# A pausa no farol: sem "Sair da fase", com o Menu principal.
	j.abrir_pausa()
	await _esperar_real(0.2)
	ok = _conferir("a pausa no farol para o jogo e mostra Continuar, Ajustes, Menu principal e Sair, sem Sair da fase", j.menu_aberto
			and j.get_tree().paused and not j.botoes_pausa.sair_fase.visible and j.botoes_pausa.ajustes.visible and j.botoes_pausa.menu.visible
			and j.botoes_pausa.sair.visible
			and j.get_viewport().gui_get_focus_owner() == j.botoes_pausa.continuar) and ok
	j.botoes_pausa.ajustes.pressed.emit()
	await _esperar_real(0.3)
	var no_painel: bool = j.painel_ajustes.visible and not j.botoes_pausa.continuar.is_visible_in_tree()
	j.painel_ajustes.fechar()
	await _esperar_real(0.2)
	ok = _conferir("os Ajustes abrem no lugar da pausa e, fechando, a pausa volta", no_painel and not j.painel_ajustes.visible
			and j.botoes_pausa.continuar.is_visible_in_tree() and j.get_tree().paused) and ok
	j.botoes_pausa.continuar.pressed.emit()
	await _esperar_real(0.4)
	ok = _conferir("Continuar fecha a pausa e devolve o controle", not j.menu_aberto and not j.get_tree().paused and f.controle_ligado) and ok

	# A 1-1.
	await _faisca_em(hub.inicio, 0.3)
	var porta11: Node3D = hub.portas_nos["1-1"]
	await _faisca_em(porta11.global_position + porta11.global_basis.z * 0.9 + Vector3.UP * 0.1, 0.1)
	await _ate(func() -> bool: return j.lugar == "fase" and not j.busy(), 8.0)
	var lvl := j.nivel
	ok = _conferir("a porta da 1-1 leva à fase, e o Faísca desce do céu até o começo", lvl is Fase11 and f.is_on_floor()
			and f.global_position.distance_to(lvl.inicio) < 1.5 and f.controle_ligado) and ok
	# Modo Fácil (Ajustes): cair não tira coração, só volta.
	Ajustes.facil = true
	var vida0 := f.vida
	f.cair()
	await _esperar(0.5)
	ok = _conferir("no Modo Fácil, cair não tira coração", f.vida == vida0 and f.global_position.distance_to(f.ponto_retorno) < 2.0,
			"(vida %d)" % f.vida) and ok
	Ajustes.padrao()
	await _esperar(1.2)
	for k in 5:
		await _faisca_em(lvl.estrelas[k].global_position - Vector3(0, 1.0, 0), 0.2)
	# Estrelinhas vizinhas podem vir junto: conta o que a fase contou.
	var pegas := lvl.pegas
	ok = _conferir("estrelinhas da fase contam no total", pegas >= 5 and j.total_estrelas() == do_farol + pegas and j.hud._contador.text == str(pegas),
			"(fase %d, total %d)" % [pegas, j.total_estrelas()]) and ok
	await _faisca_em(lvl.inicio, 0.2)
	j.abrir_pausa()
	await _esperar_real(0.2)
	ok = _conferir("na pausa dentro da fase aparece Sair da fase", j.botoes_pausa.sair_fase.visible and j.menu_aberto) and ok
	j.botoes_pausa.sair_fase.pressed.emit()
	await _ate(func() -> bool: return j.lugar == "hub" and not j.busy(), 6.0)
	await _esperar(0.2)
	hub = j.hub
	porta11 = hub.portas_nos["1-1"]
	ok = _conferir("Sair da fase volta para o farol, na frente da porta, e guarda as estrelinhas", j.lugar == "hub" and not j.get_tree().paused
			and f.global_position.distance_to(porta11.global_position) < 4.5 and j.total_estrelas() == do_farol + pegas
			and (FaiscaSave.ler().get("estrelas", {}).get("1-1", []) as Array).size() == pegas) and ok

	# De novo na 1-1: as já pegas ficam transparentes; a Estrela Grande termina a fase.
	await _faisca_em(porta11.global_position + porta11.global_basis.z * 0.9 + Vector3.UP * 0.1, 0.1)
	await _ate(func() -> bool: return j.lugar == "fase" and not j.busy(), 8.0)
	lvl = j.nivel
	var fantasma: StandardMaterial3D = (lvl.estrelas[0].get_child(1) as MeshInstance3D).material_override
	ok = _conferir("de novo na 1-1: as já pegas ficam transparentes e o contador começa com elas", lvl.pegas == pegas
			and fantasma.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA, "(%d)" % lvl.pegas) and ok
	var nova: Area3D = null
	for e in lvl.estrelas:
		if not lvl.ja_pegas.has(e.get_meta("id")) and e.monitoring and e.global_position.distance_to(lvl.inicio) > 3.0:
			nova = e
			break
	await _faisca_em(nova.global_position - Vector3(0, 1.0, 0), 0.2)
	ok = _conferir("uma estrelinha nova conta", lvl.pegas > pegas and j.total_estrelas() == do_farol + lvl.pegas) and ok
	await _faisca_em(lvl.vaga_lumes[0].global_position - Vector3(0, 1.0, 0), 0.3)
	var bau := lvl.bau
	await _faisca_em(bau.global_position + bau.global_basis.z * 2.6, 0.2)
	for k in 3:
		bau.receber_golpe(1, f.global_position)
		await _esperar(0.35)
	await _ate(func() -> bool: return bau._estrela_pronta, 3.0)
	await _faisca_em(bau.estrela.global_position - Vector3(0, 1.2, 0), 0.2)
	await _ate(func() -> bool: return j.hud.fim_aberto, 6.0)
	ok = _conferir("a Estrela Grande termina a fase, fica guardada e a pausa espera a tela de fim", "1-1" in j.grandes and j.hud.fim_aberto
			and (j.vaga_lumes.get("1-1", []) as Array).size() == 1 and not j.pode_pausar()) and ok
	pegas = lvl.pegas
	j.hud.jogar_de_novo.emit()
	await _ate(func() -> bool: return j.lugar == "hub" and not j.busy(), 6.0)
	await _esperar(0.2)
	hub = j.hub
	porta11 = hub.portas_nos["1-1"]
	ok = _conferir("o A na tela de fim volta para o farol, com a Estrela Grande na porta e a constelação acesa", j.lugar == "hub"
			and not j.hud.fim_aberto and porta11.dados.grande and int(porta11.dados.achados) == 1 and "1-1" in hub.grandes) and ok
	ok = _conferir("com uma Estrela Grande, a porta da nave pede as outras 7", int(hub.portas_nos["nave"].dados.falta) == 7
			and not hub.portas_nos["nave"].dados.aberta) and ok
	var salvo := FaiscaSave.ler()
	ok = _conferir("o save do Faísca guarda as estrelinhas, a Estrela Grande e os vaga-lumes", "1-1" in salvo.get("grandes", [])
			and (salvo.estrelas.get("1-1", []) as Array).size() == pegas and (salvo.estrelas.get("farol", []) as Array).size() == do_farol
			and (salvo.get("vaga_lumes", {}).get("1-1", []) as Array).size() == 1 and salvo.get("abertura", false), str(salvo.get("estrelas", {}))) and ok

	# A 1-2 abre com 30 estrelinhas (completadas aqui com estrelinhas de mentira, tiradas na volta).
	var falsas := []
	for k in 30 - j.total_estrelas():
		falsas.append("t%d" % k)
	j.estrelas["teste"] = falsas
	hub.atualizar_portas(j.total_estrelas())
	await _esperar(0.6)
	var porta12: Node3D = hub.portas_nos["1-2"]
	ok = _conferir("com 30 estrelinhas, a porta dos Túneis do Morro abre, com a foto da fase", porta12.dados.aberta and porta12.dados.feita
			and porta12._quadro_mat.albedo_texture != null) and ok
	await _faisca_em(porta12.global_position + porta12.global_basis.z * 0.9 + Vector3.UP * 0.1, 0.1)
	await _ate(func() -> bool: return j.lugar == "fase" and not j.busy(), 8.0)
	ok = _conferir("a porta leva aos Túneis do Morro, e o Faísca pousa no começo do túnel", j.nivel is Fase12 and f.is_on_floor()
			and f.global_position.distance_to(j.nivel.inicio) < 1.5) and ok
	j.sair_da_fase()
	await _ate(func() -> bool: return j.lugar == "hub" and not j.busy(), 6.0)
	# As de mentira saem do save também (sair da fase salvou com elas).
	j.estrelas.erase("teste")
	j._salvar()

	# Carregar o save: volta com tudo.
	var total := j.total_estrelas()
	j.carregar({})
	j.carregar(FaiscaSave.ler())
	ok = _conferir("carregar o save devolve as estrelinhas, as Estrelas Grandes e a abertura vista", j.total_estrelas() == total
			and "1-1" in j.grandes and j.abertura_vista, "(%d de %d)" % [j.total_estrelas(), total]) and ok
	FaiscaSave.apagar()
	print("FAISCA-JOGO OK" if ok else "FAISCA-JOGO COM FALHAS")
	j.get_tree().quit(0 if ok else 1)


## Quem jogou a Parte 2 dentro da ilha (campanha versão 3) ganha o progresso no save do Faísca, uma vez só.
func _migracao() -> bool:
	var campanha := SaveGame.path
	var ligada := SaveGame.enabled
	SaveGame.path = "user://teste_migrar_campanha.json"
	SaveGame.enabled = true
	FaiscaSave.path = "user://teste_migrar_faisca.json"
	FaiscaSave.enabled = true
	FaiscaSave.apagar()
	SaveGame.write({"etapa": "fim", "parte2": {"aberta": true, "faisca": true, "lugar": "hub", "grandes": ["1-1"],
		"estrelas": {"1-1": ["a", "b"], "farol": ["f"]}, "vaga_lumes": {"1-1": ["v"]}}})
	var trouxe := FaiscaSave.migrar()
	var dados := FaiscaSave.ler()
	var de_novo := FaiscaSave.migrar()
	var ok := _conferir("quem jogou a Parte 2 dentro da ilha ganha o progresso no save do Faísca, uma vez só", trouxe and not de_novo
			and dados.get("abertura", false) and (dados.estrelas.get("1-1", []) as Array).size() == 2 and "1-1" in dados.get("grandes", [])
			and (dados.get("vaga_lumes", {}).get("1-1", []) as Array).size() == 1)
	SaveGame.erase()
	FaiscaSave.apagar()
	SaveGame.path = campanha
	SaveGame.enabled = ligada
	return ok


## Fotos (precisa de janela): a nave sugando as estrelas, o farol aceso com o Faísca, o hub, a pausa e a 1-1.
func capturar() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tools/capturas/faisca/jogo/"))
	j.abertura()
	await _ate(func() -> bool: return j.faixa_titulo_texto() == "O céu ficou apagado!", 20.0)
	await _esperar(0.6)
	await _foto("j01_nave_suga_as_estrelas")
	await _ate(func() -> bool: return j.faixa_titulo_texto() == "O Faísca!", 20.0)
	await _esperar(0.4)
	await _foto("j02_faisca_sai_do_farol")
	await _ate(func() -> bool: return j.lugar == "hub" and not j.busy(), 20.0)
	await _esperar(0.8)
	await _foto("j03_terreo_do_farol")
	j.abrir_pausa()
	await _esperar_real(0.5)
	await _foto("j04_pausa")
	j.botoes_pausa.continuar.pressed.emit()
	await _esperar_real(0.4)
	var porta11: Node3D = j.hub.portas_nos["1-1"]
	await _faisca_em(porta11.global_position + porta11.global_basis.z * 0.9 + Vector3.UP * 0.1, 0.1)
	await _ate(func() -> bool: return j.lugar == "fase" and not j.busy(), 8.0)
	await _esperar(0.8)
	await _foto("j05_comeco_da_1_1")
	j.get_tree().quit()


# --- ajudas ------------------------------------------------------------------------------

func _esperar(segundos: float) -> void:
	for i in int(segundos * Engine.physics_ticks_per_second):
		await j.get_tree().physics_frame


## Espera em tempo de relógio (com a pausa, a física para).
func _esperar_real(segundos: float) -> void:
	await j.get_tree().create_timer(segundos, true).timeout


func _ate(condicao: Callable, segundos: float) -> bool:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < segundos * 1000.0:
		if condicao.call():
			return true
		await j.get_tree().physics_frame
	return condicao.call()


func _faisca_em(pos: Vector3, segundos := 0.3) -> void:
	f.teleportar(pos)
	await _esperar(segundos)


## Sobe a escada em espiral do farol com a direção forçada, virando a câmera para seguir a curva, até o patamar do
## fim do lance `lance` (0 é o que sai do térreo). Devolve se chegou na altura do andar.
func _subir_escada(lance: int, segundos: float) -> bool:
	var meio := (HubFarol.ESCADA_DENTRO + HubFarol.SACADA) * 0.5
	var andar: float = HubFarol.ANDARES[lance + 1]
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < segundos * 1000.0:
		var p := f.global_position
		if p.y > andar - 0.05 and f.is_on_floor():
			break
		var a := atan2(p.x, -p.z)
		var r := Vector2(p.x, p.z).length()
		# A curva da escada (graus crescendo) mais um puxão de volta para o meio dos degraus.
		var dir := Vector3(cos(a), 0, sin(a)) + Vector3(sin(a), 0, -cos(a)) * (meio - r) * 0.4
		f.yaw = atan2(-dir.x, -dir.z)
		f.forcar_direcao = Vector2(0, -1)
		await j.get_tree().physics_frame
	f.forcar_direcao = Vector2.ZERO
	return f.global_position.y > andar - 0.3


func _conferir(rotulo: String, ok: bool, detalhe := "") -> bool:
	print("%s %s %s" % ["OK    " if ok else "FALHOU", rotulo, detalhe])
	return ok


func _foto(nome: String) -> void:
	await RenderingServer.frame_post_draw
	var arquivo := ProjectSettings.globalize_path("res://tools/capturas/faisca/jogo/%s.png" % nome)
	j.get_viewport().get_texture().get_image().save_png(arquivo)
	print("foto: ", arquivo)

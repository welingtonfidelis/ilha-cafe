class_name TesteFaiscaJogo
extends RefCounted
## Testes do jogo do Faísca separado da ilha (FaiscaJogo, 2026-11-10), chamados por ele:
##   --faisca-jogo           confere: a migração do progresso da Parte 2 antiga, a abertura na primeira vez, o hub
##                           (portas dos andares, sem a saída para a ilha), a escada em espiral andando de verdade,
##                           porta trancada, a 1-1 com a pausa nova (Sair da fase, Menu principal), estrelinhas que
##                           contam uma vez, a Estrela Grande, o save próprio (FaiscaSave), a 1-2 abrindo com 30 e
##                           os Faisquinhas no farol: cada um no andar do mundo dele, e os prêmios de 10 (o elevador,
##                           levando o Faísca até o 2º andar, com as cancelas), 20 (o trenzinho) e 30 (o farolete);
##                           as moedas e a Máquina de Brindes (o soco no botão, sem e com moedas, a figurinha na
##                           estante, a roupinha na cabeça, o cabide trocando, o save e "já tem todos")
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
	ok = _conferir("no farol toca o tema do farol (item 7)", j.musica_nome == "farol" and is_instance_valid(j._musica) and j._musica.playing) and ok
	ok = _conferir("a abertura termina no térreo do farol, com o controle, e o save guarda que ela passou", j.lugar == "hub" and is_instance_valid(hub)
			and f.global_position.distance_to(hub.inicio) < 1.5 and f.controle_ligado and j.get_node_or_null("Abertura") == null
			and FaiscaSave.ler().get("abertura", false)) and ok

	# As portas: no térreo a 1-1 aberta e os Túneis do Morro trancados; nos andares de cima, todas trancadas.
	var portas := hub.portas
	var terreo := portas.filter(func(d: Dictionary) -> bool: return int(d.andar) == 0)
	ok = _conferir("no térreo: a 1-1 aberta, os Túneis do Morro trancados (pedem 30) e a do chefe pedindo 2 Estrelas Grandes, sem a porta de volta para a ilha",
			terreo.size() == 3 and terreo[0].aberta and not terreo[1].aberta and int(terreo[1].pede) == 30
			and terreo[2].tipo == "chefe" and not terreo[2].aberta and int(terreo[2].pede_grandes) == 2
			and not portas.any(func(d: Dictionary) -> bool: return d.tipo == "saida")) and ok
	var de_cima := portas.filter(func(d: Dictionary) -> bool: return int(d.andar) > 0)
	ok = _conferir("nos andares de cima: as portas trancadas (com as do Chef Bolotão e do Pinguinzão) e a da nave no topo, pedindo as 8 Estrelas Grandes",
			de_cima.size() == 9 and de_cima.any(func(d: Dictionary) -> bool: return d.id == "chefe-2" and int(d.pede_grandes) == 5)
			and de_cima.any(func(d: Dictionary) -> bool: return d.id == "chefe-3" and int(d.pede_grandes) == 7)
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
	var tocando := j.get_children().filter(func(c: Node) -> bool: return c is AudioStreamPlayer and c.name != "Vinheta")
	ok = _conferir("na 1-1 toca o tema do mundo 1, e o do farol foi embora", j.musica_nome == "mundo_1" and j._musica.playing
			and tocando.size() == 1, "(%s, %s)" % [j.musica_nome, tocando.map(func(c: Node) -> String: return "%s %s" % [c.name, (c as AudioStreamPlayer).stream.resource_path.get_file()])]) and ok
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
	await _faisca_em(lvl.faisquinhas[0].global_position - Vector3(0, 1.0, 0), 0.3)
	await _ate(func() -> bool: return "vinheta_faisquinha" in j.vinhetas_tocadas, 1.5)
	await _esperar(0.4)
	ok = _conferir("o Faisquinha salvo toca o tema curto do resgate, com a música abaixada", "vinheta_faisquinha" in j.vinhetas_tocadas
			and j._musica.volume_db < -10.0, "(%.1f dB)" % j._musica.volume_db) and ok
	var bau := lvl.bau
	await _faisca_em(bau.global_position + bau.global_basis.z * 2.6, 0.2)
	for k in 3:
		bau.receber_golpe(1, f.global_position)
		await _esperar(0.35)
	await _ate(func() -> bool: return bau._estrela_pronta, 3.0)
	await _faisca_em(bau.estrela.global_position - Vector3(0, 1.2, 0), 0.2)
	await _ate(func() -> bool: return j.hud.fim_aberto, 6.0)
	ok = _conferir("a Estrela Grande toca a fanfarra, e a música da fase some", "vinheta_estrela" in j.vinhetas_tocadas
			and j._musica.volume_db < -30.0) and ok
	ok = _conferir("a Estrela Grande termina a fase, fica guardada e a pausa espera a tela de fim", "1-1" in j.grandes and j.hud.fim_aberto
			and (j.faisquinhas.get("1-1", []) as Array).size() == 1 and not j.pode_pausar()) and ok
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
	ok = _conferir("o save do Faísca guarda as estrelinhas, a Estrela Grande e os Faisquinhas", "1-1" in salvo.get("grandes", [])
			and (salvo.estrelas.get("1-1", []) as Array).size() == pegas and (salvo.estrelas.get("farol", []) as Array).size() == do_farol
			and (salvo.get("faisquinhas", {}).get("1-1", []) as Array).size() == 1 and salvo.get("abertura", false), str(salvo.get("estrelas", {}))) and ok

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
	ok = await _moradores_e_premios() and ok
	ok = await _brindes() and ok
	ok = await _chefe() and ok
	FaiscaSave.apagar()
	print("FAISCA-JOGO OK" if ok else "FAISCA-JOGO COM FALHAS")
	j.get_tree().quit(0 if ok else 1)


## Os Faisquinhas no farol (itens 1 e 2 da lista do Faísca, 2026-11-11). Completa com Faisquinhas de mentira em
## outras fases para chegar a 10, 20 e 30.
func _moradores_e_premios() -> bool:
	var ok := true
	var hub := j.hub
	var um := hub.moradores.size()
	ok = _conferir("o Faisquinha salvo na 1-1 mora no térreo do farol", um == j.total_faisquinhas() and um >= 1
			and absf(hub.moradores[0].casa.y) < 0.01, "(%d no farol, %d salvos)" % [um, j.total_faisquinhas()]) and ok
	ok = _conferir("com menos de 10, o elevador fica quebrado e as três placas mostram quantos faltam", not hub.elevador.funcionando
			and hub.get_node_or_null("Placa_elevador") != null and hub.get_node_or_null("Placa_trem") != null
			and hub.get_node_or_null("Placa_farolete") != null
			and (hub.get_node("Placa_elevador/Numero") as Label3D).text == "%d/10" % um) and ok
	j.abrir_pausa()
	await _esperar_real(0.2)
	ok = _conferir("a pausa no farol conta as estrelinhas, os Faisquinhas e as Estrelas Grandes", j.contador_pausa.faisquinhas.text == "%d/42" % um
			and j.contador_pausa.grandes.text == "%d/8" % j.grandes.size() and j.contador_pausa.estrelas.text == str(j.total_estrelas()),
			"(%s, %s, %s)" % [j.contador_pausa.estrelas.text, j.contador_pausa.faisquinhas.text, j.contador_pausa.grandes.text]) and ok
	j.botoes_pausa.continuar.pressed.emit()
	await _esperar_real(0.4)

	# 10: o elevador funciona (a festa só uma vez), e cada um mora no andar do mundo dele.
	j.faisquinhas["2-1"] = ["0", "1", "2", "3", "4", "5"]
	j.faisquinhas["3-1"] = ["0", "1", "2"]
	await _refazer_hub()
	hub = j.hub
	ok = _conferir("com 10 Faisquinhas, o elevador funciona, com festa", hub.elevador.funcionando and hub.premios_novos == ["elevador"]
			and hub.get_node_or_null("Placa_elevador") == null and (hub.get_node("Placa_trem/Numero") as Label3D).text == "10/20") and ok
	var andar_certo := hub.moradores.all(func(m: Faisquinha) -> bool:
		var andar: int = {"1-1": 0, "2-1": 1, "3-1": 2}[m.get_meta("fase")]
		return absf(m.casa.y - HubFarol.ANDARES[andar]) < 0.01)
	var juntos := 99.0
	var perto_de_porta := 99.0
	for a in hub.moradores:
		for b in hub.moradores:
			if a != b and absf(a.casa.y - b.casa.y) < 0.5:
				juntos = minf(juntos, a.casa.distance_to(b.casa))
		for p in hub.portas_nos.values():
			if absf((p as Node3D).global_position.y - a.casa.y) < 0.5:
				perto_de_porta = minf(perto_de_porta, Vector2(p.global_position.x - a.casa.x, p.global_position.z - a.casa.z).length())
	ok = _conferir("10 no farol, cada um no andar do mundo dele, longe das portas e um do outro", hub.moradores.size() == 10 and andar_certo
			and juntos > 1.5 and perto_de_porta > 2.4, "(%.1f m entre dois, %.1f m de uma porta)" % [juntos, perto_de_porta]) and ok
	await _refazer_hub()
	ok = _conferir("a festa do elevador não repete", j.hub.premios_novos.is_empty() and "elevador" in j.premios_vistos) and ok
	hub = j.hub
	# O elevador leva o Faísca do térreo ao 2º andar; lá a cancela abre e no 3º fica fechada.
	var elev := hub.elevador
	await _faisca_em(elev.global_position + Vector3.UP * 0.15, 0.1)
	await _ate(func() -> bool: return elev.andar == 1 and elev.parado, 12.0)
	await _esperar(0.3)
	var abertas := elev.cancelas.filter(func(c: HubFarol.Cancela) -> bool: return c.aberta).map(func(c: HubFarol.Cancela) -> int: return c.andar)
	ok = _conferir("o elevador sobe com o Faísca até o 2º andar, e só a cancela de lá abre", absf(f.global_position.y - HubFarol.ANDARES[1]) < 0.4
			and f.is_on_floor() and abertas == [1, 1], "(Faísca a %.1f m, cancelas abertas %s)" % [f.global_position.y, str(abertas)]) and ok
	# Saindo pela cancela aberta, ele pisa na sacada do 2º andar.
	var lado := elev.global_basis.z
	await _faisca_em(elev.global_position + lado * 2.6 + Vector3.UP * 0.2, 0.4)
	ok = _conferir("pela cancela aberta, o Faísca sai na sacada", f.is_on_floor() and absf(f.global_position.y - HubFarol.ANDARES[1]) < 0.3) and ok

	# 20: o trenzinho roda no térreo.
	j.faisquinhas["2-2"] = ["0", "1", "2", "3", "4", "5"]
	j.faisquinhas["2-3"] = ["0", "1", "2", "3"]
	await _refazer_hub()
	hub = j.hub
	var antes := hub.trem[0].global_position if hub.trem.size() == 3 else Vector3.ZERO
	await _esperar(1.0)
	ok = _conferir("com 20, o trenzinho roda em volta do eixo, com dois Faisquinhas no vagão", hub.trem.size() == 3
			and hub.trem[0].global_position.distance_to(antes) > 0.5 and hub.premios_novos == ["trem"]
			and hub.trem[2].get_node_or_null("Passageiro0") != null and (hub.get_node("Placa_farolete/Numero") as Label3D).text == "20/30") and ok

	# 30: o farolete acende e gira.
	j.faisquinhas["3-2"] = ["0", "1", "2", "3", "4", "5"]
	j.faisquinhas["1-2"] = ["0", "1", "2", "3"]
	await _refazer_hub()
	hub = j.hub
	var giro := hub.farolete.rotation.y if hub.farolete else 0.0
	await _esperar(0.5)
	ok = _conferir("com 30, o farolete acende e gira, sem placa nenhuma", hub.farolete != null and hub.farolete.rotation.y > giro
			and hub.premios_novos == ["farolete"] and not hub.get_children().any(func(n: Node) -> bool: return n.name.begins_with("Placa_"))) and ok

	# Dançando, os do térreo dançam junto.
	await _faisca_em(hub.inicio, 0.6)
	f.dancando = 2.0
	await _esperar(0.3)
	var do_terreo := hub.moradores.filter(func(m: Faisquinha) -> bool: return absf(m.casa.y) < 0.1)
	ok = _conferir("quando o Faísca dança, os Faisquinhas do térreo dançam junto", not do_terreo.is_empty()
			and do_terreo.all(func(m: Faisquinha) -> bool: return m._acao == "danca")) and ok
	f.dancando = 0.0
	for id in ["2-1", "3-1", "2-2", "2-3", "3-2", "1-2"]:
		j.faisquinhas.erase(id)
	j.premios_vistos.clear()
	return ok


## As moedas e a Máquina de Brindes (item 4 da lista do Faísca, 2026-11-11).
func _brindes() -> bool:
	var ok := true
	# Na rodada rápida da 1-1 o Faísca sai antes de juntar todas as do baú: basta ter vindo moeda.
	ok = _conferir("a 1-1 desta rodada deu moedas para a carteira (o baú e o Faisquinha)", j.moedas >= 10, "(%d)" % j.moedas) and ok
	j.moedas = 0
	j.brindes.clear()
	j.vestir("")
	await _refazer_hub()
	var hub := j.hub
	var maq := hub.maquina
	# O soco de verdade no botão, sem moedas: a máquina balança que não.
	var frente := maq.global_position + maq.global_basis.z * 1.6
	await _faisca_em(frente + Vector3.UP * 0.1, 0.3)
	f.yaw = atan2(-(maq.global_position - frente).x, -(maq.global_position - frente).z)
	f.visual.rotation.y = f.yaw + PI
	await _esperar(0.1)
	var pedidos := [0]
	maq.pedido.connect(func() -> void: pedidos[0] += 1)
	f.forcar_golpe = true
	await _esperar(0.1)
	f.forcar_golpe = false
	await _esperar(0.5)
	ok = _conferir("o soco no botão da máquina pede um brinde; sem moedas, ela nega", pedidos[0] == 1 and j.brindes.is_empty()
			and j.faixa_titulo_texto().begins_with("Faltam 25"), "(%d pedidos, faixa %s)" % [pedidos[0], j.faixa_titulo_texto()]) and ok
	# Com 60 moedas: a primeira é uma figurinha, que vai para a estante.
	j.moedas = 60
	maq._imune = 0.0
	maq.receber_golpe(1, f.global_position)
	var primeiro: String = j.brindes[0] if not j.brindes.is_empty() else ""
	await _ate(func() -> bool: return not maq.ocupada, 8.0)
	await _esperar(0.2)
	ok = _conferir("com moedas: paga 25, a cápsula abre e a figurinha nova vai para a estante", j.moedas == 35
			and Brindes.dados(primeiro).get("tipo", "") == "figurinha" and hub.estante.tem_figurinha(primeiro)
			and j.faixa_titulo_texto() == "Figurinha nova!", "(%s, %d moedas)" % [primeiro, j.moedas]) and ok
	# A segunda é uma roupinha: o Faísca já sai vestido, e ela aparece no cabide.
	maq._imune = 0.0
	maq.receber_golpe(1, f.global_position)
	var segundo: String = j.brindes[1] if j.brindes.size() > 1 else ""
	await _ate(func() -> bool: return not maq.ocupada, 8.0)
	await _esperar(0.2)
	ok = _conferir("a segunda é uma roupinha: o Faísca já sai com ela, e ela vai para o cabide", Brindes.dados(segundo).get("tipo", "") == "roupa"
			and j.roupa == segundo and f.robo.chapeu == Brindes.chapeu_de(segundo) and hub.cabide.tem_roupa(segundo)
			and f.robo.get_node_or_null("%Chapeu") == null and f.robo.find_child("Chapeu", true, false) != null, "(%s)" % segundo) and ok
	# O cabide: tira a roupinha e põe de novo.
	hub.cabide._imune = 0.0
	hub.cabide.receber_golpe(1, f.global_position)
	var sem := f.robo.chapeu
	hub.cabide._imune = 0.0
	hub.cabide.receber_golpe(1, f.global_position)
	ok = _conferir("o soco no cabide tira a roupinha e o seguinte põe de novo", sem == "" and j.roupa == segundo
			and f.robo.chapeu == Brindes.chapeu_de(segundo)) and ok
	var salvo := FaiscaSave.ler()
	ok = _conferir("o save guarda as moedas, os brindes e a roupinha", int(salvo.get("moedas", -1)) == 10
			and (salvo.get("brindes", []) as Array).size() == 2 and salvo.get("roupa", "") == segundo) and ok
	# Com todos os brindes, a máquina avisa.
	j.brindes = Brindes.LISTA.map(func(b: Dictionary) -> String: return b.id)
	j.moedas = 100
	await _refazer_hub()
	hub = j.hub
	var todas: bool = Brindes.ids("figurinha").all(func(id: String) -> bool: return j.hub.estante.tem_figurinha(id))
	hub.maquina.receber_golpe(1, f.global_position)
	await _esperar(0.3)
	ok = _conferir("com todos: a estante cheia, o cabide com as 6 roupinhas e a máquina avisa que já tem tudo", todas and j.moedas == 100
			and Brindes.ids("roupa").all(func(id: String) -> bool: return j.hub.cabide.tem_roupa(id))
			and j.faixa_titulo_texto() == "Você já tem todos os brindes!") and ok
	j.brindes.clear()
	j.moedas = 0
	j.vestir("")
	return ok


## O chefe do andar 1 (item 5 da lista do Faísca, 2026-11-11): a porta abre com as 2 Estrelas Grandes do mundo 1, a
## luta mostra os corações dele no HUD, e vencido ele conta em `chefes` (não nas Estrelas Grandes), com o troféu no
## farol e a constelação dele.
func _chefe() -> bool:
	var ok := true
	var antes := j.grandes.duplicate()
	j.grandes = ["1-1", "1-2"]
	await _refazer_hub()
	var porta: Node3D = j.hub.portas_nos["chefe-1"]
	ok = _conferir("com as 2 Estrelas Grandes do mundo 1, a porta do chefe abre", porta.dados.aberta and porta.dados.feita) and ok
	await _faisca_em(porta.global_position + porta.global_basis.z * 0.9 + Vector3.UP * 0.1, 0.1)
	await _ate(func() -> bool: return j.lugar == "fase" and not j.busy(), 8.0)
	var arena := j.nivel as Chefe1
	await _ate(func() -> bool: return arena != null and arena.chefe.fase == 1, 6.0)
	ok = _conferir("na luta toca o tema dos chefes", j.musica_nome == "chefe") and ok
	ok = _conferir("a porta leva ao Ninho das Nuvens, e a luta começa com os 3 corações dele no HUD", arena != null
			and arena.chefe.fase == 1 and j.hud.chefe_restam() == 3 and j.faixa_titulo_texto() == "Bolotão Fofão!") and ok
	if arena:
		f._invencivel = 999.0
		arena.chefe._proxima_fase()
		var dois := j.hud.chefe_restam()
		arena.chefe._proxima_fase()
		arena.chefe._proxima_fase()
		await _ate(func() -> bool: return arena.bau != null, 5.0)
		await _esperar(1.3)
		var bau := arena.bau
		await _faisca_em(bau.global_position + bau.global_basis.z * 2.6, 0.3)
		for k in 3:
			bau.receber_golpe(1, f.global_position)
			await _esperar(0.35)
		await _ate(func() -> bool: return bau._estrela_pronta, 3.0)
		await _faisca_em(bau.estrela.global_position - Vector3(0, 1.2, 0), 0.2)
		await _ate(func() -> bool: return j.hud.fim_aberto, 6.0)
		ok = _conferir("vencido: os corações dele somem um a um, e ele conta como chefe, não como Estrela Grande", dois == 2
				and "chefe-1" in j.chefes and j.grandes.size() == 2 and not "chefe-1" in j.grandes) and ok
		j.hud.jogar_de_novo.emit()
		await _ate(func() -> bool: return j.lugar == "hub" and not j.busy(), 6.0)
		await _esperar(0.2)
		ok = _conferir("no farol: o troféu dourado do lado da porta, a coroa acesa na porta e a nave ainda pedindo 6",
				j.hub.get_node_or_null("Trofeu_chefe-1") != null and j.hub.portas_nos["chefe-1"].dados.grande
				and int(j.hub.portas_nos["nave"].dados.falta) == 6 and "chefe-1" in j.hub.grandes
				and "chefe-1" in FaiscaSave.ler().get("chefes", [])) and ok
	# O do andar 2: com as 5 Estrelas Grandes dos mundos 1 e 2, a porta do Chef abre e leva à Cozinha do Chef.
	j.grandes = ["1-1", "1-2", "2-1", "2-2", "2-3"]
	await _refazer_hub()
	var porta2: Node3D = j.hub.portas_nos["chefe-2"]
	ok = _conferir("com 5 Estrelas Grandes, a porta do Chef Bolotão abre no 2º andar", porta2.dados.aberta and int(porta2.dados.andar) == 1) and ok
	j.entrar_fase("chefe-2")
	await _ate(func() -> bool: return j.lugar == "fase" and not j.busy() and j.nivel is Chefe2 and (j.nivel as Chefe2).chefe.fase == 1, 10.0)
	ok = _conferir("a porta leva à Cozinha do Chef, com os corações dele no HUD", j.nivel is Chefe2 and j.hud.chefe_restam() == 3
			and j.faixa_titulo_texto() == "Chef Bolotão!") and ok
	j.sair_da_fase()
	await _ate(func() -> bool: return j.lugar == "hub" and not j.busy(), 6.0)
	# O do andar 3: com 7 Estrelas Grandes, a porta do Pinguinzão abre no 3º andar.
	j.grandes = ["1-1", "1-2", "2-1", "2-2", "2-3", "3-1", "3-2"]
	await _refazer_hub()
	var porta3: Node3D = j.hub.portas_nos["chefe-3"]
	ok = _conferir("com 7 Estrelas Grandes, a porta do Pinguinzão do Gelo abre no 3º andar", porta3.dados.aberta and int(porta3.dados.andar) == 2) and ok
	j.entrar_fase("chefe-3")
	await _ate(func() -> bool: return j.lugar == "fase" and not j.busy() and j.nivel is Chefe3 and (j.nivel as Chefe3).chefe.fase == 1, 10.0)
	ok = _conferir("a porta leva ao Pico do Pinguinzão, com a Luva de Neve e os corações dele no HUD", j.nivel is Chefe3
			and j.hud.chefe_restam() == 3 and f.luva_de_neve) and ok
	j.sair_da_fase()
	await _ate(func() -> bool: return j.lugar == "hub" and not j.busy(), 6.0)
	ok = _conferir("saindo da luta, o poder fica lá dentro", not f.luva_de_neve and not f.martelinho) and ok
	f._invencivel = 0.0
	j.chefes.clear()
	j.grandes = antes
	return ok


## Sai e entra de novo no farol (como voltando de uma fase).
func _refazer_hub() -> void:
	j.hub.queue_free()
	j.hub = null
	await _esperar(0.1)
	j._montar_hub("")
	await _esperar(0.3)


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
			and (dados.get("faisquinhas", {}).get("1-1", []) as Array).size() == 1)
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


## Fotos do farol com os Faisquinhas (precisa de janela), em tools/capturas/faisca/jogo/: o térreo com 4 morando e as
## placas; depois, com 30 (de mentira), o térreo com o trenzinho, o elevador no 2º andar com a cancela aberta, o 3º
## andar e o farolete aceso visto do topo; e a pausa dentro de uma fase, com o contador.
## Uso: godot --path . -- --faisca-farol-captura
func capturar_farol() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tools/capturas/faisca/jogo/"))
	j.abertura_vista = true
	j.faisquinhas = {"1-1": ["0", "1", "3"], "1-2": ["2"]}
	j.chegando = ["1-1:3"]
	j.comecar_no_farol()
	await _ate(func() -> bool: return j.lugar == "hub" and not j.busy(), 10.0)
	var cam := Camera3D.new()
	cam.fov = 62.0
	j.add_child(cam)
	cam.make_current()
	cam.global_position = Vector3(0, 3.2, 10.5)
	cam.look_at(Vector3(0, 1.0, -2.0))
	await _esperar(1.6)
	await _foto("f01_terreo_com_faisquinhas_e_placas")
	var ids := ["0", "1", "2", "3", "4", "5"]
	j.faisquinhas = {"1-1": ids, "1-2": ids, "2-1": ids, "2-2": ids, "3-1": ids}
	await _refazer_hub()
	var hub := j.hub
	j.hub.festa()
	cam.make_current()
	f.teleportar(hub.inicio)
	cam.global_position = Vector3(-2.5, 5.8, 7.0)
	cam.look_at(Vector3(0.0, 0.4, 0.0))
	await _esperar(1.5)
	await _foto("f02_terreo_com_o_trenzinho")
	await _ate(func() -> bool: return hub.elevador.andar == 1 and hub.elevador.parado, 15.0)
	var e := hub.elevador.global_position
	cam.global_position = HubFarol.ponto(176.0, 9.6, HubFarol.ANDARES[1] + 2.2)
	cam.look_at(e + Vector3.UP * 1.0)
	await _esperar(0.6)
	await _foto("f03_elevador_no_2o_andar")
	cam.global_position = HubFarol.ponto(300.0, 9.6, HubFarol.ANDARES[1] + 2.4)
	cam.look_at(HubFarol.ponto(235.0, 9.6, HubFarol.ANDARES[1] + 0.6))
	await _esperar(0.4)
	await _foto("f04_2o_andar_com_faisquinhas")
	cam.global_position = HubFarol.ponto(250.0, 10.5, HubFarol.ANDARES[3] + 2.5)
	cam.look_at(Vector3(0, HubFarol.ANDARES[3] + 1.6, 0))
	await _esperar(0.6)
	await _foto("f05_farolete_aceso")
	# A pausa dentro da 1-1, com o contador.
	await _refazer_hub()
	f.camera.make_current()
	var porta11: Node3D = j.hub.portas_nos["1-1"]
	await _faisca_em(porta11.global_position + porta11.global_basis.z * 0.9 + Vector3.UP * 0.1, 0.1)
	await _ate(func() -> bool: return j.lugar == "fase" and not j.busy(), 8.0)
	await _esperar(0.5)
	j.abrir_pausa()
	await _esperar_real(0.5)
	await _foto("f06_pausa_com_contador")
	j.get_tree().quit()


## Fotos dos brindes (precisa de janela), em tools/capturas/faisca/jogo/: a Máquina de Brindes com o Faísca na frente,
## a cápsula abrindo, a estante com algumas figurinhas e o cabide, e o Faísca com cada um dos 6 chapéus.
## Uso: godot --path . -- --faisca-brindes-captura
func capturar_brindes() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tools/capturas/faisca/jogo/"))
	j.abertura_vista = true
	j.brindes = ["fig_alien", "fig_pinguim", "fig_porco", "fig_abelha", "fig_fantasma", "roupa_palha", "roupa_urso"]
	j.moedas = 80
	j.comecar_no_farol()
	await _ate(func() -> bool: return j.lugar == "hub" and not j.busy(), 10.0)
	var hub := j.hub
	var cam := Camera3D.new()
	cam.fov = 55.0
	j.add_child(cam)
	cam.make_current()
	var maq := hub.maquina
	var frente := maq.global_position + maq.global_basis.z * 2.2
	f.teleportar(frente + Vector3.UP * 0.1)
	f.yaw = atan2(maq.global_basis.z.x, maq.global_basis.z.z)
	f.visual.rotation.y = f.yaw
	cam.global_position = maq.global_position + maq.global_basis.z * 5.5 + maq.global_basis.x * 2.5 + Vector3.UP * 2.6
	cam.look_at(maq.global_position + Vector3.UP * 1.4)
	await _esperar(1.0)
	await _foto("b01_maquina_de_brindes")
	maq.receber_golpe(1, f.global_position)
	await _ate(func() -> bool: return j.faixa_titulo_texto().ends_with("nova!"), 6.0)
	await _esperar(0.5)
	await _foto("b02_capsula_abriu")
	await _ate(func() -> bool: return not maq.ocupada, 8.0)
	var est := hub.estante
	# Do anel de fora da escada (a escada passa entre o meio e a estante).
	cam.global_position = HubFarol.ponto(296.0, 9.4, 2.0)
	cam.look_at(est.global_position + Vector3.UP * 1.3 + est.global_basis.x * 1.2)
	await _esperar(0.6)
	await _foto("b03_estante_e_cabide")
	# O Faísca de frente, com cada chapéu.
	f.teleportar(Vector3(0, 0.1, 8.5))
	f.yaw = 0.0
	f.visual.rotation.y = 0.0
	f.controle_ligado = false
	await _esperar(0.5)
	for k in Brindes.ids("roupa").size():
		var id: String = Brindes.ids("roupa")[k]
		f.robo.vestir_chapeu(Brindes.chapeu_de(id))
		var cabeca := f.global_position + Vector3.UP * 2.0
		cam.global_position = cabeca + Vector3(1.4, 0.5, 2.6)
		cam.look_at(cabeca + Vector3.UP * 0.1)
		await _esperar(0.3)
		await _foto("b%02d_faisca_%s" % [4 + k, Brindes.chapeu_de(id)])
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

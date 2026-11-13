class_name TesteControleFaisca
extends RefCounted
## Confere o DualSense no Faísca (item 3 da lista dele, 2026-11-11), sem precisar do controle ligado:
## - os bytes: a luz (0x04) e os LEDs (0x10) no byte 1, os LEDs no 43, o RGB no 44 a 46; na ilha, sem luz, nada muda;
## - o ControleFaisca escolhendo: o estalinho do soco, o R2 endurecendo na carga do giro, o Martelinho, o Ioiô, a Bolota
##   agarrada no L2, a cor de cada poder, 1 coração (vermelho piscando e 1 LED), a pausa e a vibração desligada
##   (gatilhos soltos) e a piscada de festa;
## - a tremida de cada chão: andando na 1-1 (grama), na 1-2 (pedra), na 2-2 (algodão) e na 3-2 (metal), em cima da
##   esteira, no gelo da 3-1 e no pouso; e as festas no controle.
## Uso: godot --headless --path . -- --faisca-dualsense

var solo: Node
var j: Jogador
var _ok := true


func _init(s: Node) -> void:
	solo = s
	j = solo.jogador


func _conferir(nome: String, cond: bool, extra := "") -> bool:
	print("%s %s %s" % ["OK    " if cond else "FALHOU", nome, extra])
	_ok = _ok and cond
	return cond


func _esperar(s: float) -> void:
	var t := 0.0
	while t < s:
		await solo.get_tree().physics_frame
		t += solo.get_physics_process_delta_time()


func rodar() -> void:
	_bytes()
	await _escolhas()
	await _chaos()
	print("CONTROLE DO FAISCA OK" if _ok else "CONTROLE DO FAISCA COM FALHAS")
	solo.get_tree().quit()


func _bytes() -> void:
	var r2 := DualSense.efeito_arma(4, 6, 3)
	var l2 := DualSense.efeito_solto()
	var c := DualSense.bloco_comum(r2, l2, Color8(10, 20, 30), 0x15)
	_conferir("bytes: luz e LEDs ligados no byte 1, os LEDs no 43, o RGB no 44 a 46 e os gatilhos no 10 e no 21", c.size() == 47
			and c[0] == 0x0C and c[1] == 0x14 and c[43] == 0x15 and c[44] == 10 and c[45] == 20 and c[46] == 30
			and c.slice(10, 21) == r2 and c.slice(21, 32) == l2)
	var ilha := DualSense.bloco_comum(r2, l2)
	_conferir("na ilha (sem luz), o bloco fica como antes", ilha[1] == 0 and ilha[43] == 0 and ilha[44] == 0 and ilha[0] == 0x0C)
	var bt := DualSense.relatorio(c, true)
	_conferir("pelo Bluetooth, o 0x31 de 78 bytes leva a luz", bt.size() == 78 and bt[0] == 0x31 and bt[1] == 0x02 and bt[2 + 44] == 10)


func _escolhas() -> void:
	var n := TesteFaisquinhas.nova_fase("1-1")
	n.name = "Fase"
	solo.add_child(n)
	j.limite_queda = n.limite_queda
	j.teleportar(n.inicio)
	j.controle_ligado = true
	await _esperar(0.5)
	var ocupado := [false]
	var cf := ControleFaisca.new(j, func() -> bool: return ocupado[0])
	var solto := DualSense.efeito_solto()
	var e := cf.escolher(10.0)
	_conferir("normal: estalinho no R2, L2 solto, a luz azul do Faísca e os 3 LEDs", e[0] == DualSense.efeito_arma(4, 6, 3)
			and e[1] == solto and e[2] == ControleFaisca.AZUL_FAISCA and e[3] == 0x15)
	j._segurando_golpe = 0.7
	var duro: PackedByteArray = cf.escolher(10.0)[0]
	j._segurando_golpe = 0.2
	var menos: PackedByteArray = cf.escolher(10.0)[0]
	j._segurando_golpe = 0.0
	_conferir("segurando o golpe, o R2 vai endurecendo", duro[0] == 0x21 and menos[0] == 0x21 and duro != menos)
	j.martelinho = true
	e = cf.escolher(10.0)
	j.martelinho = false
	_conferir("com o Martelinho de Apito: o estalo forte no R2 e a luz laranja", e[0] == DualSense.efeito_arma(3, 6, 8)
			and e[2] == ControleFaisca.CORES_PODER.martelinho)
	j.balao_de_chiclete = true
	e = cf.escolher(10.0)
	j.balao_de_chiclete = false
	j.ioio = true
	var com_ioio := cf.escolher(10.0)
	j.no_ioio = true
	var puxando := cf.escolher(10.0)
	j.no_ioio = false
	j.ioio = false
	j.luva_de_neve = true
	var luva := cf.escolher(10.0)
	j.luva_de_neve = false
	_conferir("a cor de cada poder: rosa no Balão, verde no Ioiô, branco-azulado na Luva", e[2] == ControleFaisca.CORES_PODER.balao
			and com_ioio[2] == ControleFaisca.CORES_PODER.ioio and luva[2] == ControleFaisca.CORES_PODER.luva)
	_conferir("puxado pelo Ioiô, o R2 treme; com a Luva, o estalo fofo", puxando[0][0] == 0x26 and luva[0] == DualSense.efeito_arma(2, 5, 4))
	j.agarrada = n.alvos[0]
	e = cf.escolher(10.0)
	j.agarrada = null
	_conferir("com uma Bolota agarrada, o L2 pesa", e[1][0] == 0x21)
	j.vida = 1
	# Pisca a cada 0,8 s: aceso nos primeiros 0,4 s.
	var aceso := cf.escolher(9.7)
	var apagado := cf.escolher(10.1)
	j.vida = 2
	var dois := cf.escolher(10.0)
	j.vida = Jogador.VIDA_MAX
	_conferir("com 1 coração: 1 LED e a luz vermelha piscando; com 2, dois LEDs", aceso[3] == 0x04 and aceso[2] == ControleFaisca.VERMELHO
			and apagado[2] == ControleFaisca.VERMELHO_FRACO and dois[3] == 0x0A and dois[2] == ControleFaisca.AZUL_FAISCA)
	ocupado[0] = true
	e = cf.escolher(10.0)
	ocupado[0] = false
	_conferir("na pausa, na cena e na tela de fim, os gatilhos ficam soltos e a luz continua", e[0] == solto and e[1] == solto
			and e[2] == ControleFaisca.AZUL_FAISCA)
	var vibrava := Ajustes.vibracao
	Ajustes.vibracao = false
	e = cf.escolher(10.0)
	Ajustes.vibracao = vibrava
	_conferir("com a vibração desligada nos Ajustes, os gatilhos ficam soltos", e[0] == solto and e[1] == solto)
	cf.piscar(Color8(255, 200, 40), 1.0)
	e = cf.escolher()
	_conferir("a piscada de festa troca a luz por um instante", e[2] != ControleFaisca.AZUL_FAISCA and e[2].r8 > 150 and e[2].b8 < 60)
	# O nó DualSense com o perfil escolhe pelo ControleFaisca (sem controle, não manda nada).
	var ds := DualSense.new()
	ds.perfil = cf.escolher
	_conferir("o DualSense com o perfil do Faísca usa a escolha dele", ds.escolher().size() == 4 and ds.escolher()[3] == 0x15
			and ds.escolher()[0] == DualSense.efeito_arma(4, 6, 3))
	ds.free()
	# As festas no controle.
	for qual in ["estrelinha", "faisquinha", "coracao", "estrela_grande", "premio"]:
		j.festa_no_controle(qual)
	_conferir("as festas no controle: estrelinha, Faisquinha, coração, Estrela Grande e prêmio", j.festas.size() == 5)
	await _andar_e_conferir(n, "1-1", "grama")
	# Em cima da esteira (a do playground 1), o chão é a esteira.
	var est := n.esteiras[0]
	await _pisar_em(est.global_position)
	_conferir("1-1: em cima da esteira, o chão é a esteira", j.superficie_embaixo() == "esteira", "(%s)" % j.superficie_embaixo())
	# O pouso treme mais forte.
	j.teleportar(n.inicio + Vector3.UP * 3.0)
	var antes: int = j.tremidas_por_chao.get("grama", 0)
	await _esperar(1.2)
	_conferir("1-1: o pouso também treme", int(j.tremidas_por_chao.get("grama", 0)) > antes)
	n.queue_free()
	await _esperar(0.1)


func _chaos() -> void:
	for spec in [["1-2", "pedra"], ["2-2", "algodao"], ["3-2", "metal"]]:
		var n := TesteFaisquinhas.nova_fase(spec[0])
		n.name = "Fase"
		solo.add_child(n)
		j.limite_queda = n.limite_queda
		await _andar_e_conferir(n, spec[0], spec[1])
		n.queue_free()
		await _esperar(0.1)
	# O gelo da 3-1: um corpo marcado com "gelo".
	var n31 := TesteFaisquinhas.nova_fase("3-1")
	n31.name = "Fase"
	solo.add_child(n31)
	j.limite_queda = n31.limite_queda
	await _esperar(0.3)
	var gelo: Node3D = null
	for no in n31.find_children("*", "StaticBody3D", true, false):
		if no.has_meta("gelo"):
			gelo = no
			break
	if gelo:
		await _pisar_em(gelo.global_position)
	_conferir("3-1: em cima do gelo, o chão é o gelo", gelo != null and j.superficie_embaixo() == "gelo", "(%s)" % j.superficie_embaixo())
	n31.queue_free()
	await _esperar(0.1)


## Anda para a frente desde o começo da fase e confere que os passos tremeram com o chão dela.
func _andar_e_conferir(n: Fase, id: String, chao: String) -> void:
	j.teleportar(n.inicio)
	j.velocity = Vector3.ZERO
	j.yaw = 0.0
	await _esperar(0.5)
	var antes: int = j.tremidas_por_chao.get(chao, 0)
	j.forcar_direcao = Vector2(0, -1)
	await _esperar(1.0)
	j.forcar_direcao = Vector2.ZERO
	await _esperar(0.2)
	_conferir("%s: andando, cada passo treme do jeito do chão (%s)" % [id, chao], int(j.tremidas_por_chao.get(chao, 0)) > antes,
			"(%d passos)" % (int(j.tremidas_por_chao.get(chao, 0)) - antes))


## Põe o Faísca em pé no alto do que estiver em `pos` (o primeiro chão de cima para baixo).
func _pisar_em(pos: Vector3) -> void:
	var espaco := j.get_world_3d().direct_space_state
	var r := espaco.intersect_ray(PhysicsRayQueryParameters3D.create(pos + Vector3.UP * 6.0, pos + Vector3.DOWN * 6.0, 1))
	j.teleportar((r.position if not r.is_empty() else pos) + Vector3.UP * 0.1)
	j.velocity = Vector3.ZERO
	await _esperar(0.4)

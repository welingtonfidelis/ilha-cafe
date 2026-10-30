class_name TesteMonstro
extends RefCounted
## Teste da turma de monstros do Cute Monsters Pack (pedidos do usuário em 2026-10-30): na 1-1, confere o modelo e as
## animações do Alien (a Bolota de sempre) e a regra de cada tipo, com monstros soltos no chão largo do playground 1.
## Chamado pelo FaiscaSolo:
##   --faisca-monstro           confere tudo
##   --faisca-monstro-captura   fotos da turma e de cada regra em ação em tools/capturas/faisca/monstro/ (precisa de janela)
## Usa as ajudas do FaiscaSolo (_esperar, _botao, _toque, _conferir, _foto).

const ANIMACOES := ["Bite_Front", "Bite_InPlace", "Dance", "Death", "HitRecieve", "Idle", "Jump", "No", "Walk", "Yes"]
## Os tipos da 1-1, na ordem das Bolotas da fase.
const TIPOS_1_1 := ["alien", "alien", "cogumelo", "pinguim", "alien", "abelha", "abelha", "cogumelo", "pinguim", "alien", "pinguim", "cogumelo"]
## Chão livre no playground 1 (entre o morro da beirada e os degraus), para soltar os monstros do teste, e onde o
## Faísca espera longe deles.
const LIVRE := Vector3(5, 0, -21)
const LONGE := Vector3(-9, 0.1, -9)

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
	await m._esperar(0.4)
	var tipos := n.alvos.map(func(a: Alvo) -> String: return (a as BolotaMonstro).tipo if a is BolotaMonstro else "?")
	ok = m._conferir("as 12 Bolotas da 1-1 são monstros: Alien, Cogumelo, Pinguim e duas Abelhas", tipos == TIPOS_1_1, "(%s)" % str(tipos)) and ok
	var b := n.alvos[0] as BolotaMonstro
	var faltando := ANIMACOES.filter(func(a: String) -> bool: return not b.anim.has_animation(a))
	ok = m._conferir("o Alien veio com as 10 animações", faltando.is_empty(), "(faltam %s)" % str(faltando)) and ok
	var caixa := _caixa(b)
	ok = m._conferir("do tamanho da Bolota com a antena: de 1,3 a 1,8 m de altura", caixa.size.y > 1.3 and caixa.size.y < 1.8,
			"(%.2f x %.2f m)" % [caixa.size.x, caixa.size.y]) and ok
	ok = m._conferir("dormindo, respira devagar (Idle lento)", b.dormindo and b.anim.current_animation == "Idle" and b.anim.speed_scale < 0.5) and ok

	# Chegando perto, ela acorda, anda até o Faísca (Walk) e encosta (Bite_InPlace), tirando um coração.
	var vista := {}
	var vida := j.vida
	j.teleportar(b.global_position + Vector3(2.6, 0.1, 0.4))
	for i in int(2.5 * Engine.physics_ticks_per_second):
		await m.get_tree().physics_frame
		vista[b.anim.current_animation] = true
	ok = m._conferir("acorda, anda até o Faísca e encosta", vista.has("Walk") and vista.has("Bite_InPlace") and j.vida < vida,
			"(%s, vida %d)" % [str(vista.keys()), j.vida]) and ok

	# Sem o Faísca por perto (fora do grupo, ela não segue), cada estado puxa a sua animação.
	j.remove_from_group("jogador")
	b.chance_tontura = 0.0
	await m._esperar(1.4)
	b.receber_golpe(1, b.global_position + Vector3(1, 0, 0), 6.0, "soco")
	await m._esperar(0.1)
	ok = m._conferir("levando golpe: HitRecieve", b.anim.current_animation == "HitRecieve") and ok
	await m._esperar(1.0)
	ok = m._conferir("depois do golpe, sai da animação de golpe (para ou volta para casa)", b.anim.current_animation in ["Idle", "Walk"],
			"(%s)" % b.anim.current_animation) and ok
	b.ficar_tonta()
	await m._esperar(0.2)
	ok = m._conferir("tonta: balança a cabeça (No) com as estrelinhas", b.anim.current_animation == "No" and b.tonta > 0.0) and ok

	# Agarrar de verdade, com o Y: pendurada pela antena, ela esperneia (Jump); soltando, voa e estoura em 3 estrelinhas.
	j.add_to_group("jogador")
	j.teleportar(b.global_position + Vector3(1.1, 0.1, 0))
	await m._esperar(0.2)
	j.visual.rotation.y = -PI / 2.0
	await m._esperar(0.1)
	var antes := n.estrelas.size()
	m._botao(JOY_BUTTON_Y, true)
	await m._esperar(0.25)
	ok = m._conferir("agarrada pela antena: esperneia (Jump)", b.agarrada and b.anim.current_animation == "Jump", "(%s)" % b.anim.current_animation) and ok
	m._botao(JOY_BUTTON_Y, false)
	await m._esperar(0.3)
	var voou := b.voando or b.derrotado
	await m._esperar(2.0)
	ok = m._conferir("arremessada, estoura e solta 3 estrelinhas", voou and b.derrotado and n.estrelas.size() == antes + 3,
			"(voou %s, %d estrelinhas novas)" % [voou, n.estrelas.size() - antes]) and ok

	ok = await _espinhos() and ok
	ok = await _garras() and ok
	ok = await _fantasma() and ok
	ok = await _investida() and ok
	ok = await _voa() and ok
	m._terminar(ok)


## Cacto: o pisão de verdade espeta (o Faísca perde coração e é jogado longe, o cacto nem sente); o soco derruba.
func _espinhos() -> bool:
	var ok := true
	await m._esperar(2.0)
	var c := n.bolota(LIVRE, true, "cacto")
	await m._esperar(0.3)
	var vida := j.vida
	j.teleportar(c.global_position + Vector3(0, 2.6, 0))
	await m._esperar(0.8)
	var longe := Vector2(j.global_position.x - c.global_position.x, j.global_position.z - c.global_position.z).length()
	ok = m._conferir("cacto: pisar em cima espeta, o Faísca perde um coração e é jogado para fora dele", c.vida == c.vida_max and j.vida == vida - 1 and longe > 1.3,
			"(vida do cacto %d, do Faísca %d, %.1f m)" % [c.vida, j.vida, longe]) and ok
	ok = m._conferir("cacto: o soco derruba", c.receber_golpe(1, c.global_position + Vector3(1.5, 0, 0), 6.0, "soco") and c.vida == c.vida_max - 1) and ok
	Bolotona.guardar(c)
	return ok


## Caranguejo: soco e giro de frente batem nas garras; pelas costas e o pisão derrubam.
func _garras() -> bool:
	var ok := true
	j.remove_from_group("jogador")
	j.teleportar(LONGE)
	await m._esperar(0.3)
	var c := n.bolota(LIVRE, false, "caranguejo")
	await m._esperar(0.3)
	c.visual.rotation.y = 0.0
	var frente := c.global_position + Vector3(0, 0, 1.5)
	var costas := c.global_position + Vector3(0, 0, -1.5)
	var de_frente := c.receber_golpe(1, frente, 6.0, "soco")
	await m._esperar(0.4)
	var giro := c.receber_golpe(1, frente + Vector3(0.6, 0, 0), 6.0, "giro")
	ok = m._conferir("caranguejo: soco e giro de frente batem nas garras", not de_frente and not giro and c.vida == c.vida_max) and ok
	await m._esperar(0.4)
	var pelas_costas := c.receber_golpe(1, costas, 6.0, "soco")
	await m._esperar(0.4)
	var pisao := c.receber_golpe(1, c.global_position + Vector3.UP * 2.0, 3.0, "pisao")
	ok = m._conferir("caranguejo: soco pelas costas e pisão derrubam", pelas_costas and pisao and c.vida == c.vida_max - 2) and ok
	ok = m._conferir("caranguejo: vira devagar, para dar a volta nele", c.giro_olhar < 2.0) and ok
	Bolotona.guardar(c)
	j.add_to_group("jogador")
	return ok


## Fantasma: soco, giro e pisão atravessam; o laser acerta.
func _fantasma() -> bool:
	var ok := true
	j.remove_from_group("jogador")
	j.teleportar(LONGE)
	await m._esperar(0.3)
	var f := n.bolota(LIVRE, false, "fantasma")
	await m._esperar(0.3)
	var de := f.global_position + Vector3(1.5, 0, 0)
	var soco := f.receber_golpe(1, de, 6.0, "soco")
	await m._esperar(0.4)
	var pisao := f.receber_golpe(2, f.global_position + Vector3.UP * 2.0, 3.0, "pisao")
	ok = m._conferir("fantasma: soco e pisão atravessam", not soco and not pisao and f.vida == f.vida_max) and ok
	await m._esperar(0.4)
	ok = m._conferir("fantasma: o laser acerta", f.receber_golpe(1, f.global_position + Vector3.UP * 3.0, 2.5, "laser") and f.vida == f.vida_max - 1) and ok
	Bolotona.guardar(f)
	j.add_to_group("jogador")
	return ok


## Porco: vendo o Faísca, pula no lugar, dispara em linha reta e fica tonto no fim (o Faísca sai da frente).
func _investida() -> bool:
	var ok := true
	j.teleportar(Vector3(2.8, 0.1, -17))
	var p := n.bolota(Vector3(6.6, 0, -17), false, "porco")
	var carregou := false
	var correu := false
	var tonto := false
	for i in int(4.0 * Engine.physics_ticks_per_second):
		await m.get_tree().physics_frame
		carregou = carregou or p.get("_carga") > 0.0
		if p.get("_correndo") > 0.0 and not correu:
			correu = true
			j.teleportar(Vector3(4.5, 0.1, -23.5))
		tonto = tonto or (correu and p.tonta > 0.0)
	ok = m._conferir("porco: pula no lugar, dispara e fica tonto no fim da corrida", carregou and correu and tonto,
			"(carregou %s, correu %s, tonto %s)" % [carregou, correu, tonto]) and ok
	Bolotona.guardar(p)
	return ok


## Abelha (no jardim): voa alto, longe do soco; perto do Faísca dá um rasante; acertada no rasante, cai tonta no chão.
func _voa() -> bool:
	var ok := true
	var a := n.alvos[5] as BolotaMonstro
	var casa: Vector3 = a.get("_origem")
	ok = m._conferir("abelha: voa alto, uns 2,3 m acima da casa", absf(a.global_position.y - (casa.y + BolotaMonstro.ALTURA_VOO)) < 0.4,
			"(%.1f m acima)" % (a.global_position.y - casa.y)) and ok
	await m._esperar(1.5)
	j.teleportar(casa + Vector3(1.5, 0.1, 0.5))
	var mais_baixa := INF
	var acertou := false
	for i in int(6.0 * Engine.physics_ticks_per_second):
		await m.get_tree().physics_frame
		var acima := a.global_position.y - j.global_position.y
		mais_baixa = minf(mais_baixa, acima)
		if acima < 0.6 and not acertou:
			acertou = a.receber_golpe(1, j.global_position, 6.0, "soco")
			if acertou:
				break
	ok = m._conferir("abelha: dá um rasante até o Faísca, e no rasante o soco pega", mais_baixa < 0.6 and acertou, "(desceu até %.1f m)" % mais_baixa) and ok
	await m._esperar(1.0)
	ok = m._conferir("abelha: acertada, cai tonta no chão", a.tonta > 0.0 and a.global_position.y - casa.y < 0.4,
			"(tonta %.1f, %.1f m acima)" % [a.tonta, a.global_position.y - casa.y]) and ok
	return ok


## Fotos para o usuário ver a turma e as regras no jogo.
func capturar() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(m.PASTA_CAPTURAS + "monstro/"))
	await m._esperar(0.5)
	# A turma toda em duas filas, de frente para a câmera (sem o Faísca no grupo, ninguém segue ninguém).
	j.remove_from_group("jogador")
	Bolotona.guardar(n.alvos[0])
	j.teleportar(Vector3(-9, 0.1, -9))
	var turma := []
	var tipos := BolotaMonstro.TIPOS.keys()
	tipos.erase("arvore")
	# Duas filas desencontradas (a de trás aparece entre as cabeças da da frente), os que voam atrás.
	for i in tipos.size():
		var fila := 0 if i < 5 else 1
		var x := -4.4 + 2.2 * i if fila == 0 else -5.5 + 2.2 * (i - 5)
		turma.append(n.bolota(Vector3(x, 0, -4.0 - 3.6 * fila), false, tipos[i]))
	await m._esperar(1.6)
	await _foto_de(Vector3(0, 6.0, 1.5), Vector3(0, 0.6, -6.5), "monstro/01_a_turma", 60.0)
	for b in turma:
		Bolotona.guardar(b)

	# Cacto: o Faísca cai em cima e é espetado.
	j.add_to_group("jogador")
	var c := n.bolota(LIVRE, true, "cacto")
	await m._esperar(0.3)
	j.teleportar(c.global_position + Vector3(0, 2.6, 0))
	for i in 40:
		await m.get_tree().physics_frame
		if j.vida < Jogador.VIDA_MAX:
			break
	await m._esperar(0.1)
	await _foto_de(c.global_position + Vector3(3.5, 1.8, 3.5), c.global_position + Vector3(0, 1.2, 0), "monstro/02_cacto_espeta")
	Bolotona.guardar(c)

	# Caranguejo: o soco de frente bate nas garras.
	await m._esperar(1.8)
	var cr := n.bolota(LIVRE, false, "caranguejo")
	cr.set("_pausa", 30.0)
	j.teleportar(cr.global_position + Vector3(0, 0.1, 1.6))
	await m._esperar(1.8)
	j.visual.rotation.y = PI
	await m._toque(JOY_BUTTON_X)
	await m._esperar(0.15)
	await _foto_de(cr.global_position + Vector3(3.2, 1.6, 1.6), cr.global_position + Vector3(0, 0.8, 0.8), "monstro/03_caranguejo_defende")
	Bolotona.guardar(cr)

	# Fantasma: o soco atravessa e ele fica transparente.
	await m._esperar(0.5)
	var f := n.bolota(LIVRE, false, "fantasma")
	f.set("_pausa", 30.0)
	j.teleportar(f.global_position + Vector3(0, 0.1, 1.6))
	await m._esperar(1.0)
	j.visual.rotation.y = PI
	await m._toque(JOY_BUTTON_X)
	await m._esperar(0.12)
	await _foto_de(f.global_position + Vector3(3.2, 1.6, 1.6), f.global_position + Vector3(0, 0.8, 0.8), "monstro/04_fantasma_atravessa")
	Bolotona.guardar(f)

	# Porco: pula no lugar e dispara.
	j.teleportar(Vector3(2.8, 0.1, -17))
	var p := n.bolota(Vector3(6.6, 0, -17), false, "porco")
	for i in int(3.0 * Engine.physics_ticks_per_second):
		await m.get_tree().physics_frame
		if p.get("_correndo") > 0.0:
			break
	await m._esperar(0.15)
	await _foto_de(Vector3(4.5, 1.8, -12.0), Vector3(4.2, 0.8, -17), "monstro/05_porco_dispara")
	j.teleportar(Vector3(4.5, 0.1, -23.5))
	await m._esperar(1.2)
	await _foto_de(p.global_position + Vector3(2.0, 1.6, 3.2), p.global_position + Vector3(0, 0.9, 0), "monstro/06_porco_tonto")
	Bolotona.guardar(p)

	# Abelha: o rasante no jardim.
	var a := n.alvos[5] as BolotaMonstro
	var casa: Vector3 = a.get("_origem")
	# De longe (fora do rasante), ela segue o Faísca lá no alto.
	j.teleportar(casa + Vector3(4.5, 0.1, 1.0))
	await m._esperar(1.0)
	await _foto_de(casa + Vector3(-1.0, 2.4, 7.5), casa + Vector3(2.0, 1.6, 0), "monstro/07_abelha_no_alto")
	j.teleportar(casa + Vector3(1.5, 0.1, 0.5))
	for i in int(6.0 * Engine.physics_ticks_per_second):
		await m.get_tree().physics_frame
		if a.global_position.y - j.global_position.y < 0.5:
			break
	await _foto_de(casa + Vector3(-1.5, 2.2, 6.0), casa + Vector3(0.8, 0.9, 0), "monstro/08_abelha_rasante")
	m.get_tree().quit()


## Foto com uma câmera solta em `de` olhando para `para`.
func _foto_de(de: Vector3, para: Vector3, nome: String, fov := 42.0) -> void:
	var cam := Camera3D.new()
	cam.fov = fov
	m.add_child(cam)
	cam.look_at_from_position(de, para, Vector3.UP)
	cam.current = true
	await m._esperar(0.05)
	await m._foto(nome)
	cam.queue_free()
	j.camera.current = true


## Caixa do modelo de pé, na escala do jogo (todas as malhas juntas; a dormindo fica inclinada).
func _caixa(b: BolotaMonstro) -> AABB:
	var caixa := AABB()
	var primeira := true
	for mi: MeshInstance3D in b.visual.find_children("*", "MeshInstance3D", true, false):
		var c := mi.get_aabb()
		c = AABB(c.position * BolotaMonstro.ESCALA, c.size * BolotaMonstro.ESCALA)
		caixa = c if primeira else caixa.merge(c)
		primeira = false
	return caixa

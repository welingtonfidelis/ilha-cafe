class_name TesteMoedas
extends RefCounted
## Confere as moedas nas fases (item 4 da lista do Faísca, 2026-11-11), na 1-1:
## - a Bolota vencida solta 3 moedas, que só dão para pegar depois do pulinho e caem no chão;
## - perto do Faísca elas voam até ele (o ímã) e contam no HUD;
## - o Faisquinha salvo solta 5 e o baú aberto solta 20.
## Uso: godot --headless --path . -- --faisca-moedas

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


func _moedas(n: Fase) -> Array:
	return n.get_children().filter(func(c: Node) -> bool: return c is Moeda and not c.is_queued_for_deletion())


func rodar() -> void:
	var n := TesteFaisquinhas.nova_fase("1-1")
	n.name = "Fase"
	solo.add_child(n)
	n.moeda_pega.connect(func(p: int) -> void: solo.hud.mostrar_moedas(p))
	j.limite_queda = n.limite_queda
	j.teleportar(n.inicio)
	await _esperar(0.4)
	# A Bolota que dorme no começo: vencida longe do Faísca, solta 3 moedas.
	var b: Alvo = n.alvos[0]
	j.teleportar(b.global_position + Vector3(0, 0.1, 9))
	await _esperar(0.3)
	var antes := _moedas(n).size()
	while not b.derrotado:
		b._imune = 0.0
		b.receber_golpe(3, b.global_position + Vector3(0, 0, 1), 0.5)
		await _esperar(0.05)
	await _esperar(0.05)
	var soltas := _moedas(n)
	var recem: bool = soltas.size() == antes + 3 and soltas.all(func(m: Moeda) -> bool: return not m.pegavel)
	await _esperar(0.8)
	var espaco := n.get_world_3d().direct_space_state
	var no_chao := soltas.all(func(m: Moeda) -> bool:
		var r := espaco.intersect_ray(PhysicsRayQueryParameters3D.create(m.global_position, m.global_position + Vector3.DOWN * 1.2, 1))
		return m.pegavel and not r.is_empty())
	_conferir("a Bolota vencida solta 3 moedas, que pulam e caem no chão", recem and no_chao, "(%d novas)" % (soltas.size() - antes))
	_conferir("a 9 m do Faísca elas ficam paradas no chão", n.moedas_pegas == 0)
	j.teleportar(b.global_position + Vector3(0, 0.1, 1.8))
	await _esperar(1.0)
	_conferir("perto, as moedas voam até o Faísca e contam no HUD", n.moedas_pegas == 3 and solo.hud.moedas_texto() == "3",
			"(%d, HUD %s)" % [n.moedas_pegas, solo.hud.moedas_texto()])
	# O Faisquinha salvo solta 5.
	var f := n.faisquinhas[3]
	j.teleportar(f.global_position - Vector3(0, 0.8, 0))
	await _esperar(1.6)
	_conferir("o Faisquinha salvo solta 5 moedas, e o Faísca pega", f.encontrado and n.moedas_pegas == 8, "(%d)" % n.moedas_pegas)
	# O baú aberto solta 20.
	var bau := n.bau
	j.teleportar(bau.global_position + bau.global_basis.z * 2.6)
	await _esperar(0.3)
	for k in 3:
		bau.receber_golpe(1, j.global_position)
		await _esperar(0.35)
	await _esperar(1.2)
	# Dando a volta no baú, ele pega todas (as da frente o ímã já puxou).
	for lado in [Vector3(2.6, 0, 0), Vector3(0, 0, -2.6), Vector3(-2.6, 0, 0), Vector3(0, 0, 2.6)]:
		j.teleportar(bau.global_position + lado + Vector3.UP * 0.1)
		await _esperar(0.6)
	_conferir("o baú aberto solta 20 moedas, e dando a volta nele o Faísca pega todas", n.moedas_pegas == 28 and _moedas(n).is_empty(),
			"(%d pegas)" % n.moedas_pegas)
	print("MOEDAS OK" if _ok else "MOEDAS COM FALHAS")
	solo.get_tree().quit()

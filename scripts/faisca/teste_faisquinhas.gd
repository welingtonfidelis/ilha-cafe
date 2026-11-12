class_name TesteFaisquinhas
extends RefCounted
## Confere os Faisquinhas das sete fases (itens 1 e 2 da lista do Faísca, 2026-11-11). Para cada fase:
## - seis Faisquinhas, nomes "0" a "5" na ordem; o "5" pendurado numa Bolota que anda (não uma que voa);
## - os presos (0 a 4) têm chão firme embaixo, até 3 m, e a bolha não entra em nada sólido; os novos (3 e 4) ficam
##   num bolso com estrelinhas (até 3,2 m de uma). Exceções marcadas na fase: "no_ar" (o 3 da 2-1, no meio da roda
##   que a tampa alcança) e "sem_estrelinhas" (o 4 da 2-1, em cima do vidro de ketchup);
## - perto de um preso, ele chama (o "piu-piu") e o controle treme;
## - encostar salva (conta e some subindo); vencer a Bolota solta o 5 num chão firme, e encostar nele salva.
## Uso: godot --headless --path . -- --faisca-faisquinhas

const FASES := ["1-1", "1-2", "2-1", "2-2", "2-3", "3-1", "3-2", "3-3", "nave"]

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


static func nova_fase(id: String) -> Fase:
	match id:
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
		"3-2":
			return Fase32.new()
		"3-3":
			return Fase33.new()
		"nave":
			return FaseNave.new()
	return null


func rodar() -> void:
	Sfx.logging = true
	for id in FASES:
		await _conferir_fase(id)
	print("FAISQUINHAS OK" if _ok else "FAISQUINHAS COM FALHAS")
	solo.get_tree().quit()


func _conferir_fase(id: String) -> void:
	var n := nova_fase(id)
	n.name = "Fase"
	solo.add_child(n)
	j.limite_queda = n.limite_queda
	j.teleportar(n.inicio)
	await _esperar(0.3)
	var nomes := n.faisquinhas.map(func(f: Faisquinha) -> String: return f.id)
	_conferir("%s: seis Faisquinhas, de 0 a 5" % id, nomes == ["0", "1", "2", "3", "4", "5"], str(nomes))
	var carregado := n.faisquinhas[5]
	var dono := carregado.dono
	_conferir("%s: o 5 vai pendurado numa Bolota que anda" % id, carregado.estado == "carregado" and is_instance_valid(dono)
			and not (dono is BolotaMonstro and (dono as BolotaMonstro).regra == "voa") and not carregado.monitoring,
			"(%s)" % carregado.estado)
	var espaco := n.get_world_3d().direct_space_state
	var bola := SphereShape3D.new()
	bola.radius = 0.5
	for f in n.faisquinhas.slice(0, 5):
		var r := espaco.intersect_ray(PhysicsRayQueryParameters3D.create(f.global_position, f.global_position + Vector3.DOWN * 3.0, 1))
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = bola
		q.transform = Transform3D(Basis(), f.global_position)
		q.collision_mask = 1
		var dentro := espaco.intersect_shape(q, 4)
		var no_ar: bool = f.get_meta("no_ar", false)
		if no_ar:
			r = espaco.intersect_ray(PhysicsRayQueryParameters3D.create(f.global_position, f.global_position + Vector3.DOWN * 5.0, 1))
		_conferir("%s: o Faisquinha %s tem chão embaixo e a bolha livre" % [id, f.id], not r.is_empty() and dentro.is_empty(),
				"(chão %s, encosta em %s)" % ["%.2f m abaixo" % (f.global_position.y - r.position.y) if not r.is_empty() else "nenhum",
				", ".join(dentro.map(func(d: Dictionary) -> String: return (d.collider as Node).name))])
		if int(f.id) >= 3 and not f.get_meta("sem_estrelinhas", false):
			var perto := INF
			for e in n.estrelas:
				perto = minf(perto, e.global_position.distance_to(f.global_position))
			_conferir("%s: o Faisquinha %s fica num bolso com estrelinhas" % [id, f.id], perto < 3.2, "(%.1f m)" % perto)
	# O chamado e a tremidinha, perto do 3 (a 6 m, de lado).
	var f3 := n.faisquinhas[3]
	j.teleportar(f3.global_position + Vector3(6, -0.5, 0))
	j.velocity = Vector3.ZERO
	j.controle_ligado = true
	var chamados := f3.chamados
	var tremidas := j.tremidinhas
	Sfx.played.clear()
	await _esperar(3.4)
	_conferir("%s: perto do 3, ele chama e o controle treme" % id, f3.chamados > chamados and j.tremidinhas > tremidas
			and "faisquinha_chama" in Sfx.played, "(%d chamados, %d tremidas)" % [f3.chamados - chamados, j.tremidinhas - tremidas])
	# Encostar salva os presos.
	for f in n.faisquinhas.slice(0, 5):
		var antes := n.achados
		# Em pé no chão embaixo dele (o que está no ar, a 0,8 m abaixo do meio da bolha, como no pulo).
		var chao := espaco.intersect_ray(PhysicsRayQueryParameters3D.create(f.global_position, f.global_position + Vector3.DOWN * 2.9, 1))
		# Em cima de uma boia ainda seca (o V3 da 2-1, no patinho), primeiro enche a cozinha: no chão seco, pisar é cair.
		if not chao.is_empty() and chao.collider is Boia and not (chao.collider as Boia).boiando():
			(n.get("enchente") as Enchente).encher_ate(2)
			await _esperar(0.3)
			chao = espaco.intersect_ray(PhysicsRayQueryParameters3D.create(f.global_position, f.global_position + Vector3.DOWN * 2.9, 1))
		j.teleportar(chao.position + Vector3.UP * 0.05 if not chao.is_empty() else f.global_position - Vector3(0, 0.8, 0))
		j.velocity = Vector3.ZERO
		await _esperar(0.25)
		_conferir("%s: encostar salva o Faisquinha %s" % [id, f.id], f.encontrado and n.achados == antes + 1 and f.id in n.novos_faisquinhas)
	j.teleportar(n.inicio)
	await _esperar(0.2)
	# A Bolota do 5: vencida, ele cai num chão firme; encostar salva.
	var origem := dono.global_position
	var tentativas := 0
	while not dono.derrotado and tentativas < 20:
		dono._imune = 0.0
		dono.receber_golpe(3, dono.global_position + Vector3(0, 0, 1), 0.5)
		tentativas += 1
		await _esperar(0.05)
	await _esperar(1.0)
	var chao := espaco.intersect_ray(PhysicsRayQueryParameters3D.create(carregado.global_position, carregado.global_position + Vector3.DOWN * 1.2, 1))
	_conferir("%s: vencida a Bolota, o 5 cai no chão e espera" % id, dono.derrotado and carregado.estado == "solto" and carregado.monitoring
			and not chao.is_empty() and carregado.bolha == null and carregado.global_position.distance_to(origem) < 12.0,
			"(%s, %.1f m de onde a Bolota estava)" % [carregado.estado, carregado.global_position.distance_to(origem)])
	j.teleportar(carregado.global_position - Vector3(0, 0.4, 0))
	await _esperar(0.25)
	_conferir("%s: encostar salva o 5, e os seis contam" % id, carregado.encontrado and n.achados == 6)
	n.queue_free()
	await _esperar(0.1)


## Fotos de perto (com janela), em tools/capturas/faisca/faisquinhas/: o Faisquinha preso na bolha, o que a Bolota
## leva, o solto esperando e o salvo pulando. Uso: godot --path . -- --faisca-faisquinhas-captura
func capturar() -> void:
	var dir := ProjectSettings.globalize_path("res://tools/capturas/faisca/faisquinhas/")
	DirAccess.make_dir_recursive_absolute(dir)
	var n := nova_fase("1-1")
	solo.add_child(n)
	j.limite_queda = -1000.0
	j.controle_ligado = false
	j.teleportar(n.inicio)
	var cam := Camera3D.new()
	cam.fov = 50.0
	solo.add_child(cam)
	cam.make_current()
	await _esperar(0.4)
	var f3 := n.faisquinhas[3]
	cam.global_position = f3.global_position + Vector3(0.6, 0.3, 2.6)
	cam.look_at(f3.global_position)
	await _esperar(0.6)
	await _foto(dir + "faisquinha_1_preso.png")
	var f5 := n.faisquinhas[5]
	var b := f5.dono
	b.set_physics_process(false)
	await _esperar(0.3)
	cam.global_position = b.global_position + Vector3(1.5, 2.2, 5.5)
	cam.look_at(b.global_position + Vector3.UP * 1.6)
	await _esperar(0.6)
	await _foto(dir + "faisquinha_2_na_bolota.png")
	b.set_physics_process(true)
	while not b.derrotado:
		b._imune = 0.0
		b.receber_golpe(3, b.global_position + Vector3(0, 0, 1), 0.5)
		await _esperar(0.05)
	await _esperar(1.2)
	j.teleportar(f5.global_position + Vector3(0, -0.4, 4.0))
	cam.global_position = f5.global_position + Vector3(0.8, 0.4, 2.4)
	cam.look_at(f5.global_position + Vector3.UP * 0.1)
	await _esperar(0.5)
	await _foto(dir + "faisquinha_3_solto.png")
	f5.salvar(j)
	await _esperar(0.12)
	await _foto(dir + "faisquinha_4_salvo.png")
	# Lado a lado: à esquerda o que ainda falta salvar, à direita o já salvo em outra vez (`ja_visto`): a bolha com a moeda.
	var lugar := n.inicio + Vector3(0, 1.6, -6)
	var de_moeda: Faisquinha
	for k in 2:
		var v := Faisquinha.new()
		v.id = "1"
		v.ja_visto = k == 1
		v.position = lugar + Vector3(-1.3 + 2.6 * k, 0, 0)
		n.add_child(v)
		if v.ja_visto:
			de_moeda = v
	j.teleportar(n.inicio + Vector3(0, 0, 8))
	cam.global_position = lugar + Vector3(0, 0.4, 5.2)
	cam.look_at(lugar)
	await _esperar(0.6)
	# A moeda de frente para a câmera (ela gira).
	de_moeda.set_process(false)
	(de_moeda.get_node("MoedaNaBolha") as Node3D).rotation.y = 0.35
	await _esperar(0.1)
	await _foto(dir + "faisquinha_5_novo_e_bolha_de_moeda.png")
	solo.get_tree().quit()


func _foto(caminho: String) -> void:
	await RenderingServer.frame_post_draw
	solo.get_viewport().get_texture().get_image().save_png(caminho)
	print("foto: ", caminho.get_file())
